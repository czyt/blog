---
title: "Rust的一些难点解惑【译】"
date: 2024-02-21
tags: ["rust"]
draft: false
---

>原文 https://katib.moe/the-hard-things-about-rust, 本文使用机器翻译而成，部分文字进行了调整。

Rust 是一种系统编程语言，运行速度极快，可防止段错误并保证线程安全。虽然这些功能使 Rust 成为系统编程的强大工具，但它们也引入了一些对于来自其他语言的人可能不熟悉的新概念。

在这份综合指南“Rust 的困难之处”中，我们的目标是阐明 Rust 的这些具有挑战性的方面，并使新手和经验丰富的程序员都可以使用它们。我们将阐明这些复杂的概念，并用具体示例和现实场景来说明每个概念，以便更好地理解。

以下是我们将要介绍的内容：

1. 所有权：我们将从 Rust 中所有权的基本概念开始。我们将探讨一个值拥有所有者意味着什么，所有权如何转移，以及 Rust 的所有权模型如何帮助内存管理。
2. 借用和生命周期：在所有权的基础上，我们将深入研究借用和生命周期，这两个相互关联的概念可让您安全地引用数据。
3. 切片：我们将揭开切片的神秘面纱，切片是内存块的视图，它在 Rust 中广泛用于高效访问数据。
4. 错误处理：Rust 处理错误的方法是独特且稳健的。我们将介绍 `Result` 和 `Option` 类型，以及如何使用它们进行优雅的错误处理。
5. 并发：我们将深入研究 Rust 强大而复杂的并发模型。我们将讨论线程、消息传递和共享状态并发等。
6. 高级类型和Trait：我们将探索 Rust 的一些高级类型，例如 `Box` 、 `Rc` 、 `Arc` 。我们还将介绍 Trait 和 Trait 对象。
7. Async/Await 和 Futures：当我们转向高级概念时，我们将解释 Rust 的 async/await 语法和用于处理异步编程的 Futures 模型。

本指南的目标不仅仅是提供这些主题的概述，而是帮助您了解这些概念背后的基本原理、它们在幕后如何工作以及如何在 Rust 程序中有效地使用它们。

无论您是希望深入了解该语言的 Rust 初学者，还是旨在巩固对这些复杂概念的理解的中级 Rustacean，本指南都适合您。让我们踏上这段征服 Rust 难点的旅程吧！

#  所有权

所有权是 Rust 的一个基本概念。它是 Rust 内存安全方法的一部分，使 Rust 在编程语言中独一无二。理解所有权对于编写 Rust 程序至关重要，因为许多其他 Rust 概念（例如借用和生命周期）都是建立在它之上的。

##  什么是所有权？

在 Rust 中，每个值都有一个称为其所有者的变量。一次只能有一位所有者。当所有者超出范围时，该值将被删除或清理。

让我们考虑一个简单的例子：

```rust
{
   let s = "hello world"; // s is the owner of the &str "hello world"
} // s goes out of scope here, and the string is dropped
```

在上面的代码中，变量 `s` 是字符串 `"hello world"` 的所有者。一旦 `s` 在块末尾超出范围，该字符串将被删除并释放其内存。

##  **转移所有权**

在 Rust 中，赋值运算符 `=` 将所有权从一个变量转移到另一个变量。这与 `=` 复制值的其他语言不同。

 考虑这个例子：

```rust
let s1 = String::from("hello");
let s2 = s1;
```

在上面的代码中， `s1` 最初拥有字符串 `"hello"` 。但是，行 `let s2 = s1;` 将所有权从 `s1` 移动到 `s2` 。现在， `s2` 是字符串 `"hello"` 的所有者，而 `s1` 不再有效。如果您在此之后尝试使用 `s1` ，Rust 会给您一个编译时错误。

##  **复制特质**

Rust 中的某些类型实现了 `` Trait。当将此类类型分配给另一个变量时，不会移动所有权，而是会创建该值的副本。所有整数和浮点类型、布尔类型、字符类型以及实现 `` Trait的类型元组都是 `` 。

这是一个例子：

```rust
let x = 5;
let y = x;
```

