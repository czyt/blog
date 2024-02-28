---
title: "Rust安装及配置"
date: 2022-02-28
tags: ["rust", "mirror", "windows", "setup"]
draft: false
---
## 下载rustup
从[此处](https://www.rust-lang.org/tools/install)下载，如果你需要安装vs的cpp生成工具，可以在[这个页面](https://visualstudio.microsoft.com/downloads/)进行下载。
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
设置`RUSTUP_HOME`和`CARGO_HOME`可以实现自定义安装路径

## crates.io 镜像
编辑 `~/.cargo/config `，这里使用的是中科大的镜像。

```
[source.crates-io]
replace-with = 'ustc'

[source.ustc]
registry = "git://mirrors.ustc.edu.cn/crates.io-index"

```
或者使用字节的,参考[官网文档](https://rsproxy.cn/#getStarted)
```
[source.crates-io]
replace-with = 'rsproxy-sparse'
[source.rsproxy]
registry = "https://rsproxy.cn/crates.io-index"
[source.rsproxy-sparse]
registry = "sparse+https://rsproxy.cn/index/"
[registries.rsproxy]
index = "https://rsproxy.cn/crates.io-index"
[net]
git-fetch-with-cli = true
```

## 安装Rust

### Windows

安装rust即可。可以参考我的步骤，如果安装的是[vs的cpp build tools](https://visualstudio.microsoft.com/downloads/?cid=learn-navbar-download-cta)，可以跳过。

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
### 其他Linux

可以使用脚本进行安装:

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

### Arch

使用包安装工具安装

```bash
paru -S rustup
```

然后安装rust

```bash
rustup install stable
```

## 配置cargo镜像

参考 

- [https://www.cnblogs.com/dhcn/p/12100675.html](https://www.cnblogs.com/dhcn/p/12100675.html)

- [https://erasin.wang/rustup/](https://erasin.wang/rustup/)

## 其他实用工具

### rust-analyzer

安装 `rustup component add rust-analyzer`

### cargo-expand

cargo expand 来查看 derive macro 展开后的代码，你首先需要在你的 Rust 项目中安装 cargo-expand：

```bash
cargo install cargo-expand
```

之后，你可以在你的项目目录中运行以下命令来查看 derive macro 展开后的代码：
```bash
cargo expand
```

这会编译你的项目，并输出所有宏展开后的代码，

### flamegraph

火焰图工具，安装

```bash
cargo install flamegraph
cargo install cargo-flamegraph
```

### cross

cross是一个跨平台编译的工具，github仓库地址为 https://github.com/cross-rs/cross

安装命令

```bash
cargo install cross
```

> ⚠️ 这个工具需要安装docker或者podman

### generate

cargo generate,这个工具可利用预先存在的 git 存储库作为模板，帮助您快速启动并运行新的 Rust 项目。官方[github](https://github.com/cargo-generate/cargo-generate)仓库，[帮助文档](https://cargo-generate.github.io/cargo-generate/index.html)

安装命令

```bash
cargo install cargo-generate
```

>陈天的两个模板库
>
>+ [smithy](https://www.smithy.rs) https://github.com/tyrchen/smithy-template
>+ [rust template](https://github.com/tyrchen/rust-template)



###  cargo-audit

cargo-audit是一个简单的Cargo工具，可以运行`cargo audit`用于检测项目中存在安全问题。安装命令

```bash
cargo install cargo-audit
```

除了检查安全漏洞，cargo-audit还支持支持自动更新（实验性功能），用来修复存在问题的依赖项。

可通过

```
cargo install cargo-audit --features=fix
```

要启用安装后，然后运行

```
cargo audit fix
```

即可以自动修复Cargo.toml中存在安全问题的依赖项。

### cargo-nextest

nextest自诩为“下一代Rust测试运行程序”。

安装

```bash
cargo install cargo-nextest
```

安装，安装后在项目目录（或工作区），可以使用以下命令运行测试

```bash
cargo nextest run
```

### cargo-make

使用cargo安装

```bash
cargo install --force cargo-make
```

如果是Arch Linux，可以使用下面的命令安装：

```bash
paru -S cargo-make
```

还可以在github下载编译好的二进制文件 [地址](https://github.com/sagiegurari/cargo-make/releases)。目前有下面几种平台的二进制文件。

- x86_64-unknown-linux-gnu

- x86_64-unknown-linux-musl

- x86_64-apple-darwin

- x86_64-pc-windows-msvc

- aarch64-apple-darwin

具体使用方法，请参考 https://crates.io/crates/cargo-make

## 跨平台编译

  可以使用上面的cross工具，下面是原生的方式。

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

  安装完成后可以通过Cargo进行编译 `cargo build --target=aarch64-unknown-linux-gnu`。另外，还可以借助Github Actions进行自动编译，下面是一个例子：

```yaml
name: Release
on:
  push:
    tags:
      - "*"

  workflow_dispatch:

env:
  CARGO_TERM_COLOR: always

jobs:
  release:
    name: Cross build for ${{ matrix.target }}
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        include:
          - os: ubuntu-latest
            target: x86_64-unknown-linux-gnu
            exe: DiscordLauncher
            cross: false

          - os: ubuntu-latest
            target: aarch64-unknown-linux-musl
            exe: DiscordLauncher
            cross: true

          - os: ubuntu-latest
            target: arm-unknown-linux-musleabi
            exe: DiscordLauncher
            cross: true

          - os: ubuntu-latest
            target: arm-unknown-linux-musleabihf
            exe: DiscordLauncher
            cross: true

          - os: ubuntu-latest
            target: armv7-unknown-linux-musleabihf
            exe: DiscordLauncher
            cross: true

          - os: windows-latest
            target: x86_64-pc-windows-msvc
            exe: DiscordLauncher.exe
            cross: false

          - os: macos-latest
            target: x86_64-apple-darwin
            exe: DiscordLauncher
            cross: false

    steps:
      - uses: actions/checkout@v4
      - uses: actions-rs/toolchain@v1
        with:
          profile: minimal
          # Since rust 1.72, some platforms are tier 3
          toolchain: 1.75
          default: true

      - name: Install OpenSSL
        if: matrix.os == 'ubuntu-latest'
        run: sudo apt-get install pkg-config libssl-dev
      - name: Install OpenSSL
        if: matrix.os == 'macos-latest'
        run: brew install openssl@3

      # Native build
      - name: Install target
        if: matrix.cross == false
        run: rustup target add ${{ matrix.target }}
      - name: Run tests
        if: matrix.cross == false
        run: cargo test --release --target ${{ matrix.target }} --verbose
      - name: Build release
        if: matrix.cross == false
        run: cargo build --release --target ${{ matrix.target }}

      # Cross build
      - name: Install cross
        if: matrix.cross
        run: cargo install --version 0.2.5 cross
      - name: Run tests
        if: matrix.cross
        run: cross test --release --target ${{ matrix.target }} --verbose  --no-default-features
      - name: Build release
        if: matrix.cross
        run: cross build --release --target ${{ matrix.target }}  --no-default-features

      - name: Run UPX
        # Upx may not support some platforms. Ignore the errors
        continue-on-error: true
        # Disable upx for mips. See https://github.com/upx/upx/issues/387
        if: matrix.os == 'ubuntu-latest' && !contains(matrix.target, 'mips')
        uses: crazy-max/ghaction-upx@v1
        with:
          version: v4.0.2
          files: target/${{ matrix.target }}/release/${{ matrix.exe }}
          args: -q --best --lzma
      - uses: actions/upload-artifact@v2
        with:
          name: DiscordLauncher-${{ matrix.target }}
          path: target/${{ matrix.target }}/release/${{ matrix.exe }}
      - name: Zip Release
        uses: TheDoctor0/zip-release@0.6.1
        with:
          type: zip
          filename: DiscordLauncher-${{ matrix.target }}.zip
          directory: target/${{ matrix.target }}/release/
          path: ${{ matrix.exe }}
      - name: Publish
        uses: softprops/action-gh-release@v1
        if: startsWith(github.ref, 'refs/tags/')
        with:
          files: target/${{ matrix.target }}/release/DiscordLauncher-${{ matrix.target }}.zip
          generate_release_notes: true
          draft: true
```



参考

+ [Cross-compilation](https://rust-lang.github.io/rustup/cross-compilation.html#cross-compilation)

+ [compiling-rust-for-raspberry-pi-arm](https://medium.com/swlh/compiling-rust-for-raspberry-pi-arm-922b55dbb050)

  
  
  

-- 全文完 --



  

  

