---
title: "HashCorp go-plugin包使用备忘"
date: 2023-08-04
tags: ["hashcorp", "golang","plugin"]
draft: true
---
## 介绍

> 下面内容机翻自官网

HashiCorp 插件系统通过启动子进程并通过 RPC 进行通信（使用标准 `net/rpc` 或 gRPC）来工作。任何插件和主机进程之间都会建立一个连接。对于基于 net/rpc 的插件，我们使用连接复用库来复用顶部的任何其他连接。对于基于 gRPC 的插件，HTTP2 协议处理多路复用。

这种架构有很多好处：

- 插件不能使您的主机进程崩溃：插件中的panic不会使插件用户panic。
- 插件非常容易编写：只需编写一个 Go 应用程序和 `go build` 。或者使用任何其他语言编写带有少量样板的 gRPC 服务器来支持 go-plugin。
- 插件非常容易安装：只需将二进制文件放在主机可以找到它的位置（取决于主机，但该库还提供帮助程序），插件主机会处理其余的事情。
- 插件可以相对安全：插件只能访问为其提供的接口和参数，而不能访问进程的整个内存空间。此外，go-plugin 可以通过 TLS 与插件进行通信。

## 使用步骤

> 下面内容机翻自官网

要使用插件系统，您必须执行以下步骤。这些是必须完成的高级步骤。示例可在 `examples/` 目录中找到。

1. 选择您想要为插件公开的接口。
2. 对于每个接口，实现该接口的实现，通过 `net/rpc` 连接或 gRPC 连接或两者进行通信。您必须同时实现客户端和服务器实现。
3. 创建一个知道如何为给定插件类型创建 RPC 客户端/服务器的 `Plugin` 实现。
4. 插件作者调用 `plugin.Serve` 从 `main` 函数提供插件。
5. 插件用户使用 `plugin.Client` 启动子进程并通过 RPC 请求接口实现。

## 例子

### 计算年龄的服务

#### 准备proto文件

proto定义

```protobuf
syntax = "proto3";
package proto;
option go_package="proto/v1;age";

message CalcAgeResponse {
    string message = 1;
    int32  age = 2;
}

message CalcAgeRequest {
    string birthday = 1;
}

service AgeService {
    rpc GetAge(CalcAgeRequest) returns (CalcAgeResponse);
}
```

项目结构

```
│  go.mod
│  go.sum
└─proto
    └─v1
       └─ age_svc.proto
```

执行命令 `protoc -I . .\proto\v1\age_svc.proto --go-grpc_out=. --go_out=.` 生成文件

#### 定义接口

### 双向通信



## 参考链接
+ https://eli.thegreenplace.net/2023/rpc-based-plugins-in-go/
+ https://zerofruit-web3.medium.com/hashicorp-plugin-system-design-and-implementation-5f939f09e3b3