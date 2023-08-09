---
title: "在GO中使用日志库slog"
date: 2023-08-09
tags: ["golang", "slog"]
draft: false
---

> 本文根据两篇文章机翻拼凑而来。两篇文章发布时，slog还未进入标准库。golang 1.21.0 于2023-08-09发布，slog也包含在正式库中，本文根据原文内容进行了部分的修订和补充。

## 什么是slog？ #


slog 是 Go 团队的一个实验性日志记录包，提供结构化日志记录的功能。


本文向您概述了此包中的日志记录功能。

##  安装 ＃

创建一个新的 go 项目并引入 `log/slog`

##  使用记录器#


立即导入并开始使用记录器。

```go
package main

import (
	"log/slog"
)

func main() {
	slog.Info("Go is best language!")
}
```

 输出：

```
$ go run main.go
2022/12/15 01:31:23 INFO Go is best language!
```


默认情况下，输出包括时间、日志级别和消息。


以下日志级别可用。

```go
Debug
Info
Warn
Error
```

##  结构化日志#


`slog` 是一个结构化记录器，支持两种格式的日志记录：文本和 json。


让我们看一下文本记录器。

##  文本处理程序#


您首先创建一个文本处理程序和一个新的记录器。

```go
package main

import (
	"os"

	"log/slog"
)

func main() {
	textHandler := slog.NewTextHandler(os.Stdout,nil)
	logger := slog.New(textHandler)

	logger.Info("Go is the best language!")
}
```

 输出：

```bash
$ go run main.go
time=2022-12-15T01:41:25.277-05:00 level=INFO msg="Go is the best language!"
```


密切注意，您将看到输出格式为键=值对。这通常也称为 logfmt 格式。


许多现代系统可以处理 logfmt 格式的日志。例如，DataDog、Splunk、Grafana Loki。 Logfmt 是人类可读的并且相当容易解析。

##  JSON 处理程序 #


您还可以以 JSON 格式输出日志，您所要做的就是关闭处理程序。

```go
package main

import (
	"os"

	"log/slog"
)

func main() {
	jsonHandler := slog.NewJSONHandler(os.Stdout,nil)  // 👈
	logger := slog.New(jsonHandler)

	logger.Info("Go is the best language!")
}
```

 输出：

```bash
$ go run main.go
{"time":"2022-12-17T18:05:48.479126-05:00","level":"INFO","msg":"Go is the best language!"}
```


每个日志都记录为 json 对象，其中包含属性。

##  具体类型的属性


slog 是一个结构化记录器，提供指定属性的能力。

```go
package main

import (
	"os"

	"log/slog"
)

func main() {
	textHandler := slog.NewTextHandler(os.Stdout,nil)
	logger := slog.New(textHandler)

	logger.Info("Usage Statistics", slog.Int("current-memory", 50))
}
```

 输出：

```
$ go run main.go
time=2022-12-17T18:28:38.246-05:00 level=INFO msg="Usage Statistics" current-memory=50
```


在上面的示例中，使用 `slog.Int` 添加了整数属性。


可以使用各种类型的属性：

```
String
Int64
Int
Uint64
Float64
Bool
Time
Duration
```


您可以根据需要添加任意数量的属性。

```go
package main

import (
	"os"

	"log/slog"
)

func main() {
	textHandler := slog.NewTextHandler(os.Stdout,nil)
	logger := slog.New(textHandler)

	logger.Info("Usage Statistics",
		slog.Int("current-memory", 50),
		slog.Int("min-memory", 20),
		slog.Int("max-memory", 80),
		slog.Int("cpu", 10),
		slog.String("app-version", "v0.0.1-beta"),
	)
}
```

 输出：

```bash
$ go run main.go
time=2022-12-17T18:34:12.781-05:00 level=INFO msg="Usage Statistics" current-memory=50 min-memory=20 max-memory=80 cpu=10 app-version=v0.0.1-beta
```

##  Group


您可以将属性分组到单个键下。例如，所有内存属性都可以分组在 `memory` 键下。

```go
package main

import (
	"os"

	"log/slog"
)

func main() {
	textHandler := slog.NewTextHandler(os.Stdout,nil)
	logger := slog.New(textHandler)

	logger.Info("Usage Statistics",
		slog.Group("memory",
			slog.Int("current", 50),
			slog.Int("min", 20),
			slog.Int("max", 80)),
		slog.Int("cpu", 10),
		slog.String("app-version", "v0.0.1-beta"),
	)
}
```

 输出：

