---
title: "在go中使用CoAP"
date: 2024-08-26
tags: ["go", "iot"]
draft: false
---

## CoAP协议

CoAP（Constrained Application Protocol）是一种专为物联网（IoT）和受限环境设计的网络协议。它的主要目标是为资源受限的设备（如传感器、执行器等）提供一种轻量级的通信方式。以下是 CoAP 协议的几个关键特点和功能：

### 1. 轻量级设计

- **小开销**：CoAP 使用 UDP（用户数据报协议）作为传输层，相比于 TCP（传输控制协议），它具有更小的头部开销，适合带宽有限的环境。
- **简化的消息格式**：CoAP 消息格式简单，适合资源受限的设备。

### 2. 请求/响应模型

- **类似 HTTP**：CoAP 采用类似于 HTTP 的请求/响应模型，客户端可以发送请求（如 GET、POST、PUT、DELETE）来与服务器交互。
- **资源导向**：CoAP 允许客户端访问和操作服务器上的资源，资源通过 URI（统一资源标识符）进行标识。

### 3. 可靠性

- **确认机制**：虽然 CoAP 基于 UDP，但它实现了可靠性机制，包括重传和确认，以确保消息的可靠传输。
- **非确认和确认消息**：CoAP 支持两种类型的消息：确认消息（需要确认）和非确认消息（不需要确认），以适应不同的应用需求。

### 4. 观察功能

- **资源观察**：CoAP 支持观察功能，允许客户端订阅资源的变化，当资源状态发生变化时，服务器会主动通知客户端。这减少了轮询请求的需要。

### 5. 多播支持

- **多播通信**：CoAP 原生支持多播，允许服务器向多个客户端同时发送消息，适合需要广播信息的场景。

### 6. 安全性

- **DTLS**：CoAP 可以与 DTLS（Datagram Transport Layer Security）结合使用，以提供数据加密和安全性，保护数据在传输过程中的安全。

### 应用场景

- **物联网**：CoAP 广泛应用于物联网设备的通信，如智能家居、环境监测、工业自动化等。
- **资源受限设备**：适合用于低功耗、低带宽的设备和网络环境。

