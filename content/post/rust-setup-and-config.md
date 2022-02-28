---
title: "Rust安装及配置"
date: 2022-02-28
tags: ["rust", "mirror", "windows", "setup"]
draft: false
---
## 下载rustup
从[此处](https://www.rust-lang.org/tools/install)下载
## 设置rustup镜像


字节提供的镜像
[https://rsproxy.cn](https://rsproxy.cn)
```bash
export RUSTUP_DIST_SERVER="https://rsproxy.cn"
export RUSTUP_UPDATE_ROOT="https://rsproxy.cn/rustup"
```
设置两个环境变量即可
设置环境变量 `RUSTUP_DIST_SERVER` (用于更新 toolchain)
```bash
export RUSTUP_DIST_SERVER=https://mirrors.ustc.edu.cn/rust-static
```
以及 `RUSTUP_UPDATE_ROOT` (用于更新 rustup)
```bash
export RUSTUP_UPDATE_ROOT=https://mirrors.ustc.edu.cn/rust-static/rustup
```
## crates.io 镜像
编辑 `~/.cargo/config `

```
[source.crates-io]
replace-with = 'rsproxy'

[source.rsproxy]
registry = "https://rsproxy.cn/crates.io-index"

[registries.rsproxy]
index = "https://rsproxy.cn/crates.io-index"

[net]
git-fetch-with-cli = true

```
## 


## 安装Rust
安装rust即可。可以参考我的步骤

``` bash
Current installation options:


   default host triple: x86_64-pc-windows-msvc
     default toolchain: stable (default)
               profile: default
  modify PATH variable: yes

1) Proceed with installation (default)
2) Customize installation
3) Cancel installation
>2

I'm going to ask you the value of each of these installation options.
You may simply press the Enter key to leave unchanged.

Default host triple?
x86_64-pc-windows-gnu

Default toolchain? (stable/beta/nightly/none)


Profile (which tools and data to install)? (minimal/default/complete)


Modify PATH variable? (y/n)
y


Current installation options:


   default host triple: x86_64-pc-windows-gnu
     default toolchain: stable
               profile: default
  modify PATH variable: yes

1) Proceed with installation (default)
2) Customize installation
3) Cancel installation
>1

info: profile set to 'default'
info: setting default host triple to x86_64-pc-windows-gnu
info: syncing channel updates for 'stable-x86_64-pc-windows-gnu'
info: latest update on 2020-10-08, rust version 1.47.0 (18bf6b4f0 2020-10-07)
info: downloading component 'cargo'
  5.6 MiB /   5.6 MiB (100 %) 1023.6 KiB/s in  5s ETA:  0s
info: downloading component 'clippy'
info: downloading component 'rust-docs'
 12.9 MiB /  12.9 MiB (100 %)   5.5 MiB/s in  1s ETA:  0s
info: downloading component 'rust-mingw'
  4.2 MiB /   4.2 MiB (100 %)   1.4 MiB/s in  4s ETA:  0s
info: downloading component 'rust-std'
 19.5 MiB /  19.5 MiB (100 %)  15.5 MiB/s in  1s ETA:  0s
info: downloading component 'rustc'
 66.4 MiB /  66.4 MiB (100 %)  13.0 MiB/s in  8s ETA:  0s
info: downloading component 'rustfmt'
  6.0 MiB /   6.0 MiB (100 %)   1.3 MiB/s in  4s ETA:  0s
info: installing component 'cargo'
info: Defaulting to 500.0 MiB unpack ram
info: installing component 'clippy'
info: installing component 'rust-docs'
 12.9 MiB /  12.9 MiB (100 %)   2.9 MiB/s in  4s ETA:  0s
info: installing component 'rust-mingw'
info: installing component 'rust-std'
 19.5 MiB /  19.5 MiB (100 %)   9.5 MiB/s in  2s ETA:  0s
info: installing component 'rustc'
 66.4 MiB /  66.4 MiB (100 %)  10.1 MiB/s in  6s ETA:  0s
info: installing component 'rustfmt'
info: default toolchain set to 'stable'

  stable installed - rustc 1.47.0 (18bf6b4f0 2020-10-07)


Rust is installed now. Great!

```
## 配置cargo镜像
参考 

- [https://www.cnblogs.com/dhcn/p/12100675.html](https://www.cnblogs.com/dhcn/p/12100675.html)
- [https://erasin.wang/rustup/](https://erasin.wang/rustup/)
