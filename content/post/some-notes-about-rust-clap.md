---
title: "一些rust clap库的笔记"
date: 2024-04-19
tags: ["rust","cli","rust-lib"]
draft: false
---

## 小试牛刀

clap是rust下面的一款命令行解析的库，下面是一些使用的笔记。

在Cargo.toml中添加下面的依赖

```toml
[dependencies]
clap = {version = "4",features = ["derive"]}
```

对应feature的作用如下：

默认特性

- **std**: *Not Currently Used.* Placeholder for supporting `no_std` environments in a backwards compatible manner.
- **color**: Turns on colored error messages.
- **help**: Auto-generate help output
- **usage**: Auto-generate usage
- **error-context**: Include contextual information for errors (which arg failed, etc)
- **suggestions**: Turns on the `Did you mean '--myoption'?` feature for when users make typos.

可选特性

- **deprecated**: Guided experience to prepare for next breaking release (at different stages of development, this may become default)
- **derive**: Enables the custom derive (i.e. `#[derive(Parser)]`). Without this you must use one of the other methods of creating a `clap` CLI listed above.
- **cargo**: Turns on macros that read values from [`CARGO_*` environment variables](https://doc.rust-lang.org/cargo/reference/environment-variables.html#environment-variables-cargo-sets-for-crates).
- **env**: Turns on the usage of environment variables during parsing.
- **unicode**: Turns on support for unicode characters (including emoji) in arguments and help messages.
- **wrap_help**: Turns on the help text wrapping feature, based on the terminal size.
- **string**: Allow runtime generated strings (e.g. with [`Str`](https://docs.rs/clap/4.5.4/clap/builder/struct.Str.html)).


### 使用derive实现（推荐）

下面是一个简单的示例

```rust
use clap::Parser;

/// Simple program to greet a person
#[derive(Parser, Debug)]
#[command(version, about, long_about = None)]
struct Args {
    /// Name of the person to greet
    #[arg(short, long)]
    name: String,

    /// Number of times to greet
    #[arg(short, long, default_value_t = 1)]
    count: u8,
}

fn main() {
    let args = Args::parse();

    for _ in 0..args.count {
        println!("Hello {}!", args.name)
    }
}
```

执行

```bash
$ demo --help
A simple to use, efficient, and full-featured Command Line Argument Parser

Usage: demo[EXE] [OPTIONS] --name <NAME>

Options:
  -n, --name <NAME>    Name of the person to greet
  -c, --count <COUNT>  Number of times to greet [default: 1]
  -h, --help           Print help
  -V, --version        Print version

$ demo --name Me
Hello Me!
```
### 使用Builder实现

下面是一个例子，模仿了pacman

```rust
use clap::{Arg, ArgAction, Command};

fn main() {
    let matches = Command::new("pacman")
        .about("package manager utility")
        .version("5.2.1")
        .subcommand_required(true)
        .arg_required_else_help(true)
        // Query subcommand
        //
        // Only a few of its arguments are implemented below.
        .subcommand(
            Command::new("query")
                .short_flag('Q')
                .long_flag("query")
                .about("Query the package database.")
                .arg(
                    Arg::new("search")
                        .short('s')
                        .long("search")
                        .help("search locally installed packages for matching strings")
                        .conflicts_with("info")
                        .action(ArgAction::Set)
                        .num_args(1..),
                )
                .arg(
                    Arg::new("info")
                        .long("info")
                        .short('i')
                        .conflicts_with("search")
                        .help("view package information")
                        .action(ArgAction::Set)
                        .num_args(1..),
                ),
        )
        // Sync subcommand
        //
        // Only a few of its arguments are implemented below.
        .subcommand(
            Command::new("sync")
                .short_flag('S')
                .long_flag("sync")
                .about("Synchronize packages.")
                .arg(
                    Arg::new("search")
                        .short('s')
                        .long("search")
                        .conflicts_with("info")
                        .action(ArgAction::Set)
                        .num_args(1..)
                        .help("search remote repositories for matching strings"),
                )
                .arg(
                    Arg::new("info")
                        .long("info")
                        .conflicts_with("search")
                        .short('i')
                        .action(ArgAction::SetTrue)
                        .help("view package information"),
                )
                .arg(
                    Arg::new("package")
                        .help("packages")
                        .required_unless_present("search")
                        .action(ArgAction::Set)
                        .num_args(1..),
                ),
        )
        .get_matches();

    match matches.subcommand() {
        Some(("sync", sync_matches)) => {
            if sync_matches.contains_id("search") {
                let packages: Vec<_> = sync_matches
                    .get_many::<String>("search")
                    .expect("contains_id")
                    .map(|s| s.as_str())
                    .collect();
                let values = packages.join(", ");
                println!("Searching for {values}...");
                return;
            }

            let packages: Vec<_> = sync_matches
                .get_many::<String>("package")
                .expect("is present")
                .map(|s| s.as_str())
                .collect();
            let values = packages.join(", ");

            if sync_matches.get_flag("info") {
                println!("Retrieving info for {values}...");
            } else {
                println!("Installing {values}...");
            }
        }
        Some(("query", query_matches)) => {
            if let Some(packages) = query_matches.get_many::<String>("info") {
                let comma_sep = packages.map(|s| s.as_str()).collect::<Vec<_>>().join(", ");
                println!("Retrieving info for {comma_sep}...");
            } else if let Some(queries) = query_matches.get_many::<String>("search") {
                let comma_sep = queries.map(|s| s.as_str()).collect::<Vec<_>>().join(", ");
                println!("Searching Locally for {comma_sep}...");
            } else {
                println!("Displaying all locally installed packages...");
            }
        }
        _ => unreachable!(), // If all subcommands are defined above, anything else is unreachable
    }
}
```

可以使用`command!()`，需要启用`cargo`特性。

```rust
use clap::{arg, command};

fn main() {
    // requires `cargo` feature, reading name, version, author, and description from `Cargo.toml`
    let matches = command!()
        .arg(arg!(--two <VALUE>).required(true))
        .arg(arg!(--one <VALUE>).required(true))
        .get_matches();

    println!(
        "two: {:?}",
        matches.get_one::<String>("two").expect("required")
    );
    println!(
        "one: {:?}",
        matches.get_one::<String>("one").expect("required")
    );
}
```


## 常见问题

### 参数组

在`clap`库中，可以用`ArgGroup`属性来创建参数组，这样你可以要求用户至少提供组中的一个参数，或者最多只能提供一个参数。以下是一个简单的例子：

```rust
use clap::{Parser, ArgGroup};

#[derive(Parser, Debug)]
#[clap(group = ArgGroup::new("input").required(true).multiple(false))]
struct Opt {
    #[clap(short, long, group = "input")]
    file: Option<String>,
    #[clap(short, long, group = "input")]
    url: Option<String>,
}

fn main() {
    let opt = Opt::parse();
    match opt {
        Opt { file: Some(file), .. } => println!("Using file: {}", file),
        Opt { url: Some(url), .. } => println!("Using url: {}", url),
        _ => unreachable!(),
    }
}
```

在这个例子中，我们创建了一个名为`Opt`的结构体，并使用`derive(Parser)`宏来自动为它实现`Parser` trait。我们还使用`#[clap(group = ArgGroup::new("input").required(true).multiple(false))]`来创建一个名为"input"的参数组，这个组是必需的，并且只能提供一个参数。然后我们添加了两个参数"file"和"url"，并将它们都添加到了"input"组中。最后，我们解析用户提供的命令行参数，并根据用户提供的参数来执行不同的操作。

当你运行这个程序时，你必须提供`-f`或`-u`选项，否则程序会报错。如果你同时提供了`-f`和`-u`选项，程序也会报错。

### 默认值

`clap`库中的`default_value`和`default_value_t`都是用于设置参数的默认值的，但它们的使用场景和方式有所不同。

1. `default_value`: 这个属性接受一个字符串作为默认值。当用户没有提供该参数时，`clap`会使用这个字符串作为默认值。这个属性在所有情况下都可以使用。

```rust
#[clap(short, default_value = "input.csv", long)]
input: String,
```

2. `default_value_t`: 这个属性接受一个类型为`T`的值作为默认值，其中`T`是参数的类型。当用户没有提供该参数时，`clap`会使用这个值作为默认值。这个属性只能在参数类型实现了`std::fmt::Display`和`std::str::FromStr`的情况下使用。

```rust
#[clap(short, default_value_t = 10, long)]
input: i32,
```

总的来说，`default_value`更加通用，可以接受任何字符串作为默认值，而`default_value_t`则需要参数类型实现了特定的trait，但它可以接受非字符串类型的默认值。

其他的还有下面一些常用的：

- `default_values_t = <expr>` ： `Arg::default_values` 和 `Arg::required(false)`
  - 要求字段 arg 的类型为 `Vec<T>` 和 `T` 才能实现 `std::fmt::Display` 或 `#[arg(value_enum)]`
  - `<expr>` 必须实现 `IntoIterator<T>`
- `default_value_os_t [= <expr>]` ： `Arg::default_value_os` 和 `Arg::required(false)`
  - 需要 `std::convert::Into<OsString>` 或 `#[arg(value_enum)]`
  - 没有 `<expr>` ，依赖 `Default::default()`
- `default_values_os_t = <expr>` ： `Arg::default_values_os` 和 `Arg::required(false)`
  - 要求字段 arg 的类型为 `Vec<T>` 和 `T` 才能实现 `std::convert::Into<OsString>` 或 `#[arg(value_enum)]`
  - `<expr>` 必须实现 `IntoIterator<T>`

### 值校验

可以使用 `Arg::value_parser` 验证并解析为任何数据类型。

```rust
use clap::{arg, command, value_parser};

fn main() {
    let matches = command!() // requires `cargo` feature
        .arg(
            arg!(<PORT>)
                .help("Network port to use")
                .value_parser(value_parser!(u16).range(1..)),
        )
        .get_matches();

    // Note, it's safe to call unwrap() because the arg is required
    let port: u16 = *matches
        .get_one::<u16>("PORT")
        .expect("'PORT' is required and parsing will fail if its missing");
    println!("PORT = {port}");
}
```

### 编写测试

clap 将大多数开发错误报告为 `debug_assert!` 。您应该进行一个调用 `Command::debug_assert` 的测试，而不是检查每个子命令：

```rust
use clap::{arg, command, value_parser};

fn main() {
    let matches = cmd().get_matches();

    // Note, it's safe to call unwrap() because the arg is required
    let port: usize = *matches
        .get_one::<usize>("PORT")
        .expect("'PORT' is required and parsing will fail if its missing");
    println!("PORT = {port}");
}

fn cmd() -> clap::Command {
    command!() // requires `cargo` feature
        .arg(
            arg!(<PORT>)
                .help("Network port to use")
                .value_parser(value_parser!(usize)),
        )
}

#[test]
fn verify_cmd() {
    cmd().debug_assert();
}
```

## 引用

更多请参考 [doc]( https://docs.rs/clap/4.5.4/clap/index.html)