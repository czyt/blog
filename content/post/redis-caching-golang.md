---
title: "【译】Go 中的 Redis 缓存：初学者指南"
date: 2023-09-22
tags: ["golang","redis"]
draft: false
---

>原文链接：https://betterstack.com/community/guides/scaling-go/redis-caching-golang/ 使用Google机翻

Redis 是一种通用的内存数据存储，通常用于缓存、会话管理、发布/订阅等。它的灵活性和广泛的用例使其成为个人和商业项目的热门选择。

本文将提供关于使用 Redis 作为 Go 程序缓存的可访问介绍，探索其最流行的应用程序。您将学习如何在 Go 应用程序中连接到 Redis 服务器并执行基本的数据库操作，利用其功能来提高性能并减少数据库负载。

 让我们开始吧！

##  先决条件

要按照本文进行操作，请确保您的计算机上安装了最新版本的 Go。如果您缺少 Go，可以在此处找到安装说明。

## 步骤 1 — 安装和配置 Redis

请按照此处的说明为您的操作系统安装最新的 Redis 稳定版本（撰写本文时为 v7.x）。

```command
redis-server --version
```

 输出

```text
Redis server v=7.0.12 sha=00000000:0 malloc=jemalloc-5.2.1 bits=64 build=d706905cc5f560c1
```

安装后，通过执行以下命令确认 Redis 正在运行：

```command
sudo systemctl status redis
```

 输出

```text
● redis-server.service - Advanced key-value store
     Loaded: loaded (/lib/systemd/system/redis-server.service; enabled; vendor preset: enabled)
     Active: active (running) since Wed 2023-08-09 08:23:32 UTC; 5min ago
       Docs: http://redis.io/documentation,
             man:redis-server(1)
   Main PID: 3099 (redis-server)
     Status: "Ready to accept connections"
      Tasks: 5 (limit: 1025)
     Memory: 2.8M
        CPU: 259ms
     CGroup: /system.slice/redis-server.service
             └─3099 "/usr/bin/redis-server 127.0.0.1:6379" "" "" "" "" "" "" ""
```

现在，您可以通过 Redis CLI 连接到 Redis 服务器，并测试它是否正常工作。

```command
redis-cli
```



```text
127.0.0.1:6379> PING
```

 输出

```text
PONG
```

接收上述 `PONG` 输出可确认您的 Redis 服务器配置正确。

另一个可选步骤是配置 Redis 的访问控制列表 （ACL） 功能，以要求对默认用户（和任何其他用户）进行身份验证。完成本教程不需要此步骤，但强烈建议用于生产环境。有关更多详细信息，请参阅文档。

## 步骤 2 — 设置演示存储库

在本节中，您将克隆包含本教程中提供的所有示例的存储库，并安装必要的依赖项。

执行以下每个命令进行设置：

```command
git clone https://github.com/betterstack-community/go-redis.git
```

```command
cd go-redis/
```

```command
go mod download
```

在项目根目录中找到该文件 `.env.example` 并将其重命名为 `.env` ：

```command
mv .env.example .env
```

在文本编辑器中打开文件，然后更改连接详细信息以匹配本地 Redis 实例的连接详细信息。如果您为 Redis 用户设置了密码，请在此处包含该密码。否则，您可以将其留空。

```command
nano .env
```

.env

```text
ADDRESS=localhost:6379
PASSWORD=
DATABASE=0
```

## 步骤 3 — 连接到 Redis 服务器

与传统数据库类似，Redis 利用数据库来促进数据隔离，从而可以为单个项目创建专用数据库。与 SQL 数据库不同，Redis 不提供等效项 `CREATE DATABASE` 。相反，Redis 包含一组预定义的 16 个数据库，编号从 0 到 15。可以通过调整 `redis.conf` 配置文件中的 `databases` 指令来修改数据库的数量。

在本节中，您将学习如何使用 Go 连接到 `.env` 使用文件中 `DATABASE` 的密钥指定的 Redis 数据库。在本教程中，我们将使用 Go 应用程序的官方 Redis 包。

