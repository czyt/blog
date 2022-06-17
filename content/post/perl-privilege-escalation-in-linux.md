---
title: "Linux环境下Perl提权"
date: 2022-06-17
tags: ["linux", "ssh", "perl"]
draft: false
---
## 事故起因

我们公司的应用程序部署目录有个bin目录，手误，删除的时候输入的是/bin

## 事故现象

● SSH 不能登陆进来了
● ls、chmod等常用命令都不能使用了
● wget 还能用

## 事故解决

通过查找谷歌，发现有个perl带有提权的功能,简单来说就是

```perl
perl -e "chmod 0777, '/bin/ls'"
```

通过这个方式可以对指定的文件进行权限的修改。于是从另外的机器上打包了一个/bin目录，放到网上，wget 下载到本地`wget bin.tar.gz`

​    本机开外网ssh转发，scp 拷贝tar文件到目录，执行 

```perl
perl -e "chmod 0777, './tar'"
```

,再使用tar进行文件解压`./tar xvzf bin.tar.gz -C /`,然后再给chmod执行文件赋予执行权限 

```perl
perl -e "chmod 0777, '/bin/chmod'"
```

然后再通过chmod 执行 `chmod -R +x /bin/`给/bin目录下的可执行程序文件授予执行权限。至此，完成事故修复。
## 参考连接

● https://perldoc.perl.org/functions/chmod.html