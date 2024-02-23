---
title: "Rust完整备忘单【译】"
date: 2024-02-23
tags: ["rust"]
draft: false
---

>原文 https://katib.moe/the-completesh-rust-cheat-sheet 本文大部分通过机器翻译进行翻译，小部分进行了微调。

这个“完整的 Rust 备忘单”提供了 Rust 编程语言的全面指南，涵盖了它的所有主要功能。涵盖的主题范围从非常基础的知识（例如语法和基本概念）到更复杂的方面（例如并发和错误处理）。该备忘单还深入研究了 Rust 的独特功能，例如所有权、借用和生命周期，以及其强大的类型系统和健壮的宏系统。对于每个主题，都提供了清晰的示例来阐明解释。对于刚刚开始使用 Rust 的初学者和想要快速回顾特定 Rust 概念的经验丰富的开发人员来说，这是一个理想的资源。

我编写了这份备忘单作为 Rust 编程语言的综合指南，旨在将其作为个人参考工具。然而，Rust 社区的美妙之处在于共享学习和协作。因此，如果您发现我遗漏的内容、错误，或者您有改进建议，请随时分享您的反馈。请记住，没有人是绝对正确的，本资源也不例外 - 通过您的见解，我们可以继续改进和完善它。快乐 Rustacean！

#  基本语法和概念

1.  **你好世界**

   这是标准的“你好，世界！” Rust 中的程序。

   ```rust
    fn main() {
        println!("Hello, world!");
    }
   ```

2.  **变量和可变性**

   Rust 中的变量默认是不可变的。要使变量可变，请使用 `mut` 关键字。

   ```rust
    let x = 5; // immutable variable
    let mut y = 5; // mutable variable
    y = 6; // this is okay
   ```

3.  **数据类型**

   Rust 是一种静态类型语言，这意味着它必须在编译时知道所有变量的类型。

   ```rust
    let x: i32 = 5; // integer type
    let y: f64 = 3.14; // floating-point type
    let z: bool = true; // boolean type
    let s: &str = "Hello"; // string slice type
   ```

4.  **控制流**

   Rust 的控制流关键字包括 `if` 、 `else` 、 `while` 、 `for` 和 `match` 。

   ```rust
    if x < y {
        println!("x is less than y");
    } else if x > y {
        println!("x is greater than y");
    } else {
        println!("x is equal to y");
    }
   ```

5.  **功能**

   Rust 中的函数是用 `fn` 关键字定义的。

   ```rust
    fn greet() {
        println!("Hello, world!");
    }
   ```

6.  **结构体**

   结构体用于在 Rust 中创建复杂的数据类型。

   ```rust
    struct Point {
        x: i32,
        y: i32,
    }
    let p = Point { x: 0, y: 0 }; // instantiate a Point struct
   ```

7.  **枚举**

   Rust 中的枚举是可以有多种不同变体的类型。

   ```rust
    enum Direction {
        Up,
        Down,
        Left,
        Right,
    }
    let d = Direction::Up; // use a variant of the Direction enum
   ```

8.  **模式匹配**

   Rust 具有强大的模式匹配功能，通常与 `match` 关键字一起使用。

   ```rust
    match d {
        Direction::Up => println!("We're heading up!"),
        Direction::Down => println!("We're going down!"),
        Direction::Left => println!("Turning left!"),
        Direction::Right => println!("Turning right!"),
    }
   ```

9.  **错误处理**

   Rust 使用 `Result` 和 `Option` 类型进行错误处理。

   ```rust
    let result: Result<i32, &str> = Ok(42); // a successful result
    let option: Option<i32> = Some(42); // an optional value
   ```

这只是 Rust 语法和概念的初步体验。当您继续学习时，该语言还有更多功能需要探索。

#  变量和数据类型

Rust 是一种静态类型语言，这意味着它必须在编译时知道所有变量的类型。编译器通常可以根据值以及我们如何使用它来推断我们想要使用什么类型。

##  变量

默认情况下，Rust 中的变量是不可变的，这意味着它们的值在声明后就无法更改。如果您希望变量可变，可以使用 `mut` 关键字。

###  不可变变量：

```rust
let x = 5;
```

###  可变变量：

```rust
let mut y = 5;
y = 6;  // This is allowed because y is mutable
```

##  数据类型

Rust 语言内置了多种数据类型，可分为：

- 标量类型：表示单个值。例如整数、浮点数、布尔值和字符。
- 复合类型：将多个值分组为一种类型。例如元组和数组。

 **标量类型**

###  整数：

```rust
let a: i32 = 5;  // i32 is the type for a 32-bit integer
```

###  浮点数：

```rust
let b: f64 = 3.14;  // f64 is the type for a 64-bit floating point number
```

###  布尔值：

```rust
let c: bool = true;  // bool is the type for a boolean
```