假设您已经在项目目录中，请使用以下命令安装 Go Redis 包：

```command
go get github.com/redis/go-redis/v9
```

安装后，在文本编辑器中打开 `cmd/connect/connect.go` 文件并观察以下突出显示的行：

cmd/connect/connect.go

```go
package main

import (
    "context"
    "fmt"
    "github.com/redis/go-redis/v9"
    "github.com/woojiahao/go_redis/internal/utility"
    "log"
)

func main() {
    ctx := context.Background()
    // Ensure that you have Redis running on your system
    rdb := redis.NewClient(&redis.Options{
        Addr:     utility.Address(),
        Password: utility.Password(), // no password set
        DB:       utility.Database(), // use default DB
    })
    // Ensure that the connection is properly closed gracefully
    defer rdb.Close()

    // Perform basic diagnostic to check if the connection is working
    // Expected result > ping: PONG
    // If Redis is not running, error case is taken instead
    status, err := rdb.Ping(ctx).Result()
    if err != nil {
        log.Fatalln("Redis connection was refused")
    }
    fmt.Println(status)
}
```

Redis 连接详细信息通过 `utility` 包从 `.env` 文件加载。将从 `.env` 文件中加载 Redis 服务器地址、数据库名称和默认密码（如果有），这些详细信息用于设置新的 Redis 客户端 （ `rdb` ）。

创建新的 Redis 客户端后，必须使用该方法 `Ping()` 确认配置详细信息是否正确。如果 Redis 服务器未在提供的地址上运行，或者任何其他选项配置错误，您将收到错误。否则，将观察到 `PONG` 响应，就像我们使用之前一样 `redis-cli` 。

```command
go run cmd/connect/connect.go
```

 输出

```text
PONG
```

如果 Redis 服务器未运行或连接字符串无效，您将收到以下响应，并且应用程序将终止：

 输出

```text
2023/07/15 15:23:13 Redis connection was refused
```

成功连接到 Redis 服务器并确认其功能后，您就可以开始使用 Redis 作为 Go Redis 的缓存。就像许多其他数据存储一样，您可以在 Redis 缓存中执行基本的 CRUD（创建、读取、更新、删除）操作，这就是我们将在本文中演示的内容。

## 步骤 4 — 将数据添加到缓存

您可以通过 Redis 中的 SET 命令将数据添加到缓存中：



```text
127.0.0.1:6379> SET FOO "BAR"
```

 输出

```text
OK
```

这样做会将值 `"BAR"` 分配给键 `FOO` 。

在 Go 中，您可以使用 Redis 客户端的方法将数据 `Set()` 添加到连接的数据库中：

cmd/set/set.go

```go
// Package imports

type Person struct {
    Name string `redis:"name"`
    Age  int    `redis:"age"`
}

func main() {
    // Redis connection...
    _, err := rdb.Set(ctx, "FOO", "BAR", 0).Result()
    if err != nil {
        fmt.Println("Failed to add FOO <> BAR key-value pair")
        return
    }
    rdb.Set(ctx, "INT", 5, 0)
    rdb.Set(ctx, "FLOAT", 5.5, 0)

    rdb.Set(ctx, "EXPIRING", 15, 30*time.Minute)

    rdb.HSet(ctx, "STRUCT", Person{"John Doe", 15})
}
```

该文件的突出显示部分描述了如何在 Redis 缓存中存储各种数据类型。下面是该方法 `Set()` 的签名：

```command
func (c Client) Set(ctx context.Context, key string, value interface{}, expiration time.Duration) *StatusCmd
```

请注意，虽然允许您在其第三个参数中指定任何类型，但 `Set()` 存储在 Redis 缓存中的实际数据将采用字符串的形式。但是，该 `go-redis` 软件包为 Redis 中支持的数据类型提供了一个方便的包装器，提供了将 Redis 字符串解析为相应数据类型的实用程序函数。我们将在下一节中深入研究这些实用程序函数。

