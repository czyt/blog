---
title: "Rasp3b 安装MongoDB"
date: 2022-03-23
tags: ["mongo", "Arch", "manjaro"]
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

启用服务 `systemctl enable mongodb`

检查服务状态 `systemctl status mongodb`

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

说明：

   开始使用的是 `yay -S mongodb-bin`进行安装，结果运行后老是报错``,后搜索官方论坛解决。

  原帖 https://www.mongodb.com/community/forums/t/core-dump-on-mongodb-5-0-on-rpi-4/115291/13