```bash
$ go run main.go
time=2022-12-17T18:36:46.660-05:00 level=INFO msg="Usage Statistics" memory.current=50 memory.min=20 memory.max=80 cpu=10 app-version=v0.0.1-beta
```


使用 `JsonHandler` json 中的输出如下所示。

```bash
$ go run main.go | jq
{
  "time": "2022-12-17T18:38:04.74786-05:00",
  "level": "INFO",
  "msg": "Usage Statistics",
  "memory": {
    "current": 50,
    "min": 20,
    "max": 80
  },
  "cpu": 10,
  "app-version": "v0.0.1-beta"
}
```

##  自定义属性


假设您希望有一个属性应该包含在生成的所有日志中，此类属性的示例包括服务名称、应用程序版本。


您可以将属性附加到将包含在每个日志语句中的处理程序。

```go
package main

import (
	"context"
	"os"

	"log/slog"
)

func main() {
	textHandler := slog.NewTextHandler(os.Stdout,nil).
		WithAttrs([]slog.Attr{slog.String("app-version", "v0.0.1-beta")}) // 👈 add attributes to all logs
	logger := slog.New(textHandler)

	logger.Info("Generating statistics")
	logger.Info("Usage Statistics",
		slog.Group("memory",
			slog.Int("current", 50),
			slog.Int("min", 20),
			slog.Int("max", 80)),
		slog.Int("cpu", 10),
	)
}
```

 输出：

```bash
$ go run main.go
time=2022-12-17T20:21:27.664-05:00 level=INFO msg="Generating statistics" app-version=v0.0.1-beta
time=2022-12-17T20:21:27.664-05:00 level=INFO msg="Usage Statistics" app-version=v0.0.1-beta memory.current=50 memory.min=20 memory.max=80 cpu=10
```


您可以看到两个日志中都包含 `app-version` 属性。在处理程序上使用 `WithAttrs` 函数指定的属性将包含在所有日志中。

##  Context


理想情况下，您希望创建一个具有某些配置、属性的单个记录器，并在整个应用程序中使用它。


slog 具有`Context`结尾函数，可让您在 `context` 内传递上下文，这里我们以传递一个自定义的Logger为例。

```go
package main

import (
	"context"
	"os"

	"log/slog"
)

const (
	contextKey = "logger"
)

func main() {
	textHandler := slog.NewTextHandler(os.Stdout, nil).
		WithAttrs([]slog.Attr{slog.String("app-version", "v0.0.1-beta")})
	logger := slog.New(textHandler)
	ctx := context.WithValue(context.Background(), contextKey, logger)
	// 👈 context containing logger
	sendUsageStatus(ctx)
}

func sendUsageStatus(ctx context.Context) {
	l := ctx.Value(contextKey).(*slog.Logger)
	l.InfoContext(ctx, "Usage Statistics",
		slog.Group("memory",
			slog.Int("current", 50),
			slog.Int("min", 20),
			slog.Int("max", 80)),
		slog.Int("cpu", 10),
	)
}
```

 输出：

```bash
$ go run main.go
time=2022-12-17T20:27:58.797-05:00 level=INFO msg="Generating statistics" app-version=v0.0.1-beta
time=2022-12-17T20:27:58.797-05:00 level=INFO msg="Usage Statistics" app-version=v0.0.1-beta memory.current=50 memory.min=20 memory.max=80 cpu=10
```

##  日志级别记录 #


如果您使用默认记录器，它不会记录调试日志，因为默认日志级别为 `Info` 。


您可以创建一个新的记录器，并将默认日志级别设置为 `Debug` 以显示调试日志。

```go
package main

import (
	"os"

	"log/slog"
)

func main() {
	opts := slog.HandlerOptions{
		Level: slog.LevelDebug,
	}

	textHandler := opts.NewTextHandler(os.Stdout)
	logger := slog.New(textHandler)

	logger.Debug("Debug")
	logger.Info("Info")
	logger.Warn("Warn")
}
```

 输出：

```bash
$ go run main.go
time=2022-12-17T23:28:29.130-05:00 level=DEBUG msg=Debug
time=2022-12-17T23:28:29.130-05:00 level=INFO msg=Info
time=2022-12-17T23:28:29.130-05:00 level=WARN msg=Warn
```

