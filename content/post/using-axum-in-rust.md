---
title: "在 Rust 中使用 Axum【译】"
date: 2024-01-30
tags: ["rust"]
draft: false
---
> 本文原文地址为 https://www.shuttle.rs/blog/2023/12/06/using-axum-rust

Rust Web 生态系统中有如此多的后端 Web 框架，很难知道该选择什么。尽管在更早的过去，您可能会看到 Rocket 在受欢迎程度方面跃居排行榜首位，但现在通常是 Axum 和 actix-web 展开激烈的竞争，Axum 慢慢地登上了榜首。在本文中，我们将深入研究 Axum，这是一个由 Tokio 团队支持的用于制作 Rust REST API 的 Web 框架，它易于使用，并且与 Tower 具有超兼容性，Tower 是一个强大的可重用、模块化组件库，用于构建网络应用程序。

在本文中，我们将全面了解如何使用 Axum 编写 Web 服务。这也将包括[ 0.7 的更改](https://github.com/tokio-rs/axum/releases/tag/axum-v0.7.0)。

## Axum的路由

Axum 遵循 REST 风格的 API（例如 Express）的风格，您可以在其中创建处理函数并将它们附加到 axum 的 `axum::Router` 类型。路线的示例可能如下所示：

```rust
async fn hello_world() -> &'static str {
    "Hello world!"
}
```

然后我们可以将它添加到我们的路由器中，如下所示：

```rust
use axum::{Router, routing::get};

fn init_router() -> Router {
    Router::new()
        .route("/", get(hello_world))
}
```

为了使处理函数有效，它需要是 `axum::response::Response` 类型或实现 `axum::response::IntoResponse` 。这已经针对大多数原始类型和 Axum 自己的所有类型实现了 - 例如，如果我们想要将一些 JSON 数据发送回用户，我们可以使用 Axum 的 JSON 类型作为返回类型来轻松实现这一点， `axum::Json` 类型包装了我们想要发回的任何内容。正如您在上面看到的，我们还可以单独返回一个字符串（切片）。

我们还可以直接使用 `impl IntoResponse` ，乍一看，它立即解决了我们需要返回什么类型的问题；但是，直接使用它也意味着确保所有返回类型都是相同的类型！这意味着我们可能会遇到不必要的错误。我们可以为枚举或结构实现 `IntoResponse` ，然后将其用作返回类型。见下文：

```rust
use axum::{response::{Response, IntoResponse}, Json, http::StatusCode};
use serde::Serialize;

// here we show a type that implements Serialize + Send
#[derive(Serialize)]
struct Message {
    message: String
}

enum ApiResponse {
    OK,
    Created,
    JsonData(Vec<Message>),
}

impl IntoResponse for ApiResponse {
    fn into_response(self) -> Response {
        match self {
            Self::OK => (StatusCode::OK).into_response(),
            Self::Created => (StatusCode::CREATED).into_response(),
            Self::JsonData(data) => (StatusCode::OK, Json(data)).into_response()
        }
    }
}
```

然后，您将在处理程序函数中实现枚举，如下所示：

```rust
async fn my_function() -> ApiResponse {
    // ... rest of your code
}
```

当然，我们也可以使用Result类型来返回！虽然错误类型在技术上也接受任何可以转换为 HTTP 响应的内容，但我们还可以实现一个错误类型，它可以说明 HTTP 请求在我们的应用程序中失败的几种不同方式，就像我们对成功的 HTTP 请求枚举所做的那样。见下文：

```rust
enum ApiError {
    BadRequest,
    Forbidden,
    Unauthorised,
    InternalServerError
}

// ... your IntoResponse implementation goes here

async fn my_function() -> Result<ApiResponse, ApiError> {
    // ... your code
}
```

这使我们能够在编写 Axum 路由时区分错误和成功请求。

## 在 Axum 中添加数据库

通常，在设置数据库时，您可能需要设置数据库连接：

```rust
use axum::{Router, routing::get};
use sqlx::PgPoolOptions;

#[derive(Clone)]
struct AppState {
    db: PgPool
}

#[tokio::main]
async fn main() {
    let pool = PgPoolOptions::new()
        .max_connections(5)
        .connect(<db-connection-string-here>).await;

    let state = AppState { pool };
        
    let router = Router::new().route("/", get(hello_world)).with_state(state);
    
    //... rest of your code
}
```

然后，您需要配置自己的 Postgres 实例，无论是本地安装在计算机上、通过 Docker 或其他方式配置。但是，使用 Shuttle，我们可以消除这种情况，因为运行时会为您配置数据库：

```rust
#[shuttle_runtime::main]
async fn axum(
    #[shuttle_shared_db::Postgres] pool: PgPool,
) -> shuttle_axum::ShuttleAxum {
    let state = AppState { pool };
    
    // .. the rest of your code
}
```

在本地，这是通过 Docker 完成的，但在部署中，有一个总体流程可以为您完成此操作！不需要额外的工作。我们还有一个 AWS RDS 数据库产品，需要零 AWS 知识才能设置 - 请访问[此处](https://shuttle.rs/pricing)了解更多信息。

## Axum中的应用程序状态

现在您可能想知道，“我如何存储我的数据库池和其他状态范围的变量？我不想每次想做某事时都初始化我的连接池！” - 这是一个完全有效的问题并且很容易回答！您可能已经注意到，在我们使用 `axum::Extension` 来存储它之前 - 这对于某些用例来说非常好，但存在不完全类型安全的缺点。在大多数 Rust Web 框架（包括 Axum）中，我们使用所谓的“应用程序状态”——一个专门用于保存您想要在应用程序上的路由之间共享的所有变量的结构。在 Axum 中执行此操作的唯一要求是该结构需要实现 `Clone` ，我们可以这样做。例如：

```rust
use sqlx::PgPool; // this is a Postgres connection pool

#[derive(Clone)]
struct AppState {
    pool: PgPool,
}

#[shuttle_runtime::main]
async fn axum(
    #[shuttle_shared_db::Postgres] pool: PgPool,
) -> shuttle_axum::ShuttleAxum {
    let state = AppState { pool };
    
    // .. the rest of your code
}
```

要使用它，我们将其插入到路由器中，并通过将其作为参数传递来将状态添加到我们的函数中：

```rust
use axum::{Router, routing::get, extract::State};

fn init_router() -> Router {
    Router::new()
        .route("/", get(hello_world))
        .route("/do_something", get(do_something))
        .with_state(state)
}

// note that adding the app state is not mandatory - only if you want to use it
async fn hello_world() -> &'static str {
    "Hello world!"
}

async fn do_something(
    State(state): State<AppState>
) -> Result<ApiResponse, ApiError> {
    // .. your code
}
```

还应该注意的是，您还可以将应用程序状态结构包装在原子引用计数器中（供参考），而不是使用 `#[derive(Clone)]` 。弧是垃圾收集的一种形式，它跟踪有多少克隆，并且只有在没有剩余副本时才会丢弃 - 在 Rust 中是一个值得了解的类型。这将如下完成：

```rust
use std::sync::Arc;

let state = Arc::new(AppState { db });
```

现在将状态添加到应用程序时，您需要确保将状态提取器类型引用为 `State<Arc<AppState>>` 而不是 `State<AppState>` 。

从个人观察来看，似乎并不清楚哪种方法更好。 `Arcs` 可能会在微基准测试中表现更好，但这是否会带来现实世界的改进可能取决于您的用例。

您还可以从应用程序状态派生子状态！当我们需要来自主状态的一些变量但想要限制对给定路由可以访问的内容的访问控制时，这非常有用。见下文：

```rust
// the application state
#[derive(Clone)]
struct AppState {
    // that holds some api specific state
    api_state: ApiState,
}

// the api specific state
#[derive(Clone)]
struct ApiState {}

// support converting an `AppState` in an `ApiState`
impl FromRef<AppState> for ApiState {
    fn from_ref(app_state: &AppState) -> ApiState {
        app_state.api_state.clone()
    }
}
```

##  Axum的提取器

提取器正是这样：它们从 HTTP 请求中提取内容，并允许您将它们作为参数传递到处理函数中。目前，它已经为广泛的事物提供了本机支持，例如获取单独的标头、路径和查询、表单和 JSON，以及对 MsgPack、JWT 提取器等事物的社区支持！您还可以创建自己的提取器，我们稍后会介绍。

例如，我们可以使用 `axum::Json` 类型通过从 HTTP 请求中提取 JSON 请求正文来消费 HTTP 请求。请参阅下文了解如何完成此操作：

```rust
use axum::Json;
use serde_json::Value;

async fn my_function(
    Json(json): Json<Value>
) -> Result<ApiResponse, ApiError> {
    // ... your code
}
```

然而，这可能不太符合人体工程学，因为我们使用的 `serde_json::Value` 是未成形的并且可以包含任何东西！让我们使用实现 `serde::Deserialize` 的 Rust 结构再试一次 - 它需要能够将原始数据转换为结构本身：

```rust
use axum::Json;
use serde::Deserialize;

#[derive(Deserialize)]
pub struct Submission {
    message: String
}

async fn my_function(
    Json(json): Json<Submission>
) -> Result<ApiResponse, ApiError> {
    println!("{}", json.message);
    
    // ... your code
}
```

请注意，结构中不存在的任何字段都将被忽略 - 根据您的用例，这可能是一件好事；例如，如果您收到 Webhook 但只想查看 Webhook 请求中的某些字段。

通过将适当的类型添加到处理函数中，可以以相同的方式处理表单和 URL 查询参数 - 例如，表单提取器可能如下所示：

```rust
async fn my_function(
    Form(form): Form<Submission>
) -> Result<ApiResponse, ApiError> {
    println!("{}", json.message);
    
    // ... your code
}
```

在 HTML 方面，当您向 API 发送 HTTP 请求时，您当然还需要确保发送正确的内容类型。

标头也可以以相同的方式处理，只是标头不消耗请求正文 - 这意味着您可以使用任意数量的标头！我们可以使用 `TypedHeader` 类型来做到这一点。对于 Axum 0.6，您需要启用 `headers` 功能，但在 0.7 中，此功能已移至 `axum-extra` 箱，您需要添加 `typed-header` 功能，像这样：

```bash
cargo add axum-extra -F typed-header
```

使用类型化标头就像将其作为参数添加到处理函数一样简单：

```rust
use headers::ContentType;
use axum::{TypedHeader, headers::Origin}; // use this if on axum 0.6
use axum_extra::{TypedHeader, headers::Origin}; // use this if on axum 0.7

async fn my_function(
    TypedHeader(origin): TypedHeader<Origin>
) -> Result<ApiResponse, ApiError> {
    println!("{}", origin.hostname);
    
    // ... your code
}
```

您可以在[此处](https://docs.rs/axum-extra/latest/axum_extra/struct.TypedHeader.html)找到 `TypedHeader` 提取器/响应的文档。

除了 `TypedHeaders` 之外， `axum-extra` 还提供了许多其他我们可以使用的有用类型。例如，它有一个 `CookieJar` 提取器，有助于管理 cookie，并且在 cookie jar 中内置了其他功能，例如在需要时具有加密安全性（尽管应该注意，有不同的 cookie jar 功能，具体取决于您需要哪一个），以及一个用于使用 gRPC 的 `protobuf` 提取器。您可以在[此处](https://docs.rs/axum-extra/latest/axum_extra/index.html)找到该库的文档。

## Axum的定制提取器

现在我们对提取器有了更多的了解，您可能想知道如何创建自己的提取器 - 例如，假设您需要创建一个提取器，该提取器根据请求正文是 Json 还是 Form 进行解析。让我们设置结构体和处理函数：

```rust
#[derive(Debug, Serialize, Deserialize)]
struct Payload {
    foo: String,
}

async fn handler(JsonOrForm(payload): JsonOrForm<Payload>) {
    dbg!(payload);
}

struct JsonOrForm<T>(T);
```

现在我们可以为 `JsonOrForm` 结构实现 `FromRequest<S, B>` 了！

```rust
#[async_trait]
impl<S, B, T> FromRequest<S, B> for JsonOrForm<T>
where
    B: Send + 'static,
    S: Send + Sync,
    Json<T>: FromRequest<(), B>,
    Form<T>: FromRequest<(), B>,
    T: 'static,
{
    type Rejection = Response;

    async fn from_request(req: Request<B>, _state: &S) -> Result<Self, Self::Rejection> {
        let content_type_header = req.headers().get(CONTENT_TYPE);
        let content_type = content_type_header.and_then(|value| value.to_str().ok());

        if let Some(content_type) = content_type {
            if content_type.starts_with("application/json") {
                let Json(payload) = req.extract().await.map_err(IntoResponse::into_response)?;
                return Ok(Self(payload));
            }

            if content_type.starts_with("application/x-www-form-urlencoded") {
                let Form(payload) = req.extract().await.map_err(IntoResponse::into_response)?;
                return Ok(Self(payload));
            }
        }

        Err(StatusCode::UNSUPPORTED_MEDIA_TYPE.into_response())
    }
}
```

在 Axum 0.7 中，对此进行了轻微修改。 `axum::body::Body` 现在不再是 `hyper::body::Body` 的重新导出，而是它自己的类型 - 这意味着它不再是通用的，并且 `Request` 类型将始终使用 `axum::body::Body` 。这实质上意味着我们只是删除了 `B` 泛型 - 见下文：

```rust
#[async_trait]
impl<S, T> FromRequest<S> for JsonOrForm<T>
where
    S: Send + Sync,
    Json<T>: FromRequest<()>,
    Form<T>: FromRequest<()>,
    T: 'static,
{
    type Rejection = Response;

    async fn from_request(req: Request, _state: &S) -> Result<Self, Self::Rejection> {
        let content_type_header = req.headers().get(CONTENT_TYPE);
        let content_type = content_type_header.and_then(|value| value.to_str().ok());

        if let Some(content_type) = content_type {
            if content_type.starts_with("application/json") {
                let Json(payload) = req.extract().await.map_err(IntoResponse::into_response)?;
                return Ok(Self(payload));
            }

            if content_type.starts_with("application/x-www-form-urlencoded") {
                let Form(payload) = req.extract().await.map_err(IntoResponse::into_response)?;
                return Ok(Self(payload));
            }
        }

        Err(StatusCode::UNSUPPORTED_MEDIA_TYPE.into_response())
    }
}
```

##  Axum的中间件

如前所述，Axum 相对于其他框架的一大优势是它与 `tower` 箱超兼容，这意味着我们可以有效地使用 Rust API 所需的任何 Tower 中间件！例如，我们可以添加一个 Tower 中间件来压缩响应：

```rust
use tower_http::compression::CompressionLayer;
use axum::{routing::get, Router};

fn init_router() -> Router {
    Router::new().route("/", get(hello_world)).layer(CompressionLayer::new)
}
```

有许多由 Tower 中间件组成的 crate 可供使用，甚至无需我们自己编写任何中间件！如果您已经在任何应用程序中使用 Tower 中间件，那么这是重复使用中间件的好方法，而无需编写更多代码，因为兼容性确保不会出现任何问题。

我们还可以通过编写函数来创建自己的中间件。该函数需要对 `Request` 和 `Next` 类型进行 `<B>` 通用绑定，因为 Axum 的主体类型在 0.6 中是通用的。请参阅下面的示例：

```rust
use axum::{http::Request, middleware::Next};

async fn check_hello_world<B>(
    req: Request<B>,
    next: Next<B>
) -> Result<Response, StatusCode> {
    // requires the http crate to get the header name
    if req.headers().get(CONTENT_TYPE).unwrap() != "application/json" {
        return Err(StatusCode::BAD_REQUEST);
    }

    Ok(next.run(req).await)
}
```

在 Axum 0.7 中，您需要删除 `<B>` 约束，因为 Axum 的 `axum::body::Body` 类型不再通用：

```rust
use axum::{http::Request, middleware::Next};

async fn check_hello_world(
    req: Request,
    next: Next
) -> Result<Response, StatusCode> {
    // requires the http crate to get the header name
    if req.headers().get(CONTENT_TYPE).unwrap() != "application/json" {
        return Err(StatusCode::BAD_REQUEST);
    }

    Ok(next.run(req).await)
}
```

为了实现我们在应用程序中创建的新中间件，我们想要使用 axum 的 `axum::middleware::from_fn` 函数，它允许我们使用函数作为处理程序。实际上它看起来像这样：

```rust
use axum::middleware::self;

fn init_router() -> Router {
    Router::new().route("/", get(hello_world)).layer(middleware::from_fn(check_hello_world))
}
```

如果您需要将应用程序状态添加到中间件，可以将其添加到处理函数，然后使用 `middleware::from_fn_with_state` ：

```rust
fn init_router() -> Router {
    let state = setup_state(); // app state initialisation goes here
    
    Router::new()
        .route("/", get(hello_world))
        .layer(middleware::from_fn_with_state(state.clone(), check_hello_world))
        .with_state(state)
}
```

## 在 Axum 中提供静态文件

假设您想使用 Axum 提供一些静态文件 - 或者您有一个使用 React 等前端 JavaScript 框架制作的应用程序，并且您希望将其与 Rust Axum 后端结合起来制作一个大型应用程序，而不必托管您的前端和后端分开。你会怎么做？

Axum 本身没有能力做到这一点；然而，它确实具有与 `tower-http` 的超强兼容性，无论您是运行 SPA、从 Next.js 等框架静态生成的文件还是简单地提供服务您自己的静态文件的实用程序只是原始的 HTML、CSS 和 JavaScript。

如果您使用静态生成的文件，您可以轻松地将其放入路由器中（假设您的静态文件位于项目根目录的 `dist` 文件夹中）：



```rust
use tower_http::services::ServeDir;

fn init_router() -> Router {
    Router::new()
        .nest_service("/", ServeDir::new("dist"))
}
```

如果您使用的是 React、Vue 或类似的 SPA，您可以将资产构建到相关文件夹中，然后使用以下命令：

```rust
use tower_http::services::{ServeDir, ServeFile};


fn init_router() -> Router {
    Router::new().nest_service(
         "/", ServeDir::new("dist")
        .not_found_service(ServeFile::new("dist/index.html")),
    )
}
```

您还可以将 HTML 模板与 [`askama`](https://github.com/djc/askama) 、 [`tera`](https://github.com/Keats/tera) 和 [`maud`](https://maud.lambda.xyz/) 等包一起使用！这可以与 [`htmx`](https://htmx.org/) 等轻量级 JavaScript 库的强大功能相结合，以加快生产时间。您可以在我们的另一篇关于[将 HTMX 与 Rust 结合使用](https://www.shuttle.rs/blog/2023/10/25/htmx-with-rust)的文章中阅读更多相关信息，您可以在这里找到该文章。我们还与 [Stefan Baumgartner](https://fettblog.eu/) 合作撰写了一篇[使用 Askama 提供 HTML ](https://www.shuttle.rs/launchpad/issues/2023-10-17-issue-10-Serving-HTML)的文章！

## 如何部署 Axum

由于必须使用 Dockerfile，使用 Rust 后端程序进行部署通常可能不太理想，尽管如果您已经有使用 Docker 的经验，这对您来说可能不是一个问题 - 特别是如果您使用 `cargo-chef` 。但是，如果您使用的是 Shuttle，则只需使用 `cargo shuttle deploy` 即可完成。无需设置。

##  整理起来

谢谢阅读！ Axum 是一个很棒的框架，拥有强大的团队支持，并且与 Rust Web 生态系统高度兼容，我们相信现在是开始用 Rust 编写 REST API 的最佳时机。

 有兴趣了解更多吗？

- 在[这里](https://www.shuttle.rs/blog/2022/08/11/authentication-tutorial)查看如何在 Axum 中实现身份验证！
- 在[此处](https://www.shuttle.rs/blog/2023/09/20/logging-in-rust)查看如何开始记录 Web 应用程序。
