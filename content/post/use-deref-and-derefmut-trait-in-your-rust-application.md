---
title: "在你的Rust程序中使用Deref和DerefMut trait"
date: 2024-04-25
tags: ["rust"]
draft: false
---

## Deref 

`Deref` 是一种 Rust 编译器宏，用于实现 `Deref` trait。`Deref` trait 允许将自定义类型转换为引用，从而使其能够用于任何需要引用的地方。

`Deref` 宏通常用于以下场景：

- **新类型模式:** 当您定义一个新类型时，`deref` 宏可以使其能够像引用一样使用。例如，您可以创建一个 `Box` 类型，该类型将值存储在堆上，并实现 `Deref` trait 以便可以使用 `*` 运算符访问值。
- **链式访问:** `deref` 宏可以用于创建链式访问语法。例如，您可以创建一个 `Vec<Box<T>>` 类型，其中 `T` 是任何可实现 `Deref` trait 的类型。这允许您使用 `*` 运算符在向量中迭代并访问每个值。
- **泛型代码:** `deref` 宏可以用于编写泛型代码，该代码可以与任何可实现 `Deref` trait 的类型一起使用。例如，您可以创建一个函数，该函数接受任何可实现 `Deref` trait 的类型并返回其值。

` deref `宏在 Rust 中扮演着重要的角色，它允许你自定义类型在特定情况下表现得像引用一样。这带来了许多便利，例如：

- **简化访问底层数据:** 无需手动解引用，直接访问结构体内部数据。
- **使用运算符重载:** 使自定义类型支持 * 和 [] 等运算符。
- **自动解引用:** 在需要引用的地方，自动解引用自定义类型。

### 实用例子

**1. 自定义智能指针**

```rust
use std::ops::Deref;

struct MyBox<T>(T);

impl<T> Deref for MyBox<T> {
    type Target = T;

    fn deref(&self) -> &Self::Target {
        &self.0
    }
}

fn main() {
    let x = 5;
    let y = MyBox(x);

    assert_eq!(5, *y); // 自动解引用 MyBox，等价于 *(y.deref())
}
```

> Use code [with caution](https://support.google.com/legal/answer/13505487)

在这个例子中，MyBox 实现了 Deref trait，使得它可以像普通引用一样使用 * 运算符访问内部数据。

**2. 为 Vec 添加 last 方法**

```rust
use std::ops::Deref;

struct MyVec<T>(Vec<T>);

impl<T> Deref for MyVec<T> {
    type Target = Vec<T>;

    fn deref(&self) -> &Self::Target {
        &self.0
    }
}

impl<T> MyVec<T> {
    fn last(&self) -> Option<&T> {
        self.0.last()
    }
}

fn main() {
    let v = MyVec(vec![1, 2, 3]);
    assert_eq!(Some(&3), v.last()); 
}
```

> Use code [with caution](https://support.google.com/legal/answer/13505487)

这里，我们为 MyVec 实现了 Deref 和 last 方法。Deref 使得 MyVec 可以像 Vec 一样使用，而 last 方法则提供了获取最后一个元素的功能。

**3. 使用自定义 String 类型**

```rust
use std::ops::Deref;

struct MyString(String);

impl Deref for MyString {
    type Target = str;

    fn deref(&self) -> &str {
        &self.0
    }
}

fn main() {
    let s = MyString("Hello".to_string());
    println!("{}", s); // 自动解引用 MyString，等价于 &*s
}
```

> Use code [with caution](https://support.google.com/legal/answer/13505487)

MyString 实现了 Deref，使得它可以像 str 一样使用，可以直接用于字符串格式化等操作。

## Deref 和 DerefMut: 访问与修改

除了Deref 之外，还有一个 DerefMut。这两者 都是 Rust 中的 trait，用于自定义类型的解引用行为，但它们之间存在关键区别：

**Deref：不可变借用**

- 实现 Deref 允许你的类型像不可变引用一样工作。
- 可以使用 * 运算符访问底层数据，但不能修改。
- 适用于需要读取或使用底层数据，但不需要修改的场景。

**DerefMut：可变借用**

- 实现 DerefMut 允许你的类型像可变引用一样工作。
- 可以使用 * 运算符访问和修改底层数据。
- 适用于需要修改底层数据的场景。

### 使用场景

**Deref**

- **自定义智能指针:** 如 `Box` 和 `Rc`，提供更便捷的访问方式。
- **包装类型:** 对现有类型添加功能，同时保持与原始类型兼容。
- **零成本抽象:** 在不增加运行时开销的情况下，扩展类型功能。

**DerefMut**

- **可变智能指针:** 如 `Cell` 和 `RefCell`，允许在不可变环境中修改数据。
- **自定义集合类型:** 实现类似 `Vec` 的接口，支持元素修改。
- **状态管理:** 在结构体内部管理可变状态。

**注意事项**

- 一个类型可以同时实现 `Deref` 和 `DerefMut`。

- `DerefMut` 需要 `Deref`，因为可变借用隐含着不可变借用。

- 选择使用哪个 trait 取决于你的需求：如果只需要读取数据，使用 `Deref`；如果需要修改数据，使用 `DerefMut`。

### DerefMut例子

以下是一些展示 DerefMut 用法的 Rust 例子：

**1. 自定义可变智能指针**

```rust
use std::ops::{Deref, DerefMut};

struct MyBox<T>(T);

impl<T> Deref for MyBox<T> {
    type Target = T;

    fn deref(&self) -> &Self::Target {
        &self.0
    }
}

impl<T> DerefMut for MyBox<T> {
    fn deref_mut(&mut self) -> &mut Self::Target {
        &mut self.0
    }
}

fn main() {
    let mut x = 5;
    let mut my_box = MyBox(x);

    // 使用 * 运算符修改底层数据
    *my_box = 10; 

    println!("x: {}", x); // 输出: x: 10
}
```

**2. 自定义集合类型**

```rust
use std::ops::{Deref, DerefMut};

struct MyVec<T> {
    data: Vec<T>,
}

impl<T> Deref for MyVec<T> {
    type Target = [T];

    fn deref(&self) -> &Self::Target {
        &self.data
    }
}

impl<T> DerefMut for MyVec<T> {
    fn deref_mut(&mut self) -> &mut Self::Target {
        &mut self.data
    }
}

fn main() {
    let mut my_vec = MyVec { data: vec![1, 2, 3] };

    // 使用索引修改元素
    my_vec[0] = 10; 

    // 使用 Vec 方法
    my_vec.push(4);

    println!("{:?}", my_vec); // 输出: [10, 2, 3, 4]
}
```

**3. 状态管理**

```rust
use std::ops::{Deref, DerefMut};

struct Counter {
    count: usize,
}

impl Deref for Counter {
    type Target = usize;

    fn deref(&self) -> &Self::Target {
        &self.count
    }
}

impl DerefMut for Counter {
    fn deref_mut(&mut self) -> &mut Self::Target {
        &mut self.count
    }
}

fn main() {
    let mut counter = Counter { count: 0 };

    // 使用 * 运算符修改计数
    *counter += 1;

    println!("Count: {}", *counter); // 输出: Count: 1
}
```

这些例子展示了 DerefMut 如何使自定义类型像可变引用一样工作，从而简化代码并提供更自然的接口。