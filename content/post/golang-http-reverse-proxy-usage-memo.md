---
title: "golang http Reverse Proxy使用备忘"
date: 2022-09-30
tags: ["golang", "trick"]
draft: false 
---

## 创建

### 一般使用

使用  ` httputil.NewSingleHostReverseProxy` 即可

## 返回Response

当我们想实现获取通过ReverseProxy的请求结果时，可以使用自定义的 `responsewriter` 来实现。参考定义

```go
func (p *ReverseProxy) ServeHTTP(rw http.ResponseWriter, req *http.Request) {
    ....
}

type ResponseWriter interface {
	// Header returns the header map that will be sent by
	// WriteHeader. The Header map also is the mechanism with which
	// Handlers can set HTTP trailers.
	//
	// Changing the header map after a call to WriteHeader (or
	// Write) has no effect unless the modified headers are
	// trailers.
	//
	// There are two ways to set Trailers. The preferred way is to
	// predeclare in the headers which trailers you will later
	// send by setting the "Trailer" header to the names of the
	// trailer keys which will come later. In this case, those
	// keys of the Header map are treated as if they were
	// trailers. See the example. The second way, for trailer
	// keys not known to the Handler until after the first Write,
	// is to prefix the Header map keys with the TrailerPrefix
	// constant value. See TrailerPrefix.
	//
	// To suppress automatic response headers (such as "Date"), set
	// their value to nil.
	Header() Header

	// Write writes the data to the connection as part of an HTTP reply.
	//
	// If WriteHeader has not yet been called, Write calls
	// WriteHeader(http.StatusOK) before writing the data. If the Header
	// does not contain a Content-Type line, Write adds a Content-Type set
	// to the result of passing the initial 512 bytes of written data to
	// DetectContentType. Additionally, if the total size of all written
	// data is under a few KB and there are no Flush calls, the
	// Content-Length header is added automatically.
	//
	// Depending on the HTTP protocol version and the client, calling
	// Write or WriteHeader may prevent future reads on the
	// Request.Body. For HTTP/1.x requests, handlers should read any
	// needed request body data before writing the response. Once the
	// headers have been flushed (due to either an explicit Flusher.Flush
	// call or writing enough data to trigger a flush), the request body
	// may be unavailable. For HTTP/2 requests, the Go HTTP server permits
	// handlers to continue to read the request body while concurrently
	// writing the response. However, such behavior may not be supported
	// by all HTTP/2 clients. Handlers should read before writing if
	// possible to maximize compatibility.
	Write([]byte) (int, error)

	// WriteHeader sends an HTTP response header with the provided
	// status code.
	//
	// If WriteHeader is not called explicitly, the first call to Write
	// will trigger an implicit WriteHeader(http.StatusOK).
	// Thus explicit calls to WriteHeader are mainly used to
	// send error codes.
	//
	// The provided code must be a valid HTTP 1xx-5xx status code.
	// Only one header may be written. Go does not currently
	// support sending user-defined 1xx informational headers,
	// with the exception of 100-continue response header that the
	// Server sends automatically when the Request.Body is read.
	WriteHeader(statusCode int)
}
```

## 例子

```go
package main

import (
	"fmt"
	"log"
	"net/http"
	"net/http/httputil"
	"net/url"

	"github.com/gin-gonic/gin"
)

type customWriter struct {
	http.ResponseWriter
}

func NewCustomWriter(w http.ResponseWriter) *customWriter {
	return &customWriter{w}
}

func (c *customWriter) Header() http.Header {
	return c.ResponseWriter.Header()
}

func (c *customWriter) Write(data []byte) (int, error) {
	fmt.Println(string(data)) //get response here
	return c.ResponseWriter.Write(data)
}

func (c *customWriter) WriteHeader(i int) {
	c.ResponseWriter.WriteHeader(i)
}

func main() {
	router := gin.Default()
	router.GET("/", func(ctx *gin.Context) {
		targetURL, err := url.Parse("http://192.168.0.70:8090")
		if err != nil {
			log.Println(err)
		}
		proxy := httputil.NewSingleHostReverseProxy(targetURL)
		proxy.ServeHTTP(NewCustomWriter(ctx.Writer), ctx.Request)
	})
	router.Run(":8899")
}
```

封装个函数

```go
type proxyResponseWriter struct {
	http.ResponseWriter
	timeOut  int64
	respChan chan []byte
}

func newProxyResponseWriter(w http.ResponseWriter, timeout int64) *proxyResponseWriter {
	return &proxyResponseWriter{w, timeout, make(chan []byte, 1)}
}

func (c *proxyResponseWriter) Header() http.Header {
	return c.ResponseWriter.Header()
}

func (c *proxyResponseWriter) Write(data []byte) (int, error) {
	c.respChan <- data
	return c.ResponseWriter.Write(data)
}

func (c *proxyResponseWriter) WriteHeader(i int) {
	c.ResponseWriter.WriteHeader(i)
}

func apiProxyWithResponse(target string, ctx *gin.Context) []byte {
	targetURL, _ := url.Parse(target)
	proxy := httputil.NewSingleHostReverseProxy(targetURL)
	respWriter := newProxyResponseWriter(ctx.Writer, 5)
	go proxy.ServeHTTP(respWriter, ctx.Request)
	timeoutChan := time.After(time.Duration(respWriter.timeOut) * time.Second)
	for {
		select {
		case <-timeoutChan:
			return nil
		case data := <-respWriter.respChan:
			return data

		}
	}

}
```

## 复用Requet对象

​       某些情况下，需要对http request内容进行判断，然后再根据判断进行操作。写代码的时候发现通过 `ioutil.ReadAll` 读取以后，post进行发送，会报错 `transport connection broken: http: ContentLength=272 with Body length 0` 这样的错误。错误的原因大致是读取body'内容后，request body的Io关闭，不能再读取。

​     解决办法很简单，读取完毕body以后，再将 ` ioutil.NopCloser(bytes.NewReader(data))` 的返回赋值给Request的body即可。

## 参考链接

https://stackoverflow.com/questions/31535569/golang-how-to-read-response-body-of-reverseproxy

https://stackoverflow.com/questions/42466491/golang-reverse-proxy-to-app-behind-nginx

https://stackoverflow.com/questions/54704420/how-to-retry-http-post-requests