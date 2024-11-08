---
title: "Connect Rpc快速上手"
date: 2024-11-06T16:04:38+08:00
draft: false
tags: ["go","rpc"]
author: "czyt"
---
## 入门

Connect RPC 是一个轻量级的 HTTP API 构建库，支持浏览器和 gRPC 兼容的 API。它通过 Protocol Buffer 定义服务，并生成类型安全的服务器和客户端代码。

### 压缩和序列化

Connect 支持多种压缩和序列化选项，默认情况下，Connect 处理程序支持在默认压缩级别使用标准库的 `compress/gzip` 进行 gzip 压缩。Connect 客户端默认发送未压缩的请求并请求 gzip 压缩的响应。如果您知道服务器支持 gzip，则还可以在客户端构建期间使用 `WithSendGzip` 选项来压缩请求。

```go
// 服务端不需要进行什么选项设置 参考https://github.com/connectrpc/connect-go/issues/773
handler := greetv1connect.NewGreetServiceHandler(
    &GreetServer{},
)

// 客户端配置压缩，默认
client := greetv1connect.NewGreetServiceClient(
    http.DefaultClient,
    "http://localhost:8080",
    connect.WithSendGzip(),
)
```

自定义压缩实现：
```go
type CustomCompressor struct{}

func (c *CustomCompressor) Name() string { return "custom" }
func (c *CustomCompressor) Compress(w io.Writer) (io.WriteCloser, error)
func (c *CustomCompressor) Decompress(r io.Reader) (io.Reader, error)
```

### Get 请求

Connect 支持通过 HTTP GET 进行无副作用的请求，这使得可以在浏览器、CDN 或代理中缓存某些类型的请求。

