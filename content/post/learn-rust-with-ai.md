---
title: "跟AI学习Rust"
date: 2024-02-16
tags: ["rust"]
draft: false
---

> 本文为学习rust过程中，向ai提问的内容汇总。配套图书为《Rust程序设计 第2版》

![GReMdJtb0AAGn53](https://assets.czyt.tech/img/rust-memory-container-cheet-sheet.jpg)

## 基础

### 迭代器

#### fuse



### Cow

在 Rust 中，`Cow` 是 "Clone on Write" 的缩写，它是一个智能指针类型，属于标准库的 `std::borrow` 模块。`Cow` 可以用来封装一个可能是借用（borrowed）也可能是拥有（owned）的值。`Cow`类型实际上是一个枚举类型，定义如下：

```rust
enum Cow<'a, B>
where
    B: 'a + ToOwned + ?Sized,
{
    Borrowed(&'a B),
    Owned(<B as ToOwned>::Owned),
}
```

其中 `B` 是被借用的类型，而 `<B as ToOwned>::Owned` 是该类型的拥有版本。一个具体类型必须实现 `ToOwned` trait，这样 `Cow` 才能根据需要clone被借用的数据产生一个拥有的副本。 **实际用途：** `Cow` 最大的优势在于它提供了一种方法来延迟昂贵的克隆操作，直到真正需要修改数据时才进行，这样可以提高性能。它经常被用于以下场景：

1. **优化读多写少的情况**：当数据通常只是被读取，但偶尔需要被修改时，`Cow` 可以避免不必要的克隆操作。
2. **提供 API 的灵活性**：某些函数可能需要对输入数据做出修改，但并不总是需要。这时，使用 `Cow` 作为参数类型允许调用者传递拥有的也可以是借用的值，增加了 API 的使用灵活性。
3. **处理字符串数据**：当处理字符串切片（`&str`）和字符串（`String`）时，`Cow<str>` 可以根据实际情况借用静态字符串或者拥有一个可变的字符串副本。
4. **避免生命周期问题**：当要返回一个引用但函数的实际行为可能需要返回一个拥有的值时，使用 `Cow` 可以更好地管理生命周期问题。

**示例:** 你可以在下面的示例中看到 `Cow` 的用法：

```rust
use std::borrow::Cow;
fn greeting(name: &str) -> Cow<str> {
    if name.is_empty() {
        // 不需要创建String
        Cow::Borrowed("Hello, guest!")
    } else {
        // 需要构建拥有的String
        Cow::Owned(format!("Hello, {}!", name))
    }
}
fn main() {
    let borrowed_name = "";
    let owned_name = "Alice";
    let borrow_greeting = greeting(borrowed_name);
    let owned_greeting = greeting(owned_name);
    println!("{}", borrow_greeting);
    println!("{}", owned_greeting);
}
```

在这个例子中，第一个 `greeting` 调用返回了一个被借用的值，因为 `name` 是空的，而第二个 `greeting` 调用返回了一个拥有的值，因为需要根据 `name` 的内容来格式化字符串。 通过使用 `Cow`，你可以在不牺牲性能的情况下写出更加灵活且可能更有效率的代码。 

### `move`和`ref`

在 Rust 中，`move` 和 `ref` 关键字在不同的上下文中被使用，通常用于处理所有权和借用。

### `move` 关键字

`move` 通常与闭包（closure）一起使用，用于改变闭包捕获外部变量的方式。默认情况下，闭包可能通过引用捕获变量，这样的话捕获的变量的生命周期必须不短于闭包本身。为了在闭包中使用长生命周期的变量，可以使用 `move` 关键字，这样闭包会获得变量的所有权，并且可以在闭包内安全地使用。

```rust
fn main() {
    let num = 5;
    // 使用 move 关键字，将 num 的所有权移入闭包
    let owns_num = move || {
        println!("This closure owns the num: {}", num);
    };
    owns_num(); // 正确执行
    // println!("{}", num); // 这里将无法编译，因为 num 已经被闭包 "owns_num" 拥有
}
```



### `ref` 关键字

`ref` 关键字则用于模式匹配的上下文中，允许通过模式匹配绑定非拥有（non-owning）引用到数据结构的一部分。这样可以方便地在不取得所有权的情况下访问数据结构的内容。

```rust
fn main() {
    let tuple = (1, 2, 3);
    // 使用 ref 关键字创建对元组中元素的引用
    let (a, ref b, _) = tuple;
    println!("a is: {}", a); // 直接打印 a，所有权被移动了
    println!("b is: {}", b); // 打印 b 的引用
    // tuple.1 是无效的，因为 b 的所有权并没有被移动，这里只引用了它的值
}
```

理解 `move` 和 `ref` 的使用主要还是与 Rust 的所有权和借用规则紧密相关，可以说它们是 Rust 内存安全理念的具体应用。通过正确地利用这两个关键字，可以编写既安全又高效的 Rust 代码。

### 如何区分`Fn`和`fn`

在 Rust 中，`Fn`，`FnMut` 和 `FnOnce` 是 trait 对象，分别代表了可调用的类型的三种调用约定：

1. **`Fn`**：是一个trait，代表一个不改变其捕获变量的闭包类型。使用此trait的闭包可以多次调用，并且不会更改环境中捕获的任何变量的值。

2. **`FnMut`**：也是一个trait，代表一个可变地借用其捕获变量的闭包类型，这意味着闭包在调用过程中能够改变这些变量的值。

3. **`FnOnce`**：同样是一个trait，表示一个消耗（取得所有权并可能移动）其捕获变量的闭包类型。这样的闭包只能被调用一次。

它们对应的使用场景分别如下：

#### `Fn`

- **不可变借用捕获变量**：当你拥有一个闭包，它需要读取环境中的变量，但不对其做出修改时，可以使用实现了 `Fn` trait 的闭包。
- **多次调用**：`Fn` trait 的闭包可以被多次调用，因为它们不改变它们的捕获环境。
- **高阶函数**：当你写一个函数，它接受一个闭包作为参数，并计划多次调用它，你应当要求它实现 `Fn`。
- **实现回调**：在观察者模式或事件监听器中，可使用 `Fn` trait 的闭包作为回调函数，因为它们经常需要被多次调用。

#### `FnMut`

- **可变借用捕获变量**：当闭包需要改变捕获的变量的值时，该闭包需要实现 `FnMut`。
- **状态变化**：当闭包需要维护状态，并且随着每次调用可能改变这些状态时，通常使用实现了 `FnMut` 的闭包。
- **迭代器适配器**：很多迭代器适配器接受实现了 `FnMut` 的闭包作为参数，因为它们需要修改环境来反映迭代过程中的状态。

#### `FnOnce`

- **消费捕获变量**：当一个闭包需要获取它捕获变量的所有权，并在调用过程中消费它们时，它应该实现 `FnOnce`。
- **单次调用**：由于 `FnOnce` 可能会对环境造成不可逆转的变化（例如，通过移动某个捕获变量），闭包可能只能被调用一次。
- **初始化代码**：在只运行一次的初始化代码中使用 `FnOnce` trait 的闭包是很常见的。

通过这些 trait，Rust 能够给予函数和闭包高度的灵活性，同时保持代码的安全性和性能。选择合适的闭包类型可以根据实际需要优化内存使用和性能。在设计 API 或框架时，合理地选择闭包类型是非常关键的。 

另一方面，**`fn`** 是一个函数指针类型，它代表一个具体的函数。这不是trait，而是一个类型本身。`fn` 用于指示普通函数的类型，而不是闭包。它用于引用或传递那些不需要捕获环境状态的普通函数。 简单来说：

- 使用 `Fn`，`FnMut` 或 `FnOnce` 作为 trait 边界或 trait 对象时，你通常指的是可以被调用的闭包；
- 使用 `fn` 关键字声明的是一个普通的函数，而作为类型时（小写 `fn`），它代表一个没有捕获变量的函数指针。

例如，你可以将普通函数作为参数传递给接受 `fn` 的函数，或者使用 `Fn` 等trait作为参数类型，来传递闭包给接受闭包的函数。 

### Lib支持多个平台

在lib中使用属性指定操作系统平台及对应文件

```rust
#[cfg(target_os = "windows")]
#[path = "win/mod.rs"]
mod platform;

#[cfg(target_os = "linux")]
#[path = "nix/mod.rs"]
mod platform;

#[cfg(target_os = "macos")]
#[path = "mac/mod.rs"]
mod platform;
```

可以使用not进行取反

```rust
#[cfg(not(target_os = "linux"))]
mod version;
#[cfg(not(target_os = "linux"))]
pub(crate) use self::version::Version;
```

下面以一个获取指定程序位置的库为例。如果您想要实现的功能是跨平台的并且能在不同操作系统下运行（例如，定位可执行文件的路径），Rust 代码的结构应该考虑以下几点：

1. **抽象层**：定义一个通用接口（trait）以抽象出查找可执行文件路径的行为。这样可以为不同操作系统实现具体的功能。
2. **平台特定实现**：针对每个操作系统实现上述接口。可能需要利用条件编译属性（比如 `#[cfg(target_os = "windows")]`），来确保只在特定平台编译特定代码。
3. **错误处理**：确保跨平台功能能够适当地处理错误，因为不同操作系统可能会以不同方式响应相同的操作。
4. **单元和集成测试**：为跨平台代码编写测试，确保功能在所有目标平台上都正常工作。

具体到代码结构，您可能会有下列结构：

```rust
// 定义一个名为 ExecutableFinder 的 trait，其有一个查找可执行文件路径的方法
pub trait ExecutableFinder {
    fn find_executable(&self, executable_name: &str) -> Option<PathBuf>;
}
// 针对 Unix-like 系统的平台特定实现
#[cfg(unix)]
pub struct UnixFinder;
#[cfg(unix)]
impl ExecutableFinder for UnixFinder {
    fn find_executable(&self, executable_name: &str) -> Option<PathBuf> {
        // Unix-like 系统的查找逻辑
    }
}
// 针对 Windows 系统的平台特定实现
#[cfg(windows)]
pub struct WindowsFinder;
#[cfg(windows)]
impl ExecutableFinder for WindowsFinder {
    fn find_executable(&self, executable_name: &str) -> Option<PathBuf> {
        // Windows 系统的查找逻辑
    }
}
// 一个通用的函数，它使用特定于平台的实现来查找可执行文件
pub fn find_executable_in_path(executable_name: &str) -> Option<PathBuf> {
    let finder: Box<dyn ExecutableFinder> = if cfg!(unix) {
        Box::new(UnixFinder)
    } else if cfg!(windows) {
        Box::new(WindowsFinder)
    } else {
        unimplemented!() // 对于其他系统，您可能需要实现额外的逻辑或者返回 None
    };
    finder.find_executable(executable_name)
}
```

### 默认值

#### 属性的默认值

在 Rust 当中，相对于其他语言如 Python，JavaScript 等，没有内建的对默认值的支持。但是你可以通过为结构体实现 `Default` trait 来定义默认值。`Default` trait 是一种约定，它用于为类型创建一个 "默认" 值。 这里给出一个例子展示如何在 Rust 中实现默认值：

```rust
#[derive(Debug, Default)]
struct User {
    name: String,
    age: u8,
    email: Option<String>,
}
fn main() {
    let user1: User = Default::default();
    println!("{:?}", user1);
}
```

`Default::default()` 会对每个字段调用 `default`，对于内建类型，如 `String`, `u8` 和 `Option<T>` 等，Rust 已经帮你实现了 `Default` trait。 对于`String`类型，`default()`返回空字符串，对于 `u8`，返回 `0`，对于 `Option<T>` 返回 `None`。 如果你想要为自定义类型提供默认值，你可以自行实现 `Default` trait：

```rust
use std::path::PathBuf;
#[derive(Debug)]
struct Config {
    output: PathBuf,
    //其他字段
}
impl Default for Config {
    fn default() -> Self {
        Self {
            output: PathBuf::from("./"),
            //其他字段的默认值实现
        }
    }
}
```

这种方式能非常方便地为字段设置默认值，实现以后就可以使用`unwrap_or_default()`来取得默认值，并且可以根据实际的业务需求灵活定制。

#### 方法的默认值

在 Rust 中，函数参数不能像某些语言（如 Python）那样直接设定默认值。然而，可以通过一些其他方式达到类似的目的。 一种常用的策略是使用 `Option<T>` 来处理可能的默认参数，然后在函数体内提供默认值。例如：

```rust
fn say_hello(name: Option<&str>) {
    let name = name.unwrap_or("World");
    println!("Hello, {}!", name);
}
fn main() {
    say_hello(None);                 // Prints: Hello, World!
    say_hello(Some("BackendCoderAssist")); // Prints: Hello, BackendCoderAssist!
}
```

在 `say_hello` 函数中，我们接受一个 `Option<&str>` 参数，如果调用者没有提供值（即 `None`），我们就使用 "World" 作为默认值。 然而，这种方式当参数多时，调用这类带多个Option参数的函数可能会有点繁琐。另外一种方法是使用 Builder Pattern 或者使用更复杂的方法如别的 crate 提供方法（例如 `getopts` 或 `structopt`），这在处理复杂命令行参数或者构造函数时会很有用。

### pub(crate)和pub

在 Rust 中，使用 `pub(crate)` 关键字组合为函数或类型设置可见性修饰符，意味着这些项将仅在当前的 crate（包）内可见。这是 Rust 模块系统的一部分，用于控制函数、结构体、枚举等项的范围和封装性。

如果你从函数前面的声明中去掉 `pub(crate)` 这部分，那么默认情况下这个函数将变为私有函数，只能在当前模块中使用。如果你希望函数在 crate 外也可见，你应当使用 `pub` 关键字。

这是一个概括的修饰符可见性：

- `pub(crate)`: 函数或项对当前 crate 是公共的，但对外部 crate 是私有的。
- `pub`: 函数或项是完全公开的，可在 crate 外部访问。
- 没有任何修饰符: 默认为私有，只能在定义它们的模块或子模块中使用。

### Cargo使用github仓库依赖

在cargo.toml中的一个示例如下：

```toml
[dependencies]
systeminfo = { git = "https://github.com/marirs/systeminfo-rs", branch = "main" }
```

###  原生字符串 `r""`和`r##""##`的异同

在Rust中,`r""`和`r##""##`都是原生字符串字面量(raw string literals)。它们的主要区别是:

- `r""`是一个普通的原生字符串字面量,里面的内容会原封不动地作为字符串。
- `r##""##`是一个可嵌套的原生字符串字面量,可以包含未转义的引号`"`。

普通的原生字符串字面量`r""`:

```rust
let s = r"Hello, world!";
```

可嵌套的原生字符串字面量`r##""##`:

```rust
let s = r##"Hello, "world"!"##;
```

`r##""##`允许字符串内部包含未转义的引号,这在需要编写包含引号的字符串时很有用。

它们的共同点是都不对字符串内容进行转义处理。不同的是`r##""##`支持嵌套未转义的引号。

### 范围表达式中`..=`和`..`的区别

在Rust中,`..=`和`..`都是范围表达式,用于生成一个迭代器来遍历指定范围内的数值。

主要区别在于:

- `..=`表示一个闭区间,包含范围的起始和结束值。
- `..`表示一个开区间,包含范围的起始值但不包含结束值。

 CancellationTokenSource cts = new CancellationTokenSource();CancellationToken token = cts.Token;​Parallel.ForEach(list, new ParallelOptions { CancellationToken = token }, item =>{    // do something});c#

```rust
let a = 1..=3; 
// a iterates over 1, 2, 3

let b = 1..3;
// b iterates over 1, 2
```

`..=`常用于`for`循环中遍历一个闭区间:

```rust
for i in 1..=10 {
  println!("{}", i); 
} 
// prints 1 2 3 ... 10
```

而`..`用于需要跳过结束值的情况:

```rust
let arr = [1, 2, 3];

for i in 0..arr.len() {
  println!("{}", arr[i]);
}
// prints 1 2
```



也就是,`..=`包含结束值,`..`不包含结束值。选择哪个取决于迭代需求。

### `self`和`Self`

在 Rust 中，`self` 和 `Self` 是两个有特殊意义的关键词，但是它们的用途和含义是不同的。
1. `self`：它通常是指当前实例对象的一个引用，并且是方法的第一个参数的隐式别名。`self` 可以采取以下三种形式：
   - `self`：这代表当前对象的所有权。当你在方法中使用 `self` 时，你将获取调用对象的所有权，这通常意味着此后原始对象将不能再使用，除非该方法返回了所有权。
   - `&self`：这是对当前对象的不可变引用。当你想在方法内部读取数据但不修改它时使用。
   - `&mut self`：这是对当前对象的可变引用。当你想修改调用对象的数据时使用。
2. `Self`：它指当前实现了方法的类型。你通常在定义 trait 或实现（impl 块）时遇到 `Self`。当你在这些上下文中使用 `Self` 时，它代表实现 trait 或者类型定义的具体类型。例如，在某个结构体 `MyStruct` 的 impl 块中，`Self` 就代表了 `MyStruct`。
简单来说，`self` 是指当前对象的实例，而 `Self` 是指当前实现方法的类型。这两者都是为了在 Rust 中的方法定义和实现中提供一种简洁的方式来引用调用者或它的类型。

### 闭包和函数的差异

在Rust中,闭包和函数有以下几点主要区别:

1. 闭包可以捕获环境中的变量,函数不能。

```rust
fn main() {
  let x = 10;

  let closure = || println!("{}", x); // 闭包捕获了x

  fn function() {
    println!("{}", x); // 函数不能捕获x
  }
}
```

1. 闭包的类型是不确定的,函数的类型是固定的。

```rust
fn foo(x: i32) -> i32 {
  x + 1 
} // foo的类型是 fn(i32) -> i32

let closure = |x| x + 1; // closure的类型是不确定的
```

1. 闭包可以通过Fn/FnMut/FnOnce trait来实现调用,函数必须通过名称来调用。

```rust
let closure = |x| println!("{}", x);
closure(1); // 通过Fn trait调用

fn foo(x: i32) {
  println!("{}", x)  
}
foo(1); // 必须通过名称foo来调用
```

1. 闭包是在运行时捕获环境的,函数在编译时就确定了作用域。
2. 闭包一般用于回调或高阶函数参数,函数用于通用逻辑封装。

所以总结来说,闭包更灵活,适合需要保存状态或环境的场景;函数更结构化,适合封装通用逻辑。

### 常见的模式匹配用法
#### `match`语句

一般可以使用`match` 语句来根据值的不同情况执行不同的代码块。以下是 `match` 的基本用法示例：

```rust
rustCopy codefn main() {
    let number = 5;

    match number {
        1 => println!("One"),
        2 => println!("Two"),
        3 | 4 => println!("Three or Four"),  // Matching multiple values
        5..=10 => println!("Five to Ten"),  // Matching a range
        _ => println!("Other"),              // Default case
    }
}
```

在这个例子中，`match` 语句匹配变量 `number` 的值，根据不同的情况执行不同的代码块。下面是各个模式的解释：

- `1 => println!("One")`: 如果 `number` 的值为 1，执行这个代码块。
- `2 => println!("Two")`: 如果 `number` 的值为 2，执行这个代码块。
- `3 | 4 => println!("Three or Four")`: 如果 `number` 的值为 3 或 4，执行这个代码块。
- `5..=10 => println!("Five to Ten")`: 如果 `number` 的值在 5 到 10 的范围内（包括5和10），执行这个代码块。
- `_ => println!("Other")`: 对于所有其他情况，执行这个代码块（通配符 `_` 表示匹配任何值）。

你还可以在 `match` 中使用模式匹配结构体、枚举、引用等。下面是一个匹配结构体的示例：

```rust
rustCopy codestruct Point {
    x: i32,
    y: i32,
}

fn main() {
    let point = Point { x: 1, y: 2 };

    match point {
        Point { x: 0, y: 0 } => println!("Origin"),
        Point { x, y } => println!("Non-origin point at ({}, {})", x, y),
    }
}
```

在这个例子中，`match` 语句根据结构体 `Point` 的不同情况执行不同的代码块。除了match，你可能还会遇到`matches!`。在 Rust 中，`matches!` 是一个宏，用于快速检查一个值是否匹配给定的模式。与 `match` 表达式不同，`matches!` 宏用于产生一个布尔值，表示模式是否匹配，而不是用来执行匹配后的代码分支。这在条件表达式或断言中非常有用。

下面是使用 `matches!` 宏的一个简单例子：

```rust
enum TrafficLight {
    Red,
    Yellow,
    Green,
}

fn main() {
    let light = TrafficLight::Red;

    let is_red = matches!(light, TrafficLight::Red);
    println!("Is light red? {}", is_red); // 输出: Is light red? true

    let is_yellow = matches!(light, TrafficLight::Yellow);
    println!("Is light yellow? {}", is_yellow); // 输出: Is light yellow? false

    // 对于带有数据的枚举变体，也可以使用 matches! 进行匹配
    let number = Some(5);

    let is_bigger_than_seven = matches!(number, Some(x) if x >7 );
    println!("Is number bigger than seven? {}", is_seven); // 输出: Is number seven? false
}
```

在这个例子中，我们定义了一个 `TrafficLight` 枚举，我们通过 `matches!` 宏去检查变量 `light` 是否是 `TrafficLight::Red` 或 `TrafficLight::Yellow`。该宏返回一个布尔值，该值表明是否匹配成功，我们再将其打印出来。

同时，在 `number` 变量的匹配中，`matches!` 还可以用于带数据的枚举变体，这里我们检查 `Some(7)` 是否包含的是数字7。

#### `if let` 示例：

```rust
rustCopy codestruct Person {
    name: Option<String>,
    age: Option<u32>,
}

fn main() {
    let person = Person {
        name: Some(String::from("Alice")),
        age: Some(30),
    };

    // 使用 if let 处理 Option 中的某个特定模式
    if let Some(name) = person.name {
        println!("Name: {}", name);
    } else {
        println!("No name available");
    }
}
```

在这个例子中，`if let` 用于匹配 `person.name` 是否包含值，如果是，将值绑定给 `name` 并执行相应的代码块。

#### `while let` 示例：

```rust
rustCopy codefn main() {
    let mut stack = Vec::new();
    stack.push(Some(42));
    stack.push(Some(23));
    stack.push(None);

    // 使用 while let 处理迭代过程中的某个特定模式
    while let Some(value) = stack.pop() {
        if let Some(inner_value) = value {
            println!("Popped value: {}", inner_value);
        } else {
            println!("Encountered None");
        }
    }
}
```

在这个例子中，`while let` 用于迭代 `stack` 同时检查是否存在值，如果存在，将值绑定给 `value` 并执行相应的代码块。

#### **for 循环**

可以在 for 循环中使用模式来解构元组、结构体和枚举。

```rust
let pairs = vec![(1, 'a'), (2, 'b'), (3, 'c')];
for (num, letter) in pairs {
    println!("{}: {}", num, letter);
}
```

#### **忽略模式**

有时你可能不关心某个值或某些值，可以使用 `_` 或 `..` 来忽略它们。

```rust
match some_value {
    Value::A { x, .. } => println!("x is {}", x),
    _ => (),
}
```

#### `ref`关键字

在Rust中，模式匹配通常会涉及所有权的转移。但是，如果你想避免转移所有权，可以使用引用或者`ref`关键字。下面是一个示例，展示了如何在模式匹配中避免所有权的转移：

```rust
rustCopy codestruct Person {
    name: String,
    age: u32,
    city: String,
}

fn main() {
    let person = Person {
        name: String::from("Alice"),
        age: 30,
        city: String::from("Wonderland"),
    };

    // 使用引用来避免所有权的转移
    match &person {
        // 使用引用解构结构体
        &Person { ref name, age, ref city } => {
            // 注意：name 和 city 现在是引用，不会转移所有权
            println!("Name: {}, Age: {}, City: {}", name, age, city);
        }
    }

    // 在这里可以继续使用 person，因为它并没有被移动
    println!("Person is still accessible: {:?}", person);
}
```

在这个例子中，使用`&`来创建结构体`Person`的引用，然后使用`ref`来创建对`name`和`city`的引用，从而避免了对这些字段的所有权转移。这允许你在`match`块内使用这些字段，而在匹配之后仍然可以继续使用`person`，因为它的所有权并没有被转移。

#### **@ 绑定**

允许你在测试一个值的模式的同时创建一个变量来保存这个值。

```rust
enum Message {
    ChangeColor(i32, i32, i32),
}
let msg = Message::ChangeColor(0, 160, 255);
match msg {
    Message::ChangeColor(r, g, b) => println!("Change color to: {}, {}, {}", r, g, b),
}
match msg {
    Message::ChangeColor(r @ 0..=255, g @ 0..=255, b @ 0..=255) => {
        println!("Change color to RGB ({}, {}, {})", r, g, b)
    }
    _ => ()
}
```

#### 元组解构

在Rust中，你可以在函数参数中使用模式匹配来解构元组。以下是一个简单的示例，演示了如何在函数中使用模式匹配处理元组：

```rust
rustCopy code// 函数接收一个包含多个值的元组作为参数，并使用模式匹配解构元组
fn process_person_info(person: (String, u32, String)) {
    match person {
        // 使用模式匹配解构元组
        (name, age, city) => {
            println!("Name: {}, Age: {}, City: {}", name, age, city);
        }
    }
}

fn main() {
    // 创建包含多个值的元组
    let person_info = ("Alice".to_string(), 30, "Wonderland".to_string());

    // 调用函数并传递元组作为参数
    process_person_info(person_info);
}
```

在这个例子中，`process_person_info` 函数接收一个包含多个值的元组作为参数，并使用 `match` 语句进行模式匹配。模式 `(name, age, city)` 将元组的各个元素解构并绑定到相应的变量，然后你可以在 `match` 的代码块中使用这些变量。

如果你不关心元组的所有元素，也可以使用通配符 `_`：

```rust
rustCopy codefn process_person_info(person: (String, u32, String)) {
    match person {
        (_, age, _) => {
            println!("Age: {}", age);
        }
    }
}
```

这样，只有 `age` 被解构并使用，而其他的元素被忽略。

### 日志

在 Rust 中正确使用日志记录的方法是使用 log crate，这是 Rust 生态系统中的一个通用日志记录接口，它允许库作者输出日志信息，而无需考虑最终用户选择的日志记录框架。

要在 Rust 项目中使用 log crate 进行日志记录，请按照以下步骤操作：

#### 添加依赖项

在你的 Cargo.toml 文件中添加 log crate 作为依赖项：
```toml
[dependencies]
log = "0.4"
```

这里 "0.4" 表示 log crate 的版本号，请使用最新的版本号。

#### 选择日志后端

除了 log crate 外，你还需要一个具体的日志后端（如 env_logger）来实现实际的日志记录功能。添加后端如下：
```toml
env_logger = "0.9"
```
#### 初始化日志后端

在程序的入口点（如 main 函数）初始化日志后端：
```rust
fn main() {
    env_logger::init();
    // ... 你的程序逻辑
}
```
#### 记录日志

使用 log crate 提供的宏（error!, warn!, info!, debug!, trace!）来记录日志：

```rust
use log::{info, warn, error, debug, trace};

fn main() {
    env_logger::builder().filter_level(log::LevelFilter::Trace).init();
    info!("Hello, world!");
    warn!("This is a warning");
    error!("This is an error");
    debug!("This is a debug message");
    trace!("This is a trace message {:?}","sss")
}
```

#### 运行程序

运行你的程序时，你可以通过设置环境变量 RUST_LOG 来控制日志的详细程度。例如，使用以下命令运行程序：

```bash
RUST_LOG=info cargo run
```
这会显示所有的 “info” 级别和更高级别（如 “warn” 和 “error”）的日志。
请注意，以上步骤是一个基础的入门指南。在生产环境中，你可能需要对日志记录进行更复杂的配置，包括日志格式的定制、记录到文件、集成错误报告服务等。但出于功能演示的目的，env_logger 是一个简单且常见的选择。记得阅读你选择的日志后端的文档，以了解所有可用的配置选项。

## 进阶

### type state

在 Rust 中，Type State 设计模式是一种编码风格，它充分利用 Rust 的强类型系统来编码和保证特定的状态和行为，从而在编译时期而不是运行时对状态进行检查。这种模式通过类型变化来表示对象的状态转换，确保了对象的方法调用总是在合适的状态下发生。

#### 问题解决

Type State 模式主要解决了跟对象状态相关的安全性和正确性问题，例如：

- 保证在对资源执行操作之前，资源已经被正确地初始化。
- 防止在对象不在某个特定状态时调用某些方法。
- 在不同的状态下，为同一对象提供不同的方法集合。

这些通常需要在运行时通过逻辑判断来实现，但 Type State 模式允许在编译时就强制这些约束，这减少了运行时错误的可能性，并提高了代码的稳定性。

#### Type State 模式的特征

- **状态作为类型**：每个状态都有一个对应的 Rust 类型，这样状态的改变实际上就是类型的变化。
- **归属权和生命周期**：结合 Rust 的归属权和生命周期特性，可以在类型转换时传递或借用资源，保证在任何时间点资源都不会被不合规地访问或释放。
- **零成本抽象**：由于状态的转换和检查都发生在编译时，运行时没有额外的开销。

#### 一个简单的例子

下面是一个简化的 Type State 设计模式的例子，它展示了如何使用此模式来编码一个只能顺序初始化、启动和停止的服务：

```rust
struct Service;

struct InitializedService(Service);
struct StartedService(InitializedService);

// Service 本身没有任何方法
impl Service {
    fn new() -> Service {
        Service
    }
}

// 只有 InitializedService 才有 start 方法
impl InitializedService {
    fn start(self) -> StartedService {
        StartedService(self)
    }
}

// 只有 StartedService 才有 stop 方法
impl StartedService {
    fn stop(self) -> Service {
        self.0 .0
    }
}

fn main() {
    let service = Service::new(); // 创建服务
    let init_service = InitializedService(service); // 初始化服务
    let started_service = init_service.start(); // 启动服务
    let service = started_service.stop(); // 停止服务
}
```

在这个例子中，原始的 `Service` 类型没有任何行为。一旦它转换为 `InitializedService`，就可以调用 `start` 方法，然后它又转换为 `StartedService`，在这个状态下可以调用 `stop` 方法。

#### 结论

Type State 模式通过编译时检查来确保代码的安全性和正确性，它可以在各种场景下帮助我们避免运行时错误，特别是在需要精确管理对象状态生命周期的系统和资源约束性强的应用程序中。它是 Rust 类型系统提供的显著优势之一，允许开发者将更多的逻辑和保证编码为类型本身。

#### 附加阅读

+ [How To Use The Typestate Pattern In Rust](https://zerotomastery.io/blog/rust-typestate-patterns/)
+ [Type-Driven API Design in Rust](https://willcrichton.net/rust-api-type-patterns/typestate.html)
+ [Typestates in Rust](https://yoric.github.io/post/rust-typestate/)

### GAT

在 Rust 中，GAT 指的是“泛型关联类型”（Generic Associated Types）。这是 Rust 类型系统的一个高级特性，随 Rust 2021 版本稳定化。GAT 允许在 trait 中定义的关联类型拥有自己的泛型参数。这解决了 Rust 在表示某些类型关系时的限制，特别是在涉及到生命周期和泛型时，为 Rust 的类型系统提供了更高的灵活性和表达能力。

#### 解决的问题

在 GAT 出现之前，Rust 的 trait 无法在其关联类型上指定泛型参数。这限制了一些模式的表达，特别是在涉及到异步编程和迭代器模式时。举个例子，考虑以下试图定义一个异步迭代器 trait 的尝试：

```rust
trait AsyncIterator {
    type Item;
    async fn next(&mut self) -> Option<Self::Item>;
}
```

在这个例子中，`next` 方法是异步的，返回一个 `Future`。但在 Rust 没有 GAT 支持的时候，我们无法直接在 trait 中表达这种方法签名，因为关联类型 `Item` 不可以携带自己的生命周期或泛型参数。

#### GAT 的使用

GAT 的引入允许我们在关联类型上使用泛型参数，这意味着我们现在可以这样定义上述的 `AsyncIterator` trait：

```rust
trait AsyncIterator {
    type Item<'a>;
    async fn next<'a>(&'a mut self) -> Option<Self::Item<'a>>;
}
```

通过使用 GAT，`Item` 关联类型现在可以接受一个生命周期 `'a` 作为参数，使其能够适应异步和生命周期的需求。

#### GAT 的优势

GAT 引入了更多的灵活性，允许开发者以更自然的方式定义复杂的类型关系，从而在 Rust 中实现更高级的抽象模式。它特别适用于那些需要关联类型依赖特定生命周期或其他类型参数的场景。GAT 使得 Rust 的类型系统更加强大和灵活，提升了 Rust 编程中的表达能力。

#### 结论

GAT 是 Rust 语言中一个强大的特性，它解决了在泛型和生命周期应用上的限制问题，为 Rust 开发者提供了一种在 trait 定义中应用复杂类型关系的方法。通过允许关联类型拥有自己的泛型参数，GAT 为 Rust 编程带来了新的可能性，尤其是在构建高层次的类型抽象和复杂 API 设计时。

### 宏和元编程

#### 声明宏

`macro_rules! `是 Rust 中定义宏的一种方式。这种宏称为 "声明宏"（declarative macros），它允许你编写模式匹配规则，它们指定如何根据宏的参数替换代码。宏定义看起来像这样：

```rust
macro_rules! macro_name {
    // pattern => expansion
    (pattern) => (expansion);
    // 你可以有多个模式/展开规则
}
```

你可以按照以下步骤来使用 macro_rules! 定义和使用宏：
定义宏： 你需要使用 macro_rules! 开始宏定义，后面跟上宏的名称：

```rust
macro_rules! say_hello {
    // patterns
}
```

创建模式和展开规则： 在大括号中，写下一个或多个模式和对应的展开代码。这决定了你的宏如何响应不同的输入：
```rust
// 宏接收一个表达式作为参数，并打印出 "Hello, …!"
($name:expr) => {
    println!("Hello, {}!", $name);
};
```

宏调用： 这样，宏就定义好了，你可以在代码的任何地方调用它，就像这样：
```rust
say_hello!("World");
// 每个宏调用都会被宏定义中的展开规则所替换。
```

它将展开为：
```rust
println!("Hello, World!");
```

这是一个完整的简单宏的例子：
```rust
macro_rules! say_hello {
    ($name:expr) => {
        println!("Hello, {}!", $name);
    };
}
fn main() {
    // 宏调用
    say_hello!("World");
}
```

运行这个程序，输出会是 "Hello, World!"。这就是 macro_rules! 宏在 Rust 中的基本用法。你可以定义更复杂的模式和展开，包括重复模式、匹配不同类型的输入等，这样的宏非常灵活而强大。 

#### 过程宏

Rust 元编程主要是通过它的宏系统实现的。Rust 宏系统中的 "过程宏" (procedural macros) 是一种功能强大的工具，允许你在编译时生成，修改或消费 Rust 代码。过程宏通常用于自动生成代码（例如，实现特定特征/trait），从而减少重复代码，或者是根据标记/注解 (annotations) 以特定的方式扩展代码。
在 Rust 中，过程宏可以被分为三种：

+ 派生宏 (derive macros)：自动为结构体和枚举实现特定的 trait。

+ 属性宏 (attribute macros)：将宏绑定到结构体、函数或模块上，以添加新的功能或提供编译时指令。

+ 函数宏 (function-like macros)：看似调用函数一样的宏，但在调用点扩展为一些代码。

darling, syn 和 quote 是三个常用的库，用于创建过程宏：

- syn：用于解析 Rust 代码成为一个可操作的语法树（抽象语法树，AST）。这样你就可以分析和处理 Rust 源代码中的结构和表达式。     
- quote：用于将 Rust 代码的语法树转换回 Rust 代码。它提供了一种方式，可以很方便的写 Rust 代码的 "引用"，然后扩展为实际的代码片段。
- darling：这是一个用于解析宏输入的库，建立在 syn 之上，提供了更加方便的 API 来处理宏属性和数据。

现在让我们来看一个基本的例子，用这些库来展示如何实现一个简单的派生宏：
```rust
extern crate proc_macro;
use proc_macro::TokenStream;
use quote::quote;
use syn::{parse_macro_input, DeriveInput};
#[proc_macro_derive(MyTrait)]
pub fn my_trait_derive(input: TokenStream) -> TokenStream {
    // 使用 syn 解析 TokenStream 成为一个数据结构。
    let ast = parse_macro_input!(input as DeriveInput);
    // 获取我们要实现的 trait 的结构体或枚举的名字。
    let name = &ast.ident;
    // 使用 quote 来构建输出的 TokenStream。
    let expanded = quote! {
        // 这里生成 Rust 代码，此例子中为目标类型实现一个 MyTrait。
        impl MyTrait for #name {
            fn my_function(&self) -> String {
                String::from(concat!("MyTrait is implemented for ", stringify!(#name)))
            }
        }
    };
    // 将生成的代码转换为 TokenStream 发送给编译器。
    TokenStream::from(expanded)
}
```

这个宏当被添加到一个结构体或枚举上时，会自动为其实现 MyTrait，提供一个叫做 my_function 的方法。
请注意，这里使用的是非常简单的例子来演示过程宏的基本概念。实际应用中，你可能需要解析宏的输入来获取更详细的信息，如字段类型、传递的参数等，并且可能要处理各种错误情况。darling 可以提供辅助功能，简化这个处理过程。

下面这个例子展示了使用 `syn` 库来解析 Rust 代码。以下是一个基本的示例：

```rust
extern crate proc_macro;
use proc_macro::TokenStream;
use syn::{parse_macro_input, DeriveInput};
#[proc_macro_derive(MyDerive)]
pub fn my_derive(input: TokenStream) -> TokenStream {
   // 将传入的 TokenStream 转化为 Rust AST。
    let ast = parse_macro_input!(input as DeriveInput);
    // 现在你可以访问 AST 中的所有信息
    // 例如，我们可以获取正在派生的结构体的名字
    let struct_name = ast.ident;
    // ...在这里根据 struct_name 和其他 AST 组件做进一步的处理...
    // 接下来你将使用 quote 生成代码并返回 TokenStream
    TokenStream::new()
}
```

在这段代码中，`parse_macro_input!` 宏接收一个 `TokenStream` 并使用 `syn` 的解析器将其转化为 `DeriveInput` 结构。`DeriveInput` 是 `syn` 提供的一个 AST 节点，它代表正在被派生的结构体、枚举或联合体。一旦你有了 AST 的 `DeriveInput` 结构，你就可以使用它来访问结构体的名字、字段、属性、泛型参数等。 例如，如果你想要检查所有的字段并打印它们的名字，你可以这样做：

```rust
if let syn::Data::Struct(ref data_struct) = ast.data {
    for field in data_struct.fields.iter() {
        if let Some(ident) = &field.ident {
            println!("Field name: {}", ident);
        }
    }
}
```

在操作完 AST 后，接着使用 `quote` 衍生宏生成所需的代码。

### 异步和多线程

#### 多线程

todo

#### 异步

todo

### 生命周期

### FFI

#### **[`bindgen`](https://github.com/rust-lang/rust-bindgen)**

**自动生成与 C 和 C++ 库的 Rust FFI 绑定。**

例如，给定 C 标头 `cool.h` ：

```c
typedef struct CoolStruct {
    int x;
    int y;
} CoolStruct;

void cool_function(int i, char c, CoolStruct* cs);
```

`bindgen` 生成 Rust FFI 代码，允许您调用 `cool` 库的函数并使用其类型：

```rust
/* automatically generated by rust-bindgen 0.99.9 */

#[repr(C)]
pub struct CoolStruct {
    pub x: ::std::os::raw::c_int,
    pub y: ::std::os::raw::c_int,
}

extern "C" {
    pub fn cool_function(i: ::std::os::raw::c_int,
                         c: ::std::os::raw::c_char,
                         cs: *mut CoolStruct);
}
```

#### CXX 

仓库地址  https://github.com/dtolnay/cxx

该库提供了一种安全机制，用于从 Rust 调用 C++ 代码和从 C++ 调用 Rust 代码，不受使用 bindgen 或 cbindgen 生成不安全的 C 样式绑定时可能出错的多种方式的影响。



#### 其他

https://hacks.mozilla.org/2019/04/crossing-the-rust-ffi-frontier-with-protocol-buffers/
