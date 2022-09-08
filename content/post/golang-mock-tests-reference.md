---
title: "Golang Mock测试参考"
date: 2022-07-25
tags: ["golang","mock"]
draft: true
---

## GoMock

gomock是官方的mock生成工具，能够很好地和go test 框架集成。mock代码的生成基于`mockgen`。

### 安装mockgen
Go 版本< 1.16
```
GO111MODULE=on go get github.com/golang/mock/mockgen@v1.6.0
```
Go版本 1.16+
```bash
go install github.com/golang/mock/mockgen@latest
```

### 使用

GoMock支持两种Mock模式：源码模式和反射模式。完整的参数列表说明如下：

若给定一个 Go 源文件，其中包含要被模拟的接口，则使用 modgen 命令为模拟类生成源代码。它支持以下参数:

- `source`: 包含要模拟的接口的文件。

- `destination`: 一个文件，用于编写源代码。如果不设置此选项，代码将打印到标准输出。

- `package`: 用于生成模拟类源代码的包。如果您没有设置它，那么包的名称就是 mock _ concatedwith 输入文件的包。

- `import`: 应该在生成的源代码中使用的显式导入列表，指定为以逗号分隔的 foo = bar/baz 格式的元素列表，其中 bar/baz 是被导入的包，foo 是生成的源代码中用于包的标识符。

- `aux_files`: 一个用于解析的附加文件列表，例如需要使用在不同文件中定义的嵌入式接口。这是以逗号分隔的 foo = bar/baz.go 格式的元素列表指定的，其中 bar/baz.go 是源文件，foo 是`-source`参数使用的文件的包名。

- `build_flags`: (仅反射模式)逐字传递标志去构建。

- `mock_names`: 生成的模拟的自定义名称列表。这是以逗号分隔的形式指定的 Repository = MockSensorRepository，Endpoint = MockSensorEndpoint 的元素列表，其中 Repository 是接口名称，MockSensorRepository 是所需的模拟名称(模拟工厂方法和模拟记录器将以模拟命名)。如果其中一个接口没有指定自定义名称，那么将使用默认命名转换规则。

- `self_package`: 生成代码的完整包导入路径。此标志的用途是通过尝试包含其自身的包来防止生成的代码中的循环引用。如果 mock 的包被设置为它的一个输入(通常是主输入) ，并且输出为 stdio，因此 mock gen 无法检测到最终的输出包，那么就会发生这种情况。设置这个标志，然后将告诉 Mockgen 排除哪个导入。

- `version_file`: 用于将版权头文件添加到生成的源代码中的版权文件。

- `debug_parser`: 仅打印解析器结果。

- `exec_only`: (反射模式)如果设置了，执行这个反射程序。

- `prog_only`: (反射模式)只生成反射程序; 将其写入标准输出并退出。

- `write_package_comments`: 如果为 true，则写包文档注释(godoc)。(默认为 true)

要获得使用 modgen 的示例，请参见 sample目录。在简单的情况下，您只需要-source 标志。

#### 源码模式

源码模式会从源码文件生成模拟的接口实现。该模式通过`-source`参数来设置。与该参数相关的参数为`-imports`和` -aux_files`。调用示例为 `mockgen -source=foo.go [other options]`

#### 反射模式

反射模式通过构建一个使用反射来理解接口的程序来生成模拟接口。通过传递两个非限制参数来启用它：导入路径和一个逗号分隔的符号列表。您可以使用 `.`参考当前路径的软件包。调用示例 

```
mockgen database/sql/driver Conn,Driver

# Convenient for `go:generate`.
mockgen . Conn,Driver
```

### 参考

+ https://github.com/golang/mock

## Ginkgo（BDD行为驱动开发）测试框架
### 安装
使用命令安装 `go install github.com/onsi/ginkgo/v2/ginkgo@latest`
## 文档
+ [官方文档](https://onsi.github.io/ginkgo/)
+ [中文文档](https://www.ginkgo.wiki)
##  网络情况模拟
＋　https://github.com/tylertreat/comcast