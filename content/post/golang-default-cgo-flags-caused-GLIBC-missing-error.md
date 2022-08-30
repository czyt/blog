---
title: "Golang 默认的CGO参数编译导致的GLIBC错误"
date: 2022-08-30
tags: ["dsl", "golang"]
draft: false
---
## 问题描述
使用go正常编译了Linux下的程序，放到服务器上报错
```
./app: /lib64/libc.so.6: version `GLIBC_2.34' not found (required by ./app)
```

## 解决

Google了下，发现相同的[Issue](https://github.com/aws/aws-lambda-go/issues/340),于是通过`go env`检查本机golang运行环境，发现CGO默认启用而且程序也不涉及CGO相关的东西，于是设置CGO参数为关闭。然后编译程序

` CGO_ENABLED="0" go build -v`

重新上传，运行OK.

