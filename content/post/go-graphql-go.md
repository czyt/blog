---
title: "使用go来编写graphql服务"
date: 2023-12-29
tags: ["golang", "graphql"]
draft: false
---

> 本文为 文章 Go GraphQL Go!!! A beginner's guide to GraphQL in Go using Ent. 的翻译。大部分使用机翻，部分内容作了相应调整。原文地址为 https://psj.codes/go-graphql-go

您是否想知道计算机和应用程序如何相互通信以获取信息？嗯，他们使用一种称为 API 的东西，它代表应用程序编程接口。 API 充当桥梁，允许不同的软件系统相互通信并交换数据。

在互联网的早期，构建 API 具有挑战性。开发人员必须以一种对每个使用它们的人都有意义的方式进行设计。这就像试图从调酒师那里点一杯饮料，而调酒师的菜单很复杂，有太多的选择。您通常会得到比您需要的更多或不够的信息，例如订购一杯简单的橙汁并收到整个水果篮！这给开发人员带来了挫败感并浪费了时间，他们必须筛选不必要的数据或发出多个请求才能获得他们想要的东西。想象一下，您必须向调酒师要一杯饮料，但您收到的不是简单的订单，而是完整的饮料目录！更糟糕的是，传统 API（称为 REST API）依赖大量端点。这些端点充当访问数据不同部分的特定路径。这就像一个迷宫，里面有无数扇门需要穿过。但随后，改变游戏规则的事情发生了。 Facebook 在 2012 年推出了 GraphQL，这是一种构建 API 的革命性方法，彻底扭转了局面。借助 GraphQL，开发人员终于告别了数据过度获取和数据获取不足的麻烦。快进到 2015 年，Facebook 开源了 GraphQL，并于 2018 年将 GraphQL 捐赠给了 Linux 基金会。

GraphQL 是一种 API 查询语言，或者有人可能会说它是开发 API 的新标准。

在本博客中，我们将探讨 GraphQL 如何应对传统 REST API 面临的挑战。我们还将踏上在 Go 中构建 GraphQL 服务器的实践之旅，为了使我们的开发过程更加令人兴奋和高效，我们将利用 Ent 的强大功能，这是一个专为 Go 设计的令人惊叹的实体库。

###  GraphQL 救世主

在简介中，我们提到了 RESTful API 的问题。让我们尝试理解它们并研究 GraphQL 如何解决它们。

想象一下您在图书馆，并且想要收集有关不同书籍的信息。您向图书管理员询问有关书名、作者和出版日期的详细信息。图书馆员为您提供书名，但当您询问作者的电子邮件或地址或同一作者出版的其他书籍时，他们会告诉您去找不同的图书馆员。为了获得您需要的所有信息，您必须不断地在不同的图书馆员之间来回奔波。这称为数据获取不足。

在软件和应用程序领域，从服务器获取数据时也会发生类似的情况。

让我们考虑一个场景，您使用图书目录 API 来获取有关不同图书的信息。如果您想要检索特定书籍的作者姓名，通常需要对不同的端点进行多个 API 调用。

例如，如果想从数据库中获取与作者相关的详细信息，那么我们可能首先点击 /books/:$id。在这里，在后端我们可能需要进行两个查询，第一个查询将从书籍表中获取具有特定 id 的书籍或仅获取作者 id，然后我们必须使用以下命令对作者表进行第二个查询：作者 id 并获取记录，假设与作者相关的信息存储在单独的表中。

```bash
Request 1: GET /books/1
Response 1:
"book":
   {
     "id": 1,
     "title": "The Ink Black Heart",
     "genre": "Mystery",
     "publicationDate": "30 August 2022",
     "isbn": "9780316413138"
     "author_id": "123"
   }

Request 2: GET /authors/123
Response 2:
"author":
  {
      "id": 123,
      "name": "J. K. Rowling"
  }
```

正如您所看到的，服务器必须对不同的端点进行多次调用才能满足此请求，从而导致我们所说的数据获取不足。这意味着 API 无法在一次调用中检索所有所需的数据，从而导致额外的请求和不必要的处理。

另一方面，存在过度获取数据的问题。

想象一下，您在一家神奇的餐厅，可以点任何您想要的食物或饮料。你走到调酒师面前说：“请给我喝一杯。”调酒师点点头，消失了一会儿，然后带着一个托盘回来，里面装满了你能想到的各种饮料：水、苏打水、果汁、鸡尾酒，甚至还有一碗汤！您只想喝一杯简单的柠檬水，但现在您却被选择淹没了。这称为过度获取数据。

