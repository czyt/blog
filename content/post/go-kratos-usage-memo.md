---
title: "go-kratos使用备忘"
date: 2022-08-12
tags: ["golang", "kratos"]
draft: false
---
## 自定义接口返回内容
+ 正常的响应序列化逻辑通过[Response Encoder](https://go-kratos.dev/docs/component/transport/http#responseencoderen-encoderesponsefunc-serveroption)实现。

+ 错误的序列化逻辑通过[ErrorEncoder](https://go-kratos.dev/docs/component/transport/http#errorencoderen-encodeerrorfunc-serveroption)实现。

  **注意**：自定义Encoder后，可能会遇到零值字段被忽略的情况，可以参考这个[issue](https://github.com/go-kratos/kratos/issues/1952)

## 通过Context取得信息

Server端取JWT中的key数据

```go
func getPayloadFromCtx(ctx context.Context, partName string) (string, error) {
	if claims, ok := jwt.FromContext(ctx); ok {
		if m, ok := claims.(jwtV4.MapClaims); ok {
			if v, ok := m[partName].(string); ok {
				return v, nil
			}
		}
	}
	return "", errors.New("invalid Jwt")
}
```

middleware中，还可以将context转换为`http.Transport`获取更多的信息。

```go
if tr, ok := transport.FromServerContext(ctx); ok {
    // 可以取header等信息
    if hr, ok := tr.(*http.Transport); ok {
      // 可以取request等信息
   }
}

```

## 日志脱敏与过滤

需要对日志进行脱敏和过滤，使用 kratos的[日志过滤](https://go-kratos.dev/docs/component/log#filter-%E6%97%A5%E5%BF%97%E8%BF%87%E6%BB%A4)

```go
h := NewHelper(
    NewFilter(logger,
        // 等级过滤
        FilterLevel(log.LevelError),

        // 按key遮蔽
        FilterKey("username"),

        // 按value遮蔽
        FilterValue("hello"),

        // 自定义过滤函数
        FilterFunc(
            func (level Level, keyvals ...interface{}) bool {
                if level == LevelWarn {
                    return true
                }
                for i := 0; i < len(keyvals); i++ {
                    if keyvals[i] == "password" {
                        keyvals[i+1] = fuzzyStr
                    }
                }
                return false
            }
        ),
    ),
)

```

> - `FilterFunc(f func(level Level, keyvals ...interface{}) bool)` 使用自定义的函数来对日志进行处理，keyvals里为key和对应的value，按照奇偶进行读取即可

TODO:按奇偶进行读取的意思

## 一个接口对应多个httpPath

下面是官网的文档中的一个例子（[原文](https://go-kratos.dev/docs/component/api#%E5%AE%9A%E4%B9%89%E6%8E%A5%E5%8F%A3)）：

```protobuf
syntax = "proto3";

package helloworld.v1;

import "google/api/annotations.proto";

option go_package = "github.com/go-kratos/service-layout/api/helloworld/v1;v1";
option java_multiple_files = true;
option java_package = "dev.kratos.api.helloworld.v1";
option java_outer_classname = "HelloWorldProtoV1";

// The greeting service definition.
service Greeter {
  // Sends a greeting
  rpc SayHello (HelloRequest) returns (HelloReply)  {
    option (google.api.http) = {
        // 定义一个 GET 接口，并且把 name 映射到 HelloRequest
        get: "/helloworld/{name}",
        // 可以添加附加接口
        additional_bindings {
            // 定义一个 POST 接口，并且把 body 映射到 HelloRequest
            post: "/v1/greeter/say_hello",
            body: "*",
        }
    };
  }
}

// The request message containing the user's name.
message HelloRequest {
  string name = 1;
}

// The response message containing the greetings
message HelloReply {
  string message = 1;
}
```

## 支持文件上传

因为protobuf官方限制，并不能通过protobuf生成http服务，需要创建相关逻辑，参考[example](https://github.com/go-kratos/examples/tree/main/http/upload)中的实现：

```go
package main

import (
	"io"
	"log"
	"os"

	"github.com/go-kratos/kratos/v2"
	"github.com/go-kratos/kratos/v2/transport/http"
)

func uploadFile(ctx http.Context) error {
	req := ctx.Request()

	fileName := req.FormValue("name")
	file, handler, err := req.FormFile("file")
	if err != nil {
		return err
	}
	defer file.Close()

	f, err := os.OpenFile(handler.Filename, os.O_WRONLY|os.O_CREATE, 0o666)
	if err != nil {
		return err
	}
	defer f.Close()
	_, _ = io.Copy(f, file)

	return ctx.String(200, "File "+fileName+" Uploaded successfully")
}

func main() {
	httpSrv := http.NewServer(
		http.Address(":8000"),
	)
	route := httpSrv.Route("/")
	route.POST("/upload", uploadFile)

	app := kratos.New(
		kratos.Name("upload"),
		kratos.Server(
			httpSrv,
		),
	)
	if err := app.Run(); err != nil {
		log.Fatal(err)
	}
}
```

## 静态文件托管

官方例子

```go
package main

import (
	"embed"
	"log"
	"net/http"

	"github.com/go-kratos/kratos/v2"
	transhttp "github.com/go-kratos/kratos/v2/transport/http"
	"github.com/gorilla/mux"
)

//go:embed assets/*
var f embed.FS

func main() {
	router := mux.NewRouter()
	// example: /assets/index.html
	router.PathPrefix("/assets").Handler(http.FileServer(http.FS(f)))

	httpSrv := transhttp.NewServer(transhttp.Address(":8000"))
	httpSrv.HandlePrefix("/", router)

	app := kratos.New(
		kratos.Name("static"),
		kratos.Server(
			httpSrv,
		),
	)
	if err := app.Run(); err != nil {
		log.Fatal(err)
	}
}
```

## Service和Biz层的区分

Service 层：协议转换，比如grpc转http 和一些简单的validate。

Biz层：具体的Biz业务，跟协议无关。

## 集成实时的metric
### statsviz

[官方网站](https://github.com/arl/statsviz)说明

>Visualise Go program runtime metrics data in real time: heap, objects, goroutines, GC pauses, scheduler, etc. in your browser.
>
>实时可视化Go程序运行时度量数据：在浏览器中的堆、对象、goroutine、GC暂停、调度程序等。

在服务的入口添加下面的代码
```go
imports(
    ....
    "github.com/arl/statsviz"
    ....
)
func newApp(logger log.Logger, gs *grpc.Server, hs *http.Server) *kratos.App {
	statsviz.RegisterDefault()
	....
	}
```
然后在服务监听地址(默认是http://localhost:8000)后面加上`/debug/statsviz/`访问即可。

![image-20220908220623248](https://assets.czyt.tech/img/statsviz-demo-screenshot.png)

类似的还有：

+ https://github.com/felixge/fgtrace 

  >fgtrace is an experimental profiler/tracer that is capturing wallclock timelines for each goroutine. It's very similar to the Chrome profiler.
  >
  >⚠️ fgtrace may cause noticeable stop-the-world pauses in your applications. It is intended for dev and testing environments for now.

## 服务端配置选项

参考[官方项目](https://github.com/go-kratos/beer-shop/blob/main/app/shop/interface/internal/server/http.go)

```go
http.Filter(handlers.CORS(
			handlers.AllowedHeaders([]string{"X-Requested-With", "Content-Type", "Authorization"}),// 允许的header
			handlers.AllowedMethods([]string{"GET", "POST", "PUT", "HEAD", "OPTIONS"}),// 允许方法
			handlers.AllowedOrigins([]string{"*"}),//允许的请求源
		)),
```

需要引用包`"github.com/gorilla/handlers"`

## 参考

+ [三分钟小课堂 - 如何控制接口返回值](https://mp.weixin.qq.com/s/4ocdoAVXXKTvJ3U65YXltw)