###  char：

```rust
let d: char = 'R';  // char is the type for a character. Note that it's declared using single quotes
```

###  **复合类型**

###  元组：

```rust
let e: (i32, f64, char) = (500, 6.4, 'J');  // A tuple with three elements
```

###  数组：

```rust
let f: [i32; 5] = [1, 2, 3, 4, 5];  // An array of i32s with 5 elements
```

这些是 Rust 中一些最基本的数据类型和变量声明。随着您继续学习，您将遇到更复杂的类型并学习如何创建自己的类型。

##  高级数据类型

###  结构体

结构体允许您创建自定义数据类型。它们是一种从简单类型创建复杂类型的方法。

 定义一个结构体：

```rust
struct User {
    username: String,
    email: String,
    sign_in_count: u64,
    active: bool,
}
```

创建结构体的实例：

```rust
let user1 = User {
    email: String::from("someone@example.com"),
    username: String::from("someusername123"),
    active: true,
    sign_in_count: 1,
};
```

###  **枚举**

枚举是枚举的缩写，是一种表示数据的类型，该数据是几种可能的变体之一。枚举中的每个变体都可以选择具有与其关联的数据。

 定义一个枚举：

```rust
enum IpAddrKind {
    V4,
    V6,
}
```

创建枚举的实例：

```rust
let four = IpAddrKind::V4;
let six = IpAddrKind::V6;
```

###  Option

Option 枚举是 Rust 作为其标准库的一部分提供的特殊枚举。当值可以是某物或什么都不是时使用它。

```rust
let some_number = Some(5);
let some_string = Some("a string");
let absent_number: Option<i32> = None;  // Note that we need to provide the type of None here
```

###  Result

Result 枚举是标准库中的另一个特殊枚举，主要用于错误处理。它有两个变体，Ok（成功）和 Err（错误）。

```rust
enum Result<T, E> {
    Ok(T),
    Err(E),
}
```

这些是 Rust 中的一些更高级的数据类型。理解这些概念将使您能够编写更健壮、更灵活的 Rust 程序。

##  标准系列

集合是保存多个值的数据结构。 Rust 的标准库包括几个通用集合： `Vec<T>` 、 `HashMap<K, V>` 和 `HashSet<T>` 。

###  Vector

Vector，或 `Vec<T>` ，是 Rust 标准库提供的可调整大小的数组类型。它允许您在单个数据结构中存储多个值，该数据结构将所有值在内存中彼此相邻。

创建一个向量并向其中添加元素：

```rust
let mut v: Vec<i32> = Vec::new();  // creates an empty vector of i32s
v.push(5);
v.push(6);
v.push(7);
v.push(8);
```

###  HashMap

HashMap，即 `HashMap<K, V>` ，是键值对的集合，类似于其他语言中的字典。它允许您将数据存储为一系列键值对，其中每个键必须是唯一的。

创建 HashMap 并向其中添加元素：

```rust
use std::collections::HashMap;

let mut scores = HashMap::new();
scores.insert(String::from("Blue"), 10);
scores.insert(String::from("Yellow"), 50);
```

###  HashSet

HashSet 或 `HashSet<T>` 是唯一元素的集合。它被实现为一个哈希表，其中每个键的值都是无意义的 ()，因为我们唯一关心的值是键。

创建一个 HashSet 并向其中添加元素：

```rust
use std::collections::HashSet;

let mut hs = HashSet::new();
hs.insert("a");
hs.insert("b");
```

这些是 Rust 中的一些主要集合类型。它们中的每一个都非常有用，具体取决于您想要在程序中实现的目标。

###  BTreeMap

`BTreeMap` 是按其键排序的映射。它允许您按需获取一系列条目，当您对最小或最大的键值对感兴趣，或者您想要查找小于或大于某个值的最大或最小键时，这非常有用。

```rust
use std::collections::BTreeMap;

let mut btree_map = BTreeMap::new();
btree_map.insert(3, "c");
btree_map.insert(2, "b");
btree_map.insert(1, "a");

for (key, value) in &btree_map {
    println!("{}: {}", key, value);
}
```

在上面的示例中，尽管以不同的顺序插入，但打印时键仍按升序排序。

###  BTreeSet

`BTreeSet` 本质上是一个 `BTreeMap` ，您只想记住您见过的键，并且没有与您的键关联的有意义的值。当您只想要一套时，它很有用。

```rust
use std::collections::BTreeSet;

let mut btree_set = BTreeSet::new();
btree_set.insert("orange");
btree_set.insert("banana");
btree_set.insert("apple");

for fruit in &btree_set {
    println!("{}", fruit);
}
```

在上面的示例中，尽管以不同的顺序插入，但水果还是按字典顺序（即字母顺序）打印出来。

###  BinaryHeap