## 创建和使用子Logger

在特定程序范围内的所有记录中包含相同的属性有助于确保它们的存在而无需重复的日志记录语句。这就是子Logger证明有用的地方，因为它们创建继承自父Logger的日志记录Context，同时允许添加其他字段。

在 slog 中，创建子Logger是使用 `Logger.With()` 方法完成的。它接受一个或多个键/值对，并返回一个包含指定属性的新 `Logger` 。考虑以下代码片段，它将程序的进程 ID 和用于编译的 Go 版本添加到每个日志记录，并将它们存储在 `program_info` 属性中：

有时，在程序给定范围内生成的所有记录中包含相同的属性会很有帮助，以便它们出现在所有记录中，而不会在日志点重复。这就是子Logger派上用场的地方，因为它们创建了一个从父Logger继承的新Context，但带有附加字段。

在 `slog` 中创建子记录器是通过 `Logger` 上的 `With()` 方法完成的，该方法接受强类型和松散类型键/值对的混合并返回一个新的 `Logger` 实例。例如，下面的代码片段将程序的进程 ID 和用于将其编译到 `program_info` 属性中的每个日志记录的 Go 版本添加：

```go
func main() {
    handler := slog.NewJSONHandler(os.Stdout, nil)
    buildInfo, _ := debug.ReadBuildInfo()

    logger := slog.New(handler)

    child := logger.With(
        slog.Group("program_info",
            slog.Int("pid", os.Getpid()),
            slog.String("go_version", buildInfo.GoVersion),
        ),
    )

    . . .
}
```

完成此配置后， `child` 记录器创建的所有记录都将包含 `program_info` 属性下的指定属性，只要它在日志点未被覆盖：

```go
func main() {
    . . .

    child.Info("image upload successful", slog.String("image_id", "39ud88"))
    child.Warn(
        "storage is 90% full",
        slog.String("available_space", "900.1 mb"),
    )
}
```

 输出

```json
{
  "time": "2023-02-26T19:26:46.046793623+01:00",
  "level": "INFO",
  "msg": "image upload successful",
  "program_info": {
    "pid": 229108,
    "go_version": "go1.20"
  },
  "image_id": "39ud88"
}
{
  "time": "2023-02-26T19:26:46.046847902+01:00",
  "level": "WARN",
  "msg": "storage is 90% full",
  "program_info": {
    "pid": 229108,
    "go_version": "go1.20"
  },
  "available_space": "900.1 MB"
}
```

您还可以使用 `WithGroup()` 方法创建一个启动组的子记录器，以便添加到记录器的所有属性（包括在日志点添加的属性）都将嵌套在组名称下：

```go
handler := slog.NewJSONHandler(os.Stdout, nil)
buildInfo, _ := debug.ReadBuildInfo()
logger := slog.New(handler).WithGroup("program_info")

child := logger.With(
  slog.Int("pid", os.Getpid()),
  slog.String("go_version", buildInfo.GoVersion),
)

child.Info("image upload successful", slog.String("image_id", "39ud88"))
child.Warn(
  "storage is 90% full",
  slog.String("available_space", "900.1 MB"),
)
```

 输出

```json
{
  "time": "2023-05-24T19:00:18.384085509+01:00",
  "level": "INFO",
  "msg": "image upload successful",
  "program_info": {
    "pid": 1971993,
    "go_version": "go1.20.2",
    "image_id": "39ud88"
  }
}
{
  "time": "2023-05-24T19:00:18.384136084+01:00",
  "level": "WARN",
  "msg": "storage is 90% full",
  "program_info": {
    "pid": 1971993,
    "go_version": "go1.20.2",
    "available_space": "900.1 mb"
  }
}
```

## 自定义日志级别

`slog` 包默认提供四种日志级别，每个级别都与一个整数值关联： `DEBUG` (-4)、 `INFO` (0)、< b3> (4) 和 `ERROR` (8)。每个级别之间 4 的差距是经过深思熟虑的设计决策，旨在适应默认级别之间具有自定义级别的日志记录方案。例如，您可以在 `INFO` 和 `WARN` 之间创建值为 1、2 或 3 的自定义 `NOTICE` 级别。