与 `Ping()` 该方法非常相似，也返回查询结果的包装器，以便您可以显式处理错误， `Set()` 如第一次 `Set()` 调用所示。

值得注意的是方法调用中的 `Set()` 最后一个参数，它指定缓存中键的过期时间。在上面的大多数示例中，使用值 ，表示密钥不会自动过期， `0` 必须在需要时手动从缓存中删除。还包括一个在 30 分钟内自动过期的键值对示例。

如果你想在 Redis 中存储一个 `struct` ，你可以使用 `HSet()` 将你的 `struct` 存储为 Redis 哈希的方法。

可以使用以下命令执行上面的示例：

```command
go run cmd/set/set.go
```

现在我们已经在缓存中存储了一些值，让我们尝试在下一节中访问它。

## 步骤 5 — 从缓存中读取数据

在 Redis 数据库中存储值后，可以使用 GET 命令检索它。您需要将 Redis 密钥作为参数传递给此命令：

```text
127.0.0.1:6379> GET FOO
```

 输出

```text
"BAR"
```

在 Go 中，使用 `Get()` 该方法可以实现相同的效果：

cmd/get/get.go

```go
// Package imports

type Person struct {
    Name string `redis:"name"`
    Age  int    `redis:"age"`
}

func main() {
    // Redis connection...
    result, err := rdb.Get(ctx, "FOO").Result()
    if err != nil {
        fmt.Println("Key FOO not found in Redis cache")
    } else {
        fmt.Printf("FOO has value %s\n", result)
    }

    intValue, err := rdb.Get(ctx, "INT").Int()
    if err != nil {
        fmt.Println("Key INT not found in Redis cache")
    } else {
        fmt.Printf("INT has value %d\n", intValue)
    }

    var person Person
    err = rdb.HGetAll(ctx, "STRUCT").Scan(&person)
    if err != nil {
        fmt.Println("Key STRUCT not found in Redis cache")
    } else {
        fmt.Printf("STRUCT has value %+v\n", person)
    }

    result, err = rdb.Get(ctx, "BAZ").Result()
    if err != nil {
        fmt.Println("Key BAZ not found in Redis cache")
    } else {
        fmt.Printf("BAZ has value %s\n", result)
    }
}
```

您可以在演示存储库中运行该示例：

```command
go run cmd/get/get.go
```

您应该观察到以下结果：

 输出

```text
FOO has value BAR
INT has value 5
STRUCT has value {Name:John Doe Age:15}
Key BAZ not found in Redis cache
```

如前所述，Go Redis 使用包装器来封装从 Redis 获得的实际结果。使用该 `Get()` 函数时，将返回包装 `*StringCmd` 器。事实证明，这些包装器在处理字符串以外的数据类型时特别有用，因为它们提供了将值解析为适当数据类型的实用工具方法。

例如，在前面的情况下，键 `FOO` 与字符串值相关联，可以使用该方法 `Result()` 检索该值 `"BAR"` 。

但是，对于与上一示例中的整数值关联的键 `INT` ，Go Redis 提供了将 Redis 字符串解析为 `int` 类型的实用程序方法 `Int()` ，考虑到该值存储为 Redis `5` 字符串。还存在用于 `Float32()` 解析浮点数的方法。

有关 `StringCmd` 该类型的实用程序方法的列表，请参阅文档。

使用 检索 `HGetAll()` 哈希值时，结果 `MapStringStringCmd` 类型提供了一种 `Scan()` 方法，该方法接收指向预期 `struct` 值的指针引用，并相应地自动填充该 `struct` 字段。

在缓存中不存在提供的键的情况下，将返回错误，允许您相应地处理这种情况。

在下一节中，我们将研究如何修改存储在缓存中的值。

## 步骤 6 — 更新缓存中的数据