在上面的代码中， `x` 是一个整数，它实现了 `` Trait。因此，当我们编写 `let y = x;` 时，它不会移动所有权。相反，它将值从 `x` 复制到 `y` 。

##  **为什么要所有权？**

所有权的概念使 Rust 能够在不需要垃圾收集器的情况下做出内存安全保证。通过强制一个值只能有一个所有者，并且当所有者超出范围时该值会被清除，Rust 可以防止常见的编程错误，例如空指针或悬空指针、双重释放和数据竞争。

# **借用和生命周期：在 Rust 中安全引用数据**

借用和生命周期是 Rust 最显着的两个Trait。它们共同使 Rust 能够在没有垃圾收集器的情况下保证内存安全和线程安全。让我们详细探讨这些概念。

##  **借款**

在 Rust 中，我们经常让代码的其他部分访问一个值而不获取它的所有权。这是通过称为“借用”的功能来完成的。借用有两种类型：共享借用和可变借用。

###  **共享借用**

共享借用允许一个项目具有多个引用。这是通过使用 Rust 中的 `&` 符号来完成的。让我们看一个例子：

```rust
fn main() {
    let s1 = String::from("hello");
    let len = calculate_length(&s1);
    println!("The length of '{}' is {}.", s1, len);
}

fn calculate_length(s: &String) -> usize {
    s.len()
}
```

在此代码中， `calculate_length` 借用 `s1` 临时使用。 `s1` 仍然属于 `main` 函数，因此我们可以在 `calculate_length` 调用之后再次使用 `s1` 。

###  **可变借用**

可变借用是指您希望允许更改借用值。这是通过在变量前面使用 `&mut` 来完成的。例如：

```rust
fn main() {
    let mut s1 = String::from("hello");
    change(&mut s1);
}

fn change(s: &mut String) {
    s.push_str(", world");
}
```

这里， `change` 函数借用了 `s1` 并改变了它。这是可能的，因为 `s1` 是可变借用的。

然而，Rust 有一条规则，即您可以拥有一个可变引用或任意数量的不可变引用，但不能同时拥有两者。该规则保证数据竞争永远不会发生。

让我们用代码示例来分解这个概念。

```rust
fn main() {
    let mut s = String::from("hello");

    let r1 = &s; // no problem
    let r2 = &s; // no problem
    println!("{} and {}", r1, r2);
    // r1 and r2 are no longer used after this point

    let r3 = &mut s; // no problem
    println!("{}", r3);
}
```

在此示例中，代码有效，因为即使 `r1` 和 `r2` 在创建 `r3` 时位于范围内，但在 `r3` 之后不会使用它们> 已创建。 Rust 的规则规定（如前所述），您可以拥有一个可变引用或任意数量的不可变引用，但不能同时拥有两者。但这仅适用于使用参考文献时。

现在，让我们看一个违反 Rust 借用规则的示例：

```rust
fn main() {
    let mut s = String::from("hello");

    let r1 = &s; // no problem
    let r2 = &s; // no problem
    let r3 = &mut s; // PROBLEM! // cannot borrow `s` as mutable because it is also borrowed as immutable

    println!("{}, {}, and {}", r1, r2, r3);
}
```

在本例中， `r1` 和 `r2` 是不可变引用， `r3` 是可变引用。我们试图同时使用它们，这违反了 Rust 的借用规则，因此编译器会抛出错误。

此规则可防止编译时的数据竞争。

##  **生命周期**

生命周期是 Rust 确保所有借用有效的方式。生命周期的要点是防止悬空引用。当我们引用某些数据时，就会出现悬空引用，并且该数据在引用之前被删除。

在 Rust 中，编译器使用生命周期来确保不会发生此类错误。这是一个例子：

```rust
fn longest<'a>(x: &'a str, y: &'a str) -> &'a str {
    if x.len() > y.len() {
        x
    } else {
        y
    }
}
```

在此函数中， `'a` 是一个生命周期参数，表示：对于某个生命周期 `'a` ，采用两个参数，两者都是至少与 `'a` ，并返回一个字符串切片，该切片的持续时间至少与 `'a` 一样长。

这有点抽象，所以让我们考虑一个具体的例子：

