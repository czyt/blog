---
title: "在Alibaba Cloud Linux上安装MongoDB"
date: 2022-03-23
tags: ["mongodb", "alibaba", "linux"]
draft: false 
---
## 安装步骤
### 查询系统版本
执行命令`lsb_release -a`返回下面的内容
```
LSB Version:	:core-4.1-amd64:core-4.1-noarch
Distributor ID:	AlibabaCloud
Description:	Alibaba Cloud Linux release 3 (Soaring Falcon) 
Release:	3
Codename:	SoaringFalcon
```

### 添加yum源

创建repo文件`etc/yum.repos.d/mongodb.repo`并输入下面的内容，这里安装的mongodb版本为6.0,其他版本请参考[官网](https://www.mongodb.com/docs/manual/tutorial/install-mongodb-on-red-hat/)（配置偶数版本，奇数版不适合生产使用）。

官网的配置文件如下：

```yaml
[mongodb-org-6.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/$releasever/mongodb-org/6.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-6.0.asc
```

使用这个配置文件是安装不了的，需要修改`$releasever`为相应的版本，Alibaba Cloud Linux 3修改为8 （设置一个releasever的环境变量也许也可以，没有验证。）即可。即下面的样子

```yaml
[mongodb-org-6.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/8/mongodb-org/6.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-6.0.asc
```

使用命令 `yum -y install mongodb-org `安装即可。另外阿里云也提供了国内的镜像源，上面的配置文件可以修改为下面的内容，也是等效的。

```yaml
[mongodb-org-6.0]
name=MongoDB Repository
baseurl=http://mirrors.aliyun.com/mongodb/yum/redhat/8/mongodb-org/6.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-6.0.asc
```

## 参考链接
+ [如何在Alibaba Cloud Linux 3上安装MongoDB 5.0](https://www.bootschool.net/article/61a8c242e7ac006d8b321537)