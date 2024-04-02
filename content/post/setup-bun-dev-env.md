---
title: "设置bun开发环境"
date: 2024-04-02
tags: ["bun", "linux"]
draft: true
---

## 安装

windows

```powershell
powershell -c "irm http://bun.sh/install.ps1 | iex"
```



## 安装组件

npm

```bash
bun install -g npm
```

配置npm镜像源

```bash
npm config set registry https://registry.npmmirror.com
// 查询  npm config get registry
```