`BinaryHeap` 是一个优先级队列。它允许您存储一堆元素，但在任何给定时间只处理“最大”或“最重要”的元素。当您需要优先级队列时，此结构非常有用。

```rust
use std::collections::BinaryHeap;

let mut binary_heap = BinaryHeap::new();
binary_heap.push(1);
binary_heap.push(5);
binary_heap.push(2);

println!("{}", binary_heap.peek().unwrap());  // prints: 5
```

在上面的示例中，尽管以不同的顺序插入，“peek”操作仍检索堆中的最大数字。

#  控制流

Rust 提供了几种结构来控制程序中的执行流程，包括 `if` 、 `else` 、 `loop` 、 `while` 、 `for` 和 `match` 。

##  if else

`if` 关键字允许您根据条件分支代码。 `else` 和 `else if` 可用于替代条件。

```rust
let number = 7;

if number < 5 {
    println!("condition was true");
} else {
    println!("condition was false");
}
```

##  loop

`loop` 关键字为您提供无限循环。要停止循环，可以使用 `break` 关键字。

```rust
let mut counter = 0;

loop {
    counter += 1;

    if counter == 10 {
        break;
    }
}
```

## while

`while` 关键字可用于在条件为真时进行循环。

```rust
let mut number = 3;

while number != 0 {
    println!("{}!", number);

    number -= 1;
}
```

## for

`for` 关键字允许您循环遍历集合的元素。

```rust
let a = [10, 20, 30, 40, 50];

for element in a.iter() {
    println!("the value is: {}", element);
}
```

##  match

`match` 关键字允许您将值与一系列模式进行比较，然后根据模式匹配执行代码。

```rust
let value = 1;

match value {
    1 => println!("one"),
    2 => println!("two"),
    _ => println!("something else"),
}
```

这些控制流结构中的每一个都可用于控制 Rust 程序中的执行路径，使它们更加灵活和动态。

#  函数

函数是一个命名的语句序列，它接受一组输入、执行计算或操作，并可选择返回一个值。函数的输入称为参数，返回的输出称为返回值。

## 定义和调用函数

函数是用 `fn` 关键字定义的。函数的一般形式如下所示：

```rust
fn function_name(param1: Type1, param2: Type2, ...) -> ReturnType {
    // function body
}
```

下面是一个简单函数的示例，它接受两个整数并返回它们的和：

```rust
fn add_two_numbers(x: i32, y: i32) -> i32 {
    x + y  // no semicolon here, this is a return statement
}
```

以下是调用此函数的方式：

```rust
let sum = add_two_numbers(5, 6);
println!("The sum is: {}", sum);
```

## 函数参数

参数是一种将值传递给函数的方法。参数在函数定义中指定，当调用函数时，这些参数将包含传入的值。

这是带有参数的函数的示例：

```rust
fn print_sum(a: i32, b: i32) {
    let sum = a + b;
    println!("The sum of {} and {} is: {}", a, b, sum);
}
```

## 从函数返回值

函数可以返回值。在 Rust 中，函数的返回值与函数体块中最终表达式的值同义。您可以通过使用 `return` 关键字并指定一个值来提前从函数返回，但大多数函数都会隐式返回最后一个表达式。

这是一个返回布尔值的函数：

```rust
fn is_even(num: i32) -> bool {
    num % 2 == 0
}
```

在 Rust 中，函数为变量创建了一个新的作用域，这可能会导致诸如影子和所有权之类的概念，这些概念是 Rust 内存管理系统的关键方面。

#  错误处理

Rust 将错误分为两大类：可恢复错误和不可恢复错误。对于可恢复的错误，例如找不到文件错误，向用户报告问题并重试操作是合理的。不可恢复的错误始终是错误的症状，例如尝试访问超出数组末尾的位置。

Rust 也不例外。相反，它具有用于可恢复错误的类型 `Result<T, E>` 和当程序遇到不可恢复错误时停止执行的 `panic!` 宏。

这是使用 `Result` 的基本示例：

```rust
fn division(dividend: f64, divisor: f64) -> Result<f64, String> {
    if divisor == 0.0 {
        Err(String::from("Can't divide by zero"))
    } else {
        Ok(dividend / divisor)
    }
}
```

以下是处理 `Result` 的方法：

```rust
match division(4.0, 2.0) {
    Ok(result) => println!("The result is {}", result),
    Err(msg) => println!("Error: {}", msg),
}
```

然而，Rust 提供了 `?` 运算符，可以在返回 `Result` 的函数中使用，这使得错误处理更加简单：

```rust
fn main() -> Result<(), Box<dyn std::error::Error>> {
    let result = division(4.0, 0.0)?;
    println!("The result is {}", result);
    Ok(())
}
```

