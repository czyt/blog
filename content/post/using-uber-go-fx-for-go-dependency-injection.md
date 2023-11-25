---
title: "使用uber-go的fx进行依赖注入"
date: 2023-09-37
tags: ["golang", "dependency injection"]
draft: true
---

## 入门

下面是一个官方的例子：

```go
package main

import (
	"context"
	"fmt"
	"go.uber.org/fx"
	"io"
	"net"
	"net/http"
	"os"
)

func main() {
	fx.New(
		fx.Provide(
			NewHTTPServer,
			NewEchoHandler,
			NewServeMux,
		),
		fx.Invoke(func(srv *http.Server) {}),
	).Run()
}

func NewHTTPServer(lc fx.Lifecycle, mux *http.ServeMux) *http.Server {
	srv := &http.Server{
		Addr:    ":8080",
		Handler: mux,
	}
	lc.Append(fx.Hook{
		OnStart: func(ctx context.Context) error {
			ln, err := net.Listen("tcp", srv.Addr)
			if err != nil {
				return err
			}
			fmt.Println("Starting HTTP server at", srv.Addr)
			go srv.Serve(ln)
			return nil
		},
		OnStop: func(ctx context.Context) error {
			return srv.Shutdown(ctx)
		},
	})
	return srv
}

// EchoHandler is an http.Handler that copies its request body
// back to the response.
type EchoHandler struct{}

// NewEchoHandler builds a new EchoHandler.
func NewEchoHandler() *EchoHandler {
	return &EchoHandler{}
}

// ServeHTTP handles an HTTP request to the /echo endpoint.
func (*EchoHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	if _, err := io.Copy(w, r.Body); err != nil {
		fmt.Fprintln(os.Stderr, "Failed to handle request:", err)
	}
}

// NewServeMux builds a ServeMux that will route requests
// to the given EchoHandler.
func NewServeMux(echo *EchoHandler) *http.ServeMux {
	mux := http.NewServeMux()
	mux.Handle("/echo", echo)
	return mux
}
```

## 详解

### fx.Lifecycle

使用 `fx.Lifecycle` 对象向应用程序添加生命周期挂钩。这告诉 Fx 如何启动和停止 HTTP 服务器。

```go
func NewHTTPServer(lc fx.Lifecycle) *http.Server {
  srv := &http.Server{Addr: ":8080"}
  lc.Append(fx.Hook{
    OnStart: func(ctx context.Context) error {
      ln, err := net.Listen("tcp", srv.Addr)
      if err != nil {
        return err
      }
      fmt.Println("Starting HTTP server at", srv.Addr)
      go srv.Serve(ln)
      return nil
    },
    OnStop: func(ctx context.Context) error {
      return srv.Shutdown(ctx)
    },
  })
  return srv
}
```
Fx 应用程序的生命周期有两个高级阶段：初始化和执行。这两者又由多个步骤组成。

在初始化期间，Fx 将，

1. 注册传递给 `fx.Provide` 的所有构造函数
2. 注册所有传递给 `fx.Decorate` 的装饰器
3. 运行传递给 `fx.Invoke` 的所有函数，根据需要调用构造函数和装饰器
4. 在执行期间，Fx 将，运行由提供者、装饰器和调用的函数附加到应用程序的所有启动挂钩等待信号停止运行运行附加到应用程序的所有关闭挂钩

{{<mermaid>}}
flowchart LR
    subgraph "Initialization (fx.New)"
        Provide --> Decorate --> Invoke
    end
    subgraph "Execution (fx.App.Run)"
        Start --> Wait --> Stop
    end
    Invoke --> Start
    

    style Wait stroke-dasharray: 5 5
{{</mermaid>}}

生命周期挂钩提供了在应用程序启动或关闭时安排 Fx 执行的工作的能力。 Fx提供了两种钩子：

- 启动挂钩，也称为 OnStart 挂钩。它们按照附加的顺序运行。

- 关闭挂钩，也称为 OnStop 挂钩。它们以与附加顺序相反的顺序运行。
  通常，提供启动钩子的组件也会提供相应的关闭钩子来释放它们在启动时获取的资源。

Fx 运行两种类型的钩子并强制执行硬超时。因此，钩子仅在需要安排工作时才会阻塞。换句话说，

挂钩不得阻塞以同步运行长时间运行的任务
hooks 应该在后台 goroutine 中安排长时间运行的任务
关闭钩子应该停止由启动钩子启动的后台工作
### fx.Provide

使用 `fx.Provide` 将上面的HttpServer构造函数提供给 Fx 应用程序。

```go
func main() {
  fx.New(
    fx.Provide(NewHTTPServer),
  ).Run()
}
```

### fx.Invoke

### fx.Annotated

### fx.Supply()

### fx.Module

### fx.In/fx.Out

### fx.Replace

### fx.Extract

### fx.Populate



## 参考

+ [Dependency injection in Go with uber-go/fx](https://vincent.composieux.fr/article/dependency-injection-in-go-with-uber-go-fx)
