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

## 遇到的问题

1. 启动服务报错 `非法指令 (核心已转储)`英文系统可能是`(Illegal instruction(core dumped))`

   开始使用的是 `yay -S mongodb-bin`进行安装，后搜索官方论坛发现是官方打包的时候默认使用了最新架构，但是树莓派是老设备，可能不支持部分指令，换成上文的指令安装`4.x`版本后解决。
   注意：默认安装是不在mongodb tools的，所以需要执行 `yay -S mongodb-tools-bin`进行安装。参考下面语句：
   
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

2. 启动服务后不能连接到mongoDB

   需要修改配置文件，默认是`/etc/mongodb.conf`,修改其中的监听地址为`0.0.0.0`或者您要访问MongoDB服务的网段中当前设备的IP。

   ```yaml
   # network interfaces
   net:
     port: 27017
     bindIp: 0.0.0.0
   ```

   3. 创建用户。执行`mongo`命令，执行下面的命令。
   
      ```bash
      use admin;
      db.createUser(   
      {
          user: "admin",
          pwd: "admin_Pwd", 
          roles: [ { role: "readAnyDatabase", db: "admin" } ]  
      } );
      ```
      
      后期如果需要调整角色，可以使用语句`db.grantRolesToUser("admin",["userAdminAnyDatabase"])`
   
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
   
   
      ##  参考连接
   
      - https://dba.stackexchange.com/questions/283843/create-user-for-all-databases-in-mongodb
      - https://www.guru99.com/mongodb-create-user.html
   
      