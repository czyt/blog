---
title: "Git小技巧"
date: 2022-06-17
tags: ["git", "windows"]
draft: false
---
## Windows两个有用的设置
### 记住git密码
使用下面命令可以设置记住git密码，但推荐使用ssh进行操作。
```bash
git config credential.helper store
```
### 设置换行符转换
在windows下开发时，迁出的代码是CRLF会导致编译的sh脚本不能正确执行:

```bash
git config --global core.autocrlf false
```



## Git推送到多个服务器
要实现一次push到多个远程仓库
本机git仓库A  https://aaaaa.git
要同步push的远程git仓库B  https://bbbbb.git

###  通过git remote add添加

先使用git remote -v查看远程仓库的情况 ,然后添加一个git仓库
```bash
git remote add b https://bbbbb.git
```

再次查看远程仓库情况，如果需要push，则需要push两次

### 通过git remote set-url 添加

如果按上面添加过remote分支，需要先git remote rm b,使用下面命令添加即可。
```bash
git remote set-url --add a https://bbbbb.git
```


查看远程仓库情况，看看是否已经是两个push地址了 。这个只需push一次就行了

###  修改配置文件

打开 .git/config 找到 [remote "github"]，添加对应的 url 即可，效果如下。这种方法其实和方法二是一样的。

```yaml
[remote "a"]
url =  https://aaaaa.git
fetch = +refs/heads/*:refs/remotes/a/*
url = https://bbbbb.git
```



参考链接

● 一个项目push到多个远程Git仓库  https://segmentfault.com/a/1190000011294144