Redis 没有像 or `EDIT` 这样的 `UPDATE` 专用命令，而是使用 SET 命令来更新数据。使用 时 `SET` ，Redis 会执行检查以查看缓存中是否已存在指定的键。缓存中的新键值对（如果未找到该键）。但是，如果键已存在，Redis 将使用新值更新现有的键值对。这种方法允许 Redis 以统一的方式处理键值对的创建和更新。

```text
127.0.0.1:6379> SET FOO 5
```

 输出

```text
OK
```

```command
127.0.0.1:6379> GET FOO
```

 输出

```text
"5"
```

在 Go 中，行为如下，该方法 `Set()` 用于更新数据库中的值：

cmd/update/update.go

```go
// Package imports
func main() {
    // Redis connection...
    // Set "FOO" to be associated with "BAR"
    rdb.Set(ctx, "FOO", "BAR", 0)
    result, err := rdb.Get(ctx, "FOO").Result()
    if err != nil {
        fmt.Println("FOO not found")
    } else {
        fmt.Printf("FOO has value %s\n", result)
    }

    // Update "FOO" to be associated with 5
    rdb.Set(ctx, "FOO", 5, 0)
    intResult, err := rdb.Get(ctx, "FOO").Int()
    if err != nil {
        fmt.Println("FOO not found")
    } else {
        fmt.Printf("FOO has value %d\n", intResult)
    }
}
```

就像 Redis CLI 示例一样，代码片段首先将键 `FOO` 与字符串值 `"BAR"` 相关联。然后，与键 `FOO` 关联的值将立即更新为整数值 `5` 。

如果执行提供的示例，则可以预期观察到以下结果：

```command
go run cmd/update/update.go
```

 输出

```text
FOO has value BAR
FOO has value 5
```

正如预期的那样，由 持有 `FOO` `"BAR"` 的初始值为 ，更新后，该值变为 `5` 。

## 步骤 7 — 从缓存中删除数据

在 Redis 中，对 CRUD 操作进行舍入的是删除操作，这可以使用 Redis CLI 中的 DEL 命令来实现：

```text
127.0.0.1:6379> DEL FOO
```

 输出

```text
(integer) 1
```

要从 Go 程序中删除缓存的数据，您可以类似地使用 `Del()` 此方法：

cmd/delete/delete.go

```go
// Package imports
func main() {
    // Redis connection...
    // Set "FOO" to be associated with "BAR"
    rdb.Set(ctx, "FOO", "BAR", 0)
    result, err := rdb.Get(ctx, "FOO").Result()
    if err != nil {
        fmt.Println("FOO not found")
    } else {
        fmt.Printf("FOO has value %s\n", result)
    }

    // Deleting the key "FOO" and its associated value
    rdb.Del(ctx, "FOO")
    result, err = rdb.Get(ctx, "FOO").Result()
    if err != nil {
        fmt.Println("FOO not found")
    } else {
        fmt.Printf("FOO has value %s\n", result)
    }
}
```

在演示存储库中运行代码将产生以下结果：

```command
go run cmd/delete/delete.go
```

 输出

```text
FOO has value BAR
FOO not found
```

设置并检索与键关联的值后，程序将使用 `Del()` 该方法删除键 `FOO` 值对。随后，任何访问与键关联的值的尝试都会导致错误，因为键 `FOO` 值对已从缓存中删除。

现在我们已经探索了 Redis 缓存上的所有基本操作，让我们来看看如何有效地将 Redis 与数据库和应用程序服务器一起使用，以提供高效可靠的缓存功能。

## 第 8 步 — 将所有内容放在一起

在本节中，您将通过将检索到的数据存储在 Redis 缓存中并将其重用于后续请求来提高耗时的数据库查询的性能。尽管模拟了数据库查询，但概念思维和实现保持一致。

为了提供简洁的概述，该演示旨在向（模拟）数据库发出三次昂贵的数据请求。将提出两种不同类型的请求。初始类型遵循没有缓存的系统体系结构，导致所有三个请求都查询数据库并等待其响应。相比之下，第二种类型在第一次查询之后缓存数据库响应，因此后续请求将遇到显著缩短的处理持续时间。