在上面的示例中，如果 `division` 函数返回 `Err` ，则 `main` 函数将返回错误。如果它返回 `Ok` ，则 `Ok` 内的值将被分配给 `result` 。除了 Rust 提供的标准错误类型之外，您还可以定义自己的错误类型。

```rust
enum MyError {
    Io(std::io::Error),
    Parse(std::num::ParseIntError),
}

impl From<std::io::Error> for MyError {
    fn from(err: std::io::Error) -> MyError {
        MyError::Io(err)
    }
}

impl From<std::num::ParseIntError> for MyError {
    fn from(err: std::num::ParseIntError) -> MyError {
        MyError::Parse(err)
    }
}
```

#  高级错误处理

对于更高级的错误处理，我们可以利用 `thiserror` 包来简化流程。 `thiserror` 箱自动执行了创建自定义错误类型并为其实现 `Error` trait的大部分过程。

首先，将 `thiserror` 添加到 `Cargo.toml` 依赖项中：

```toml
[dependencies]
thiserror = "1.0.40"
```

然后，您可以使用 `#[derive(thiserror::Error)]` 创建您自己的自定义错误类型：

```rust
use thiserror::Error;

#[derive(Error, Debug)]
pub enum MyError {
    #[error("I/O error: {0}")]
    Io(#[from] std::io::Error),
    #[error("Parse error: {0}")]
    Parse(#[from] std::num::ParseIntError),
    // Add other error variants here as needed
}
```

对于此错误类型，由于 `#[from]` 自动创建 `Io` 和 `Parse`  属性。 `#[error("...")]` 属性指定错误消息。

您可以在返回 `Result` 的函数中使用此自定义错误类型：

```rust
use std::fs::File;

fn read_file() -> Result<(), MyError> {
    let _file = File::open("non_existent_file.txt")?;
    Ok(())
}
```

为了确保您的代码能够适应未来对 `Error` 枚举的更改，Rust 具有 `#[non_exhaustive]` 属性。当它添加到您的枚举中时，它就变得不详尽，因此可以在库的未来版本中使用其他变体进行扩展：

```rust
#[non_exhaustive]
pub enum Error {
    Io(std::io::Error),
    Parse(std::num::ParseIntError),
    // potentially more variants in the future
}
```

现在，当在定义的包之外匹配此 `Error` 枚举时，Rust 将强制包含 `_` 情况：

```rust
match error {
    Error::Io(err) => println!("I/O error: {}", err),
    Error::Parse(err) => println!("Parse error: {}", err),
    _ => println!("Unknown error"),
}
```

这种高级错误处理方法提供了一种强大而灵活的方法来管理 Rust 中的错误，特别是对于库作者而言。

# 枚举和模式匹配

枚举是枚举的缩写，允许您通过枚举可能的值来定义类型。这是枚举的基本示例：

```rust
enum Direction {
    North,
    South,
    East,
    West,
}
```

枚举的每个变体都是它自己的类型。您可以将数据与枚举变体相关联：

```rust
enum OptionalInt {
    Value(i32),
    Missing,
}
```

Rust 有一个强大的功能，称为模式匹配，它允许您使用干净的语法检查不同的情况。以下是如何将模式匹配与枚举结合使用：

```rust
let direction = Direction::North;

match direction {
    Direction::North => println!("We are heading north!"),
    Direction::South => println!("We are heading south!"),
    Direction::East => println!("We are heading east!"),
    Direction::West => println!("We are heading west!"),
}
```

Rust 中的模式匹配是详尽的：我们必须穷尽所有最后的可能性才能使代码有效，否则代码将无法编译。这个功能在处理枚举时特别有用，因为我们被迫处理所有变体。

Rust 还提供了 `if let` 构造作为 `match` 的更简洁的替代方案，其中只有一种情况值得关注：

```rust
let optional = OptionalInt::Value(5);

if let OptionalInt::Value(i) = optional {
    println!("Value is: {}", i);
} else {
    println!("Value is missing");
}
```

在上面的示例中， `if let` 允许您从 `optional` 中提取 `Value(i)` 并打印它，或者如果 `optional` 则打印“值丢失”是 `OptionalInt::Missing` 。

枚举变体还可以具有带有 `impl` 关键字的方法：

```rust
enum Message {
    Quit,
    ChangeColor(i32, i32, i32),
    Write(String),
}

impl Message {
    fn call(&self) {
        // method body
    }
}

let m = Message::Write(String::from("hello"));
m.call();
```

在此示例中，我们在 `Message` 枚举上定义一个名为 `call` 的方法，然后将其用于 `Message::Write` 实例。

Rust 中的枚举非常通用，并且通过模式匹配，它们在程序中提供了高度的控制流。

## non_exhaustive属性

