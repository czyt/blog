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

#### upsert插入

```rust
use mongodb::{
    bson::{doc, Document},
    sync::{Client, Collection},
};
fn main() -> mongodb::error::Result<()> {
    let uri = "<connection string>";
    let client = Client::with_uri_str(uri)?;
    let my_coll: Collection<Document> = client
        .database("sample_restaurants")
        .collection("restaurants");
    let filter = doc! { "name": "Captain Marvel" };
    let update = doc! { "$set": { "year": 2019 } };
    let options = Some(mongodb::options::UpdateOptions::builder().upsert(true).build());
    let result = my_coll.update_one(filter, update, options)?;
    if result.upserted_id.is_some() {
        println!("Document inserted");
    } else {
        println!("Document updated");
    }
    Ok(())
}
```

#### 单条数据

```rust
use mongodb::{bson::{doc, Document}, options::ClientOptions, Client};

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    // Set up the MongoDB connection
    let client_options = ClientOptions::parse("mongodb://localhost:27017").await?;
    let client = Client::with_options(client_options)?;

    // Get the 'mydb' database and 'mycoll' collection
    let db = client.database("mydb");
    let coll = db.collection("mycoll");

    // Create a document
    let document = doc! {
        "name": "John Doe",
        "age": 30,
        "email": "johndoe@example.com"
    };

    // Insert the document into the collection
    coll.insert_one(document.clone(), None).await?;

    Ok(())
}

```

#### 多条数据

```rust
use mongodb::{
    bson::{doc, Document},
    options::InsertManyOptions,
    sync::Client,
};
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, Debug)]
struct Restaurant {
    name: String,
    cuisine: String,
}

fn main() -> mongodb::error::Result<()> {
    let uri = "<connection string>";
    let client = Client::with_uri_str(uri)?;

    let my_coll = client
        .database("sample_restaurants")
        .collection("restaurants");

    let docs = vec![
        Restaurant {
            name: "While in Kathmandu".to_string(),
            cuisine: "Nepalese".to_string(),
        },
        Restaurant {
            name: "Cafe Himalaya".to_string(),
            cuisine: "Nepalese".to_string(),
        },
    ];

    let options = InsertManyOptions::default();
    let insert_many_result = my_coll.insert_many(docs, options)?;

    println!("Inserted documents with _ids:");
    for (_key, value) in &insert_many_result.inserted_ids {
        println!("{}", value);
    }

    Ok(())
}
```



### 删除数据

#### 删除单条数据

```rust
use mongodb::{
    bson::{Document, doc},
    sync::{Client, Collection},
};

fn main() -> mongodb::error::Result<()> {
    let uri = "<connection string>";
    let client = Client::with_uri_str(uri)?;

    let my_coll: Collection<Document> = client
        .database("sample_restaurants")
        .collection("restaurants");

    let filter = doc! {
        "$and": [
            doc! { "name": "Haagen-Dazs" },
            doc! { "borough": "Brooklyn" }
        ]
    };

    let result = my_coll.delete_one(filter, None)?;

    println!("Deleted documents: {}", result.deleted_count);

    Ok(())
}

```

#### 批量删除数据

```rust

use mongodb::{
    bson::{Document, doc},
    sync::{Client, Collection},
};
fn main() -> mongodb::error::Result<()> {
    let uri = "<connection string>";
    let client = Client::with_uri_str(uri)?;
    let my_coll: Collection<Document> = client
        .database("sample_restaurants")
        .collection("restaurants");
    let filter = doc! {
        "year": doc! { "$lt": 1920 }
    };
    let result = my_coll.delete_many(filter, None)?;
    println!("Deleted documents: {}", result.deleted_count);
    Ok(())
}
```



### 修改数据

#### 更新单条数据

```rust
use mongodb::{
    bson::{doc, Document},
    sync::Client,
};
fn main() -> mongodb::error::Result<()> {
    let uri = "<connection string>";
    let client = Client::with_uri_str(uri)?;
    let my_coll = client.database("mydb").collection("mycoll");
    let filter = doc! { "name": "John" };
    let update = doc! { "$set": { "age": 30 } };
    let result = my_coll.update_one(filter, update, None)?;
    println!("Modified documents: {}", result.modified_count);
    Ok(())
}
```

#### 更新多条数据

```rust
use mongodb::{
    bson::{doc, Document},
    sync::Client,
};
fn main() -> mongodb::error::Result<()> {
    let uri = "<connection string>";
    let client = Client::with_uri_str(uri)?;
    let my_coll = client.database("mydb").collection("mycoll");
    let filter = doc! { "status": "active" };
    let update = doc! { "$set": { "status": "inactive" } };
    let result = my_coll.update_many(filter, update, None)?;
    println!("Modified documents: {}", result.modified_count);
    Ok(())
}
```

#### 查找和替换单条数据

```rust
use mongodb::{
    bson::{doc, Document},
    sync::Client,
};
fn main() -> mongodb::error::Result<()> {
    let uri = "<connection string>";
    let client = Client::with_uri_str(uri)?;
    let my_coll = client.database("mydb").collection("mycoll");
    let filter = doc! { "name": "John" };
    let replacement = doc! { "name": "Jane", "age": 25 };
    let result = my_coll.replace_one(filter, replacement, None)?;
    println!("Replaced documents: {}", result.modified_count);
    Ok(())
}
```