在 proto 文件中标记方法，使用[`MethodOptions.IdempotencyLevel` ](https://github.com/protocolbuffers/protobuf/blob/e5679c01e8f47e8a5e7172444676bda1c2ada875/src/google/protobuf/descriptor.proto#L795]选项将其标记为无副作用。
```protobuf
service ElizaService {
  rpc Say(SayRequest) returns (SayResponse) {
    option idempotency_level = NO_SIDE_EFFECTS;
  }
}
```

客户端启用 GET 请求：
```go
client := elizav1connect.NewElizaServiceClient(
    http.DefaultClient,
    connect.WithHTTPGet(),
)
```
> **仅当**使用 Connect 协议（将 Connect 客户端与 Connect 服务一起使用）时，才支持此功能。将 gRPC 客户端与 Connect 服务器一起使用，或将 Connect 客户端与 gRPC 服务器一起使用时，所有请求都将使用 HTTP POST。如果您在与原版 gRPC 服务器通信时需要 HTTP GET 支持，则可以使用代理。Envoy 支持使用 [Connect-gRPC Bridge](https://www.envoyproxy.io/docs/envoy/v1.26.0/configuration/http/http_filters/connect_grpc_bridge_filter#config-http-filters-connect-grpc-bridge) 在 Connect 客户端和 gRPC 服务器之间进行转换。

## 进阶

### 发布和 HTTP/2

1. **HTTP/2 支持**:

服务端

```go
package main

import (
  "net/http"

  "golang.org/x/net/http2"
  "golang.org/x/net/http2/h2c"
)

func main() {
  mux := http.NewServeMux()
  // Mount some handlers here.
  server := &http.Server{
    Addr: ":http",
    Handler: h2c.NewHandler(mux, &http2.Server{}),
    // Don't forget timeouts!
  }
}
```

客户端

```go
package main

import (
  "crypto/tls"
  "net"
  "net/http"

  "golang.org/x/net/http2"
)

func newInsecureClient() *http.Client {
  return &http.Client{
    Transport: &http2.Transport{
      AllowHTTP: true,
      DialTLS: func(network, addr string, _ *tls.Config) (net.Conn, error) {
        // If you're also using this client for non-h2c traffic, you may want
        // to delegate to tls.Dial if the network isn't TCP or the addr isn't
        // in an allowlist.
        return net.Dial(network, addr)
      },
      // Don't forget timeouts!
    },
  }
}
```

2. **CORS 配置**:

```go
corsHandler := cors.New(cors.Options{
    AllowedMethods: []string{
        http.MethodGet,
        http.MethodPost,
    },
    AllowedHeaders: []string{
        "Accept-Encoding",
        "Content-Type",
        "Connect-Protocol-Version",
    },
    AllowedOrigins: []string{"*"},
})
handler := corsHandler.Handler(mux)
```

### Header 和 Trailer

#### **处理 Headers**:
```go
func (s *Server) Greet(
    ctx context.Context,
    req *connect.Request[greetv1.GreetRequest],
) (*connect.Response[greetv1.GreetResponse], error) {
    // 读取请求头
    tenantID := req.Header().Get("Tenant-ID")
    
    // 设置响应头
    res := connect.NewResponse(&greetv1.GreetResponse{})
    res.Header().Set("Version", "v1")
    return res, nil
}
```
Headers 处理和grpc的差异和相似点：

1. **相似点**：
- 都使用 HTTP headers
- 都支持二进制 headers (使用 -Bin 后缀)
- 都有保留的 header 前缀限制

2. **不同点**：
- Connect 使用更简单的 API，直接通过 `Request` 和 `Response` 结构访问
- gRPC 通常通过 context 传递 metadata
- Connect 的 header 命名更灵活，只要符合 HTTP header 规范即可

关键限制
**Header 命名限制**：
- 保留前缀：`Connect-` 和 `Grpc-`
- 只能包含 ASCII 字母、数字、下划线、连字符和点
- 值只能包含可打印 ASCII 和空格

####  **二进制 Headers**:
```go
// 编码二进制头
res.Header().Set(
    "Binary-Data-Bin",
    connect.EncodeBinaryHeader([]byte("data")),
)

// 解码二进制头
if data, err := connect.DecodeBinaryHeader(
    req.Header().Get("Binary-Data-Bin"),
); err == nil {
    // 使用解码后的数据
}
```

#### **Trailer** 

> Trailer 必须在响应返回前设置

```go
func (s *Server) Greet(
    ctx context.Context,
    req *connect.Request[greetv1.GreetRequest],
) (*connect.Response[greetv1.GreetResponse], error) {
    res := connect.NewResponse(&greetv1.GreetResponse{})
    // Trailer 必须在返回前设置
    res.Trailer().Set("Greet-Version", "v1")
    return res, nil
}
```

##### **Trailer 限制**:

- 一旦响应返回,无法再修改 Trailer
- 对于流式响应,可以在流结束前的任何时候设置 Trailer
- 建议在非流式响应中使用 Header 而不是 Trailer

##### 和grpc的差异和相似点

1. **编码差异**：
```go
// Connect 的 Trailer 处理
func (s *Server) Greet(ctx context.Context, req *connect.Request[greetv1.GreetRequest]) (*connect.Response[greetv1.GreetResponse], error) {
    res := connect.NewResponse(&greetv1.GreetResponse{})
    // Connect 会自动添加 Trailer- 前缀
    res.Trailer().Set("Greet-Version", "v1")
    return res, nil
}
```
2. **协议差异**：
- gRPC: 总是使用 HTTP trailers
- gRPC-Web: 将 trailers 编码在响应体的最后部分
- Connect: 
  - 对于一元调用：使用 `Trailer-` 前缀的 HTTP headers
  - 对于流式调用：类似 gRPC-Web 的处理方式

3. **使用建议**：
- 一元调用建议使用 Headers 而不是 Trailers
- Trailers 主要用于流式调用，在发送消息后需要传递元数据的场景

关键限制

1. **Trailer 设置时机**：
- 必须在响应返回前设置
- 一旦响应返回，无法修改 Trailer
- 流式响应可以在流结束前的任何时候设置

这些差异主要是为了提供更好的 HTTP 兼容性和更简单的 API 使用体验。

### 注意

对于流式的Connect RPC 官方已明确不支持 Nginx 直接代理。

>使用 Connect 协议制作的请求-响应（一元）RPC 不需要端到端 HTTP/2，因此可以通过 NGINX 进行代理。流式 RPC 通常需要端到端 HTTP/2，而 NGINX 不支持。我们建议使用 Envoy、Apache 或 TCP 级负载均衡器（如 HAProxy），而不是 NGINX，所有这些负载均衡器都支持完整的 Connect 协议.

### 错误处理

1. **标准错误处理**:
```go
if err != nil {
    return nil, connect.NewError(
        connect.CodeInvalidArgument,
        fmt.Errorf("invalid request: %w", err),
    )
}
```

2. **错误详情**:
```go
// 创建带详情的错误
err := connect.NewError(
    connect.CodeNotFound,
    errors.New("resource not found"),
)
err.Meta().Set("resource-id", "123")

// 处理错误
if connectErr := new(connect.Error); errors.As(err, &connectErr) {
    fmt.Println(connectErr.Code())
    fmt.Println(connectErr.Meta().Get("resource-id"))
}
```

Connect RPC 提供了简单而强大的 API 构建方式，既保持了与 gRPC 的兼容性，又提供了更现代的开发体验。通过合理使用其提供的功能，可以构建高效、可靠的微服务系统。