您可能已经注意到，默认情况下所有记录器都配置为在 `INFO` 级别记录，这会导致以较低严重性记录的事件（例如 `DEBUG` ）被抑制。您可以通过 HandlerOptions 类型自定义此行为，如下所示：

```go
func main() {
    opts := &slog.HandlerOptions{
        Level: slog.LevelDebug,
    }

    handler := slog.NewJSONHandler(os.Stdout, opts)

    logger := slog.New(handler)
    logger.Debug("Debug message")
    logger.Info("Info message")
    logger.Warn("Warning message")
    logger.Error("Error message")
}
```

 输出

```json
{"time":"2023-05-24T19:03:10.70311982+01:00","level":"DEBUG","msg":"Debug message"}
{"time":"2023-05-24T19:03:10.703187713+01:00","level":"INFO","msg":"Info message"}
{"time":"2023-05-24T19:03:10.703190419+01:00","level":"WARN","msg":"Warning message"}
{"time":"2023-05-24T19:03:10.703192892+01:00","level":"ERROR","msg":"Error message"}
```

请注意，此方法在 `handler` 的整个生命周期中固定其最低级别。如果您需要动态改变最低级别，则必须使用 `LevelVar` 类型，如下所示：

```go
logLevel := &slog.LevelVar{} // INFO

opts := slog.HandlerOptions{
  Level: logLevel,
}

// you can change the level anytime like this
logLevel.Set(slog.LevelDebug)
```

### 创建自定义日志级别

如果您需要超出 slog 默认提供的自定义级别，您可以通过实现由单个方法定义的 Leveler 接口来创建它们：

```go
type Leveler interface {
    Level() Level
}
```

通过 `Level` 类型实现 `Leveler` 接口也很容易，如下所示（因为 `Level` 本身实现了 `Leveler` ）：

```go
const (
    LevelTrace  = slog.Level(-8)
    LevelNotice = slog.Level(2)
    LevelFatal  = slog.Level(12)
)
```

如上所述定义自定义级别后，您可以按如下方式使用它们：



```go
opts := &slog.HandlerOptions{
    Level: LevelTrace,
}

logger := slog.New(slog.NewJSONHandler(os.Stdout, opts))

ctx := context.Background()
logger.Log(ctx, LevelTrace, "Trace message")
logger.Log(ctx, LevelNotice, "Notice message")
logger.Log(ctx, LevelFatal, "Fatal level")
```

 输出

```json
{"time":"2023-02-24T09:26:41.666493901+01:00","level":"DEBUG-4","msg":"Trace level"}
{"time":"2023-02-24T09:26:41.66659754+01:00","level":"INFO+2","msg":"Notice level"}
{"time":"2023-02-24T09:26:41.666602404+01:00","level":"ERROR+4","msg":"Fatal level"}
```

请注意自定义级别是如何根据默认值进行标记的。这可能不是您想要的，因此您应该通过 `HandlerOptions` 类型自定义级别名称：

```go
. . .

var LevelNames = map[slog.Leveler]string{
    LevelTrace:      "TRACE",
    LevelNotice:     "NOTICE",
    LevelFatal:      "FATAL",
}

func main() {
    opts := slog.HandlerOptions{
        Level: LevelTrace,
        ReplaceAttr: func(groups []string, a slog.Attr) slog.Attr {
            if a.Key == slog.LevelKey {
                level := a.Value.Any().(slog.Level)
                levelLabel, exists := LevelNames[level]
                if !exists {
                    levelLabel = level.String()
                }

                a.Value = slog.StringValue(levelLabel)
            }

            return a
        },
    }

    . . .
}
```

 输出

```json
{"time":"2023-02-24T09:27:51.747625912+01:00","level":"TRACE","msg":"Trace level"}
{"time":"2023-02-24T09:27:51.747732118+01:00","level":"NOTICE","msg":"Notice level"}
{"time":"2023-02-24T09:27:51.747737319+01:00","level":"FATAL","msg":"Fatal level"}
```

`ReplaceAttr()` 函数用于自定义 `Record` 中的每个键/值对如何由 `Handler` 处理。它可用于自定义键的名称，或以某种方式转换值。在上面的示例中，它将自定义日志级别映射到各自的标签： `TRACE` 、 `NOTICE` 和 `FATAL` 。

##  自定义处理程序

