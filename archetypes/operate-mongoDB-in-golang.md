---
title: "使用Golang操作MongoDB"
date: 2022-05-26
tags: ["golang", "mongoDB"]
draft: true
---

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

### 删除数据

### 更新数据

### 查询数据

## 数据库定义与设计