Rust 中的 `#[non_exhaustive]` 属性是一个有用的功能，可确保enum或struct不会在其定义的包外部进行彻底匹配。这对于可能需要添加更多变体的库作者特别有用或将来枚举或结构的字段，而不会破坏现有代码。

```rust
#[non_exhaustive]
pub enum Error {
    Io(std::io::Error),
    Parse(std::num::ParseIntError),
    // potentially more variants in the future
}
```

在上面的示例中， `Error` 枚举是非详尽的，这意味着它可以在定义它的库的未来版本中使用其他变体进行扩展。当匹配其定义之外的非详尽枚举时crate 中，您必须包含一个 `_` 案例来处理未来潜在的变体：

```rust
match error {
    Error::Io(err) => println!("I/O error: {}", err),
    Error::Parse(err) => println!("Parse error: {}", err),
    _ => println!("Unknown error"),
}
```

如果不包含 `_` 情况，代码将无法编译。这有助于确保您的代码不会因 `Error` 枚举的更改而受到未来的影响。

`#[non_exhaustive]` 属性还可以与struct一起使用，以防止它们在其定义包之外被解构，确保可以在不破坏现有代码的情况下添加未来的字段。Rust 的这一功能提供了一定程度的前向兼容性，并且可以在不造成重大更改的情况下扩展库中的枚举和结构。

# 所有权、借用和生命周期

所有权是 Rust 中的一个关键概念，它可以确保内存安全，而不需要垃圾回收。它围绕三个主要规则：

1. Rust 中的每个值都有一个称为其所有者的变量。
2. 一次只能有一位所有者。
3. 当所有者超出范围时，该值将被删除。

```rust
let s1 = String::from("hello");  // s1 becomes the owner of the string.
let s2 = s1;  // s1's ownership is moved to s2.
// println!("{}", s1);  // This won't compile because s1 no longer owns the string.
```

借用是 Rust 中的另一个关键概念，它允许您对一个值进行多个引用，只要它们不冲突。借用有两种类型：可变借用和不可变借用。

```rust
let s = String::from("hello");
let r1 = &s;  // immutable borrow
let r2 = &s;  // another immutable borrow
// let r3 = &mut s;  // This won't compile because you can't have a mutable borrow while having an immutable one.
```

生命周期是 Rust 编译器确保引用始终有效的一种方式。这是 Rust 中的一个高级概念，通常编译器可以在大多数情况下推断生命周期。但有时，您可能必须自己注释生命周期：

```rust
fn longest<'a>(x: &'a str, y: &'a str) -> &'a str {
    if x.len() > y.len() {
        x
    } else {
        y
    }
}
```

在上面的示例中，函数 `longest` 返回两个字符串切片中最长的一个。生命周期注释 `'a` 指示返回的引用的生命周期至少与两个输入生命周期中最短的生命周期一样长。所有权、借用和生命周期对于理解 Rust 如何管理内存和确保安全至关重要。 Rust 编译器在编译时强制执行这些规则，从而实现高效且安全的程序。

#  泛型

泛型是一种创建在不同类型之间具有广泛适用性的函数或数据类型的方法。它们是在 Rust 中创建可重用代码的基本工具。

以下是使用泛型的函数示例：

```rust
fn largest<T: PartialOrd>(list: &[T]) -> T {
    let mut largest = list[0];

    for &item in list.iter() {
        if item > largest {
            largest = item;
        }
    }

    largest
}
```

在此示例中， `T` 是通用数据类型的名称。 `T: PartialOrd` 是一个trait绑定，这意味着该函数适用于任何实现 `PartialOrd` trait的类型 `T` （或者换句话说，可以排序的类型）。

泛型也可以用在结构定义中：

```rust
struct Point<T> {
    x: T,
    y: T,
}
```

在此示例中， `Point` 是一个具有两个 `T` 类型字段的结构体。这意味着 `Point` 可以具有 `x` 和 `y` 的任何类型，只要它们是相同的类型即可。

泛型在编译时进行检查，因此您可以拥有泛型的所有功能，而无需任何运行时成本。它们是编写灵活、可重用代码而不牺牲性能的强大工具。

#  trait

Rust 中的trait（特性）是一种定义跨类型共享行为的方法。您可以将它们视为其他语言中的接口（interface）。

这是定义trait并实现它的示例：

```rust
trait Speak {
    fn speak(&self);
}

struct Dog;
struct Cat;

impl Speak for Dog {
    fn speak(&self) {
        println!("Woof!");
    }
}

impl Speak for Cat {
    fn speak(&self) {
        println!("Meow!");
    }
}
```

在上面的示例中， `Speak` 是定义名为 `speak` 的方法的trait。 `Dog` 和 `Cat` 是实现 `Speak` trait的结构。这意味着我们可以在 `Dog` 和 `Cat` 实例上调用 `speak` 方法。

#  结构体

结构或结构是自定义数据类型，可让您命名并将多个相关值打包在一起。

