---
title: "使用Golang操作MongoDB"
date: 2022-05-26
tags: ["golang", "mongoDB"]
draft: false
---

**TL;DR**

## 环境准备

+ golang

+ mongoDB

  

## 预备知识

MongoDB常见的数据类型

|      数据类型      | 示例                                                         | 说明                                                         |
| :----------------: | :----------------------------------------------------------- | :----------------------------------------------------------- |
|        Null        | `{"x" : null}`                                               |                                                              |
|      Boolean       | `{"x" : true}`                                               |                                                              |
|       Number       | `{"x" : 3.14}` `{"x" : 3}` `{"x" : NumberInt("3")}` `{"x" : NumberLong("3")}` | 默认64位浮点数，整数需要使用`NumberInt`和`NumberLong`        |
|       String       | `{"x" : "foobar"}`                                           | 编码格式为UTF-8                                              |
|        Date        | `{"x" : new Date()}`                                         | 64位时间戳(从January 1, 1970)，不存时区。通过`new  Date()`进行调用。 |
| Regular expression | `{"x" : /foobar/i}`                                          | javascript 正则                                              |
|       Array        | `{"x" : ["a", "b", "c"]}`                                    |                                                              |
| Embedded document  | `{"x" : {"foo" : "bar"}}`                                    |                                                              |
|     Object ID      | `{"x" : ObjectId()}`                                         | 文档12字节的ID                                               |
|    Binary data     |                                                              | 一个任意字节的字符串。是保存非UTF-8字符串到数据库的唯一方法。 |
|        Code        | `{"x" : function() { /* ... */ }}`                           |                                                              |



## 数据操作

### 数据库连接

#### 连接字符串

MongoDB的连接字符串为如下格式

