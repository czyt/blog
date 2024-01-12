---
title: "Google Service Weaver中文文档[机翻]"
date: 2024-01-12
tags: ["golang", "google"]
draft: false
---

> 本文为 [Service Weaver ](https://serviceweaver.dev/) 文档的机器翻译+细节微调。

# Service Weaver是什么 ？ 

Service Weaver 是一个用于编写、部署和管理分布式应用程序的编程框架。您可以在计算机上本地运行、测试和调试 Service Weaver 应用程序，然后使用单个命令将该应用程序部署到云。

```
$ go run .                       # Run locally.
$ weaver ssh deploy weaver.toml  # Run on multiple machines.
$ weaver gke deploy weaver.toml  # Run on Google Cloud.
$ weaver kube deploy weaver.toml # Run on Kubernetes.
```

Service Weaver 应用程序由许多组件组成。组件被表示为常规的 Go 接口，组件之间通过调用这些接口定义的方法进行交互。这使得编写 Service Weaver 应用程序变得容易。您不必编写任何网络或序列化代码；你只要写 Go 就可以了。 Service Weaver 还提供用于日志日志、指标、跟踪、路由、测试等的库。

您可以像运行单个命令一样轻松地部署 Service Weaver 应用程序。在幕后，Service Weaver 将沿着组件边界Profile您的二进制文件，从而允许不同的组件在不同的计算机上运行。 Service Weaver 将为您复制、自动缩放和共同定位这些分布式组件。它还将代表您管理所有网络详细信息，确保不同的组件可以相互通信，并且客户端可以与您的应用程序通信。

请参阅安装部分在您的计算机上安装 Service Weaver，或阅读分步教程部分以获取有关如何编写 Service Weaver 应用程序的教程。

#  安装

确保您已安装 Go 版本 1.21 或更高版本。然后，运行以下命令安装 `weaver` 命令：

```
$ go install github.com/ServiceWeaver/weaver/cmd/weaver@latest
```

`go install` 将 `weaver` 命令安装到 `$GOBIN` ，默认为 `$HOME/go/bin` 。确保此目录包含在您的 `PATH` 中。例如，您可以通过将以下内容添加到 `.bashrc` 并运行 `source ~/.bashrc` 来实现此目的：

```
$ export PATH="$PATH:$HOME/go/bin"
```

如果安装成功，您应该能够运行 `weaver --help` ：

```
$ weaver --help
USAGE

  weaver generate                 // weaver code generator
  weaver version                  // show weaver version
  weaver single    <command> ...  // for single process deployments
  weaver multi     <command> ...  // for multiprocess deployments
  weaver ssh       <command> ...  // for multimachine deployments
  ...
```

注意：对于云部署，您还应该安装 `weaver gke` 或 `weaver kube` 命令（有关详细信息，请参阅 GKE、Kube 部分）：

```
$ go install github.com/ServiceWeaver/weaver-gke/cmd/weaver-gke@latest
$ go install github.com/ServiceWeaver/weaver-kube/cmd/weaver-kube@latest
```

注意：如果您在 macOS 上安装 `weaver` 、 `weaver gke` 或 `weaver kube` 命令时遇到问题，您可能需要在安装命令前加上 `export CGO_ENABLED=1; export CC=gcc` .例如：

```
$ export CGO_ENABLED=1; export CC=gcc; go install github.com/ServiceWeaver/weaver/cmd/weaver@latest
```

# 分步教程

在本节中，我们将向您展示如何编写 Service Weaver 应用程序。要安装 Service Weaver 并按照说明进行操作，请参阅安装部分。可以在此处找到本教程中提供的完整源代码。

##  组件

Service Weaver 的核心抽象是组件。组件就像一个参与者，Service Weaver 应用程序是作为一组组件实现的。具体来说，一个组件用一个常规的Go接口来表示，组件之间通过调用这些接口定义的方法来进行交互。

在本节中，我们将定义一个简单的 `hello` 组件，它仅打印字符串并返回。首先，运行 `go mod init hello` 创建一个 go 模块。

```
$ mkdir hello/
$ cd hello/
$ go mod init hello
```

然后，创建一个名为 `main.go` 的文件，其中包含以下内容：

```
package main

import (
    "context"
    "fmt"
    "log"

    "github.com/ServiceWeaver/weaver"
)

func main() {
    if err := weaver.Run(context.Background(), serve); err != nil {
        log.Fatal(err)
    }
}

// app is the main component of the application. weaver.Run creates
// it and passes it to serve.
type app struct{
    weaver.Implements[weaver.Main]
}

// serve is called by weaver.Run and contains the body of the application.
func serve(context.Context, *app) error {
    fmt.Println("Hello")
    return nil
}
```

`weaver.Run(...)` 初始化并运行 Service Weaver 应用程序。特别是， `weaver.Run` 查找主要组件，创建它，并将其传递给提供的函数。在此示例中， `app` 是主要组件，因为它包含 `weaver.Implements[weaver.Main]` 字段。

在构建和运行应用程序之前，我们需要运行 Service Weaver 的代码生成器，称为 `weaver generate` 。 `weaver generate` 写入一个 `weaver_gen.go` 文件，其中包含 Service Weaver 运行时所需的代码。我们稍后将详细说明 `weaver generate` 的具体用途以及为什么需要运行它。最后，运行应用程序！

```
$ go mod tidy
$ weaver generate .
$ go run .
Hello
```

组件是 Service Weaver 的核心抽象。 Service Weaver 应用程序中的所有代码都作为某个组件的一部分运行。组件的主要优点是它们将编写代码的方式与运行代码的方式分离。它们允许您将应用程序编写为整体，但是当您运行代码时，您可以在单独的进程或完全不同的机器上运行组件。这是说明这个概念的图表：

![A diagram showing off various types of Service Weaver deployments](https://serviceweaver.dev/assets/images/components.svg)

当我们 `go run` 一个Service Weaver应用程序时，所有组件在单个进程中一起运行，并且组件之间的方法调用作为常规Go方法调用执行。稍后，我们将描述如何在单独的进程中运行每个组件，并在作为 RPC 执行的组件之间进行方法调用。

##  多个组件

在 Service Weaver 应用程序中，任何组件都可以调用任何其他组件。为了演示这一点，我们引入第二个 `Reverser` 组件。创建一个包含以下内容的文件 `reverser.go` ：

```
package main

import (
    "context"

    "github.com/ServiceWeaver/weaver"
)

// Reverser component.
type Reverser interface {
    Reverse(context.Context, string) (string, error)
}

// Implementation of the Reverser component.
type reverser struct{
    weaver.Implements[Reverser]
}

func (r *reverser) Reverse(_ context.Context, s string) (string, error) {
    runes := []rune(s)
    n := len(runes)
    for i := 0; i < n/2; i++ {
        runes[i], runes[n-i-1] = runes[n-i-1], runes[i]
    }
    return string(runes), nil
}
```

`Reverser` 组件由 `Reverser` 接口表示，不出所料，该接口具有反转字符串的 `Reverse` 方法。 `reverser` 结构是我们对 `Reverser` 组件的实现（如它包含的 `weaver.Implements[Reverser]` 字段所示）。

接下来，编辑 `main.go` 中的应用程序组件以使用 `Reverser` 组件：

```
package main

import (
    "context"
    "fmt"
    "log"

    "github.com/ServiceWeaver/weaver"
)

func main() {
    if err := weaver.Run(context.Background(), serve); err != nil {
        log.Fatal(err)
    }
}

type app struct{
    weaver.Implements[weaver.Main]
    reverser weaver.Ref[Reverser]
}

func serve(ctx context.Context, app *app) error {
    // Call the Reverse method.
    var r Reverser = app.reverser.Get()
    reversed, err := r.Reverse(ctx, "!dlroW ,olleH")
    if err != nil {
        return err
    }
    fmt.Println(reversed)
    return nil
}
```

`app` 结构有一个 `weaver.Ref[Reverser]` 类型的新字段，可提供对 `Reverser` 组件的访问。

一般来说，如果组件 X 使用组件 Y，则 X 的实现结构应包含 `weaver.Ref[Y]` 类型的字段。创建 X 组件实例时，Service Weaver 也会自动创建 Y 组件，并使用 Y 组件的句柄填充 `weaver.Ref[Y]` 字段。 X 的实现可以在 `weaver.Ref[Y]` 字段上调用  `Get()` 来获取 Y 分量，如前面示例中的以下几行所示：

```
    var r Reverser = app.reverser.Get()
    reversed, err := r.Reverse(ctx, "!dlroW ,olleH")
```

##  Listener

Service Weaver 专为编写服务系统而设计。在本节中，我们将增强我们的应用程序以使用网络侦听器提供 HTTP 流量。使用以下内容重写 `main.go` ：

```
package main

import (
    "context"
    "fmt"
    "log"
    "net/http"

    "github.com/ServiceWeaver/weaver"
)

func main() {
    if err := weaver.Run(context.Background(), serve); err != nil {
        log.Fatal(err)
    }
}

type app struct {
    weaver.Implements[weaver.Main]
    reverser weaver.Ref[Reverser]
    hello    weaver.Listener
}

func serve(ctx context.Context, app *app) error {
    // The hello listener will listen on a random port chosen by the operating
    // system. This behavior can be changed in the config file.
    fmt.Printf("hello listener available on %v\n", app.hello)

    // Serve the /hello endpoint.
    http.HandleFunc("/hello", func(w http.ResponseWriter, r *http.Request) {
        name := r.URL.Query().Get("name")
        if name == "" {
            name = "World"
        }
        reversed, err := app.reverser.Get().Reverse(ctx, name)
        if err != nil {
            http.Error(w, err.Error(), http.StatusInternalServerError)
            return
        }
        fmt.Fprintf(w, "Hello, %s!\n", reversed)
    })
    return http.Serve(app.hello, nil)
}
```

这是代码的解释：

- `app` 结构中的 `hello` 字段声明一个网络侦听器，类似于 `net.Listen` 。
- `http.HandleFunc(...)` 为 `/hello?name=<name>` 端点注册一个 HTTP 处理程序，该处理程序通过调用 `Reverser.Reverse` 方法返回反向问候语。
- `http.Serve(lis, nil)` 在提供的侦听器上运行 HTTP 服务器。

默认情况下，所有应用程序侦听器侦听操作系统选择的随机端口。在这里，我们想要更改此默认行为并为 `hello` 侦听器分配固定的本地侦听器端口。为此，请创建一个名为 `weaver.toml` 的 TOML 配置文件，其中包含以下内容：

```
[single]
listeners.hello = {address = "localhost:12345"}
```

请注意，侦听器的名称（在本例中为 `hello` ）是从字段名称派生的。您可以覆盖此行为并使用 `"weaver"` 字段标记指定特定的侦听器名称，如下所示：

```
type app struct {
    weaver.Implements[weaver.Main]
    reverser weaver.Ref[Reverser]
    hello    weaver.Listener `weaver:"my_custom_listener_name"`
}
```

监听器名称必须是有效的 Go 标识符。例如，名称 `"foo"` 、 `"bar42"` 和 `"_moo"` 是合法的，而 `""` 、 `"foo bar"` 和 `"foo-bar"` 是非法的。

运行 `weaver generate` ，然后运行  `go mod tidy` ，然后运行  `SERVICEWEAVER_CONFIG=weaver.toml go run .` 。该程序应打印出应用程序的名称和唯一的部署 ID。然后它应该阻止在 `localhost:12345` 上提供 HTTP 请求。

```
$ weaver generate
$ go mod tidy
$ go run .
╭───────────────────────────────────────────────────╮
│ app        : hello                                │
│ deployment : 5c9753e4-c476-4f93-97a0-0ea599184178 │
╰───────────────────────────────────────────────────╯
hello listener available on 127.0.0.1:12345
...
```

在单独的终端中，curl 服务器以接收反向问候语：

```
$ curl "localhost:12345/hello?name=Weaver"
Hello, revaeW!
```

运行 `weaver single status` 以查看 Service Weaver 应用程序的状态。状态显示每个部署、组件和侦听器。

```
$ weaver single status
╭────────────────────────────────────────────────────╮
│ DEPLOYMENTS                                        │
├───────┬──────────────────────────────────────┬─────┤
│ APP   │ DEPLOYMENT                           │ AGE │
├───────┼──────────────────────────────────────┼─────┤
│ hello │ 5c9753e4-c476-4f93-97a0-0ea599184178 │ 1s  │
╰───────┴──────────────────────────────────────┴─────╯
╭────────────────────────────────────────────────────╮
│ COMPONENTS                                         │
├───────┬────────────┬────────────────┬──────────────┤
│ APP   │ DEPLOYMENT │ COMPONENT      │ REPLICA PIDS │
├───────┼────────────┼────────────────┼──────────────┤
│ hello │ 5c9753e4   │ main           │ 691625       │
│ hello │ 5c9753e4   │ hello.Reverser │ 691625       │
╰───────┴────────────┴────────────────┴──────────────╯
╭─────────────────────────────────────────────────╮
│ LISTENERS                                       │
├───────┬────────────┬──────────┬─────────────────┤
│ APP   │ DEPLOYMENT │ LISTENER │ ADDRESS         │
├───────┼────────────┼──────────┼─────────────────┤
│ hello │ 5c9753e4   │ hello    │ 127.0.0.1:12345 │
╰───────┴────────────┴──────────┴─────────────────╯
```

您还可以运行 `weaver single dashboard` 在 Web 浏览器中打开仪表板。

## 多进程执行

我们已经了解了如何使用 `go run` 在单个进程中运行 Service Weaver 应用程序。现在，我们将在多个进程中运行应用程序，组件之间的方法调用作为 RPC 执行。首先，创建一个名为 `weaver.toml` 的 TOML 配置文件，其中包含以下内容：

```
[serviceweaver]
binary = "./hello"

[multi]
listeners.hello = {address = "localhost:12345"}
```

此配置文件指定 Service Weaver 应用程序的二进制文件，以及 hello 侦听器的固定地址。接下来，使用 `weaver multi deploy` 构建并运行应用程序：

```
$ go build                        # build the ./hello binary
$ weaver multi deploy weaver.toml # deploy the application
╭───────────────────────────────────────────────────╮
│ app        : hello                                │
│ deployment : 6b285407-423a-46cc-9a18-727b5891fc57 │
╰───────────────────────────────────────────────────╯
S1205 10:21:15.450917 stdout  26b601c4] hello listener available on 127.0.0.1:12345
S1205 10:21:15.454387 stdout  88639bf8] hello listener available on 127.0.0.1:12345
```

注意： `weaver multi` 将每个组件复制两次，这就是您看到两个日志条目的原因。我们稍后将在“组件”部分详细介绍复制。

在单独的终端中，curl 服务器：

```
$ curl "localhost:12345/hello?name=Weaver"
Hello, revaeW!
```

当主组件收到您的 `/hello` HTTP 请求时，它会调用 `reverser.Reverse` 方法。此方法调用作为对运行在不同进程中的 `Reverser` 组件的 RPC 执行。还记得之前我们运行 Service Weaver 代码生成器 `weaver generate` 时的情况吗？ `weaver generate` 所做的一件事是为每个组件生成 RPC 客户端和服务器，以使这种通信成为可能。

运行 `weaver multi status` 以查看 Service Weaver 应用程序的状态。请注意， `main` 和 `Reverser` 组件被复制两次，并且每个副本都在其自己的操作系统进程中运行。

```
$ weaver multi status
╭────────────────────────────────────────────────────╮
│ DEPLOYMENTS                                        │
├───────┬──────────────────────────────────────┬─────┤
│ APP   │ DEPLOYMENT                           │ AGE │
├───────┼──────────────────────────────────────┼─────┤
│ hello │ 6b285407-423a-46cc-9a18-727b5891fc57 │ 3s  │
╰───────┴──────────────────────────────────────┴─────╯
╭──────────────────────────────────────────────────────╮
│ COMPONENTS                                           │
├───────┬────────────┬────────────────┬────────────────┤
│ APP   │ DEPLOYMENT │ COMPONENT      │ REPLICA PIDS   │
├───────┼────────────┼────────────────┼────────────────┤
│ hello │ 6b285407   │ main           │ 695110, 695115 │
│ hello │ 6b285407   │ hello.Reverser │ 695136, 695137 │
╰───────┴────────────┴────────────────┴────────────────╯
╭─────────────────────────────────────────────────╮
│ LISTENERS                                       │
├───────┬────────────┬──────────┬─────────────────┤
│ APP   │ DEPLOYMENT │ LISTENER │ ADDRESS         │
├───────┼────────────┼──────────┼─────────────────┤
│ hello │ 6b285407   │ hello    │ 127.0.0.1:12345 │
╰───────┴────────────┴──────────┴─────────────────╯
```

您还可以运行 `weaver multi dashboard` 在 Web 浏览器中打开仪表板。

## 部署到云端

能够在本地运行 Service Weaver 应用程序（使用 `go run` 在单个进程中运行，或者使用 `weaver multi deploy` 跨多个进程运行），可以轻松快速地开发、调试和测试应用程序。然而，当您的应用程序准备好投入生产时，您通常希望将其部署到云中。 Service Weaver 也让这一切变得简单。

例如，我们可以将“Hello, World”应用程序部署到 Google Kubernetes Engine（Google Cloud 的托管 Kubernetes 产品），就像运行单个命令一样简单（有关详细信息，请参阅 GKE 部分）：

```
$ weaver gke deploy weaver.toml
```

当您运行此命令时，Service Weaver 将

- 将您的应用程序二进制文件包装到容器中；
- 将容器上传到您选择的云项目；
- 创建并配置适当的 Kubernetes 集群；
- 设置所有负载平衡器和网络基础设施；和
- 在 Kubernetes 上部署您的应用程序，组件分布在多个区域的机器上。

Service Weaver 还将您的应用程序与现有的云工具集成。日志上传到 Google Cloud Logging，指标上传到 Google Cloud Monitoring，跟踪上传到 Google Cloud Tracing 等。

##  下一步

- 完成我们 Codelab 中的练习，以获得编写 Service Weaver 应用程序的经验。
- 继续阅读文档以更好地了解组件并了解 Service Weaver 的其他基本功能，例如日志日志、指标、路由等。
-  阅读我们的博客。
- 通读示例 Service Weaver 应用程序，了解 Service Weaver 所提供的功能。
- 深入了解部署 Service Weaver 应用程序的各种方式，包括单进程、多进程、SSH、GKE 和 Kube 部署程序。
- 在 GitHub 上查看 Service Weaver 的源代码。
- 在 Discord 上与我们聊天或给我们发送电子邮件。

#  代码实验室

查看 GitHub 上托管的 Service Weaver Codelab。该 Codelab 包含一组练习（带有解决方案），可引导您完成由 ChatGPT 支持的表情符号搜索引擎应用程序的实现。分步教程部分引导您了解 Service Weaver 的基础知识，代码实验室将这些基础知识付诸实践，为您提供编写成熟的 Service Weaver 应用程序的实践经验。

#  组件

组件是 Service Weaver 的核心抽象。组件是一个长期存在的、可能存在复制的实体，它公开了一组方法。具体来说，组件表示为 Go 接口和该接口的相应实现。例如，考虑以下 `Adder` 组件：

```
type Adder interface {
    Add(context.Context, int, int) (int, error)
}

type adder struct {
    weaver.Implements[Adder]
}

func (*adder) Add(_ context.Context, x, y int) (int, error) {
    return x + y, nil
}
```

`Adder` 定义组件的接口， `adder` 定义组件的实现。两者通过嵌入的 `weaver.Implements[Adder]` 字段链接。您可以调用 `weaver.Ref[Adder].Get()` 来获取 `Adder` 组件的客户端。返回的客户端实现了组件的接口，因此您可以像调用任何常规 Go 方法一样调用组件的方法。当您调用组件的方法时，该方法调用由可能的多个组件副本之一执行。

组件通常寿命较长，但 Service Weaver 运行时可能会根据负载随时间增加或减少组件副本的数量。同样，组件副本可能会失败并重新启动。 Service Weaver 还可以移动组件副本，例如将两个常用组件放在同一操作系统进程中，以便组件之间的通信在本地完成，而不是通过网络进行。

当调用组件的方法时，请做好准备，它可以通过远程过程调用来执行。因此，您的呼叫可能会因网络错误而不是应用程序错误而失败。如果您不想处理网络错误，可以显式地将这两个组件放在同一个主机托管组中，确保它们始终在同一个操作系统进程中运行。

##  接口

组件接口中的每个方法都必须接收 `context.Context` 作为其第一个参数，并返回 `error` 作为其最终结果。所有其他参数必须是可序列化的。这些都是有效的组件方法：

```
a(context.Context) error
b(context.Context, int) error
c(context.Context) (int, error)
d(context.Context, int) (int, error)
```

这些都是无效的组件方法：

```
a() error                          // no context.Context argument
b(context.Context)                 // no error result
c(int, context.Context) error      // first argument isn't context.Context
d(context.Context) (error, int)    // final result isn't error
e(context.Context, chan int) error // chan int isn't serializable
```

##  实施

组件实现必须是一个如下所示的结构：

```
type foo struct{
    weaver.Implements[Foo]
    // ...
}
```

- 它必须是一个结构体。
- 它必须嵌入一个 `weaver.Implements[T]` 字段，其中 `T` 是它实现的组件接口。

如果组件实现实现了 `Init(context.Context) error` 方法，则在创建组件实例时将调用该方法。

```
func (f *foo) Init(context.Context) error {
    // ...
}
```

##  语义

实现组件时，需要记住一些语义细节：

1. 组件的状态不会被持久化。
2. 组件的方法可以同时调用。
3. 一个组件可能有多个副本。
4. 默认情况下，组件方法可能会自动重试。

以下面的 `Cache` 组件为例，它维护内存中的键值缓存。

```
type Cache interface {
    Put(ctx context.Context, key, value string) error
    Get(ctx context.Context, key string) (string, error)
}

type cache struct {
    mu sync.Mutex
    data map[string]string
}

func (c *Cache) Put(_ context.Context, key, value string) error {
    c.mu.Lock()
    defer c.mu.Unlock()
    c.data[key] = value
    return nil
}

func (c *Cache) Get(_ context.Context, key string) (string, error) {
    c.mu.Lock()
    defer c.mu.Unlock()
    return c.data[key], nil
}
```

注意以上几点：

1. `Cache` 的状态不会持久，因此如果 `Cache` 副本失败，其数据就会丢失。任何需要持久化的状态都应该显式地持久化。
2. `Cache` 的方法可以同时调用，因此我们必须使用互斥锁 `mu` 来保护对 `data` 的访问。
3. `Cache` 组件可能有多个副本，因此不能保证一个客户端的 `Get` 将被路由到与另一客户端的 `Put` 相同的副本。对于本示例，这意味着 `Cache` 具有弱一致性。

如果远程方法调用无法正确执行（例如，由于机器崩溃或网络分区），它将返回一个带有嵌入式 `weaver.RemoteCallError` 的错误。这是一个说明性示例：

```
// Call the cache.Get method.
value, err := cache.Get(ctx, "key")
if errors.Is(err, weaver.RemoteCallError) {
    // cache.Get did not execute properly.
} else if err != nil {
    // cache.Get executed properly, but returned an error.
} else {
    // cache.Get executed properly and did not return an error.
}
```

请注意，如果方法调用返回带有嵌入 `weaver.RemoteCallError` 的错误，并不意味着该方法从未执行。由于自动重试，该方法可能已部分执行、全部执行或多次执行。

当出现网络错误时，Service Weaver 可能会自动重试组件方法调用。这可能会导致单个方法调用变成该方法的多次执行。在实践中，许多方法（例如只读或幂等方法）即使每次调用执行多次也能正常工作，并且这种自动重试可以帮助使应用程序在出现故障时更加健壮。

但是，某些方法不应自动重试。例如，如果我们的缓存使用将字符串附加到缓存值的方法进行了扩展，则自动重试可能会导致参数的多个副本附加到缓存值。可以对此类方法进行专门标记，以防止自动重试。

```
type Cache interface{
    ...
    Append(context.Context, key, val string) error
}

// Do not retry Cache.Append.
var _ weaver.NotRetriable = Cache.Append
```

##  Listener

组件实现可能希望使用一个或多个网络监听器，例如，为 HTTP 网络流量提供服务。为此，必须将命名的 `weaver.Listener` 字段添加到实现结构中。例如，以下组件实现创建两个网络侦听器：

```
type impl struct{
    weaver.Implements[MyComponent]
    foo weaver.Listener
    Bar weaver.Listener
}
```

使用 Service Weaver，可以命名侦听器。默认情况下，侦听器以其相应的结构字段命名（例如上例中的 `"foo"` 和 `"bar"` ）。或者，可以将特殊的 `weaver:"name"` 结构标记添加到结构字段以显式指定侦听器名称：

```
type impl struct{
    weaver.Implements[MyComponent]
    foo weaver.Listener
    lis weaver.Listener `weaver:"bar"`
}
```

侦听器名称在给定应用程序二进制文件中必须是唯一的，无论它们是在哪个组件中指定的。例如，在两个不同的组件实现结构中声明侦听器字段 `"foo"` 是非法的，除非使用以下命令重命名一个 `weaver:"name"` 结构标记。

默认情况下，所有应用程序侦听器都将侦听操作系统选择的随机端口。可以在相应部署程序的配置文件中修改此行为以及其他自定义选项。例如，当使用以下命令部署应用程序时，以下配置文件将分别将地址 `"localhost:12345"` 和 `"localhost:12346"` 分配给 `"foo"` 和 `"bar"` 多进程部署器。

```
[multi]
listeners.foo = {address = "localhost:12345"}
listeners.bar = {address = "localhost:12346"}
```

##  配置

Service Weaver 使用以 TOML 编写的配置文件来配置应用程序的运行方式。例如，最小的配置文件仅列出应用程序二进制文件：

```
[serviceweaver]
binary = "./hello"
```

配置文件可能还包含特定于部署程序的配置部分，这些部分允许您在使用给定部署程序时配置执行。例如，当使用多进程部署器部署应用程序时，以下多进程配置将启用组件之间通过 `mTLS` 进行加密的安全通信：

```
[multi]
mtls = true
```

配置文件还可能包含特定于组件的配置部分，允许您在应用程序中配置组件。例如，请考虑以下 `Greeter` 组件。

```
type Greeter interface {
    Greet(context.Context, string) (string, error)
}

type greeter struct {
    weaver.Implements[Greeter]
}

func (g *greeter) Greet(_ context.Context, name string) (string, error) {
    return fmt.Sprintf("Hello, %s!", name), nil
}
```

我们可以在配置文件中提供问候语，而不是对问候语 `"Hello"` 进行硬编码。首先，我们定义一个选项结构。

```
type greeterOptions struct {
    Greeting string
}
```

接下来，我们通过嵌入 `weaver.WithConfig[T]` 结构将选项结构与 `greeter` 实现关联起来。

```
type greeter struct {
    weaver.Implements[Greeter]
    weaver.WithConfig[greeterOptions]
}
```

现在，我们可以将 `Greeter` 部分添加到配置文件中。该部分由组件的完整路径前缀名称作为键控。

```
["example.com/mypkg/Greeter"]
Greeting = "Bonjour"
```

当创建 `Greeter` 组件时，Service Weaver 会自动将配置文件的 `Greeter` 部分解析为 `greeterOptions` 结构体。您可以通过嵌入的 `WithConfig` 结构的 `Config` 方法访问填充的结构。例如：

```
func (g *greeter) Greet(_ context.Context, name string) (string, error) {
    greeting := g.Config().Greeting
    if greeting == "" {
        greeting = "Hello"
    }
    return fmt.Sprintf("%s, %s!", greeting, name), nil
}
```

您可以使用 `toml` 结构标记来指定配置文件中字段的名称。例如，我们可以将 `greeterOptions` 结构更改为以下内容。

```
type greeterOptions struct {
    Greeting string `toml:"my_custom_name"`
}
```

并相应地更改配置文件：

```
["example.com/mypkg/Greeter"]
my_custom_name = "Bonjour"
```

如果直接运行应用程序（即使用 `go run` ），则可以使用 `SERVICEWEAVER_CONFIG` 环境变量传递配置文件：

```
$ SERVICEWEAVER_CONFIG=weaver.toml go run .
```

 或者，使用 `weaver single deploy` ：

```
$ weaver single deploy weaver.toml
```

#  日志

Service Weaver 提供日志日志 API `weaver.Logger` 。通过使用 Service Weaver 的日志日志 API，您可以对每个 Service Weaver 应用程序（过去或现在）的日志进行分类、跟踪、搜索和过滤。 Service Weaver 还将日志集成到部署应用程序的环境中。例如，如果您将 Service Weaver 应用程序部署到 Google Cloud，日志会自动导出到 Google Cloud Logging。

使用组件实现的 `Logger` 方法来获取范围仅限于该组件的日志器。例如：

```
type Adder interface {
    Add(context.Context, int, int) (int, error)
}

type adder struct {
    weaver.Implements[Adder]
}

func (a *adder) Add(ctx context.Context, x, y int) (int, error) {
    // adder embeds weaver.Implements[Adder] which provides the Logger method.
    logger := a.Logger(ctx)
    logger.Debug("A debug log.")
    logger.Info("An info log.")
    logger.Error("An error log.", fmt.Errorf("an error"))
    return x + y, nil
}
```

日志看起来像这样：

```
D1103 08:55:15.650138 main.Adder 73ddcd04 adder.go:12 │ A debug log.
I1103 08:55:15.650149 main.Adder 73ddcd04 adder.go:13 │ An info log.
E1103 08:55:15.650158 main.Adder 73ddcd04 adder.go:14 │ An error log. err="an error"
```

日志行的第一个字符指示日志是 [D]ebug、[I]nfo 还是 [E]rror 日志条目。然后是 `MMDD` 格式的日期，后面是时间。然后是组件名称，后跟逻辑节点 ID。如果两个组件位于同一操作系统进程中，则它们会被赋予相同的节点 ID。然后是生成日志的文件和行，最后是日志的内容。

Service Weaver 还允许您将键值属性附加到日志条目。这些属性在搜索和过滤日志时非常有用。

```
logger.Info("A log with attributes.", "foo", "bar")  // adds foo="bar"
```

如果您发现自己重复添加同一组键值属性，则可以预先创建一个日志器，将这些属性添加到所有日志条目中：

```
fooLogger = logger.With("foo", "bar")
fooLogger.Info("A log with attributes.")  // adds foo="bar"
```

注意：您还可以将普通的打印语句添加到代码中。这些打印将由 Service Weaver 捕获并日志，但它们不会与特定组件关联，它们不会有 `file:line` 信息，并且不会有任何属性，因此我们建议您尽可能使用 `weaver.Logger` 。

```
S1027 14:40:55.210541 stdout d772dcad] This was printed by fmt.Println
```

请参阅特定于部署者的文档，了解如何搜索和过滤单进程、多进程和 GKE 部署的日志。

#  指标

Service Weaver 提供了指标 API；特别是计数器、仪表和直方图。

- 计数器是一个只能随着时间的推移而增加的数字。它永远不会减少。您可以使用计数器来测量诸如程序到目前为止已处理的 HTTP 请求数量等信息。
- 仪表是一个可以随时间增加或减少的数字。您可以使用仪表来测量程序当前使用的内存量（以字节为单位）等信息。
- 直方图是分组到桶中的数字的集合。您可以使用直方图来测量程序迄今为止收到的每个 HTTP 请求的延迟等信息。

Service Weaver 将这些指标集成到部署应用程序的环境中。例如，如果您将 Service Weaver 应用程序部署到 Google Cloud，指标会自动导出到 Google Cloud Metrics Explorer，您可以在其中查询、聚合和绘制图表。

下面是如何向简单的 `Adder` 组件添加指标的示例。

```
var (
    addCount = metrics.NewCounter(
        "add_count",
        "The number of times Adder.Add has been called",
    )
    addConcurrent = metrics.NewGauge(
        "add_concurrent",
        "The number of concurrent Adder.Add calls",
    )
    addSum = metrics.NewHistogram(
        "add_sum",
        "The sums returned by Adder.Add",
        []float64{1, 10, 100, 1000, 10000},
    )
)

type Adder interface {
    Add(context.Context, int, int) (int, error)
}

type adder struct {
    weaver.Implements[Adder]
}

func (*adder) Add(_ context.Context, x, y int) (int, error) {
    addCount.Add(1.0)
    addConcurrent.Add(1.0)
    defer addConcurrent.Sub(1.0)
    addSum.Put(float64(x + y))
    return x + y, nil
}
```

请参阅特定于部署者的文档，了解如何查看单进程、多进程和 GKE 部署的指标。

##  标签

指标还可以有一组键值标签。 Service Weaver 使用结构体表示标签。下面是如何声明和使用带标签的计数器来计算 `Halve` 方法参数的奇偶校验的示例。

```
type halveLabels struct {
    Parity string // "odd" or "even"
}

var (
    halveCounts = metrics.NewCounterMap[halveLabels](
        "halve_count",
        "The number of values that have been halved",
    )
    oddCount = halveCounts.Get(halveLabels{"odd"})
    evenCount = halveCounts.Get(halveLabels{"even"})
)

type Halver interface {
    Halve(context.Context, int) (int, error)
}

type halver struct {
    weaver.Implements[Halver]
}

func (halver) Halve(_ context.Context, val int) (int, error) {
    if val % 2 == 0 {
        evenCount.Add(1)
    } else {
        oddCount.Add(1)
    }
    return val / 2, nil
}
```

为了遵守流行的指标命名约定，Service Weaver 默认情况下会小写每个标签的首字母。例如， `Parity` 字段导出为 `parity` 。您可以覆盖此行为并使用 `weaver` 注释提供自定义标签名称。

```
type labels struct {
    Foo string                           // exported as "foo"
    Bar string `weaver:"my_custom_name"` // exported as "my_custom_name"
}
```

## 自动生成的指标 

Service Weaver 自动创建并维护以下一组指标，这些指标测量每个组件方法调用的计数、延迟和频繁程度。每个指标都由调用组件以及调用的组件和方法以及调用是本地还是远程来标记。

- `serviceweaver_method_count` ：Service Weaver 组件方法调用计数。
- `serviceweaver_method_error_count` ：导致错误的 Service Weaver 组件方法调用计数。
- `serviceweaver_method_latency_micros` ：Service Weaver 组件方法执行的持续时间（以微秒为单位）。
- `serviceweaver_method_bytes_request` ：Service Weaver 远程组件方法请求中的字节数。
- `serviceweaver_method_bytes_reply` ：Service Weaver 远程组件方法回复中的字节数。

##  HTTP 指标

Service Weaver 声明以下一组 HTTP 相关指标。

- `serviceweaver_http_request_count` ：HTTP 请求计数。
- `serviceweaver_http_error_count` ：导致 4XX 或 5XX 响应的 HTTP 请求计数。该指标还标有返回的状态代码。
- `serviceweaver_http_request_latency_micros` ：HTTP 请求执行的持续时间（以微秒为单位）。
- `serviceweaver_http_request_bytes_received` ：HTTP 处理程序接收的估计字节数。
- `serviceweaver_http_request_bytes_returned` ：HTTP 处理程序返回的估计字节数。

如果您将 `http.Handler` 传递给 `weaver.InstrumentHandler` 函数，它将返回一个新的 `http.Handler` ，它会自动更新这些指标，并标有提供的标签。例如：

```
// Metrics are recorded for fooHandler with label "foo".
var mux http.ServeMux
var fooHandler http.Handler = ...
mux.Handle("/foo", weaver.InstrumentHandler("foo", fooHandler))
```

#  追踪

Service Weaver 依靠 OpenTelemetry 来跟踪您的应用程序。 Service Weaver 将这些跟踪导出到部署应用程序的环境中。例如，如果您将 Service Weaver 应用程序部署到 Google Cloud，跟踪信息会自动导出到 Google Cloud Trace。

如果将 `http.Handler` 传递给 `weaver.InstrumentHandler` 函数，它将返回一个新的 `http.Handler` ，每秒跟踪一次 HTTP 请求。

```
// Tracing is enabled for one request every second.
var mux http.ServeMux
var fooHandler http.Handler = ...
mux.Handle("/foo", weaver.InstrumentHandler("foo", fooHandler))
```

或者，您可以使用 OpenTelemetry 库手动启用跟踪：

```
import (
    "context"
    "fmt"
    "log"
    "net/http"

    "go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
    "github.com/ServiceWeaver/weaver"
)

func main() {
    if err := weaver.Run(context.Background(), serve); err != nil {
        log.Fatal(err)
    }
}

type app struct {
    weaver.Implements[weaver.Main]
    lis weaver.Listener
}

func serve(ctx context.Context, app *app) error {
    fmt.Printf("hello listener available on %v\n", app.lis)

    // Serve the /hello endpoint.
    http.HandleFunc("/hello", func(w http.ResponseWriter, r *http.Request) {
        fmt.Fprintf(w, "Hello, %s!\n", r.URL.Query().Get("name"))
    })

    // Create an otel handler to manually enable tracing.
    otelHandler := otelhttp.NewHandler(http.DefaultServeMux, "http")
    return http.Serve(lis, otelHandler)
}
```

无论您是使用 `weaver.InstrumentHandler` 还是手动启用跟踪，一旦为给定 HTTP 请求启用跟踪，该请求和生成的组件方法调用都会被自动跟踪。 Service Weaver 将为您收集并导出痕迹。请参阅单进程、多进程和 GKE 的特定于部署者的文档，了解特定于部署者的导出器。

上述步骤是开始追踪所需的全部步骤。如果要向跟踪添加更多特定于应用程序的详细信息，可以使用传递给已注册 HTTP 处理程序和组件方法的上下文来添加属性、事件和错误。例如，在我们的 `hello` 示例中，您可以按如下方式添加事件：

```
http.HandleFunc("/hello", func(w http.ResponseWriter, r *http.Request) {
    fmt.Fprintf(w, "Hello, %s!\n", r.URL.Query().Get("name"))
    trace.SpanFromContext(r.Context()).AddEvent("writing response",
        trace.WithAttributes(
            label.String("content", "hello "),
            label.String("answer", r.URL.Query().Get("name")),
        ))
})
```

请参阅 OpenTelemetry Go：您需要了解的一切，以了解有关如何向跟踪添加更多特定于应用程序的详细信息的更多信息。

#  Profile

Service Weaver 允许您分析整个 Service Weaver 应用程序，甚至是跨多台计算机的多个进程中部署的应用程序。 Service Weaver 对每个单独的二进制文件进行分析，并将它们聚合到单个配置文件中，以捕获整个应用程序的性能。请参阅特定于部署者的文档，详细了解如何收集单进程、多进程和 GKE 部署的配置文件。

#  路由

默认情况下，当客户端调用远程组件的方法时，该方法调用将由任意选择的可能的多个组件副本之一执行。有时，根据提供给方法的参数将方法调用路由到特定副本是有益的。例如，考虑一个 `Cache` 组件，它在底层磁盘支持的键值存储前面维护内存中缓存：

```
type Cache interface {
    Get(ctx context.Context, key string) (string, error)
    Put(ctx context.Context, key, value string) error
}

type cache struct {
    weaver.Implements[Cache]
    // ...
}
```

为了提高缓存命中率，我们可能希望将给定键的每个请求路由到同一个副本。 Service Weaver 通过允许应用程序指定与组件实现关联的路由器类型来支持这种基于关联的路由。例如：

```
type cacheRouter struct{}
func (cacheRouter) Get(_ context.Context, key string) string { return key }
func (cacheRouter) Put(_ context.Context, key, value string) string { return key }
```

对于需要路由的每个组件方法（例如， `Get` 和 `Put` ），路由器类型应该实现一个等效方法（即相同的名称和参数类型），其返回类型为路由键。当调用组件的路由方法时，会调用其相应的路由器方法来生成路由键。产生相同密钥的方法调用将被路由到相同的副本。

路由键可以是

- 任何整数（例如 `int` 、 `int32` ）、浮点数（即 `float32` 、 `float64` ）或字符串；或者
- 可以选择嵌入 `weaver.AutoMarshal` 的结构，并且所有剩余字段必须是整数、浮点数或字符串。 （例如 `struct{weaver.AutoMarshal; x int; y string}` 、 `struct{x int; y string}` 等）

每个路由器方法必须返回相同的路由键类型。例如，以下内容是无效的：

```
// ERROR: Get returns a string, but Put returns an int.
func (cacheRouter) Get(_ context.Context, key string) string { return key }
func (cacheRouter) Put(_ context.Context, key, value string) int { return 42 }
```

要将路由器与其组件关联起来，请在组件实现中嵌入 `weaver.WithRouter[T]` 字段，其中 `T` 是路由器的类型。

```
type cache struct {
    weaver.Implements[Cache]
    weaver.WithRouter[cacheRouter]
    // ...
}
```

注意：路由是在尽力而为的基础上完成的。 Service Weaver 将尝试将具有相同密钥的方法调用路由到同一个副本，但这并不能保证。因此，您永远不应该依赖路由来保证正确性。仅在常见情况下使用路由来提高性能。

另请注意，如果组件调用位于同一位置的组件上的方法，则该方法调用将始终由位于同一位置的组件执行，并且不会被路由。

#  储存

我们希望大多数 Service Weaver 应用程序以某种方式保留其数据。例如，电子商务应用程序可以将其产品目录和用户信息存储在数据库中，并在服务用户请求时访问它们。

默认情况下，Service Weaver 将应用程序数据的存储和检索留给开发人员。例如，如果您使用数据库，则必须创建数据库、预先填充数据，并编写代码以从 Service Weaver 应用程序访问数据库。

下面是如何使用配置文件将数据库信息传递到简单的 `Adder` 组件的示例。首先，配置文件：

```
["example.com/mypkg/Adder"]
Driver = "mysql"
Source = "root:@tcp(localhost:3306)/"
```

以及使用它的应用程序：

```
type Adder interface {
    Add(context.Context, int, int) (int, error)
}

type adder struct {
    weaver.Implements[Adder]
    weaver.WithConfig[config]

    db *sql.DB
}

type config struct {
    Driver string // Name of the DB driver.
    Source string // DB data source.
}

func (a *adder) Init(_ context.Context) error {
    db, err := sql.Open(a.Config().Driver, a.Config().Source)
    a.db = db
    return err
}

func (a *Adder) Add(ctx context.Context, x, y int) (int, error) {
    // Check in the database first.
    var sum int
    const q = "SELECT sum FROM table WHERE x=? AND y=?;"
    if err := a.db.QueryRowContext(ctx, q, x, y).Scan(&sum); err == nil {
        return sum, nil
    }

    // Make a best-effort attempt to store in the database.
    q = "INSERT INTO table(x, y, sum) VALUES (?, ?, ?);"
    a.db.ExecContext(ctx, q, x, y, x + y)
    return x + y, nil
}
```

可以遵循类似的过程来使用 Go 标志或环境变量传递数据库信息。

#  测试

Service Weaver 包含一个 `weavertest` 包，您可以使用它来测试您的 Service Weaver 应用程序。该包提供了带有 `Test` 和 `Bench` 方法的 `Runner` 类型。测试使用 `Runner.Test` 而不是 `weaver.Run` 。例如，要使用 `Add` 方法测试 `Adder` 组件，请创建一个包含以下内容的 `adder_test.go` 文件。

```
package main

import (
    "context"
    "testing"

    "github.com/ServiceWeaver/weaver"
    "github.com/ServiceWeaver/weaver/weavertest"
)

func TestAdd(t *testing.T) {
     runner := weavertest.Local  // A runner that runs components in a single process
     runner.Test(t, func(t *testing.T, adder Adder) {
         ctx := context.Background()
         got, err := adder.Add(ctx, 1, 2)
         if err != nil {
             t.Fatal(err)
         }
         if want := 3; got != want {
             t.Fatalf("got %q, want %q", got, want)
         }
     })
}
```

运行 `go test` 来运行测试。 `runner.Test` 将创建一个子测试，并在其中创建一个 `Adder` 组件并将其传递给提供的函数。如果要测试组件的实现而不是其接口，请指定指向实现结构的指针作为参数。例如，如果 `adderImpl` 结构实现了 `Adder` 接口，我们可以编写以下内容：

```
runner.Test(t, func(t *testing.T, adder *adderImpl) {
    // Test adder...
})
```

想要运用多个组件的测试可以传递一个函数，每个组件都有一个单独的参数。每个组件都将被创建并传递给函数。每个参数可以是组件接口或指向组件实现的指针。

```
func TestArithmetic(t *testing.T) {
    weavertest.Local.Test(t, func(t *testing.T, adder *adderImpl, multiplier Multiplier) {
        // ...
    })
}
```

##  Runner

`weavertest` 提供了一组内置的 Runner，它们的不同之处在于它们如何跨进程划分组件以及组件之间如何通信：

1. weavertest.Local：每个组件都会被放置在测试进程中，并且所有组件方法调用都将使用本地过程调用，发生在您 `go run` 一个Service Weaver应用程序时。
2. weavertest.Multi：每个组件都会被放置在不同的进程中。这与运行 `weaver multi deploy` 时发生的情况类似。
3. weavertest.RPC：每个组件都会被放入测试进程中，但所有组件方法调用都将使用远程，即使被调用者是本地的。此模式在收集配置文件或覆盖范围数据时最有用。

使用 `weavertest.Local` 运行的测试更容易调试和排除故障，但不测试分布式执行。您应该使用不同的跑步者进行测试，以获得两全其美的效果（每个 Runner.Test 调用将创建一个新的子测试）：

```
func TestAdd(t *testing.T) {
    for _, runner := range weavertest.AllRunners() {
        runner.Test(t, func(t *testing.T, adder Adder) {
            // ...
        })
    }
}
```

##  Fake

您可以使用 `weavertest.Fake` 在测试中用假实现替换组件实现。下面是一个示例，我们将 `Clock` 组件的真实实现替换为始终返回固定时间的虚假实现。

```
// fakeClock is a fake implementation of the Clock component.
type fakeClock struct {
    now int64
}

// Now implements the Clock component interface. It returns the current time, in
// microseconds, since the unix epoch.
func (f *fakeClock) Now(context.Context) (int64, error) {
    return f.now, nil
}

func TestClock(t *testing.T) {
    for _, runner := range weavertest.AllRunners() {
        // Register a fake Clock implementation with the runner.
        fake := &fakeClock{100}
        runner.Fakes = append(runner.Fakes, weavertest.Fake[Clock](fake))

        // When a fake is registered for a component, all instances of that
        // component dispatch to the fake.
        runner.Test(t, func(t *testing.T, clock Clock) {
            now, err := clock.UnixMicro(context.Background())
            if err != nil {
                t.Fatal(err)
            }
            if now != 100 {
                t.Fatalf("bad time: got %d, want %d", now, 100)
            }

            fake.now = 200
            now, err = clock.UnixMicro(context.Background())
            if err != nil {
                t.Fatal(err)
            }
            if now != 200 {
                t.Fatalf("bad time: got %d, want %d", now, 200)
            }
        })
    }
}
```

##  配置

您还可以通过设置 `Runner.Config` 字段向运行器提供配置文件的内容：

```
func TestArithmetic(t *testing.T) {
    runner := weavertest.Local()
    runner.Name = "Custom"
    runner.Config = `[serviceweaver] ...`
    runner.Test(t, func(t *testing.T, adder Adder, multiplier Multiplier) {
        // ...
    })
}
```

#  版本控制

服务系统随着时间的推移而发展。无论您是修复错误还是添加新功能，您都不可避免地必须推出系统的新版本来替换当前运行的版本。为了保持系统的可用性，人们通常会执行滚动更新，即部署中的节点从旧版本一一更新到新版本。

在滚动更新期间，运行旧版本代码的节点必须与运行新版本代码的其他节点进行通信。尽管存在这些跨版本交互的可能性，但确保系统正确是非常具有挑战性的。在了解和检测分布式系统中的软件升级失败中，Zhang 等人。对 8 个广泛使用的系统中 123 个失败的更新进行案例研究。他们发现大多数故障是由系统多个版本之间的交互引起的：

> *大约三分之二的更新失败是由数据语法或语义假设不兼容的两个软件版本之间的交互引起的。*

Service Weaver 采用不同的方法来部署并回避这些复杂的跨版本交互。 Service Weaver 确保客户端请求完全在单一版本的系统中执行。一个版本中的组件永远不会与不同版本中的组件进行通信。这消除了更新失败的主要原因，使您能够安全、轻松地推出 Service Weaver 应用程序的新版本。

对于使用 `go run` 或 `weaver multi deploy` 部署的应用程序来说，避免跨版本通信是微不足道的，因为每个部署都彼此独立运行。请参阅 GKE 部署和 GKE 版本控制部分，了解 Service Weaver 如何结合使用蓝/绿部署和自动扩展，将流量从在 GKE 上运行的旧版本 Service Weaver 应用缓慢转移到新版本，从而避免跨版本通信以资源有效利用的方式。

#  单一进程

##  开始使用

部署 Service Weaver 应用程序的最简单方法是直接通过 `go run` 运行它。当您 `go run` Service Weaver 应用程序时，每个组件都位于单个进程中，并且组件之间的方法调用将作为常规 Go 方法调用执行。有关完整示例，请参阅分步教程部分。

```
$ go run .
```

如果您使用 `go run` 运行应用程序，则可以使用 `SERVICEWEAVER_CONFIG` 环境变量提供配置文件：

```
$ SERVICEWEAVER_CONFIG=weaver.toml go run .
```

或者，您可以使用 `weaver single deploy` 命令。 `weaver single deploy` 实际上与 `go run .` 相同，但它使提供配置文件变得更容易。

```
$ weaver single deploy weaver.toml
```

您可以运行 `weaver single status` 来查看使用 `go run` 部署的所有活动 Service Weaver 应用程序的状态。

```
$ weaver single status
╭────────────────────────────────────────────────────╮
│ DEPLOYMENTS                                        │
├───────┬──────────────────────────────────────┬─────┤
│ APP   │ DEPLOYMENT                           │ AGE │
├───────┼──────────────────────────────────────┼─────┤
│ hello │ a4bba25b-6312-4af1-beec-447c33b8e805 │ 26s │
│ hello │ a4d4c71b-a99f-4ade-9586-640bd289158f │ 19s │
│ hello │ bc663a25-c70e-440d-b022-04a83708c616 │ 12s │
╰───────┴──────────────────────────────────────┴─────╯
╭─────────────────────────────────────────────────────╮
│ COMPONENTS                                          │
├───────┬────────────┬─────────────────┬──────────────┤
│ APP   │ DEPLOYMENT │ COMPONENT       │ REPLICA PIDS │
├───────┼────────────┼─────────────────┼──────────────┤
│ hello │ a4bba25b   │ main            │ 123450       │
│ hello │ a4bba25b   │ hello.Reverser  │ 123450       │
│ hello │ a4d4c71b   │ main            │ 903510       │
│ hello │ a4d4c71b   │ hello.Reverser  │ 903510       │
│ hello │ bc663a25   │ main            │ 489102       │
│ hello │ bc663a25   │ hello.Reverser  │ 489102       │
╰───────┴────────────┴─────────────────┴──────────────╯
╭────────────────────────────────────────────╮
│ LISTENERS                                  │
├───────┬────────────┬──────────┬────────────┤
│ APP   │ DEPLOYMENT │ LISTENER │ ADDRESS    │
├───────┼────────────┼──────────┼────────────┤
│ hello │ a4bba25b   │ hello    │ [::]:33541 │
│ hello │ a4d4c71b   │ hello    │ [::]:41619 │
│ hello │ bc663a25   │ hello    │ [::]:33319 │
╰───────┴────────────┴──────────┴────────────╯
```

您还可以运行 `weaver single dashboard` 在 Web 浏览器中打开仪表板。

##  Listener

您可以将 `weaver.Listener` 字段添加到组件实现中以触发网络侦听器的创建（有关上下文，请参阅分步教程部分）。

```
type app struct {
    weaver.Implements[weaver.Main]
    hello    weaver.Listener
}
```

当您使用 `go run` 部署应用程序时，Service Weaver 运行时将自动创建网络侦听器。每个侦听器将侦听操作系统选择的随机端口，除非在配置文件的 singleprocess 部分中指定了具体地址，例如：

```
[single]
listeners.hello = { address = "localhost:12345" }
```

##  日志

当您使用 `go run` 部署 Service Weaver 应用程序时，日志将打印到标准输出。这些日志不会被持久化。您可以选择保存日志以供以后使用基本 shell 结构进行分析：

```
$ go run . | tee mylogs.txt
```

##  指标

运行 `weaver single dashboard` 以在 Web 浏览器中打开仪表板。对于通过 `go run .` 部署的每个 Service Weaver 应用程序，仪表板都有一个页面。每个部署的页面都有一个指向部署指标的链接。指标以 Prometheus 格式导出，如下所示：

```
# Metrics in Prometheus text format [1].
#
# To visualize and query the metrics, make sure Prometheus is installed on
# your local machine and then add the following stanza to your Prometheus yaml
# config file:
#
# scrape_configs:
# - job_name: 'prometheus-serviceweaver-scraper'
#   scrape_interval: 5s
#   metrics_path: /debug/serviceweaver/prometheus
#   static_configs:
#     - targets: ['127.0.0.1:43087']
#
# [1]: https://prometheus.io

# HELP example_count An example counter.
# TYPE example_count counter
example_count{serviceweaver_node="bbc9beb5"} 42
example_count{serviceweaver_node="00555c38"} 9001

# ┌─────────────────────────────────────┐
# │ SERVICEWEAVER AUTOGENERATED METRICS │
# └─────────────────────────────────────┘
# HELP serviceweaver_method_count Count of Service Weaver component method invocations
# TYPE serviceweaver_method_count counter
serviceweaver_method_count{caller="main",component="main.Example",serviceweaver_node="9fa07495",method="Foo"} 0
serviceweaver_method_count{caller="main",component="main.Example",serviceweaver_node="ee76816d",method="Foo"} 1
...
```

正如标题所解释的，您可以通过安装 Prometheus 并使用提供的节对其进行配置来可视化和查询指标，以定期抓取所提供目标的 `/debug/serviceweaver/prometheus` 端点（上面的例子）。您还可以手动检查指标。指标页面显示应用程序中每个指标的最新值，后面是 Service Weaver 自动为您创建的指标。

##  Profile

使用 `weaver single profile` 命令收集 Service Weaver 应用程序的配置文件。使用您的部署 ID 调用该命令。例如，假设您 `go run` Service Weaver 应用程序，它获得一个部署 ID `28807368-1101-41a3-bdcb-9625e0f02ca0` 。

```
$ go run .
╭───────────────────────────────────────────────────╮
│ app        : hello                                │
│ deployment : 28807368-1101-41a3-bdcb-9625e0f02ca0 │
╰───────────────────────────────────────────────────╯
```

在单独的终端中，您可以运行 `weaver single profile` 命令。

```
$ weaver single profile 28807368               # Collect a CPU profile.
$ weaver single profile --duration=1m 28807368 # Adjust the duration of the profile.
$ weaver single profile --type=heap 28807368   # Collect a heap profile.
```

`weaver single profile` 打印出收集的配置文件的文件名。您可以使用 `go tool pprof` 命令来可视化和分析配置文件。例如：

```
$ profile=$(weaver single profile <deployment>) # Collect the profile.
$ go tool pprof -http=localhost:9000 $profile   # Visualize the profile.
```

请参阅 `weaver single profile --help` 了解更多详情。有关如何使用 pprof 分析您的配置文件的更多信息，请参阅 `go tool pprof --help` 。有关教程，请参阅分析 Go 程序。

##  追踪

运行 `weaver single dashboard` 以在 Web 浏览器中打开仪表板。对于通过 `go run .` 部署的每个 Service Weaver 应用程序，仪表板都有一个页面。每个部署的页面都有一个指向可通过 Perfetto 访问的部署跟踪的链接。以下是跟踪页面的示例：

![An example trace page](https://serviceweaver.dev/assets/images/trace_single.png)

请参阅 Perfetto UI 文档，了解有关如何使用跟踪 UI 的更多信息。

#  多进程

##  开始使用

您可以使用 `weaver multi` 在本地计算机上跨多个进程部署 Service Weaver 应用程序，每个组件副本都在单独的操作系统进程中运行。创建一个配置文件，例如 `weaver.toml` ，它指向已编译的 Service Weaver 应用程序。

```
[serviceweaver]
binary = "./your_compiled_serviceweaver_binary"
```

使用 `weaver multi deploy` 部署应用程序：

```
$ weaver multi deploy weaver.toml
```

有关完整示例，请参阅分步教程部分。

当 `weaver multi deploy` 终止时（例如，当您按 `ctrl+c` 时），应用程序将被销毁，所有进程都将终止。

您可以运行 `weaver multi status` 来查看使用 `weaver multi` 部署的所有活动 Service Weaver 应用程序的状态。

```
$ weaver multi status
╭────────────────────────────────────────────────────╮
│ DEPLOYMENTS                                        │
├───────┬──────────────────────────────────────┬─────┤
│ APP   │ DEPLOYMENT                           │ AGE │
├───────┼──────────────────────────────────────┼─────┤
│ hello │ a4bba25b-6312-4af1-beec-447c33b8e805 │ 26s │
│ hello │ a4d4c71b-a99f-4ade-9586-640bd289158f │ 19s │
│ hello │ bc663a25-c70e-440d-b022-04a83708c616 │ 12s │
╰───────┴──────────────────────────────────────┴─────╯
╭───────────────────────────────────────────────────────╮
│ COMPONENTS                                            │
├───────┬────────────┬─────────────────┬────────────────┤
│ APP   │ DEPLOYMENT │ COMPONENT       │ REPLICA PIDS   │
├───────┼────────────┼─────────────────┼────────────────┤
│ hello │ a4bba25b   │ main            │ 695110, 695115 │
│ hello │ a4bba25b   │ hello.Reverser  │ 193720, 398751 │
│ hello │ a4d4c71b   │ main            │ 847020, 292745 │
│ hello │ a4d4c71b   │ hello.Reverser  │ 849035, 897452 │
│ hello │ bc663a25   │ main            │ 245702, 157455 │
│ hello │ bc663a25   │ hello.Reverser  │ 997520, 225023 │
╰───────┴────────────┴─────────────────┴────────────────╯
╭────────────────────────────────────────────╮
│ LISTENERS                                  │
├───────┬────────────┬──────────┬────────────┤
│ APP   │ DEPLOYMENT │ LISTENER │ ADDRESS    │
├───────┼────────────┼──────────┼────────────┤
│ hello │ a4bba25b   │ hello    │ [::]:33541 │
│ hello │ a4d4c71b   │ hello    │ [::]:41619 │
│ hello │ bc663a25   │ hello    │ [::]:33319 │
╰───────┴────────────┴──────────┴────────────╯
```

您还可以运行 `weaver multi dashboard` 在 Web 浏览器中打开仪表板。

##  Listener

您可以将 `weaver.Listener` 字段添加到组件实现中以触发网络侦听器的创建（有关上下文，请参阅分步教程部分）。

```
type app struct {
    weaver.Implements[weaver.Main]
    hello    weaver.Listener
}
```

当您使用 `weaver multi deploy` 部署应用程序时，Service Weaver 运行时将自动创建网络侦听器。特别是，对于应用程序二进制文件中指定的每个侦听器，运行时：

1. 创建一个本地主机网络侦听器，侦听操作系统选择的随机端口（即侦听 `localhost:0` ）。
2. 确保创建 HTTP 代理。该代理将流量转发到侦听器。事实上，代理平衡侦听器的每个副本之间的流量。 （回想一下，组件可以被复制，因此每个组件副本都将具有不同的侦听器实例。）

代理地址默认为 `:0` ，除非在配置文件的多进程部分中指定了具体地址，例如：

```
[multi]
listeners.hello = { address = "localhost:12345" }
```

##  日志

`weaver multi deploy` 日志到标准输出。它还将所有日志条目保存在 `/tmp/serviceweaver/logs/weaver-multi` 中的一组文件中。每个文件都包含编码为协议缓冲区的日志条目流。您可以使用 `weaver multi logs` 来分类、关注和过滤这些日志。例如：

```
# Display all of the application logs
weaver multi logs

# Follow all of the logs (similar to tail -f).
weaver multi logs --follow

# Display all of the logs for the "todo" app.
weaver multi logs 'app == "todo"'

# Display all of the debug logs for the "todo" app.
weaver multi logs 'app=="todo" && level=="debug"'

# Display all of the logs for the "todo" app in files called foo.go.
weaver multi logs 'app=="todo" && source.contains("foo.go")'

# Display all of the logs that contain the string "error".
weaver multi logs 'msg.contains("error")'

# Display all of the logs that match a regex.
weaver multi logs 'msg.matches("error: file .* already closed")'

# Display all of the logs that have an attribute "foo" with value "bar".
weaver multi logs 'attrs["foo"] == "bar"'

# Display all of the logs in JSON format. This is useful if you want to
# perform some sort of post-processing on the logs.
weaver multi logs --format=json

# Display all of the logs, including internal system logs that are hidden by
# default.
weaver multi logs --system
```

有关查询语言的完整说明以及更多示例，请参阅 `weaver multi logs --help` 。

##  指标

运行 `weaver multi dashboard` 以在 Web 浏览器中打开仪表板。对于通过 `weaver muli deploy` 部署的每个 Service Weaver 应用程序，仪表板都有一个页面。每个部署的页面都有一个指向部署指标的链接。指标以 Prometheus 格式导出，如下所示：

```
# Metrics in Prometheus text format [1].
#
# To visualize and query the metrics, make sure Prometheus is installed on
# your local machine and then add the following stanza to your Prometheus yaml
# config file:
#
# scrape_configs:
# - job_name: 'prometheus-serviceweaver-scraper'
#   scrape_interval: 5s
#   metrics_path: /debug/serviceweaver/prometheus
#   static_configs:
#     - targets: ['127.0.0.1:43087']
#
#
# [1]: https://prometheus.io

# HELP example_count An example counter.
# TYPE example_count counter
example_count{serviceweaver_node="bbc9beb5"} 42
example_count{serviceweaver_node="00555c38"} 9001

# ┌─────────────────────────────────────┐
# │ SERVICEWEAVER AUTOGENERATED METRICS │
# └─────────────────────────────────────┘
# HELP serviceweaver_method_count Count of Service Weaver component method invocations
# TYPE serviceweaver_method_count counter
serviceweaver_method_count{caller="main",component="main.Example",serviceweaver_node="9fa07495",method="Foo"} 0
serviceweaver_method_count{caller="main",component="main.Example",serviceweaver_node="ee76816d",method="Foo"} 1
...
```

正如标题所解释的，您可以通过安装 Prometheus 并使用提供的节对其进行配置来可视化和查询指标，以定期抓取所提供目标的 `/debug/serviceweaver/prometheus` 端点（例如 `127.0.0.1:43087` ）。您还可以手动检查指标。指标页面显示应用程序中每个指标的最新值，后面是 Service Weaver 自动为您创建的指标。

##  Profile

使用 `weaver multi profile` 命令收集 Service Weaver 应用程序的配置文件。使用您的部署 ID 调用该命令。例如，假设您 `weaver multi deploy` Service Weaver 应用程序，它获得一个部署 ID `28807368-1101-41a3-bdcb-9625e0f02ca0` 。

```
$ weaver multi deploy weaver.toml
╭───────────────────────────────────────────────────╮
│ app        : hello                                │
│ deployment : 28807368-1101-41a3-bdcb-9625e0f02ca0 │
╰───────────────────────────────────────────────────╯
```

在单独的终端中，您可以运行 `weaver multi profile` 命令。

```
$ weaver multi profile 28807368               # Collect a CPU profile.
$ weaver multi profile --duration=1m 28807368 # Adjust the duration of the profile.
$ weaver multi profile --type=heap 28807368   # Collect a heap profile.
```

`weaver multi profile` 打印出收集的配置文件的文件名。您可以使用 `go tool pprof` 命令来可视化和分析配置文件。例如：

```
$ profile=$(weaver multi profile <deployment>) # Collect the profile.
$ go tool pprof -http=localhost:9000 $profile # Visualize the profile.
```

请参阅 `weaver multi profile --help` 了解更多详情。有关如何使用 pprof 分析您的配置文件的更多信息，请参阅 `go tool pprof --help` 。有关教程，请参阅分析 Go 程序。

##  追踪

运行 `weaver multi dashboard` 以在 Web 浏览器中打开仪表板。对于通过 `weaver multi deploy` 部署的每个 Service Weaver 应用程序，仪表板都有一个页面。每个部署的页面都有一个指向可通过 Perfetto 访问的部署跟踪的链接。以下是跟踪页面的示例：

![An example trace page](https://serviceweaver.dev/assets/images/trace_multi.png)

跟踪事件按共置组及其相应的副本进行分组。每个事件都有一个与之关联的标签，具体取决于事件是由本地调用还是远程调用引起的。请注意，用户可以通过单击事件的 `traceID` 并选择 `Find slices with the same arg value` 来过滤特定跟踪的事件集。

请参阅 Perfetto UI 文档，了解有关如何使用跟踪 UI 的更多信息。

#  Kube

Kube 是一个部署程序，允许您在任何 Kubernetes 环境（即 GKE、EKS、AKS、minikube 等）中运行 Service Weaver 应用程序。

 特征：

- 您可以控制如何运行应用程序（例如，资源要求、扩展规范、卷）。
- 您决定如何导出遥测数据（例如，对 Jaeger 的跟踪、对 Prometheus 的指标、编写自定义插件）。
- 您可以使用现有工具来部署应用程序（例如 kubectl、CI/CD 管道，如 Github Actions、Argo CD 或 Jenkins）。

##  概览

下图显示了 `Kube` 部署程序的高级概述。用户提供应用程序二进制文件和配置文件 `config.yaml` 。部署者为应用程序构建容器镜像，并生成使应用程序能够在 Kubernetes 集群中运行的 Kubernetes 资源。

![Kube Overview](https://serviceweaver.dev/assets/images/kube_overview.png)

最后，用户可以使用 kubectl 或 CI/CD 管道来部署应用程序。

```
$ kubectl apply -f deployment.yaml
```

请注意，生成的 Kubernetes 资源将用户提供的信息封装在 `config.yaml` 中。例如，用户可以将组件并置到组中（[ `Foo` 、 `Bar` ]），指定运行 pod 的资源要求、最小和最大副本、挂载卷等。更多详细信息请参阅配置选项在这里。

默认情况下， `Kube` 部署程序将日志导出到 `stdout` 并丢弃指标和跟踪。要自定义如何导出遥测数据，您必须使用 `Kube` 插件 API 来注册包含如何导出日志、指标和跟踪的实现的插件。以下是如何将指标导出到 Prometheus 并将跟踪导出到 Jaeger 的示例。有关如何编写插件的更多详细信息请参见此处。

请注意， `Kube` 部署程序允许您在单个区域中部署 Service Weaver 应用程序。

##  安装

首先，确保您安装了 Service Weaver。接下来，安装 Docker 和 kubectl。最后，安装 `weaver-kube` 命令：

```
$ go install github.com/ServiceWeaver/weaver-kube/cmd/weaver-kube@latest
```

注意：在尝试使用 `Kube` 部署程序进行部署之前，请确保您已创建 Kubernetes 集群。

##  开始使用

再考虑一下“你好，世界！”分步教程部分中的 Service Weaver 应用程序。该应用程序在名为 `hello` 的侦听器上运行 HTTP 服务器，并使用返回 `Hello, <name>!` 问候语的 `/hello?name=<name>` 端点。要在 Kubernetes 上部署此应用程序，首先创建一个 Service Weaver 应用程序配置文件，例如 `weaver.toml` ，其中包含以下内容：

```
[serviceweaver]
binary = "./hello"
```

配置文件的 `[serviceweaver]` 部分指定已编译的 Service Weaver 二进制文件。

然后，创建一个 `Kube` 配置文件，例如 `config.yaml` ，其中包含以下内容：

```
appConfig: weaver.toml
repo: docker.io/mydockerid

listeners:
  - name: hello
    public: true
```

`Kube` 配置文件包含指向应用程序配置文件的指针。它还声明应用程序应导出的侦听器列表，以及哪些侦听器应该是公共的，即哪些侦听器应该可以从公共互联网访问。默认情况下，所有侦听器都是私有的，即只能从集群的内部网络访问。在我们的示例中，我们声明 `hello` 侦听器是公共的。

使用 `weaver kube deploy` 部署应用程序：

```
$ go build .
$ weaver kube deploy config.yaml
...
Building image hello:ffa65856...
...
Uploading image to docker.io/mydockerid/...
...
Generating kube deployment info ...
...
kube deployment information successfully generated
/tmp/kube_ffa65856.yaml
```

`/tmp/kube_ffa65856.yaml` 包含为“Hello, World!”生成的 Kubernetes 资源。应用。

```
# Listener Service for group github.com/ServiceWeaver/weaver/Main
apiVersion: v1
kind: Service
spec:
  type: LoadBalancer
...

---
# Deployment for group github.com/ServiceWeaver/weaver/Main
apiVersion: apps/v1
kind: Deployment
...

---
# Autoscaler for group github.com/ServiceWeaver/weaver/Main
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
...

---
# Deployment for group github.com/ServiceWeaver/weaver/examples/hello/Reverser
apiVersion: apps/v1
kind: Deployment
...

---
# Autoscaler for group github.com/ServiceWeaver/weaver/examples/hello/Reverser
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
...
```

您可以简单地部署 `/tmp/kube_ffa65856.yaml` ，如下所示：

```
$ kubectl apply -f /tmp/kube_ffa65856.yaml

role.rbac.authorization.k8s.io/pods-getter created
rolebinding.rbac.authorization.k8s.io/default-pods-getter created
configmap/config-ffa65856 created
service/hello-ffa65856 created
deployment.apps/weaver-main-ffa65856-acfd658f created
horizontalpodautoscaler.autoscaling/weaver-main-ffa65856-acfd658f created
deployment.apps/hello-reverser-ffa65856-58d0b71e created
horizontalpodautoscaler.autoscaling/hello-reverser-ffa65856-58d0b71e created
```

要查看您的应用程序是否已部署，您可以运行 `kubectl get all` 。

```
$ kubectl get all

NAME                                                   READY   STATUS    RESTARTS   AGE
pod/hello-reverser-ffa65856-58d0b71e-5c96fb875-zsjrb   1/1     Running   0          4m
pod/weaver-main-ffa65856-acfd658f-86684754b-w94vc      1/1     Running   0          4m

NAME                     TYPE           CLUSTER-IP       EXTERNAL-IP      PORT(S)        AGE
service/hello-ffa65856   LoadBalancer   10.103.133.111   10.103.133.111   80:30410/TCP   4m1s

NAME                                               READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/hello-reverser-ffa65856-58d0b71e   1/1     1            1           4m1s
deployment.apps/weaver-main-ffa65856-acfd658f      1/1     1            1           4m1s

NAME                                                         DESIRED   CURRENT   READY   AGE
replicaset.apps/hello-reverser-ffa65856-58d0b71e-5c96fb875   1         1         1       4m1s
replicaset.apps/weaver-main-ffa65856-acfd658f-86684754b      1         1         1       4m1s

NAME                                                                   REFERENCE                                     TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
horizontalpodautoscaler.autoscaling/hello-reverser-ffa65856-58d0b71e   Deployment/hello-reverser-ffa65856-58d0b71e    1%/80%     1         10        1        4m
horizontalpodautoscaler.autoscaling/weaver-main-ffa65856-acfd658f      Deployment/weaver-main-ffa65856-acfd658f       2%/80%     1         10        1        4m
```

请注意，默认情况下， `Kube` 部署程序会为每个组件生成一个部署；在此示例中，部署了 `Main` 和 `Reverser` 组件。

`Kube` 将您的应用程序配置为使用 Kubernetes Horizontal Pod Autoscaler 自动缩放。随着应用程序负载的增加，过载组件的副本数量也会增加。相反，随着应用程序负载的减少，副本数量也会减少。 Service Weaver 可以独立扩展应用程序的不同组件，这意味着可以扩展负载较重的组件，同时可以扩展负载较少的组件。

对于在生产中运行的应用程序，您可能需要配置 DNS 以将您的域名（例如 `hello.com` ）映射到负载均衡器的地址（例如 `http://10.103.133.111` ）。然而，在测试和调试应用程序时，我们也可以简单地卷曲负载均衡器。例如：

```
$ curl "http://10.103.133.111/hello?name=Weaver"
Hello, Weaver!
```

`/tmp/kube_ffa65856.yaml` 标头包含有关生成的 Kubernetes 资源以及如何查看/删除资源的更多详细信息。例如，要删除与此部署关联的资源，您可以运行：

```
$ kubectl delete all,configmaps --selector=serviceweaver/version=ffa65856
```

要查看应用程序日志，您可以运行：

```
$ kubectl logs -l serviceweaver/app=hello --all-containers=true

D1107 23:39:38.096525 weavelet             643fc8a3 remoteweavelet.go:231                │ 🧶 weavelet started addr="tcp://[::]:10000"
D1107 23:39:38.097369 weavelet             643fc8a3 remoteweavelet.go:485                │ Updating components="hello.Reverser"
D1107 23:39:38.097398 weavelet             643fc8a3 remoteweavelet.go:330                │ Constructing component="hello.Reverser"
D1107 23:39:38.097438 weavelet             643fc8a3 remoteweavelet.go:336                │ Constructed component="hello.Reverser"
D1107 23:39:38.097443 weavelet             643fc8a3 remoteweavelet.go:491                │ Updated component="hello.Reverser"
D1107 23:39:37.295945 weavelet             49c6e04e remoteweavelet.go:273                │ Activated component="hello.Reverser"
D1107 23:39:38.349496 weavelet             49c6e04e remoteweavelet.go:415                │ Connecting to remote component="hello.Reverser"
D1107 23:39:38.349587 weavelet             49c6e04e remoteweavelet.go:515                │ Updated routing info addr="[tcp://10.244.2.74:10000]" component="hello.Reverser"
I1107 23:39:38.349646 weavelet             49c6e04e call.go:690                        │ connection addr="tcp://10.244.2.74:10000" from="missing" to="disconnected"
I1107 23:39:38.350108 weavelet             49c6e04e call.go:690                        │ connection addr="tcp://10.244.2.74:10000" from="disconnected" to="checking"
I1107 23:39:38.350252 weavelet             49c6e04e call.go:690                        │ connection addr="tcp://10.244.2.74:10000" from="checking" to="idle"
D1107 23:39:38.358632 weavelet             49c6e04e remoteweavelet.go:429                │ Connected to remote component="hello.Reverser"
S0101 00:00:00.000000 stdout               49c6e04e                       │ hello listener available on [::]:20000
D1107 23:39:38.360294 weavelet             49c6e04e remoteweavelet.go:336                │ Constructed component="weaver.Main"
D1107 23:39:38.360337 weavelet             49c6e04e remoteweavelet.go:491                │ Updated component="weaver.Main"
```

##  配置

您可以使用配置文件中导出的旋钮来配置 `Kube` 部署程序。

| 场地         | 必需的？ | 描述                                                         |
| ------------ | -------- | ------------------------------------------------------------ |
| 应用程序配置 | 必需的   | Service Weaver 应用程序配置文件的路径。                      |
| 图像         | 选修的   | `Kube` 创建的容器映像的名称。如果不存在，图像名称默认为 `<app_name>:<app_version>` 。 |
| 回购协议     | 选修的   | 上传容器镜像的仓库名称。如果为空，则图像不会推送到存储库。   |
| 名称空间     | 选修的   | 应部署应用程序的 Kubernetes 命名空间的名称。默认为 `default` 。 |
| 服务帐户     | 选修的   | 用于运行 Pod 的 Kubernetes 服务帐户的名称。如果不存在，它将使用您的命名空间的默认服务帐户。 |
| Listener     | 选修的   | 应用程序侦听器的选项。如果不存在，将使用默认选项。           |
| 团体         | 选修的   | 共置组件组的选项。如果不存在，每个组件都在自己的组中运行。   |
| 资源规格     | 选修的   | 运行 Pod 所需的资源要求。应满足 Kubernetes 资源格式。如果不存在， `Kube` 将使用 Kubernetes 配置的默认资源要求。 |
| 缩放规范     | 选修的   | 有关如何使用 Kubernetes Horizontal Pod Autoscaler 扩展 Pod 的规范。应满足 Kubernetes HPA 规范格式。如果不存在，将使用默认选项（ `minReplicas=1` 、 `maxReplicas=10` 、 `CPU` 指标、 `averageUtilization=80)` 。 |
| 探针规格     | 选修的   | 配置 Kubernetes 探针来监控 Pod 的运行状况、活跃度和就绪情况。应满足 Kubernetes 探针格式。如果不存在，则不会配置探测器。 |
| 存储规格     | 选修的   | 配置 Kubernetes 卷和卷挂载的选项。如果不存在，则不配置存储。 |
| 使用主机网络 | 选修的   | 如果为 true，应用程序侦听器将使用底层节点的网络。通常不鼓励这种行为，但在 minikube 环境中运行应用程序时它可能很有用。 |

有关每个配置旋钮的特定子字段的更多详细信息，请检查所有配置选项。

注意：诸如 `resourceSpec` 、 `scalingSpec` 、 `storageSpec` 之类的配置旋钮可以针对每个部署和每组共置组件进行配置。但是，如果某个字段同时具有每个部署和每个组的定义，则 `Kube` 部署程序将考虑该字段的每个组值（ `storageSpec` 除外，它考虑两者的串联）。例如，在下面的示例中， `Kube` 部署程序将运行两个托管组，其中运行 `Reverser` 组件的 pod 至少需要 `256Mi` 内存，而运行 `Reverser` 组件的 pod 至少需要 `256Mi` 内存运行 `Main` 组件至少需要 `64Mi` 内存。

```
appConfig: weaver.toml
repo: docker.io/mydockerid

listeners:
- name: hello
  public: true

resourceSpec:
  requests:
    memory: "64Mi"

groups:
  - name: reverser-group
    components:
      -  github.com/ServiceWeaver/weaver/examples/hello/Reverser
    resourceSpec:
      requests:
        memory: "256Mi"
```

##  遥测

`Kube` 部署程序允许您自定义如何导出日志、指标和跟踪。为此，您需要使用 Kube 工具抽象在 `Kube` 部署器之上实现一个包装器部署器。

以下是我们如何将指标导出到 Prometheus 并将跟踪导出到 Jaeger 的示例。

例如，要将跟踪导出到 Jaeger，您必须执行以下操作：

1. 将 Jaeger 部署在 Kubernetes 集群中，作为典型的 Kubernetes 服务。这也是有人在实践中必须要做的事情。

```
$ kubectl apply -f jaeger.yaml
```

1. 编写一个简单的二进制文件来实现将跟踪导出到 Jaeger 的插件。代码如下：

```
// ./examples/customkube
...

const jaegerPort = 14268 // Port on which the Jaeger service is receiving traces.

func main() {
  // Implementation of how to export the traces to Jaeger.
  jaegerURL := fmt.Sprintf("http://jaeger:%d/api/traces", jaegerPort)
  endpoint := jaeger.WithCollectorEndpoint(jaeger.WithEndpoint(jaegerURL))
  traceExporter, err := jaeger.New(endpoint)
  if err != nil {
    panic(err)
  }
  handleTraceSpans := func(ctx context.Context, spans []trace.ReadOnlySpan) error {
    return traceExporter.ExportSpans(ctx, spans)
  }

  // Invokes the `Kube` deployer with the plugin to export traces as instructed
  // by handleTraceSpans.
  tool.Run("customkube", tool.Plugins{
    HandleTraceSpans: handleTraceSpans,
  })
}
```

1. 使用 `customkube` 部署程序构建并部署应用程序。

```
$ go build
$ kubectl apply -f $(customkube deploy config.yaml)
```

1. 您可以访问 Jaeger UI 以查看应用程序的 Service Weaver 跟踪。

##  CI/CD 管道

`Kube` 部署器应该可以轻松地与您的 CI/CD 管道集成。以下是有关如何与 Github Actions 集成的示例。

我们还尝试了 ArgoCD 和 Jenkins。如果您在将 `Kube` 与您自己的 CI/CD 管道集成时遇到问题，请在 Discord 上联系我们。

##  版本控制

要推出应用程序的新版本，只需重建应用程序并再次运行 `weaver kube deploy` 即可。一旦部署新生成的 Kubernetes 资源，它将启动一个运行新应用程序版本的新树。

请注意，用户有责任确保新应用程序版本运行良好，并将流量转移到新版本。

我们发现，通常用户首先在测试集群中启动新版本。一旦它对新版本的行为符合预期有足够的信心，它就会在生产集群中推出新版本，并触发原子推出。您可以通过跨版本保留外部侦听器服务名称，使用 `Kube` 部署程序来执行此操作。

例如，如果您想在“Hello, World!”的多个版本中进行原子部署。上面提到的应用程序，您可以按如下方式配置 `hello` 监听器：

```
appConfig: weaver.toml
repo: docker.io/mydockerid

listeners:
  - name: hello
    public: true
    serviceName: uniqueServiceName
```

这将保证每次发布新版本的“Hello, World!”应用程序中，运行 `hello` 侦听器的负载均衡器服务将始终指出应用程序版本的最新版本。

# GKE

Google Kubernetes Engine (GKE) 是一项 Google Cloud 托管服务，实现了完整的 Kubernetes API。它支持自动扩展和多集群开发，并允许您在云中运行容器化应用程序。

您可以使用 `weaver gke` 将 Service Weaver 应用程序部署到 GKE，其中组件在多个云区域的不同计算机上运行。 `weaver gke` 命令代表您执行大量繁重的工作来设置 GKE。它将您的应用程序容器化；它创建适当的 GKE 集群；它将所有网络基础设施连接在一起；等等。这使得将 Service Weaver 应用程序部署到云就像运行 `weaver gke deploy` 一样简单。在本节中，我们将向您展示如何使用 `weaver gke` 部署应用程序。请参阅本地 GKE 部分，了解如何在计算机上本地模拟 GKE 部署。

##  安装

首先，确保您安装了 Service Weaver。接下来，安装 `weaver-gke` 命令：

```
$ go install github.com/ServiceWeaver/weaver-gke/cmd/weaver-gke@latest
```

将 `gcloud` 命令安装到本地计算机。为此，请按照以下说明操作，或运行以下命令并按照提示操作：

```
$ curl https://sdk.cloud.google.com | bash
```

安装 `gcloud` 后，安装所需的 GKE 身份验证插件：

```
$ gcloud components install gke-gcloud-auth-plugin
```

，然后运行以下命令来初始化本地环境：

```
$ gcloud init
```

上述命令将提示您选择要使用的 Google 帐户和云项目。如果您没有云项目，该命令将提示您创建一个。确保选择唯一的项目名称，否则命令将失败。如果发生这种情况，请按照以下说明创建一个新项目，或者只需运行：

```
$ gcloud projects create my-unique-project-name
```

但是，在使用云项目之前，您必须向其添加计费帐户。转至此页面创建新的计费帐户，然后转至此页面将计费帐户与您的云项目关联。

##  开始使用

再考虑一下“你好，世界！”分步教程部分中的 Service Weaver 应用程序。该应用程序在名为 `hello` 的侦听器上运行 HTTP 服务器，并使用返回 `Hello, <name>!` 问候语的 `/hello?name=<name>` 端点。要将此应用程序部署到 GKE，首先创建一个 Service Weaver 配置文件，例如 `weaver.toml` ，其中包含以下内容：

```
[serviceweaver]
binary = "./hello"

[gke]
regions = ["us-west1"]
listeners.hello = {public_hostname = "hello.com"}
```

配置文件的 `[serviceweaver]` 部分指定已编译的 Service Weaver 二进制文件。 `[gke]` 部分配置部署应用程序的区域（本例中为 `us-west1` ）。它还声明哪些侦听器应该是公开的，即哪些侦听器应该可以从公共互联网访问。默认情况下，所有侦听器都是私有的，即只能从云项目的内部网络访问。在我们的示例中，我们声明 `hello` 侦听器是公共的。

部署到 GKE 的所有监听器均配置为由 `/debug/weaver/healthz` URL 路径上的 GKE 负载均衡器进行运行状况检查。 ServiceWeaver 会自动在默认 ServerMux 中的此 URL 路径下注册运行状况检查处理程序，因此 `hello` 应用程序不需要进行任何更改。

使用 `weaver gke deploy` 部署应用程序：

```
$ GOOS=linux GOARCH=amd64 go build
$ weaver gke deploy weaver.toml
...
Deploying the application... Done
Version "8e1c640a-d87b-4020-b3dd-4efc1850756c" of app "hello" started successfully.
Note that stopping this binary will not affect the app in any way.
Tailing the logs...
...
```

第一次将 Service Weaver 应用程序部署到云项目时，该过程可能会很慢，因为 Service Weaver 需要配置您的云项目、创建适当的 GKE 集群等。后续部署应该会明显加快。

当 `weaver gke` 部署您的应用程序时，它会创建一个全局的、外部可访问的负载均衡器，将流量转发到应用程序中的公共侦听器。 `weaver gke deploy` 打印出此负载均衡器的 IP 地址以及如何与之交互的说明：

```
NOTE: The applications' public listeners will be accessible via an
L7 load-balancer managed by Service Weaver running at the public IP address:

    http://34.149.225.62

This load-balancer uses hostname-based routing to route request to the
appropriate listeners. As a result, all HTTP(s) requests reaching this
load-balancer must have the correct "Host" header field populated. This can be
achieved in one of two ways:
...
```

对于在生产中运行的应用程序，您可能需要配置 DNS 以将您的域名（例如 `hello.com` ）映射到负载均衡器的地址（例如 `http://34.149.225.62` ）。然而，在测试和调试应用程序时，我们也可以简单地使用适当的主机名标头来卷曲负载均衡器。由于我们将应用程序配置为将主机名 `hello.com` 与 `hello` 侦听器关联，因此我们使用以下命令：

```
$ curl --header 'Host: hello.com' "http://34.149.225.63/hello?name=Weaver"
Hello, Weaver!
```

我们可以使用 `weaver gke status` 命令检查在 GKE 上运行的 Service Weaver 应用程序。

```
$ weaver gke status
╭───────────────────────────────────────────────────────────────╮
│ Deployments                                                   │
├───────┬──────────────────────────────────────┬───────┬────────┤
│ APP   │ DEPLOYMENT                           │ AGE   │ STATUS │
├───────┼──────────────────────────────────────┼───────┼────────┤
│ hello │ 20c1d756-80b5-42a7-9e73-b0d3e717516e │ 1m10s │ ACTIVE │
╰───────┴──────────────────────────────────────┴───────┴────────╯
╭──────────────────────────────────────────────────────────╮
│ COMPONENTS                                               │
├───────┬────────────┬──────────┬────────────────┬─────────┤
│ APP   │ DEPLOYMENT │ LOCATION │ COMPONENT      │ HEALTHY │
├───────┼────────────┼──────────┼────────────────┼─────────┤
│ hello │ 20c1d756   │ us-west1 │ hello.Reverser │ 2/2     │
│ hello │ 20c1d756   │ us-west1 │ main           │ 2/2     │
╰───────┴────────────┴──────────┴────────────────┴─────────╯
╭─────────────────────────────────────────────────────────────────────────────────────╮
│ TRAFFIC                                                                             │
├───────────┬────────────┬───────┬────────────┬──────────┬─────────┬──────────────────┤
│ HOST      │ VISIBILITY │ APP   │ DEPLOYMENT │ LOCATION │ ADDRESS │ TRAFFIC FRACTION │
├───────────┼────────────┼───────┼────────────┼──────────┼─────────┼──────────────────┤
│ hello.com │ public     │ hello │ 20c1d756   │ us-west1 │         │ 0.5              │
├───────────┼────────────┼───────┼────────────┼──────────┼─────────┼──────────────────┤
│ hello.com │ public     │ hello │ 20c1d756   │ us-west1 │         │ 0.5              │
╰───────────┴────────────┴───────┴────────────┴──────────┴─────────┴──────────────────╯
╭────────────────────────────╮
│ ROLLOUT OF hello           │
├─────────────────┬──────────┤
│                 │ us-west1 │
├─────────────────┼──────────┤
│ TIME            │ 20c1d756 │
│ Feb 27 21:23:07 │ 1.00     │
╰─────────────────┴──────────╯
```

`weaver gke status` 报告有关云项目中每个应用程序、部署、组件和侦听器的信息。在此示例中，我们有 `hello` 应用程序的单个部署（ID 为 `20c1d756` ）。我们的应用程序有两个组件（ `main` 和 `hello.Reverser` ），每个组件都有两个运行状况良好的副本在 `us-west1` 区域中运行。 `main` 组件的两个副本各导出一个 `hello` 侦听器。我们之前卷曲的全局负载均衡器在这两个侦听器之间均匀地平衡流量。输出的最后部分详细介绍了应用程序的推出时间表。我们稍后将在“推出”部分讨论推出。您还可以运行 `weaver gke dashboard` 在 Web 浏览器中打开仪表板。

注意： `weaver gke` 将 GKE 配置为自动缩放您的应用程序。随着应用程序负载的增加，过载组件的副本数量也会增加。相反，随着应用程序负载的减少，副本数量也会减少。 Service Weaver 可以独立扩展应用程序的不同组件，这意味着可以扩展负载较重的组件，同时可以扩展负载较少的组件。

您可以使用 `weaver gke kill` 命令来终止已部署的应用程序。

```
$ weaver gke kill hello
WARNING: You are about to kill every active deployment of the "hello" app.
The deployments will be killed immediately and irrevocably. Are you sure you
want to proceed?

Enter (y)es to continue: y
```

##  日志

`weaver gke deploy` 日志到标准输出。它还会将所有日志条目导出到 Cloud Logging。您可以使用 `weaver gke logs` 从命令行捕获、关注和过滤这些日志。例如：

```
# Display all of the application logs
weaver gke logs

# Follow all of the logs (similar to tail -f).
weaver gke logs --follow

# Display all of the logs for the "todo" app.
weaver gke logs 'app == "todo"'

# Display all of the debug logs for the "todo" app.
weaver gke logs 'app=="todo" && level=="debug"'

# Display all of the logs for the "todo" app in files called foo.go.
weaver gke logs 'app=="todo" && source.contains("foo.go")'

# Display all of the logs that contain the string "error".
weaver gke logs 'msg.contains("error")'

# Display all of the logs that match a regex.
weaver gke logs 'msg.matches("error: file .* already closed")'

# Display all of the logs that have an attribute "foo" with value "bar".
weaver gke logs 'attrs["foo"] == "bar"'

# Display all of the logs in JSON format. This is useful if you want to
# perform some sort of post-processing on the logs.
weaver gke logs --format=json

# Display all of the logs, including internal system logs that are hidden by
# default.
weaver gke logs --system
```

有关查询语言的完整说明以及更多示例，请参阅 `weaver gke logs --help` 。

您还可以运行 `weaver gke dashboard` 在 Web 浏览器中打开仪表板。对于通过 `weaver gke deploy` 部署的每个 Service Weaver 应用程序，仪表板都有一个页面。每个部署的页面都有一个指向 Google Cloud 日志浏览器上的部署日志的链接，如下所示。

![A screenshot of Service Weaver logs in the Logs Explorer](https://serviceweaver.dev/assets/images/logs_explorer.png)

##  指标

`weaver gke` 将指标导出到 Google Cloud Monitoring 控制台。您可以使用 Cloud Metrics Explorer 查看这些指标并绘制图表。打开 Metrics Explorer 后，单击 `SELECT A METRIC` 。

![A screenshot of the Metrics Explorer](https://serviceweaver.dev/assets/images/cloud_metrics_1.png)

所有 Service Weaver 指标均导出到 `custom.googleapis.com` 域下。查询 `serviceweaver` 以查看这些指标并选择您感兴趣的指标。

![A screenshot of selecting a metric in Metrics Explorer](https://serviceweaver.dev/assets/images/cloud_metrics_2.png)

您可以使用 Metrics Explorer 来绘制所选指标的图表。

![A screenshot of a metric graph in Metrics Explorer](https://serviceweaver.dev/assets/images/cloud_metrics_3.png)

有关更多信息，请参阅云指标文档。

##  Profile

使用 `weaver gke profile` 命令收集 Service Weaver 应用程序的配置文件。使用您要分析的应用程序的名称（以及可选的版本）调用该命令。例如：

```
# Collect a CPU profile of the latest version of the hello app.
$ weaver gke profile hello

# Collect a CPU profile of a specific version of the hello app.
$ weaver gke profile --version=8e1c640a-d87b-4020-b3dd-4efc1850756c hello

# Adjust the duration of a CPU profile.
$ weaver gke profile --duration=1m hello

# Collect a heap profile.
$ weaver gke profile --type=heap hello
```

`weaver gke profile` 打印出收集的配置文件的文件名。您可以使用 `go tool pprof` 命令来可视化和分析配置文件。例如：

```
$ profile=$(weaver gke profile <app>)         # Collect the profile.
$ go tool pprof -http=localhost:9000 $profile # Visualize the profile.
```

请参阅 `weaver gke profile --help` 了解更多详情。

##  追踪

运行 `weaver gke dashboard` 以在 Web 浏览器中打开仪表板。对于通过 `weaver gke deploy` 部署的每个 Service Weaver 应用程序，仪表板都有一个页面。每个部署的页面都有一个指向部署跟踪的链接，可通过 Google Cloud Trace 访问，如下所示。

![A screenshot of a Google Cloud Trace page](https://serviceweaver.dev/assets/images/trace_gke.png)

##  多区域

`weaver gke` 允许您将 Service Weaver 应用程序部署到多个云区域。只需在配置文件中包含要部署的区域即可。例如：

```
[gke]
regions = ["us-west1", "us-east1", "asia-east2", "europe-north1"]
```

当 `weaver gke` 将应用程序部署到多个区域时，它故意不会立即将应用程序部署到每个区域。相反，它会缓慢地推出应用程序。 `weaver gke` 首先将应用程序部署到一小部分区域，这些区域充当金丝雀。该应用程序在金丝雀集群中运行一段时间，然后再推广到更大的区域子集。 `weaver gke` 继续这种增量部署——迭代地增加部署应用程序的区域数量——直到应用程序部署到配置文件中指定的每个区域。在每个区域内， `weaver gke` 也会慢慢地将流量从旧应用程序版本转移到新版本。我们将在下一节讨论这个问题。

通过跨区域缓慢推出应用程序， `weaver gke` 使您可以及早发现有缺陷的版本并减轻它们可能造成的损害。配置文件中的 `rollout` 字段确定缓慢推出的长度。例如：

```
[serviceweaver]
rollout = "1h" # Perform a one hour slow rollout.
...
```

您可以使用 `weaver gke status` 监视应用程序的推出。例如，以下是 `weaver gke status` 生成的部署计划，用于在 us-central1、us-west1、us-south1 和 us-east1 上部署 `hello` 应用程序一小时地区。

```
[ROLLOUT OF hello]
                 us-west1  us-central1  us-south1  us-east1
TIME             a838cf1d  a838cf1d     a838cf1d   a838cf1d
Nov  8 22:47:30  1.00      0.00         0.00       0.00
        +15m00s  0.50      0.50         0.00       0.00
        +30m00s  0.33      0.33         0.33       0.00
        +45m00s  0.25      0.25         0.25       0.25
```

时间表中的每一行显示每个区域从全局负载均衡器接收的流量比例。最上面一行是当前的流量分配，随后的每一行显示未来某个时间点的预计流量分配。请注意，只有已部署应用程序的区域才会接收流量，我们可以看到该应用程序最初部署在 us-west1 中，然后以 15 分钟的增量慢慢部署到 us-central1、us-south1 和 us-east1。

另请注意，虽然全局负载均衡器平衡跨区域的流量，但一旦在某个区域内收到请求，该请求就会完全在该区域内进行处理。与缓慢推出和金丝雀攻击一样，避免跨区域通信是一种隔离形式，有助于最大限度地减少行为不当应用程序的影响范围。

##  版本控制

要推出应用程序的新版本来替代现有版本，只需重建应用程序并再次运行 `weaver gke deploy` 即可。 `weaver gke` 将慢慢地将新版本的应用程序推出到配置文件中提供的区域，如上一节所述。除了跨区域缓慢推出外， `weaver gke` 也在区域内缓慢推出。在每个区域内， `weaver gke` 更新全局负载均衡器，以缓慢地将流量从旧版本的应用程序转移到新版本。

我们可以再次使用 `weaver gke status` 来监控新应用程序版本的推出。例如，以下是 `weaver gke status` 为 us-west1 和 us-east1 区域中 `hello` 应用程序的一小时更新生成的推出计划。新版本的应用 `45a521a3` 正在替换旧版本 `def1f485` 。

```
[ROLLOUT OF hello]
                 us-west1  us-west1  us-east1  us-east1
TIME             def1f485  45a521a3  def1f485  45a521a3
Nov  9 00:54:59  0.45      0.05      0.50      0.00
         +4m46s  0.38      0.12      0.50      0.00
         +9m34s  0.25      0.25      0.50      0.00
        +14m22s  0.12      0.38      0.50      0.00
        +19m10s  0.00      0.50      0.50      0.00
        +29m58s  0.00      0.50      0.45      0.05
        +34m46s  0.00      0.50      0.38      0.12
        +39m34s  0.00      0.50      0.25      0.25
        +44m22s  0.00      0.50      0.12      0.38
        +49m10s  0.00      0.50      0.00      0.50
```

时间表中的每一行显示每个部署在每个区域收到的流量比例。时间表显示新应用程序先于 us-east1 在 us-west1 推出。最初，新版本在 us-west1 区域接收的流量越来越多，从全球流量的 5%（us-west1 流量的 10%）过渡到全球流量的 50%（us-west1 流量的 100%） ）在大约20分钟的过程中。 10 分钟后，此过程在 us-east1 中重复 20 分钟，直到新版本接收 100% 的全球流量。完整一小时的推出完成后，旧版本将被视为已过时并会自动删除。

注意：虽然负载均衡器会跨应用程序版本平衡流量，但一旦收到请求，该请求将完全由接收该请求的版本进行处理。不存在跨版本通信。

从表面上看， `weaver gke` 的推出方案似乎需要大量资源，因为它并排运行应用程序的两个副本。实际上， `weaver gke` 使用自动缩放使这种类型的蓝/绿部署资源高效。随着流量从旧版本转移，其负载减少，自动缩放器减少其资源分配。同时，随着新版本接收更多流量，其负载增加，自动缩放器开始增加其资源分配。这两个转换相互抵消，导致部署使用大致恒定数量的资源。

##  配置

您可以使用配置文件的 `[gke]` 部分配置 `weaver gke` 。

```
[gke]
project = "my-google-cloud-project"
account = "my_account@gmail.com"
regions = ["us-west1", "us-east1"]
listeners.cat = {public_hostname = "cat.com"}
listeners.hat = {public_hostname = "hat.gg"}
```

| 场地     | 必需的？ | 描述                                                         |
| -------- | -------- | ------------------------------------------------------------ |
| 项目     | 选修的   | 要在其中部署 Service Weaver 应用程序的 Google Cloud 项目的名称。如果不存在，则使用当前活动的项目（即 `gcloud config get-value project` ） |
| 帐户     | 必需的   | 用于部署 Service Weaver 应用程序的 Google Cloud 帐户。如果不存在，则使用当前活动帐户（即 `gcloud config get-value account` ）。 |
| 地区     | 选修的   | 应部署 Service Weaver 应用程序的区域。默认为 `["us-west1"]` 。 |
| Listener | 选修的   | 应用程序的侦听器选项，例如侦听器的公共主机名。               |

##  本地 GKE 

`weaver gke` 可让您将 Service Weaver 应用程序部署到 GKE。 `weaver gke-local` 是 `weaver gke` 的直接替代品，允许您在计算机上本地模拟 GKE 部署。每个 `weaver gke` 命令都可以替换为等效的 `weaver gke-local` 命令。 `weaver gke deploy` 变为 `weaver gke-local deploy` ； `weaver gke status` 变为 `weaver gke-local status` ；等等。 `weaver gke-local` 在模拟 GKE 集群中运行您的组件，并启动本地代理来模拟 GKE 的全局负载均衡器。 `weaver gke-local` 还使用与 `weaver gke` 相同的配置，这意味着在使用 `weaver gke-local` 本地测试应用程序后，您可以将相同的应用程序部署到 GKE，无需任何代码或配置更改。

###  安装

首先，确保您安装了 Service Weaver。接下来，安装 `weaver-gke-local` 命令：

```
$ go install github.com/ServiceWeaver/weaver-gke/cmd/weaver-gke-local@latest
```

###  入门

在 `weaver gke` 部分中，我们部署了“Hello, World!”使用 `weaver gke deploy` 向 GKE 应用程序。我们可以使用 `weaver gke-local deploy` 在本地部署相同的应用程序：

```
$ cat weaver.toml
[serviceweaver]
binary = "./hello"

[gke]
regions = ["us-west1"]
listeners.hello = {public_hostname = "hello.com"}

$ weaver gke-local deploy weaver.toml
Deploying the application... Done
Version "a2bc7a7a-fcf6-45df-91fe-6e6af171885d" of app "hello" started successfully.
Note that stopping this binary will not affect the app in any way.
Tailing the logs...
...
```

您可以运行 `weaver gke-local status` 来检查使用 `weaver gke-local` 部署的所有应用程序的状态。

```
$ weaver gke-local status
╭─────────────────────────────────────────────────────────────╮
│ Deployments                                                 │
├───────┬──────────────────────────────────────┬─────┬────────┤
│ APP   │ DEPLOYMENT                           │ AGE │ STATUS │
├───────┼──────────────────────────────────────┼─────┼────────┤
│ hello │ af09030c-b3a6-4d15-ba47-cd9e9e9ec2e7 │ 13s │ ACTIVE │
╰───────┴──────────────────────────────────────┴─────┴────────╯
╭──────────────────────────────────────────────────────────╮
│ COMPONENTS                                               │
├───────┬────────────┬──────────┬────────────────┬─────────┤
│ APP   │ DEPLOYMENT │ LOCATION │ COMPONENT      │ HEALTHY │
├───────┼────────────┼──────────┼────────────────┼─────────┤
│ hello │ af09030c   │ us-west1 │ hello.Reverser │ 2/2     │
│ hello │ af09030c   │ us-west1 │ main           │ 2/2     │
╰───────┴────────────┴──────────┴────────────────┴─────────╯
╭─────────────────────────────────────────────────────────────────────────────────────────────╮
│ TRAFFIC                                                                                     │
├───────────┬────────────┬───────┬────────────┬──────────┬─────────────────┬──────────────────┤
│ HOST      │ VISIBILITY │ APP   │ DEPLOYMENT │ LOCATION │ ADDRESS         │ TRAFFIC FRACTION │
├───────────┼────────────┼───────┼────────────┼──────────┼─────────────────┼──────────────────┤
│ hello.com │ public     │ hello │ af09030c   │ us-west1 │ 127.0.0.1:46539 │ 0.5              │
│ hello.com │ public     │ hello │ af09030c   │ us-west1 │ 127.0.0.1:43439 │ 0.5              │
╰───────────┴────────────┴───────┴────────────┴──────────┴─────────────────┴──────────────────╯
╭────────────────────────────╮
│ ROLLOUT OF hello           │
├─────────────────┬──────────┤
│                 │ us-west1 │
├─────────────────┼──────────┤
│ TIME            │ af09030c │
│ Feb 27 20:33:10 │ 1.00     │
╰─────────────────┴──────────╯
```

毫不奇怪，输出与 `weaver gke status` 的输出相同。有关于每个应用程序、组件和侦听器的信息。请注意，在此示例中， `weaver gke-local` 正在运行“Hello, World!”应用程序位于虚假的 us-west1“区域”中，如 `weaver.toml` 配置文件中指定。

`weaver gke-local` 在端口 8000 上运行代理，模拟 `weaver gke` 使用的全局负载均衡器。我们可以像卷曲全局负载均衡器一样卷曲代理。由于我们将应用程序配置为将主机名 `hello.com` 与 `hello` 侦听器关联，因此我们使用以下命令：

```
$ curl --header 'Host: hello.com' "localhost:8000/hello?name=Weaver"
Hello, Weaver!
```

您可以使用 `weaver gke-local kill` 命令来终止已部署的应用程序。

```
$ weaver gke-local kill hello
WARNING: You are about to kill every active deployment of the "hello" app.
The deployments will be killed immediately and irrevocably. Are you sure you
want to proceed?

Enter (y)es to continue: y
```

###  日志

`weaver gke-local deploy` 日志到标准输出。它还将所有日志条目保存在 `/tmp/serviceweaver/logs/weaver-gke-local` 中的一组文件中。每个文件都包含编码为协议缓冲区的日志条目流。您可以使用 `weaver gke-local logs` 来分类、关注和过滤这些日志。例如：

```
# Display all of the application logs
weaver gke-local logs

# Follow all of the logs (similar to tail -f).
weaver gke-local logs --follow

# Display all of the logs for the "todo" app.
weaver gke-local logs 'app == "todo"'

# Display all of the debug logs for the "todo" app.
weaver gke-local logs 'app=="todo" && level=="debug"'

# Display all of the logs for the "todo" app in files called foo.go.
weaver gke-local logs 'app=="todo" && source.contains("foo.go")'

# Display all of the logs that contain the string "error".
weaver gke-local logs 'msg.contains("error")'

# Display all of the logs that match a regex.
weaver gke-local logs 'msg.matches("error: file .* already closed")'

# Display all of the logs that have an attribute "foo" with value "bar".
weaver gke-local logs 'attrs["foo"] == "bar"'

# Display all of the logs in JSON format. This is useful if you want to
# perform some sort of post-processing on the logs.
weaver gke-local logs --format=json

# Display all of the logs, including internal system logs that are hidden by
# default.
weaver gke-local logs --system
```

有关查询语言的完整说明以及更多示例，请参阅 `weaver gke-local logs --help` 。

###  指标

除了在端口 8000 上运行代理（请参阅入门）之外， `weaver gke-local` 还在端口 8001 上运行状态服务器。此服务器的 `/metrics` 端点导出所有正在运行的 Service Weaver 的指标Prometheus 格式的应用程序，如下所示：

```
# HELP example_count An example counter.
# TYPE example_count counter
example_count{serviceweaver_node="bbc9beb5"} 42
example_count{serviceweaver_node="00555c38"} 9001
```

要可视化和查询指标，请确保本地计算机上安装了 Prometheus，然后将以下节添加到 Prometheus yaml 配置文件中：

```
scrape_configs:
- job_name: 'prometheus-serviceweaver-scraper'
  scrape_interval: 5s
  metrics_path: /metrics
  static_configs:
    - targets: ['localhost:8001']
```

###  分析

使用 `weaver gke-local profile` 命令收集 Service Weaver 应用程序的配置文件。使用您要分析的应用程序的名称（以及可选的版本）调用该命令。例如：

```
# Collect a CPU profile of the latest version of the hello app.
$ weaver gke-local profile hello

# Collect a CPU profile of a specific version of the hello app.
$ weaver gke-local profile --version=8e1c640a-d87b-4020-b3dd-4efc1850756c hello

# Adjust the duration of a CPU profile.
$ weaver gke-local profile --duration=1m hello

# Collect a heap profile.
$ weaver gke-local profile --type=heap hello
```

`weaver gke-local profile` 打印出收集的配置文件的文件名。您可以使用 `go tool pprof` 命令来可视化和分析配置文件。例如：

```
$ profile=$(weaver gke-local profile <app>)    # Collect the profile.
$ go tool pprof -http=localhost:9000 $profile # Visualize the profile.
```

请参阅 `weaver gke-local profile --help` 了解更多详情。

###  追踪

运行 `weaver gke-local dashboard` 以在 Web 浏览器中打开仪表板。对于通过 `weaver gke-local deploy` 部署的每个 Service Weaver 应用程序，仪表板都有一个页面。每个部署的页面都有一个指向可通过 Perfetto 访问的部署跟踪的链接。以下是跟踪页面的示例：

![An example trace page](https://serviceweaver.dev/assets/images/trace_gke_local.png)

请参阅 Perfetto UI 文档，了解有关如何使用跟踪 UI 的更多信息。

###  版本控制

回想一下， `weaver gke` 跨区域和跨应用程序版本执行缓慢的部署。 `weaver gke-local` 在本地模拟此行为。当您 `weaver gke-local deploy` 应用程序时，该应用程序首先会部署到多个金丝雀区域，然后慢慢部署到所有区域。在一个区域内，本地运行的代理慢慢地将流量从旧版本的应用程序转移到新版本的应用程序。您可以使用 `weaver gke-local status` 来监视应用程序的部署，就像使用 `weaver gke status` 一样。

#  SSH [实验] 

SSH 是一个部署程序，允许您在可通过 `ssh` 访问的一组计算机上运行 Service Weaver 应用程序。请注意， `SSH` 部署程序将应用程序的组件作为独立操作系统进程运行，因此您不需要 Kubernetes、Docker 等。

##  开始使用

 先决条件：

- 可通过 `ssh` 访问的一组机器。
- 您可能希望在计算机之间设置无密码 `ssh` ，否则在部署/停止应用程序时必须输入每台计算机的密码。

再考虑一下“你好，世界！”分步教程部分中的 Service Weaver 应用程序。该应用程序在名为 `hello` 的侦听器上运行 HTTP 服务器，并使用返回 `Hello, <name>!` 问候语的 `/hello?name=<name>` 端点。要使用 `SSH` 部署程序部署此应用程序，首先创建一个 Service Weaver 应用程序配置文件，例如 `weaver.toml` ，其中包含以下内容：

```
[serviceweaver]
binary = "./hello"

[ssh]
listeners.hello = {address = "localhost:9000"}
locations = "./ssh_locations.txt"
```

配置文件的 `[serviceweaver]` 部分指定已编译的 Service Weaver 二进制文件。 `[ssh]` 部分包含应部署应用程序的计算机集以及每个侦听器配置。机器集在 `ssh_locations.txt` 中指定如下：

```
10.100.12.31
10.100.12.32
10.100.12.33
...
```

使用 `weaver ssh deploy` 部署应用程序：

```
$ weaver ssh deploy weaver.toml
```

当 `weaver ssh deploy` 终止时（例如，当您按 `ctrl+c` 时），应用程序将被销毁，所有进程都将终止。

##  日志

`weaver ssh logs` 日志到标准输出。详情请参阅 `weaver ssh logs --help` 。

##  指标

运行 `weaver ssh dashboard` 以在 Web 浏览器中打开仪表板。对于通过 `weaver ssh deploy` 部署的每个 Service Weaver 应用程序，仪表板都有一个页面。每个部署的页面都有一个指向部署指标的链接。指标以 Prometheus 格式导出，如下所示：

```
# Metrics in Prometheus text format [1].
#
# To visualize and query the metrics, make sure Prometheus is installed on
# your local machine and then add the following stanza to your Prometheus yaml
# config file:
#
# scrape_configs:
# - job_name: 'prometheus-serviceweaver-scraper'
#   scrape_interval: 5s
#   metrics_path: /debug/serviceweaver/prometheus
#   static_configs:
#     - targets: ['127.0.0.1:43087']
#
# [1]: https://prometheus.io

# HELP example_count An example counter.
# TYPE example_count counter
example_count{serviceweaver_node="bbc9beb5"} 42
example_count{serviceweaver_node="00555c38"} 9001

# ┌─────────────────────────────────────┐
# │ SERVICEWEAVER AUTOGENERATED METRICS │
# └─────────────────────────────────────┘
# HELP serviceweaver_method_count Count of Service Weaver component method invocations
# TYPE serviceweaver_method_count counter
serviceweaver_method_count{caller="main",component="main.Example",serviceweaver_node="9fa07495",method="Foo"} 0
serviceweaver_method_count{caller="main",component="main.Example",serviceweaver_node="ee76816d",method="Foo"} 1
...
```

正如标题所解释的，您可以通过安装 Prometheus 并使用提供的节对其进行配置来可视化和查询指标，以定期抓取所提供目标的 `/debug/serviceweaver/prometheus` 端点（上面的例子）。您还可以手动检查指标。指标页面显示应用程序中每个指标的最新值，后面是 Service Weaver 自动为您创建的指标。

##  追踪

运行 `weaver ssh dashboard` 以在 Web 浏览器中打开仪表板。对于通过 `weaver ssh deploy` 部署的每个 Service Weaver 应用程序，仪表板都有一个页面。每个部署的页面都有一个指向可通过 Perfetto 访问的部署跟踪的链接。这与使用单进程或多进程部署程序时访问跟踪的方式类似。

请参阅 Perfetto UI 文档，了解有关如何使用跟踪 UI 的更多信息。

##  限制

请注意， `SSH` 部署程序尚未准备好用于生产，而是充当在一组计算机上部署 Service Weaver 应用程序的平台。我们欢迎做出贡献，使其做好生产准备。一些限制：

- 每个组件都部署在所有机器上。
- 没有基于运行状况/负载信号的放大/缩小机制。
- 不支持缓慢推出。
- `weaver ssh profile` 命令未执行。
- 不与现有框架集成来导出日志、指标和跟踪。

#  可序列化类型

当您调用组件的方法时，该方法的参数（以及该方法返回的结果）可能会被序列化并通过网络发送。因此，组件的方法只能接收和返回 Service Weaver 知道如何序列化的类型，我们称之为可序列化的类型。如果组件方法接收或返回不可序列化的类型， `weaver generate` 将在代码生成期间引发错误。以下类型是可序列化的：

- 所有原始类型（例如 `int` 、 `bool` 、 `string` ）都是可序列化的。
- 如果 `t` 可序列化，则指针类型 `*t` 也可序列化。
- 如果 `t` 可序列化，则数组类型 `[N]t` 也可序列化。
- 如果 `t` 可序列化，则切片类型 `[]t` 也可序列化。
- 如果 `k` 和 `v` 可序列化，则映射类型 `map[k]v` 也可序列化。
- 如果 `type t u` 中的命名类型 `t` 不是递归的并且满足以下一项或多项条件，则它是可序列化的：
  - `t` 是一个协议缓冲区（即 `*t` 实现 `proto.Message` ）；
  - `t` 实现 `encoding.BinaryMarshaler` 和 `encoding.BinaryUnmarshaler` ；
  - `u` 是可序列化的；或者
  - `u` 是嵌入 `weaver.AutoMarshal` 的结构类型（见下文）。

以下类型不可序列化：

- Chan 类型 `chan t` 不可序列化。
- 结构文字类型 `struct{...}` 不可序列化。
- 函数类型 `func(...)` 不可序列化。
- 接口类型 `interface{...}` 不可序列化。

注意：默认情况下，未实现 `proto.Message` 或 `BinaryMarshaler` 和 `BinaryUnmarshaler` 的命名结构类型不可序列化。但是，可以通过嵌入 `weaver.AutoMarshal` 轻松地使它们可序列化。

```
type Pair struct {
    weaver.AutoMarshal
    x, y int
}
```

`weaver.AutoMarshal` 嵌入指示 `weaver generate` 为结构生成序列化方法。但请注意， `weaver.AutoMarshal` 无法神奇地使任何类型可序列化。例如， `weaver generate` 将引发以下代码的错误，因为 `NotSerializable` 结构基本上不可序列化。

```
// ERROR: NotSerializable cannot be made serializable.
type NotSerializable struct {
    weaver.AutoMarshal
    f func()   // functions are not serializable
    c chan int // chans are not serializable
}
```

另请注意， `weaver.AutoMarshal` 不能嵌入通用结构中。

```
// ERROR: Cannot embed weaver.AutoMarshal in a generic struct.
type Pair[A any] struct {
    weaver.AutoMarshal
    x A
    y A
}
```

要序列化通用结构，请实现 `BinaryMarshaler` 和 `BinaryUnmarshaler` 。

##  错误

Service Weaver 要求每个组件方法都返回错误。如果返回非零错误，Service Weaver 默认情况下会传输错误的文本表示。因此，调用者无法使用错误值或自定义 `Is` 或 `As` 方法中存储的任何自定义信息。

需要自定义错误信息的应用程序可以在其自定义错误类型中嵌入 `weaver.AutoMarshal` 。然后，Service Weaver 将正确序列化和反序列化此类错误，并将其提供给调用者。

#  generate

`weaver generate` 是 Service Weaver 的代码生成器。在编译和运行 Service Weaver 应用程序之前，您应该运行 `weaver generate` 以生成 Service Weaver 运行应用程序所需的代码。例如， `weaver generate` 生成代码来编组和解组可能通过网络发送的任何类型。

在命令行中， `weaver generate` 接受包路径列表。例如， `weaver generate . ./foo` 将为当前目录和 `./foo` 目录中的Service Weaver 应用程序生成代码。对于每个包，生成的代码都放置在包目录中的 `weaver_gen.go` 文件中。例如，运行 `weaver generate .  ./foo` 将创建 `./weaver_gen.go` 和 `./foo/weaver_gen.go` 。您为 `weaver generate` 指定包的方式与为 `go build` 、 `go test` 、 `go vet` 等指定包的方式相同。运行 `go help packages`

虽然您可以直接调用 `weaver generate` ，但我们建议您将以下形式的行放在模块根目录的 `.go` 文件之一中：

```
//go:generate weaver generate ./...
```

然后，您可以使用 `go generate` 命令生成模块中的所有 `weaver_gen.go` 文件。

#  配置文件

Service Weaver 配置文件是用 TOML 编写的，如下所示：

```
[serviceweaver]
name = "hello"
binary = "./hello"
args = ["these", "are", "command", "line", "arguments"]
env = ["PUT=your", "ENV=vars", "HERE="]
colocate = [
    ["main/Rock", "main/Paper", "main/Scissors"],
    ["github.com/example/sandy/PeanutButter", "github.com/example/sandy/Jelly"],
]
rollout = "1m"
```

配置文件包含 `[serviceweaver]` 部分，后跟以下字段的子集：

| 场地   | 必需的？ | 描述                                                         |
| ------ | -------- | ------------------------------------------------------------ |
| 姓名   | 选修的   | Service Weaver 应用程序的名称。如果不存在，则应用程序的名称源自二进制文件的名称。 |
| 二进制 | 必需的   | 已编译的 Service Weaver 应用程序。二进制路径（如果不是绝对路径）应相对于包含配置文件的目录。 |
| 参数   | 选修的   | 传递给二进制文件的命令行参数。                               |
| env    | 选修的   | 在二进制文件执行之前设置的环境变量。                         |
| 并置   | 选修的   | 托管组列表。当部署同一主机组中的两个组件时，它们会部署在同一个操作系统进程中，其中它们之间的所有方法调用都按照常规 Go 方法调用执行。为了避免歧义，组件必须以其完整的包路径作为前缀（例如 `github.com/example/sandy/` ）。请注意，可执行文件中主包的完整包路径是 `main` 。 |
| 推出   | 选修的   | 推出新版本的应用程序需要多长时间。有关部署的更多信息，请参阅 GKE 部署部分。 |

配置文件还可以包含特定于侦听器和特定于组件的配置部分。有关详细信息，请参阅组件配置部分。

#  常见问题解答

### 使用 Service Weaver 时是否需要担心网络错误？

是的。虽然 Service Weaver 允许您将应用程序编写为单个二进制文件，但分布式部署程序（例如多进程、gke）可能会将您的组件放置在单独的进程/机器上。这意味着这些组件之间的方法调用将作为远程过程调用执行，从而导致应用程序中可能出现网络错误。

为了安全起见，我们建议您假设所有跨组件方法调用都涉及网络，无论实际的组件放置如何。如果这过于繁琐，您可以显式地将相关组件放在同一个主机托管组中，确保它们始终在同一个操作系统进程中运行。

注意：Service Weaver 保证所有系统错误都以 `weaver.RemoteCallError` 的形式呈现给应用程序代码，这可以按照前面部分中所述的方式进行处理。

### Service Weaver 面向哪些类型的分布式应用程序？

Service Weaver 主要针对分布式服务系统。这些是在线系统，需要在用户请求到达时对其进行处理。例如，Web 应用程序或 API 服务器都是服务系统。 Service Weaver 通过以下方式针对服务系统定制其功能集和运行时假设：

- 网络服务器集成到框架中。应用程序可以轻松获取网络侦听器并在其上创建 HTTP 服务器。
- 推出已内置于框架中。用户指定推出持续时间，框架逐渐将网络流量从旧版本转移到新版本。
- 所有组件均被复制。对组件的请求可以发送到其任何一个副本。副本可以根据负载自动缩放。

### 数据处理应用程序怎么样？我可以使用 Service Weaver 来完成这些任务吗？

理论上，您可以将 Service Weaver 用于数据处理应用程序，尽管您会发现它对一些常见数据处理功能（例如检查点、故障恢复、重新启动等）提供很少的支持。

此外，Service Weaver 的复制模型意味着组件副本可以根据负载自动扩展和缩减。这可能是您在数据处理应用程序中不希望出现的情况。这种放大/缩小行为甚至会转换为应用程序的 `main()` 功能，并可能导致数据处理程序运行多次。

### 为什么 Service Weaver 不提供自己的数据存储？

不同的应用程序有不同的存储需求（例如全局复制、性能、SQL/NoSQL）。还有无数的存储系统在不同的维度（例如价格、性能、API）上进行不同的权衡。

我们认为，通过将自己插入到应用程序的数据模型中，我们无法提供足够的价值。我们也不想限制应用程序与其数据交互的方式（例如，离线数据库更新）。出于这些原因，我们将数据存储的选择留给了应用程序。

### 缺乏数据存储集成是否会限制 Service Weaver 应用程序的可移植性？

是的，在某种程度上。如果您使用全球可访问的数据存储系统，那么您可以真正在任何地方运行您的应用程序，从而消除任何可移植性问题。

但是，如果您在部署环境中运行存储系统（例如，在 Cloud VPN 中运行的 MySQL 实例），那么如果您在不同的环境（例如，您的桌面）中启动应用程序，它可能无法访问存储系统。在这种情况下，我们通常建议您为不同的应用程序环境创建不同的存储系统，并使用 Service Weaver 配置文件将您的应用程序指向给定执行环境的正确存储系统。

如果您使用 SQL，Go 的 sql 包有助于将您的代码与底层存储系统中的一些差异隔离开来。请参阅 Service Weaver 的聊天应用程序示例，了解如何设置应用程序以使用环境本地存储系统。

### Service Weaver 版本控制方法是否意味着我最终将在部署期间运行应用程序的多个实例？那不是很贵吗？

正如我们在 GKE 版本控制部分中所述，我们利用自动扩展和蓝/绿部署的组合来最大限度地降低在部署期间运行同一应用程序的多个版本的成本。

一般来说，由部署者实施来确保最小化部署成本。我们预计大多数云部署者将使用与 GKE 类似的技术来最大限度地降低部署成本。其他部署程序可能会选择简单地运行完整的每个版本服务树，例如多进程部署程序。

### Service Weaver的微服务开发模式相当独特。它是否反对传统的微服务开发？

不。我们承认，开发人员选择为不同的微服务运行单独的二进制文件（例如，不同的团队控制自己的二进制文件）仍然有充分的理由。然而，我们相信 Service Weaver 的模块化整体模型适用于许多常见用例，并且可以与传统的微服务模型结合使用。

例如，团队可能决定将其控制下的所有服务统一到单个 Service Weaver 应用程序中。跨团队交互仍将在传统模型中处理，并具有该模型带来的所有版本控制和开发影响。

### 对于分布式应用程序开发来说，编写“单体”难道不是朝着错误方向迈出的一步吗？

Service Weaver 试图鼓励模块化整体模型，其中应用程序被编写为作为单独的微服务运行的单个模块化二进制文件。这与整体模型不同，在整体模型中，二进制文件作为单个（复制）服务运行。

我们相信 Service Weaver 的模块化整体模型具有两全其美的优点：易于开发整体应用程序，同时具有微服务的运行时优势。



## 附录

### 参考文章

+ https://atoo.hashnode.dev/gingonic-service-weaver

### 使用模板创建项目
可以使用官方的模板仓库创建项目
```bash
$ go install golang.org/x/tools/cmd/gonew@latest
$ gonew github.com/ServiceWeaver/template example.com/foo
```
