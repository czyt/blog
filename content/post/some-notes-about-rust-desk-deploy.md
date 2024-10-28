---
title: "一些RustDesk部署的笔记"
date: 2024-05-17
tags: ["tricks", "rustdesk","self-host]
draft: false
---

##  自建 Server

### 搭建中转服务器

参考官方 https://rustdesk.com/docs/en/self-host/rustdesk-server-oss/install/

一些有用的链接：

+ https://github.com/infiniteremote/installer/blob/main/install.sh

### 搭建api server

api server是高级版的功能，但是我们可以通过自建api server实现设备id同步等部分操作。推荐使用：

+ https://github.com/kingmo888/rustdesk-api-server

+ https://github.com/sctg-development/sctgdesk-server

  > 这个是带web console的用户名和密码分别是`admin`和`Hello,world!`

+ https://github.com/lantongxue/rustdesk-api-server

+ https://github.com/v5star/rustdesk-api

+ https://github.com/lejianwen/rustdesk-api

更多的实现，可以去Github 搜一搜 https://github.getafreenode.com/topics/rustdesk-api-server

## 客户端自定义部署

### 基于Github Action

参考官方 https://rustdesk.com/docs/en/dev/build/all/

> 对于arm版本的自动化构建，Github Action暂时不提供arm64的runner

### 基于配置文件和命令行

#### RustDesk有用的命令行参数

```bash
--password 可用于设置永久密码。
--get-id 可用于检索 ID。
--set-id 可用于设置ID，请注意ID应以字母开头。
--silent-install 可用于在 Windows 上静默安装 RustDesk。
```

#### RustDesk 配置文件

RustDesk的配置文件，windows为`"%appdata%\RustDesk\config\RustDesk2.toml"`linux则为`~/.config/rustdesk/RustDesk2.toml`,下面是一个完整的配置文件示例：

```toml
rendezvous_server = 'rustdesk.xxxx.tech:21116'
nat_type = 1
serial = 0

[options]
# 对应安全选项->权限中的完全访问
access-mode = 'full'
# 对应安全选项->安全->允许IP直接访问
direct-server = 'Y'
# 对应安全选项->安全->自动关闭不活跃的会话
allow-auto-disconnect = 'Y'
stop-service = 'Y'
key = 'KEY'
relay-server = 'IPADDRESS'
api-server = 'https://IPADDRESS'
custom-rendezvous-server = 'rustdesk.xxxx.tech'
verification-method = 'use-permanent-password'
```

这样可以结合命令行参数和配置文件进行rustdesk的自动化配置，然后通过`--import-config`导入配置。对于key配置项，需要服务器也开启key认证。

可以通过`rustdesk://connection/new/{{agent.rustdeskid}}?password={{agent.rustdeskpwd}}`这样的私有协议在web上进行rustdesk的唤起连接。

