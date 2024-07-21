---
title: "Rasp3b 安装MongoDB"
date: 2022-03-23
tags: ["mongoDB", "Arch", "manjaro"]
draft: false
---

## 安装

机器安装的是Manjaro,所以本文介绍的是Manjaro的树莓派3安装方式

``` bash
➜  ~ screenfetch
                             czyt@**
                             OS: Manjaro-ARM 22.01
                             Kernel: aarch64 Linux 5.15.24-1-MANJARO-ARM-RPI
         #####               Uptime: 21d 21h 58m
        #######              Packages: Unknown
        ##O#O##              Shell: zsh 5.8.1
        #######              Disk: 11G / 118G (9%)
      ###########            CPU: BCM2835 @ 4x 1.2GHz
     #############           GPU:
    ###############          RAM: 248MiB / 919MiB
    ################
   #################
 #####################
 #####################
   #################



```

使用命令 `yay -S mongodb44-bin`进行安装，安装完毕后

+ 启用服务 `systemctl enable mongodb`

+ 检查服务状态 `systemctl status mongodb`

``` bash
● mongodb.service - MongoDB Database Server
     Loaded: loaded (/usr/lib/systemd/system/mongodb.service; enabled; vendor preset: disabled)
     Active: active (running) since Wed 2022-03-23 13:11:08 CST; 11s ago
       Docs: https://docs.mongodb.org/manual
   Main PID: 624895 (mongod)
        CPU: 2.610s
     CGroup: /system.slice/mongodb.service
             └─624895 /usr/bin/mongod --config /etc/mongodb.conf
```
## 常见问题
### 非法指令 (核心已转储)
 启动服务报错 `非法指令 (核心已转储)`英文系统可能是`(Illegal instruction(core dumped))`
   开始使用的是 `yay -S mongodb-bin`进行安装，后搜索官方论坛发现是官方打包的时候默认使用了最新架构，但是树莓派是老设备，可能不支持部分指令，换成上文的指令安装`4.x`版本后解决。
### 数据库备份及还原
   默认安装是不在mongodb tools的，所以需要执行 `yay -S mongodb-tools-bin`进行安装。参考下面语句：
   备份
   ```bash
   mongodump -h <host>:<port> -u <username> -p <password> -d ubertower-new -o /path/to/destination/directory
   ```
   恢复
   ```bash
   mongorestore -h <host>:<port> -u <username> -p <password> -d <DBNAME> /path/to/destination/directory/<DBNAME>
   ```
   恢复文件夹下的bson文件
   ```bash
   for FILENAME in *.bson; do mongorestore -d nts -c "${FILENAME%.*}" $FILENAME; done
   // 带权限的恢复
   for FILENAME in *.bson; do mongorestore  --authenticationDatabase="admin" -d "nts" -u="xxxx" -p="yyyy"  -c "${FILENAME%.*}" $FILENAME; done
   ```
  原帖 https://www.mongodb.com/community/forums/t/core-dump-on-mongodb-5-0-on-rpi-4/115291/13

### 安装启动服务后不能连接到mongoDB
   需要修改配置文件，默认是`/etc/mongodb.conf`,修改其中的监听地址为`0.0.0.0`或者您要访问MongoDB服务的网段中当前设备的IP。
   ```yaml
   # network interfaces
   net:
     port: 27017
     bindIp: 0.0.0.0
   ```
创建用户。执行`mongo`命令，执行下面的命令。
```bash
      use admin;
      db.createUser(   
      {
          user: "czyt",
          pwd: "admin_Pwd", 
          roles: [ { role: "userAdminAnyDatabase", db: "admin" } ]  
      } );
      db.grantRolesToUser('czyt',[{ role: "root", db: "admin" }])
```
后期如果需要调整角色，可以使用语句`db.grantRolesToUser("otherRole",["userAdminAnyDatabase"])`

>在 MongoDB 中，内置角色用于授予数据库用户一系列预定义的权限。下面是一些内置角色，它们允许用户连接到数据库：
>
>1. read: 允许用户读取指定数据库的非系统集合和视图。
>
>2. readWrite: 允许用户读写指定数据库的非系统集合和视图。
>
>3. dbAdmin: 允许用户执行管理函数，如索引创建、删除、查看统计信息和系统集合的读取。
>
>4. userAdmin: 允许用户创建和修改用户和角色。
>
>5. dbOwner: 此角色结合了 readWrite、dbAdmin 和 userAdmin 的权限，允许用户对数据库执行任何操作。
>
>对于那些需要跨多个数据库操作的角色：
>
>1. readAnyDatabase: 授予连接到并读取所有数据库权限（不包括 config 和 local 数据库）。这个角色通常在 admin 数据库中授予。
>
>2. readWriteAnyDatabase: 授予在所有数据库上读写的权限（不包括 config 和 local 数据库）。这个角色通常在 admin 数据库中授予。
>
>3. userAdminAnyDatabase: 授予创建和管理所有数据库中用户账户的权限。这个角色通常在 admin 数据库中授予。
>
>4. dbAdminAnyDatabase: 授予在所有数据库上执行管理任务的权限。这个角色通常在 admin 数据库中授予。
>
>还有更高级别的角色，如:
>
>1. clusterAdmin: 授予管理集群的权限。
>
>2. clusterManager: 允许用户管理和监控集群。
>
>3. clusterMonitor: 允许用户监控集群但不管理它。
>
>4. hostManager: 允许用户管理服务器。
>
>最高权限的角色:
>
>1. root: 几乎拥有所有权限，包括服务器管理和用户管理权限。
>
>请记住，创建用户并分配角色需要具备相应的权限，通常由已有 userAdmin 或 userAdminAnyDatabase 角色的用户来执行。再次强调，分配具有广泛权限的角色（如 root 或任何 *AnyDatabase 角色）应该十分谨慎，因为它们会授予用户对数据库的广泛访问能力。常见的做法是仅根据用户需要完成其工作的最小权限集来分配角色。

修改配置文件`/etc/mongodb.conf`，启用授权连接。

```yaml
security:
  authorization: enabled
```
重启mongodb服务 `systemctl restart mongodb` 使配置生效。
 修改用户密码
```shell
      use admin;
      db.changeUserPassword("czyt", "dbpassword");
```
 > 最新的MongoDB4.4版本已经不能在树莓派3b上安装，最后可安装的版本为4.4.18。可以下载版本的[存档](https://aur.archlinux.org/cgit/aur.git/snapshot/aur-754d0709ee78271915f24163cb914aca2f27d758.tar.gz)，解压后`makepkg -si`安装即可。

然后就可以`mongosh` （MongoDB Shell）并且带上密码登录 MongoDB，你可以使用以下格式的命令：

```bash
mongosh "mongodb://yourUsername:yourPassword@hostname:port/database?authSource=admin"
```

以下是命令参数的解释：

- `yourUsername`：你的 MongoDB 用户名。
- `yourPassword`：你的 MongoDB 密码。
- `hostname`：MongoDB 服务器的主机名或者 IP 地址。
- `port`：MongoDB 服务的端口（如果是默认端口 27017 可以省略）。
- `database`：你想要登录的数据库名称。
- `authSource=admin`：用于指定认证数据库，通常默认为 `admin`。

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

-[MongoDB报错“not authorized on admin to execute command“](https://xiaoligege.blog.csdn.net/article/details/108749801)
- https://dba.stackexchange.com/questions/283843/create-user-for-all-databases-in-mongodb
- https://www.guru99.com/mongodb-create-user.html
- https://github.com/themattman/mongodb-raspberrypi-binaries
  
  ​    