以下是定义结构体的方法：

```rust
struct User {
    username: String,
    email: String,
    sign_in_count: u64,
    active: bool,
}
```

以下是创建结构体实例的方法：

```rust
let user = User {
    email: String::from("someone@example.com"),
    username: String::from("someusername"),
    active: true,
    sign_in_count: 1,
};
```

结构体用于在程序中创建复杂的数据类型，它们是任何 Rust 程序的基本组成部分。

#  模块（mod）和命名空间

Rust 中的模块允许您将代码组织到不同的命名空间中。这对于可读性和防止命名冲突很有用。

以下是如何定义模块的示例：

```rust
mod front_of_house {
    pub mod hosting {
        pub fn add_to_waitlist() {}
    }
}
```

在上面的示例中， `front_of_house` 是一个包含另一个模块 `hosting` 的模块。 `add_to_waitlist` 是 `hosting` 模块中定义的函数。

您可以使用 `use` 关键字将路径纳入范围：

```rust
use crate::front_of_house::hosting;

fn main() {
    hosting::add_to_waitlist();
}
```

在上面的示例中，我们使用 `use` 将 `hosting` 引入作用域，这允许我们在不使用 `front_of_house` 前缀的情况下调用 `add_to_waitlist` 。模块和命名空间对于管理更大的代码库和在程序的不同部分重用代码至关重要。

# 并发：线程和消息传递

并发是许多程序中复杂但重要的一部分，Rust 提供了多种处理并发编程的方法。一种方法是使用带有消息传递的线程来进行线程之间的通信。

以下是创建新线程的方法：

```rust
use std::thread;
use std::time::Duration;

fn main() {
    thread::spawn(|| {
        for i in 1..10 {
            println!("hi number {} from the spawned thread!", i);
            thread::sleep(Duration::from_millis(1));
        }
    });

    for i in 1..5 {
        println!("hi number {} from the main thread!", i);
        thread::sleep(Duration::from_millis(1));
    }
}
```

在本例中，我们使用 `thread::spawn` 创建一个新线程。新线程打印一条消息并循环休眠一毫秒。

但是我们如何处理线程之间的通信呢？ Rust 的标准库提供了用于此目的的通道：

```rust
use std::thread;
use std::sync::mpsc;  // mpsc stands for multiple producer, single consumer.

fn main() {
    let (tx, rx) = mpsc::channel();

    thread::spawn(move || {
        let val = String::from("hi");
        tx.send(val).unwrap();
        // println!("val is {}", val);  // This won't compile because `val` has been moved.
    });

    let received = rx.recv().unwrap();
    println!("Got: {}", received);
}
```

在此示例中， `mpsc::channel` 创建一个新通道。 `tx` （发送器）被移动到新线程中，并沿着通道发送字符串“hi”。主线程中的 `rx` （接收者）接收字符串并打印它。

Rust 的线程和消息传递并发模型强制线程之间发送的所有数据都是线程安全的。编译时检查可确保您不会出现数据争用或其他常见并发问题，这可以使并发代码更安全、更容易推理。

# 并发：共享状态并发

除了消息传递之外，Rust 还允许通过使用 `Mutex` （“互斥”的缩写）和 `Arc` （原子引用计数器）来实现共享状态并发。

`Mutex` 提供互斥，这意味着它确保在任何给定时间只有一个线程可以访问某些数据。要访问数据，线程必须首先通过询问互斥体来发出它想要访问的信号。

另一方面， `Arc` 是一种智能指针，它允许同一数据的多个所有者，并确保当对数据的所有引用超出范围时数据得到清理。

以下是如何使用 `Mutex` 和 `Arc` 的示例：

```rust
use std::sync::{Mutex, Arc};
use std::thread;

fn main() {
    let counter = Arc::new(Mutex::new(0));
    let mut handles = vec![];

    for _ in 0..10 {
        let counter = Arc::clone(&counter);
        let handle = thread::spawn(move || {
            let mut num = counter.lock().unwrap();

            *num += 1;
        });
        handles.push(handle);
    }

    for handle in handles {
        handle.join().unwrap();
    }

    println!("Result: {}", *counter.lock().unwrap());
}
```

在此示例中，我们在 `Arc<Mutex<T>>` 内创建一个计数器，可以在多个线程之间安全地共享和改变。每个线程获取一个锁，递增计数器，然后在 `MutexGuard` 超出范围时释放锁。

使用这些工具，Rust 可以通过编译时检查确保安全并发，有助于避免与共享状态并发相关的常见陷阱（例如竞争条件）。

# 错误处理：panic vs. expect vs. unwrap

错误处理在任何编程语言中都至关重要，Rust 为此提供了多种工具：

- `panic!` ：该宏导致程序终止执行，并在运行过程中展开并清理堆栈。