假设您只需要某本书的作者姓名。然而，服务器遵循传统的 RESTful 方法，获取并发送有关作者的所有可用信息，例如他们的 ID、电话号码、电子邮件和地址。这种额外的数据检索和处理被认为是过度获取，因为它包含了不必要的信息。

这些类型的数据请求可能会使系统资源紧张，从而导致高流量和性能下降。随着时间的推移，这种低效请求的不断积累会降低系统的整体性能和可扩展性。

GraphQL 只需一次 API 调用即可解决上述问题。

```graphql
Request: Get /graphql
Body:
{
  "query": "
    query {
      books {
        title
        genre
        author {
          name
        }
      }
    }
  "
}

Response:
{
  "data": {
    "books": [
      {
        "title": "The Ink Black Heart",
        "genre": "Mystery",
        "author": {
          "name": "J. K. Rowling"
        }
      },
      ...
    ]
  }
}
```

如您所见，GraphQL 查询精确定义了所需的字段：书名、流派和嵌套作者姓名。响应仅包含请求的数据，消除了获取不足和过度获取的问题。这种方法减少了网络开销，提高了性能，并增强了开发人员和用户的整体体验。

对于用户群有限的小公司来说，过度获取和不足获取数据的挑战可能不会造成重大问题。然而，对于像 Facebook 这样每秒处理大量数据和数百万个请求的庞然大物来说，这些问题变得至关重要。在处理用户请求时，Facebook 通常需要进行多个 REST 调用来获取所需的精确数据。即使是几百万个额外请求的乘数效应也会使服务器超载，导致处理开销增加，从而导致高流量和性能下降。

###  查询（query）与变异（mutation）

要完全理解 GraphQL，我们需要首先理解查询和变异。

 **查询：**

在 GraphQL 中，查询用于从服务器检索数据。它们允许您指定所需的确切数据和响应的形状。您可以通过指定要获取的字段及其关系来定义查询。服务器处理查询并以结构化格式（通常是 JSON）返回请求的数据。

例如，GraphQL 中用于检索书籍信息的查询可能如下所示：

```graphql
query {
  book(id: 123) {
    title
    genre
    author {
      name
    }
  }
}
```

此查询要求服务器获取 ID 为 123 的书籍的标题和类型及其作者姓名。响应将仅包含请求的字段。

 **突变：**

GraphQL 中的突变用于修改或创建服务器上的数据。它们允许您执行创建新记录、更新现有记录或删除数据等操作。突变类似于 RESTful API 中的 POST、PUT 或 DELETE 方法。

例如，用于创建一本书及其作者的 GraphQL 突变可能如下所示：

```graphql
mutation {
  createBook(title: "The Ink Black Heart", genre: "Mystery", author: "J. K. Rowling") {
    id
    title
    genre
    author {
      id
      name
    }
  }
}
```

此突变创建了一本名为“墨水黑心”、类型为“神秘”的新书，并将其分配给作者“J.K.罗琳”。响应将包含 ID、标题、流派以及所创建书籍的作者的 ID 和姓名。

通过使用查询和突变，GraphQL 提供了一种灵活有效的方法来从服务器检索和修改数据。客户可以准确请求他们需要的内容，并且突变使他们能够修改数据，同时保持清晰一致的 API 合同。

有关 GraphQL 及其功能或编写复杂查询或突变的更多信息，您可以访问官方文档。

##  开始编码

在本博客中，我们将为图书目录应用程序开发一个非常小的 graphql 服务器，我们将能够在数据库中创建图书和作者实体并获取它们。该项目的源代码可在 pratikjagrut/book-catalog 中找到。

###  **先决条件**

