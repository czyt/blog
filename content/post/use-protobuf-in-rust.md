---
title: "在rust中使用protobuf"
date: 2024-08-29
tags: ["rust","protobuf"]
draft: false
---

## 常规方式

### 安装必要工具

```bash
# 安装 protoc
# 在 macOS 上：
brew install protobuf

# 在 Ubuntu 上：
sudo apt-get install protobuf-compiler

# 安装 Rust protobuf 代码生成器
cargo install protobuf-codegen
```

### 示例

创建一个protobuf的文件：

message.proto

```protobuf
syntax = "proto3";

package mypackage;

message Person {
  string name = 1;
  int32 age = 2;
  string email = 3;
}
```

然后执行命令

```bash
protoc --rust_out=. message.proto
```

如果是在项目中，在你的 Rust 项目中，添加必要的依赖到 Cargo.toml：

```yaml
[dependencies]
protobuf = "2.27.1"
```

然后可以在代码中访问生成的内容

```rust
use protobuf::Message;
mod message; // 引入生成的模块
use message::Person;

fn main() {
    let mut person = Person::new();
    person.set_name("Alice".to_string());
    person.set_age(30);
    person.set_email("alice@example.com".to_string());

    // 序列化
    let encoded: Vec<u8> = person.write_to_bytes().unwrap();

    // 反序列化
    let decoded = Person::parse_from_bytes(&encoded).unwrap();
    println!("Name: {}", decoded.get_name());
    println!("Age: {}", decoded.get_age());
    println!("Email: {}", decoded.get_email());
}
```

可以借助build.rs来自动化这一步骤：

build.rs

```rust
// build.rs
use std::env;
use std::path::PathBuf;

fn main() {
    let out_dir = PathBuf::from(env::var("OUT_DIR").unwrap());
    protobuf_codegen::Codegen::new()
        .out_dir(&out_dir)
        .inputs(&["src/message.proto"])
        .include("src")
        .run()
        .expect("Codegen failed.");
}
```

然后在你的 main.rs 或 lib.rs 中：

```rust
include!(concat!(env!("OUT_DIR"), "/message.rs"));
```

>如果你想使用 gRPC，可以考虑使用 tonic 库，它提供了更现代和 Rust 风格的 API：
>
>```yaml
>[dependencies]
>tonic = "0.8"
>prost = "0.11"
>
>[build-dependencies]
>tonic-build = "0.8"
>```
>
>使用 tonic-build 在 build.rs 中生成代码：
>
>```rust
>fn main() -> Result<(), Box<dyn std::error::Error>> {
>    tonic_build::compile_protos("src/message.proto")?;
>    Ok(())
>}
>```

## 使用buf

buf的使用，请参考官方文档，这里仅提供一个buf.gen.yaml的配置：

buf.gen.yaml:

```yaml
# buf.gen.yaml
version: v2
managed:
  enabled: true
plugins:
  - remote: buf.build/community/neoeinstein-prost:v0.4.0
    out: gen
```

其他的插件：

- *[protoc-gen-prost](https://github.com/neoeinstein/protoc-gen-prost/blob/main/protoc-gen-prost/README.md)*: The core code generation plugin
- *[protoc-gen-prost-crate](https://github.com/neoeinstein/protoc-gen-prost/blob/main/protoc-gen-prost-crate/README.md)*: Generates an include file and cargo manifest for turn-key crates
- *[protoc-gen-prost-serde](https://github.com/neoeinstein/protoc-gen-prost/blob/main/protoc-gen-prost-serde/README.md)*: Canonical JSON serialization of protobuf types
- *[protoc-gen-prost-validate](https://github.com/neoeinstein/protoc-gen-prost/blob/main/protoc-gen-prost-validate/README.md)*: Generate validators based on embedded metadata
- *[protoc-gen-tonic](https://github.com/neoeinstein/protoc-gen-prost/blob/main/protoc-gen-tonic/README.md)*: gRPC service generation for the *[Tonic](https://github.com/hyperium/tonic)* framework