```rust
fn main() {
    panic!("crash and burn");
}
```

- `unwrap` ：如果 `Result` 是 `Ok` ，此方法返回 `Ok` 内的值，并调用 `panic!` 如果 `Result` 是 `Err` 则为宏。

```rust
let x: Result<u32, &str> = Err("emergency failure");
x.unwrap(); // This will call panic!
```

- `expect` ：此方法类似于 `unwrap` ，但允许您指定紧急消息。

```rust
let x: Result<u32, &str> = Err("emergency failure");
x.expect("failed to get the value"); // This will call panic with the provided message.
```

虽然 `unwrap` 和 `expect` 很简单，但应减少使用它们的频率，因为它们可能会导致程序突然终止。在大多数情况下，您应该致力于在适当的时候使用模式匹配和传播错误来优雅地处理错误。

#  测试

测试是软件开发的重要组成部分，Rust 对使用 `#[test]` 属性编写自动化测试提供一流的支持：

```rust
#[cfg(test)]
mod tests {
    #[test]
    fn it_works() {
        assert_eq!(2 + 2, 4);
    }
}
```

在上面的代码中， `#[test]` 将该函数标记为测试函数， `assert_eq!` 是一个宏，用于检查两个参数是否相等，如果不相等则发生恐慌。

# FFI（外部函数接口）

Rust 提供了外部函数接口 (FFI)，允许 Rust 代码与其他语言编写的代码进行交互。下面是从 Rust 调用 C 函数的示例：

```rust
extern "C" {
    fn abs(input: i32) -> i32;
}

fn main() {
    unsafe {
        println!("Absolute value of -3 according to C: {}", abs(-3));
    }
}
```

在此示例中， `extern "C"` 块定义了 C `abs` 函数的接口。它被标记为 `unsafe` ，因为由程序员来确保外部代码的正确性。

#  宏（macro）

Rust 中的宏是定义可重用代码块的一种方式。宏看起来像函数，只不过它们对指定为其参数的代码标记进行操作，而不是对这些标记的值进行操作。

这是一个简单宏的示例：

```rust
macro_rules! say_hello {
    () => (
        println!("Hello, world!");
    )
}

fn main() {
    say_hello!();
}
```

在此示例中， `say_hello!` 是一个打印“Hello, world!”的宏。宏使用与常规 Rust 函数不同的语法，它们在名称后面用 `!` 表示。它们是 Rust 中代码重用和元编程的强大工具。

#  程序宏

Rust 中的过程宏就像函数：它们接受代码作为输入，对该代码进行操作，并生成代码作为输出。它们比声明性宏更灵活。下面是派生宏的示例，它是一种特定类型的过程宏：

```rust
use proc_macro::TokenStream;
use quote::quote;
use syn::{parse_macro_input, DeriveInput};

#[proc_macro_derive(HelloWorld)]
pub fn hello_world_derive(input: TokenStream) -> TokenStream {
    let ast = parse_macro_input!(input as DeriveInput);

    let gen = quote! {
        impl HelloWorld for #ast {
            fn hello_world() {
                println!("Hello, World! My name is {}", stringify!(#ast));
            }
        }
    };

    gen.into()
}
```

在此示例中，我们创建一个过程宏，为给定类型生成 `HelloWorld` trait的实现。

要使用此宏，您首先需要将箱子添加到 `Cargo.toml` 中的依赖项中：

```toml
[dependencies]
HelloMacro = "0.1.0"
```

然后，在 Rust 代码中，您将导入宏并将其应用到结构或枚举：

```rust
use HelloMacro::HelloMacro;

#[derive(HelloMacro)]
struct Pancakes;

fn main() {
    Pancakes::hello_macro();
}
```

在此示例中， `HelloMacro` 过程宏为 `Pancakes` 结构生成一个名为 `hello_macro` 的函数。调用时，此函数会打印“Hello，Macro！我的名字是 Pancakes”。

请注意，创建过程宏所涉及的复杂性比此示例所示的要复杂得多。定义 `HelloMacro` 过程宏需要创建一个 `proc-macro` 类型的单独包，并实现一个生成所需代码的函数。 `syn` 和 `quote` 包通常用于在过程宏中解析和生成 Rust 代码。

#  Rust 的内置特性

Rust 有几个对 Rust 编译器具有特殊含义的内置trait，例如 `Copy` 、 `Drop` 、 `Deref` 等。

例如， `Copy` trait表示可以通过复制位来复制类型的值。如果类型实现 `Copy` ，则可以复制它，而无需“移动”原始值。另一方面， `Drop` trait用于指定当类型的值超出范围时会发生什么。