![Each part of the connection string](https://www.mongodb.com/docs/drivers/go/current/includes/figures/connection_uri_parts.png)

示例连接地址 `mongodb://user:pass@sample.host:27017/?maxPoolSize=20&w=majority`

官方提供的连接字符选项说明

> | Option Name                  | Type              | Default Value | Description                                                  |
> | :--------------------------- | :---------------- | :------------ | :----------------------------------------------------------- |
> | **connectTimeoutMS**         | integer           | `30000`       | Specifies the number of milliseconds to wait before timeout on a TCP connection. |
> | **maxPoolSize**              | integer           | `100`         | Specifies the maximum number of connections that a connection pool may have at a given time. |
> | **replicaSet**               | string            | `null`        | Specifies the replica set name for the cluster. All nodes in the replica set must have the same replica set name, or the Client will not consider them as part of the set. |
> | **maxIdleTimeMS**            | integer           | `0`           | Specifies the maximum amount of time a connection can remain idle in the connection pool before being removed and closed. The default is `0`, meaning a connection can remain unused indefinitely. |
> | **minPoolSize**              | integer           | `0`           | Specifies the minimum number of connections that the driver maintains in a single connection pool. |
> | **socketTimeoutMS**          | integer           | `0`           | Specifies the number of milliseconds to wait for a socket read or write to return before returning a network error. The `0` default value indicates that there is no timeout. |
> | **serverSelectionTimeoutMS** | integer           | `30000`       | Specifies the number of milliseconds to wait to find an available, suitable server to execute an operation. |
> | **heartbeatFrequencyMS**     | integer           | `10000`       | Specifies the number of milliseconds to wait between periodic background server checks. |
> | **tls**                      | boolean           | `false`       | Specifies whether to establish a Transport Layer Security (TLS) connection with the instance. This is automatically set to `true` when using a DNS seedlist (SRV) in the connection string. You can override this behavior by setting the value to `false`. |
> | **w**                        | string or integer | `null`        | Specifies the write concern. To learn more about values, see the server documentation on [Write Concern options](https://www.mongodb.com/docs/manual/reference/write-concern/). |
> | **directConnection**         | boolean           | `false`       | Specifies whether to force dispatch **all** operations to the host specified in the connection URI. |



#### 数据库驱动

MongoDB的`CRUD` 操作如下，本文使用MongoDB标准数据库驱动，未使用ODM框架如[mgm](https://github.com/Kamva/mgm)、[upper/db](https://github.com/upper/db)、[mango](https://github.com/amorist/mango)等。引入方法

```go
import "go.mongodb.org/mongo-driver/mongo"
```

Demo程序如下:

```go
package main

import (
	"context"
	"fmt"

	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
	"go.mongodb.org/mongo-driver/mongo/readpref"
)

// Connection URI
const uri = "mongodb://user:pass@sample.host:27017/?maxPoolSize=20&w=majority"

func main() {
	// Create a new client and connect to the server
	client, err := mongo.Connect(context.TODO(), options.Client().ApplyURI(uri))

	if err != nil {
		panic(err)
	}
	defer func() {
		if err = client.Disconnect(context.TODO()); err != nil {
			panic(err)
		}
	}()

	// Ping the primary
	if err := client.Ping(context.TODO(), readpref.Primary()); err != nil {
		panic(err)
	}

	fmt.Println("Successfully connected and pinged.")
}

```

### 准备测试数据

TODO

### 新增数据

#### insertOne

insertOne用于插入一条记录:

```sql
db.movies.insertOne({"title" : "Stand by Me"})
```

#### insertMany

insertMany用于插入多条记录：

```sql
db.movies.insertMany([{"title" : "Ghostbusters"},
                    {"title" : "E.T."},
                    {"title" : "Blade Runner"}]);
```

### 删除数据

#### deleteOne

```sql
 db.movies.deleteOne({"_id" : 4})
```

#### deleteMany

```sql
db.mailing.list.deleteMany({"opt-out" : true})
```

#### drop

drop用于删除collection

```sql
 db.movies.drop()
```



### 更新数据

#### 一般更新

一般更新使用`findOneAndReplace` `updateOne` `updateMany`方法。

常见逻辑操作符

| 操作符       | 含义                                                         | 示例                                                         |
| ------------ | ------------------------------------------------------------ | :----------------------------------------------------------- |
| $inc         | 数值类型数据增加。可用于数值类型 `integer` `long` `double` `decimal`的增加及减小。 | `db.analytics.updateOne({"url" : "www.example.com"}, {"$inc" : {"pageviews" : 1}})` |
| $mul         | 乘法（$mul）运算符用于将一个数字字段的值乘以 给定的数字。    | `db.movies.findOneAndUpdate( {"title" : "Macbeth"},{$mul : {"rating" : 2}},{returnNewDocument : true})` |
| $rename      | $rename操作符用于重命名字段。                                | `db.movies.findOneAndUpdate({"title" : "Macbeth"},{$rename : {"num_mflix_comments" : "comments",     "imdb_rating" : "rating"}}, {returnNewDocument : true})` |
| $set         | 更新字段值，不存在会自动创建。                               | `db.user.updateOne({_id:2},{"$set":{"lovemusic":"jaychou"}});` |
| $setOnInsert | $setOnInsert与$set类似，但是，它只在upsert插入操作时设置给定的字段。如果要更新的文档存在则不更新。 | `db.products.update(  { _id: 1 },  {     $set: { item: "apple" },     $setOnInsert: { defaultQty: 100 }  },  { upsert: true } )` |
| $unset       | 删除键及对应的值                                             | `db.user.updateOne({_id:2},{"$unset":{"lovemusic":"jaychou"}});` |
| $push        | 当字段为数组对象时，更新字段使用。可以往数组对象添加记录。   | `db.blog.posts.updateOne({"title" : "A blog post"},{"$push" : {"comments" :{"name" : "joe", "email" : "joe@example.com","content" : "nice post."}}})` |
| $each        | 和$push配合使用，适用于一次操作添加多个记录的情况            | `db.stock.ticker.updateOne({"_id" : "GOOG"}, {"$push" : {"hourly" : {"$each" : [562.776, 562.790, 559.123]}}})` |
| $slice       | 配合$push和$each使用，用于限制字段数组的最大长度。右侧的示例意思为，将数组内容限制为10条记录，导入优先级从后向前。单独使用，可以实现TOP的效果 | 配合使用`db.movies.updateOne({"genre" : "horror"}, {"$push" : {"top10" : {"$each" : ["Nightmare on Elm Street", "Saw"], "$slice" : -10}}})`单独使用`db.blog.posts.findOne(criteria, {"comments" : {"$slice" : 10}})`返回前10条记录`db.blog.posts.findOne(criteria, {"comments" : {"$slice" : [23, 10]}})`返回从24条开始的10条数据 ` db.blog.posts.findOne(criteria, {"comments" : {"$slice" : -1}})`返回最后一条评论 |
| $sort        | 配合$push和$each使用,用于设置添加记录字段的排序，1升序 -1 降序 | `db.movies.updateOne({"genre" : "horror"}, {"$push" : {"top10" : {"$each" : [{"name" : "Nightmare on Elm Street", "rating" : 6.6}, {"name" : "Saw", "rating" : 4.3}], "$slice" : -10, "$sort" : {"rating" : -1}}}})` |
| $ne          | 判断记录是否已经存在于数组。可以理解为Is Not Exist           | `db.papers.updateOne({"authors cited" : {"$ne" : "Richie"}},{$push : {"authors cited" : "Richie"}})` |
| $currentDate | $currentDate用于设置一个给定字段的值为当前的 日期或时间戳。  | `db.movies.findOneAndUpdate( {"title" : "Macbeth"}, {$currentDate : {   "created_date" : true,       "last_updated.date" : {$type : "date"},      "last_updated.timestamp" : {$type : "timestamp"},}}, {returnNewDocument : true})` |
| $addToSet    | 功能与$ne有部分重叠，添加前会检查是否存在以避免重复，适用于$ne不适用的场景且有更好的描述性。 | `db.users.updateOne({"_id" : ObjectId("4b2d75476cc613d5ee930164")},{"$addToSet" : {"emails" : "joe@hotmail.com"}})` |
| $pop         | 从数组尾部移除。{"$pop" : {"key" : 1}}从尾部移除1条记录，{"$pop" : {"key" : -1}}从前面移除1条记录。 |                                                              |
| $pull        | 移除所有满足条件的记录。例如记录为[1,2,3,1]调用$pull删除1，则只剩下[2,3] | 插入几条数据` db.lists.insertOne({"todo" : ["dishes",dishes", "laundry", "dry cleaning"]})   `  删除一条数据` db.lists.updateOne({}, {"$pull" : {"todo" : "dishes"}})` |
| $            | 位置运算符，用于替代筛选记录的Index。该运算符只更新第一个匹配的记录。 | `db.blog.updateOne({"comments.author" : "John"},{"$set" : {"comments.$.author" : "Jim"}})` |
| arrayFilters |                                                              | `db.blog.updateOne({"post" : post_id },{ $set: { "comments.$[elem].hidden" : true } },{   arrayFilters: [ { "elem.votes": { $lte: -5 } } ]})` |

#### Upsert更新

Upsert是一种特殊的更新。如果记录不存在会合并筛选条件和更新记录来自动创建记录。示例：

```sql
db.post.updateOne({title:"my love song"},{$set:{content:{head:"js",body:"javascript"}}},{upsert:true});
```



### 查询数据

MongoDB 常用查询的逻辑操作符如下：

| 运算符     | 含义                                                         |
| ---------- | ------------------------------------------------------------ |
| $lt        | <                                                            |
| $lte       | <=                                                           |
| $gt        | >                                                            |
| $gte       | >=                                                           |
| $ne        | !=                                                           |
| $in        | in                                                           |
| $nin       | not in                                                       |
| $or        | or                                                           |
| $not       | not                                                          |
| $nor       | $nor操作符在语法上与$or相似，但行为方式相反。$nor运算符$nor操作符以数组的形式接受多个条件表达式，并且 返回不满足任何给定条件的文档。`db.movies.find({$nor:[{"rated" : "G"},{"year" : 2005},       {"num_mflix_comments" : {$gte : 5}}]})` |
| $mod       | mod取模运算。如` db.users.find({"id_num" : {"$mod" : [5, 1]}})`返回用户id为1 ,  6 ,  11 ,  16等符合取模运算的记录。 |
| $regex     | 正则匹配                                                     |
| $all       | **所有** 满足条件的记录                                      |
| $size      | 将数组长度作为查询的一部分。如`db.food.find({"fruit" : {"$size" : 3}})`表示查询所有fruit字段值为3元素数组的记录。 |
| $elemMatch | 强迫MongoDB用一个单个数组元素进行比较，不匹配非数组元素.`db.test.find({"x" : {"$elemMatch" : {"$gt" : 10, "$lt" : 20}}})`表示查询字段为数组且数组元素均满足 10<x<20的记录。 |
| $where     |                                                              |
| $match     | `db.companies.aggregate([{$match: {founded_year: 2004}}])`等价于`db.companies.find({founded_year: 2004})` |



#### find/findOne



`find`用于查询所有满足条件的记录。示例:

```sql
db.users.find({"username" : "joe"})
```

注:传入`{}`表示全部查询。

+ 指定返回字段的查询，示例:

```sql
db.users.find({}, {"username" : 1, "email" : 1})
```

默认是要返回`_id`字段，如果要隐藏，则上面的语句需要改成下面的语句(其他字段如果需要隐藏，操作也是类似):

```sql
db.users.find({}, {"username" : 1,"email" : 1, "_id" : 0})
```

+ 比较查询

```sql
db.users.find({"age" : {"$gte" : 18, "$lte" : 30}})
```

+ IN查询

```sql
 db.raffle.find({"ticket_no" : {"$in" : [725, 542, 390]}})
```

+ OR查询

```sql
db.raffle.find({"$or" : [{"ticket_no" : 725}, {"winner" : true}]})
```

+ 查询字段为null的记录

```sql
 db.c.find({"z" : {"$eq" : null, "$exists" : true}})
```

默认查询不存在的记录会返回所有的记录，所以需要添加`$exist`来检查记录是否存在。

+ 数组查询，如一个表有下面的记录：
  ![image-20220527144010401](https://assets.czyt.tech/img/mongo_record_sample.png)

  则可以使用语句`db.food.find({"fruit" : "banana"})`进行查询。如果要查询多条数据，可以使用`$all`来查询，示例语句`db.food.find({fruit : {$all : ["apple", "banana"]}})`表示查询所有fruit为apple和banana的记录。

+ 正则模糊匹配查询

  ``` sql
  db.users.find( {"name" : {"$regex" : /joe/i } })
  ```

  注：MongoDB的正则引擎为`PCRE` 

#### sort

设置按记录字段的排序。

```sql
 db.c.find().sort({username : 1, age : -1})
```

注：`1` 表示升序排列 `-1` 表示降序排列。

#### skip

跳过数据条数。类似于limit，区别在于Skip设置的是数据数量的下限。

```sql
 db.c.find().skip(3)
```
当Skip的数字较大时，请勿使用skip，这会影响数据库的性能。
#### limit  

限制返回记录条数。limit设置的是数据数量的上限。

```sql
db.c.find().limit(3)
```
####  distinct

查询去重。

```sql
db.movies.distinct("rated", {"year" : 1994}) 
```

#### countDocuments/count/estimatedDocumentCount

查询统计

```sql
db.movies.countDocuments({"year": 1999})
```



#### 聚合查询 Aggregation

![image-20220527160917081](https://assets.czyt.tech/img/mongodb_aggregation_pipe_line.png)

​	MongoDB聚合查询用于对数据文档进行变换和组合。实现上，MongoDB聚合管道基于数据流的概念，数据进入管道经过多个stage操作（主要有筛选、投射、分组、排序、限制及跳过），最终输出。常用管道操作符参考下表：

| 操作符   | 简述                                                         |
| -------- | ------------------------------------------------------------ |
| $project | 投射操作符，用于重构每一个文档的字段，可以提取字段，重命名字段，甚至可以对原有字段进行操作后新增字段。如`db.users.aggregate([{ $project : { userId: '$_id', _id: 0 } }]);`将`_id` 字段重命名为`userId `，不显示字段`_id`。 |
| $match   | 匹配操作符，用于对文档集合进行筛选。                         |
| $group   | 分组操作符，用于对文档集合进行分组。`db.users.aggregate([{$group : {_id: '$sex',avgAge: { $avg: '$age' }, count: { $sum: 1 }}} ]);`将用户按性别分组并显示各性别的平均年龄，最后返回各性别人数。 |
| $unwind  | 拆分操作符，用于将数组中的每一个值拆分为单独的文档。         |
| $sort    | 排序操作符，用于根据一个或多个字段对文档进行排序。如`db.users.aggregate([{ $sort : { age: 1 } }]);`将用户按字段`age`升序排列。 |
| $limit   | 限制操作符，用于限制返回文档的数量。                         |
| $skip    | 跳过操作符，用于跳过指定数量的文档。                         |
| $lookup  | 连接操作符，用于连接同一个数据库中另一个集合，并获取指定的文档，类似于populate。 |
| $count   | 统计操作符，用于统计文档的数量。                             |
| $sum     | 对文档字段求和。                                             |
| $avg     | 对文档字段进行平均值计算。                                   |

   更多管道操作符,参考[官网](https://link.jianshu.com/?t=https://docs.mongodb.com/manual/reference/operator/aggregation/)。             




## 数据库定义与设计

![Use Cases vs Patterns Matrix](https://webassets.mongodb.com/_com_assets/cms/patternsmatrix-xv1kqjlrpb.png)

WIP



## 参考

+ [Building with Patterns: A Summary](https://www.mongodb.com/blog/post/building-with-patterns-a-summary)



