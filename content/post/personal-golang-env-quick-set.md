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


  ## 环境设置

  设置proxy

  ```bash
  go env -w GOPROXY=https://goproxy.io,https://goproxy.cn,direct
  ```

  

## 安装相关工具

- kratos `go install github.com/go-kratos/kratos/cmd/kratos/v2@latest`

- ent `go install entgo.io/ent/cmd/ent@latest`

- entimport `go install ariga.io/entimport/cmd/entimport@latest`

- wire `go install github.com/google/wire/cmd/wire@latest`

- 规范化git commit消息工具 comet `go install github.com/liamg/comet@latest`

