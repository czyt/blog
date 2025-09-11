---
title: "Arch NVIDIA 驱动故障排查与修复指南"
date: 2025-09-11T10:03:26+08:00
draft: false
tags: ["arch"]
author: "czyt"
---

> 本文基于warp Terminal的修复操作使用deepseek进行复盘

## **问题描述**
在EndeavourOS系统更新后，显示器因NVIDIA驱动问题停止工作，主要症状如下：

- `nvidia-smi` 命令报错：
  ```bash
  NVIDIA-SMI 失败：无法与NVIDIA驱动通信
  ```
- 检测不到显示设备：
  ```bash
  xrandr --listproviders
  提供方数量：0
  ```
- 内核模块缺失：
  ```bash
  modprobe: 致命错误：在/lib/modules/6.16.6-arch1-1中找不到nvidia模块
  ```

## **问题根源**
1. **版本不匹配**
   - `nvidia=580.82.07-2` 与 `nvidia-utils=580.82.07-1` 版本不一致
2. **内核兼容性问题**
   - 预编译的`nvidia`驱动不支持新内核(6.16.6-arch1-1)
3. **驱动类型限制**
   - 标准`nvidia`软件包无法自动重建内核模块

## **完整解决方案**

### **1. 排除问题包进行系统更新**
```bash
paru -Syyu --ignore nvidia,nvidia-utils,nvidia-settings --noconfirm
```

### **2. 卸载问题驱动并安装DKMS版本**
```bash
paru -R nvidia --noconfirm           # 移除问题驱动包
paru -S nvidia-dkms --noconfirm      # 安装DKMS版本
```

### **3. 加载NVIDIA模块并验证**
```bash
sudo modprobe nvidia                 # 强制加载驱动模块
nvidia-smi                           # 验证驱动状态
```
预期输出示例：
```
+-----------------------------------------------------------------------------+
| NVIDIA-SMI 580.82.07    驱动版本: 580.82.07    CUDA版本: 12.1     |
|-------------------------------+----------------------+----------------------+
| GPU  名称       持久性| Bus-Id        显存使用 | 易失性非校正ECC |
| 风扇  温度  性能  功耗上限 |         显存使用率 | GPU利用率  计算模式 |
|===============================+======================+======================|
|   0  NVIDIA RTX 3050   关闭  | 00000000:01:00.0 开启 |                  N/A |
| N/A   45C    待机    10W / 115W |    200MiB /  4096MiB |      0%      默认    |
+-------------------------------+----------------------+----------------------+
```

## **技术对比：nvidia vs nvidia-dkms**
| 特性         | `nvidia`(预编译版)     | `nvidia-dkms`(动态版)  |
| ------------ | ---------------------- | ---------------------- |
| 内核适配方式 | 静态(为特定内核预编译) | 动态(自动重建模块)     |
| 维护难度     | 需手动更新             | 随内核变更自动适配     |
| 稳定性       | 适合固定内核系统       | 适合滚动更新系统       |
| 额外依赖     | 无                     | 需要安装linux-headers  |
| 推荐使用场景 | 服务器/LTS系统         | 频繁更新内核的桌面环境 |

## **预防性措施**
1. **优先使用DKMS版本**
```bash
paru -S nvidia-dkms linux-headers
```

2. **LTS内核用户替代方案**
```bash
paru -S nvidia-lts
```

3. **双显卡优化建议**
安装Optimus管理器优化切换：
```bash
sudo pacman -S optimus-manager
```

## **系统环境信息**
- **操作系统**： EndeavourOS (基于Arch Linux)
- **显卡配置**：
  - 独立显卡：NVIDIA GeForce RTX 3050 Mobile
  - 集成显卡：Intel Iris Xe Graphics
- **显示器设置**：eDP-1 @ 1920x1080分辨率
- **内核版本**：6.16.6-arch1-1

## **经验总结**
1. 使用DKMS可解决90%因内核更新导致的驱动失效问题
2. 注意检查驱动工具包版本一致性：
```bash
pacman -Q nvidia nvidia-utils
```
3. 双显卡系统可能需要额外配置才能正常切换