```rust
fn main() {
    let string1 = String::from("long string is long");
    {
        let string2 = String::from("xyz");
        let result = longest(string1.as_str(), string2.as_str());
        println!("The longest string is {}", result);
    }
}
```

这里， `string1` 的生命周期比 `string2` 长，所以当 `result` 在 `println!` 中使用时，它不会引用 `string2` ，确保我们没有悬空引用。

总之，借用和生命周期是同一枚硬币的两个侧面，使 Rust 安全高效。它们允许 Rust 在编译时确保安全性和并发性。理解它们是掌握 Rust 的关键。

# **切片：Rust 中序列的视图**

Rust 提供了一种引用连续序列或集合的一部分，而不是整个集合本身的方法。这是通过称为“切片”的功能来完成的。

##  了解切片

切片表示对集合中一个或多个连续元素的引用，而不是对整个集合的引用。这是切片的示例：

```rust
fn main() {
    let s = String::from("hello world");
    let hello = &s[0..5];
    let world = &s[6..11];
    println!("{} {}", hello, world);
}
```

在此代码中， `hello` 和 `world` 是 `s` 的切片。数字 [0..5] 和 [6..11] 是范围索引，表示“从索引 0 开始并继续到但不包括索引 5”和“从索引 6 开始并继续到但不包括”分别包括索引 11"。如果我们运行这个程序，它将打印 `hello world` 。

##  **字符串切片**

字符串切片是对字符串的一部分的引用，它看起来像这样：

```rust
let s = String::from("hello world");
let hello = &s[0..5];
let world = &s[6..11];
```

这里 `hello` 和 `world` 是字符串 `s` 的切片。您可以通过指定 [starting_index..ending_index] 使用括号内的范围创建切片，其中 `starting_index` 是切片中的第一个位置， `ending_index` 比最后一个位置多一个在切片中。

##  **数组切片**

就像字符串一样，我们也可以对数组进行切片。这是一个例子：

```rust
fn main() {
    let a = [1, 2, 3, 4, 5];
    let slice = &a[1..3];
    println!("{:?}", slice);
}
```

这里， `slice` 将是一个包含 `2, 3` 的切片，它们是数组 `a` 的第二个和第三个元素。

##  **切片的好处**

切片的强大之处在于它们允许您引用连续的序列，而无需将序列复制到新的集合中。这是让函数访问集合的一部分的更有效方法。

#  **Rust 中的错误处理**

错误处理是任何编程语言的基本组成部分，Rust 也不例外。它认识到软件中不可避免的错误，并提供强大的机制来有效地处理这些错误。 Rust 错误处理机制的设计要求开发人员明确地承认和处理错误，从而使程序更加健壮并防止许多问题影响到生产环境。

Rust 将错误分为两种主要类型：可恢复错误和不可恢复错误。可恢复的错误通常是正常情况下可能失败的操作的结果，例如尝试打开不存在的文件。在这种情况下，我们通常希望通知用户错误并重试操作或以不同的方式继续执行程序。

另一方面，不可恢复的错误通常表示代码中存在错误，例如尝试访问超出其范围的数组。此类错误非常严重，需要立即停止程序。

有趣的是，Rust 不使用异常，这是许多语言中常见的错误处理机制。相反，它提供了两个结构： `Result<T, E>` 和 `panic!` 宏，分别用于处理可恢复和不可恢复的错误。

##   宏

Rust 中的 `panic!` 宏用于立即停止程序的执行。它通常在程序遇到不知道如何处理的情况或达到不应该达到的状态时使用。这些场景通常代表程序中的错误。当 `panic!` 被调用时，一条错误消息被打印到标准错误输出，并且程序被终止。

您可以使用简单的字符串消息调用 `panic!` ，或者将其与格式字符串一起使用，类似于 `println!` 。您传递给 `panic!` 的消息将成为紧急负载，并在程序崩溃时作为错误消息的一部分返回。例如：

```rust
panic!();
panic!("this is a terrible mistake!");
panic!("this is a {} {message}", "fancy", message = "message");
std::panic::panic_any(4); // panic with the value of 4 to be collected elsewhere
```

如果在主线程中调用 `panic!` ，它将终止所有其他线程并以退出代码 `101` 结束程序。

