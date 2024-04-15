---
title: "使用rust操作mongodb"
date: 2024-04-15
tags: ["rust", "mongoDB"]
draft: false
---

## 准备工作

使用rust进行mongodb连接需要添加依赖，在Cargo.toml中添加下面的依赖

```toml
[dependencies]
mongodb="2"
serde = "1"
```

> 添加serde的原因是我们建模的时候需要用。

## 预备知识

### 连接数据库

下面是我们的本地数据库连接

```rust
 const CONNECT_STR:&str = "mongodb://czyt:czyt@192.168.1.21:27017";
```

然后使用连接字符串进行数据库连接

```rust
 let mut client_options = ClientOptions::parse_async(CONNECT_STR).await?;
        // Set the server_api field of the client_options object to Stable API version 1
        let server_api = ServerApi::builder()
            .version(ServerApiVersion::V1)
            .build();
        client_options.server_api = Some(server_api);
        // Create a new client and connect to the server
        let client = Client::with_options(client_options)?;
        // Send a ping to confirm a successful connection
        client.database("admin").run_command(doc! { "ping": 1 }, None).await?;
        println!("Pinged your deployment. You successfully connected to MongoDB!");
        Ok(())
```

### 数据库建模 

您可以使用任何实现 `serde` 包中的 `Serialize` 和 `Deserialize` 特征的 Rust 数据类型作为 `Collection` 的泛型类型参数实例。要实现 `Serialize` 和 `Deserialize` 特征，您必须在定义 Rust 类型之前包含以下 `derive` 属性：

```rust
#[derive(Serialize, Deserialize)]
```

以下代码定义了一个实现 `serde` 序列化特征的示例 `Vegetable` 结构：

```rust
#[derive(Serialize, Deserialize)]
struct Vegetable {
    name: String,
    category: String,
    tropical: bool,
}
```

#### 辅助函数

`serde` 包提供 `serialize_with` 和 `deserialize_with` 属性，它们将辅助函数作为值。这些辅助函数可自定义特定字段和变体的序列化和反序列化。要指定字段的属性，请在字段定义之前包含该属性：

```rust
#[derive(Serialize, Deserialize)]
struct MyStruct {
    #[serde(serialize_with = "<helper function>")]
    field1: String,
    // ... other fields
}
```

常见的`serde_helpers API `有下面这些，更多的你可以参考下相关文档。

##### 将字符串序列化为 ObjectId 

您可能希望将文档中的 `_id` 字段表示为结构中的十六进制字符串。要将十六进制字符串转换为 `ObjectId` BSON 类型，请使用 `serialize_hex_string_as_object_id` 辅助函数作为 `serialize_with` 属性的值。以下示例将 `serialize_with` 属性附加到 `_id` 字段，以便驱动程序将十六进制字符串序列化为 `ObjectId` 类型：

```rust
#[derive(Serialize, Deserialize)]
struct Order {
    #[serde(serialize_with = "serialize_hex_string_as_object_id")]
    _id: String,
    item: String,
}
```

struct定义

```rust
let order = Order {
    _id: "6348acd2e1a47ca32e79f46f".to_string(),
    item: "lima beans".to_string(),
};
```

bson定义

```javascript
{
  "_id": { "$oid": "6348acd2e1a47ca32e79f46f" },
  "item": "lima beans"
}
```

##### 将 DateTime 序列化为字符串 

您可能希望将文档中的 `DateTime` 字段值表示为 BSON 中的 ISO 格式字符串。要指定此转换，请使用 `serialize_bson_datetime_as_rfc3339_string` 辅助函数作为附加到具有 `DateTime` 值的字段的 `serialize_with` 属性的值。以下示例将 `serialize_with` 属性附加到 `delivery_date` 字段，以便驱动程序将 `DateTime` 值序列化为字符串：

```rust
#[derive(Serialize, Deserialize)]
struct Order {
    item: String,
    #[serde(serialize_with = "serialize_bson_datetime_as_rfc3339_string")]
    delivery_date: DateTime,
}
```

要查看驱动程序如何将示例 `Order` 结构序列化为 BSON，请从以下 Struct 和 BSON 选项卡中进行选择：

struct定义

```rust
let order = Order {
    item: "lima beans".to_string(),
    delivery_date: DateTime::now(),
};
```

bson定义

```javascript
{
  "_id": { ... },
  "item": "lima beans",
  "delivery_date": "2023-09-26T17:30:18.181Z"
}
```

##### 将 u32 序列化为 f64

您可能希望将文档中的 `u32` 字段值表示为 BSON 中的 `f64` 或 `Double` 类型。要指定此转换，请使用 `serialize_u32_as_f64` 辅助函数作为附加到具有 `u32` 值的字段的 `serialize_with` 属性的值。以下示例将 `serialize_with` 属性附加到 `quantity` 字段，以便驱动程序将 `u32` 值序列化为 `Double` 类型：

```rust
#[derive(Serialize, Deserialize)]
struct Order {
    item: String,
    #[serde(serialize_with = "serialize_u32_as_f64")]
    quantity: u32,
}
```

> `u32` 值的 BSON `Double` 表示形式与原始值相同。

#### 其他属性和模块

除了辅助函数之外， `bson` 库还提供了处理序列化和反序列化的模块。要选择在特定字段或变体上使用的模块，请将 `with` 属性的值设置为模块的名称：

```rust
#[derive(Serialize, Deserialize)]
struct MyStruct {
    #[serde(with = "<module>")]
    field1: u32,
    // ... other fields
}
```

有关这些模块的完整列表，请参阅 serde_helpers API 文档。

`serde` 包提供了许多其他属性来自定义序列化。以下列表描述了一些常见属性及其功能：

- `rename` ：序列化和反序列化具有指定名称而不是 Rust 结构或变体名称的字段
- `skip` ：不序列化或反序列化指定字段
- `default` ：如果反序列化期间不存在任何值，则使用 `Default::default()` 中的默认值

有关 `serde` 属性的完整列表，请参阅 serde 属性 API 文档。

## CRUD

### 新增数据

todo

### 删除数据

todo

### 修改数据

todo

### 查询数据



## 高级主题

### 聚合

todo

### 索引

#### 常规索引

todo

#### ttl索引

todo