如前所述， `TextHandler` 和 `JSONHandler` 都可以使用 `HandlerOptions` 类型进行自定义。您已经了解了如何在记录属性之前调整最低级别和修改属性。可以通过 `HandlerOptions` 完成的另一个自定义是添加日志消息的源（如果需要）：

```go
opts := slog.HandlerOptions{
  AddSource: true,
  Level: slog.LevelDebug,
}
```

 输出

```json
{"time":"2023-05-24T19:39:27.005871442+01:00","level":"DEBUG","source":{"function":"main.main","file":"/home/ayo/dev/demo/slog/main.go","line":30},"msg":"Debug message"}
{"time":"2023-05-24T19:39:27.005940778+01:00","level":"INFO","source":{"function":"main.main","file":"/home/ayo/dev/demo/slog/main.go","line":31},"msg":"Info message"}
{"time":"2023-05-24T19:39:27.00594459+01:00","level":"WARN","source":{"function":"main.main","file":"/home/ayo/dev/demo/slog/main.go","line":32},"msg":"Warning message"}
{"time":"2023-05-24T19:39:27.005947669+01:00","level":"ERROR","source":{"function":"main.main","file":"/home/ayo/dev/demo/slog/main.go","line":33},"msg":"Error message"}
```

根据应用程序环境切换处理程序也很容易。例如，您可能更喜欢使用 `TextHandler` 作为开发日志，因为它更容易阅读，然后在生产中切换到 `JSONHandler` 以获得与各种日志记录工具的更好兼容性。您可以通过环境变量轻松启用此类行为：

```go
var appEnv = os.Getenv("APP_ENV")

func main() {
    opts := &slog.HandlerOptions{
        Level: slog.LevelDebug,
    }

    var handler slog.Handler = slog.NewTextHandler(os.Stdout, opts)
    if appEnv == "production" {
        handler = slog.NewJSONHandler(os.Stdout, opts)
    }

    logger := slog.New(handler)

    logger.Info("Info message")
}
```

```command
go run main.go
```

 输出

```text
time=2023-02-24T10:36:39.697+01:00 level=INFO msg="Info message"
```

```command
APP_ENV=production go run main.go
```

 输出

```json
{"time":"2023-02-24T10:35:16.964821548+01:00","level":"INFO","msg":"Info message"}
```

### 创建自定义处理程序

由于 `Handler` 是一个接口，因此您还可以创建自定义处理程序来以不同方式格式化日志，或将它们写入其他目标。其签名如下：

```go
type Handler interface {
    Enabled(context.Context, Level) bool
    Handle(context.Context, r Record) error
    WithAttrs(attrs []Attr) Handler
    WithGroup(name string) Handler
}
```

以下是每个方法的作用：

- `Enabled()` 根据日志记录的级别确定是否应处理或丢弃该日志记录。 `context` 也可以用来做出决定。
- `Handle()` 处理发送到处理程序的每个日志记录。仅当 `Enabled()` 返回 `true` 时才调用它。
- `WithAttrs()` 从现有处理程序创建一个新处理程序，并为其添加指定的属性。
- `WithGroup()` 从现有处理程序创建一个新处理程序，并向其中添加指定的组名称，以便后续属性由该名称限定。

下面是一个使用 `log` 、 `json` 和 color 包来实现日志记录的美化开发输出的示例：

handler.go

```go
// NOTE: Not well tested, just an illustration of what's possible
package main

import (
    "context"
    "encoding/json"
    "io"
    "log"

    "github.com/fatih/color"
    "log/slog"
)

type PrettyHandlerOptions struct {
    SlogOpts slog.HandlerOptions
}

type PrettyHandler struct {
    slog.Handler
    l *log.Logger
}

func (h *PrettyHandler) Handle(ctx context.Context, r slog.Record) error {
    level := r.Level.String() + ":"

    switch r.Level {
    case slog.LevelDebug:
        level = color.MagentaString(level)
    case slog.LevelInfo:
        level = color.BlueString(level)
    case slog.LevelWarn:
        level = color.YellowString(level)
    case slog.LevelError:
        level = color.RedString(level)
    }

    fields := make(map[string]interface{}, r.NumAttrs())
    r.Attrs(func(a slog.Attr) bool {
        fields[a.Key] = a.Value.Any()

        return true
    })

    b, err := json.MarshalIndent(fields, "", "  ")
    if err != nil {
        return err
    }

    timeStr := r.Time.Format("[15:05:05.000]")
    msg := color.CyanString(r.Message)

    h.l.Println(timeStr, level, msg, color.WhiteString(string(b)))

    return nil
}

func NewPrettyHandler(
    out io.Writer,
    opts PrettyHandlerOptions,
) *PrettyHandler {
    h := &PrettyHandler{
        Handler: slog.NewJSONHandler(out, &opts.SlogOpts),
        l:       log.New(out, "", 0),
    }

    return h
}
```

