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
>  ```bash
>     RUN apk add --no-cache git
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
>** Dockerfile 的指令每执行一次都会在 docker 上新建一层。所以过多无意义的层，会造成镜像膨胀过大 **

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

### 一个前端项目

Dockerfile

```dockerfile
# 第一阶段：依赖安装和构建
FROM node:18-alpine AS builder

# 设置工作目录
WORKDIR /app

# 安装 pnpm 并配置国内镜像源
RUN corepack enable && corepack prepare pnpm@8.15.9 --activate

RUN pnpm config set registry https://registry.npmmirror.com && \
    pnpm config set disturl https://npmmirror.com/mirrors/node && \
    pnpm config set electron_mirror https://npmmirror.com/mirrors/electron/
# 复制 package.json 和 pnpm-lock.yaml
COPY package.json ./
COPY pnpm-lock.yaml ./

# 添加 packageManager 字段到 package.json
RUN npm pkg set packageManager="pnpm@8.15.9"

# 安装依赖（使用配置好的镜像源）
RUN pnpm install || pnpm install --force

# 复制源代码
COPY . .

# 构建应用
RUN pnpm build

# 第二阶段：生产环境
FROM node:18-alpine AS runner

WORKDIR /app

# 安装 pnpm 并配置国内镜像源
RUN corepack enable && corepack prepare pnpm@8.15.9 --activate && \
    pnpm config set registry https://registry.npmmirror.com

# 设置为生产环境
ENV NODE_ENV production

# 从builder阶段复制必要文件
COPY --from=builder /app/package.json ./
COPY --from=builder /app/pnpm-lock.yaml ./
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public
COPY --from=builder /app/next.config.js ./

# 仅安装生产依赖
RUN npm pkg set packageManager="pnpm@8.15.9" && \
    pnpm install --prod

# 添加非 root 用户
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nextjs && \
    chown -R nextjs:nodejs /app

USER nextjs

# 暴露端口 3000
EXPOSE 3000

# 设置环境变量
ENV PORT 3000
ENV HOSTNAME "0.0.0.0"

# 启动应用
CMD ["pnpm", "start"]
```

## 构建与发布
### 本地构建镜像

```bash
  # 在Dockerfile 所在目录执行构建命令
docker build -t your-app-name:latest .

# 示例：如果你的应用名为 my-next-app
docker build -t my-next-app:latest .
```

### 本地运行镜像

```bash
  # 基本运行命令
docker run -p 3000:3000 your-app-name:latest

# 使用后台运行模式
docker run -d -p 3000:3000 your-app-name:latest

# 如果需要指定环境变量
docker run -d -p 3000:3000 \-e NODE_ENV=production \
  your-app-name:latest
```

访问 `http://localhost:3000` 即可看到应用运行效果。

### 推送到 DockerHub

#### 准备工作

```bash
  # 1. 登录到 DockerHub
docker login

# 2. 为镜像添加标签（格式：用户名/镜像名:标签）
docker tag your-app-name:latest your-dockerhub-username/your-app-name:latest

# 示例：
# docker tag my-next-app:latest johndoe/my-next-app:latest
```

#### 推送镜像

```bash
  # 推送到 DockerHub
docker push your-dockerhub-username/your-app-name:latest
```

### 常用管理命令

```bash
  # 查看本地镜像列表
docker images

# 查看运行中的容器
docker ps

# 停止运行中的容器
docker stop <container-id>

# 删除容器
docker rm <container-id>

# 删除镜像
docker rmi <image-id>
```

### 注意事项

1. **镜像命名规范**

   - 使用小写字母
   - 可以包含数字和下划线
   - 版本标签建议语义化，如 `v1.0.0`、`latest`

2. **安全建议**

   - 不要在镜像中包含敏感信息
   - 推送前确保镜像已经完全测试
   - 使用 `.dockerignore` 排除不必要的文件

3. **资源清理**

   ```bash       
     # 清理未使用的镜像和容器
   docker system prune -a
   ```

4. **查看容器日志**

   ```bash
     # 查看容器运行日志
   docker logs <container-id>
   
   # 实时查看日志
   docker logs -f <container-id>
   ```

## 6. 常见问题排查

-如果无法访问应用，检查端口映射是否正确

- 如果推送失败，确认是否正确登录 DockerHub
- 如果构建失败，检查 Dockerfile 语法和依赖配置

这些步骤将帮助你完成从本地构建到部署到 DockerHub 的完整流程。记得替换示例中的 `your-app-name` 和 `your-dockerhub-username` 为你实际使用的名称。

## 参考链接

### docker相关

+ [常见docker命令](https://www.runoob.com/docker/docker-command-manual.html)