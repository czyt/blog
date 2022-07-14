---
title: "Git小技巧"
date: 2022-06-17
tags: ["git", "windows"]
draft: false
---
## Windows下GIT的几个小技巧
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

### 让你的 GitHub 公共仓库保持更新

当你派生了一个 GitHub 仓库之后，你的仓库（即你的“派生”）会独立于原仓库而独立。 特别地，当原仓库有新的提交时，GitHub 会通知你：

```text
This branch is 5 commits behind progit:master.
（本分支落后 progit:master 5 个提交。）
```

但你的 GitHub 仓库不会被 GitHub 自动更新，这件事必须由你自己来做。还好，这事儿很简单。

第一种方法无需配置。例如，若你从 `https://github.com/progit/progit2.git` 派生了项目， 你可以像这样更新你的 `master` 分支：

```console
$ git checkout master (1)
$ git pull https://github.com/progit/progit2.git (2)
$ git push origin master (3)
```

1. 如果在另一个分支上，就切换到 `master`
2. 从 `https://github.com/progit/progit2.git` 抓取更改后合并到 `master`
3. 将 `master` 分支推送到 `origin`

这虽然可行，但每次都要输入从哪个 URL 抓取有点麻烦。你可以稍微设置一下来自动完成它：

```console
$ git remote add progit https://github.com/progit/progit2.git (1)
$ git branch --set-upstream-to=progit/master master (2)
$ git config --local remote.pushDefault origin (3)
```

1. 添加源仓库并取一个名字，这里叫它 `progit`
2. 将 `master` 分支设置为从 `progit` 远端抓取
3. 将默认推送仓库设置为 `origin`

搞定之后，工作流程为更加简单：

```console
$ git checkout master (1)
$ git pull (2)
$ git push (3)
```

1. 如果在另一个分支上，就切换到 `master`
2. 从 `progit` 抓取更改后合并到 `master`
3. 将 `master` 分支推送到 `origin`

这种方法可能很有用，但也不是没有缺点。如果你向 `master` 提交，再从 `progit` 中拉取，然后推送到 `origin`，Git 会很乐意安静地为您完成这项工作，但不会警告你——所有这些操作在以上设置下都是有效的。 所以你必须注意永远不要直接提交到 `master`，因为该分支实际上属于上游仓库。
