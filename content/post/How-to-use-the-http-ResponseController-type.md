---
title: "【译】如何使用 http.ResponseController 类型"
date: 2023-03-09
tags: ["http", "golang","translate"]
draft: false
---
> 本文原文地址 https://www.alexedwards.net/blog/how-to-use-the-http-responsecontroller-type，使用chatGPT翻译 

One of my favorite things about the recent Go 1.20 release is the new [`http.ResponseController`](https://pkg.go.dev/net/http#ResponseController) type, which brings with it three nice benefits:
关于最近的 Go 1.20 版本，我最喜欢的事情之一是新的 `http.ResponseController` 类型，它带来了三个好处：

1. You can now override your server-wide read and write deadlines on a *per request* basis.
   您现在可以根据每个请求覆盖服务器范围内的读取和写入截止日期。
2. The pattern for using the `http.Flusher` and `http.Hijacker` interfaces is clearer and feels less hacky. No more type assertions necessary!
   使用 `http.Flusher` 和 `http.Hijacker` 接口的模式更清晰，感觉更轻松。不再需要类型断言！
3. It makes it easier and safer to create and use custom `http.ResponseWriter` implementations.
   它使创建和使用自定义 `http.ResponseWriter` 实现变得更容易和更安全。

The first two benefits are mentioned in the release notes, but the third one seems to have gone under the radar a bit... which is a shame, because it's very helpful!
发行说明中提到了前两个好处，但第三个好处似乎有点不为人知……这很遗憾，因为它非常有帮助！

Let's dive in a take a look.
让我们深入了解一下。

## Per-request deadlines 每个请求的截止日期

Go's [`http.Server`](https://pkg.go.dev/net/http#Server) has `ReadTimeout` and `WriteTimeout` settings, which you can use to automatically close a HTTP connection if reading a request or writing response takes longer than a fixed amount of time. These settings are server-wide and apply to all requests, irrespective of the handler or URL.
Go 的 `http.Server` 有 `ReadTimeout` 和 `WriteTimeout` 设置，如果读取请求或写入响应花费的时间超过固定时间，您可以使用它们自动关闭 HTTP 连接。这些设置是服务器范围的，适用于所有请求，无论处理程序或 URL 是什么。

With `http.ResponseController` you can now use the [`SetReadDeadline()`](https://pkg.go.dev/net/http#ResponseController.SetReadDeadline) and [`SetWriteDeadline()`](https://pkg.go.dev/net/http#ResponseController.SetWriteDeadline) methods to relax or tighten these settings on a per-request basis if you need too. For example:

使用 `http.ResponseController` ，如果需要，您现在可以使用 `SetReadDeadline()` 和 `SetWriteDeadline()` 方法根据每个请求放宽或收紧这些设置。例如：

```
func exampleHandler(w http.ResponseWriter, r *http.Request) {
    rc := http.NewResponseController(w)

    // Set a write deadline in 5 seconds time.
    err := rc.SetWriteDeadline(time.Now().Add(5 * time.Second))
    if err != nil {
        // Handle error
    }

    // Do something...

    // Write the response as normal.
    w.Write([]byte("Done!"))
}
```

This is particularly helpful in an application where you have a small number of handlers that need longer deadlines than all the others, for things like processing a file upload or carrying out a long-running operation.

这在您拥有少量处理程序的应用程序中特别有用，这些处理程序需要比所有其他处理程序更长的截止日期，例如处理文件上传或执行长时间运行的操作。

A few other details to mention:
需要提及的其他一些细节：

- If you set a short server-wide deadline, and that deadline is hit *before* you call `SetWriteDeadline()` or `SetReadDeadline()` then they will have no effect. The server-wide deadline wins.

  如果您设置了一个较短的服务器范围的截止日期，并且在您调用 `SetWriteDeadline()` 或 `SetReadDeadline()` 之前达到了该截止日期，那么它们将无效。服务器范围的截止日期获胜。

- If your underlying `http.ResponseWriter` doesn't support setting per-request deadlines, then calling `SetWriteDeadline()` or `SetReadDeadline()` will return a `http.ErrNotSupported` error.
  
  如果您的底层 `http.ResponseWriter` 不支持设置每个请求的截止日期，则调用 `SetWriteDeadline()` 或 `SetReadDeadline()` 将返回 `http.ErrNotSupported` 错误。
  
- You can effectively remove the server-wide deadline on a per-request basis by passing a zero-valued `time.Time` struct to `SetWriteDeadline()` or `SetReadDeadline()`. For example:
  
  您可以通过将零值 `time.Time` 结构传递给 `SetWriteDeadline()` 或 `SetReadDeadline()` 来有效地删除基于每个请求的服务器范围的截止日期。例如：

```go
rc := http.NewResponseController(w) 
err := rc.SetWriteDeadline(time.Time{})
if err != nil {
// Handle error 
} 
```

## Flusher and Hijacker interfaces Flusher 和 Hijacker 接口

The `http.ResponseController` type also makes it slightly nicer to use the 'optional' [`http.Flusher`](https://pkg.go.dev/net/http#Flusher) and [`http.Hijacker`](https://pkg.go.dev/net/http#Hijacker) interfaces. For example, before Go 1.20 you would use a code pattern like this this to flush response data to the client:

`http.ResponseController` 类型还使使用“可选” `http.Flusher` 和 `http.Hijacker` 接口稍微好一些。例如，在 Go 1.20 之前，您将使用这样的代码模式将响应数据刷新到客户端：

```go
func exampleHandler(w http.ResponseWriter, r *http.Request) {
    f, ok := w.(http.Flusher)
    if !ok {
        // Handle error
    }

    for i := 0; i < 5; i++ {
        fmt.Fprintf(w, "Write %d\n", i)
        f.Flush()

        time.Sleep(time.Second)
    }
}
```

Now you can do this: 现在你可以这样做：

```go
func exampleHandler(w http.ResponseWriter, r *http.Request) {
    rc := http.NewResponseController(w)

    for i := 0; i < 5; i++ {
        fmt.Fprintf(w, "Write %d\n", i)
        err := rc.Flush()
        if err != nil {
            // Handle error
        }

        time.Sleep(time.Second)
    }
}
```

The pattern for hijacking a connection is similar:

劫持连接的模式类似：

```go
func (app *application) home(w http.ResponseWriter, r *http.Request) {
    rc := http.NewResponseController(w)

    conn, bufrw, err := rc.Hijack()
    if err != nil {
        // Handle error
    }
    defer conn.Close()

    // Do something...
}
```

Again, if your underlying `http.ResponseWriter` doesn't support support flushing or hijacking, then calling `Flush()` or `Hijack()` on a `http.ResponseController` will also return an `http.ErrNotSupported` error.

同样，如果您的底层 `http.ResponseWriter` 不支持刷新或劫持，那么在 `http.ResponseController` 上调用 `Flush()` 或 `Hijack()` 也会返回 `http.ErrNotSupported` 错误。

## Custom http.ResponseWriters 自定义 http.ResponseWriters

It's now also easier and safer to create and use custom `http.ResponseWriter` implementations that still support flushing and hijacking.

现在创建和使用仍然支持刷新和劫持的自定义 `http.ResponseWriter` 实现也更容易和更安全。

It's probably easiest to explain how this works with an example, so let's look at the code for a custom `http.ResponseWriter` implementation that records the HTTP status code of a response.

用一个例子来解释它是如何工作的可能是最简单的，所以让我们看一下用于记录响应的 HTTP 状态代码的自定义 `http.ResponseWriter` 实现的代码。

```go
type statusResponseWriter struct {
    http.ResponseWriter // Embed a http.ResponseWriter
    statusCode    int
    headerWritten bool
}

func newstatusResponseWriter(w http.ResponseWriter) *statusResponseWriter {
    return &statusResponseWriter{
        ResponseWriter: w,
        statusCode:     http.StatusOK,
    }
}

func (mw *statusResponseWriter) WriteHeader(statusCode int) {
    mw.ResponseWriter.WriteHeader(statusCode)

    if !mw.headerWritten {
        mw.statusCode = statusCode
        mw.headerWritten = true
    }
}

func (mw *statusResponseWriter) Write(b []byte) (int, error) {
    mw.headerWritten = true
    return mw.ResponseWriter.Write(b)
}

func (mw *statusResponseWriter) Unwrap() http.ResponseWriter {
    return mw.ResponseWriter
}
```

So here we've defined a custom `statusResponseWriter` type, which embeds an existing `http.ResponseWriter` and implements custom `WriteHeader()` and `Write()` methods to support the recording of the HTTP response status code.

所以这里我们定义了一个自定义的 `statusResponseWriter` 类型，它嵌入了一个已有的 `http.ResponseWriter` ，并实现了自定义的 `WriteHeader()` 和 `Write()` 方法，以支持HTTP响应状态码的记录。

But the important thing to notice here is the `Unwrap()` method at the end, which *returns the original embedded `http.ResponseWriter`*.

但这里要注意的重要一点是末尾的 `Unwrap()` 方法，它返回原始嵌入的 `http.ResponseWriter` 。

When you use the new `http.ResponseController` type to to flush, hijack or set a deadline, it will call this `Unwrap()` method to access the original `http.ResponseWriter`. This is done recursively if necessary, so you can potentially layer multiple custom `http.ResponseWriter` implementations on top of each other.

当您使用新的 `http.ResponseController` 类型来刷新、劫持或设置截止日期时，它将调用此 `Unwrap()` 方法来访问原始的 `http.ResponseWriter` 。如有必要，这是递归完成的，因此您可以将多个自定义 `http.ResponseWriter` 实现层叠在一起。

Let's look at a complete example, where we use this `statusResponseWriter` in conjunction with some middleware to log response status codes, along with a handler that sends a 'normal' response and another that uses the new `http.ResponseController` type to send a flushed response.

让我们看一个完整的示例，其中我们将此 `statusResponseWriter` 与一些中间件结合使用来记录响应状态代码，以及一个发送“正常”响应的处理程序和另一个使用新的 `http.ResponseController` 类型发送刷新的处理程序回复。

```go
package main

import (
    "log"
    "net/http"
    "time"
)

type statusResponseWriter struct {
    http.ResponseWriter // Embed a http.ResponseWriter
    statusCode    int
    headerWritten bool
}

func newstatusResponseWriter(w http.ResponseWriter) *statusResponseWriter {
    return &statusResponseWriter{
        ResponseWriter: w,
        statusCode:     http.StatusOK,
    }
}

func (mw *statusResponseWriter) WriteHeader(statusCode int) {
    mw.ResponseWriter.WriteHeader(statusCode)

    if !mw.headerWritten {
        mw.statusCode = statusCode
        mw.headerWritten = true
    }
}

func (mw *statusResponseWriter) Write(b []byte) (int, error) {
    mw.headerWritten = true
    return mw.ResponseWriter.Write(b)
}

func (mw *statusResponseWriter) Unwrap() http.ResponseWriter {
    return mw.ResponseWriter
}

func main() {
    mux := http.NewServeMux()
    mux.HandleFunc("/normal", normalHandler)
    mux.HandleFunc("/flushed", flushedHandler)

    log.Print("Listening...")
    err := http.ListenAndServe(":3000", logResponse(mux))
    if err != nil {
        log.Fatal(err)
    }
}


func logResponse(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        sw := newstatusResponseWriter(w)
        next.ServeHTTP(sw, r)
        log.Printf("%s %s: status %d\n", r.Method, r.URL.Path, sw.statusCode)
    })
}

func normalHandler(w http.ResponseWriter, r *http.Request) {
    w.WriteHeader(http.StatusTeapot)
    w.Write([]byte("OK"))
}

func flushedHandler(w http.ResponseWriter, r *http.Request) {
    rc := http.NewResponseController(w)

    w.Write([]byte("Write A...."))
        err := rc.Flush()
    if err != nil {
        log.Println(err)
        return
    }

    time.Sleep(time.Second)

    w.Write([]byte("Write B...."))
    err = rc.Flush()
    if err != nil {
        log.Println(err)
    }
}
```

If you want, you can run this and try making requests to the `/normal` and `/flushed` endpoints:

如果需要，您可以运行它并尝试向 `/normal` 和 `/flushed` 端点发出请求：

```bash
$ curl http://localhost:3000/normal
OK

$ curl --no-buffer http://localhost:3000/flushed
Write A....Write B....
```

You should see the response from the `flushedHandler` in two parts, first the `Write A...` part, then followed a second later by the `Write B...` part.

您应该看到来自 `flushedHandler` 的响应分为两部分，首先是 `Write A...` 部分，然后是 `Write B...` 部分。

And you should see that the `statusResponseWriter` and `logResponse` middleware have successfully written log messages, including the correct HTTP status code for each response.

您应该会看到 `statusResponseWriter` 和 `logResponse` 中间件已成功写入日志消息，包括每个响应的正确 HTTP 状态代码。

```bash
$ go run main.go 
2023/03/06 21:41:21 Listening...
2023/03/06 21:41:32 GET /normal: status 418
2023/03/06 21:41:44 GET /flushed: status 200
```