1. `Clone` 和 `Copy` ： `Clone` trait用于需要实现创建实例副本的方法的类型。如果复制过程很简单（即仅复制位），则可以使用 `Copy` trait。

   ```rust
    #[derive(Clone, Copy)]
    struct Point {
        x: i32,
        y: i32,
    }
   ```

2. `Drop` ：此trait允许您自定义当值超出范围时会发生的情况。当您的类型正在管理资源（如内存或文件）并且您需要在使用完毕后进行清理时，这特别有用。

   ```rust
    struct Droppable {
        name: &'static str,
    }
   
    impl Drop for Droppable {
        fn drop(&mut self) {
            println!("{} is being dropped.", self.name);
        }
    }
   ```

3. `Deref` 和 `DerefMut` ：这些trait用于重载取消引用运算符。 `Deref` 用于重载不可变解引用运算符，而 `DerefMut` 用于重载可变解引用运算符。

   ```rust
    use std::ops::Deref;
    struct DerefExample<T> {
        value: T,
    }
   
    impl<T> Deref for DerefExample<T> {
        type Target = T;
        fn deref(&self) -> &T {
            &self.value
        }
    }
   ```

4. `PartialEq` 和 `Eq` ：这些trait用于比较对象的等效性。 `PartialEq` 允许部分比较，而 `Eq` 要求完全相等（即，它要求每个值必须与其自身相等）。

   ```rust
    #[derive(PartialEq, Eq)]
    struct EquatableExample {
        x: i32,
    }
   ```

5. `PartialOrd` 和 `Ord` ：这些trait用于比较对象的排序。 `PartialOrd` 允许部分比较，而 `Ord` 需要全排序。

   ```rust
    #[derive(PartialOrd, Ord)]
    struct OrderableExample {
        x: i32,
    }
   ```

6. `AsRef` 和 `AsMut` ：这些trait用于廉价的引用到引用转换。 `AsRef` 用于转换为不可变引用，而 `AsMut` 用于转换为可变引用。

   ```rust
    fn print_length<T: AsRef<str>>(s: T) {
        println!("{}", s.as_ref().len());
    }
   ```

这些只是 Rust 中可用的内置trait的几个示例。还有更多，每一个都有特定的目的。这是 Rust 支持多态性的方式之一。

#  迭代器和闭包

迭代器是一种生成值序列的方法，通常在循环中。这是一个例子：

```rust
let v1 = vec![1, 2, 3];
let v1_iter = v1.iter();

for val in v1_iter {
    println!("Got: {}", val);
}
```

闭包是一个可以捕获其环境的匿名函数。这是一个例子：

```rust
let x = 4;
let equal_to_x = |z| z == x;
let y = 4;
assert!(equal_to_x(y));
```

# 使用 Rust 进行异步编程

Rust 的 `async/.await` 语法使 Rust 中的异步编程更加符合人体工程学。这是一个例子：

```rust
async fn hello_world() {
    println!("hello, world!");
}

fn main() {
    let future = hello_world(); // Nothing is printed
    futures::executor::block_on(future); // "hello, world!" is printed
}
```

# Rust 中的Pin和Unpin

`Pin` 是一种标记类型，指示它所包装的值不得移出其中。这对于自引用结构和其他不需要移动的情况很有用。

`Unpin` 是一个自动trait，表明它所实现的类型可以安全地移出。

1. `Pin` ： `Pin` 类型是一个包装器，它使得它包装的值不可移动。这意味着，一旦一个值被固定，它就不能再移动到其他地方，并且它的内存地址也不会改变。当处理需要具有稳定地址的某些类型的不安全代码时，例如在构建自引用结构或处理异步编程时，这可能很有用。

   这是固定值的示例：

   ```rust
    let mut x = 5;
    let mut y = Box::pin(x);
   
    let mut z = y.as_mut();
    *z = 6;
   
    assert_eq!(*y, 6);
   ```

   在上面的示例中， `y` 是包含值 `5` 的固定 `Box` 。当我们通过 `y.as` `_mut()` 获得对 `y` 的可变引用时，我们可以更改 `Box` 中的值，但我们不能更改 `y` 以指向其他内容。 `y` 内的值被“固定”。

2. `Unpin` ： `Unpin` trait是一个“自动trait”（由 Rust 编译器自动实现的trait），它是为所有没有任何固定字段的类型实现的，本质上使其成为可以安全地移动这些类型。

   下面是 `Unpin` 类型的示例：

   ```rust
    struct MyStruct {
        field: i32,
    }
   ```

   在上面的示例中， `MyStruct` 是 `Unpin` 因为它的所有字段都是 `Unpin` 。这意味着在内存中移动 `MyStruct` 是安全的。

`Pin` 和 `Unpin` trait是 Rust 安全处理内存并确保对对象的引用保持有效的能力的关键部分。它们广泛用于高级 Rust 编程，例如使用 `async/await` 或其他形式的“自引用”结构时。