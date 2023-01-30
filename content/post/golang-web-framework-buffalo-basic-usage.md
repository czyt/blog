---
title: "Golang Web框架Buffalo 简单使用"
date: 2023-01-29
tags: ["golang", "web", "server"]
draft: false
---
## 安装

安装要求

> Before installing make sure you have the required dependencies installed:
>
> - [A working Go environment](http://gopherguides.com/before-you-come-to-class)
> - [Go](https://golang.org/) version `v1.16.0`.
>
> ##### Frontend Requirements[#](https://gobuffalo.io/documentation/getting_started/installation/#frontend-requirements)
>
> The following requirements are optional. You don’t need them if you want to build an API or if you prefer to build your app in an old-fashioned way.
>
> - [node](https://github.com/nodejs/node) version `8` or greater
> - either [yarn](https://yarnpkg.com/en/) or [npm](https://github.com/npm/npm) for the [asset pipeline](https://gobuffalo.io/documentation/frontend-layer/assets) built upon [webpack](https://github.com/webpack/webpack).
>
> ##### Database Specific Requirements[#](https://gobuffalo.io/documentation/getting_started/installation/#database-specific-requirements)
>
> Again, if you don’t need a database, you won’t need these.
>
> - **SQLite 3**: GCC, or equivalent C compiler for [mattn/go-sqlite3](https://github.com/mattn/go-sqlite3).

使用下面的命令安装cli及相关工具

```bash
go install  github.com/gobuffalo/cli/cmd/buffalo@latest
go install  github.com/gobuffalo/buffalo-pop/v3@latest
```

如果需要sqlite支持，请使用下面的命令

```bash
go install -tags sqlite github.com/gobuffalo/cli/cmd/buffalo@latest
go install -tags sqlite github.com/gobuffalo/buffalo-pop/v3@latest
```

因为国内的原因，npm等组件可能因为某些原因下载不了，可以通过下面的内容设置mirror

```bash
npm config set registry https://registry.npmmirror.com
```

yarn工具设置代理

```bash
yarn config set https-proxy http://host:port
yarn config set proxy http://host:port
```

## 创建项目及运行

通过下面命令创建项目

```bash
buffalo new tinyApp --db-type sqlite3
```

然后切换到tiny_app目录，运行

```bash
buffalo dev
```

运行效果如下

![image-20230130130031874](https://assets.czyt.tech/img/buffalo-demo.png)