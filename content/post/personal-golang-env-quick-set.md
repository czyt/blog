---
title: "个人Golang环境安装快速设置"
date: 2022-03-24
tags: ["golang"]
draft: false
---

## 下载

- 官方下载  https://go.dev/dl/

- [Google 香港镜像](https://golang.google.cn/dl/)

- [Golang Downloads Mirrors](https://gomirrors.org)

  更多请参考 [Thanks Mirror](https://github.com/eryajf/Thanks-Mirror#golang)


  ## 环境设置

  设置proxy

  ```bash
  go env -w GOPROXY=https://goproxy.io,https://goproxy.cn,direct
  ```

## 安装相关工具
### 进程工具

[goreman ](https://github.com/mattn/goreman)`go install github.com/mattn/goreman@latest`

### 框架Cli

- kratos `go install github.com/go-kratos/kratos/cmd/kratos/v2@latest`
- wire `go install github.com/google/wire/cmd/wire@latest`
- ent `go install entgo.io/ent/cmd/ent@latest`

- entimport `go install ariga.io/entimport/cmd/entimport@latest`

- entproto `go install entgo.io/contrib/entproto/cmd/entproto@latest`
### 代码Lint
- golangci-lint `go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest`

- [golines](https://github.com/segmentio/golines) `go install github.com/segmentio/golines@latest`

  > 1. Go into the Goland settings and click "Tools" -> "File Watchers" then click the plus to create a new file watcher
  > 2. Set the following properties and confirm by clicking OK:
  >
  > - **Name:** `golines`
  > - **File type:** `Go files`
  > - **Scope:** `Project Files`
  > - **Program:** `golines`
  > - **Arguments:** `$FilePath$ -w`
  > - **Output paths to refresh:** `$FilePath$`

- [gofumpt](https://github.com/mvdan/gofumpt) `go install mvdan.cc/gofumpt@latest` goland设置

  >GoLand doesn't use `gopls` so it should be configured to use `gofumpt` directly. Once `gofumpt` is installed, follow the steps below:
  >
  >- Open **Settings** (File > Settings)
  >- Open the **Tools** section
  >- Find the *File Watchers* sub-section
  >- Click on the `+` on the right side to add a new file watcher
  >- Choose *Custom Template*
  >
  >When a window asks for settings, you can enter the following:
  >
  >- File Types: Select all .go files
  >- Scope: Project Files
  >- Program: Select your `gofumpt` executable
  >- Arguments: `-w $FilePath$`
  >- Output path to refresh: `$FilePath$`
  >- Working directory: `$ProjectFileDir$`
  >- Environment variables: `GOROOT=$GOROOT$;GOPATH=$GOPATH$;PATH=$GoBinDirs$`
  >
  >To avoid unnecessary runs, you should disable all checkboxes in the *Advanced* section.
- [betteralign](https://github.com/dkorunic/betteralign)
> **betteralign**  is a tool to detect structs that would use less memory if their fields were sorted and optionally sort such fields.

+ nilaway

  安装 `go install go.uber.org/nilaway/cmd/nilaway@latest`

### buf

  需要使用格式化功能，windows环境需要安装[diff工具](https://gnuwin32.sourceforge.net/packages/diffutils.htm),goland则需要安装插件`Buf for Protocol Buffers`

buf 首页: https://github.com/bufbuild/buf

## 其他

-  [Handy well-known and lesser-known tools for Go projects](https://github.com/nikolaydubina/go-recipes)