当您在代码中使用 `PrettyHandler` 时，如下所示：

```go
func main() {
    opts := PrettyHandlerOptions{
        SlogOpts: slog.HandlerOptions{
            Level: slog.LevelDebug,
        },
    }
    handler := NewPrettyHandler(os.Stdout, opts)
    logger := slog.New(handler)
    logger.Debug(
        "executing database query",
        slog.String("query", "SELECT * FROM users"),
    )
    logger.Info("image upload successful", slog.String("image_id", "39ud88"))
    logger.Warn(
        "storage is 90% full",
        slog.String("available_space", "900.1 MB"),
    )
    logger.Error(
        "An error occurred while processing the request",
        slog.String("url", "https://example.com"),
    )
}
```

执行程序时，您将观察到以下彩色输出：

![Screenshot from 2023-05-24 19-53-04.png](https://imagedelivery.net/xZXo0QFi-1_4Zimer-T0XQ/c62a13a4-afea-4e53-2ac3-c5c8c790b200/orig)

## 使用 LogValuer 接口隐藏敏感字段

`LogValuer` 接口允许您确定记录自定义类型时将生成什么输出。这是它的签名：

```go
type LogValuer interface {
    LogValue() Value
}
```

实现此接口的主要用例是隐藏自定义类型中的敏感字段。例如，下面的 `User` 类型未实现 `LogValuer` 接口。请注意记录类型时如何暴露敏感详细信息：

```go
// User does not implement `LogValuer` here
type User struct {
    ID        string `json:"id"`
    FirstName string `json:"first_name"`
    LastName  string `json:"last_name"`
    Email     string `json:"email"`
    Password  string `json:"password"`
}

func main() {
    handler := slog.NewJSONHandler(os.Stdout, nil)
    logger := slog.New(handler)

    u := &User{
        ID:        "user-12234",
        FirstName: "Jan",
        LastName:  "Doe",
        Email:     "jan@example.com",
        Password:  "pass-12334",
    }

    logger.Info("info", "user", u)
}
```

 输出

```json
{
  "time": "2023-02-26T22:11:30.080656774+01:00",
  "level": "INFO",
  "msg": "info",
  "user": {
    "id": "user-12234",
    "first_name": "Jan",
    "last_name": "Doe",
    "email": "jan@example.com",
    "password": "pass-12334"
  }
}
```

如果不实现 `LogValuer` 接口，整个 `User` 类型将被记录，如上所示。这是有问题的，因为该类型包含不应出现在日志中的秘密字段（例如电子邮件和密码），并且它还会使您的日志变得不必要的冗长。

您可以通过指定您希望如何在日志中处理类型来解决此问题。例如，您可以指定仅应记录 `ID` 字段，如下所示：

```go
// implement the `LogValuer` interface
func (u *User) LogValue() slog.Value {
    return slog.StringValue(u.ID)
}
```

您现在将观察到以下输出：

 输出

```json
{
  "time": "2023-02-26T22:43:28.184363059+01:00",
  "level": "INFO",
  "msg": "info",
  "user": "user-12234"
}
```

您还可以将多个属性分组，如下所示：

```go
func (u *User) LogValue() slog.Value {
    return slog.GroupValue(
        slog.String("id", u.ID),
        slog.String("name", u.FirstName+" "+u.LastName),
    )
}
```

 输出

```json
{
  "time": "2023-03-15T14:44:24.223381036+01:00",
  "level": "INFO",
  "msg": "info",
  "user": {
    "id": "user-12234",
    "name": "Jan Doe"
  }
}
```

## 原文

+ [A Comprehensive Guide to Logging in Go with Slog](https://betterstack.com/community/guides/logging/logging-in-go/#contextual-logging-in-go-with-slog)

+ https://thedevelopercafe.com/articles/logging-in-go-with-slog-a7bb489755c2 

## 相关库
+ [samber/slog-multi](https://github.com/samber/slog-multi)
