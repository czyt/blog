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

对于公网的docker应用如果要使用，需要先进行`copy-image`来利用懒猫官方提供的镜像源，参考[官方说明](https://developer.lazycat.cloud/publish-app.html#%E6%8E%A8%E9%80%81%E9%95%9C%E5%83%8F%E5%88%B0%E5%AE%98%E6%96%B9%E4%BB%93%E5%BA%93)。下面是我的一个执行例子：

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

当然你也可以不推送到懒猫微服的registry，不过得加上你的镜像地址，比如上面的`f0rc3/gokapi`你就可以改成

```yaml
services:
  gokapi:
    image: docker.hlmirror.com/f0rc3/gokapi:latest
    binds:
      - /lzcapp/var/gokapi/data:/app/data 
      - /lzcapp/var/gokapi/config:/app/config
    environment:
      - TZ=UTC
      - GOKAPI_DATA_DIR=/app/data
      - GOKAPI_CONFIG_DIR=/app/config
      - GOKAPI_PORT=53842
```

docker的镜像地址有很多，这个要去网上自己搜一搜

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

+ `host.lzcapp` 一个类似"虚拟网卡"的地址。仅lzcapp之间访问。因为应用是网络隔离的，这个在应用使用host模式下的时候很有用，比如您的应用的一个镜像开启了Host模式，监听地址为`6666`在另外的一个镜像访问，就可以用`host.lzcapp:6666`

>  ssh ping上面这个地址是ping不通的,更多请参考[官方文档](https://developer.lazycat.cloud/advanced-domain.html)

## 实用技巧

### 添加用户使用的帮助文档

有些软件在使用上需要给用户一些readme之类的东西，但是通过路由映射出来体验不好。可以通过404的handler来实现这一目的，但是帮助文件需要也映射相关的路径。

下面是一个例子

```yaml
lzc-sdk-version: "0.1"
name: MTranServer
package: cloud.lazycat.app.mtranserver
version: 1.1.1
description: 一个超低资源消耗超快的离线翻译服务器
homepage: https://github.com/xxnuo/MTranServer
usage: "请在浏览器打开应用，通过程序域名+/help获取使用帮助"
author: xxnuo
application:
  subdomain: mtranserver
  background_task: true
  multi_instance: false
  gpu_accel: false
  kvm_accel: false
  usb_accel: false
  handlers:
    error_page_templates:
      404: /lzcapp/pkg/content/errors/404.html.tpl
  public_path:
    - /
  routes:
    - /=http://mtranserver.cloud.lazycat.app.mtranserver.lzcapp:8989/
    - /help=file:///lzcapp/pkg/content/
    - /playground=file:///lzcapp/pkg/content/playground.html
services:
  mtranserver:
    image: docker.hlmirror.com/xxnuo/mtranserver:1.1.1
    binds:
      - /lzcapp/var/config:/app/config
      - /lzcapp/var/models:/app/models
    setup_script: |
      if [ -z "$(find /app/config/config.ini -mindepth 1 -maxdepth 1)" ]; then
          cp  /lzcapp/pkg/content/config.ini /app/config/config.ini
      fi
      ln -sf /app/config/config.ini /app/config.ini
      if [ ! -d /app/models/enzh ];then
        cp -r /lzcapp/pkg/content/models/enzh /app/models/
      fi
      if [ ! -d /app/models/zhen ];then
        cp -r /lzcapp/pkg/content/models/zhen /app/models/
      fi
unsupported_platforms:
  - ios
  - android
```

> 路由这里的 `- /=http://mtranserver.cloud.lazycat.app.mtranserver.lzcapp:8989/`
>
> 写成 `- /=http://mtranserver:8989/`也是可以的

模板内容

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="MtranServer" content="width=device-width, initial-scale=1.0" />
    <title>Redirecting...</title>
    页面跳转中...
    <script>
      window.location.href = window.location.origin + "/help";
    </script>
  </head>
  <body>
    <p>
      If you are not redirected automatically,
      <a href=" ">click here</a >.
    </p >
  </body>
</html>
```

### 添加HealthCheck

在Docker compose里面有两种概念

`depends_on`：仅确保容器的启动顺序，不保证依赖服务的就绪状态。

`health_check`：用于检测服务是否真正准备好接收请求

所以当我们的服务依赖于第三方的数据库、KV等软件的时候最好加上health check，下面是一些常见数据库的health check


#### 关系型数据库

| 数据库     | 命令行健康检查                                               | Docker健康检查示例                                           | 备注                                       |
| ---------- | ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------ |
| MySQL      | `mysqladmin ping -h localhost -u root -p`                    | `["CMD", "mysqladmin", "ping", "-h", "localhost", "-u", "root", "-p${MYSQL_ROOT_PASSWORD}"]` | 如果服务健康，返回"mysqld is alive"        |
| PostgreSQL | `pg_isready -U postgres`                                     | `["CMD", "pg_isready", "-U", "postgres"]`                    | 成功连接返回状态码0                        |
| MariaDB    | `mysqladmin ping -h localhost -u root -p`                    | `["CMD", "mysqladmin", "ping", "-h", "localhost"]`           | 与MySQL类似                                |
| SQLite     | `sqlite3 <db_file> "SELECT 1;"`                              | 不适用于Docker(文件型数据库)                                 | 通常不需要健康检查，直接检查文件是否可读写 |
| Oracle     | `sqlplus -s sys/password@//localhost:1521 as sysdba <<< "select 1 from dual;"` | `["CMD", "sqlplus", "-s", "sys/password@//localhost:1521", "as", "sysdba", "<<", "select 1 from dual;"]` | 需要Oracle客户端工具                       |
| SQL Server | `sqlcmd -S localhost -U sa -P password -Q "SELECT 1"`        | `["CMD", "/opt/mssql-tools/bin/sqlcmd", "-S", "localhost", "-U", "sa", "-P", "password", "-Q", "SELECT 1"]` | 需要sqlcmd工具                             |

#### 文档数据库

| 数据库    | 命令行健康检查                                | Docker健康检查示例                                           | 备注                       |
| --------- | --------------------------------------------- | ------------------------------------------------------------ | -------------------------- |
| MongoDB   | `mongosh --eval "db.adminCommand('ping')"`    | `["CMD", "mongosh", "--eval", "db.adminCommand('ping')"]`    | 成功返回`{ ok: 1 }`        |
| CouchDB   | `curl http://localhost:5984/`                 | `["CMD", "curl", "-f", "http://localhost:5984/"]`            | 成功返回JSON状态信息       |
| RavenDB   | `curl -f http://localhost:8080/admin/stats`   | `["CMD", "curl", "-f", "http://localhost:8080/admin/stats"]` | 需认证的环境需添加认证参数 |
| Couchbase | `curl -f http://localhost:8091/pools/default` | `["CMD", "curl", "-f", "http://localhost:8091/pools/default"]` | 可通过REST API检查集群状态 |

#### 键值/内存数据库

| 数据库    | 命令行健康检查                                   | Docker健康检查示例                                           | 备注                             |
| --------- | ------------------------------------------------ | ------------------------------------------------------------ | -------------------------------- |
| Redis     | `redis-cli ping`                                 | `["CMD", "redis-cli", "ping"]`                               | 成功返回"PONG"                   |
| Memcached | `echo stats                                      | nc localhost 11211`                                          | `["CMD", "sh", "-c", "echo stats |
| etcd      | `etcdctl endpoint health`                        | `["CMD", "etcdctl", "endpoint", "health"]`                   | 成功返回"endpoint is healthy"    |
| Hazelcast | `curl -f http://localhost:5701/hazelcast/health` | `["CMD", "curl", "-f", "http://localhost:5701/hazelcast/health"]` | REST API健康检查                 |

#### 列式数据库

| 数据库     | 命令行健康检查                         | Docker健康检查示例                                    | 备注                                         |
| ---------- | -------------------------------------- | ----------------------------------------------------- | -------------------------------------------- |
| Cassandra  | `nodetool status`                      | `["CMD", "nodetool", "status"]`                       | 检查节点状态                                 |
| HBase      | `echo 'status'                         | hbase shell`                                          | `["CMD", "hbase", "shell", "<<<", "status"]` |
| ClickHouse | `clickhouse-client --query "SELECT 1"` | `["CMD", "clickhouse-client", "--query", "SELECT 1"]` | 简单的可用性检查                             |

#### 图数据库

| 数据库   | 命令行健康检查                               | Docker健康检查示例                                           | 备注                          |
| -------- | -------------------------------------------- | ------------------------------------------------------------ | ----------------------------- |
| Neo4j    | `curl -f http://localhost:7474/`             | `["CMD", "curl", "-f", "http://localhost:7474/"]`            | 也可使用官方的neo4j-admin工具 |
| ArangoDB | `curl -f http://localhost:8529/_api/version` | `["CMD", "curl", "-f", "http://localhost:8529/_api/version"]` | 返回版本信息表示服务正常      |

#### 时序数据库

| 数据库      | 命令行健康检查                            | Docker健康检查示例                                         | 备注                         |
| ----------- | ----------------------------------------- | ---------------------------------------------------------- | ---------------------------- |
| InfluxDB    | `curl -f http://localhost:8086/health`    | `["CMD", "curl", "-f", "http://localhost:8086/health"]`    | 通过HTTP API检查             |
| TimescaleDB | `pg_isready -U postgres`                  | `["CMD", "pg_isready", "-U", "postgres"]`                  | 基于PostgreSQL，使用相同方法 |
| Prometheus  | `curl -f http://localhost:9090/-/healthy` | `["CMD", "curl", "-f", "http://localhost:9090/-/healthy"]` | 通过HTTP endpoint检查        |

以postgres为例，在懒猫的服务里面就是这样写的

```yaml
  cashbook_db:
    container_name: cashbook_db
    image: registry.lazycat.cloud/czyt/library/postgres:4bf579971745e6ce
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=postgres
      - POSTGRES_DB=cashbook
    binds:
      - /lzcapp/var/db:/var/lib/postgresql/data
    health_check:
      test:
        - CMD-SHELL
        - pg_isready -U postgres
      start_period: 90s
```

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
