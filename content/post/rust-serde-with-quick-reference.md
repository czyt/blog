---
title: "Rust serde_with快速参考"
date: 2024-09-01
tags: ["rust"]
draft: false
---

serde_with 是 Rust 中 serde 序列化/反序列化库的一个扩展,提供了许多有用的自定义序列化和反序列化方法。以下是一些常用的功能和适用场景:

1. 字符串格式化

```rust
use serde_with::rust::display_fromstr;

#[derive(Serialize, Deserialize)]
struct Foo {
    #[serde_with(as = "display_fromstr")]
    bar: u32,
}
```

适用于需要将数字类型序列化为字符串的场景。

2. 时间格式化

```rust
use serde_with::chrono::datetime_utc_ts_seconds_from_any;

#[derive(Serialize, Deserialize)]
struct Foo {
    #[serde_with(as = "datetime_utc_ts_seconds_from_any")]
    time: DateTime<Utc>,
}
```

适用于需要自定义时间格式的场景。

3. 枚举字符串表示

```rust
use serde_with::{serde_as, DisplayFromStr};

#[serde_as]
#[derive(Serialize, Deserialize)]
struct Foo {
    #[serde_as(as = "DisplayFromStr")]
    bar: MyEnum,
}
```

适用于将枚举序列化为字符串的场景。

4. 跳过序列化默认值

```rust
use serde_with::skip_serializing_none;

#[skip_serializing_none]
#[derive(Serialize)]
struct Foo {
    bar: Option<String>,
}
```

适用于需要在序列化时忽略 None 值的场景。

5. 自定义序列化/反序列化

```rust
use serde_with::{serde_as, FromInto};

#[serde_as]
#[derive(Serialize, Deserialize)]
struct Foo {
    #[serde_as(as = "FromInto<String>")]
    bar: MyCustomType,
}
```

适用于需要为自定义类型实现序列化/反序列化的场景。

6. 集合类型转换

```rust
use serde_with::{serde_as, VecSkipError};

#[serde_as]
#[derive(Deserialize)]
struct Foo {
    #[serde_as(as = "VecSkipError<_>")]
    bar: Vec<u32>,
}
```

适用于需要在反序列化集合时跳过错误项的场景。

7. 字段重命名

```rust
use serde_with::serde_as;

#[serde_as]
#[derive(Serialize, Deserialize)]
struct Foo {
    #[serde(rename = "BAR")]
    bar: String,
}
```

适用于需要在序列化/反序列化时重命名字段的场景。

这些功能适用于各种复杂的序列化/反序列化需求,特别是在处理外部 API、数据库存储或配置文件等场景时非常有用。serde_with 提供了灵活的方式来处理各种数据格式和类型转换,使得序列化和反序列化过程更加可控和定制化。