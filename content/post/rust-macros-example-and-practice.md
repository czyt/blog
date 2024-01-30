---
title: "Rust宏示例和实践【译】"
date: 2024-01-28
tags: ["rust"]
draft: false
---

> 原文链接为 https://earthly.dev/blog/rust-macros/ ，文章大部分使用机器翻译，小部分进行了文字调整。

**本文深入探讨 Rust 宏的强大功能和多功能性。 Earthly 保证构建过程与您创建的宏一样强大。了解更多关于地球的信息。**

在 Rust 中，宏是使用通常称为元编程的技术生成其他 Rust 代码的代码片段。宏在编译期间被扩展，并且宏的输出被插入到程序的源代码中。

最著名的宏示例是 `println!` 。尽管它看起来像函数并且使用起来也像函数，但它实际上在编译过程中进行了扩展，并且 `println!` 调用被替换为更复杂的实现代码。

在本文中，您将看到一些宏的实际示例，并了解一些有关如何最好地使用它们的提示和技巧。

##  Rust 宏基础知识

![Macros](https://earthly.dev/blog/assets/images/rust-macros/macro.png)

> 本教程假设您熟悉 Rust 编程的基础知识。

在 Rust 中，有两种类型的宏：声明性宏和过程性宏。逐一查看：

###  声明性宏

声明性宏是最简单的宏类型，由 `macro-rules!` 宏定义。它们的外观和行为与 `match` 表达式类似。

`match` 表达式将表达式作为输入，并将其与一组预定义模式进行匹配并运行相应的代码。类似地，声明性宏将一段 Rust 源代码作为输入，将源代码与一组预定义的结构进行匹配，并且在成功匹配时，将代码替换为与匹配模式关联的代码。

以下示例显示了正在运行的声明性宏：

```rust
declarative_macro.rs//declarative_macro.rs

macro_rules! greetings {
    ($x: expr) => {
        println!("Hello, {}", $x);
    };
}

fn main() {
    greetings!("Earthly"); // Prints "Hello, Earthly"
}
```

这里，宏被命名为 `greetings` 并用 `macro_rules!` 定义。在宏主体中，只有一种模式： `($x: expr) => { ... }` 。此模式匹配任何 Rust 表达式（由 `expr` 类型表示）并将其存储在变量 `$x` 中。匹配模式后， `$x` 占位符将替换为 `4x` 的值（在本例中为 `"Earthly"` ），并且宏的输出变为 `println!("Hello, {}", "Earthly");` 。

输入代码在编译期间被结果代码替换，这意味着 `greetings!("Earthly");` 行在编译期间被转换为 `println!("Hello, {}", "Earthly");` 。

可以有多个模式，就像 `match` 表达式一样：

```rust
declarative_macro.rs//declarative_macro.rs

macro_rules! greetings {
    (struct $x: ident {}) => {
        println!("Hello from struct {}", stringify!($x));
    };
    ($x: expr) => {
        println!("Hello, {}", $x);
    };
}

fn main() {
    greetings!("Earthly"); // Prints "Hello, Earthly"
    greetings! {
        struct G {} // Prints "Hello from struct G"
    };
}
```

在此示例中，在 `greetings` 宏中添加了另一个臂，它与 `struct X {}` 形式的代码匹配，并将其替换为 `println!("Hello from struct {}", "X");` 。 `ident` 类型用于指示 `$x` 是标识符（结构体的名称）。对于任何其他代码，另一条臂的匹配就像在前面的示例中一样。

此外，还可以使用特殊语法来匹配重复的表达式：

```rust
declarative_macro.rs//declarative_macro.rs

macro_rules! add {
    ($a:expr)=>{
        $a
    };
    ($a:expr,$b:expr)=>{
        $a+$b
    };
    ($a:expr,$($b:tt)*)=>{
        $a+add!($($b)*)
    }
}
```

`add!` 宏具有三个分支：第一个分支匹配单个表达式并返回相同的表达式。第二个分支匹配两个逗号分隔的表达式并返回它们的和。在第三个臂中，第一个输入与 `$a` 匹配。下一个（或多个输入）与 `$b` 匹配，其中 `*` 表示该模式应匹配 `*` 之前的任何内容零次或多次出现。

在宏体中，递归地使用 `add!` 来添加 `$b` 中的输入。这里， `*` 表示应该为arm中与 `$()*` 匹配的每个部分生成代码。这意味着宏调用 `add(1,2,3)` 扩展为 `add(1, add(2,3))` ，进一步扩展为 `add(1, add(2, add(3)))` 最后变为 `1+2+3` 。

这里， `$b` 的类型是 `tt` ，它代表一个令牌树。

您已经看到了 `expr` 和 `ident` 类型。以下是您可以使用的其他一些类型：

- `item` ：一个项目；例如，函数或结构体
- `block` ：大括号内的语句块和/或表达式
-  `stmt` ：声明
-  `pat` 一个模式
- `expr` ：一个表达式
-  `ty` ：一种类型
- `ident` ：标识符
- `path` ：路径（例如 `::foo::bar` ）
- `meta` ：位于 `#[...]` 和 `#![...]` 属性内的元项
- `tt` ：单个令牌树
- `vis` ：可能为空的可见性限定符（例如 `pub` ）

您可以在 Rust 参考文档中找到完整的类型列表。

声明性宏易于编写和使用，但其功能仅限于基于宏输入的模式匹配和代码替换。他们缺乏对代码执行复杂操作的能力。

请记住，声明宏时，不能在宏名称后面写感叹号（ `!` ），但在调用宏时必须写感叹号。

###  程序宏

过程宏是声明性宏的一大进步。与它们的声明式表兄弟一样，它们可以访问 Rust 代码，但过程宏可以对代码进行操作（类似于函数）并生成新代码。

过程宏的定义与函数类似，它接收一个或两个 `TokenStream` 作为输入并生成另一个 `TokenStream` ，然后由编译器将其插入到源代码中。 `TokenStream` 是组成程序源代码的抽象标记序列。这意味着过程宏可以对 Rust 源代码的抽象语法树（AST）进行操作，使其更加灵活和强大。

程序宏分为三种类型：

1. [ 自定义派生宏](https://doc.rust-lang.org/reference/procedural-macros.html#derive-macros)
2. [ 类似属性的宏](https://doc.rust-lang.org/reference/procedural-macros.html#attribute-macros)
3. [ 类似函数的宏](https://doc.rust-lang.org/reference/procedural-macros.html#function-like-procedural-macros)

每个过程宏都必须在自己的包中定义，需要将其作为依赖项添加到使用该宏的任何项目中。例如，必须将以下内容添加到定义过程宏的项目的 `Cargo.toml` 文件中：

Cargo.toml

```toml
[lib]
proc-macro = true
```

该宏被定义为具有 `#[proc_macro_derive]` 、 `#[proc_macro_attribute]` 或 `#[proc_macro]` 属性的函数，具体取决于它是派生宏、类似属性的宏还是类似函数的宏。

在本文中，您将简单概述三种类型的过程宏。有关编写这些宏的分步教程，您可以参考 Rust 文档。

####  派生宏

派生宏允许您为 `derive` 属性创建新输入，该属性可以对结构、联合和枚举进行操作以创建新项。以下示例显示了实现 `MyTrait` 特征的派生宏：

lib.rs

```rust
//macro_demo/macro_demo_derive/src/lib.rs

use proc_macro::TokenStream;
use quote::quote;
use syn;

/*
Definition of MyTrait:

pub trait MyTrait {
    fn hello();
}
*/

#[proc_macro_derive(MyMacro)]
pub fn my_macro_derive(input: TokenStream) -> TokenStream {
    let syn::DeriveInput { ident, .. } = syn::parse_macro_input!{input};

    let gen = quote! {
        impl MyTrait for #ident {
            fn hello() {
                println!("Hello from {}", stringify!(#ident));
            }
        }
    };
    gen.into()
}
```

以下是一些需要注意的重要事项：

- `#[proc_macro_derive(MyMacro)]` 属性表示以下函数是一个派生宏，其名称为 `MyMacro` 。
- 该函数接收其输入作为 `TokenStream` 。
- `syn` 箱用于将输入解析为 `DeriveInput` 并提取项目的标识符。
- 标识符名称与 `#` 符号一起使用，该符号将其替换为 `ident` 的值，由 `quote` 箱提供。
- `quote` 包用于从输出代码生成 `TokenStream` 。

该宏可以如下使用：

main.rs

```rust
//procedural_macro/src/main.rs

#[derive(MyMacro)]
struct MyStruct;

fn main() {
    MyStruct::hello();
}
```

####  类似属性的宏

类似属性的宏定义了一个新的外部属性，可以附加到项目上，例如函数定义和结构定义。

属性宏使用 `#[proc_macro_attribute]` 定义，并接收两个 `TokenStream` 参数。第一个参数包含传递给属性宏的输入，第二个 `TokenStream` 包含它将操作的项目。

在以下示例中，定义了一个名为 `trace` 的宏，该宏对函数定义（由 `syn` 包中的 `ItemFn` 类型表示）进行操作。它打印函数的名称和传递给属性的参数，并用函数本身替换函数定义：

lib.rs

```rust
//macro_demo/macro_demo_derive/src/lib.rs

use proc_macro::TokenStream;
use quote::quote;
use syn::{parse_macro_input, ItemFn};

#[proc_macro_attribute]
pub fn trace(_attr: TokenStream, item: TokenStream) -> TokenStream {
    let input = parse_macro_input!(item as ItemFn);
    println!("{} defined", input.sig.ident);
    println!("Args received: {}", _attr.to_string());
    TokenStream::from(quote!(#input))
}
```

可以使用该宏，如下所示：

main.rs

```rust
//procedural_macro/src/main.rs

#[trace]
fn foo() {}
/* Output:
foo defined
Args received:
*/

#[trace(some_arg)]
fn bar() {}
/* Output:
bar defined
Args received: some_arg
*/

#[trace(some_arg1, some_arg2)]
fn baz() {}
/* Output:
baz defined
Args received: some_arg1, some_arg2
*/
```

这将打印注释中所示的输出。请注意，由于宏在编译期间展开并且没有可见的输出（它保持函数定义不变），因此您只能在编译期间看到此输出。

####  类似函数的宏

类函数宏是使用宏调用运算符 ( `!` ) 调用的过程宏。它们是用 `#[proc_macro]` 属性定义的，并接收一个 `TokenStream` 输入，这是传递给宏调用的代码。整个宏调用将替换为宏的输出。

以下示例定义了一个类似函数的宏，该宏仅打印其输入，然后用函数定义替换宏调用：

lib.rs

```rust
//macro_demo/macro_demo_derive/src/lib.rs

use proc_macro::TokenStream;

#[proc_macro]
pub fn print_and_replace(input: TokenStream) -> TokenStream {
    println!("Inputs: {}", input.to_string());
    "fn add(a:i32, b:i32) -> i32 { a+ b }".parse().unwrap()
}
```

这是它的使用方式：

main.rs

```rust
//procedural_macro/src/main.rs

fn main() {
    print_and_replace!(100); // Output: "Inputs: 100"
    add(1,2); // Not an error as the macro call brings 'add' into scope
}
```

##  宏卫生

在宏的上下文中，卫生是指宏是否受到其周围的外部代码的影响。卫生宏适用于所有上下文，并且不受调用站点周围代码的影响。

一般来说，声明性宏是部分卫生的。声明性宏对于局部变量和标签来说是卫生的，但对于其他任何东西来说却不是。考虑以下示例：

lib.rs

```rust
macro_rules! foo {
    ($x: expr) => {
        a + $x
    }
}
fn main() {
    let a = 42;
    println!("{}", foo!(5));
}
```

宏展开后，前面的代码应该变成如下：

lib.rs

```rust
fn main() {
    let a = 42;
    println!("{}", a + 5);
}
```

但是，此代码无法编译，因为宏是卫生的，并且宏无法使用宏外部的 `a` 定义。

相比之下，以下是宏不卫生的场景：

lib.rs

```rust
//// Definitions in the `my_macro` crate.
#[macro_export]
macro_rules! foo {
    () => { bar!() }
}

#[macro_export]
macro_rules! bar {
    () => { () }
}

//// Usage in another crate.
use my_macro::foo;

fn unit() {
    foo!();
}
```

此代码无法编译，因为调用 `foo` 时未导入 `my_macro::bar` 。这是周围代码（或缺少代码）影响宏的情况。解决方案是使用 `$crate::bar` ：

lib.rs

```rust
macro_rules! foo {
    () => { $crate::bar!() }
}
```

程序宏总是不卫生的。它们的行为就好像它们是内联编写的而不是宏调用，因此会受到周围代码的影响。

## 宏的实际例子

现在您已经了解了如何定义和使用宏，您可以查看一些现实生活中的宏示例。以下示例均取自流行的板条箱，让您感受真实的宏。所有示例代码都经过显着简化，可帮助您轻松掌握。

###  循环展开

可以使用声明性宏通过递归来实现简单的循环展开。以下 `unroll_loop` 宏可以展开最多四次迭代的循环：

lib.rs

```rust

macro_rules! unroll_loop {
    (0, |$i:ident| $s:stmt) => {};
    (1, |$i:ident| $s:stmt) => {{ let $i: usize = 0; $s; }};
    (2, |$i:ident| $s:stmt) => {{ unroll!(1, |$i| $s); let $i: usize = 1; \
    $s; }};
    (3, |$i:ident| $s:stmt) => {{ unroll!(2, |$i| $s); let $i: usize = 2; \
    $s; }};
    (4, |$i:ident| $s:stmt) => {{ unroll!(3, |$i| $s); let $i: usize = 3; \
    $s; }};
    // ...
}

fn main() {
    unroll_loop!(3, |i| println!("i: {}", i));
}
```

由于声明性宏受到模式匹配的限制，无法对其输入执行操作，因此 `unroll_loop` 宏在无法动态设置递归的意义上受到限制。您必须为要用作循环索引的每个整数显式编写案例。解决这个问题的方法是使用过程宏，但由于显而易见的原因，这更加复杂。

这是 seq-macro 箱中的一个真实示例：

lib.rs

```rust
seq!(N in 0..=10 {
    println!("{}", N);
});
```

### JSON解析和序列化

Serde JSON 包使用声明性宏 `json` 来解析和序列化 JSON。 `json` 宏提供了一个熟悉的接口来创建 JSON 对象：

lib.rs

```rust
let user = json!({
    "id": 1,
    "name": "John Doe",
    "age": 42
});

println!("Name of user: {}", user["name"]);
```

`json` 是一个声明性宏，如下所示：

lib.rs

```rust
#[macro_export(local_inner_macros)]
macro_rules! json {
    // Hide distracting implementation details from the generated rustdoc.
    ($($json:tt)+) => {
        json_internal!($($json)+)
    };
}
```

`json` 匹配零个或多个 `tt` 类型的表达式（即标记树）并调用 `json_internal` 宏。使用 `local_inner_macro` 会自动导出内部 `json_internal` 宏，因此不需要在调用站点显式导入它。这是使用 `$crate` 的替代方法，如前面有关卫生的部分中所述。

`json_internal` 宏是神奇发生的地方。它与您之前看到的 `add` 宏类似，因为它实现了一个 TT muncher，可以生成 `vec![]` 元素：

lib.rs

```rust
macro_rules! json_internal {
    ///////////////////////////////////////////////////////////
    // TT muncher for parsing the inside of an array [...]. \
    Produces a vec![...]
    // of the elements.
    //
    // Must be invoked as: json_internal!(@array [] $($tt)*)
    ///////////////////////////////////////////////////////////

    // Done with trailing comma.
    (@array [$($elems:expr,)*]) => {
        json_internal_vec![$($elems,)*]
    };

    // Done without trailing comma.
    (@array [$($elems:expr),*]) => {
        json_internal_vec![$($elems),*]
    };

    // Next element is `null`.
    (@array [$($elems:expr,)*] null $($rest:tt)*) => {
        json_internal!(@array [$($elems,)* json_internal!(null)] $($rest)*)
    };

    // Next element is `true`.
    (@array [$($elems:expr,)*] true $($rest:tt)*) => {
        json_internal!(@array [$($elems,)* json_internal!(true)] $($rest)*)
    };

    ...
}
```

有关更多详细信息，请查看源代码。

###  服务器路由创建

流行的 Rocket 框架使用类似属性的过程宏来创建服务器路由。有几个与 HTTP 动词对应的宏，例如 `get` 、 `post` 和 `put` 。您可以将它们与函数定义一起使用，以注释向该路由发出 HTTP 请求时要调用的函数：

lib.rs

```rust
#[get("/hello")]
fn hello() -> String {
    "Hello, World!"
}
```

这些宏是使用另一个辅助宏定义的 - 一个名为 `route_attribute` 的声明性宏：

lib.rs

```rust
macro_rules! route_attribute {
    ($name:ident => $method:expr) => (
        #[proc_macro_attribute]
        pub fn $name(args: TokenStream, input: TokenStream) -> TokenStream {
            emit!(attribute::route::route_attribute($method, args, input))
        }
    )
}
```

实际属性定义如下：

lib.rs

```rust
route_attribute!(route => None);
route_attribute!(get => Method::Get);
route_attribute!(put => Method::Put);
route_attribute!(post => Method::Post);
route_attribute!(delete => Method::Delete);
route_attribute!(head => Method::Head);
route_attribute!(patch => Method::Patch);
route_attribute!(options => Method::Options);
```

例如， `route_attribute` 宏展开后， `get` 宏定义如下：

lib.rs

```rust
#[proc_macro_attribute]
pub fn get(args: TokenStream, input: TokenStream) -> TokenStream {
    emit!(attribute::route::route_attribute(Method::Get, args, input))
}
```

`emit` 本身是一个声明性宏，它生成最终输出：

lib.rs

```rust
macro_rules! emit {
    ($tokens:expr) => ({
        use devise::ext::SpanDiagnosticExt;

        let mut tokens = $tokens;
        if std::env::var_os("ROCKET_CODEGEN_DEBUG").is_some() {
            let debug_tokens = proc_macro2::Span::call_site()
                .note("emitting Rocket code generation debug output")
                .note(tokens.to_string())
                .emit_as_item_tokens();

            tokens.extend(debug_tokens);
        }

        tokens.into()
    })
}
```

###  自定义代码解析

SQLx 宏使用声明性宏和过程性宏的组合来在编译期间解析和验证 SQL 查询，如下所示：

lib.rs

```rust
let usernames = sqlx::query!(
        "
SELECT username
FROM users
GROUP BY country
WHERE country = ?
        ",
        country
    )
    .fetch_all(&pool)
    .await?;
```

`query` 宏是在此链接中定义的声明性宏：

lib.rs

```rust
macro_rules! query (
    ($query:expr) => ({
        $crate::sqlx_macros::expand_query!(source = $query)
    });
    ($query:expr, $($args:tt)*) => ({
        $crate::sqlx_macros::expand_query!(source = $query, \
        args = [$($args)*])
    })
);
```

`expand_query` 宏是在此链接中定义的类似函数的过程宏：

lib.rs

```rust
pub fn expand_query(input: TokenStream) -> TokenStream {
    let input = syn::parse_macro_input!(input as query::QueryMacroInput);

    match query::expand_input(input, FOSS_DRIVERS) {
        Ok(ts) => ts.into(),
        Err(e) => {
            if let Some(parse_err) = e.downcast_ref::<syn::Error>() {
                parse_err.to_compile_error().into()
            } else {
                let msg = e.to_string();
                quote!(::std::compile_error!(#msg)).into()
            }
        }
    }
}
```

## 有效使用宏的技巧

![Tips](https://earthly.dev/blog/assets/images/rust-macros/tips.png)

了解如何有效地使用宏至关重要。为此，以下提示可以提供帮助。

### 知道何时使用宏与函数

尽管宏和函数的行为相似，但宏更强大，因为它们可以生成 Rust 代码。然而，由于宏的强大功能，它们比函数更难编写、读取和维护。

此外，宏在编译期间会扩展，导致二进制文件的大小和编译时间增加。因此，在使用宏时必须保持克制，仅在函数无法提供您所需的解决方案时才使用宏。

以下是宏可能优于函数的一些场景：

- 创建一种扩展 Rust 语法的领域特定语言 (DSL)。
- 将计算和检查移至编译时。例如，在编译期间验证 SQL 查询，以便无需在运行时执行检查，从而减少运行时开销。
- 编写重复或样板代码。例如，您可以使用派生宏来自动实现特征，这样您就不必手动实现它。

### 确保宏可读且可维护

由于宏在 Rust 代码上运行，如果您不小心，它们可能会难以阅读和维护。对于程序宏来说尤其如此，因为它们更加复杂。

丰富的文档是您的朋友。您还可以尝试通过将宏逻辑提取到单独的函数或宏来保持宏简单。 Rust 文档中的以下示例展示了这一点：

lib.rs

```rust
#[proc_macro_derive(HelloMacro)]
pub fn hello_macro_derive(input: TokenStream) -> TokenStream {
    // Construct a representation of Rust code as a syntax tree
    // that we can manipulate
    let ast = syn::parse(input).unwrap();

    // Build the trait implementation
    impl_hello_macro(&ast)
}
```

这里，实际的实现被提取到 `impl_hello_macro` 内部。这使实际的宏观保持精简和简单。

### 处理宏中的错误

由于宏本质上很复杂，因此最好提供完整的错误消息，清楚地表明出了什么问题，以及如果可能的话，如何修复它。为此，您可以在过程宏中使用 `panic` ：

lib.rs

```rust
#[proc_macro]
pub fn foo(tokens: TokenStream) -> TokenStream {
    panic!("Boom")
}
```

或者您可以使用 `compile_error` 宏，这会引发编译器错误：

lib.rs

```rust
macro_rules! give_me_foo_or_bar {
    (foo) => {};
    (bar) => {};
    ($x:ident) => {
        compile_error!("This macro only accepts `foo` or `bar`");
    }
}

give_me_foo_or_bar!(neither); // Error: \
"This macro only accepts `foo` or `bar`"
```

您还可以使用 `proc_macro_error` 包，它提供了强大的 API 来处理宏中的错误。

###  测试你的宏

与任何其他代码单元一样，宏需要经过彻底的测试。然而，通常的测试方法不适用于宏，因为它们是在编译时扩展的。

要测试您的宏，可以使用 enums crate。该板条箱提供了一个 `compile_fail` ，它预计 Rust 文件无法编译，并检查是否打印了正确的错误消息。提供了另一个 `pass` 函数，它确保给定的 Rust 文件成功编译。

您可以使用如下所示的crate：

lib.rs

```rust
#[test]
fn test_macro() {
    let t = trybuild::TestCases::new();
    t.compile_fail("tests/my_macro.rs");
}
```

这里，假设 `my_macro.rs` 以无效的方式调用某个宏。 `trybuild` 包确保错误的调用不会编译。如果您有一个名为 `tests/my_macro.stderr` 的文件，它会检查编译期间生成的错误消息是否与该文件的内容匹配。

##  结论

宏是 Rust 中的一项强大功能，用于代码操作和降低复杂性。在本教程中，您了解了声明性宏和过程宏、它们的语法、现实生活中的示例和效率技巧。

如果您像专业人士一样使用 Rust 宏，并寻找进一步简化开发流程的方法，那么您应该查看 Earthly。它提供了更流畅、可重复的构建，使其成为 Rust 开发工具箱中的一个有价值的工具。

在 [GitHub ](https://github.com/heraldofsolace/rust-macros-demo)上查找本教程的所有代码。如需进一步学习，请访问 [Rust 文档](https://doc.rust-lang.org/book/ch19-06-macros.html)、[The Little Book of Rust Macros](https://danielkeep.github.io/tlborm/book/README.html) 以及 [GitHub 上的更多实际示例](https://github.com/thepacketgeek/rust-macros-demo)。