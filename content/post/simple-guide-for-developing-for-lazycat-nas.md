---
title: "懒猫微服开发简明教程"
date: 2025-02-07
draft: false
tags: ["lazycat","tricks"]
author: "czyt"
---
最近入手了懒猫微服，简单记录下开发相关的内容。
## 环境配置

### 先决条件

+ 你必须有一台懒猫微服，[购买地址](https://item.jd.com/10101262547531.html)
+ 安装基本环境lzc-cli，请参考[官方说明地址](https://developer.lazycat.cloud/lzc-cli.html)
+ 如果你要发布程序，必须要申请成为懒猫微服开发者,[申请地址](https://developer.lazycat.cloud/manage)
+ 设备上必须安装[懒猫开发者工具](https://appstore.lazycat.cloud/#/shop/detail/cloud.lazycat.developer.tools)应用。这个应用主要用来通过lzc-cli进入devshell容器的开发以及将本地的测试镜像推送到盒子进行测试。
+ 开发机器上安装懒猫微服客户端,这和懒猫微服的网络机制有关,参考[官方文档](https://developer.lazycat.cloud/network.html)。开启客户端并且设备需要联网开机。

如果上面的条件都已经满足，那么我们进入下一步。

## 不同类型应用的注意事项

### Docker应用

对于公网的docker应用如果要使用，需要先进行`copy-image`操作才能在打包过程中使用，参考[官方说明](https://developer.lazycat.cloud/publish-app.html#%E6%8E%A8%E9%80%81%E9%95%9C%E5%83%8F%E5%88%B0%E5%AE%98%E6%96%B9%E4%BB%93%E5%BA%93)。下面是我的一个执行例子：

我在没copy操作之前`lzc-cli project devshell`

```bash
cmd:  install --uid czyt --pkgId cloud.lazycat.app.gokapi
Error: rpc error: code = Unknown desc = "time=\"2025-02-08T00:18:51+08:00\" level=warning msg=\"The \\\"LAZYCAT_APP_ID\\\" variable is not set. Defaulting to a blank string.\"\ntime=\"2025-02-08T00:18:51+08:00\" level=warning msg=\"The \\\"LAZYCAT_APP_DEPLOY_UID\\\" variable is not set. Defaulting to a blank string.\"\ntime=\"2025-02-08T00:18:51+08:00\" level=warning msg=\"The \\\"LAZYCAT_APP_DEPLOY_UID\\\" variable is not set. Defaulting to a blank string.\"\ntime=\"2025-02-08T00:18:51+08:00\" level=warning msg=\"The \\\"LAZYCAT_APP_DOMAIN\\\" variable is not set. Defaulting to a blank string.\"\ntime=\"2025-02-08T00:18:51+08:00\" level=warning msg=\"The \\\"LAZYCAT_APP_DEPLOY_UID\\\" variable is not set. Defaulting to a blank string.\"\ntime=\"2025-02-08T00:18:51+08:00\" level=warning msg=\"The \\\"LAZYCAT_APP_DEPLOY_UID\\\" variable is not set. Defaulting to a blank string.\"\ntime=\"2025-02-08T00:18:51+08:00\" level=warning msg=\"The \\\"LAZYCAT_APP_DOMAIN\\\" variable is not set. Defaulting to a blank string.\"\ntime=\"2025-02-08T00:18:51+08:00\" level=warning msg=\"The \\\"LAZYCAT_APP_ID\\\" variable is not set. Defaulting to a blank string.\"\n app Pulling \n gokapi Pulling \n a0bed814693a Already exists \n b4e16c7102ef Already exists \n b23adc163656 Pulling fs layer \n 99db376b5073 Pulling fs layer \n 5ed8719dcb50 Pulling fs layer \n 99db376b5073 Downloading [==================================================>]     251B/251B\n 99db376b5073 Verifying Checksum \n 99db376b5073 Download complete \n b23adc163656 Downloading [>                                                  ]  134.7kB/11.46MB\n 5ed8719dcb50 Downloading [>                                                  ]  265.8kB/23.48MB\n b23adc163656 Verifying Checksum \n b23adc163656 Download complete \n 5ed8719dcb50 Verifying Checksum \n 5ed8719dcb50 Download complete \n b23adc163656 Extracting [>                                                  ]  131.1kB/11.46MB\n b23adc163656 Extracting [======================>                            ]  5.243MB/11.46MB\n b23adc163656 Extracting [==================================================>]  11.46MB/11.46MB\n gokapi Error unknown: {\"errors\":[{\"code\":\"MANIFEST_UNKNOWN\",\"message\":\"manifest unknown\",\"detail\":{\"name\":\"f0rc3/gokapi\",\"revision\":\"v1.9.6\"}}]}\nError response from daemon: unknown: {\"errors\":[{\"code\":\"MANIFEST_UNKNOWN\",\"message\":\"manifest unknown\",\"detail\":{\"name\":\"f0rc3/gokapi\",\"revision\":\"v1.9.6\"}}]}\n" with exit status 18
```

Copy

```bash
lzc-cli appstore copy-image f0rc3/gokapi:v1.9.6
Waiting ... ( copy f0rc3/gokapi:v1.9.6 to lazycat offical registry)
lazycat-registry: registry.lazycat.cloud/czyt/f0rc3/gokapi:8491074e73af38d8
```

之后在我们的app中就可以使用这个镜像了

```yaml
services:
  gokapi:
    image: registry.lazycat.cloud/czyt/f0rc3/gokapi:8491074e73af38d8
    binds:
      - /lzcapp/var/gokapi/data:/app/data 
      - /lzcapp/var/gokapi/config:/app/config
    environment:
      - TZ=UTC
      - GOKAPI_DATA_DIR=/app/data
      - GOKAPI_CONFIG_DIR=/app/config
      - GOKAPI_PORT=53842
```

### Web 项目

+ web项目，懒猫现有的框架不支持Basic Auth认证，所有使用Basic Auth的应用都会返回401
+ 如果是自己使用，那么不需要开启public path，如果需要不认证使用，就需要开启public path[官方文档](https://developer.lazycat.cloud/spec/manifest.html#_4-2-%E5%8A%9F%E8%83%BD%E9%85%8D%E7%BD%AE)

### 自行通过SDK开发的项目

Todo

### 网络配置

#### 使用宿主网络
通过 [ServiceConfig](https://developer.lazycat.cloud/spec/manifest.html#%E4%B8%83%E3%80%81-serviceconfig-%E9%85%8D%E7%BD%AE) 下的`network_mode`进行设置。目前只支持`host`或留空。 若为 `host` 则会容器的网络为宿主网络空间。 此模式下应用进行网络监听时务必注意鉴权， 非必要不要监听 `0.0.0.0`

#### 一些特殊的域名

+ `_gateway` (网关) 

+ `_outbound`(微服局域网的默认出口IP)


## 软件调试

###  查看应用日志

需要安装 懒猫开发者工具 然后在 lzc-docker 实时日志  https://dev.设备名字.heiyu.space/dozzle/ 可以查看日志输出。

### 进入应用镜像

某些时候，可能需要进入应用的镜像排查问题，可以通过下面的命令进行操作：

```bash
lzc-cli docker ps
```

找到要操作的容器，然后

```bash
lzc-cli docker exec -it xxxxx sh
```

即可。容器的名字同样可以通懒猫开发者工具查看。

## 相关工具

+ [社区移植工具](https://github.com/glzjin/lzc-dtl) 一键把docker-compose转换成懒猫应用
+ [官方开发文档](https://developer.lazycat.cloud)
