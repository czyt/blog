---
title: "Rust学习笔记2023-2024"
date: 2023-12-06
tags: ["rust"]
draft: false
---

## 基础

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

