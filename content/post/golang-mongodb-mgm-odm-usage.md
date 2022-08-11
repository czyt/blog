---
title: "Golang MongoDB ODM mgm使用"
date: 2022-05-31
tags: ["golang","mongoDB"]
draft: false
---



(本文大部分内容根据官方文档翻译而来)

## 环境准备

+ golang 1.10+
+ mongodb 
+ [mgm](https://github.com/Kamva/mgm)

## 模型定义

### 定义

定义模型

```go
type Book struct {
   // DefaultModel adds _id, created_at and updated_at fields to the Model
   mgm.DefaultModel `bson:",inline"`
   Name             string `json:"name" bson:"name"`
   Pages            int    `json:"pages" bson:"pages"`
}

func NewBook(name string, pages int) *Book {
   return &Book{
      Name:  name,
      Pages: pages,
   }
}
```
mgm 在创建表时会自动检测Model生成的Collection名称

```go
book:=Book{}

// Print your model collection name.
collName := mgm.CollName(&book)
fmt.Println(collName) // 打印: books
```

如果要自定义生成Collection的名称。需要实现`CollectionNameGetter`接口。

```go
func (model *Book) CollectionName() string {
   return "my_books"
}

// mgm return "my_books" collection
coll:=mgm.Coll(&Book{})
```

#### struct Tags

​     不知您是否注意到模型定义的struct tags。**struct tags**修改 Go 驱动程序的默认编组和解组行为 ，这是附加到 struct 字段的可选元数据片段。struct 标记最常见的用途是指定 BSON 文档中与 struct 字段对应的字段名称。下表描述了mongoDB 的 Go 驱动程序中的常见结构标记：

| 结构标签    | 描述                                                         |
| :---------- | :----------------------------------------------------------- |
| `omitempty` | 如果将字段设置为对应于字段类型的零值，则不会对字段进行编组。 |
| `minsize`   | 如果字段类型是 int64、uint、uint32 或 uint64 类型，并且该字段的值可以适合带符号的 int32，则该字段将被序列化为 BSON int32 而不是 BSON int64。如果该值不适合带符号的 int32，则忽略此标记。 |
| `truncate`  | 如果字段类型是非浮点数字类型，则未编组到该字段中的 BSON 双精度将在小数点处被截断。 |
| `inline`    | 如果字段类型是 struct 或 map 字段，则该字段将在编组时展平，在解组时不展平。 |

如果没有来自结构标签的额外指令，Go Driver 将使用以下规则编组结构：

1. Go Driver 仅对导出的字段进行编组和解组。
2. Go Driver 使用相应结构字段的小写字母生成 BSON 密钥。
3. Go 驱动程序将嵌入的结构字段编组为子文档。每个键都是字段类型的小写。
4. 如果指针非 nil，Go Driver 将指针字段编组为基础类型。如果指针为 nil，则驱动程序将其编组为 BSON 空值。
5. 解组时，Go Driver 跟随[这些 D/M 类型映射](https://pkg.go.dev/go.mongodb.org/mongo-driver@v1.9.0/bson#hdr-Native_Go_Types) 对于类型的字段`interface{}`。驱动程序将未编组的 BSON 文档`interface{}`作为`D`类型解组到字段中。

#### 模型默认字段

每个模型的都包含`mgm.DefaultModel`,包含下面三个字段:

- `_id` : 文档 Id.
- `created_at`: 文档创建时间. 保存文档时通过 `Creating` 勾子自动填充。
- `updated_at`: 文档最后更新时间. 保存文档时通过 `Saving` 勾子自动填充。
#### 模型勾子（Hook）

- `Creating`: Model新模型时调用.**使用DefaultModel默认使用该Hook**
  函数签名: `Creating() error`

- `Created`: Model创建完成后被调用。
  函数签名: `Created() error`

- `Updating`: Model更新时调用.
  函数签名: `Updating() error`

- `Updated` : Model更新后被调用.
  函数签名: `Updated(result *mongo.UpdateResult) error`

- `Saving`: Model 在creating 或者updating被调用.**使用DefaultModel默认使用该Hook**
  函数签名: `Saving() error`

- `Saved`: Model 在Created 或 updated被调用.
  函数签名: `Saved() error`

- `Deleting`: Model在 deleting时调用.
  函数签名: `Deleting() error`

- `Deleted`: Model删除后调用.
  函数签名: `Deleted(result *mongo.DeleteResult) error`

  下面是一个使用`Creating`进行参数校验的例子：

  ```go
  func (model *Book) Creating() error {
     // Call to DefaultModel Creating hook
     if err:=model.DefaultModel.Creating();err!=nil{
        return err
     }
  
     // We can check if model fields is not valid, return error to
     // cancel document insertion .
     if model.Pages < 1 {
        return errors.New("book must have at least one page")
     }
  
     return nil
  }
  ```

  

## 使用

开始使用之前，先设置默认配置选项：

```go
import (
   "github.com/kamva/mgm/v3"
   "go.mongodb.org/mongo-driver/mongo/options"
)

func init() {
   // Setup the mgm default config
   err := mgm.SetDefaultConfig(nil, "test",        	options.Client().ApplyURI("mongodb://root:12345@localhost:27017"))
}
```



### 新增

```go
book:=NewBook("Pride and Prejudice", 345)

// Make sure pass the model by reference.
err := mgm.Coll(book).Create(book)
```

如果需要设置数据在某一时间自动过期（清除),那么可以使用下面的语句：

```go
book:=NewBook("Pride and Prejudice", 345)
model := mongo.IndexModel{
    Keys: bson.D{
        {"created_at", 1},
        {"expireAfterSeconds", t.data.temporaryRecordExpireSeconds}},
}
	_, err = mgm.Coll(book).Indexes().CreateOne(ctx, model)
	if err != nil {
		return "", "", err
	}
```

更多详情，请参考 [expire data](https://www.mongodb.com/docs/v4.4/tutorial/expire-data/) [index ttl](https://www.mongodb.com/docs/v4.4/core/index-ttl/)

### 删除

```go
// Just find and delete your document
err := mgm.Coll(book).Delete(book)
```



### 更新

常规更新

```go
// Find your book
book:=findMyFavoriteBook()

// and update it
book.Name="Moulin Rouge!"
err:=mgm.Coll(book).Update(book)
```

upsert更新

```go
filter := bson.D{{"type", "Oolong"}}
update := bson.D{{"$set", bson.D{{"rating", 8}}}}
opts := options.Update().SetUpsert(true)
result, err := mgm.Coll(book).UpdateOne(mgm.Ctx(), filter, update, opts)
if err != nil {
   panic(err)
}
```

### 查询

#### 基础查询

简单查询

```go
//Get document's collection
book := &Book{}
coll := mgm.Coll(book)

// Find and decode doc to the book model.
_ = coll.FindByID("5e0518aa8f1a52b0b9410ee3", book)

// Get first doc of collection 
_ = coll.First(bson.M{}, book)

// Get first doc of collection with filter
_ = coll.First(bson.M{"page":400}, book)
```
查询并返回列表

```go
result := []Book{}

err := mgm.Coll(&Book{}).SimpleFind(&result, bson.M{"age": bson.M{operator.Gt: 24}})
```



#### 自定义返回字段

查询并隐藏`_id`字段

```go
opts := options.FindOne().SetProjection(bson.D{{"_id", 0}})
// 如果是调用的Find方法就应该是opts := options.Find().SetProjection(bson.D{{"_id", 0}})
err := mgm.Coll(&Book{}).FindOne(nil, bson.M{}, opts)
```
查询并返回`name`和`publish_year`字段
```go
opts := options.FindOne().SetProjection(bson.D{{"_id", 0},{"name",1},{"publish_year",1}})
// 如果是调用的Find方法就应该是opts := options.Find().SetProjection(bson.D{{"_id", 0},{"name",1},{"publish_year",1}})
err := mgm.Coll(&Book{}).FindOne(nil, bson.M{}, opts)
```

### 聚合

尽管我们可以使用官方go驱动中的聚合操作，但mgm也提供了更简单的方法：

官方go驱动实现

```go
import (
   "github.com/kamva/mgm/v3"
   "github.com/kamva/mgm/v3/builder"
   "github.com/kamva/mgm/v3/field"
   . "go.mongodb.org/mongo-driver/bson"
   "go.mongodb.org/mongo-driver/bson/primitive"
)

// Author model collection
authorColl := mgm.Coll(&Author{})

cur, err := mgm.Coll(&Book{}).Aggregate(mgm.Ctx(), A{
    // S function get operators and return bson.M type.
    builder.S(builder.Lookup(authorColl.Name(), "author_id", field.Id, "author")),
})
```

使用mgm实现

```go
authorCollName := mgm.Coll(&Author{}).Name()
result := []Book{}


// Lookup in just single line
_ := mgm.Coll(&Book{}).SimpleAggregate(&result, builder.Lookup(authorCollName, "auth_id", "_id", "author"))

// Multi stage(mix of mgm builders and raw stages)
_ := mgm.Coll(&Book{}).SimpleAggregate(&result,
		builder.Lookup(authorCollName, "auth_id", "_id", "author"),
		M{operator.Project: M{"pages": 0}},
)

// Do something with result...
```

复杂点的例子

```go
import (
   "github.com/kamva/mgm/v3"
   "github.com/kamva/mgm/v3/builder"
   "github.com/kamva/mgm/v3/field"
   "github.com/kamva/mgm/v3/operator"
   . "go.mongodb.org/mongo-driver/bson"
   "go.mongodb.org/mongo-driver/bson/primitive"
)

// Author model collection
authorColl := mgm.Coll(&Author{})

_, err := mgm.Coll(&Book{}).Aggregate(mgm.Ctx(), A{
    // S function get operators and return bson.M type.
    builder.S(builder.Lookup(authorColl.Name(), "author_id", field.Id, "author")),
    builder.S(builder.Group("pages", M{"books": M{operator.Push: M{"name": "$name", "author": "$author"}}})),
    M{operator.Unwind: "$books"},
})

if err != nil {
    panic(err)
}
```
另外一个例子
```go
import (
  "github.com/kamva/mgm/v3"
  f "github.com/kamva/mgm/v3/field"
  o "github.com/kamva/mgm/v3/operator"
  "go.mongodb.org/mongo-driver/bson"
)

// Instead of hard-coding mongo operators and fields 
_, _ = mgm.Coll(&Book{}).Aggregate(mgm.Ctx(), bson.A{
   bson.M{"$count": ""},
   bson.M{"$project": bson.M{"_id": 0}},
})

// Use predefined operators and pipeline fields.
_, _ = mgm.Coll(&Book{}).Aggregate(mgm.Ctx(), bson.A{
   bson.M{o.Count: ""},
   bson.M{o.Project: bson.M{f.Id: 0}},
})
```
### 事务 Transaction

+ 要在默认连接上运行事务，请使用 `mgm.Transaction()` 函数，例如:

```go
d := &Doc{Name: "Mehran", Age: 10}

err := mgm.Transaction(func(session mongo.Session, sc mongo.SessionContext) error {

       // do not forget to pass the session's context to the collection methods.
	err := mgm.Coll(d).CreateWithCtx(sc, d)

	if err != nil {
		return err
	}

	return session.CommitTransaction(sc)
})
```

+ 要使用您的上下文运行事务，请使用 `mgm.TransactionWithCtx()` 方法。
+  要在另一个连接上运行事务，请使用 `mgm.TransactionWithClient() `方法。

## 参考资料

- 官方文档 [Quick Start: Golang & MongoDB - Data Aggregation Pipeline](https://www.mongodb.com/blog/post/quick-start-golang--mongodb--data-aggregation-pipeline)
- [Go By Example](https://golangexample.com/mongo-go-models-a-fast-and-simple-mongodb-odm-for-go-based-on-official-mongo-go-driver/)
- [官方GO驱动使用详解](https://www.mongodb.com/docs/drivers/go/current/)
- [Custom-marshal Golang structs with flattening](https://sudssm.medium.com/custom-marshal-golang-structs-with-flattening-908d5006404c)

