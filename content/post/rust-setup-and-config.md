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


## 跨平台编译

  rust支持的Target列表 `rustup target list`

  ```tex
  aarch64-apple-darwin
  aarch64-apple-ios
  aarch64-apple-ios-sim
  aarch64-fuchsia
  aarch64-linux-android
  aarch64-pc-windows-msvc
  aarch64-unknown-linux-gnu
  aarch64-unknown-linux-musl
  aarch64-unknown-none
  aarch64-unknown-none-softfloat
  arm-linux-androideabi
  arm-unknown-linux-gnueabi
  arm-unknown-linux-gnueabihf
  arm-unknown-linux-musleabi
  arm-unknown-linux-musleabihf
  armebv7r-none-eabi
  armebv7r-none-eabihf
  armv5te-unknown-linux-gnueabi
  armv5te-unknown-linux-musleabi
  armv7-linux-androideabi
  armv7-unknown-linux-gnueabi
  armv7-unknown-linux-gnueabihf
  armv7-unknown-linux-musleabi
  armv7-unknown-linux-musleabihf
  armv7a-none-eabi
  armv7r-none-eabi
  armv7r-none-eabihf
  asmjs-unknown-emscripten
  i586-pc-windows-msvc
  i586-unknown-linux-gnu
  i586-unknown-linux-musl
  i686-linux-android
  i686-pc-windows-gnu
  i686-pc-windows-msvc
  i686-unknown-freebsd
  i686-unknown-linux-gnu
  i686-unknown-linux-musl
  mips-unknown-linux-gnu
  mips-unknown-linux-musl
  mips64-unknown-linux-gnuabi64
  mips64-unknown-linux-muslabi64
  mips64el-unknown-linux-gnuabi64
  mips64el-unknown-linux-muslabi64
  mipsel-unknown-linux-gnu
  mipsel-unknown-linux-musl
  nvptx64-nvidia-cuda
  powerpc-unknown-linux-gnu
  powerpc64-unknown-linux-gnu
  powerpc64le-unknown-linux-gnu
  riscv32i-unknown-none-elf
  riscv32imac-unknown-none-elf
  riscv32imc-unknown-none-elf
  riscv64gc-unknown-linux-gnu
  riscv64gc-unknown-none-elf
  riscv64imac-unknown-none-elf
  s390x-unknown-linux-gnu
  sparc64-unknown-linux-gnu
  sparcv9-sun-solaris
  thumbv6m-none-eabi
  thumbv7em-none-eabi
  thumbv7em-none-eabihf
  thumbv7m-none-eabi
  thumbv7neon-linux-androideabi
  thumbv7neon-unknown-linux-gnueabihf
  thumbv8m.base-none-eabi
  thumbv8m.main-none-eabi
  thumbv8m.main-none-eabihf
  wasm32-unknown-emscripten
  wasm32-unknown-unknown
  wasm32-wasi
  x86_64-apple-darwin
  x86_64-apple-ios
  x86_64-fortanix-unknown-sgx
  x86_64-fuchsia
  x86_64-linux-android
  x86_64-pc-solaris
  x86_64-pc-windows-gnu
  x86_64-pc-windows-msvc
  x86_64-sun-solaris
  x86_64-unknown-freebsd
  x86_64-unknown-illumos
  x86_64-unknown-linux-gnu (installed)
  x86_64-unknown-linux-gnux32
  x86_64-unknown-linux-musl
  x86_64-unknown-netbsd
  x86_64-unknown-redox
  ```

  这里以添加`aarch64-unknown-linux-gnu`平台为例，添加命令如下：

  ```bash
  rustup target add --toolchain stable aarch64-unknown-linux-gnu
  ```

  Ps：如果要移除指定Target把上面命令换成`rustup target remove`即可。

  输出如下

  ```tex
  info: downloading component 'rust-std' for 'aarch64-unknown-linux-gnu'
  info: installing component 'rust-std' for 'aarch64-unknown-linux-gnu'
   35.6 MiB /  35.6 MiB (100 %)   9.9 MiB/s in  3s ETA:  0s
  ```

  安装完成后可以通过Cargo进行编译 `cargo build --target=aarch64-unknown-linux-gnu`

参考

+ [[Cross-compilation](https://rust-lang.github.io/rustup/cross-compilation.html#cross-compilation)]

  

-- 全文完 --



  

  

