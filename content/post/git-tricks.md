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

### 核武器级选项：filter-branch

有另一个历史改写的选项，如果想要通过脚本的方式改写大量提交的话可以使用它——例如，全局修改你的邮箱地址或从每一个提交中移除一个文件。 这个命令是 `filter-branch`，它可以改写历史中大量的提交，除非你的项目还没有公开并且其他人没有基于要改写的工作的提交做的工作，否则你不应当使用它。 然而，它可以很有用。 你将会学习到几个常用的用途，这样就得到了它适合使用地方的想法。

| Caution | `git filter-branch` 有很多陷阱，不再推荐使用它来重写历史。 请考虑使用 `git-filter-repo`，它是一个 Python 脚本，相比大多数使用 `filter-branch` 的应用来说，它做得要更好。它的文档和源码可访问 https://github.com/newren/git-filter-repo 获取。 |
| ------- | ------------------------------------------------------------ |
|         |                                                              |

#### 从每一个提交中移除一个文件

这经常发生。 有人粗心地通过 `git add .` 提交了一个巨大的二进制文件，你想要从所有地方删除。 可能偶然地提交了一个包括一个密码的文件，然而你想要开源项目。 `filter-branch` 是一个可能会用来擦洗整个提交历史的工具。 为了从整个提交历史中移除一个叫做 `passwords.txt` 的文件，可以使用 `--tree-filter` 选项给 `filter-branch`：

```console
$ git filter-branch --tree-filter 'rm -f passwords.txt' HEAD
Rewrite 6b9b3cf04e7c5686a9cb838c3f36a8cb6a0fc2bd (21/21)
Ref 'refs/heads/master' was rewritten
```

`--tree-filter` 选项在检出项目的每一个提交后运行指定的命令然后重新提交结果。 在本例中，你从每一个快照中移除了一个叫作 `passwords.txt` 的文件，无论它是否存在。 如果想要移除所有偶然提交的编辑器备份文件，可以运行类似 `git filter-branch --tree-filter 'rm -f *~' HEAD` 的命令。

最后将可以看到 Git 重写树与提交然后移动分支指针。 通常一个好的想法是在一个测试分支中做这件事，然后当你决定最终结果是真正想要的，可以硬重置 `master` 分支。 为了让 `filter-branch` 在所有分支上运行，可以给命令传递 `--all` 选项。

#### 使一个子目录做为新的根目录

假设已经从另一个源代码控制系统中导入，并且有几个没意义的子目录（`trunk`、`tags` 等等）。 如果想要让 `trunk` 子目录作为每一个提交的新的项目根目录，`filter-branch` 也可以帮助你那么做：

```console
$ git filter-branch --subdirectory-filter trunk HEAD
Rewrite 856f0bf61e41a27326cdae8f09fe708d679f596f (12/12)
Ref 'refs/heads/master' was rewritten
```

现在新项目根目录是 `trunk` 子目录了。 Git 会自动移除所有不影响子目录的提交。

#### 全局修改邮箱地址

另一个常见的情形是在你开始工作时忘记运行 `git config` 来设置你的名字与邮箱地址， 或者你想要开源一个项目并且修改所有你的工作邮箱地址为你的个人邮箱地址。 任何情形下，你也可以通过 `filter-branch` 来一次性修改多个提交中的邮箱地址。 需要小心的是只修改你自己的邮箱地址，所以你使用 `--commit-filter`：

```console
$ git filter-branch --commit-filter '
        if [ "$GIT_AUTHOR_EMAIL" = "schacon@localhost" ];
        then
                GIT_AUTHOR_NAME="Scott Chacon";
                GIT_AUTHOR_EMAIL="schacon@example.com";
                git commit-tree "$@";
        else
                git commit-tree "$@";
        fi' HEAD
```

这会遍历并重写每一个提交来包含你的新邮箱地址。 因为提交包含了它们父提交的 SHA-1 校验和，这个命令会修改你的历史中的每一个提交的 SHA-1 校验和， 而不仅仅只是那些匹配邮箱地址的提交。
