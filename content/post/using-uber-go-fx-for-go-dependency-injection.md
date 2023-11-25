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

Fx 模块是一个可共享的 Go 库或包，为 Fx 应用程序提供独立的功能。

#### 编写模块

要编写 Fx 模块：

1. 定义从 `fx.Module` 调用构建的顶级 `Module` 变量。为您的模块指定一个简短且易于记忆的日志名称。

   ```go
   var Module = fx.Module("server",
    
           Copied!
       
   ```

2. 使用 `fx.Provide` 添加模块的组件。

   ```go
   var Module = fx.Module("server",
     fx.Provide(
       New,
       parseConfig,
     ),
   )
    
           Copied!
       
   ```

3. 如果您的模块有一个必须始终运行的函数，请为其添加 `fx.Invoke` 。

   ```go
   var Module = fx.Module("server",
     fx.Provide(
       New,
       parseConfig,
     ),
     fx.Invoke(startServer),
   )
       
   ```

4. 如果您的模块需要在使用其依赖项之前对其进行修饰，请为其添加 `fx.Decorate` 调用。

   ```go
   var Module = fx.Module("server",
     fx.Provide(
       New,
       parseConfig,
     ),
     fx.Invoke(startServer),
     fx.Decorate(wrapLogger),
   
   )
       
   ```

5. 最后，如果您希望将构造函数的输出保留到您的模块（以及您的模块包含的模块）中，您可以在提供时添加 `fx.Private` 。

   ```go
   var Module = fx.Module("server",
     fx.Provide(
       New,
     ),
     fx.Provide(
       fx.Private,
       parseConfig,
     ),
     fx.Invoke(startServer),
     fx.Decorate(wrapLogger),
   
   )
       
   ```

   在这种情况下， `parseConfig` 现在是“服务器”模块私有的。包含“server”的模块将无法使用生成的 `Config` 类型，因为它只能由“server”模块看到。

这就是编写模块的全部内容。本节的其余部分介绍了我们为在 Uber 编写 Fx 模块而建立的标准和约定。

#### 命名

##### 包名

独立的 Fx 模块，即作为独立库分发的模块，或在库中具有独立 Go 包的模块，应根据它们包装的库或它们提供的功能来命名，并添加“fx”后缀。

| Bad                | 好的              |
| ------------------ | ----------------- |
| `package mylib`    | `package mylibfx` |
| `package httputil` | `package httpfx`  |

作为另一个 Go 包一部分的 Fx 模块或为特定应用程序编写的单服务模块可能会省略此后缀。

##### 参数和结果对象

参数和结果对象类型应以它们所属的函数命名，方法是在函数名称中添加 `Params` 或 `Result` 后缀。

例外：如果函数名称以 `New` 开头，请在添加 `Params` 或 `Result` 后缀之前去除 `New` 前缀。

| 功能 | 参数对象 | 结果对象 |
| ---- | -------- | -------- |
| New  | 参数     | 结果     |
| Run  | 运行参数 | 运行结果 |
| 新富 | Foo参数  | Foo结果  |

#### 导出边界函数

如果您的模块使用的功能无法以其他方式访问，则通过 `fx.Provide` 或 `fx.Invoke` 导出该功能。

```go
var Module = fx.Module("server",
  fx.Provide(
    New,
    parseConfig,
  ),
)

type Config struct {
  Addr string `yaml:"addr"`
}

func New(p Params) (Result, error) {
 
        
    
```

在此示例中，我们不导出 `parseConfig` ，因为它是一个简单的 `yaml.Decode` ，我们不需要公开，但我们仍然导出 `Config` 所以用户可以自己解码。

理由：应该可以在不使用 Fx 本身的情况下使用 Fx 模块。用户应该能够直接调用构造函数并获得与 Fx 模块提供的相同功能。这对于破坏性更改和部分迁移是必要的。
> 坏处：没有 Fx 就无法构建服务器
> ```go
> var Module = fx.Module("server",
>   fx.Provide(newServer),
> )
> 
> func newServer(...) (*Server, error)
> ```

#### 使用参数对象

模块公开的函数不应直接接受依赖项作为参数。相反，他们应该使用参数对象。

```go
type Params struct {
  fx.In

  Log    *zap.Logger
  Config Config
}

func New(p Params) (Result, error) {
    
```

理由：模块不可避免地需要声明新的依赖项。通过使用参数对象，我们可以以向后兼容的方式添加新的可选依赖项，而无需更改函数签名。

>坏：无法在不破坏的情况下添加新参数
>
>```go
>func New(log *zap.Logger) (Result, error)
>```


#### 使用结果对象

模块公开的函数不应将其结果声明为常规返回值。相反，他们应该使用结果对象。

```go
type Result struct {
  fx.Out

  Server *Server
}

func New(p Params) (Result, error) {
 
        Copied!
    
```

理由：模块不可避免地需要返回新结果。通过使用结果对象，我们可以以向后兼容的方式生成新结果，而无需更改函数签名。

>坏：无法在不破坏的情况下添加新结果
>
>```go
>func New(Params) (*Server, error)
>```


#### 不要提供你不拥有的东西

Fx 模块应该只向应用程序提供其权限范围内的类型。模块不应向应用程序提供它们碰巧使用的值。模块也不应该批发地捆绑其他模块。

理由：这使消费者可以自由选择依赖项的来源和方式。他们可以使用您推荐的方法（例如，“include zapfx.Module”），或者构建自己的该依赖项的变体。

>坏：提供依赖
>
>```go
>package httpfx
>
>type Result struct {
>	fx.Out
>
>	Client *http.Client
>	Logger *zap.Logger // BAD
>}
>```
>
>坏：捆绑另一个模块
>
>```go
>package httpfx
>
>var Module = fx.Module("http",
>	fx.Provide(New),
>	zapfx.Module, // BAD
>)
>```

例外：仅用于捆绑其他模块的组织或团队级别的“厨房水槽”模块可能会忽略此规则。例如，在 Uber，我们定义了一个 `uberfx.Module` 来捆绑其他几个独立的模块。所有服务都需要此模块中的所有内容。

#### 保持独立模块的精简

独立的 Fx 模块——那些名称以“fx”结尾的模块很少包含重要的业务逻辑。如果 Fx 模块位于包含重要业务逻辑的包内，则其名称中不应包含“fx”后缀。

理由：某人应该可以迁移到或离开 Fx，而无需重写其业务逻辑。

>好：业务逻辑消耗 net/http.Client
>
>```go
>package httpfx
>
>import "net/http"
>
>type Result struct {
>	fx.Out
>
>	Client *http.Client
>}
>```
>
>坏处：Fx 模块实现了记录器
>
>```go
>package logfx
>
>type Logger struct {
> // ...
>}
>
>func New(...) Logger
>```

#### 谨慎调用

请慎重选择在模块中使用 `fx.Invoke` 。根据设计，仅当应用程序通过另一个模块、构造函数或调用直接或间接使用其结果时，Fx 才会执行通过 `fx.Provide` 添加的构造函数。另一方面，使用 `fx.Invoke` 添加的函数无条件运行，并在此过程中实例化它们所依赖的每个直接值和传递值。

### fx.In/fx.Out

### fx.Replace

### fx.Extract

### fx.Populate



## 参考

+ [Dependency injection in Go with uber-go/fx](https://vincent.composieux.fr/article/dependency-injection-in-go-with-uber-go-fx)
