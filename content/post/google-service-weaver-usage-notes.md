---
title: "Google Service Weaver使用笔记"
date: 2023-07-04
tags: ["golang", "grpc", "google"]
draft: true
---

## 安装

### 安装gonew

安装gonew后可以使用官方的模板创建项目

```bash
go install golang.org/x/tools/cmd/gonew@latest
```
使用方法：
```bash
gonew github.com/ServiceWeaver/template example.com/foo
```
> gonew 请参考这个[discuss](https://github.com/golang/go/discussions/61669)

### 安装weaver

使用下面的命令安装：

```bash
go install github.com/ServiceWeaver/weaver/cmd/weaver@latest
```

如果使用GKE，可能还要安装

```bash
go install github.com/ServiceWeaver/weaver-gke/cmd/weaver-gke@latest
```

>注意：如果您在 macOS 上安装 `weaver` 和 `weaver gke` 命令时遇到问题，您可能需要在安装命令前加上 `export CGO_ENABLED=1; export CC=gcc` 前缀。例如：
>
>```bash
>export CGO_ENABLED=1; export CC=gcc; go install github.com/ServiceWeaver/weaver/cmd/weaver@latest
>```

