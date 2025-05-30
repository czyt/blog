---
title: "在 Go 中构建可扩展的多租户应用程序【译】"
date: 2025-05-30T14:50:27+08:00
draft: false
tags: ["golang","ent]
author: "czyt"
---

> 原文链接 https://atlasgo.io/blog/2025/05/26/gophercon-scalable-multi-tenant-apps-in-go

**为 GopherCon Israel 2025 准备并呈现。**

###  引言

在本篇博客中，我们将基于我们在构建 Atlas Cloud 后端（作为我们商业产品的一部分）的经验，探讨在 Go 中构建可扩展多租户应用程序的不同策略。

但首先，让我们明确一下我们所说的多租户应用是什么。

*多租户是一个系统的特性，即单个实例为多个客户（租户）提供服务。*

作为一家商业企业，你的目标当然是有很多客户！但你想要服务许多客户，他们期望有一个流畅无缝的体验，就好像只有他们在使用你的服务一样。

你向客户隐含做出的两个重要承诺是：

1. 数据隔离：每个租户的数据都是隔离和安全的，确保一个租户无法访问另一个租户的数据。
2. 性能：无论租户数量如何，应用程序都应表现良好，确保一个租户的使用不会降低其他租户的体验。

让我们探讨一些可能实现这些承诺的方法。

###  物理隔离

确保数据和性能隔离最直接的方法是为每个租户运行一个独立的应用实例。这种方法通常被称为“物理隔离”或“专用实例”。

为每个租户运行独立实例，可以确保：

1. 每个租户的数据存储在独立的数据库中，从而保证完全隔离。如有需要，租户可以在不同的 VPC 中运行，甚至可以在不同的云账户中运行。
2. 租户独立消费资源，因此一个租户的使用不会影响其他租户，从而消除了“吵闹邻居”问题。

然而，大多数公司不会选择这条路，原因有几点：

1. 运营开销：将应用程序部署到数百或数千个生产环境，每个环境都有自己的数据库和配置，管理起来可能非常复杂。
2. 成本：如果您的公司需要为每个租户的资源支付云服务提供商的费用，成本可能会迅速变得难以承受。
3. 可扩展性：如果添加新租户需要部署新实例，那么扩展应用程序以支持许多租户可能会成为瓶颈。
4. 可见性：跨多个实例监控和调试问题可能具有挑战性，因为您需要从所有实例中聚合日志和指标。

###  逻辑隔离

另一种方法是运行单个应用程序实例来服务多个租户，通常称为“逻辑隔离”。在此模型中，租户共享相同的应用程序代码和数据库，但它们的数据在逻辑上是隔离的。逻辑隔离可以总结为：

*共享基础设施，作用域请求*

让我们看看在 Go 应用程序中实际如何使用这个示例，从一个简单的 GORM 示例开始：

```go
package main

type Tenant struct {
	ID   uint   `gorm:"primaryKey" json:"id"`
	Name string `json:"name"`
}

type Customer struct {
	ID       uint   `gorm:"primaryKey" json:"id"`
	Name     string `json:"name"`
	TenantID uint   `json:"tenant_id"`
}
```



在这个示例中，我们有两个模型： `Tenant` 和 `Customer` 。每个 `Customer` 属于一个 `Tenant` ， `Customer` 模型中的 `TenantID` 字段用于将每个客户与特定的租户关联起来。

为了确保数据隔离，我们必须在每个请求中将查询范围限定在租户的 ID 上。例如，在获取客户时，我们会这样做：

```go
func (s *Server) customersHandler(w http.ResponseWriter, r *http.Request) {
	tid, err := s.getTenantID(r)
	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		w.Write([]byte("invalid tenant"))
		return
	}
	var customers []Customer
	if err := s.db.
		Where("tenant_id = ?", tid).
		Find(&customers).Error; err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		return
	}
	json.NewEncoder(w).Encode(customers)
}
```
注意我们如何从请求上下文中获取租户 ID，并使用它来将查询范围限定在租户的数据上。

这种方法比物理隔离有许多优势：

1. 操作简便性：您只需要部署和管理单个应用程序实例，这简化了部署和操作。
2. 成本效益：您可以用单个实例服务多个租户，从而降低运行应用程序的成本。
3. 可扩展性：您可以通过添加更多实例来水平扩展应用程序，而无需为每个租户部署新的实例来处理更多租户。
4. 可见性：您可以从单个实例聚合日志和指标，从而更容易监控和调试问题。

然而，让我们考虑一下这种方法的缺点。

假设您想添加一个端点来返回特定租户的报告。您可以像这样实现：

```go
type OrderSumResult struct {
	CustomerID uint   `json:"customer_id"`
	Customer   string `json:"customer"`
	OrderCount int    `json:"order_count"`
}

func (s *Server) orderSumsHandler(w http.ResponseWriter, r *http.Request) {
	tid, err := s.getTenantID(r)
	if err != nil {
		w.WriteHeader(http.StatusUnauthorized)
		w.Write([]byte("unauthenticated"))
		return
	}
	var results []OrderSumResult
	err = s.db.Raw(`
		SELECT c.id as customer_id, c.name as customer, COUNT(o.id) as order_count
		FROM customers c
		LEFT JOIN orders o ON c.id = o.customer_id AND o.tenant_id = c.tenant_id
		WHERE c.tenant_id = ?
		GROUP BY c.id, c.name
	`, tid).Scan(&results).Error
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte("query error"))
		return
	}
	json.NewEncoder(w).Encode(results)
}
```
当您的端点只是简单的 CRUD 操作时，将查询范围限定在租户 ID 上相对简单。然而，随着应用程序的增长以及您开始添加更复杂的查询，您可能会发现将查询范围限定在租户 ID 上变得更加具有挑战性。自定义 SQL 需要精心设计和审查，以确保租户的数据始终是隔离的。

换句话说，对于任何开发人员来说，租户管理都成为了一个持续的关注点，如果你的团队规模较大并且频繁发布代码，错误是难免的。

这种容易出错且影响巨大的组合是任何架构师都应该避免的。在这种情况下，建议找到将租户管理的关注点推向应用程序基础设施层的方法，这样开发人员就不需要在日常工作中考虑它。

### Go 中的多租户策略

在构建 Atlas 的 SaaS 端时，我们寻找能够让我们扩展、隔离数据并保持快速，同时又不给开发者带来更多麻烦的多租户处理方式。我们问自己：

*我们能否在保持“单租户”开发者体验的同时，利用逻辑隔离？*

在本文的其余部分，我将演示三种你可以考虑实现这一目标的方法：

1. ORM 中间件：将租户决策推向 ORM 层级的共享中间件层。
2. 行级安全（RLS）：如果你使用的是 PostgreSQL，你可以使用 RLS 来在数据库级别强制执行租户隔离。
3. 租户级模式：一种不太为人所知的方法，它使用中间件为每个请求创建作用域数据库连接，允许你为每个租户使用一个单独的模式。

###  使用 Ent 隐私规则

Ent 是一个流行的 Go ORM，它提供了一种强大的方式来定义你的数据模型，并为与数据库交互生成类型安全的代码。 Ent 由我的联合创始人 Ariel 在他在 Facebook 期间创建，并自那以后已成为 Linux 基金会的一部分。

与 Atlas 类似，Ent 基于“模式即代码”的概念，您可以在 Go 代码中定义数据模型，然后 Ent 的代码生成引擎会继续处理。Ent 支持许多有用的功能，例如：

- 您数据的图模型（节点和边）
- 轻松遍历您的数据模型
- 为类型安全的查询生成代码
- 自动生成 GraphQL、REST 和 gRPC API

Ent 还具有强大的隐私规则功能，允许您根据请求的上下文定义访问数据的规则。正如 Ent 文档所说：

> 隐私层的主要优势在于，您只需编写一次隐私政策（在模式中），它就会一直被评估。无论您的代码库中查询和变异操作发生在哪里，它都会始终通过隐私层。

让我们看看如何结合一些有趣的 Go 技巧，使用 Ent 的隐私规则来在我们的应用程序中强制执行租户隔离。

#### 第一步：将租户 ID 注入到上下文中

为了强制执行租户隔离，我们需要将租户 ID 注入到每个请求的上下文中。这可以通过一个中间件来完成，该中间件从请求中提取租户 ID 并将其添加到上下文中。以下是如何做到这一点的示例：

```go
package viewer

type middleware struct {
	*ent.Client
}

func Middleware(c *ent.Client) func(http.Handler) http.Handler {
	m := &middleware{c}
	return m.handle
}

func (m *middleware) handle(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, req *http.Request) {
		tenant, err := m.tenant(req)
		if err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}
		req = req.WithContext(
			NewContext(
				req.Context(),
				UserViewer{T: tenant},
			),
		)
		next.ServeHTTP(w, req)
	})
}

func (m *middleware) tenant(r *http.Request) (*ent.Tenant, error) {
	tid := r.Header.Get(Header)
	if tid == "" {
		return nil, http.ErrNoLocation
	}
	id, err := strconv.Atoi(tid)
	if err != nil {
		return nil, err
	}
	return m.Tenant.Get(r.Context(), id)
}
```



在这个示例中，我们定义了一个中间件，它从请求头中提取租户 ID，并使用自定义的 `UserViewer` 类型将其添加到上下文中。 `tenant` 方法使用租户 ID 从数据库中检索租户，然后使用它创建一个包含租户信息的新的上下文。

接下来，我们需要将这个中间件注册到我们的 HTTP 服务器中：

```go
// NewServer creates a new HTTP server with ent client and returns http.Handler
func NewServer(client *ent.Client) http.Handler {
	s := &Server{client: client}
	r := chi.NewRouter()
	r.Use(middleware.Recoverer)
	r.Use(viewer.Middleware(client))

	r.Get("/customers", s.GetCustomers)
	r.Get("/products", s.GetProducts)
	r.Get("/orders", s.GetOrders)
	r.Get("/order-sums", s.orderSumsHandler)

	return r
}
```



通过使用 `viewer.Middleware` ，我们确保租户 ID 被注入到每个请求的上下文中，使我们能够在后续的处理程序中访问它。

#### 第二步：定义数据模型

在深入隐私规则之前，让我们使用 Ent 定义我们的数据模型。我们将创建两个实体： `Tenant` 和 `Customer` ：

ent/schema/tenant.go

```go
package schema

import (
	"entgo.io/ent"
	"entgo.io/ent/schema/edge"
	"entgo.io/ent/schema/field"
)

// Tenant holds the schema definition for the Tenant entity.
type Tenant struct {
	ent.Schema
}

// Fields of the Tenant.
func (Tenant) Fields() []ent.Field {
	return []ent.Field{
		field.String("name").Unique(),
	}
}

// Edges of the Tenant.
func (Tenant) Edges() []ent.Edge {
	return []ent.Edge{
		edge.To("customers", Customer.Type),
	}
}
```

此模式定义了一个具有唯一名称且指向 `Customer` 实体的 `Tenant` 实体。现在让我们定义 `Customer` 实体：

ent/schema/customer.go

```go
package schema

import (
	"entgo.io/ent"
	"entgo.io/ent/schema/edge"
	"entgo.io/ent/schema/field"
)

// Customer holds the schema definition for the Customer entity.
type Customer struct {
	ent.Schema
}

func (Customer) Fields() []ent.Field {
	return []ent.Field{
		field.String("name"),
	}
}

func (Customer) Edges() []ent.Edge {
	return []ent.Edge{
		edge.To("orders", Order.Type),
	}
}

func (Customer) Mixin() []ent.Mixin {
	return []ent.Mixin{TenantMixin{}}
}
```
请注意，我们使用 `TenantMixin` 将租户逻辑应用于 `Customer` 实体。由于我们应用程序中的每个实体都将限定于一个租户，我们可以定义一个混入（mixin），将租户逻辑应用于所有实体。让我们定义 `TenantMixin` 。

ent/schema/tenant_mixin.go

```go
package schema

import (
	"entgo.io/ent"
	"entgo.io/ent/schema/edge"
	"entgo.io/ent/schema/field"
	"entgo.io/ent/schema/mixin"
	"gophercon/entpriv/ent/rule"
)

// TenantMixin for embedding the tenant info in different schemas.
type TenantMixin struct {
	mixin.Schema
}

// Fields for all schemas that embed TenantMixin.
func (TenantMixin) Fields() []ent.Field {
	return []ent.Field{
		field.Int("tenant_id").
			Immutable(),
	}
}

// Edges for all schemas that embed TenantMixin.
func (TenantMixin) Edges() []ent.Edge {
	return []ent.Edge{
		edge.To("tenant", Tenant.Type).
			Field("tenant_id").
			Unique().
			Required().
			Immutable(),
	}
}

func (TenantMixin) Policy() ent.Policy {
	return rule.FilterTenantRule()
}
```



`TenantMixin` 定义了一个不可变且必填的 `tenant_id` 字段，以及指向 `Tenant` 实体的边。 `Policy` 方法返回一个自定义策略，我们将在下文中定义它，该策略将强制执行租户逻辑。

#### 第 3 步：定义隐私规则

接下来，我们需要定义一个隐私规则来执行租户逻辑。我们可以通过实现一个自定义的隐私规则，根据上下文中的租户 ID 来过滤数据。具体操作如下：

entpriv/ent/rule/filter_tenant_rule.go

```go
package rule

import (
	"context"
	"entgo.io/ent/entql"
	"gophercon/entpriv/ent/privacy"
	"gophercon/entpriv/viewer"
)

// FilterTenantRule is a query/mutation rule that filters out entities that are not in the tenant.
func FilterTenantRule() privacy.QueryMutationRule {
	// TenantsFilter is an interface to wrap WhereHasTenantWith()
	// predicate that is used by both `Group` and `User` schemas.
	type TenantsFilter interface {
		WhereTenantID(entql.IntP)
	}
	return privacy.FilterFunc(func(ctx context.Context, f privacy.Filter) error {
		view := viewer.FromContext(ctx)
		tid, ok := view.Tenant()
		if !ok {
			return privacy.Denyf("missing tenant information in viewer")
		}
		tf, ok := f.(TenantsFilter)
		if !ok {
			return privacy.Denyf("unexpected filter type %T", f)
		}
		// Make sure that a tenant reads only entities that have an edge to it.
		tf.WhereTenantID(entql.IntEQ(tid))
		// Skip to the next privacy rule (equivalent to return nil).
		return privacy.Skip
	})
}
```
在这个示例中，我们定义了一个 `FilterTenantRule` ，用于检查上下文中的租户 ID 并根据其过滤数据。 `TenantsFilter` 接口用于封装 `WhereTenantID` 预测，该预测被 `Customer` 实体以及任何嵌入 `TenantMixin` 的其他实体使用。这提供了一种基于租户 ID 过滤数据的安全类型方式。

#### 第 4 步：编写单租户代码

现在，我们可以像单租户一样编写应用程序代码，而不用担心租户逻辑。例如，我们可以编写一个处理器来获取租户的客户：

```go
// GetCustomers handles GET /customers request
func (s *Server) GetCustomers(w http.ResponseWriter, r *http.Request) {
	customers, err := s.client.Customer.Query().All(r.Context())
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(customers)
}
```

请注意，这段代码中没有包含租户逻辑。 `Customer.Query().All(r.Context())` 调用将根据我们之前定义的隐私规则，自动根据上下文中的租户 ID 过滤客户。

总而言之，以下是我们的应用程序中请求的流程：

![img](https://atlasgo.io/assets/images/entpriv-journey-48f03d480b272cc114032834cada7b45.png)

这种方法使我们能够在利用 Ent 的隐私规则在 ORM 层级强制执行租户隔离的同时编写单租户代码。

然而，这种方法有几个重要的局限性：

1. 自定义查询。如果你需要打破砂锅问到底，编写不使用 Ent 查询构建器的自定义 SQL 查询，你需要手动将查询范围限定为租户的 ID，这可能导致错误。
2. 其他客户端。如果您有其他直接访问数据库的客户端（例如，一个报告服务或数据导出工具），您需要确保它们也遵循租户逻辑，这意味着在这些客户端中重新实现相同的逻辑。
3. 嘈杂的邻居。由于所有租户共享同一个数据库和应用程序，这种方法在性能隔离方面没有任何帮助。如果一个租户负载很重，它可能会影响其他租户的性能。

###  行级安全 (RLS)

如果你使用的是 PostgreSQL，你可以利用其内置的行级安全 (RLS) 功能在数据库级别强制执行租户隔离。行级安全允许你定义策略，根据请求的上下文来控制哪些行对哪些用户可见。

使用 RLS，我们可以克服在 ORM 层面解决多租户问题所带来的一些限制。要为表启用 RLS，你可以使用以下 SQL 命令：

```sql
--- Enable row-level security on the users table.
ALTER TABLE "customers" ENABLE ROW LEVEL SECURITY;

-- Create a policy that restricts access to
-- rows in the users table based on the current tenant.
CREATE POLICY tenant_isolation ON "users"
USING (
  "tenant_id" = current_setting('app.current_tenant')::integer
);
```
然后，您可以在每个请求的上下文中设置 `app.current_tenant` 设置，PostgreSQL 将根据租户 ID 自动过滤行。例如使用 Ent：

```go
ctx := sql.WithIntVar(
    ctx, "app.current_tenant",
    tenant1.ID,
)

// Get only tenant1 customers
users := client.Customer.Query().AllX(ctx)
```
在数据库层面过滤行有很多优势：

1. 性能：RLS 策略在数据库级别执行，这比在应用级别过滤数据可能更高效。
2. 安全性：RLS 策略由数据库强制执行，这意味着即使你有其他直接访问数据库的客户，他们仍然会尊重租户逻辑。
3. 简洁性：你可以像单租户一样编写你的应用代码，而不用担心租户逻辑。

然而，RLS 也有一些限制：

1. 数据库特定：RLS 是 PostgreSQL 特有的功能，因此如果您切换到不同的数据库，您需要重新实现租户逻辑。
2. 需要仔细管理模式：您需要确保 RLS 策略应用于所有相关的表，如果您有较大的模式或许多表，这可能具有挑战性。为了帮助您完成此操作，您可以使用 Atlas 来管理 RLS 策略，并使用 Atlas 的自定义模式规则功能强制执行其存在。
3. 嘈杂的邻居：与 Ent 隐私规则方法类似，RLS 不会提供任何帮助来隔离性能。如果一个租户有繁重的负载，它可能会影响其他租户的性能。

要了解如何使用 Atlas 来管理 RLS 策略，请查看这篇博客文章。

###  每个租户的架构

我们最终为 Atlas 的 SaaS 系统采用的方法虽然不常见，但已证明对我们的用例非常有效。它结合了逻辑隔离的好处和单租户代码的简单性，同时提供了相当不错的隔离效果。这种方法通常被称为“租户模式”或“数据库模式”。

使用租户模式，我们使用单个数据库实例，但每个租户在该数据库中都有自己的模式（表在模式之间进行复制）。这使我们能够隔离每个租户的数据，同时仍然保持成本较低。

![img](https://atlasgo.io/assets/images/schema-per-tenant-5a65933ed1f4980e158e1a03cb64915e.png)

请求作用域是在中间件级别处理的，我们根据请求上下文中的租户 ID 为每个租户创建一个作用域数据库客户端。

中间件处理器如下所示：

```go
type middleware struct {
	url     *url.URL
	dialect string

	clients map[string]*ent.Client
	sync.Mutex
}

func (m *middleware) handle(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, req *http.Request) {
		client, err := m.tenantClient(req)
		if err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}
		ctx := ent.NewContext(req.Context(), client)
		next.ServeHTTP(w, req.WithContext(ctx))
	})
}

func (m *middleware) tenantClient(r *http.Request) (*ent.Client, error) {
	m.Lock()
	defer m.Unlock()
	name := r.Header.Get(Header)
	if name == "" {
		return nil, fmt.Errorf("missing tenant ID")
	}
	client, ok := m.clients[name]
	if !ok {
		return ent.Open(m.dialect, m.urlFor(name))
	}
	return client, nil
}

func (m *middleware) urlFor(t string) string {
	u := *m.url
	q := u.Query()
	q.Set("search_path", t)
	u.RawQuery = q.Encode()
	return u.String()
}
```
当请求到来时，中间件从请求头中提取租户 ID，并使用它为该租户创建一个作用域数据库客户端。方法 `urlFor` 修改数据库 URL，将 `search_path` 设置为租户的架构，这使我们能够使用相同的数据库连接为所有租户提供服务，同时隔离他们的数据。我们使用 `sync.Mutex` 来确保 `clients` 映射是线程安全的，因为多个请求可以同时到来。

这种方法有几个优点：

1. 单租户开发者体验：开发者可以编写单租户代码，而无需担心租户逻辑，因为中间件处理了请求的作用域。
2. 伪物理隔离：每个租户的数据都隔离在其自己的模式中，这提供了良好的隔离级别，同时仍然保持成本较低。我们依赖于数据库来执行数据隔离，因此无需担心租户之间意外泄露数据。
3. 私有数据库实例：如果需要，我们可以通过为每个租户创建单独的数据库实例来轻松切换到物理隔离模型，因为中间件也可以适应这种情况。在这些情况下，我们可以为重要的租户分配专用资源，从而保护它们免受嘈杂邻居的影响。
4. VPC 对等连接：如果需要，我们也可以在每个租户中分别运行在独立的 VPC 或云账户中，因为中间件也可以适应这种情况。

#### 为什么在所有地方都不使用每个租户一个模式？

如果你在网上搜索数据库或租户专用模式，你会很快发现这种方法被许多人所不喜。甚至有位工程师写了这样一段话：

> "这个架构决策是我最大的悔恨之一，我们目前正在重建为单一数据库模型。"

这种方法的缺点主要在于管理单个数据库中的大量模式所面临的挑战：

- 迁移时间线性增长。当你需要运行迁移时，它必须应用于所有模式。这可能导致迁移时间过长，特别是如果你有很多租户。
- 检测和修复不一致性很困难。最终，某些模式可能与其他模式产生分歧，导致难以检测和修复的不一致性。这变成了大海捞针的棘手问题。
- 回滚很困难。如果你需要回滚一个迁移，你需要为所有模式回滚，这很难管理，并可能导致租户停机。

为了解决这些问题，我们在 Atlas 中集成了按租户模式的支持（几乎是从一开始就集成了）。Atlas 提供了一种定义“目标组”的方法，允许你在部分模式上运行迁移，这有助于管理大量模式。例如：

```hcl
data "sql" "tenants" {
  url = var.url
  query = <<EOS
SELECT `schema_name`
  FROM `information_schema`.`schemata`
  WHERE `schema_name` LIKE ?
EOS
  args = [local.pattern]
}

env "prod" {
  for_each = toset(data.sql.tenants.values)
  url      = urlsetpath(var.url, each.value)
}
```



在这个示例中，我们定义了一个数据源，该数据源查询 `information_schema` 以获取所有匹配特定模式的所有模式列表。然后，我们使用此数据源为每个模式创建一个环境，这使我们能够在模式子集上运行迁移。这样，我们就可以在所有匹配模式的模式上运行迁移，而无需在 Atlas 配置中手动定义每个模式。

在合适的工具支持下，按租户配置模式可以非常有效地管理 Go 应用程序中的多租户。

要了解更多关于如何使用 Atlas 管理每个租户的架构或数据库的信息，请查看我们的专用指南。

###  结论

在这篇文章中，我们基于在构建 Atlas Cloud 后端的经验，探讨了在 Go 中构建可扩展多租户应用的不同策略。我们讨论了多租户的挑战以及如何通过利用逻辑隔离、ORM 中间件、行级安全性和租户级模式来克服这些挑战。以下是我主要的收获：

- 在必要时进行物理隔离。一些客户会因合规或安全原因要求物理隔离，这些通常是能够支付相关费用的企业，这使得问题变得相对容易解决！
- 注意逻辑隔离中的数据泄露风险。在使用逻辑隔离时，要小心确保数据始终限定在租户的 ID 范围内。这可以在每个请求中完成，也可以手动完成，但容易出错。
- 将复杂问题推给基础设施层。当我们遇到一个既容易出错又影响重大的问题时，我们应该尝试将其推给基础设施层，这样开发人员就不需要在日常工作中担心这些问题。
- 按租户分架构如果拥有良好的工具会非常出色。虽然不太常见，但按租户分架构可以是非常有效的方式来管理 Go 应用程序中的多租户，特别是如果你有合适的工具来管理它。Atlas 提供了一种定义目标组的方式，允许你在架构子集上运行迁移，这有助于管理大量的架构。

我在 GopherCon 上做这次演讲非常愉快，希望对你们有帮助。如果你有任何问题或评论，欢迎在 Discord 服务器上联系我们。