[Go](https://go.dev/doc/install)

###  **设置Ent框架**

Ent 是一个专为 Go 设计的开源实体框架。将其视为一种帮助我们以更轻松、更有组织的方式使用数据库的工具。 Ent 因其独特的功能和优点在 Go 社区中广受欢迎。

Ent 最初由 Facebook 开发，旨在解决管理具有大型复杂数据模型的应用程序的挑战。它在 Facebook 内部成功使用了一年，然后于 2019 年开源。此后，Ent 不断发展，甚至于 2021 年加入了 Linux 基金会。

有关 Ent 的详细信息，请参阅文档。

安装必备依赖项后，为项目创建一个目录并初始化 Go 模块：

```bash
mkdir book-catalog
cd book-catalog
go mod init github.com/pratikjagrut/book-catalog
```

 **安装**

运行以下 Go 命令来安装 Ent，并告诉它初始化项目结构以及 Book 模式。

```bash
go get -d entgo.io/ent/cmd/ent
go run -mod=mod entgo.io/ent/cmd/ent new Book
go run -mod=mod entgo.io/ent/cmd/ent new Author
```

安装 Ent 并运行 ent new 后，您的项目目录应如下所示：

```bash
➜  book-catalog git:(main) ✗ tree .
.
├── ent
│   ├── generate.go
│   └── schema
│       ├── author.go
│       └── book.go
├── go.mod
└── go.sum

2 directories, 5 files
```

 **代码生成**

当您运行 ent new 命令时，它会在 ent/schema/book.go 处为您生成一个架构文件

```go
package schema

import "entgo.io/ent"

// Book holds the schema definition for the Book entity.
type Book struct {
   ent.Schema
}

// Fields of the Book.
func (Book) Fields() []ent.Field {
   return nil
}

// Edges of the Book.
func (Book) Edges() []ent.Edge {
   return nil
}
```

正如您所看到的，最初，模式没有定义字段或边。让我们运行命令来生成与 Book 和 Author 实体交互的资产：

```bash
go generate ./ent
```

当我们运行命令 gogenerate./ent 时，它会触发 Ent 的自动代码生成工具。该工具采用我们在 schema 包中定义的 schema 并生成相应的 Go 代码。生成的代码将使我们能够与数据库进行交互。

运行代码生成后，您将在./ent目录下找到一个名为client.go的文件。该文件包含允许我们对实体执行查询和突变的客户端代码。它充当我们与数据库交互的网关。

让我们创建一个测试来使用它。我们将在此测试用例中使用 SQLite 来测试 Ent。

```bash
go get github.com/mattn/go-sqlite3
go get github.com/stretchr/testify/assert
touch ent/book-catalog_test.go
```

您可以将以下代码添加到 book-catalog_test.go 文件中。此代码创建 ent.Client 的实例，自动生成数据库中所有必需的架构资源，包括表和列。

在此阶段，测试仅建立连接并创建没有任何字段或边的模式。但是，随着博客的进展，我们将更新和扩展此测试。

```go
package ent

import (
   "context"
   "testing"

   "github.com/stretchr/testify/assert"

   _ "github.com/mattn/go-sqlite3"
)

func TestBookCatalog(t *testing.T) {
   client, err := Open("sqlite3", "file:book-catalog.db?cache=shared&_fk=1")

   assert.NoErrorf(t, err, "failed opening connection to sqlite")
   defer client.Close()

   ctx := context.Background()

   // Run the automatic migration tool to create all schema resources.
   err = client.Schema.Create(ctx)
   assert.NoErrorf(t, err, "failed creating schema resources")
}
```

然后，运行 go test -v ./ent，它将创建一个带有空 books 表的模式。

```bash
➜  book-catalog git:(main) ✗ go test -v ./ent
=== RUN   TestBookCatalog
--- PASS: TestBookCatalog (0.00s)
PASS
ok      github.com/pratikjagrut/book-catalog/ent    0.660s
```

 **创建数据库架构：**

基本设置就位后，我们现在准备通过添加字段并继续构建查询和突变来扩展我们的 Book 实体。

让我们为我们的数据库定义一个模式：

作者具有以下特点：

- **ID**：书籍的唯一标识符。自动生成。
- **Name**：作者姓名
- **Email**：作者的电子邮件地址**

此外，我们需要在作者和书籍实体之间建立关系或边缘。在这种情况下，作者可以写多本书，从而创建一对多 (1->M) 关系。

将以下字段和边添加到 ent/schema/author.go 文件中。

```go
package schema

import (
   "entgo.io/ent"
   "entgo.io/ent/schema/edge"
   "entgo.io/ent/schema/field"
)

// Author holds the schema definition for the Author entity.
type Author struct {
   ent.Schema
}

// Fields of the Author.
func (Author) Fields() []ent.Field {
   return []ent.Field{
       field.String("name"),
       field.String("email"),
   }
}

// Edges of the Author.
func (Author) Edges() []ent.Edge {
   return []ent.Edge{
       edge.To("books", Book.Type),
   }
}
```

该书具有以下特点：

- ID：书籍的唯一标识符。自动生成。
- **Title**：书名或书名。
- **Genre**：书籍所属的类型或类别。
- **PublicationDate**：书籍出版的日期。
- **ISBN**：分配给书籍的国际标准书号。
- **CreatedAt**：在数据库中创建记录的日期和时间。

在这里，书和作者之间的关系将是多对一的。所以我们将创建一个反向边缘。

现在，将这些字段添加到 ent/schema/book.go 文件中。

```go
package schema

import (
   "time"

   "entgo.io/ent"
   "entgo.io/ent/schema/edge"
   "entgo.io/ent/schema/field"
)

// Book holds the schema definition for the Book entity.
type Book struct {
   ent.Schema
}

// Fields of the Book.
func (Book) Fields() []ent.Field {
   return []ent.Field{
       field.String("title").NotEmpty(),
       field.String("genre").NotEmpty(),
       field.String("publication_date").NotEmpty(),
       field.String("isbn").NotEmpty(),
       field.Time("created_at").Default(time.Now()),
   }
}

// Edges of the Book.
func (Book) Edges() []ent.Edge {
   return []ent.Edge{
       edge.From("author", Author.Type).
           Ref("books").
           Unique(),
   }
}
```

**创建突变和查询**

再次运行 gogenerate ./ent 为我们在 Author 和 Book 实体中定义的字段生成必要的突变，并使用 go run -mod=mod entgo.io/ent/cmd/entdescribe ./ent/schema 检查模式命令。

```bash
➜ go run -mod=mod entgo.io/ent/cmd/ent describe ./ent/schema
Author:
    +-------+--------+--------+----------+----------+---------+---------------+-----------+------------------------+------------+---------+
    | Field |  Type  | Unique | Optional | Nillable | Default | UpdateDefault | Immutable |       StructTag        | Validators | Comment |
    +-------+--------+--------+----------+----------+---------+---------------+-----------+------------------------+------------+---------+
    | id    | int    | false  | false    | false    | false   | false         | false     | json:"id,omitempty"    |          0 |         |
    | name  | string | false  | false    | false    | false   | false         | false     | json:"name,omitempty"  |          0 |         |
    | email | string | false  | false    | false    | false   | false         | false     | json:"email,omitempty" |          0 |         |
    +-------+--------+--------+----------+----------+---------+---------------+-----------+------------------------+------------+---------+
    +-------+------+---------+---------+----------+--------+----------+---------+
    | Edge  | Type | Inverse | BackRef | Relation | Unique | Optional | Comment |
    +-------+------+---------+---------+----------+--------+----------+---------+
    | books | Book | false   |         | O2M      | false  | true     |         |
    +-------+------+---------+---------+----------+--------+----------+---------+

Book:
    +------------------+-----------+--------+----------+----------+---------+---------------+-----------+-----------------------------------+------------+---------+
    |      Field       |   Type    | Unique | Optional | Nillable | Default | UpdateDefault | Immutable |             StructTag             | Validators | Comment |
    +------------------+-----------+--------+----------+----------+---------+---------------+-----------+-----------------------------------+------------+---------+
    | id               | int       | false  | false    | false    | false   | false         | false     | json:"id,omitempty"               |          0 |         |
    | title            | string    | false  | false    | false    | false   | false         | false     | json:"title,omitempty"            |          1 |         |
    | genre            | string    | false  | false    | false    | false   | false         | false     | json:"genre,omitempty"            |          1 |         |
    | publication_date | string    | false  | false    | false    | false   | false         | false     | json:"publication_date,omitempty" |          1 |         |
    | isbn             | string    | false  | false    | false    | false   | false         | false     | json:"isbn,omitempty"             |          1 |         |
    | created_at       | time.Time | false  | false    | false    | true    | false         | false     | json:"created_at,omitempty"       |          0 |         |
    +------------------+-----------+--------+----------+----------+---------+---------------+-----------+-----------------------------------+------------+---------+
    +--------+--------+---------+---------+----------+--------+----------+---------+
    |  Edge  |  Type  | Inverse | BackRef | Relation | Unique | Optional | Comment |
    +--------+--------+---------+---------+----------+--------+----------+---------+
    | author | Author | true    | books   | M2O      | true   | true     |         |
    +--------+--------+---------+---------+----------+--------+----------+---------+
```

使用 Ent，创建迁移和执行常见操作（例如创建记录或获取记录）既简单又实用。

要在数据库中创建一条新记录，我们可以简单地调用以下代码：

```go
author, _ := client.Author.Create().
       SetName("J. K. Rowling").
       SetEmail("jk@gmail.com").
       Save(context.Background())

book, _ := client.Book.Create().
       SetTitle("The Ink Black Heart").
       SetGenre("Mystery").
       SetIsbn("9780316413138").
       SetPublicationDate("30 August 2022").
       SetAuthor(author).
       Save(context.Background())
```

此代码片段创建一个新的作者和书籍记录，并使用 SetAuthor 方法添加边缘。

要从数据库中获取所有书籍，我们可以使用以下代码：

```go
books, err := client.Book.Query().All(ctx)
```

此代码检索数据库中存储的所有 Book 记录。

Ent 提供了许多更有用的函数和选项，用于在数据库中创建、获取和操作数据。这些功能使数据库操作更加易于管理和高效。我鼓励您探索 Ent 文档，以更深入地了解 Ent 的功能以及如何在您的项目中充分利用它。

 **Ent的测试设置**

让我们用迁移来更新 ent/book-catalog_test.go。

```go
package ent

import (
   "context"
   "testing"

   "github.com/stretchr/testify/assert"

   _ "github.com/mattn/go-sqlite3"
)

func TestBookCatalog(t *testing.T) {
   // client, err := Open("sqlite3", "file:book-catalog.db?cache=shared&_fk=1")
   client, err := Open("sqlite3", "file:ent?mode=memory&cache=shared&_fk=1")
   assert.NoErrorf(t, err, "failed opening connection to sqlite")
   defer client.Close()

   ctx := context.Background()

   // Run the automatic migration tool to create all schema resources.
   err = client.Schema.Create(ctx)
   assert.NoErrorf(t, err, "failed creating schema resources")

   author, err := client.Author.Create().
       SetName("J. K. Rowling").
       SetEmail("jk@gmail.com").
       Save(ctx)
   assert.NoError(t, err)

   _, err = client.Book.Create().
       SetTitle("The Ink Black Heart").
       SetGenre("Mystery").
       SetIsbn("9780316413138").
       SetPublicationDate("30 August 2022").
       SetAuthor(author).
       Save(ctx)
   assert.NoError(t, err)

   author, err = client.Author.Create().
       SetName("George R. R. Martin").
       SetEmail("grrm@gmail.com").
       Save(ctx)
   assert.NoError(t, err)

   _, err = client.Book.Create().
       SetTitle("A Game of Thrones").
       SetGenre("Fantasy Fiction").
       SetIsbn("9780553593716").
       SetPublicationDate("1 August 1996").
       SetAuthor(author).
       Save(ctx)
   assert.NoError(t, err)

   books, err := client.Book.Query().All(ctx)
   assert.NoError(t, err)
   assert.Equal(t, len(books), 2)
}
```

现在运行 go 测试，它应该会通过。

```bash
➜  book-catalog git:(main) ✗ go test -v ./ent
=== RUN   TestBookCatalog
--- PASS: TestBookCatalog (0.00s)
PASS
ok      github.com/pratikjagrut/book-catalog/ent
```

##  使用 Ent 设置 GraphQL

现在，让我们通过集成 GraphQL 将 Ent 设置与 SQLite 数据库更进一步。这种集成将提供一种更先进、更实用的方法来处理数据库查询。

通过将 GraphQL 与 Ent 集成，我们可以利用 GraphQL 灵活的查询功能来高效地检索数据。借助强大的 Go 库 99designs /gqlgen，我们可以根据 Ent 数据模型自动生成 GraphQL 模式和解析器。这简化了构建 GraphQL API 的过程，使我们能够专注于定义模式和编写解析器函数。

#### **安装并配置 entgql**

Ent 提供了一个名为 [contrib/entgql ](https://pkg.go.dev/entgo.io/contrib/entgql)的便捷扩展，可以无缝生成 GraphQL 模式。通过安装和利用此扩展，我们可以根据 Ent 数据模型轻松生成 GraphQL 模式。

要开始使用 contrib/entgql，您可以通过运行以下命令来安装它：

```bash
go get entgo.io/contrib/entgql
```

要使用 Ent 和 contrib/entgql 启用 Autor 和 Book 模式的查询和突变功能，我们需要向两个实体的模式添加以下注释。

将以下代码添加到 ent/schema/author.go 中：

```go
func (Author) Annotations() []schema.Annotation {
   return []schema.Annotation{
       entgql.QueryField(),
       entgql.Mutations(entgql.MutationCreate()),
   }
}
```

将以下代码添加到 ent/schema/book.go 中：

```go
func (Book) Annotations() []schema.Annotation {
   return []schema.Annotation{
       entgql.QueryField(),
       entgql.Mutations(entgql.MutationCreate()),
   }
}
```

通过添加的注释，我们告诉 contrib/entgql 为我们的实体生成必要的 GraphQL 查询和突变字段来获取和创建数据。

让我们创建一个名为 ent/entc.go 的新文件并添加以下内容：

```go
//go:build ignore

package main

import (
    "log"

    "entgo.io/ent/entc"
    "entgo.io/ent/entc/gen"
    "entgo.io/contrib/entgql"
)

func main() {
    ex, err := entgql.NewExtension(
        // Generate a GraphQL schema for the Ent schema
        // and save it as "ent.graphql".
        entgql.WithSchemaGenerator(),
        entgql.WithSchemaPath("ent.graphql"),
    )
    if err != nil {
        log.Fatalf("failed to create entgql extension: %v", err)
    }
    opts := []entc.Option{
        entc.Extensions(ex),
    }
    if err := entc.Generate("./ent/schema", &gen.Config{}, opts...); err != nil {
        log.Fatalf("failed to run ent codegen: %v", err)
    }
}
```

在此代码中，我们有一个执行 Ent 代码生成的 main 函数。我们使用 entgql 扩展根据 Ent 模式生成 GraphQL 模式。生成的 GraphQL 模式将保存为 ent.graphql。

值得注意的是，在构建过程中使用 //go:build 忽略标记忽略 ent/entc.go 文件。为了执行此文件，我们将使用 gogenerate 命令，该命令由项目中的generate.go 文件触发。

删除 ent/generate.go 文件并在项目根目录中创建一个包含以下内容的新文件。在接下来的步骤中，gqlgen 命令也将添加到此文件中。

```go
package bookcatalog

//go:generate go run -mod=mod ./ent/entc.go
```

#### **运行模式生成**

安装并配置 entgql 后，您可以通过运行以下命令来执行代码生成过程：

```bash
go generate .
```

注意：如果运行 gogenerate 后在 IDE 中遇到包不一致或缺少包的错误，可以通过运行 go mod tidy 来解决。

您会注意到创建了一个名为 ent.graphql 的新文件：

```graphql
directive @goField(forceResolver: Boolean, name: String) on FIELD_DEFINITION | INPUT_FIELD_DEFINITION
directive @goModel(model: String, models: [String!]) on OBJECT | INPUT_OBJECT | SCALAR | ENUM | INTERFACE | UNION
type Author implements Node {
 id: ID!
 name: String!
 email: String!
 books: [Book!]
}
type Book implements Node {
 id: ID!
 title: String!
 genre: String!
 publicationDate: String!
 isbn: String!
 createdAt: Time!
 author: Author
}
"""
CreateAuthorInput is used for create Author object.
Input was generated by ent.
"""
input CreateAuthorInput {
 name: String!
 email: String!
 bookIDs: [ID!]
}
"""
CreateBookInput is used for create Book object.
Input was generated by ent.
"""
input CreateBookInput {
 title: String!
 genre: String!
 publicationDate: String!
 isbn: String!
 createdAt: Time
 authorID: ID
}
"""
...
```

#### **安装并配置 gqlgen**

安装 99designs/gqlgen：

```bash
go get github.com/99designs/gqlgen
```

要配置 gqlgen 包，我们需要在项目的根目录中创建一个 gqlgen.yml 文件。该文件由 gqlgen 自动加载，并提供生成 GraphQL 服务器代码所需的配置。

让我们将 gqlgen.yml 文件添加到项目的根目录中，并按照文件中的注释来理解每个配置指令的含义。

```yaml
# schema tells gqlgen where the GraphQL schema is located.
schema:
- ent.graphql

# resolver reports where the resolver implementations go.
resolver:
layout: follow-schema
dir: .

# gqlgen will search for any type names in the schema in these go packages
# if they match it will use them, otherwise it will generate them.

# autobind tells gqngen to search for any type names in the GraphQL schema in the
# provided package. If they match it will use them, otherwise it will generate new.
autobind:
- github.com/pratikjagrut/book-catalog/ent
- github.com/pratikjagrut/book-catalog/ent/author
- github.com/pratikjagrut/book-catalog/ent/book

# This section declares type mapping between the GraphQL and Go type systems.
models:
# Defines the ID field as Go 'int'.
ID:
  model:
    - github.com/99designs/gqlgen/graphql.IntID
Node:
  model:
    - github.com/pratikjagrut/book-catalog/ent.Noder
```

为了通知 Ent 有关 gqlgen 配置的信息，我们需要对 ent/entc.go 文件进行修改。我们将 entgql.WithConfigPath("gqlgen.yml") 参数传递给 entgql.NewExtension() 函数。

打开 ent/entc.go 文件并复制并粘贴以下代码：

```go
//go:build ignore

package main

import (
   "log"

   "entgo.io/contrib/entgql"
   "entgo.io/ent/entc"
   "entgo.io/ent/entc/gen"
)

func main() {
   ex, err := entgql.NewExtension(
       // Tell Ent to generate a GraphQL schema for
       // the Ent schema in a file named ent.graphql.
       entgql.WithSchemaGenerator(),
       entgql.WithSchemaPath("ent.graphql"),
       entgql.WithConfigPath("gqlgen.yml"),
   )
   if err != nil {
       log.Fatalf("creating entgql extension: %v", err)
   }
   opts := []entc.Option{
       entc.Extensions(ex),
   }
   if err := entc.Generate("./ent/schema", &gen.Config{}, opts...); err != nil {
       log.Fatalf("running ent codegen: %v", err)
   }
}
```

将 gqlgengenerate 命令 //go:generate go run -mod=mod github.com/99designs/gqlgen 添加到generate.go 文件中：

```go
package bookcatalog

//go:generate go run -mod=mod ./ent/entc.go
//go:generate go run -mod=mod github.com/99designs/gqlgen
```

现在，我们准备运行 gogenerate 来触发 ent 和 gqlgen 代码生成。从项目的根目录执行 gogenerate 命令，您可能会注意到创建了新文件。

```bash
➜  book-catalog git:(main) ✗ tree -L 1
.
├── ent
├── ent.graphql
├── ent.resolvers.go
├── generate.go
├── generated.go
├── go.mod
├── go.sum
├── gqlgen.yml
└── resolver.go

1 directory, 8 files
```

##  服务器

为了构建 GraphQL 服务器，我们需要设置主 schema Resolver，如resolver.go 中定义的那样。 gqlgen 库提供了修改生成的解析器并向其添加依赖项的灵活性。

要将 ent.Client 作为依赖项包含在内，您可以将以下代码片段添加到resolver.go：

```go
package bookcatalog

import (
   "github.com/pratikjagrut/book-catalog/ent"

   "github.com/99designs/gqlgen/graphql"
)

// Resolver is the resolver root.
type Resolver struct{ client *ent.Client }

// NewSchema creates a graphql executable schema.
func NewSchema(client *ent.Client) graphql.ExecutableSchema {
   return NewExecutableSchema(Config{
       Resolvers: &Resolver{client},
   })
}
```

在上面的代码中，我们定义了一个 Resolver 结构体，其中包含一个名为 client、类型为 *ent.Client 的字段。这允许我们使用 ent.Client 作为解析器中的依赖项。

NewSchema 函数负责创建 GraphQL 可执行模式。它以 ent.Client 作为参数并用它初始化 Resolver。

通过将此代码添加到resolver.go，我们确保我们的GraphQL服务器可以访问ent.Client并可以利用它进行数据库操作。

为了创建 GraphQL 服务器的入口点，我们首先创建一个名为 server 的新目录。在此目录中，我们将创建一个 main.go 文件，它将作为 GraphQL 服务器的入口点。

```bash
mkdir server
touch server/main.go
```

使用以下命令运行服务器，然后打开 localhost:8081 以访问 GraphiQL IDE。

```bash
go run server/main.go
```

![运行截图](https://assets.czyt.tech/img/graphsqlServer.png)

###  查询数据

当您在 localhost:8081 上使用 UI 运行 GraphQL 服务器并发送查询或突变请求时，您会注意到终端中显示一条“未实现”消息，并显示紧急错误。出现这种情况是因为我们还没有在 GraphQL 解析器中实现相应的查询和变异函数。

```graphql
{
  books {
    title
    author {
      name
    }
    genre
    publicationDate
    isbn
  }
}
```

 输出：

```graphql
{
  "errors": [
    {
      "message": "internal system error",
      "path": [
        "books"
      ]
    }
  ],
  "data": null
}
```

只需将 ent.resolver.go 中的以下实现替换为以下代码即可。

```go
// Authors is the resolver for the authors field.
func (r *queryResolver) Authors(ctx context.Context) ([]*ent.Author, error) {
   return r.client.Author.Query().All(ctx)
}

// Books is the resolver for the books field.
func (r *queryResolver) Books(ctx context.Context) ([]*ent.Book, error) {
   return r.client.Book.Query().All(ctx)
}
```

现在，重新启动服务器并在 GraphiQL IDE 中再次运行上述查询。这次您应该看到下面的输出。

```bash
{
  books {
    title
    author {
      name
    }
    genre
    publicationDate
    isbn
  },

  authors{
    name
  }
}
```

 输出：

```bash
{
  "data": {
    "books": [],
    "authors": []
  }
}
```

###  变异（Mutation）数据

正如在前面的示例中观察到的，我们的 GraphQL 模式当前返回一个空的书籍和作者列表。为了用数据填充列表，我们可以利用 GraphQL 突变来创建新的图书条目。幸运的是，Ent 会自动生成突变来创建和更新节点和边，从而使这个过程变得无缝。

我们首先使用自定义突变扩展 GraphQL 模式。让我们创建一个名为 book.graphql 的新文件并添加我们的 Mutation 类型：

```graphql
type Mutation {
 # The input and the output are types generated by Ent.
 createAuthor(input: CreateAuthorInput!): Author
 createBook(input: CreateBookInput!): Book
}
```

将自定义 GraphQL 架构添加到 gqlgen.yml 配置中：

```yaml
# schema tells gqlgen where the GraphQL schema is located.
schema:
 - ent.graphql
 - book.graphql
```

正如您所看到的，gqlgen 为我们生成了一个名为 book.resolvers.go 的新文件，复制并粘贴以下代码片段：

```go
// CreateAuthor is the resolver for the createAuthor field.
func (r *mutationResolver) CreateAuthor(ctx context.Context, input ent.CreateAuthorInput) (*ent.Author, error) {
   return r.client.Author.Create().SetInput(input).Save(ctx)
}

// CreateBook is the resolver for the createBook field.
func (r *mutationResolver) CreateBook(ctx context.Context, input ent.CreateBookInput) (*ent.Book, error) {
   return r.client.Book.Create().SetInput(input).Save(ctx)
}
```

现在，重新启动服务器并在 GraphiQL IDE 中运行以下突变查询。

```graphql
mutation CreateBook {
  createAuthor(input: {name: "J. K. Rowling", email: "jk@gmail.com"}){id},
  createBook(input: {title: "The Ink Black Heart", 
    genre: "Mystery", 
    publicationDate:"30 August 2022", 
    isbn: "9780316413138",
    authorID: "1",
  }){id, title, author{name} }
}
```

 输出：

```graphql
{
  "data": {
    "createAuthor": {
      "id": "1"
    },
    "createBook": {
      "id": "4294967297",
      "title": "The Ink Black Heart",
      "author": {
        "name": "J. K. Rowling"
      }
    }
  }
}
```

现在我们来查询一下数据：

```graphql
{
  books {
    title
    author {
      name
    }
    genre
    publicationDate
    isbn
  },

  authors{
    name
    email
  }
}
```

 输出：

```graphql
{
  "data": {
    "books": [
      {
        "title": "The Ink Black Heart",
        "author": {
          "name": "J. K. Rowling"
        },
        "genre": "Mystery",
        "publicationDate": "30 August 2022",
        "isbn": "9780316413138"
      }
    ],
    "authors": [
      {
        "name": "J. K. Rowling",
        "email": "jk@gmail.com"
      }
    ]
  }
}
```

##  结论

在这篇博文中，我们发现了结合 GraphQL 和 Ent 在 Go 中创建高效 API 的强大功能。 GraphQL 提供了处理数据的灵活性，而 Ent 则简化了数据库管理。集成这些工具可以在 Go 中实现无缝 API 开发。

我们学习了如何使用 Ent 构建 GraphQL 服务器并探索了基本功能。此外，我们利用 GraphQL 来查询和修改数据库中的数据。

我希望这篇博文能够成为对 GraphQL 和 Ent 的有价值的介绍，激励您在未来的 API 开发项目中考虑使用它们。

您可以在我的 GitHub 上找到该项目的源代码。

感谢您的阅读，祝您编码愉快！