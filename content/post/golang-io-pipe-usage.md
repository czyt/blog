---
title: "Golang io.Pipe 使用"
date: 2022-06-24
tags: ["golang", "io"]
draft: false
---

## 介绍

> // Pipe creates a synchronous in-memory pipe.
> // It can be used to connect code expecting an io.Reader
> // with code expecting an io.Writer.
> //
> // Reads and Writes on the pipe are matched one to one
> // except when multiple Reads are needed to consume a single Write.
> // That is, each Write to the PipeWriter blocks until it has satisfied
> // one or more Reads from the PipeReader that fully consume
> // the written data.
> // The data is copied directly from the Write to the corresponding
> // Read (or Reads); there is no internal buffering.
> //
> // It is safe to call Read and Write in parallel with each other or with Close.
> // Parallel calls to Read and parallel calls to Write are also safe:
> // the individual calls will be gated sequentially.

源码位置[github](https://github.com/golang/go/blob/master/src/io/pipe.go)

## 使用例子
下面代码原链接为 https://luckymrwang.github.io/2020/12/17/Examples-For-Using-io-Pipe-in-Go/
定义

```go
pr, pw := io.Pipe()
```
### Example 1: JSON to HTTP Request
```go
pr, pw := io.Pipe()

go func() {
    // close the writer, so the reader knows there's no more data
    defer pw.Close()

    // write json data to the PipeReader through the PipeWriter
    if err := json.NewEncoder(pw).Encode(&PayLoad{Content: "Hello Pipe!"}); err != nil {
        log.Fatal(err)
    }
}()

// JSON from the PipeWriter lands in the PipeReader
// ...and we send it off...
if _, err := http.Post("http://example.com", "application/json", pr); err != nil {
    log.Fatal(err)
}
```
### Example 2: Split up Data with TeeReader
```go
pr, pw := io.Pipe()

// we need to wait for everything to be done
wg := sync.WaitGroup{}
wg.Add(2)

// we get some file as input
f, err := os.Open("./fruit.txt")
if err != nil {
    log.Fatal(err)
}

// TeeReader gets the data from the file and also writes it to the PipeWriter
tr := io.TeeReader(f, pw) 

go func() {
    defer wg.Done()
    defer pw.Close()

    // get data from the TeeReader, which feeds the PipeReader through the PipeWriter
    _, err := http.Post("https://example.com", "text/html", tr)
    if err != nil {
        log.Fatal(err)
    }
}()

go func() {
    defer wg.Done()
    // read from the PipeReader to stdout
    if _, err := io.Copy(os.Stdout, pr); err != nil {
        log.Fatal(err)
    }
}()

wg.Wait()
```

### Example 3: Piping the output of Shell commands
```go
pr, pw := io.Pipe()
defer pw.Close()

// tell the command to write to our pipe
cmd := exec.Command("cat", "fruit.txt")
cmd.Stdout = pw

go func() {
    defer pr.Close()
    // copy the data written to the PipeReader via the cmd to stdout
    if _, err := io.Copy(os.Stdout, pr); err != nil {
        log.Fatal(err)
    }
}()

// run the command, which writes all output to the PipeWriter
// which then ends up in the PipeReader
if err := cmd.Run(); err != nil {
    log.Fatal(err)
}
```
### Example 4: Piping the output of Http response
```go
package main

import (
	"io"
	"net/http"
	"os/exec"
)

var (
	BUF_LEN = 1024
)

func handler(w http.ResponseWriter, r *http.Request) {
	cmd := exec.Command("./build.sh")
	pipeReader, pipeWriter := io.Pipe()
	cmd.Stdout = pipeWriter
	cmd.Stderr = pipeWriter
	go writeCmdOutput(w, pipeReader)
	cmd.Run()
	pipeWriter.Close()
}

func writeCmdOutput(res http.ResponseWriter, pipeReader *io.PipeReader) {
	buffer := make([]byte, BUF_LEN)
	for {
		n, err := pipeReader.Read(buffer)
		if err != nil {
			pipeReader.Close()
			break
		}

		data := buffer[0:n]
		res.Write(data)
		if f, ok := res.(http.Flusher); ok {
			f.Flush()
		}
		//reset buffer
		for i := 0; i < n; i++ {
			buffer[i] = 0
		}
	}
}

func main() {
	http.HandleFunc("/", handler)
	http.ListenAndServe(":8080", nil)
}
```
### Example 4+: Piping the output of Http response
```go
package main

import (
	"io"
	"net/http"
	"os/exec"
)

func handler(w http.ResponseWriter, r *http.Request) {
	cmd := exec.Command("ls")
	pipeReader, pipeWriter := io.Pipe()
	cmd.Stdout = pipeWriter
	cmd.Stderr = pipeWriter
	go io.Copy(w, pipeReader)
	cmd.Run()
	pipeWriter.Close()
}

func main() {
	http.HandleFunc("/", handler)
	http.ListenAndServe(":8080", nil)
}
```

## 参考

+ https://zetcode.com/golang/pipe/
+ https://medium.com/learning-the-go-programming-language/streaming-io-in-go-d93507931185
+ https://www.jianshu.com/p/aa207155ca7d
+ https://www.ohyee.cc/post/note_go_io_pipe
+ https://golang.hotexamples.com/examples/io/-/Pipe/golang-pipe-function-examples.html

