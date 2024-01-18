---
title: "如何获取一个Github或者gitlab用户的公钥"
date: 2024-01-17
tags: ["github"]
draft: false
---

##  背景

今天无意在t上看到，然后找到这个帖子  https://stackoverflow.com/questions/16158158/what-is-the-public-url-for-the-github-public-keys

## How TO

### 获取

**GitHub** 可以通过下面链接

```
https://github.com/USER.keys
https://github.com/USER.gpg
```

当然也可以通过github的api方式来获取

```bash
curl -i https://api.github.com/users/<username>/keys
```

**GitLab**可以使用下面链接

```
https://gitlab.com/USER.keys
https://gitlab.com/USER.gpg
```

### 使用

以github为例

```bash
curl https://github.com/<username>.keys | tee -a ~/.ssh/authorized_keys
```

添加完毕以后，对方就可以用ssh直接连接到你的电脑了。

这个帖子还举了bitbucket的例子

```bash	
curl -i https://bitbucket.org/api/1.0/users/<accountname>/ssh-keys
```

## 延伸阅读
+ [史上最全 SSH 暗黑技巧详解](https://plantegg.github.io/2019/06/02/%E5%8F%B2%E4%B8%8A%E6%9C%80%E5%85%A8_SSH_%E6%9A%97%E9%BB%91%E6%8A%80%E5%B7%A7%E8%AF%A6%E8%A7%A3--%E6%94%B6%E8%97%8F%E4%BF%9D%E5%B9%B3%E5%AE%89/)
