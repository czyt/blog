---
title: "跟AI学习Rust"
date: 2024-02-16
tags: ["rust"]
draft: false
---

> 本文为学习rust过程中，向ai提问的内容汇总。配套图书为《Rust程序设计 第2版》

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

例如:

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

在这个例子中，`match` 语句根据结构体 `Point` 的不同情况执行不同的代码块。

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

## 进阶

### 宏

### 生命周期

