---
title: "Golang编译进阶[译]"
date: 2023-09-01
tags: ["golang"]
draft: false
---
> 本文翻译自 https://dev.to/jacktt/go-build-in-advance-4o8n

## I/构建选项

以下是 `go build` 命令最常用的一些选项：

- `-o` ：指定输出文件名。默认输出文件名是主包的名称，Windows 上添加 `.exe` 后缀。
- `-v` ：详细输出。此选项在编译包时打印包的名称。
- `-work` ：打印临时工作目录的名称，退出时不删除。该选项对于调试很有用。
- `-x` ：打印命令。此选项打印 `go build` 命令正在执行的命令。
- `-asmflags` ：传递给 `go tool asm` 调用的参数。
- `-buildmode` ：要使用的构建模式。默认构建模式是 `exe` 。其他可能的值有 `shared` 、 `pie` 和 `plugin` 。
- `-buildvcs` ：是否使用版本控制信息标记二进制文件。默认值为 `auto` 。

有关 `go build` 命令的更多信息，您可以运行以下命令：

```
go help build
```

## II/ 将包含哪些文件

当您在 Go 中使用 `go build` 命令时，它会编译当前目录及其子目录中的 Go 源文件以创建可执行二进制文件。默认情况下，Go 只编译 `.go` 文件，忽略目录中的其他类型的文件。然而，值得注意的是 `go build` 命令的行为可能会受到构建标签、构建约束的影响。

`go build` 通常会忽略以下类型的文件：

**1. 具有非 `.go` 扩展名的文件：**

目录中任何没有 `.go` 扩展名的文件都将被忽略。这包括文本文件、配置文件、图像等。

**2.子目录中的文件：**

`go build` 命令编译当前目录及其子目录中的所有 `.go` 文件。其他文件和目录通常会被忽略。

**3.以下划线或句点开头的文件：**

以 `"."` 或 `"_"` 开头的目录和文件名会被 go 工具忽略，名为“testdata”的目录也是如此。

**4. 构建约束排除的文件：**

Go 支持构建约束，允许您根据目标操作系统或体系结构等条件在构建中包含或排除特定文件。例如，在为非 Windows 平台构建时，具有诸如 `// +build windows` 之类的构建约束的文件将被忽略。

**5. 构建标签排除的文件：**

构建标签是 Go 源文件中的特殊注释，可用于根据自定义条件指定应在构建中包含哪些文件。带有与构建上下文不匹配的构建标签的文件将被忽略。

6. 名为“testdata”的目录中的文件： 名为 `testdata` 的目录中的文件在设计上会被忽略。该目录通常用于包含不需编译的与测试相关的数据。

## III/ 构建标签

Go 的构建标签提供了一种强大的机制，用于在构建过程中包含或排除特定代码。通过使用构建标签，开发人员可以定制他们的应用程序，以适应不同的构建配置、环境或特定于平台的要求。在处理交叉编译或为特定操作系统创建二进制文件时，此功能特别有价值。

构建标签是放置在 Go 源文件开头的注释，指定一组条件，在这些条件下，应在构建中包含或排除该文件中的代码。语法是 // +build 。例如，考虑这样一个场景：您只想在构建特定版本的应用程序时包含特定的代码段：

```
main.go
package main

import "fmt"

var version string

func main() {
    fmt.Println(version)
}
```

```
pro.go
// +build pro

package main

func init() {
    version = "pro"
}
```

```
free.go
// +build free

package main

func init() {
    version = "pro"
}
```

当您使用 `-tags=free` 构建时，输出将为 `free` ，因为包含了 `free.go` 文件。当您使用 `-tags=pro` 构建时，输出将为 `pro` 。

### 构建标签语法

您可以像编程中任何其他条件语句一样组合约束，即 AND、OR、NOT

**NOT**

```
// +build !cgo
```

如果未启用 CGO，这只会在构建中包含该文件。

**AND**

```
// +build cgo darwin
```

如果启用了 CGO 并且 GOOS 设置为 darwin，则只会在构建中包含该文件。

**OR**

```
// +build darwin,linux
```

 **将它们全部组合起来，例如**

```
// +build linux,386 darwin,!cgo
```



结果为 (linux AND 386) OR (darwin AND (NOT cgo))。

## IV/构建约束

虽然自定义构建标签是使用标签构建标志设置的，但 golang 会根据环境变量和其他因素自动设置一些标签。这是可用标签的列表

**1. OOS 和 GOARCH 环境价值观**

您可以在源代码中设置约束，以便仅在使用特定 GOOS 或 GOARCH 时运行文件。例如

```
// +build darwin,amd64

package utils
```



 **2. GO版本限制**

您还可以将文件包含到构建整个模块时使用的 go 版本。 EX 仅在使用的 go 版本为 1.12 及更高版本时构建文件，您将使用 `// +build go1.18` 。如果 go 版本是 1.18 或 1.21（撰写本文时最新版本），这将包括该文件。

##  参考

- https://kofo.dev/build-tags-in-golang
- https://pkg.go.dev/cmd/go
- https://www.digitalocean.com/community/tutorials/customizing-go-binaries-with-build-tags
