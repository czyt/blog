---
title: "在rust中使用duckdb的一些笔记"
date: 2024-07-12
tags: ["rust"]
draft: false
---

## 基本使用

### 添加cargo包

在cargo.toml中添加

```toml
[dependencies]
duckdb = {version = "1"}
```



### 示例代码

```rust
use duckdb::{params, Connection, Result};
use duckdb::arrow::record_batch::RecordBatch;
use duckdb::arrow::util::pretty::print_batches;

#[derive(Debug)]
struct Person {
    id: i32,
    name: String,
    data: Option<Vec<u8>>,
}

fn main() -> Result<()> {
    let conn = Connection::open_in_memory()?;

    conn.execute_batch(
        r"CREATE SEQUENCE seq;
          CREATE TABLE person (
                  id              INTEGER PRIMARY KEY DEFAULT NEXTVAL('seq'),
                  name            TEXT NOT NULL,
                  data            BLOB
                  );
         ")?;
    let me = Person {
        id: 0,
        name: "Steven".to_string(),
        data: None,
    };
    conn.execute(
        "INSERT INTO person (name, data) VALUES (?, ?)",
        params![me.name, me.data],
    )?;

    let mut stmt = conn.prepare("SELECT id, name, data FROM person")?;
    let person_iter = stmt.query_map([], |row| {
        Ok(Person {
            id: row.get(0)?,
            name: row.get(1)?,
            data: row.get(2)?,
        })
    })?;

    for person in person_iter {
        println!("Found person {:?}", person.unwrap());
    }

    // query table by arrow
    let rbs: Vec<RecordBatch> = stmt.query_arrow([])?.collect();
    print_batches(&rbs);
    Ok(())
}
```




## 编译环境设置

Linux不需要过多配置，在windows下使用duckdb库的时候，windows需要作一些设置才可以正常编译

### windows

因为rust的duckdb库，使用c api进行编写，需要链接相关的库。在Windows下，可以通过下面的步骤来实现。

#### 下载libduckdb

在duckdb的[release页面](https://github.com/duckdb/duckdb/releases)下载`libduckdb-windows-amd64.zip`（我是windows64的系统），然后解压到源代码目录

#### 创建build.rs

创建一个build.rs,内容如下：

```rust
use std::env;
use std::fs;
use std::path::{Path, PathBuf};

fn main() {
    #[cfg(target_os = "windows")]
    {
        // 获取当前项目根目录
        let current_dir = env::current_dir().expect("Failed to get current directory");

        // 相对于项目根目录的自定义库路径
        let custom_lib_relative_path = PathBuf::from("libduckdb");

        // 构建绝对路径
        let custom_lib_path = current_dir.join(&custom_lib_relative_path);

        // 将新的路径添加到 LINKER_SEARCH_PATH
        println!("cargo:rustc-link-search=native={}", custom_lib_path.display());
        // 设置要链接的库名称
        println!("cargo:rustc-link-lib=static=duckdb");

        // 获取目标输出目录并转到上级目录
        let out_dir = env::var("OUT_DIR").unwrap();
        let target_dir = PathBuf::from(&out_dir)
            .ancestors()
            .nth(3)
            .expect("Failed to find target directory")
            .to_path_buf();

        // 定义一个递归复制文件的函数
        fn copy_dir_all(src: &Path, dst: &Path) -> std::io::Result<()> {
            if !dst.exists() {
                fs::create_dir_all(dst)?;
            }
            for entry in fs::read_dir(src)? {
                let entry = entry?;
                let file_type = entry.file_type()?;
                if file_type.is_dir() {
                    copy_dir_all(&entry.path(), &dst.join(entry.file_name()))?;
                } else {
                    fs::copy(entry.path(), dst.join(entry.file_name()))?;
                }
            }
            Ok(())
        }

        // 复制 lib 文件夹中的所有文件到 target 目录
        copy_dir_all(&custom_lib_path, &target_dir).expect("Failed to copy files");
    }
}

```

除了上述的方式外，还可以通过设置`DUCKDB_LIB_DIR`和`DUCKDB_INCLUDE_DIR`这两个环境变量来设置lib的路径。ps：文件也还是需要拷贝。参考的是这个说明：
> When linking against a DuckDB library already on the system (so *not* using any of the `bundled` features), you can set the `DUCKDB_LIB_DIR` environment variable to point to a directory containing the library. You can also set the `DUCKDB_INCLUDE_DIR` variable to point to the directory containing `duckdb.h`.

ok，所有工作完成。