---
title: "一些docker和k8s的笔记"
date: 2024-08-17
tags: ["go", "docker"]
draft: false
---

## 常见的项目Dockerfile

### golang项目

```dockerfile
# 构建阶段
FROM golang:1.23 AS builder

# 设置工作目录,
WORKDIR /app

# 复制go.mod和go.sum文件
COPY go.mod go.sum ./

# 设置goproxy
RUN go env -w GOPROXY='https://goproxy.io,https://goproxy.cn,direct'
# 下载依赖
RUN go mod download

# 复制源代码
COPY . .

# 构建应用
RUN CGO_ENABLED=0 GOOS=linux go build -o server .

# 运行阶段
FROM alpine:latest  

# 安装ca-certificates以支持HTTPS,
RUN apk --no-cache add ca-certificates

WORKDIR /root/

# 从构建阶段复制编译好的二进制文件
COPY --from=builder /app/server .

# 暴露端口（如果您的应用监听某个端口）
EXPOSE 8080

# 运行应用
CMD ["./main"]
```

这个dockerfile使用多阶段构建来减小最终镜像的大小。

1. 第一阶段（builder）编译Go应用程序。

2. 第二阶段使用轻量级的Alpine镜像作为运行环境。

- 从构建阶段复制编译好的二进制文件到运行环境。

- 设置CMD指令来运行应用程序

>`apk` 是 Alpine Linux 的包管理器，类似于 Ubuntu 的 `apt` 或 CentOS 的 `yum`。在 Dockerfile 中，我们使用 `apk` 来安装、更新或删除 Alpine Linux 容器中的软件包。
>
>比如下面的这个 Dockerfile 中的 `apk` 命令：
>
>1. ```
>   RUN apk add --no-cache git
>   ```
>
>   这条命令在 Alpine Linux 容器中安装 git。
>
>   - `add` 是安装包的子命令
>   - `--no-cache` 选项告诉 `apk` 不要缓存下载的包，这有助于保持镜像小巧
>   - `git` 是要安装的包名
>
>2. `RUN apk --no-cache add ca-certificates` 这条命令安装 CA 证书，这通常是必要的，以确保 HTTPS 连接正常工作。
>
>一些常用的 `apk` 命令：
>
>- `apk update`: 更新可用包的列表
>- `apk add <package>`: 安装一个包
>- `apk del <package>`: 删除一个包
>- `apk info`: 列出已安装的包
>
>在 Dockerfile 中使用 Alpine Linux 和 `apk` 的主要优点是：
>
>1. Alpine 镜像非常小（约 5MB），这有助于保持最终 Docker 镜像的小巧
>2. `apk` 操作通常很快，这有助于加速 Docker 构建过程
>3. Alpine 提供了大多数常用软件包，尽管有时可能需要使用 `-edge` 仓库来获取最新版本
>
>需要注意的是，由于 Alpine 使用 musl libc 而不是更常见的 glibc，某些应用程序可能会遇到兼容性问题。但对于大多数 Go 应用程序来说，这通常不是问题，因为 Go 可以静态链接所有依赖。
>
>**  Dockerfile 的指令每执行一次都会在 docker 上新建一层。所以过多无意义的层，会造成镜像膨胀过大**

1. 构建 Docker 镜像：

   ```bash
   docker build -t your-app-name .
   ```

2. 运行 Docker 容器：

   ```bash
   docker run your-app-name
   ```

3. 构建完成后，您可以使用以下命令检查镜像大小：

```bash
docker images your-app-name
```

## 参考链接

### docker相关

+ [常见docker命令](https://www.runoob.com/docker/docker-command-manual.html)