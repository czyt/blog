---
title: "Buf使用备忘"
date: 2023-07-29
tags: ["golang", "protobuf", "buf"]
draft: false
---

Buf 工具针对于Schema驱动、基于 Protobuf 的 API 开发，为服务发布者和服务客户端提供可靠和更好的用户体验。简化了您的 Protobuf 管理策略，以便您可以专注于重要的事情。
## 下载安装

可以直接去buf的GitHub的[release](https://github.com/bufbuild/buf/releases/latest)页面下载，其他的安装方式参考[官方文档](https://buf.build/docs/installation)

## 使用

### 三个yaml文件

初次接触buf项目的时候，有个疑问就是buf项目中`buf.yaml` `buf.gen.yaml` `buf.work.yaml`这个三个文件的区别和用途。下面是简单的一个表，列出了三个文件的区别：

| 文件名        | 文件位置                  | 说明                                                         |
| ------------- | ------------------------- | ------------------------------------------------------------ |
| buf.yaml      | 每个proto模块定义的根目录 | buf.yaml 配置的位置告诉 buf 在哪里搜索 .proto 文件，模块的依赖项以及如何处理导入 |
| buf.gen.yaml  | 一般放在仓库的根目录      | 文件控制 `buf generate` 命令如何针对任何输入执行 `protoc` 插件 |
| buf.work.yaml | 一般放在仓库的根目录      | 定义项目需要哪些proto模块                                    |

示例目录结构：

```yaml
.
├── buf.gen.yaml
├── buf.work.yaml
├── proto
│   ├── acme
│   │   └── weather
│   │       └── v1
│   │           └── weather.proto
│   └── buf.yaml
└── vendor
    └── protoc-gen-validate
        ├── buf.yaml
        └── validate
            └── validate.proto


```
一个[buf.yaml](https://buf.build/docs/configuration/v1/buf-yaml)的样例，可以通过`buf mod init`来创建：

```yaml
version: v1
breaking:
  use:
    - FILE
lint:
  use:
    - DEFAULT
build:
  excludes:
    - foo/bar

```

> 注：迁移相关，请参考[Migrate from Prototool](https://buf.build/docs/how-to/migrate-from-prototool#prototool-pros)

一个[buf.gen.yaml](https://buf.build/docs/configuration/v1/buf-gen-yaml)的样例：

```yaml
version: v1
plugins:
  - plugin: go
    out: gen/go
    opt: paths=source_relative
  - plugin: go-grpc
    out: gen/go
    opt:
      - paths=source_relative
      - require_unimplemented_servers=false

```
buf可以远程proto插件方式，本地不需要安装插件。远程插件生成输入代码。输入可以是 git 存储库、tarball、zip 文件、包含使用 `buf.yaml` 配置文件配置的 Protobuf 文件的本地目录。
上面的文件使用远程插件可以改成下面内容：
```yaml
version: v1
plugins:
  - plugin: buf.build/protocolbuffers/go
    out: gen/go
    opt: paths=source_relative
  - plugin: go-grpc
    out: gen/go
    opt:
      - paths=source_relative
      - require_unimplemented_servers=false
```
更多内容，可以参考 [Never install Protobuf plugins again with remote plugins](https://buf.build/docs/bsr/remote-plugins/usage)


一个[buf.work.yaml](https://buf.build/docs/configuration/v1/buf-work-yaml)的样例

```yaml
version: v1
directories:
  - paymentapis
  - petapis
```

### 命令行选项

#### RPC客户端

buf的curl子命令可用来调用 gRPC 或 Connect 的服务器上的HTTP 服务。

```bash
$ buf curl --schema buf.build/bufbuild/eliza  \
     --data '{"name": "Bob Loblaw"}'          \
     https://demo.connect.build/buf.connect.demo.eliza.v1.ElizaService/Introduce
```

默认调用的是buf自研的Connect RPC，调用gRPC需要使用`--protocol`指定

```bash
$ buf curl --schema . --protocol grpc --http2-prior-knowledge  \
     http://localhost:20202/foo.bar.v1.FooService/DoSomething
```

参考 [官方文档](https://buf.build/docs/reference/cli/buf/curl#usage)

### 发布Buf 模块

参考

+ [Try the Buf Schema Registry](https://buf.build/docs/tutorials/getting-started-with-bsr) 
+ [Organize Protobuf files into modules](https://buf.build/docs/how-to/create-and-push-module)



更多参数选项，请参考 [buf命令行选项](https://buf.build/docs/reference/cli/buf)

## 参考链接

+ [Using buf.build to generate your gRPC codes](https://vchitai.medium.com/using-buf-build-to-generate-your-grpc-codes-44e1811d5291)