#### 常见操作符例子

**比较运算符**

```rust
use mongodb::bson::{doc, Bson};

let query = doc! {
    "age": { "$gt": 30 }, // greater than
    "salary": { "$lt": 50000 }, // less than
    "name": { "$eq": "John" }, // equal to
    "city": { "$ne": "New York" }, // not equal to
    "score": { "$gte": 80 }, // greater than or equal to
    "rating": { "$lte": 4.5 }, // less than or equal to
};

let result = collection.find(query, None).await?;
```

**逻辑运算符**

```rust
use mongodb::bson::{doc, Bson};

let query = doc! {
    "$and": [
        { "age": { "$gt": 30 } },
        { "city": "New York" }
    ],
    "$or": [
        { "salary": { "$lt": 50000 } },
        { "rating": { "$gte": 4.5 } }
    ],
};

let result = collection.find(query, None).await?;
```

**元素运算符**

```rust
use mongodb::bson::{doc, Bson};

let query = doc! {
    "name": { "$exists": true }, // field exists
    "address": { "$type": "string" }, // field type is string
    "age": { "$mod": [2, 0] }, // age is divisible by 2
};

let result = collection.find(query, None).await?;
```

**数组运算符**

```rust
use mongodb::bson::{doc, Bson};

let query = doc! {
    "tags": { "$all": ["rust", "mongodb"] }, // all tags are present
    "scores": { "$elemMatch": { "$gt": 80, "$lt": 90 } }, // at least one score is between 80 and 90
    "comments.0": { "$exists": true }, // first comment exists
};

let result = collection.find(query, None).await?;
```

#### 表达式运算符

`$expr` 运算符的例子：

```rust
let query = doc! { "$expr": { "$gt": [ "$qty", "$targetQty" ] } };
let cursor = collection.find(query, None).await?;
```

`$jsonSchema` 运算符的例子：

```rust
let query = doc! { "$jsonSchema": { "bsonType": "object", "required": ["name", "age"], "properties": { "name": { "bsonType": "string" }, "age": { "bsonType": "int" } } } };
let cursor = collection.find(query, None).await?;
```

`$mod` 运算符的例子：

```rust
let query = doc! { "quantity": { "$mod": [3, 0] } };
let cursor = collection.find(query, None).await?;
```

`$regex` 运算符的例子：

```rust
let query = doc! { "name": { "$regex": "^A" } };
let cursor = collection.find(query, None).await?;
```

`$text` 运算符的例子：

```rust
let query = doc! { "$text": { "$search": "coffee" } };
let cursor = collection.find(query, None).await?;
```

`$where` 运算符的例子：

```rust
let query = doc! { "$where": "this.quantity > 10" };
let cursor = collection.find(query, None).await?;
```

#### 位运算运算符

MongoDB提供了几个位运算运算符，包括`$bitsAnyClear`、`$bitsAnySet`、`$bitsAllClear`和`$bitsAllSet`。以下是每个运算符的例子：

`$bitsAnyClear`：使用`$bitsAnyClear`运算符测试字段`a`的位位置`1`和位位置`5`是否有任何位被清除。以下是一个示例查询：

```json
db.collection.find( { a: { $bitsAnyClear: [ 1, 5 ] } } )
```

该查询将匹配以下文档：

```json
{ "_id" : 2, "a" : 20, "binaryValueofA" : "00010100" }
{ "_id" : 3, "a" : 20.0, "binaryValueofA" : "00010100" }
```

`$bitsAnySet`：使用`$bitsAnySet`运算符测试字段`a`的位位置`1`和位位置`5`是否有任何位被设置。以下是一个示例查询：

```json
db.collection.find( { a: { $bitsAnySet: [ 1, 5 ] } } )
```

该查询将匹配以下文档：

```json
{ "_id" : 1, "a" : 54, "binaryValueofA" : "00110110" }
{ "_id" : 4, "a" : BinData(0,"Zg=="), "binaryValueofA" : "01100110" }
```

`$bitsAllClear`：使用`$bitsAllClear`运算符测试字段`a`的位位置`1`和位位置`5`是否都被清除。以下是一个示例查询：

```json
db.collection.find( { a: { $bitsAllClear: [ 1, 5 ] } } )
```

该查询将匹配以下文档：

```json
{ "_id" : 2, "a" : 20, "binaryValueofA" : "00010100" }
{ "_id" : 3, "a" : 
```

## 高级主题

### 聚合

当使用Rust编程语言执行聚合操作时，您可以使用MongoDB的聚合管道功能。聚合管道是一系列阶段，每个阶段都对输入文档进行转换，然后将结果传递给下一个阶段。以下是一个使用Rust代码执行聚合操作的示例：

