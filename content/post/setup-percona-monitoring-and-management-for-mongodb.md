---
title: "为Mongodb安装Percona Monitoring and Management"
date: 2023-11-18
tags: ["mongodb", "linux"]
draft: false
---
   Percona Monitoring and Management (PMM) 是一种开源数据库可观察性、监控和管理工具，可与 MySQL、PostgreSQL、MongoDB 及其运行的服务器一起使用。它使您能够在一个位置查看所有数据库的节点到单个查询的性能指标。通过查询分析，您可以快速找到成本高昂且运行缓慢的查询以解决瓶颈。此外，Percona Advisors 为您提供性能、安全性和配置建议，帮助您保持数据库保持最佳性能。备份、恢复和内置开源私有 DBaaS 等警报和管理功能旨在提高 IT 团队的工作速度。

## 软件安装
安装环境为Ubuntu 22.04，下面的步骤参考了[Percona官网的安装文档](https://www.percona.com/software/pmm/quickstart)

### 安装服务端

> 本安装需要Docker环境，如果当前机器没有安装Docker，脚本会自动进行安装

使用下面命令安装
```
curl -fsSL https://www.percona.com/get/pmm | /bin/bash
```
或者
```
curl -fsSL https://www.percona.com/get/pmm | /bin/bash
```
安装完毕以后，请稍等片刻会显示server的访问信息
```bash
Gathering/downloading required components, this may take a moment

Checking docker installation - installed.

Starting PMM server...
Created PMM Data Volume: pmm-data
Created PMM Server: pmm-server
        Use the following command if you ever need to update your container by hand:
        docker run -d -p 443:443 --volumes-from pmm-data --name pmm-server --restart always percona/pmm-server:2

PMM Server has been successfully setup on this system!

You can access your new server using one of the following web addresses:
        https://172.17.0.1:443/
        https://127.0.0.1:443/
        https://10.10.31.19:443/

The default username is 'admin' and the password is 'admin' :)
Note: Some browsers may not trust the default SSL certificate when you first open one of the urls above.
If this is the case, Chrome users may want to type 'thisisunsafe' to bypass the warning.

Enjoy Percona Monitoring and Management!
```
这时就可以通过web登录了，第一次登录会要求修改密码。
### 客户端安装
#### 启用Percona源
使用下面命令下载安装源启用包
```
wget https://repo.percona.com/apt/percona-release_latest.$(lsb_release -sc)_all.deb
```
安装启用包
```
sudo dpkg -i percona-release_latest.$(lsb_release -sc)_all.deb
```
日志输出
```
(Reading database ... 224919 files and directories currently installed.)
Preparing to unpack percona-release_latest.jammy_all.deb ...
Unpacking percona-release (1.0-27.generic) over (1.0-27.generic) ...
Setting up percona-release (1.0-27.generic) ...
* Enabling the Percona Original repository
<*> All done!
```

更新

```
sudo apt-get update
```

#### 安装客户端软件

```
sudo apt-get install pmm2-client
```

日志输出

```
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
The following NEW packages will be installed:
  pmm2-client
0 upgraded, 1 newly installed, 0 to remove and 13 not upgraded.
Need to get 84.6 MB of archives.
After this operation, 195 MB of additional disk space will be used.
Get:1 http://repo.percona.com/percona/apt jammy/main amd64 pmm2-client amd64 2.40.1-6.jammy [84.6 MB]
12% [1 pmm2-client 12.7 MB/84.6 MB 15%]
```

#### 将客户端连接到服务端

执行下面语句启动客户端，ip为服务端监听的ip或者域名

```bash
sudo pmm-admin config --server-insecure-tls --server-url=https://admin:<password>@10.10.31.19
```

#### 配置mongoDB权限信息
登录mongodb，切换到admin数据库`use admin;`然后执行下面的语句创建相关角色
```
db.createRole({
   "role":"explainRole",
   "privileges":[
      {
         "resource":{
            "db":"",
            "collection":""
         },
         "actions":[
            "collStats",
            "dbHash",
            "dbStats",
            "find",
            "listIndexes",
            "listCollections"
         ]
      }
   ],
   "roles":[]
})
```
然后创建用户，并授权刚才创建的角色给用户
```
db.getSiblingDB("admin").createUser({
   "user":"pmm",
   "pwd":"<password>",
   "roles":[
      {
         "role":"explainRole",
         "db":"admin"
      },
      {
         "role":"clusterMonitor",
         "db":"admin"
      },
      {
         "role":"read",
         "db":"local"
      }
   ]
});
```
#### 添加监控
使用刚才的mongodb新建用户的鉴权信息创建mongdb的监控
```
sudo pmm-admin add mongodb --username=pmm --password=<password>
```
这时就可以在服务端web上对mongodb进行监控了。