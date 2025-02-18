---
title: "Rust安装及配置"
date: 2022-02-28
tags: ["rust", "mirror", "windows", "setup"]
draft: false
---
## 下载rustup
从[此处](https://www.rust-lang.org/tools/install)下载，如果你需要安装vs的cpp生成工具，可以在[这个页面](https://visualstudio.microsoft.com/downloads/)进行下载。
## 设置rustup镜像

### 字节提供的镜像
[https://rsproxy.cn](https://rsproxy.cn)

```bash
export RUSTUP_DIST_SERVER="https://rsproxy.cn"
export RUSTUP_UPDATE_ROOT="https://rsproxy.cn/rustup"
```
设置两个环境变量即可。windows可以使用下面的命令进行设置：

```cmd
setx RUSTUP_DIST_SERVER "https://rsproxy.cn"
setx RUSTUP_UPDATE_ROOT "https://rsproxy.cn/rustup"
```

### 中科大

设置环境变量 `RUSTUP_DIST_SERVER` (用于更新 toolchain)

```bash
export RUSTUP_DIST_SERVER=https://mirrors.ustc.edu.cn/rust-static
```
以及 `RUSTUP_UPDATE_ROOT` (用于更新 rustup)
```bash
export RUSTUP_UPDATE_ROOT=https://mirrors.ustc.edu.cn/rust-static/rustup
```
### 华中科技大学

**方法一：**在“系统-高级系统设置-环境变量” 中增加环境变量。

- 变量名为 `RUSTUP_DIST_SERVER`，值为`https://mirrors.hust.edu.cn/rustup`。
- 变量名为 `RUSTUP_UPDATE_ROOT`，值为`https://mirrors.hust.edu.cn/rustup/rustup`。

**方法二（推荐）：**直接执行下面的Powershell脚本：

```powershell
[System.Environment]::SetEnvironmentVariable("RUSTUP_DIST_SERVER", "https://mirrors.hust.edu.cn/rustup", "User")
[System.Environment]::SetEnvironmentVariable("RUSTUP_UPDATE_ROOT", "https://mirrors.hust.edu.cn/rustup/rustup", "User")
```

> 设置`RUSTUP_HOME`和`CARGO_HOME`可以实现自定义安装路径

对于使用buf的开发者，需要添加下面的内容：

```toml
[registries.buf]
index = "sparse+https://buf.build/gen/cargo/"
credential-provider = "cargo:token"
```

然后登陆,token可以从[这里](https://buf.build/docs/bsr/authentication#create-a-token)获取

```bash
cargo login --registry buf "Bearer {token}"
```

更多内容，请参考https://buf.build/docs/bsr/generated-sdks/cargo

## crates.io 镜像

编辑 `~/.cargo/config `，这里使用的是中科大的镜像。

> cargo版本 1.39 中添加了对 `.toml` 扩展的支持，并且是首选形式。如果两个文件都存在，Cargo 将使用不带扩展名的文件。

```toml
[source.crates-io]
replace-with = 'ustc'

[source.ustc]
registry = "git://mirrors.ustc.edu.cn/crates.io-index"

```
或者使用字节的,参考[官网文档](https://rsproxy.cn/#getStarted)
```toml
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

华中科技大学的镜像 [文档](https://mirrors.hust.edu.cn/docs/crates)

```toml
[source.crates-io]
replace-with = 'hustmirror'

[source.hustmirror]
registry = "https://mirrors.hust.edu.cn/crates.io-index/"
```

>cargo 1.68 版本开始支持稀疏索引：不再需要完整克隆 crates.io-index 仓库，可以加快获取包的速度。
>
>如果您的 cargo 版本小于 1.68，可以通过 cargo +nightly -Z sparse-registry update 使用稀疏索引。
>
>华中科技大学的使用稀疏索引的镜像为
>
>```toml
>[source.crates-io]
>replace-with = 'hustmirror'
>
>[source.hustmirror]
>registry = "sparse+https://mirrors.hust.edu.cn/crates.io-index/"
>```

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
> 注:可以通过 `rustup toolchain install version` 和 `rustup default version`来安装和设置默认的toolchain的版本。
>
> rust的nightly 版本，rustc 已经增加了对 `x86_64-win7-windows-msvc` 的 target 的支持 编译方式修改为： `cargo build --release -Z build-std --target x86_64-win7-windows-msvc` 或者 `i686-win7-windows-msvc`
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

## 其他参数设置
### 设置统一Target目录
为所有Rust项目设置一个共享的target目录，请按下步骤：

1. 打开或创建位于全局的Cargo配置文件`~/.cargo/config`

2. 在文件中添加以下两行配置：
```toml
[build]
target-dir = "/target/directory"
```

>替换`/target/directory`为你自己的共享target目录。

### 减小程序编译体积

> 原文 https://harrychen.xyz/2023/09/03/cross-compile-rust-to-mipsel/

即使使用 release 模式，编译出的二进制文件体积也较大。通过调整编译 profile 可以进一步减少体积。在 `Cargo.toml` 中增加：

```toml
[profile.minsize]
inherits = "release"
strip = true
lto = true
opt-level = "z"
panic = "abort"
```

## IDE

### rustrover
### vscode
###  neovim

相关仓库 https://github.com/mrcjkb/rustaceanvim

## 其他实用工具

### Rustowl

官方仓库 https://github.com/cordx56/rustowl

可视化 Rust 中的所有权和生命周期，以便进行调试和优化

RustOwl 通过使用下划线来可视化这些内容：

- 🟩 绿色：变量的实际生命周期
- 🟦 蓝色：不可变借款
- 🟪 紫色：可变借款
- 🟧 橙色：值移动/函数调用
- 🟥 红色：生命周期误差 - 实际生命周期与预期生命周期之间的差异

安装 

```bash
curl -L "https://github.com/cordx56/rustowl/releases/download/v0.1.1/install.sh" | sh
```



### cacon

[bacon](https://dystroy.org/bacon/)是一个后台的 rust 代码检查器.它专为最小化交互而设计，因此您可以让它与编辑器一起运行，并收到有关 Rust 代码中的警告、错误或测试失败的通知。

安装 `cargo install --locked bacon`然后`bacon`启动

### sccache

官方仓库 https://github.com/mozilla/sccache

安装 `cargo install sccache --locked`,然后修改 `$HOME/.cargo/config.toml`，添加下面的内容

```toml
[build]
rustc-wrapper = "/path/to/sccache"
```

或者使用环境变量的方式

```bash
export RUSTC_WRAPPER=/path/to/sccache
cargo build
```

### WASM

需要安装Target

```bash
rustup target add wasm32-unknown-unknown
```

可以使用这几个库

+ wasm-bindgen-cli
+ wasm-pack
+ napi-rs

参考文章 https://mp.weixin.qq.com/s/ULErveNYlnyHFdoH8-3peA

### 代码覆盖率工具

#### **cargo-tarpaulin**

```bash
cargo install cargo-tarpaulin
```

或者

```bash
cargo binstall cargo-tarpaulin
```

[使用帮助](https://crates.io/crates/cargo-tarpaulin)参考

#### **grcov**

```bash
cargo install grcov
```

[使用说明](https://crates.io/crates/grcov)

#### **cargo-llvm-cov**

```bash
cargo +stable install cargo-llvm-cov --locked
```

[使用说明](https://crates.io/crates/cargo-llvm-cov)

### cargo-wizard

该工具可以将配置文件和配置模板应用于您的 Cargo 项目，以将其配置为最大性能、快速编译时间或最小二进制大小。[github](https://github.com/kobzol/cargo-wizard)

```bash
cargo install cargo-wizard
```

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

### cargo-zigbuild

[官方仓库](https://github.com/rust-cross/cargo-zigbuild)

#### 安装

使用 zig 作为链接器编译 Cargo 项目，以便于交叉编译。

```bash
cargo install cargo-zigbuild
```

您也可以使用 pip 安装它，它也会自动安装 `ziglang` ：

```bash
pip install cargo-zigbuild
```

#### 使用

1. 按照官方文档安装 zig，在 macOS、Windows 和 Linux 上，您还可以通过以下方式 `pip3 install ziglang` 从 PyPI 安装 zig

2. 通过 rustup 安装 Rust 目标，例如， `rustup target add aarch64-unknown-linux-gnu`

3. 运行 `cargo zigbuild` ，例如， `cargo zigbuild --target aarch64-unknown-linux-gnu`

   > **其他选项**
   >
   > + `cargo zigbuild` 支持在选项中 --target 传递 glibc 版本，例如，使用 aarch64-unknown-linux-gnu 目标编译 glibc 2.17：`cargo zigbuild --target aarch64-unknown-linux-gnu.2.17`
   >
   > + `cargo zigbuild` 支持在 Rust 1.64.0 及更高版本上构建 macOS universal2 二进制文件/库的特殊 `universal2-apple-darwin` 目标。
   >
   > ```bash
   > rustup target add x86_64-apple-darwin
   > rustup target add aarch64-apple-darwin
   > cargo zigbuild --target universal2-apple-darwin
   > ```
   >
   > 请注意，Cargo `--message-format` 选项目前不适用于 universal2 目标。

### cross

cross是一个跨平台编译的工具，github仓库地址为 https://github.com/cross-rs/cross

安装命令

```bash
cargo install cross
```

> ⚠️ 这个工具需要安装docker或者podman

### cargo-zigbuild

借助[cargo-zigbuild](https://github.com/rust-cross/cargo-zigbuild)也可以实现跨平台编译。

使用cargo安装 

```bash
cargo install cargo-zigbuild
```

或者使用pip进行安装(会自动安装zig)

```bash
pip install cargo-zigbuild
```

或者使用docker

```bash
docker run --rm -it -v $(pwd):/io -w /io messense/cargo-zigbuild \
  cargo zigbuild --release --target x86_64-apple-darwin
```

使用前确保zig已经安装，可以参考[zig官方的文档](https://ziglang.org/learn/getting-started/#installing-zig),然后确认通过rustup已经安装了对应的target，例如

```
rustup target add aarch64-unknown-linux-gnu
```

运行`cargo zigbuild`, 例如, 

```
cargo zigbuild --target aarch64-unknown-linux-gnu
```

cargo zigbuild 支持在 --target 选项中传递 glibc 版本，例如，使用 aarch64-unknown-linux-gnu 目标编译 glibc 2.17：

``` cargo zigbuild --target aarch64-unknown-linux-gnu.2.17```

>glibc 版本定位功能有多种注意事项：
>
>如果您不提供 --target ，则不会使用 Zig 并且该命令有效地运行常规 cargo build 。
>如果您指定无效的 glibc 版本， cargo zigbuild 将不会转发 zig cc 发出的有关所选后备版本的警告。
>此功能不一定与动态链接到构建主机上特定版本的 glibc 的行为相匹配。
>可以指定版本 2.32，但在只有 2.31 可用的主机上运行时，它应该因错误而中止。
>同时，在使用 glibc 2.31 的主机上运行时，指定 2.33 将被正确检测为不兼容。
>某些 RUSTFLAGS 如 -C linker 选择退出使用 Zig，而 -L path/to/files 将使 Zig 忽略 -C target-feature=+crt-static 。
>不支持静态链接到 glibc 版本的 -C target-feature=+crt-static （上游 zig cc 缺乏支持）

### uniffi-rs

这个是mozilla提供的工具，可以生成高效的ffi代码

仓库：https://github.com/mozilla/uniffi-rs

安装：`cargo install uniffi_bindgen`

参考：

- [Rust UniFFI 与 C# 交互实战：从入门到精通](https://mp.weixin.qq.com/s/o-OZlKJasFMnqI55FDQVAg)
- [UniFFI 官方文档](https://mozilla.github.io/uniffi-rs/)
- https://github.com/imWildCat/uniffi-rs-fullstack-examples

### generate

cargo generate,这个工具可利用预先存在的 git 存储库作为模板，帮助您快速启动并运行新的 Rust 项目。官方[github](https://github.com/cargo-generate/cargo-generate)仓库，[帮助文档](https://cargo-generate.github.io/cargo-generate/index.html)

安装命令

```bash
cargo install cargo-generate
```

>陈天的两个模板库
>
>+ [smithy]( https://github.com/tyrchen/smithy-template)
> > smithy是一个用来编写WebAssembly的框架，官网网站 https://www.smithy.rs
>
>+ [rust template](https://github.com/tyrchen/rust-template)
>
>我的generate仓库
>
>+ [axum模板](https://github.com/tpl-x/axump)

### cargo-update

cargo-update是一个用于检查已安装的可执行文件并将更新应用到的 `cargo` 子命令

```bash
cargo install cargo-update
```

### cargo binstall 

[binstall](https://github.com/cargo-bins/cargo-binstall) 提供了一种低复杂度的机制来安装 Rust 二进制文件，作为从源代码构建（通过 `cargo install` ）或手动下载包的替代方案。其目的是与现有的 CI 工件和基础设施一起使用，并为包维护人员提供最小的开销。

#### Linux and macOS

```bash
curl -L --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh | bash
```

#### Windows

```bash
Set-ExecutionPolicy Unrestricted -Scope Process; iex (iwr "https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.ps1").Content
```

或者使用源码安装

```bash
cargo install cargo-binstall
```

### Cargo deny

Cargo deny 是一个 Cargo 插件，可以用于检查依赖的安全性。

```
cargo install --locked cargo-deny
```

### typos

typos 是一个拼写检查工具。

```
cargo install typos-cli
```

### git cliff

git cliff 是一个生成 changelog 的工具。

```
cargo install git-cliff
```

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

### cargo watch

Cargo watch是一个Cargo插件，用于监视项目源文件中的更改。

在项目根目录下，运行如下命令安装cargo watch：

```bash
cargo add cargo-watch
```

然后运行以下命令来运行cargo watch：

```bash
cargo watch -q -c -w src/ -X 'run -q'
```

- -q 代表安静，它会抑制cargo watch的输出
- -c 将清除屏幕，
- -w 允许我们指定要监视的文件和文件夹，在这个例子中，只监视src目录
- -x 允许我们指定要执行的cargo命令，在本例中我们执行“cargo run -q”，如果我们执行这个命令，那么将阻止打印cargo日志消息。

如果代码发生变化，程序将自动重新编译。

### cargo-fuzz

cargo-fuzz是一款模糊测试工具，它使用一种称为模糊测试的技术来进行自动化软件测试。通过向程序提供许多有效的、几乎有效的或无效的输入，模糊测试可以帮助开发人员找到不希望看到的行为或漏洞。

安装

```bash
cargo install cargo-fuzz
```

下面是一个如何使用cargo-fuzz对Rust函数进行模糊测试的例子：

```rust
#![no_main]
#[macro_use]
extern crate libfuzzer_sys;
fuzz_target!(|data: &[u8]| {

    let json_string = std::str::from_utf8(data).unwrap();
    let _ = serde_json::from_str::<serde_json::Value>(&json_string).unwrap();

});
```

上面的代码通过向JSON解析器提供随机输入来测试它。fuzz_target将持续被调用，直到遇到触发panic并导致崩溃的输入。

### cargo-shuttle

[shuttle](https://www.shuttle.rs)可以将你的网站作为serverless进行托管

安装

```bash
cargo install cargo-shuttle
```

创建项目

```bash
cargo shuttle init
```

部署

```bash
cargo shuttle deploy
```

更多请参考[文档](https://docs.shuttle.rs/)

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

同时也可以使用Github Action来进行自动化可持续集成，下面是一个简单的Action例子

```yaml
name: Rust CI

on: 
  push:
    branches:
      - main
  pull_request:
    branches:
      - main

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - name: Set up Rust
        uses: actions/checkout@v2
      - name: Install cargo-audit
        uses: cargo install cargo-audit
      - name: Build
        uses: cargo build --verbose
      - name: Test
        uses: cargo test --verbose
      - names: Clippy
        uses: cargo clippy --verbose -- -D warnings
      - names: Audit
        uses: cargo audit
```

### cargo-dist

该工具用来分发您的二进制文件，使用该工具将生成自己的 CI 脚本。例如，使用 `cargo dist init` 启用 GitHub CI 将生成release.yml，它实现了计划、构建、托管、发布、宣布的完整管道：

-  计划
  - 等待您推送新版本的 git 标签（v1.0.0、my-app-v1.0.0、my-app/1.0.0，...）
  - 根据该标签选择工作区中要发布新版本的应用程序
  - 生成包含变更日志和构建计划的机器可读清单
-  建造
  - 为您支持的每个平台启动机器
  - 构建您的二进制文件和 tarball
  - 为您的二进制文件构建安装程序
-  发布：
  - 上传到包管理器
-  托管+发布changelog：
  - 创建（或编辑）GitHub 版本
  - 将构建工件上传到发行版
  - 添加发布/变更日志中的相关发行说明

安装 

```bash
cargo install cargo-dist
```

详细使用，请参考  [cargo-dist book](https://axodotdev.github.io/cargo-dist/book/)

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
      - uses: dtolnay/rust-toolchain@stable
        with:
          profile: minimal
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
      - uses: actions/upload-artifact@v4
        with:
          name: DiscordLauncher-${{ matrix.target }}
          path: target/${{ matrix.target }}/release/${{ matrix.exe }}
      - name: Zip Release
        uses: TheDoctor0/zip-release@0.7.5
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

+ [Rust开发环境最佳设置](https://mp.weixin.qq.com/s/cQxIxKYjumH21ZV1yEwVfw)

+ https://github.com/rust-cross/cargo-zigbuild

+ [必看！2024 Rust精选库清单，值得收藏](https://zhuanlan.zhihu.com/p/688906139)

+ https://blessed.rs/crates

  
  
  

-- 全文完 --



  

  

