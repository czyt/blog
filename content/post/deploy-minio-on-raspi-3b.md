---
title: "在树莓派3b上部署minio服务"
date: 2023-04-12
tags: ["minio", "linux","manjaro","golang"]
draft: false
---
## 安装

我的树莓派安装的是manjaro,直接执行如下命令即可 

```bash
yay -S minio
```

官方的安装文档开源参考

https://min.io/docs/minio/linux/operations/install-deploy-manage/deploy-minio-single-node-single-drive.html

启用服务 `systemctl enable minio`

## 修改配置

主要修改mino的设置文件，文件位置为`/etc/minio/minio.conf`

```commonlisp
# Local export path.
MINIO_VOLUMES="/srv/minio/data/"
# Server user.
MINIO_ROOT_USER=gopher
# Server password.
MINIO_ROOT_PASSWORD=gopher
# Use if you want to run Minio on a custom port.
MINIO_OPTS="--console-address :8888"
MINIO_SERVER_URL="https://minio.xxx.org"
MINIO_BROWSER_REDIRECT_URL="https://minio-console.xxx.org"

```

修改 `MINIO_OPTS` 主要是为了自定义Console的端口,而这个参数主要是在service定义中使用，安装软件后自动使用的service(路径为`/usr/lib/systemd/system/minio.service`)定义如下

```lua
[Unit]
Description=Minio
Documentation=https://docs.minio.io
Wants=network-online.target
After=network-online.target
AssertFileIsExecutable=/usr/bin/minio

[Service]
# Specifies the maximum file descriptor number that can be opened by this process
LimitNOFILE=65536

Type=simple
User=minio
Group=minio

EnvironmentFile=/etc/minio/minio.conf
ExecStartPre=/bin/bash -c "{ [ -z \"${MINIO_VOLUMES}\" ] && echo \"Variable MINIO_VOLUMES not set in /etc/minio/minio.conf\" && ex>

ExecStart=/usr/bin/minio server $MINIO_OPTS $MINIO_VOLUMES
Restart=always

```

启动服务 `systemctl start minio`

## 使用和验证

### 初始化准备

通过浏览器，访问配置文件中的连接，并使用对应的密码，看能否使用。访问`https://minio.xxx.org`会自动跳转到`https://minio-console.xxx.org`。创建一个bucket和一个ak/sk（这个只显示一次，请记好）

### 使用go验证

使用下面的go代码看能否返回相关数据。

```go
package main

import (
	"context"
	"fmt"
	"github.com/minio/minio-go/v7"
	"github.com/minio/minio-go/v7/pkg/credentials"
	"log"
	"time"
)

func main() {
	endpoint := "minio.xxx.org"
	accessKeyID := "XmLO5vDR5JXcRw1S"
	secretAccessKey := "cRQLla7WJmGYymPtfFQGYUjrFrkeCK4u"
	useSSL := true

	// Initialize minio client object.
	minioClient, err := minio.New(endpoint, &minio.Options{
		Creds:  credentials.NewStaticV4(accessKeyID, secretAccessKey, ""),
		Secure: useSSL,
	})
	if err != nil {
		log.Fatalln(err)
	}

	// List objects in bucket.
	objects := minioClient.ListObjects(context.Background(), "ebook", minio.ListObjectsOptions{Recursive: true})
	for obj := range objects {
		fmt.Println(obj.Key)
	}
	u, err := minioClient.PresignedGetObject(context.Background(), "ebook", "test.py", 7*time.Hour, nil)
	if err != nil {
		fmt.Println(err)
	}
	fmt.Println(u.String())
}

```