为了掌握缓存对系统效率的影响，合并了每个函数的执行时间，展示了缓存的有利影响。

cmd/demo/demo.go

```go
// Package imports
func main() {
    fmt.Println("Without caching...")
    start := time.Now()
    getDataExpensive()
    elapsed := time.Since(start)
    fmt.Printf("Without caching took %s\n\n", elapsed)

    fmt.Println("With caching...")
    start = time.Now()
    getDataCached()
    elapsed = time.Since(start)
    fmt.Printf("With caching took %s\n", elapsed)
}

func getDataExpensive() {
    for i := 0; i < 3; i++ {
        fmt.Println("\tBefore query")
        result := databaseQuery()
        fmt.Printf("\tAfter query with result %s\n", result)
    }
}

func getDataCached() {
    ctx := context.Background()
    rdb := redis.NewClient(&redis.Options{
        Addr:     utility.Address(),
        Password: utility.Password(), // no password set
        DB:       utility.Database(), // use default DB
    })
    // Ensure that the connection is properly closed gracefully
    defer rdb.Close()

    for i := 0; i < 3; i++ {
        fmt.Println("\tBefore query")
        val, err := rdb.Get(ctx, "query").Result()
        if err != nil {
            // Database query was not cached yet
            // Make database call and cache the value
            val = databaseQuery()
            rdb.Set(ctx, "query", val, 0)
        }
        fmt.Printf("\tAfter query with result %s\n", val)
    }
}

func databaseQuery() string {
    fmt.Println("\tDatabase queried")
    // Intentionally sleep for 5 seconds to simulate a long database query
    time.Sleep(5 * time.Second)
    return "bar"
}
```

运行此程序时，您将观察到以下结果：

```command
go run cmd/demo/demo.go
```

 输出

```text
Without caching...
        Before query
        Database queried
        After query with result bar
        Before query
        Database queried
        After query with result bar
        Before query
        Database queried
        After query with result bar
Without caching took 15.003013s

With caching...
        Before query
        Database queried
        After query with result bar
        Before query
        After query with result bar
        Before query
        After query with result bar
With caching took 5.0340745s
```

从结果中可以明显看出，缓存有效地将数据库查询的数量减少到一个，符合我们的预期。

在没有缓存的情况下，将立即查询数据库，并要求对服务器发出的每个请求重复处理请求，而不考虑处理时间。对于三个数据请求，数据库也会被查询三次，每个请求需要五秒钟才能完成。因此，三个请求的总执行时间累积到大约 15 秒。

相反，在实现缓存时，我们首先检查缓存中与 `query` 键关联的值。仅当关联值在缓存中不存在，并且其响应立即存储在缓存中时，才会发出数据库请求。这会导致从缓存而不是数据库提供后续数据请求。因此，所有三个请求的执行时间都减少到大约 5 秒，这考虑了初始数据库查询导致的 5 秒延迟。

此示例有效地强调了缓存在实时应用程序中的重要性，因为它显著缩短了进程的执行时间。

对于此示例，我们决定通过模拟数据库调用来简化数据请求过程，但您肯定可以使用 database/sql 包将 的正文替换为实际的数据库调用，并将缓存的 `databaseQuery()` 查询键重命名为更有意义的名称。

例如，如果数据库查询检索存储在数据库中的计算利润，则缓存的查询键可以是类似的，而不是 `query` 这样 `computed-profits` 它对您的业务逻辑更有意义。缓存逻辑的其余部分将保持不变，并且您将有效地从模拟数据库调用迁移到实际数据库调用。

请注意，在缓存中存储数据时，还必须制定适当的失效策略（例如基于时间的过期），以便应用程序不会为用户请求提供过时的响应。

##  结语

本文简要介绍了使用 Redis 作为缓存服务和 Go 应用程序的内存数据库。虽然它只是触及了 Redis 可以实现的目标的表面，但我们希望我们鼓励您进一步探索这个主题。

感谢您的阅读，祝您编码愉快！