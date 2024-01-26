---
title: "在 Rust 中使用 Serde"
date: 2024-1-25
tags: ["rust"]
draft: false
---

>本文原文链接为 https://www.shuttle.rs/blog/2024/01/23/using-serde-rust 。大部分使用机器翻译，个人对机器翻译内容进行了部分润色。

![Cover image](https://www.shuttle.rs/_next/image?url=%2Fimages%2Fblog%2Fserde-rust-thumb.png&w=1920&q=75)

在本文中，我们将讨论 Serde、如何在 Rust 应用程序中使用它以及一些更高级的提示和技巧。

##  什么是serde？

`serde` Rust create用于高效地序列化和反序列化多种格式的数据。它通过提供两个可以使用的trait来实现这一点，恰当地命名为 `Deserialize` 和 `Serialize` 。作为生态系统中最著名的 crate 之一，它目前支持 20 多种类型的序列化（反序列化）。

首先，您需要将 crate 安装到您的 Rust 应用程序中：

```bash
cargo add serde
```

##  使用serde

### 反序列化和序列化数据

序列化和反序列化数据的简单方法是添加 serde `derive` 功能。这会添加一个宏，您可以使用它来自动实现 `Deserialize` 和 `Serialize` - 您可以使用 `--features` 标志（ `-F` 来实现）短的）：

```bash
cargo add serde -F derive
```

然后我们可以将宏添加到我们想要实现 `Deserialize` 或 `Serialize` 的任何struct体或enum(枚举)中：

```rust
use serde::{Deserialize, Serialize};

#[derive(Deserialize, Serialize)]
struct MyStruct {
    message: String,
    // ... the rest of your fields
}
```

这允许我们使用任何支持 `serde` 的包在所述格式之间进行转换。作为示例，让我们使用 `serde-json` 与 JSON 格式相互转换：

```rust
use serde_json::json;
use serde::{Deserialize, Serialize};

#[derive(Deserialize, Serialize)]
struct MyStruct {
    message: String,
}

fn to_and_from_json() {
    let json = json!({"message": "Hello world!"});
    let my_struct: MyStruct = serde_json::from_str(&json).unwrap();

    assert_eq!(my_struct, MyStruct { message: "Hello world!".to_string());

    assert!(serde_json::to_string(my_struct).is_ok());
}
```

如果您有兴趣在 Rust 应用程序中使用 `serde-json` ，我们有一篇讨论 JSON 解析库的文章，您可以在[此处](https://www.shuttle.rs/blog/2024/01/18/parsing-json-rust)查看。

我们还可以对许多源进行反序列化和序列化，包括文件流 I/O、JSON 字节数组等等！

### 手动实现反序列化和序列化

为了更好地理解 `serde` 在底层是如何工作的，我们还可以手动实现 `Deserialize` 和 `Serialize` 。这相当复杂，但现在我们将坚持一个简单的实现。下面是序列化 `i32` 基元类型的简单实现：



```rust
use serde::{Serializer, Serialize};

impl Serialize for i32 {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: Serializer,
    {
        serializer.serialize_i32(*self)
    }
}
```

为了能够转换类型， `serde` 内部要求我们使用实现 `Serializer` 的类型。要为不直接是原语的类型实现 `Serialize` ，我们可以通过序列化为原语来扩展它，然后从原语转换为我们想要的任何类型。如果我们想要对struct进行自定义序列化，我们也可以使用 `SerializeStruct` trait来执行相同的操作：

```rust
use serde::ser::{Serialize, Serializer, SerializeStruct};

struct Color {
    r: u8,
    g: u8,
    b: u8,
}

impl Serialize for Color {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: Serializer,
    {
        // 3 is the number of fields in the struct.
        let mut state = serializer.serialize_struct("Color", 3)?;
        state.serialize_field("r", &self.r)?;
        state.serialize_field("g", &self.g)?;
        state.serialize_field("b", &self.b)?;
        state.end()
    }
}
```

请注意，要序列化字段，字段类型还需要实现 `Serialize` 。如果您有未实现 `Serialize` 的自定义类型，则需要实现 `Serialize` 或使用 `Serialize` 派生宏（如果struct体/enum(枚举)type 包含所有实现 `Serialize` 的类型）。

`Deserialize` trait有点不同，并且实现起来要复杂一些。为了能够反序列化为类型，类型本身需要实现 `Sized` 这意味着有许多类型不能使用此trait（例如 `&str` ），因为它们是无尺寸类型。要反序列化类型，您还需要使用实现 `Visitor` trait的类型。

`Visitor` trait使用 Rust 中的 Visitor 设计模式。这意味着它封装了一种对相同大小的对象集合进行操作的算法。它允许您编写多种不同的算法来操作数据，而无需更改任何原始功能。您可以在[这里](https://rust-unofficial.github.io/patterns/patterns/behavioural/visitor.html)了解更多相关信息。

下面是一个 `MessageVisitor` 类型的示例，该类型尝试将多种类型反序列化为 String：

```rust
use std::fmt;

use serde::de::{self, Visitor};

struct MessageVisitor;

impl<'de> Visitor<'de> for MessageVisitor {
    type Value = String;

    fn expecting(&self, formatter: &mut fmt::Formatter) -> fmt::Result {
        formatter.write_str("A message that can either be deserialized from an i32 or String")
    }

    fn visit_string<E>(self, value: String) -> Result<Self::Value, E>
    where
        E: de::Error,
    {
        Ok(value)
    }

    fn visit_str<E>(self, value: &str) -> Result<Self::Value, E>
    where
        E: de::Error,
    {
        Ok(value.to_owned())
    }

    fn visit_i32<E>(self, value: i32) -> Result<Self::Value, E>
    where
        E: de::Error,
    {
        Ok(value.to_string())
    }
}
```

正如您所看到的，实现的代码量相当大！然而，它也使我们能够使实现变得更加简单。通过实现 `Visitor` trait，我们可以将实现它的类型传递给 `Deserialize` 方法，然后将 JSON 反序列化到我们的struct中：

```rust
use serde::{Deserialize, Deserializer};

impl<'de> Deserialize<'de> for MyStruct {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: Deserializer<'de>,
    {
		// note: don't use unwrap in production!
        let message = deserializer.deserialize_string(MessageVisitor).unwrap();
        Ok(Self { message })
    }
}
```

您还可以在[这里](https://serde.rs/deserialize-struct.html)找到有关反序列化struct的文档。但是，一般来说，建议您使用 `derive` 功能宏，因为手动实现（如页面本身所示）相当大。该实现主要涉及使用访问者来访问映射或序列，然后迭代元素以将其反序列化。

###  使用 serde 属性

当涉及到 serde 时，crate 还具有许多有用的属性宏，我们可以在类型上使用它们，以允许在反序列化字段或序列化为struct时进行字段重命名等操作。最好的例子之一是当您与用某种语言编写的 API 进行交互时，该语言的键可能是 Rust 中的保留关键字。您可以添加 `#[serde(rename)]` 属性宏，如下所示：

```rust
use serde::{Deserialize, Serialize};

#[derive(Deserialize, Serialize)]
pub struct MyStruct {
    #[serde(rename = "type")]
    kind: String
}
```

这可以让您解决这个问题！

您还可以使用 `rename_all` 属性将所有字段重命名为另一个大小写：

```rust
use serde::{Deserialize, Serialize};

#[derive(Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct MyStruct {
    my_message: String
}
```

现在，当您序列化此struct时， `my_message` 应该自动变成 `myMessage` ！非常适合使用以其他语言或不同约定编写的 API。

如果您不想将字段包装在 `Option` 中，您还可以使用 `#[serde(default)]` 实现默认值。这只是允许用默认值填充字段，而不是自动出错。您还可以使用 `#[serde(default = "path")]` 来指向提供自动默认值的函数。例如，这个struct体和函数：

```rust
use serde::{Deserialize, Serialize};

#[derive(Deserialize, Serialize)]
pub struct MyStruct {
    #[serde(path = "my_function")]
    my_message: String,
}

fn my_function() -> String {
    "Hello world!".to_string()
}
```

`serde` 还提供其他有用的属性，例如能够在struct顶部使用 `#[serde(deny_unknown_fields)]` 拒绝未知字段。这使您可以确保序列化和反序列化时struct完全按原样。

### 反序列化和序列化enum(枚举)

让我们来研究一下这种enum(枚举)类型：

```rust
use serde::{Deserialize, Serialize};

#[derive(Deserialize, Serialize)]
enum MyEnum {
    Data { id: String, data: Value },
    SomeOtherData { id: i32, name: String }
}
```

请注意，在与该enum(枚举)之间进行转换时，可以有两个选项：

- 一个名为 `id` 的字符串字段和一个键值为 `data` 的 JSON 值（可以是一个映射、一个值或 `Json` 值可以容纳的任何内容）
- 一个名为 `id` 的 `i32` 字段和一个名为 `name` 的 `String` 字段

然后，您可以匹配enum(枚举)变量，以便进一步处理。

将第一个enum(枚举)变量写成 JSON 格式后，可以看到它应该与此相对应：

```json
{
    "Data": {
        "id": "your_id_here",
        "data": { .. }
    }
}
```

这类数据是 "外部标记 "数据--也就是说，数据的trait是位于 JSON 对象的外部标识符。我们可以添加内联标记，这样标识符就会位于crate 的内部--让我们来看看这将会是什么样子：

```rust
use serde::{Deserialize, Serialize};

#[derive(Deserialize, Serialize)]
#[serde(tag = "type")]
enum MyEnum {
    Data { id: String, data: Value },
    SomeOtherData { id: i32, name: String }
}
```

现在的 JSON 表示法是这样的

```json
{
    "type": "Data",
    "id": "your_id_here",
    "data": { .. }
}
```

有兴趣阅读更多吗？ `serde` 文档中有一个关于标记的页面，您可以在[这里](https://serde.rs/enum-representations.html)找到。

## 与 Serde 配合使用属性

### serde_with

`serde_with` 是一个提供自定义反序列化/序列化的属性工具，可与 `serde` 的 `with` 注解一起使用。通常情况下，你可以定义一个供反序列化/序列化使用的模块，该模块紧跟用于自定义反序列化/序列化的自定义模块：

```rust
#[derive(Deserialize, Serialize)]
pub struct MyStruct {
    #[serde(with = "my_module")]
    my_message: String
}
```

使用 `serde_with` 时，它的工作原理是用一个名为 `serde_as` 的新注解替换 `with` 注解。有了这个新的属性宏，你可以做很多事情：

- 使用 `Display` 和 `FromStr` 特质对类型进行序列化。
- 支持大于 32 个元素的数组。
- 跳过序列化空选项类型。
- 将逗号分隔的列表反序列化为 `Vec<String>` 。

要使用 `serde_with` ，您需要手动或使用以下命令将其添加到 Cargo.toml 中：

```bash
cargo add serde_with
```

然后您需要将 `serde_as` 添加到您想要使用它的类型，如下所示：

```rust
use serde_with::{serde_as, DisplayFromStr};
#[serde_as]
#[derive(Deserialize, Serialize)]
struct MyStruct {
    // Serialize with Display, deserialize with FromStr
    #[serde_as(as = "DisplayFromStr")]
    my_number: u8,
}
```

该struct允许您与字符串相互转换，但 Rust struct中的类型本身为 `u8` ！非常有用，对吧？

这个crate还附带了一个[指南](https://docs.rs/serde_with/3.5.0/serde_with/guide/index.html)，您可以使用它来充分利用 `serde_with` 。总的来说，这是 `serde` 的一个强大的crate伙伴 。

###  Serde_bytes

`serde_bytes` 是一个允许优化处理 `&[u8]` 和 `Vec<u8>` 类型的包 - 而 `serde` 本身能够处理这些类型，某些格式可以更有效地反/序列化。使用起来非常简单 - 您只需将其添加到 Cargo.toml 中，然后通过 `#[serde(with = "serde_bytes")]` 注释添加它，如下所示：



```rust
use serde::{Deserialize, Serialize};

#[derive(Deserialize, Serialize)]
struct MyStruct {
    #[serde(with = "serde_bytes")]
    byte_buf: Vec<u8>,
}
```

总的来说，这是一个简单且易用的 crate，无需太多知识即可提高性能。

##  总结

我希望您喜欢阅读有关 Serde 的文章！它是一个非常强大的 Rust 包，构成了大多数 Rust 应用程序的支柱。

 阅读更多：

- 在[此处](https://www.shuttle.rs/blog/2023/12/13/using-rocket-rust)阅读有关如何开始使用 Rocket Web 框架的更多信息。
- 在[此处](https://www.shuttle.rs/blog/2024/01/18/parsing-json-rust)阅读有关使用 JSON 解析器的更多信息。