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
    "github.com/plgd-dev/go-coap/v3/mux"
)

func main() {
    // 创建一个新的 CoAP 服务器
    r := mux.NewRouter()

    // 注册一个处理函数，处理 "/echo" 路径的请求
    r.Handle("/echo", mux.HandlerFunc(func(w mux.ResponseWriter, r *mux.Message) {
        // 将接收到的消息原样返回
        fmt.Printf("Received: %s\n", r.Body())
        err := w.SetResponse(coap.Content, r.MediaType(), r.Body())
        if err != nil {
            log.Printf("Cannot set response: %v", err)
        }
    }))

    // 启动服务器
    addr := ":5683"
    log.Printf("Starting CoAP server on %s\n", addr)
    err := coap.ListenAndServe("udp", addr, r)
    if err != nil {
        log.Fatal(err)
    }
}
```

Client:

```go
package main

import (
    "context"
    "fmt"
    "log"
    "time"

    "github.com/plgd-dev/go-coap/v3/udp"
)

func main() {
    // 创建一个 CoAP 客户端
    co, err := udp.Dial("localhost:5683")
    if err != nil {
        log.Fatalf("Error dialing: %v", err)
    }
    defer co.Close()

    // 要发送的消息
    message := []byte("Hello, CoAP!")

    ctx, cancel := context.WithTimeout(context.Background(), time.Second)
    defer cancel()

    // 发送请求到服务端
    resp, err := co.Post(ctx, "/echo", "text/plain", message)
    if err != nil {
        log.Fatalf("Error sending request: %v", err)
    }

    // 读取并打印响应
    body, err := resp.ReadBody()
    if err != nil {
        log.Fatalf("Error reading response: %v", err)
    }
    fmt.Printf("Response: %s\n", body)
}
```

### 可靠性机制

CoAP本身是基于UDP的协议，但它提供了一些可靠性机制。以下是在Go中实现CoAP可靠性的一些方法：

1. 使用确认消息（Confirmable Messages）:

   CoAP支持确认型消息，这是实现可靠性的主要机制。在发送消息时，将消息类型设置为确认型（CON），接收方需要发送确认（ACK）。

   ```go
   import (
       "github.com/plgd-dev/go-coap/v3"
   )
   
   // 创建一个确认型消息
   msg := coap.Message{
       Type:      coap.Confirmable,
       Code:      coap.GET,
       MessageID: 1234,
   }
   
   // 发送消息并等待确认
   resp, err := client.Do(context.Background(), msg)
   if err != nil {
       // 处理错误
   }
   ```

2. 实现重传机制：

   如果没有收到确认，可以实现重传逻辑。Go-CoAP库通常会自动处理重传，但您也可以自定义重传策略。

   ```go
   package main
   
   import (
       "context"
       "fmt"
       "log"
       "time"
   
       "github.com/plgd-dev/go-coap/v3/udp"
       "github.com/plgd-dev/go-coap/v3/udp/client"
   )
   
   func main() {
       // 创建自定义的客户端配置
       opts := []udp.Option{
           udp.WithRetransmission(udp.RetransmissionParams{
               MaxRetransmit: 3,
               AckTimeout:    2 * time.Second,
               AckRandomFactor: 1.5,
           }),
           udp.WithHandlerFunc(func(w *client.ResponseWriter, r *pool.Message) {
               log.Printf("Received response: %v", r)
           }),
       }
   
       // 创建客户端
       co, err := udp.Dial("localhost:5683", opts...)
       if err != nil {
           log.Fatalf("Error creating client: %v", err)
       }
       defer co.Close()
   
       // 发送请求
       ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
       defer cancel()
   
       resp, err := co.Get(ctx, "/test")
       if err != nil {
           log.Fatalf("Error sending request: %v", err)
       }
   
       // 读取响应
       body, err := resp.ReadBody()
       if err != nil {
           log.Fatalf("Error reading response: %v", err)
       }
       fmt.Printf("Response body: %s\n", body)
   }
   ```
   >WithRetransmission的参数说明：
   >
   >+ MaxRetransmit: 3
   >
   >含义：最大重传次数
   >
   >解释：如果没有收到确认（ACK），消息最多会重传 3 次。这意味着，包括初始传输在内，消息最多会被发送 4 次。
   >
   >+ AckTimeout: 2 * time.Second
   >
   >含义：确认超时时间
   >
   >解释：在重传消息之前，发送方会等待 2 秒钟来接收确认。如果在这个时间内没有收到确认，就会触发重传。
   >
   >+ AckRandomFactor: 1.5
   >
   >含义：确认随机因子
   >
   >解释：这个因子用于计算实际的超时时间。实际超时时间会在 AckTimeout 和 (AckTimeout *AckRandomFactor) 之间随机选择。这种随机化有助于防止网络拥塞。*


3. 使用观察者模式（Observe Option）：

   对于需要长期监控的资源，可以使用CoAP的观察者选项，这提供了一种可靠的方式来接收资源的更新。

   server：

   ```go
   package main
   
   import (
       "log"
       "time"
   
       coap "github.com/plgd-dev/go-coap/v3"
       "github.com/plgd-dev/go-coap/v3/message"
       "github.com/plgd-dev/go-coap/v3/message/codes"
       "github.com/plgd-dev/go-coap/v3/mux"
   )
   
   func main() {
       r := mux.NewRouter()
       r.Handle("/temperature", mux.HandlerFunc(handleTemperature))
   
       log.Fatal(coap.ListenAndServe("udp", ":5683", r))
   }
   
   func handleTemperature(w mux.ResponseWriter, r *mux.Message) {
       log.Printf("Got message: %+v", r)
       
       // 检查是否是 Observe 请求
       obs, err := r.Options().Observe()
       if err != nil {
           log.Printf("Unable to get observe option: %v", err)
           w.SetCode(codes.BadOption)
           return
       }
   
       if obs == 0 { // 0 表示这是一个订阅请求
           go func() {
               for i := 0; ; i++ {
                   // 模拟温度变化
                   temp := 20 + (i % 10)
                   msg := w.NewMessage(codes.Content)
                   msg.SetContentFormat(message.TextPlain)
                   msg.SetBody([]byte(fmt.Sprintf("%d°C", temp)))
                   msg.SetOption(message.Observe, uint32(i))
                   err := w.WriteMessage(msg)
                   if err != nil {
                       log.Printf("Error on transmit: %v", err)
                       return
                   }
                   time.Sleep(5 * time.Second)
               }
           }()
       } else if obs == 1 { // 1 表示这是一个取消订阅请求
           log.Println("Subscription cancelled")
           w.SetCode(codes.Content)
       }
   }
   ```
client：
```go
package main