```rust
use mongodb::{
    bson::{doc, Bson},
    options::AggregateOptions,
    sync::Client,
};

fn main() {
    // 创建MongoDB客户端
    let client = Client::with_uri_str("mongodb://localhost:27017").unwrap();

    // 选择数据库和集合
    let db = client.database("mydb");
    let coll = db.collection("mycoll");

    // 构建聚合管道
    let pipeline = vec![
        doc! {
            "$match": {
                "status": "active"
            }
        },
        doc! {
            "$group": {
                "_id": "$category",
                "total": {
                    "$sum": "$quantity"
                }
            }
        },
        doc! {
            "$sort": {
                "total": -1
            }
        },
    ];

    // 执行聚合操作
    let options = AggregateOptions::builder().build();
    let cursor = coll.aggregate(pipeline, options).unwrap();

    // 遍历结果并打印
    for result in cursor {
        if let Ok(document) = result {
            println!("{:?}", document);
        }
    }
}
```

### 索引

#### 常规索引

当使用Rust编程语言与MongoDB一起使用常规索引时，您可以使用MongoDB Rust驱动程序的`create_index`方法来创建索引。常规索引是指对单个字段或多个字段进行索引，以提高查询性能。

以下是一个使用Rust代码创建常规索引的示例：

```rust
use mongodb::{
    bson::{doc, Document},
    options::IndexModel,
    sync::Client,
};

fn main() {
    // 创建MongoDB客户端
    let client = Client::with_uri_str("mongodb://localhost:27017").unwrap();

    // 选择数据库和集合
    let db = client.database("mydb");
    let coll = db.collection("mycoll");

    // 创建常规索引
    let index = IndexModel::builder().keys(doc! { "name": 1 }).build();
    coll.create_index(index, None).unwrap();

    println!("Created index");
}
```

在这个示例中，我们首先创建了一个MongoDB客户端，并选择了要创建索引的数据库和集合。然后，我们使用`IndexModel`来定义索引的字段和排序方式。在这个示例中，我们创建了一个对`name`字段进行升序排序的索引。最后，我们使用`create_index`方法来创建索引。对于多个字段，可以创建复合索引：

```rust
let index = IndexModel::builder()
    .keys(doc! { "city": 1, "pop": -1 })
    .build();
let idx = my_coll.create_index(index, None).await?;
println!("Created index:\n{}", idx.index_name);
```

#### ttl索引

TTL索引是一种自动删除集合中文档的索引，根据指定的时间字段自动删除过期的文档。

以下是一个使用Rust代码创建TTL索引的示例：

```rust
use mongodb::{
    bson::{doc, Document},
    options::IndexModel,
    sync::Client,
};

fn main() {
    // 创建MongoDB客户端
    let client = Client::with_uri_str("mongodb://localhost:27017").unwrap();

    // 选择数据库和集合
    let db = client.database("mydb");
    let coll = db.collection("mycoll");

    // 创建TTL索引
    let index = IndexModel::builder()
        .keys(doc! { "createdAt": 1 })
        .expire_after_seconds(3600) // 设置过期时间为3600秒
        .build();

    coll.create_index(index, None).unwrap();

    println!("Created TTL index");
}
```

在这个示例中，我们首先创建了一个MongoDB客户端，并选择了要创建索引的数据库和集合。然后，我们使用`IndexModel`来定义索引的字段和排序方式。在这个示例中，我们创建了一个对`createdAt`字段进行升序排序的TTL索引，并设置了过期时间为3600秒。最后，我们使用`create_index`方法来创建索引。

#### 唯一索引

MongoDB支持单字段和多字段的唯一索引。以下是在MongoDB中创建单字段和多字段唯一索引的示例代码：

**单字段唯一索引示例：**

```rust
use mongodb::{
    bson::{doc, Document},
    options::{IndexModel, IndexOptions},
    Client,
    error::Result,
};

#[tokio::main]
async fn main() -> Result<()> {
    // 连接到MongoDB
    let client = Client::with_uri_str("mongodb://localhost:27017").await?;
    let db = client.database("your_database_name");
    let collection = db.collection("your_collection_name");

    // 创建单字段唯一索引
    let index_options = IndexOptions::builder().unique(true).build();
    let index_model = IndexModel::builder().keys(doc! { "your_field_name": 1 }).options(index_options).build();
    collection.create_index(index_model, None).await?;

    Ok(())
}
```

请将`your_database_name`替换为您的数据库名称，`your_collection_name`替换为您的集合名称，以及`your_field_name`替换为您要创建唯一索引的字段名称。

**多字段唯一索引示例：**

```rust
use mongodb::{
    bson::{doc, Document},
    options::{IndexModel, IndexOptions},
    Client,
    error::Result,
};

#[tokio::main]
async fn main() -> Result<()> {
    // 连接到MongoDB
    let client = Client::with_uri_str("mongodb://localhost:27017").await?;
    let db = client.database("your_database_name");
    let collection = db.collection("your_collection_name");

    // 创建多字段唯一索引
    let index_options = IndexOptions::builder().unique(true).build();
    let index_model = IndexModel::builder().keys(doc! { "field1": 1, "field2": 1 }).options(index_options).build();
    collection.create_index(index_model, None).await?;

    Ok(())
}
```
