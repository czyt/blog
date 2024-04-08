---
title: "enum_dispatch在rust中的简单使用"
date: 2024-04-08
tags: ["rust"]
draft: false
---

请先看下面这个例子：
```rust
enum Creatures {
    Dog(Dog),
    Cat(Cat),
}

trait Animal {
    fn make_sound(&self);
}

struct Dog;
struct Cat;

impl Animal for Dog {
    fn make_sound(&self) {
        println!("Bark!");
    }
}

impl Animal for Cat {
    fn make_sound(&self) {
        println!("Meow!");
    }
}

fn main() {
    let animals: Vec<Creatures> = vec![
        Creatures::Dog(Dog),
        Creatures::Cat(Cat),
    ];

    for animal in animals {
        match animal {
            Creatures::Dog(dog) => dog.make_sound(),
            Creatures::Cat(cat) => cat.make_sound(),
        }
    }
}
```

在 `main` 函数中，我们创建了一个名为 `animals` 的 `Vec<Creatures>` 向量，其中包含不同种类的生物。遍历 `animals` 向量时，使用 `match` 语句来确定每个生物的实际类型，然后调用相应实例的 `make_sound` 方法。

请注意，`match` 语句需确保覆盖 `Creatures` 枚举的所有变体。不使用 `enum_dispatch` 就会失去动态派发的好处，而且代码更加易于出错，特别是在枚举类型经常发生变化的情况下。因此，如果预期需要频繁处理多种不同的枚举变体，那么会比较繁琐，有没有好的解决方案呢？有的，我们今天要使用 `enum_dispatch` 通常是更明智的选择。

> [enum_dispatch](https://crates.io/crates/enum_dispatch) transforms your trait objects into concrete compound types, increasing their method call speed up to 10x.

`enum_dispatch` 是一个 Rust 的 crate，它为枚举类型提供了一种高效的动态分发机制。在 Rust 中，枚举（enum）是一种可以对不同类型的数据使用同一接口的强大工具。然而，标准的枚举使用涉及到通过模式匹配来处理不同的变体，这会导致运行时的分支预测不一定总是那么高效。

`enum_dispatch` crate 允许开发者用 trait 对象的方式来访问枚举的不同变体，达到与动态分发类似的效果，同时维护类型安全和无运行时开销。这通常会用在需要动态派发到不同实现的场景中，特别是当你有多个结构或枚举变体需要实现同一个 trait 时。

使用 `enum_dispatch` crate 之前需要在 `Cargo.toml` 文件中添加依赖：

```toml
[dependencies]
enum_dispatch = "0.3"
```

以下是 `enum_dispatch` 的一个使用示例：

首先，定义一个 trait 和一些实现了该 trait 的结构体：

```rust
trait Animal {
    fn make_sound(&self);
}

#[enum_dispatch(Animal)]
enum Creatures {
    Dog(Dog),
    Cat(Cat),
}

struct Dog;
struct Cat;

impl Animal for Dog {
    fn make_sound(&self) {
        println!("Bark!");
    }
}

impl Animal for Cat {
    fn make_sound(&self) {
        println!("Meow!");
    }
}
```

然后，给枚举添加 `enum_dispatch` 属性，它会自动生成转换代码，让我们能够以 trait 对象的方式调用不同的方法：

```rust
#[enum_dispatch]
enum Creatures {
    Dog, // 注意: 这里不用括号包裹类型
    Cat,
}

// 现在可以这样使用枚举变体
fn main() {
    let mut animals: Vec<Box<dyn Animal>> = vec![
        Box::new(Creatures::Dog(Dog)),
        Box::new(Creatures::Cat(Cat)),
    ];

    for animal in animals.iter() {
        animal.make_sound(); // 根据枚举的具体类型调用相应的方法
    }
}
```

在这个示例中，`Creatures` 枚举被作为一个通用的容器来持有任何 `Animal`，而 `enum_dispatch` crate 允许我们通过 `Box<dyn Animal>` 动态地调用 `make_sound` 方法，无需关心具体是 `Dog` 还是 `Cat`。这使得代码更加灵活和通用。