import (
    "context"
    "fmt"
    "log"
    "os"
    "os/signal"
    "time"

    coap "github.com/plgd-dev/go-coap/v3"
    "github.com/plgd-dev/go-coap/v3/message"
    "github.com/plgd-dev/go-coap/v3/message/codes"
)

func main() {
    co, err := coap.Dial("udp", "localhost:5683")
    if err != nil {
        log.Fatalf("Error dialing: %v", err)
    }
    defer co.Close()

    ctx, cancel := context.WithTimeout(context.Background(), time.Second)
    defer cancel()

    resp, err := co.Get(ctx, "/temperature")
    if err != nil {
        log.Fatalf("Error sending request: %v", err)
    }

    go func() {
        for {
            msg, err := resp.Observe()
            if err != nil {
                log.Printf("Error observing: %v", err)
                return
            }
            if msg.Code() == codes.Content {
                log.Printf("Received: %s", msg.Body())
            }
        }
    }()

    // 等待用户中断
    c := make(chan os.Signal, 1)
    signal.Notify(c, os.Interrupt)
    <-c

    // 取消订阅
    ctx, cancel = context.WithTimeout(context.Background(), time.Second)
    defer cancel()
    _, err = co.Delete(ctx, "/temperature")
    if err != nil {
        log.Fatalf("Error cancelling observation: %v", err)
    }
}
```


4. 使用块传输（Block-wise Transfer）：

   对于大型消息，CoAP支持块传输，这有助于提高可靠性和效率。

   ```go
   package main
   
   import (
       "context"
       "fmt"
       "log"
   
       "github.com/plgd-dev/go-coap/v3/message"
       "github.com/plgd-dev/go-coap/v3/message/codes"
       "github.com/plgd-dev/go-coap/v3/mux"
       "github.com/plgd-dev/go-coap/v3/udp"
   )
   
   func main() {
       // 创建一个新的消息
       req, err := message.NewMessage(message.MessageParams{
           Type:      message.Confirmable,
           Code:      codes.GET,
           MessageID: 1234,
       })
       if err != nil {
           log.Fatalf("Error creating message: %v", err)
       }
   
       // 添加 Block2 选项以启用块传输
       err = req.SetOptionUint32(message.Block2, 0)
       if err != nil {
           log.Fatalf("Error setting Block2 option: %v", err)
       }
   
       // 创建客户端连接
       co, err := udp.Dial("localhost:5683")
       if err != nil {
           log.Fatalf("Error dialing: %v", err)
       }
       defer co.Close()
   
       // 发送请求
       ctx, cancel := context.WithCancel(context.Background())
       defer cancel()
   
       resp, err := co.Do(req)
       if err != nil {
           log.Fatalf("Error sending request: %v", err)
       }
   
       // 处理响应
       fmt.Printf("Response Code: %v\n", resp.Code())
       if resp.Body() != nil {
           fmt.Printf("Response Body: %s\n", resp.Body())
       }
   }
   ```

5. 实现应用层确认：

   在应用层实现额外的确认机制，特别是对于关键操作。

   ```go
   package main
   
   import (
       "context"
       "fmt"
   
       "github.com/plgd-dev/go-coap/v3/message"
       "github.com/plgd-dev/go-coap/v3/message/codes"
       "github.com/plgd-dev/go-coap/v3/udp"
   )
   
   func sendWithConfirmation(co *udp.ClientConn, path string, payload []byte) error {
       // 创建主消息
       req, err := message.NewMessage(message.MessageParams{
           Type:      message.Confirmable,
           Code:      codes.POST,
           MessageID: 1234,
           Payload:   payload,
       })
       if err != nil {
           return fmt.Errorf("error creating message: %v", err)
       }
   
       // 设置路径
       req.SetPath(path)
   
       // 发送主消息
       resp, err := co.Do(req)
       if err != nil {
           return fmt.Errorf("error sending message: %v", err)
       }
   
       if resp.Code() != codes.Created {
           return fmt.Errorf("unexpected response: %v", resp.Code())
       }
   
       // 创建确认消息
       ackReq, err := message.NewMessage(message.MessageParams{
           Type:      message.Confirmable,
           Code:      codes.POST,
           MessageID: 1235,
           Payload:   []byte("ACK"),
       })
       if err != nil {
           return fmt.Errorf("error creating ACK message: %v", err)
       }
   
       // 设置确认消息的路径
       ackReq.SetPath(path)
   
       // 发送确认消息
       _, err = co.Do(ackReq)
       if err != nil {
           return fmt.Errorf("error sending ACK message: %v", err)
       }
   
       return nil
   }
   
   func main() {
       // 创建客户端连接
       co, err := udp.Dial("localhost:5683")
       if err != nil {
           fmt.Printf("Error dialing: %v\n", err)
           return
       }
       defer co.Close()
   
       // 使用函数
       err = sendWithConfirmation(co, "/resource", []byte("Hello, CoAP!"))
       if err != nil {
           fmt.Printf("Error: %v\n", err)
       } else {
           fmt.Println("Message sent and confirmed successfully")
       }
   }
   ```

   

## 广播

在CoAP中，广播通常是通过使用组播地址来实现的。以下是使用Go语言实现CoAP广播的说明和示例：

1. CoAP广播原理：

      CoAP使用UDP作为传输层协议，因此可以利用UDP的组播功能来实现广播。CoAP的标准组播地址是 `224.0.1.187`。

2. 实现步骤：

- 创建一个CoAP客户端
- 设置组播地址
- 构造广播消息
- 发送消息到组播地址

```go
package main

import (
    "context"
    "fmt"
    "log"
    "time"

    "github.com/plgd-dev/go-coap/v3/udp"
    "github.com/plgd-dev/go-coap/v3/message"
    "github.com/plgd-dev/go-coap/v3/message/codes"
)

func main() {
    // CoAP标准组播地址和端口
    multicastAddr := "224.0.1.187:5683"

    // 创建CoAP客户端
    co, err := udp.Dial(multicastAddr)
    if err != nil {
        log.Fatalf("Error dialing: %v", err)
    }
    defer co.Close()

    // 构造广播消息
    ctx, cancel := context.WithTimeout(context.Background(), time.Second)
    defer cancel()
    
    resp, err := co.Post(ctx, "/broadcast", message.TextPlain, []byte("Hello, CoAP world!"))
    if err != nil {
        log.Fatalf("Error sending broadcast: %v", err)
    }

    // 打印响应
    log.Printf("Response Code: %v", resp.Code())
    if resp.Body() != nil {
        log.Printf("Response Body: %s", resp.Body())
    }

    // 等待一段时间以接收可能的响应
    time.Sleep(5 * time.Second)

    fmt.Println("Broadcast completed")
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

