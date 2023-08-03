---
title: "Rasp3b 安装Postgresql"
date: 2022-09-17
tags: ["postgresql", "Arch", "manjaro"]
draft: false
---



## 安装

系统信息

![image-20220917202513873](https://assets.czyt.tech/img/rasp3binfo.png)



使用命令安装 `yay -S postgresql`

## 初始化及配置

启用数据库服务 `sudo systemctl enable --now postgresql`

开启数据库服务 `sudo systemctl start postgresql`

初始化数据 `su - postgres -c "initdb --locale en_US.UTF-8 -D '/var/lib/postgres/data'"`

查询配置文件路径

```bash
 su - postgres
[postgres@homeserver ~]$ ls
data
[postgres@homeserver ~]$ psql
psql (14.5)
输入 "help" 来获取帮助信息.

postgres=# SHOW config_file;
              config_file
----------------------------------------
 /var/lib/postgres/data/postgresql.conf
(1 行记录)
```

### 修改监听

修改配置`/var/lib/postgres/data/postgresql.conf` 文件中的`listen_addresses = '*'`监听所有地址，重启服务`sudo systemctl restart postgresql`生效。

### 允许远程访问

修改配置文件同级目录下的`pg_hba.conf`,添加一行

```
# TYPE  DATABASE  USER  CIDR-ADDRESS  METHOD
 host 	 all  		all 	0.0.0.0/0	md5
```

默认pg只允许本机通过密码认证登录，修改为上面内容后即可以对任意IP访问进行密码验证。

### 修改默认密码

登录`sudo -u postgres psql`

使用`password`修改

```none
postgres=# \password postgres
Enter new password: <new-password>
postgres=# \q
```

或者使用sql语句 `ALTER USER postgres PASSWORD '<new-password>';`

浓缩为一行 `sudo -u postgres psql -c "ALTER USER postgres PASSWORD '<new-password>';"`

## 常见问题

### 连接字符串

#### 报错 "auth error: sasl conversation error: unable to authenticateusing mechanism "SCRAM-SHA-1".(AuthenticationFailed)"

需要在连接字符串中指定authSource 

```
mongodb://root:root@127.0.0.1:27017/auth_microservice_db?authSource=admin
```

### 修改Mongodb数据文件路径

修改配置文件`mongod.conf`

```yaml
# Where and how to store data.
storage:
  dbPath: /usr/mongodb/data
  journal:
    enabled: true
```

然后将之前数据目录的文件拷贝过来

```bash
scp -r /var/lib/mondb/* /usr/mongodb/data
```

重启服务，如果报错 `"error":"IllegalOperation: Attempted to create a lock file on a read-only directory:`,则需要将 `/usr/mongodb/data`给mongod用户属主权限

```bash
chown -R mongod:mongod /usr/mongodb/data
```

然后再重启服务即可。

## 参考文档

+[MongoDB报错“not authorized on admin to execute command“](https://xiaoligege.blog.csdn.net/article/details/108749801)