![img](https://miro.medium.com/v2/resize:fit:3260/format:webp/1*oMoSQV5Wd6J4tDTxT-PvBg.png)

## 在go中使用coap

### echo服务

server:

```go
package main

import (
    "fmt"
    "log"

    "github.com/plgd-dev/go-coap/v3"
    "github.com/plgd-dev/go-coap/v3/message"
    "github.com/plgd-dev/go-coap/v3/message/codes"
    "github.com/plgd-dev/go-coap/v3/mux"
)

func main() {
    r := mux.NewRouter()
    r.Handle("/echo", mux.HandlerFunc(func(w mux.ResponseWriter, r *mux.Message) {
        fmt.Printf("Got message: %+v\n", r)
        err := w.SetResponse(codes.Content, message.TextPlain, r.Body())
        if err != nil {
            log.Printf("Cannot set response: %v", err)
        }
    }))

    log.Printf("Starting CoAP server on :5683")
    err := coap.ListenAndServe("udp", ":5683", r)
    if err != nil {
        log.Fatal(err)
    }
}
```

client:

```go
package main

import (
    "context"
    "fmt"
    "log"
    "time"

    "github.com/plgd-dev/go-coap/v3/udp"
    "github.com/plgd-dev/go-coap/v3/message"
)

func main() {
    co, err := udp.Dial("localhost:5683")
    if err != nil {
        log.Fatalf("Error dialing: %v", err)
    }
    defer co.Close()

    ctx, cancel := context.WithTimeout(context.Background(), time.Second)
    defer cancel()

    resp, err := co.Post(ctx, "/echo", message.TextPlain, []byte("Hello CoAP!"))
    if err != nil {
        log.Fatalf("Error sending request: %v", err)
    }

    body, err := resp.ReadBody()
    if err != nil {
        log.Fatalf("Error reading response: %v", err)
    }
    fmt.Printf("Response: %s\n", body)
}
```

### 可靠性机制

```go
package main

import (
    "context"
    "log"
    "time"

    "github.com/plgd-dev/go-coap/v3/udp"
    "github.com/plgd-dev/go-coap/v3/udp/client"
)

func main() {
    opts := []udp.Option{
        udp.WithRetransmission(udp.RetransmissionParams{
            MaxRetransmit:   4,
            AckTimeout:      2 * time.Second,
            AckRandomFactor: 1.5,
        }),
    }

    co, err := udp.Dial("localhost:5683", opts...)
    if err != nil {
        log.Fatalf("Error creating client: %v", err)
    }
    defer co.Close()

    ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
    defer cancel()

    resp, err := co.Get(ctx, "/test")
    if err != nil {
        log.Fatalf("Error sending request: %v", err)
    }

    // 处理响应
    body, err := resp.ReadBody()
    if err != nil {
        log.Fatalf("Error reading response: %v", err)
    }
    log.Printf("Response: %s", body)
}
```

### 观察者模式

server:

```go
package main

import (
    "fmt"
    "log"
    "time"

    "github.com/plgd-dev/go-coap/v3"
    "github.com/plgd-dev/go-coap/v3/message"
    "github.com/plgd-dev/go-coap/v3/message/codes"
    "github.com/plgd-dev/go-coap/v3/mux"
)

func handleTemperature(w mux.ResponseWriter, r *mux.Message) {
    log.Printf("Got message: %+v", r)
    
    obs, err := r.Options().Observe()
    if err != nil {
        log.Printf("Unable to get observe option: %v", err)
        w.SetResponse(codes.BadOption, message.TextPlain, nil)
        return
    }

    if obs == 0 { // Subscribe
        go func() {
            for i := 0; ; i++ {
                temp := fmt.Sprintf("%d°C", 20+(i%10))
                msg := message.Message{
                    Code:    codes.Content,
                    Body:    []byte(temp),
                    Options: message.Options{},
                }
                msg.SetOption(message.Observe, uint32(i))
                msg.SetContentFormat(message.TextPlain)
                
                err := w.WriteMessage(&msg)
                if err != nil {
                    log.Printf("Error sending: %v", err)
                    return
                }
                time.Sleep(5 * time.Second)
            }
        }()
    }
}

func main() {
    r := mux.NewRouter()
    r.Handle("/temperature", mux.HandlerFunc(handleTemperature))

    log.Printf("Starting CoAP server on :5683")
    err := coap.ListenAndServe("udp", ":5683", r)
    if err != nil {
        log.Fatal(err)
    }
}
```

client:

```go
package main

import (
    "context"
    "log"
    "os"
    "os/signal"
    "time"

    "github.com/plgd-dev/go-coap/v3/message"
    "github.com/plgd-dev/go-coap/v3/udp"
)

func main() {
    ctx, cancel := context.WithTimeout(context.Background(), time.Second)
    defer cancel()
    
    co, err := udp.Dial("localhost:5683")
    if err != nil {
        log.Fatalf("Error dialing: %v", err)
    }
    defer co.Close()

    resp, err := co.Get(ctx, "/temperature", message.Option{ID: message.Observe, Value: []byte{0}})
    if err != nil {
        log.Fatalf("Error sending request: %v", err)
    }

    go func() {
        for {
            msg, err := resp.Observe()
            if err != nil {
                log.Printf("Observation failed: %v", err)
                return
            }
            log.Printf("Got temperature: %v", string(msg.Body()))
        }
    }()

    // Wait for interrupt signal
    c := make(chan os.Signal, 1)
    signal.Notify(c, os.Interrupt)
    <-c

    // Cancel observation
    ctx, cancel = context.WithTimeout(context.Background(), time.Second)
    defer cancel()
    _, err = co.Get(ctx, "/temperature", message.Option{ID: message.Observe, Value: []byte{1}})
    if err != nil {
        log.Fatalf("Error cancelling observation: %v", err)
    }
}
```

### 广播

```go
package main

import (
    "context"
    "log"
    "time"

    "github.com/plgd-dev/go-coap/v3/message"
    "github.com/plgd-dev/go-coap/v3/udp"
)

func main() {
    multicastAddr := "224.0.1.187:5683"

    co, err := udp.Dial(multicastAddr)
    if err != nil {
        log.Fatalf("Error dialing: %v", err)
    }
    defer co.Close()

    ctx, cancel := context.WithTimeout(context.Background(), time.Second)
    defer cancel()
    
    resp, err := co.Post(ctx, "/broadcast", message.TextPlain, []byte("Hello CoAP world!"))
    if err != nil {
        log.Fatalf("Error sending broadcast: %v", err)
    }

    log.Printf("Response Code: %v", resp.Code())
    if resp.Body() != nil {
        body, err := resp.ReadBody()
        if err != nil {
            log.Fatalf("Error reading response: %v", err)
        }
        log.Printf("Response Body: %s", body)
    }
}
```

## 文件上传

### 服务端

```go
package main

import (
    "fmt"
    "log"
    "os"
    "sync"

    "github.com/plgd-dev/go-coap/v3/message"
    "github.com/plgd-dev/go-coap/v3/message/codes"
    "github.com/plgd-dev/go-coap/v3/mux"
    "github.com/plgd-dev/go-coap/v3/udp"
)

type FileUpload struct {
    file   *os.File
    mutex  sync.Mutex
    offset int64
}

var activeUploads = make(map[string]*FileUpload)
var uploadsMutex sync.Mutex

func handleFileUpload(w mux.ResponseWriter, r *mux.Message) {
    log.Printf("Received file upload request")

    filename, err := r.Options().GetString(message.URIQuery)
    if err != nil {
        log.Printf("Error getting filename: %v", err)
        w.SetResponse(codes.BadRequest, message.TextPlain, nil)
        return
    }

    block2, err := r.Options().GetUint32(message.Block2)
    if err != nil {
        log.Printf("Error getting Block2 option: %v", err)
        w.SetResponse(codes.BadRequest, message.TextPlain, nil)
        return
    }

    blockNum := block2 >> 4
    blockSize := 1 << (block2 & 0xF)
    moreBlocks := block2 & 0x8

    uploadsMutex.Lock()
    upload, exists := activeUploads[filename]
    if !exists {
        file, err := os.OpenFile(filename, os.O_CREATE|os.O_WRONLY, 0644)
        if err != nil {
            log.Printf("Error creating file: %v", err)
            w.SetResponse(codes.InternalServerError, message.TextPlain, nil)
            uploadsMutex.Unlock()
            return
        }
        upload = &FileUpload{file: file}
        activeUploads[filename] = upload
    }
    uploadsMutex.Unlock()

    upload.mutex.Lock()
    defer upload.mutex.Unlock()

    expectedOffset := int64(blockNum) * int64(blockSize)
    if upload.offset != expectedOffset {
        log.Printf("Unexpected offset. Expected: %d, Got: %d", expectedOffset, upload.offset)
        w.SetResponse(codes.BadRequest, message.TextPlain, nil)
        return
    }

    _, err = upload.file.WriteAt(r.Body(), upload.offset)
    if err != nil {
        log.Printf("Error writing to file: %v", err)
        w.SetResponse(codes.InternalServerError, message.TextPlain, nil)
        return
    }

    upload.offset += int64(len(r.Body()))

    if moreBlocks == 0 {
        upload.file.Close()
        delete(activeUploads, filename)
        log.Printf("File %s uploaded successfully", filename)
    }

    w.SetResponse(codes.Changed, message.TextPlain, []byte(fmt.Sprintf("Received block %d", blockNum)))
}

func main() {
    r := mux.NewRouter()
    r.Handle("/upload", mux.HandlerFunc(handleFileUpload))

    log.Printf("Starting CoAP server on :5683")
    err := udp.ListenAndServe(":5683", r)
    if err != nil {
        log.Fatalf("Error starting server: %v", err)
    }
}
```

### 客户端

```go
package main

import (
    "context"
    "fmt"
    "log"
    "os"
    "path/filepath"

    "github.com/plgd-dev/go-coap/v3/message"
    "github.com/plgd-dev/go-coap/v3/udp"
)

const blockSize = 1024

func main() {
    if len(os.Args) < 2 {
        log.Fatalf("Usage: %s <filename>", os.Args[0])
    }

    filename := os.Args[1]

    file, err := os.Open(filename)
    if err != nil {
        log.Fatalf("Error opening file: %v", err)
    }
    defer file.Close()

    co, err := udp.Dial("localhost:5683")
    if err != nil {
        log.Fatalf("Error dialing: %v", err)
    }
    defer co.Close()

    fileInfo, err := file.Stat()
    if err != nil {
        log.Fatalf("Error getting file info: %v", err)
    }

    totalBlocks := (fileInfo.Size() + int64(blockSize) - 1) / int64(blockSize)

    for blockNum := uint32(0); blockNum < uint32(totalBlocks); blockNum++ {
        buffer := make([]byte, blockSize)
        n, err := file.Read(buffer)
        if err != nil {
            log.Fatalf("Error reading file: %v", err)
        }

        moreBlocks := uint32(8)
        if blockNum == uint32(totalBlocks)-1 {
            moreBlocks = 0
        }

        block2 := (blockNum << 4) | moreBlocks | 6 // 6 represents block size of 1024

        ctx := context.Background()
        resp, err := co.Post(ctx, "/upload", message.AppOctetStream, buffer[:n],
            message.WithQuery(fmt.Sprintf("filename=%s", filepath.Base(filename))),
            message.WithBlock2(block2))
        if err != nil {
            log.Fatalf("Error sending block %d: %v", blockNum, err)
        }

        log.Printf("Block %d sent. Response Code: %v", blockNum, resp.Code())
        if resp.Body() != nil {
            log.Printf("Response Body: %s", resp.Body())
        }
    }

    fmt.Println("File upload completed")
}
```

