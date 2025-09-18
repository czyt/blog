---
title: "Omarchy 使用笔记"
date: 2025-09-18T16:32:07+08:00
draft: false
tags: ["linux","arch"]
author: "czyt" 
---
omarchy是DHH发布的一款Arch内核的Linux发行版。最近安装了下，稍作记录

## 快捷键

omarchy 的快捷键，请参考 https://learn.omacom.io/2/the-omarchy-manual/53/hotkeys

## 遇见的坑

### 我的浏览器怎么了

我是vivaldi浏览器的忠实用户，在omarchy上安装了vivaldi以后发现浏览器文字超大，好像出了啥问题，但是omarchy自带的浏览器却又是正常的。后面找到设置 setup->monitors.将默认的GDK放大倍数修改为1即可。

```
# Optimized for retina-class 2x displays, like 13" 2.8K, 27" 5K, 32" 6K.
env = GDK_SCALE,1
monitor=,preferred,auto,auto
```

> 我的屏幕是1920x1080分辨率的，所以看着很明显