##  Result 

Rust 处理可恢复错误的方法封装在 `Result<T, E>` 枚举中。 `Result` 是一个通用枚举，有两种变体： `Ok(T)` 表示成功结果， `Err(E)` 表示错误。 `Result` 的力量在于其明确的本质；它迫使开发人员处理成功和失败的情况，从而避免许多常见的错误处理陷阱。

Rust 提供了几种处理 `Result` 值的方法，其中最值得注意的是 `?` 运算符。 `?` 运算符可以附加到返回 `Result` 的函数调用的末尾。如果函数成功并返回 `Ok(T)` ，则 `?` 运算符将解包值 `T` 并且程序继续。如果函数遇到错误并返回 `Err(E)` ，则 `?` 运算符立即从当前函数返回并将错误沿调用堆栈向上传播。

```rust
enum Result<T, E> {
    Ok(T),
    Err(E),
}
```

此定义表示返回 `Result` 的函数可以成功 ( `Ok` ) 并返回 `T` 类型的值，也可以失败 ( `Err` ）并返回 `E` 类型的错误。

以下是返回 `Result` 的函数示例：

```rust
use std::num::ParseIntError;

fn parse_number(s: &str) -> Result<i32, ParseIntError> {
    match s.parse::<i32>() {
        Ok(n) => Ok(n),
        Err(e) => Err(e),
    }
}

let n = parse_number("42");
match n {
    Ok(n) => println!("The number is {}", n),
    Err(e) => println!("Error: {}", e),
}
```

在此示例中， `parse_number` 尝试将字符串解析为整数。如果成功，则返回 `Ok` 内的数字，否则返回 `Err` 内的错误。 `match` 语句用于处理 `Result` 的两种可能结果。

###  **Option**

`Option` 枚举与 `Result` 类似，但当函数可以返回值或根本不返回任何值（而不是错误）时使用它。它的定义为：

```rust
enum Option<T> {
    Some(T),
    None,
}
```

以下是返回 `Option` 的函数示例：

```rust
fn find(array: &[i32], target: i32) -> Option<usize> {
    for (index, &item) in array.iter().enumerate() {
        if item == target {
            return Some(index);
        }
    }
    None
}

let array = [1, 2, 3, 4, 5];
match find(&array, 3) {
    Some(index) => println!("Found at index {}", index),
    None => println!("Not found"),
}
```

在此示例中， `find` 函数尝试在数组中查找数字。如果找到，该函数将返回 `Some(index)` ，其中 `index` 是数字在数组中的位置。如果未找到，该函数将返回 `None` 。

`Result` 和 `Option` 都提供了各种有用的方法来处理这些类型。例如， `unwrap` 可用于获取 `Ok` 或 `Some` 内的值，但如果 `Result` 为 或 `Option` 是 `None` 。作为更安全的替代方案， `unwrap_or` 和 `unwrap_or_else` 可分别用于提供默认值或后备函数。

```rust
let x = Some(2);
assert_eq!(x.unwrap(), 2);

let x: Option<u32> = None;
assert_eq!(x.unwrap_or(42), 42);

let x: Result<u32, &str> = Err("emergency failure");
assert_eq!(x.unwrap_or_else(|_| 42), 42);
```

一般来说， `Result` 和 `Option` 是 Rust 中用于错误处理和表示值缺失的强大工具。它们使您的代码更明确地了解可能的失败或空情况，有助于防止许多常见的编程错误。

#  并发研究

Rust 中的并发是通过多种机制实现的，包括线程、消息传递和共享状态。让我们依次探讨其中的每一个。

##  **1. 线程**

Rust 有一个 `std::thread` 模块，允许您创建新线程并以独立于系统的方式使用它们。这是创建新线程的简单示例：

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

在此示例中，我们使用 `thread::spawn` 创建一个新线程，并向其传递一个包含新线程指令的闭包。主线程和新线程独立打印它们的消息，在每条消息之间休眠一毫秒。

##  2.消息传递

Rust 提供了受 Erlang 语言启发的消息传递并发模型。消息传递是一种处理并发的方法，其中线程或参与者通过向彼此发送包含数据的消息来进行通信。

在 Rust 中，您可以使用 `std::sync::mpsc` 模块创建通道（mpsc 代表多个生产者，单个消费者）。这是一个例子：

```rust
use std::sync::mpsc;
use std::thread;

fn main() {
    let (tx, rx) = mpsc::channel();

    thread::spawn(move || {
        let val = String::from("hi");
        tx.send(val).unwrap();
    });

    let received = rx.recv().unwrap();
    println!("Got: {}", received);
}
```

在此示例中，我们使用 `mpsc::channel` 创建一个通道，然后将传输端 ( `tx` ) 移动到新线程中。该线程向通道发送一条消息（“hi”），然后我们等待在主线程中接收该消息并将其打印出来。

##  3. 共享状态

Rust 还提供了一种使用互斥体以安全方式在线程之间共享状态的方法。互斥体提供互斥，这意味着在任何给定时间只有一个线程可以访问数据。要访问数据，线程必须首先通过要求互斥体锁定来发出它想要访问的信号。这是一个例子：

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

在此示例中，我们在互斥锁内创建一个计数器，然后使用原子引用计数 (Arc) 在多个线程之间共享它。每个线程都会锁定互斥锁，递增计数器，然后释放锁。

这是一个高层次的概述。 Rust 的并发模型非常强大和灵活，它提供了许多功能来确保并发代码免受数据竞争和其他常见并发问题的影响。

# **高级类型和Trait**

## Box

Box是一个智能指针，它指向存储在堆上的数据，而不是栈上。当您有大量数据要存储或者您想要确保特定变量不会在内存中移动时，它们非常有用。

Box 也有所有权。当 Box 超出范围时，将调用析构函数并释放堆内存。

这是一个简单的例子：

```rust
let b = Box::new(5); // b is a pointer to a heap allocated integer
println!("b = {}", *b); // Output: b = 5
```

在此示例中，变量 `b` 是一个 Box，它在堆上拥有一个整数 `5` 。 `*` 运算符用于取消引用框，获取它指向的值。

## Rc

Rc 代表引用计数。它是一个智能指针，通过跟踪对确定何时清理的值的引用数量，允许多个所有者。当我们想要在堆上分配一些数据供程序的多个部分读取，并且我们无法在编译时确定哪个部分最后使用这些数据时，可以使用 rc。

需要注意的是，Rc 仅适用于单线程场景。这是一个简单的例子：

```rust
use std::rc::Rc;

let original = Rc::new(5);
let a = Rc::clone(&original);
let b = Rc::clone(&original);

println!("original: {}, a: {}, b: {}", *original, *a, *b); // Output: original: 5, a: 5, b: 5
```

在此示例中，变量 `original` 是一个 Rc，它在堆上拥有一个整数 `5` 。我们可以创建这个 Rc 的多个“克隆”（实际上只是指向相同数据的新指针，而不是完整副本）。当所有 Rc 超出范围时，堆内存将被释放。

## Arc

Arc 是原子引用计数。它与 Rc 相同，但可以在多线程上下文中安全使用。它提供与 Rc 相同的功能，但使用原子操作进行引用计数。这使得在多个线程之间共享是安全的，但代价是性能受到轻微影响。

 这是一个例子：

```rust
use std::sync::Arc;
use std::thread;

let original = Arc::new(5);
for _ in 0..10 {
    let original = Arc::clone(&original);
    thread::spawn(move || {
        println!("{}", *original);
    });
}
```

在此示例中，我们使用 Arc 在多个线程之间共享堆分配的整数。每个线程都会获得 Arc 的克隆（指向数据的新指针）。当所有 Arc 超出范围时，堆内存将被释放。

这些类型提供了更高级的方法来管理 Rust 中的内存和数据所有权，从而实现更复杂的数据结构和模式。然而，它们也增加了复杂性，并且更难正确使用，因此应该谨慎使用它们。

##  Self

在 Rust 中，Trait是为未知类型定义的方法的集合： `Self` 。它们可以访问在同一Trait中声明的其他方法，并且是定义共享或共同行为的一种方法。将Trait视为定义类型可以实现的接口的一种方式。

考虑这个简单的例子：

```rust
trait Animal {
    fn make_noise(&self) -> String;
}

struct Dog;
struct Cat;

impl Animal for Dog {
    fn make_noise(&self) -> String {
        String::from("Woof!")
    }
}

impl Animal for Cat {
    fn make_noise(&self) -> String {
        String::from("Meow!")
    }
}
```

在上面的示例中，我们使用方法 `make_noise` 定义了一个Trait `Animal` 。然后，我们为 `Dog` 和 `Cat` 结构实现此Trait，提供其独特版本的 `make_noise` 函数。我们现在可以在任何实现 `Animal` Trait的类型上调用此函数。

## Clone和Copy Trait

Rust 提供了许多具有特定行为的预定义Trait。其中两个是 `Clone` 和  Trait。

`Clone` Trait允许显式重复数据。当您想要创建类型数据的新副本时，如果该类型实现了 `Clone` Trait，则可以调用 `clone` 方法。

```rust
#[derive(Clone)]
struct Point {
    x: i32,
    y: i32,
}

let p1 = Point { x: 1, y: 2 };
let p2 = p1.clone();  // p1 is cloned into p2
```

在此示例中， `Point` 结构实现 `Clone` Trait，因此我们可以使用 `clone` 方法创建任何 `Point` 实例的副本。

另一方面， `` Trait允许隐式重复数据。当我们希望能够制作值的浅拷贝而不用担心所有权时，可以使用它。如果类型实现了 `` Trait，则旧变量在赋值后仍然可用。

```rust
#[derive(, Clone)]
struct Simple {
    a: i32,
}

let s1 = Simple { a: 10 };
let s2 = s1; // s1 is copied into s2
println!("s1: {}", s1.a); // s1 is still usable
```

在此示例中， `Simple` 实现了 `` Trait，允许将 `s1` 复制到 `s2` 中，并且之后仍然可用。

但是，请注意：并非所有类型都可以是 `` 。管理资源的类型（例如 `String` 或拥有堆数据的自定义结构）无法实现 `` Trait。一般来说，如果类型在值被删除时需要一些特殊操作，则它不能是 `` 。此限制可以防止双重释放错误，这是手动内存管理语言中的常见问题。

##  Debug Trait

`Debug` Trait可以对输出的结构数据进行格式化，通常用于调试目的。默认情况下，Rust 不允许打印结构体值。但是，一旦派生了 `Debug` Trait，您就可以使用具有调试格式 ( `{:?}` ) 的 `println!` 宏来打印结构体值。

```rust
#[derive(Debug)]
struct Rectangle {
    width: u32,
    height: u32,
}

let rect = Rectangle { width: 30, height: 50 };

println!("rect is {:?}", rect);
```

在此示例中， `Rectangle` 派生出 `Debug` Trait，允许您在标准输出中打印出其值。

##  PartialEq 和 Eq Trait

`PartialEq` Trait允许比较类型实例的相等和不相等。 `Eq` Trait取决于 `PartialEq` ，表示所有比较都是自反的，这意味着如果 `a == b` 和 `b == c` ，则 `a == c` 。

```rust
#[derive(PartialEq, Eq)]
struct Point {
    x: i32,
    y: i32,
}

let p1 = Point { x: 1, y: 2 };
let p2 = Point { x: 1, y: 2 };

println!("Are p1 and p2 equal? {}", p1 == p2);
```

在此示例中， `Point` 派生 `PartialEq` 和 `Eq` Trait，这允许比较 `Point` 实例。

## PartialOrd 和 Ord Trait

这些Trait启用类型实例上的比较操作（ `<` 、 `>` 、 `<=` 、 `>=` ）。 `PartialOrd` 允许部分排序，其中某些值可能无法比较。另一方面， `Ord` 支持值之间的完整排序。

```rust
#[derive(PartialOrd, Ord, PartialEq, Eq)]
struct Point {
    x: i32,
}

let p1 = Point { x: 1 };
let p2 = Point { x: 2 };

println!("Is p1 less than p2? {}", p1 < p2);
```

在此示例中， `Point` 派生 `PartialOrd` 、 `Ord` 、 `PartialEq` 和 `Eq` Trait。这允许比较 `Point` 实例。

## Default Trait

`Default` Trait允许创建类型的默认值。它提供了一个函数 `default` ，它返回类型的默认值。

```rust
#[derive(Default)]
struct Point {
    x: i32,
    y: i32,
}

let p1 = Point::default(); // Creates a Point with x and y set to 0
```

在此示例中， `Point` 派生出 `Default` Trait。这允许创建具有默认值（本例中为 0）的 `Point` 实例。

#  **async/await和Future**

###  Future

Rust 中的 `Future` 表示可能尚未计算的值。它们是并发编程中的一个概念，可实现非阻塞计算：程序可以继续执行其他任务，而不是等待缓慢的计算完成。

期货基于 `Future` Trait，其最简单的形式如下所示：

```rust
pub trait Future {
    type Output;
    fn poll(self: Pin<&mut Self>, cx: &mut Context) -> Poll<Self::Output>;
}
```

`Future` Trait是 `Generator` 的异步版本。它有一个方法 `poll` ，由执行器调用以驱动 future 完成。 `poll` 方法检查 `Future` 是否已完成其计算。如果有，则返回 `Poll::Ready(result)` 。如果没有，则返回 `Poll::Pending` 并安排在再次调用 `poll` 时通知当前任务。

###  async和await

`async` 和 `await` 是 Rust 中用于处理 `Futures` 的特殊语法。您可以将 `async` 视为创建 `Future` 的方式，将 `await` 视为使用 `Future` 的方式。

`async` 是一个关键字，您可以将其放在函数前面，使其返回 `Future` 。这是一个简单的异步函数：

```rust
async fn compute() -> i32 {
    5
}
```

当您调用 `compute` 时，它将返回一个 `Future` ，当驱动完成时，将产生值 `5` 。

`await` 是一种暂停当前函数执行直到 `Future` 完成的方法。这是一个例子：

```rust
async fn compute_and_double() -> i32 {
    let value = compute().await;
    value * 2
}
```

这里， `compute().await` 将暂停 `compute_and_double` 的执行，直到 `compute` 完成运行。一旦 `compute` 完成，其返回值将用于恢复 `compute_and_double` 函数。

当函数被 `await` 挂起时，执行器可以运行其他 `Futures` 。这就是 Rust 中的异步编程实现高并发的方式：同时运行多个任务，并在任务等待缓慢操作（例如 I/O）时在它们之间进行切换。

### executor

executor负责驱动 `Future` 完成。 `Future` 描述了需要发生的事情，但执行者的工作是让它发生。换句话说，如果没有executor， `Futures` 将不会执行任何操作。

下面是一个使用 `futures` 中的 `block_on` executor的简单示例：

```rust
use futures::executor::block_on;

async fn hello() -> String {
    String::from("Hello, world!")
}

fn main() {
    let future = hello();
    let result = block_on(future);
    println!("{}", result);
}
```

在此示例中， `block_on` 采用 `Future` 并阻塞当前线程，直到 `Future` 完成。然后它返回 `Future` 的结果。

Rust 中有许多不同的executor可用，每个执行器都有不同的特性。有些，例如 `tokio` ，是为构建高性能网络服务而设计的。其他的，如 `async-std` ，提供了一组感觉像标准库的异步实用程序。

请记住，作为开发人员，您有责任确保执行者正确地驱动 `Futures` 完成。如果 `Future` 在没有被 `awaited` 或驱动完成的情况下被丢弃，它就没有机会自行清理。

总之，Rust 的 `async/await` 语法和 `Future` Trait为编写异步代码提供了强大的模型。然而，它们也很复杂，需要很好地理解语言的所有权和并发模型。

#  综上所述，

Rust 提供了一个强大的工具集来处理复杂的编程任务，提供对系统资源无与伦比的控制。它包含高级类型、Trait和异步功能，满足低级和高级编程需求。虽然 Rust 最初看起来可能令人畏惧，但它在性能、控制和安全方面提供的好处使学习之旅变得值得。当您了解 Rust 的复杂性时，理解所有权、借用和生命周期的概念将成为您的指南。遵循这些原则，您将有能力解决 Rust 编程中最具挑战性的方面。快乐编码！