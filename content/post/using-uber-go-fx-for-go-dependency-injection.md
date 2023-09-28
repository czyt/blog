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

### fx.Invoke

### fx.Supply()

### fx.Module

### fx.In/fx.Out

### fx.Replace

## 参考

+ [Dependency injection in Go with uber-go/fx](https://vincent.composieux.fr/article/dependency-injection-in-go-with-uber-go-fx)
