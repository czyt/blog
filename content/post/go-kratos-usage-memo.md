---
title: "go-kratos使用备忘"
date: 2022-08-12
tags: ["golang", "kratos"]
weight: 10
draft: false
---
> 我搭建的一个kratos项目模板，欢迎使用，[仓库地址](https://github.com/tpl-x/kratos)

## 需要特别注意的一些建议

### API路由覆盖的问题
比如有两个接口 A `get /v1/user/{user_id}`和 B `get /v1/user/profile`如果A定义在B之前，那么B可能会被A覆盖路由。需要将A放到B之前。

### JWT使用的建议

>摘自极客时间课程[《高并发系统实战课》](https://time.geekbang.org/column/article/597664)

+ 通讯过程必须使用 HTTPS 协议，这样才可以降低被拦截的可能。
+ 要注意限制 token 的更换次数，并定期刷新 token，比如用户的 access_token 每天只能更换 50 次，超过了就要求用户重新登陆，同时 token 每隔 15 分钟更换一次。这样可以降低 token 被盗取后给用户带来的影响。
+ Web 用户的 token 保存在 cookie 中时，建议加上 httponly、SameSite=Strict 限制，以防止 cookie 被一些特殊脚本偷走。

## 配置文件

### 配置文件校验

配合buf的validate可以方便地进行配置文件的校验，在程序启动之前就对配置文件进行一次校验。下面是一个简单的proto配置定义

```protobuf
syntax = "proto3";
package conf;

import "buf/validate/validate.proto";
import "google/protobuf/duration.proto";

option go_package = "github.com/tpl-x/kratos/internal/conf;conf";

message Bootstrap {
  Server server = 1;
  Data data = 2;
  Log log = 3;
}

message Server {
  message HTTP {
    string network = 1;
    string addr = 2;
    google.protobuf.Duration timeout = 3 [
      // the field is required
      (buf.validate.field).required = true,
      // duration must be longer than 1 second but no longer than 10 min.
      (buf.validate.field).duration = {
        // Validates that duration is greater than 1 second
        gt: {seconds: 1}
        // Validates that duration is less than or equal to 10 min.
        lte: {seconds: 600}
      }
    ];
  }
  message GRPC {
    string network = 1;
    string addr = 2;
    google.protobuf.Duration timeout = 3 [
      // the field is required
      (buf.validate.field).required = true,
      // duration must be longer than 1 second but no longer than 10 min.
      (buf.validate.field).duration = {
        // Validates that duration is greater than 1 second
        gt: {seconds: 1}
        // Validates that duration is less than or equal to 10 min.
        lte: {seconds: 600}
      }
    ];
  }
  HTTP http = 1;
  GRPC grpc = 2;
}

message Data {
  message Database {
    string driver = 1;
    string source = 2;
  }
  message Redis {
    string network = 1;
    string addr = 2;
    google.protobuf.Duration read_timeout = 3;
    google.protobuf.Duration write_timeout = 4;
  }
  Database database = 1;
  Redis redis = 2;
}

enum LogLevel {
  Debug = 0;
  Info = 1;
  Warn = 2;
  Error = 3;
  Fatal = 4;
}

message Log {
  string log_path = 1;
  LogLevel log_level = 2 [(buf.validate.field).enum = {
    defined_only: true
    in: [
      0,
      1,
      2,
      3,
      4
    ]
  }];
  int32 max_size = 3;
  int32 max_keep_days = 4;
  int32 max_keep_files = 5;
  bool compress = 6;
}
```

生成proto对应的go文件中以后，就可以通过下面的方式进行校验：

```go
var bc conf.Bootstrap
if err := c.Scan(&bc); err != nil {
    panic(err)
}

// create  validator to apply validation rules before boot app
validator, err := protovalidate.New()
if err != nil {
    panic(err)
}
```

### 多种格式配置文件的调整

kratos已经默认支持了下面的这些配置文件格式（不包含配置中心）：

- json
- proto
- xml
- yaml

那么如果我们想扩展，支持其他的格式的配置文件选项，应该怎么做呢？按照[官方的文档](https://go-kratos.dev/docs/component/config),我们这里以toml为例，分步实现这个目的：

1. 实现encoding，下面是一个简单的encoding的例子：

```go
package tomlencoding
import (
	"github.com/BurntSushi/toml"
	"github.com/go-kratos/kratos/v2/encoding"
)

// Name is the name registered for the xml codec.
const Name = "toml"

func init() {
	encoding.RegisterCodec(codec{})
}

// codec is a Codec implementation with xml.
type codec struct{}

func (codec) Marshal(v interface{}) ([]byte, error) {
	return toml.Marshal(v)
}

func (codec) Unmarshal(data []byte, v interface{}) error {
	return toml.Unmarshal(data, v)
}

func (codec) Name() string {
	return Name
}
```

然后在main主程序以`_`引入即可，例如我们这里是`_ "demo/internal/pkg/tomlencoding"`

2. 实现resolver。Resolver用于对解析完毕后的map结构进行再次处理。比如toml的key是`MyTiltle`,yaml中的key是`my_tiltle`，就需要在这里进行统一。

   ```go
   func resolver(input map[string]interface{}) error {
       // key: 文件中的key
       // value：文件中的对应key值
   	return nil
   }
   ```

   然后再启用这个resolver

   ```go
   s := file.NewSource("configs")
   	cfg := config.New(
   		config.WithSource(s),
   		config.WithResolver(resolver),
   	)
   ```

## 自定义接口返回内容

+ 正常的响应序列化逻辑通过[Response Encoder](https://go-kratos.dev/docs/component/transport/http#responseencoderen-encoderesponsefunc-serveroption)实现。

+ 错误的序列化逻辑通过[ErrorEncoder](https://go-kratos.dev/docs/component/transport/http#errorencoderen-encodeerrorfunc-serveroption)实现。

**注意**：自定义Encoder后，可能会遇到零值字段被忽略的情况，可以参考这个[issue](https://github.com/go-kratos/kratos/issues/1952)。具体的解决办法是

  1. proto定义返回内容，然后将生成的类型在encoder中使用。
  
  2. 简单代码大致如下：
  
     proto定义
  
     ```protobuf
     import "google/protobuf/any.proto";
     // BaseResponse is the  base response
     message BaseResponse{
       int32  code = 1 [json_name = "code"];
       google.protobuf.Any data = 2 [json_name = "data"];
     }
     ```
  
     go代码
  
     ```go
     func CustomResponseEncoder() http.ServerOption {
     	return http.ResponseEncoder(func(w http.ResponseWriter, r *http.Request, i interface{}) error {
     		reply := &v1.BaseResponse{
     			Code: 0,
     		}
     		if m, ok := i.(proto.Message); ok {
     			payload, err := anypb.New(m)
     			if err != nil {
     				return err
     			}
     			reply.Data = payload
     		}
     
     		//reply := &Response{
     		//	Code: 0,
     		//	Data: i,
     		//}
     		codec := encoding.GetCodec("json")
     		data, err := codec.Marshal(reply)
     		if err != nil {
     			return err
     		}
     		w.Header().Set("Content-Type", "application/json")
     		w.Write(data)
     		return nil
     	})
     }
     ```
  
     需要注意的是如果涉及enum但现有接口返回是int的情况，需要把官方的json codec拷贝出来在`MarshalOptions`添加一个选项 
  
     ```go
     MarshalOptions = protojson.MarshalOptions{
     		EmitUnpopulated: true,
     		UseEnumNumbers:  true,
     ```
     然后通过下面的代码注册json的codec即可使返回的enum使用数值而不是字符串。
  
     ```go
     import "github.com/go-kratos/kratos/v2/encoding"
     func init() {
     	encoding.RegisterCodec(codec{})
     }
     ```
  
     有个问题就是返回的json中会多出`"@type": "type.googleapis.comxxxxx"`这样的一个字段。
     
     > 零值问题，还可以通过脚本将json tag清除 群友 Ccheers提供
     >
     > ```bash
     > ifeq ($(GOHOSTOS), darwin)
     > 	find ./pb -name '*.pb.go' -exec  sed -i "" -e "s/,omitempty/,optional/g" {} \;
     > else
     > 	find ./pb -name '*.pb.go' -exec  sed -i -e "s/,omitempty/,optional/g" {} \;
     > endif
     > ```

HTTP API 的错误响应还有一些业界的标准，比如RFC 7807、RFC 9457等，感兴趣的可以参考下这篇文章 [HTTP API 的错误响应标准](https://www.jitao.tech/posts/problem-details-for-http-apis) 。在讨论到合理的错误码的时候，可以参考极客时间专栏《Go 语言项目开发实战》的内容。下面是节选

>错误码设计建议
>
>一套优秀的错误码设计思路：
>
>+ 有区别于http status code的业务码，业务码需要有一定规则，可以通过业务码判断出是哪类错误。
>+ 请求出错时，可以通过http status code直接感知到请求出错。
>+ 需要在请求出错时，返回详细的信息，通常包括 3 类信息：业务 Code 码、错误信息和参考文档（可选）。
>+ 返回的错误信息，需要是可以直接展示给用户的安全信息，也就是说不能包含敏感信息；同时也要有内部更详细的错误信息，方便 debug。返回的数据格式应该是固定的、规范的。错误信息要保持简洁，并且提供有用的信息。
>
>业务 Code 码设计
>
>要解决业务 Code 码如何设计这个问题，我们先来看下为什么要引入业务 Code 码。在实际开发中，引入业务 Code 码有下面几个好处：
>
>+ 可以非常方便地定位问题和定位代码行（看到错误码知道什么意思、grep 错误码可以定位到错误码所在行、某个错误类型的唯一标识）。
>
>+ 错误码包含一定的信息，通过错误码可以判断出错误级别、错误模块和具体错误信息。
>
>+ Go 中的 HTTP 服务器开发都是引用 net/http 包，该包中只有 60 个错误码，基本都是跟 HTTP 请求相关的错误码，在一个大型系统中，这些错误码完全不够用，而且这些错误码跟业务没有任何关联，满足不了业务的需求。引入业务的 Code 码，则可以解决这些问题。
>
>+ 业务开发过程中，可能需要判断错误是哪种类型，以便做相应的逻辑处理，通过定制的错误可以很容易做到这点，例如：
>
>  ```go
>  if err == code.ErrBind {    ...}
>  ```
>
>  这里要注意，业务 Code 码可以是一个整数，也可以是一个整型字符串，还可以是一个字符型字符串，它是错误的唯一标识。
>
>  通过研究腾讯云、阿里云、新浪的开放 API，我发现新浪的 API Code 码设计更合理些。所以，我参考新浪的 Code 码设计，总结出了我推荐的 Code 码设计规范：纯数字表示，不同部位代表不同的服务，不同的模块。错误代码说明：10010110: 服务。01: 某个服务下的某个模块。01: 模块下的错误码序号，每个模块可以注册 100 个错误。通过100101可以知道这个错误是服务 A，数据库模块下的记录没有找到错误。你可能会问：按这种设计，每个模块下最多能注册 100 个错误，是不是有点少？其实在我看来，如果每个模块的错误码超过 100 个，要么说明这个模块太大了，建议拆分；要么说明错误码设计得不合理，共享性差，需要重新设计。

![img](http://webmachine.github.io/images/http-headers-status-v3.png)

## 通过Context取得信息

Server端取JWT中的key数据

```go
func getPayloadFromCtx(ctx context.Context, partName string) (string, error) {
	if claims, ok := jwt.FromContext(ctx); ok {
		if m, ok := claims.(jwtV4.MapClaims); ok {
			if v, ok := m[partName].(string); ok {
				return v, nil
			}
		}
	}
	return "", errors.New("invalid Jwt")
}
```

middleware中，还可以将context转换为`http.Transport`获取更多的信息。

```go
if tr, ok := transport.FromServerContext(ctx); ok {
    // 可以取header等信息
    if hr, ok := tr.(*http.Transport); ok {
      // 可以取request等信息
   }
}

```
在Service中设置响应的Header信息
```go
if httpCtx, ok := ctx.(http.Context); ok {
		httpCtx.Response().Header().Set("x-gopher", "czyt")
}
```

## 日志脱敏与过滤

需要对日志进行脱敏和过滤，使用 kratos的[日志过滤](https://go-kratos.dev/docs/component/log#filter-%E6%97%A5%E5%BF%97%E8%BF%87%E6%BB%A4)

```go
h := NewHelper(
    NewFilter(logger,
        // 等级过滤
        FilterLevel(log.LevelError),

        // 按key遮蔽
        FilterKey("username"),

        // 按value遮蔽
        FilterValue("hello"),

        // 自定义过滤函数
        FilterFunc(
            func (level Level, keyvals ...interface{}) bool {
                if level == LevelWarn {
                    return true
                }
                for i := 0; i < len(keyvals); i++ {
                    if keyvals[i] == "password" {
                        keyvals[i+1] = fuzzyStr
                    }
                }
                return false
            }
        ),
    ),
)

```

> - `FilterFunc(f func(level Level, keyvals ...interface{}) bool)` 使用自定义的函数来对日志进行处理，keyvals里为key和对应的value，按照奇偶进行读取即可

TODO:按奇偶进行读取的意思

## 一个接口对应多个httpPath

下面是官网的文档中的一个例子（[原文](https://go-kratos.dev/docs/component/api#%E5%AE%9A%E4%B9%89%E6%8E%A5%E5%8F%A3)）：

```protobuf
syntax = "proto3";

package helloworld.v1;

import "google/api/annotations.proto";

option go_package = "github.com/go-kratos/service-layout/api/helloworld/v1;v1";
option java_multiple_files = true;
option java_package = "dev.kratos.api.helloworld.v1";
option java_outer_classname = "HelloWorldProtoV1";

// The greeting service definition.
service Greeter {
  // Sends a greeting
  rpc SayHello (HelloRequest) returns (HelloReply)  {
    option (google.api.http) = {
        // 定义一个 GET 接口，并且把 name 映射到 HelloRequest
        get: "/helloworld/{name}",
        // 可以添加附加接口
        additional_bindings {
            // 定义一个 POST 接口，并且把 body 映射到 HelloRequest
            post: "/v1/greeter/say_hello",
            body: "*",
        }
    };
  }
}

// The request message containing the user's name.
message HelloRequest {
  string name = 1;
}

// The response message containing the greetings
message HelloReply {
  string message = 1;
}
```
## 支持QueryString的Post接口
Protobuf定义

```protobuf
rpc CreateUser(CreateUserRequest) returns (CreateUserResponse) {
    option (google.api.http) = {
      post: "/users",
      body: "user"
    };
  }
  
message CreateUserRequest {
  string password = 1;
  User user = 2;
}
message CreateUserResponse {
  string response = 1;
}

message User {
  string first_name = 1;
  string last_name = 2;
}
  
```

在service层代码可以直接取到对应参数

```go
func (s *GreeterService) CreateUser(ctx context.Context, req *v1.CreateUserRequest) (*v1.CreateUserResponse, error) {
	info := fmt.Sprintf("password:%s,userName:%s %s", req.Password, req.User.FirstName, req.User.LastName)
	return &v1.CreateUserResponse{Response: info}, nil
}
```



调用

```bash
curl --location -g --request POST 'http://127.0.0.1:8000/users?password=e77eEDab-BdAe-78BE-0979-2F798d9bBe4b \
--header 'Content-Type: application/json' \
--data-raw '{
    "first_name":"czyt",
    "last_name":"cn"
}'
```

返回

```json
{
    "response": "password:e77eEDab-BdAe-78BE-0979-2F798d9bBe4b,userName:czyt cn"
}
```



参考：

+ https://github.com/grpc-ecosystem/grpc-gateway/issues/234

+ https://stackoverflow.com/questions/59171594/grpc-define-proto-post-endpoint-accepts-both-body-and-request-params

  > 注意：接口url的定义要注意url覆盖的问题。调整proto中的定义顺序即可。

## 支持Websocket
### ws

下面的代码是[官方的例子 ](https://github.com/go-kratos/examples/blob/main/ws)

main.go

```go
package main

import (
	"log"

	"github.com/go-kratos/examples/ws/handler"
	"github.com/go-kratos/kratos/v2"
	"github.com/go-kratos/kratos/v2/transport/http"
	"github.com/gorilla/mux"
)

func main() {
	router := mux.NewRouter()
	router.HandleFunc("/ws", handler.WsHandler)

	httpSrv := http.NewServer(http.Address(":8080"))
	httpSrv.HandlePrefix("/", router)

	app := kratos.New(
		kratos.Name("ws"),
		kratos.Server(
			httpSrv,
		),
	)
	if err := app.Run(); err != nil {
		log.Println(err)
	}
}
```

handler.go

```go
package handler

import (
	"log"
	"net/http"

	"github.com/gorilla/websocket"
)

var upgrader = websocket.Upgrader{}

func WsHandler(w http.ResponseWriter, r *http.Request) {
	c, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Print("upgrade:", err)
		return
	}
	defer c.Close()
	for {
		mt, message, err := c.ReadMessage()
		if err != nil {
			log.Println("read:", err)
			break
		}
		log.Printf("recv: %s", message)
		err = c.WriteMessage(mt, message)
		if err != nil {
			log.Println("write:", err)
			break
		}
	}
}
```

webSocket工程化方面，我一般是在service层中通过context转换为`http.context`来传递到useCase层进行

```go

if httpCtx, ok := ctx.(http.Context); ok {
		if req.Id == "" {
			// 处理验证逻辑
		}
		if err := a.wsUc.HandleWebsocket(req.Id, httpCtx); err != nil {
			return nil, err
		}
  }
```

对应的UseCase代码

```go
upGrader = websocket.Upgrader{
		CheckOrigin: func(r *http.Request) bool {
			return true
		},
}

func HandleWebsocket(id string,httpCtx http.Context) error {
    conn, err := upGrader.Upgrade(ctx.Response(), ctx.Request(), nil)
	if err != nil {
		c.log.Error(err)
		return err
	}
	go handleWsMessage(id, conn)
	return nil
}
```
### wss

 webSocket服务如果要支持wss，一般必须监听tls，也就是说你需要相关的域名证书。有两种实现方式：

1. 使用autoTls。免费用Let's Encrypt的证书。这种方式需要强制使用443端口，对于部署了nginx的平台不是很友好。
2. 使用证书和证书key。这种方式比较推荐，没有端口强制要求。相关代码后续再进行更新。

另外再说下nginx下配置wss需要注意的几点：

1. proxy_pass 的时候是https的，比如你以前的ws的proxy_pass 是`http://ws/hello` 那么你的wss的proxy_pass就应该是`https://ws/hello`

2. 在https的网站映射下面，对应的是wss，而http对应的是ws。

参考下面的nginx配置：
```nginx
map $http_upgrade $connection_upgrade {
      default upgrade;
      '' close;
}

upstream tiny_wssserver {
   server 0.0.0.0:8079;
   ip_hash;
}

server {
    listen      80;
    server_name test.czyt.tech;
    location / {
         root /opt/web/home/;
         index  index.html index.htm;

    }

   location /ws {
     proxy_pass https://tiny_wssserver/ws;
     proxy_http_version 1.1;
     proxy_set_header Upgrade $http_upgrade;
     proxy_set_header Connection $connection_upgrade;
     proxy_set_header   Host $host;
     proxy_read_timeout 36000s;
   }
}


server {
    listen       443  ssl;
    server_name  test.czyt.tech;
    client_max_body_size 50m;

    ssl_certificate /opt/certs/certificates/test.czyt.tech.crt;
    ssl_certificate_key /opt/certs/certificates/test.czyt.tech.key;

    location / {
         root /opt/web/home/;
         index  index.html index.htm;

    }

   location /ws {
     proxy_pass https://tiny_wssserver/ws;
     proxy_http_version 1.1;
     proxy_set_header Upgrade $http_upgrade;
     proxy_set_header Connection $connection_upgrade;
     proxy_set_header   Host $host;
     proxy_read_timeout 36000s;
   }
}

```

## 支持文件上传

因为protobuf官方限制，并不能通过protobuf生成http服务，需要创建相关逻辑，参考[example](https://github.com/go-kratos/examples/tree/main/http/upload)中的实现：

```go
package main

import (
	"io"
	"log"
	"os"

	"github.com/go-kratos/kratos/v2"
	"github.com/go-kratos/kratos/v2/transport/http"
)

func uploadFile(ctx http.Context) error {
	req := ctx.Request()

	fileName := req.FormValue("name")
	file, handler, err := req.FormFile("file")
	if err != nil {
		return err
	}
	defer file.Close()

	f, err := os.OpenFile(handler.Filename, os.O_WRONLY|os.O_CREATE, 0o666)
	if err != nil {
		return err
	}
	defer f.Close()
	_, _ = io.Copy(f, file)

	return ctx.String(200, "File "+fileName+" Uploaded successfully")
}

func main() {
	httpSrv := http.NewServer(
		http.Address(":8000"),
	)
	route := httpSrv.Route("/")
	route.POST("/upload", uploadFile)

	app := kratos.New(
		kratos.Name("upload"),
		kratos.Server(
			httpSrv,
		),
	)
	if err := app.Run(); err != nil {
		log.Fatal(err)
	}
}
```
参考 https://freshman.tech/file-upload-golang/

> 在grpc网关的这个[issue](https://github.com/grpc-ecosystem/grpc-gateway/issues/500)，[emcfarlane](https://github.com/emcfarlane ) 给出了一个方案，也算提供了一种思路，但kratos不支持stream的rpc生成，暂未测试。
>
> 👋 hello, I've solved this in my gRPC-transcoding project https://github.com/emcfarlane/larking by letting the handler access the underlying reader/writer stream. The API is:
>
> ```
> func AsHTTPBodyReader(stream grpc.ServerStream, msg proto.Message) (io.Reader, error)
> func AsHTTPBodyWriter(stream grpc.ServerStream, msg proto.Message) (io.Writer, error)
> ```
>
> Which handles asserting the stream is a stream of google.api.HttpBody and correctly unmarshals the first payloads.
>
> So if you have an API like:
>
> ```
> import "google/api/httpbody.proto";
> 
> service Files {
>   rpc LargeUploadDownload(stream UploadFileRequest)
>       returns (stream google.api.HttpBody) {
>     option (google.api.http) = {
>       post : "/files/large/{filename}"
>       body : "file"
>     };
>   }
> }
> message UploadFileRequest {
>   string filename = 1;
>   google.api.HttpBody file = 2;
> }
> ```
>
> You can use the `AsHTTPBody` methods to access the reader and writer of the http request without chunking into streams of messages. Like:
>
> ```
> // LargeUploadDownload echoes the request body as the response body with contentType.
> func (s *asHTTPBodyServer) LargeUploadDownload(stream testpb.Files_LargeUploadDownloadServer) error {
> 	var req testpb.UploadFileRequest
> 	r, _ := larking.AsHTTPBodyReader(stream, &req)
> 	log.Printf("got %s!", req.Filename)
> 
> 	rsp := httpbody.HttpBody{
> 		ContentType: req.File.GetContentType(),
> 	}
> 	w, _ := larking.AsHTTPBodyWriter(stream, &rsp)
> 
> 	_, err := io.Copy(w, r)
> 	return err
> }
> ```

我们可以用下面的方式来优化上面的代码。首先在Service层加入一个方法，它传入一个http.Server ，来添加相应的route信息。然后按原来的方式进行service的初始化，最后在http.Server注入的时候，调用我们刚才申明的方法，添加route信息，再返回http.Server即可。

下面是一个相对规范的工程代码示例(去掉了相关业务代码)：

自定义的泛型处理代码

```go
import "github.com/gorilla/schema"

func UploadHandlerWithMiddleware[T comparable](ctx http.Context, fileFormKey string) (
	chain middleware.Middleware,
	request T,
	reader io.Reader,
	filename string,
	err error,
) {
		defer func() {
		if err := recover(); err != nil {
			log.Println("panic handled:", err)
		}
	}()
	if fileFormKey == "" {
		fileFormKey = "file"
	}
	// 读取文件
	file, fileHeader, err := ctx.Request().FormFile(fileFormKey)
	defer file.Close()
	if err != nil {
		return nil, request, nil, "", err
	}
	buf := bufPool.Get()
	defer bufPool.Put(buf)
	if _, err := io.Copy(buf, file); err != nil {
		return nil, request, nil, fileHeader.Filename, err
	}
   // 开始解析Form参数
	if err := ctx.Request().ParseForm(); err != nil {
		return nil, request, nil, "", err
	}
	if err := ctx.Request().ParseMultipartForm(32 << 20); err != nil {
		return nil, request, nil, "", err
	}
    // 如果获取的Form参数不为nil，那么就进行参数到对应类型的解析
	if form := ctx.Request().Form; form != nil {
		var decoder = schema.NewDecoder()
		t := new(T)
		if err := decoder.Decode(t, form); err == nil {
			request = *t
		}
	}
    // 获取这个ctx的middleware执行权，当然也可以在上一步获取
	h := ctx.Middleware
	return h, request, bytes.NewReader(buf.Bytes()), fileHeader.Filename, nil
}
```

在Service中调用

```go
func (u UploadService) RegisterUploadServiceHttpServer(svr *http.Server) {
	route := svr.Route("/")
	route.POST("/v1/upload/demo", u.uploadDemo)

}

// 上传更新处理逻辑
func (u UploadService) uploadDemo(ctx http.Context) error {
    // 指定Operation 这样可以进行路由白名单设置等操作
	http.SetOperation(ctx, "/upload.v1.UploadService/demo")
	lazyCreator, uploadDemoOpt, reader, filename, err := udhandler.UploadHandlerWithMiddleware[biz.UploadDemoOption](
		ctx,
		"file")
	if err != nil {
		return v1.ErrorInvalidUploadDemoRequest("invalid request:%v", err)
	}
	handler := u.uploadUc.UploadDemo(filename, reader, uploadDemoOpt)
	h := lazyCreator(handler)
	resp, err := h(ctx, uploadDemoOpt)
	if err != nil {
		return v1.ErrorInvalidUploadDemoRequest("invalid request:%v", err)
	}
	return ctx.JSON(200, resp)
}
```

在useCase的Biz中定义

```go

type UploadDemoOption struct {
	// 文件最大尺寸
	FileMaxSize int64 `schema:"file_max_size"`
	// 无损上传
	UploadWithNoLoss bool ` schema:"upload_with_no_loss"`
}

type UploadDemoResult struct {
	// 文件是否上传成功
	Success bool `json:"success"`
	// 文件下载链接
	FileDownloadUrl string `json:"file_download_url"`
}

func (a UploadUseCase) UploadImage(fileName string, reader io.Reader, uploadDemoOption UploadDemoOption) middleware.Handler {
	return func(ctx context.Context, req interface{}) (interface{}, error) {
        imageUploadResult:=UploadDemoResult{}
        ........
		return imageUploadResult, nil
	}
}
```

## 文件下载、导出服务

文件下载服务既可以是本地静态文件也可能是动态生成的，本质上就是将字节返回到客户端。在Kratos中我们可以将这部分逻辑由ResponseEncoder控制，也就是说我们可以先按proto定义服务，但是返回返回文件下载。

proto 定义

```protobuf
import "google/api/field_behavior.proto";
option go_package = "attachment;attachment";

message Attachment {
  string file_name = 1 [json_name = "file_name"];
  int64  content_length = 2 [json_name = "content_length"];
  bytes payload = 3 [(google.api.field_behavior)=REQUIRED];
}
```

自定义的ResponseEncoder

```go
func CustomResponseEncoder() http.ServerOption {
	return http.ResponseEncoder(func(w http.ResponseWriter, r *http.Request, i any) error {
		if asset, ok := i.(*attachment.Attachment); ok {
			err := handleAttachment(w, asset)
			if err != nil {
				return err
			}
			return nil
		}
		if m, ok := i.(proto.Message); ok {
			 // do other logics here
		}
           .......
	})
}

func handleAttachment(w http.ResponseWriter, attach *attachment.Attachment) error {
	w.Header().Set("Content-Disposition", attach.FileName)
	w.Header().Set("Content-Length", strconv.FormatInt(attach.ContentLength, 10))
	w.Header().Set("Content-Type", "application/octet-stream")
	_, err := w.Write(attach.Payload)
	if err != nil {
		return err
	}
	return nil
}
```

参考 [issue](https://github.com/go-kratos/kratos/issues/2073)

## 支持动态内容

### 实现json.RawMessage

在go中，json.RawMessage适用于延迟解析的场景，比如你定义了一个消息，这个消息有N种类型，那么消息的payload可以使用这种类型。

```
// RawMessage is a raw encoded JSON value.
// It implements Marshaler and Unmarshaler and can
// be used to delay JSON decoding or precompute a JSON encoding.
type RawMessage []byte
```

在protobuf中，只需要将字段定义为`byte`即可

```protobuf
message DeviceMsg{
    int32 msg_type = 1;
    bytes msg_payload = 2;
}
```

客户端在传递时，只需要将payload base64 encode下，即可。服务端再根据type动态解析。

### 使用`google.protobuf.Struct`

也可以将消息定义为`google.protobuf.Struct` 

>`Struct` represents a structured data value, consisting of fields which map to dynamically typed values. In some languages, `Struct` might be supported by a native representation. For example, in scripting languages like JS a struct is represented as an object. The details of that representation are described together with the proto support for the language.
>
>The JSON representation for `Struct` is JSON object.
>
>| Field name | Type                 | Description                      |
>| ---------- | -------------------- | -------------------------------- |
>| `fields`   | `map<string, Value>` | Map of dynamically typed values. |

Todo

参考链接：

+ [动态可扩展性和Protocol Buffer](https://skyao.io/post/201909-dynamic-extensibility-and-protocol-buffers/)

## 静态文件托管

官方例子

```go
package main

import (
	"embed"
	"log"
	"net/http"

	"github.com/go-kratos/kratos/v2"
	transhttp "github.com/go-kratos/kratos/v2/transport/http"
	"github.com/gorilla/mux"
)

//go:embed assets/*
var f embed.FS

func main() {
	router := mux.NewRouter()
	// example: /assets/index.html
	router.PathPrefix("/assets").Handler(http.FileServer(http.FS(f)))

	httpSrv := transhttp.NewServer(transhttp.Address(":8000"))
	httpSrv.HandlePrefix("/", router)

	app := kratos.New(
		kratos.Name("static"),
		kratos.Server(
			httpSrv,
		),
	)
	if err := app.Run(); err != nil {
		log.Fatal(err)
	}
}
```

## 自定义路由继承middleware

对于一些从proto不支持的场景，如文件上传等，就需要自定义路由，但是鉴权和认证可能是需要的，这些功能在kratos中是通过middleware来实现的。我们可以通过下面的方式来将middleware同样应用于自定义的路由。(代码未作优化，只是为了演示具体的实现)

```go
func NewHTTPServer(c *conf.Server, greeter *service.GreeterService, logger log.Logger) *http.Server {
	var opts = []http.ServerOption{
		http.Middleware(
			recovery.Recovery(),
			nop.UserAgent(),
		),
	}
	if c.Http.Network != "" {
		opts = append(opts, http.Network(c.Http.Network))
	}
	if c.Http.Addr != "" {
		opts = append(opts, http.Address(c.Http.Addr))
	}
	if c.Http.Timeout != nil {
		opts = append(opts, http.Timeout(c.Http.Timeout.AsDuration()))
	}
	srv := http.NewServer(opts...)
    // 自定义路由，添加一个echo的功能
	route := srv.Route("/")
	route.GET("/v1/echo/{requester}", EchoHandler)
	v1.RegisterGreeterHTTPServer(srv, greeter)
	return srv
}

// 请求体定义
type echoRequest struct {
	Requester string `json:"requester"`
}
// 响应
type echoResponse struct {
	Resp string `json:"resp"`
}

// 消息处理实现逻辑
func echo(ctx context.Context, req *echoRequest) (*echoResponse, error) {
	return &echoResponse{Resp: fmt.Sprintf("hello,%s", req.Requester)}, nil
}

// middware处理
func EchoHandler(ctx http.Context) error {
	var in echoRequest
	if err := ctx.BindQuery(&in); err != nil {
		return err
	}
	if err := ctx.BindVars(&in); err != nil {
		return err
	}
	h := ctx.Middleware(func(ctx context.Context, req interface{}) (interface{}, error) {
		return echo(ctx, req.(*echoRequest))
	})
	resp, err := h(ctx, &in)
	if err != nil {
		return err
	}
	reply := resp.(*echoResponse)
	return ctx.Result(200, reply)
}

```

middleware代码如下

```go
func UserAgent() middleware.Middleware {
	return func(handler middleware.Handler) middleware.Handler {
		return func(ctx context.Context, req interface{}) (reply interface{}, err error) {
			if tr, ok := transport.FromServerContext(ctx); ok {
				userAgent:=tr.RequestHeader().Get(userAgent)
				if strings.EqualFold(userAgent,"kratos-nb") {
					return nil, errors.New(403, "INVALID-UA", "user agent is invalid")
				}
			}
			return handler(ctx, req)
		}
	}
}
```

## 接口幂等性

关于幂等性，下面是GPT4的解释

>幂等性是一种在计算机科学和数学中的概念，用来描述一个操作无论执行多少次，其结果都是相同的特性。
>
>在Web API设计中，"幂等性"指的是一个HTTP请求方法无论调用多少次，服务器上的资源状态都不会发生改变。它常用于设计RESTful接口，并且HTTP协议中定义的某些方法（如GET, PUT, DELETE, HEAD, OPTIONS, TRACE）被定义为幂等的。
>
>例如，使用GET方法从服务器上获取资源就是幂等的，不论你调用一次或一百次，服务器上的资源状态都不会发生改变。
>
>同样，使用DELETE方法删除一个资源也是幂等的。第一次调用会删除资源，然后再多次调用对于服务器上的资源状态没有任何影响（因为资源已经在第一次调用时被删除了）。
>
>需要注意的一点是，幂等性并不意味着每次请求的返回结果都一样。例如，第一次DELETE请求可能返回200（成功），而接下来的DELETE请求可能返回404（未找到），因为资源已经在第一次请求时被删除了。
>
>除了上述的Get和DELETE方法，PUT方法也是幂等的。PUT是用来更新资源的，如果你多次发送相同的PUT请求，那么虽然服务器可能会多次执行更新操作，但是资源的最终状态都是一样的。
>
>这与POST方法不同，每次的POST请求都可能导致一个新资源的创建，因此它不是幂等的。

Kratos中，可以参考  https://github.com/go-cinch/layout/blob/dev/internal/server/middleware/idempotent.go 这样在要求幂等性的接口的时候，需要请求一个幂等性的token，用完就失效。

```go
package middleware

import (
	"context"

	"github.com/go-cinch/layout/api/auth"
	"github.com/go-cinch/layout/internal/biz"
	"github.com/go-kratos/kratos/v2/middleware"
	"github.com/go-kratos/kratos/v2/transport"
	kratosHttp "github.com/go-kratos/kratos/v2/transport/http"
)

const (
	WhitelistIdempotentCategory uint32 = 2
)

func Idempotent(authClient auth.AuthClient) middleware.Middleware {
	return func(handler middleware.Handler) middleware.Handler {
		return func(ctx context.Context, req interface{}) (rp interface{}, err error) {
			tr, ok := transport.FromServerContext(ctx)
			if !ok {
				err = biz.ErrIdempotentMissingToken(ctx)
				return
			}
			var method, path string
			switch tr.Kind() {
			case transport.KindHTTP:
				if ht, ok3 := tr.(kratosHttp.Transporter); ok3 {
					method = ht.Request().Method
					path = ht.Request().URL.Path
				}
			}
			// check idempotent blacklist
			whitelist, err := authClient.HasWhitelist(ctx, &auth.HasWhitelistRequest{
				Category: WhitelistIdempotentCategory,
				Permission: &auth.HasWhitelistRequest_CheckPermission{
					Resource: tr.Operation(),
					Method:   method,
					Uri:      path,
				},
			})
			if err != nil {
				return
			}
			if !whitelist.Ok {
				return handler(ctx, req)
			}
			// check idempotent token
			token := tr.RequestHeader().Get("x-idempotent")
			if token == "" {
				err = biz.ErrIdempotentMissingToken(ctx)
				return
			}
			_, err = authClient.CheckIdempotent(ctx, &auth.CheckIdempotentRequest{Token: token})
			if err != nil {
				return
			}
			return handler(ctx, req)
		}
	}
}
```

+ 文档说明   https://go-cinch.github.io/docs/#/base/7.idempotent
+ 代码 https://github.com/go-cinch/common/blob/main/idempotent/idempotent.go

## 重定向

[官方的例子](https://github.com/go-kratos/examples/blob/main/http/redirect/main.go)

```go
package main

import (
	"context"
	"fmt"
	"log"
	"net/http"

	"github.com/go-kratos/examples/helloworld/helloworld"
	"github.com/go-kratos/kratos/v2"
	"github.com/go-kratos/kratos/v2/errors"
	khttp "github.com/go-kratos/kratos/v2/transport/http"
)

type server struct {
	helloworld.UnimplementedGreeterServer
}

// SayHello implements helloworld.GreeterServer
func (s *server) SayHello(ctx context.Context, in *helloworld.HelloRequest) (*helloworld.HelloReply, error) {
	if in.Name == "error" {
		return nil, errors.BadRequest("custom_error", fmt.Sprintf("invalid argument %s", in.Name))
	}
	if in.Name == "panic" {
		panic("server panic")
	}
	return &helloworld.HelloReply{Message: fmt.Sprintf("Hello %+v", in.Name)}, nil
}

func redirectFilter(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path == "/helloworld/kratos" {
			http.Redirect(w, r, "https://go-kratos.dev/", http.StatusMovedPermanently)
			return
		}
		next.ServeHTTP(w, r)
	})
}

func main() {
	httpSrv := khttp.NewServer(
		khttp.Address(":8000"),
		khttp.Filter(redirectFilter),
	)
	s := &server{}
	helloworld.RegisterGreeterHTTPServer(httpSrv, s)

	app := kratos.New(
		kratos.Name("cors"),
		kratos.Server(
			httpSrv,
		),
	)
	if err := app.Run(); err != nil {
		log.Fatal(err)
	}
}
```

在实际的service代码中，可以写成下面这样：

```go
imports(
    	"github.com/go-kratos/kratos/v2/transport/http"
	stdHttp "net/http"
)
func (s xxService) Handlexxx(ctx context.Context, req *v1.HandlexxxRequest) (resp *v1.HandlexxxResponse, err error) {
if httpCtx, ok := ctx.(http.Context); ok {
		stdHttp.Redirect(
            httpCtx.Response(),
            httpCtx.Request(),
            targetUrl,
            stdHttp.StatusMovedPermanently,
        )
	}
}
```

> 这种方式并不是官方例子中的实现，使用kratos 2.6.1是正常工作的，新版的有网友反馈不能正常工作，可以看看下面这种方案。

或者使用kratos的http Transport的[Redirector](https://github.com/go-kratos/kratos/blob/e1f5dc42b1e518ecfbc5e167002138736bd0a6db/transport/http/codec.go#L23)，给你的pb生成的结构体（需要指定**跳转地址** 、HTTP status Code可选），在proto输出的路径同目录，新建一个go文件，为response结构体实现这个接口，然后正常返回即可。Redirector允许我们自定义http的返回Code等信息，还是比较方便。

示例proto

```protobuf
message LuckySearchResponse {
  string redirect_to = 1;
  int32 status_code = 2;
}
```

为生成的go结构体实现Redirector接口接口

```go
package v1

import "github.com/go-kratos/kratos/v2/transport/http"

var _ http.Redirector = (*LuckySearchResponse)(nil)

func (s *LuckySearchResponse) Redirect() (string, int) {
	return s.RedirectTo, int(s.StatusCode)
}
```

然后在service层正常返回即可。

如果你自定义过ResponseEncoder，那么你还需要在你的代码中加入下面这两行，这里以我们之前的为例：

```go
if rd, ok := i.(http.Redirector); ok {
	url, code := rd.Redirect()
	stdHttp.Redirect(w, r, url, code)
	return nil
}
```

完整的ResponseEncoder就是下面这个样子

```go
import (
	.......
    stdHttp "net/http"
	.......    
   )
func CustomResponseEncoder() http.ServerOption {
	return http.ResponseEncoder(func(w http.ResponseWriter, r *http.Request, i interface{}) error {
		reply := &v1.BaseResponse{
			Code: 0,
		}
        // 优先处理跳转
        if rd, ok := i.(http.Redirector); ok {
			url, code := rd.Redirect()
			stdHttp.Redirect(w, r, url, code)
			return nil
        }
		if m, ok := i.(proto.Message); ok {
			payload, err := anypb.New(m)
			if err != nil {
				return err
			}
			reply.Data = payload
		}

		//reply := &Response{
		//	Code: 0,
		//	Data: i,
		//}
		codec := encoding.GetCodec("json")
		data, err := codec.Marshal(reply)
		if err != nil {
			return err
		}
		w.Header().Set("Content-Type", "application/json")
		w.Write(data)
		return nil
	})
}
```

>请注意HTTP 301和302重定向的区别:
>
>**HTTP 301**
>
>301是"永久重定向"的状态码。当服务器返回301响应时，它告诉浏览器请求的资源已经被永久地移动到了一个新的URL。这里有几个关键点需要理解：
>
>1. 永久性：301表示这个重定向是永久的，不像302（临时重定向）。
>
>2. 浏览器缓存：由于301的永久性质，大多数现代浏览器会缓存这个响应。这意味着：
>
>3. 首次遇到301重定向时，浏览器会跟随重定向到新的URL。之后再次请求原始URL时，浏览器可能会直接从其缓存中读取新的URL，而不再向服务器发送请求。
>
>4. 缓存持续时间：浏览器可能会无限期地缓存301重定向，除非：用户清除浏览器缓存、强制刷新页面（通常是Ctrl+F5或Cmd+Shift+R）或者浏览器有其他的缓存控制机制（如缓存过期策略）
>
>5. SEO影响：搜索引擎也会更新它们的索引，将旧的URL替换为新的URL。
>
>6. 缓存的优势：
>
>+ 减少服务器负载：不必每次都处理重定向请求
>
>+ 提高用户体验：减少了一次网络往返，加快了页面加载速度
>
>7. 潜在问题：如果你后来想撤销重定向，可能会遇到困难，因为用户的浏览器可能已经缓存了301响应。为了控制301响应的缓存行为，服务器可以使用Cache-Control头：
>
>```tex
>HTTP/1.1 301 Moved Permanently
>
>Location: https://new-url.com
>
>Cache-Control: max-age=86400
>```
>
>在这个例子中，max-age=86400告诉浏览器将这个301响应缓存一天（86400秒）。
>
>**HTTP 302**
>
>302是"临时重定向"的状态码。与301（永久重定向）相比，302有一些重要的区别：
>
>1. 临时性：302表示请求的资源暂时位于不同的URL。这种重定向是临时的，可能会在将来改变。
>
>2. 浏览器缓存行为：
>
>+ 浏览器通常不会像缓存301那样长期缓存302重定向。
>
>+ 每次遇到302重定向时，浏览器通常会再次向原始URL发送请求，以检查重定向是否仍然有效。
>
>3. SEO影响：搜索引擎会继续索引原始URL，而不是像301那样将其替换为新URL。
>
>使用场景：
>
>- 临时维护页面
>
>- A/B测试
>
>- 基于用户状态（如登录状态）的重定向
>
>缓存控制：虽然302本身不鼓励长期缓存，但服务器仍可以通过Cache-Control头来控制缓存行为：
>
>```
>HTTP/1.1 302 Found
>
>Location: https://temp-url.com
>
>Cache-Control: no-store
>```
>
>在这个例子中，no-store指示浏览器不要存储这个响应。
>
>
>
>**变体** 
>
>HTTP 1.1引入了303（See Other）和307（Temporary Redirect）作为302的更精确替代：
>
>303明确指示客户端使用GET方法访问新URL，regardless of原始请求方法。
>
>307保留原始请求的HTTP方法。
>
>浏览器行为：尽管规范建议不要缓存302，但一些浏览器可能会短暂缓存302重定向（通常只有几秒钟），以优化性能。这种行为可能因浏览器而异。
>
>安全考虑：由于302重定向通常不被缓存，它们可以用于动态情况，如基于用户会话的重定向。这提供了更大的灵活性，但也需要注意潜在的安全隐患，如开放重定向漏洞。
>
>**总结**
>
>301是永久重定向，浏览器会长期缓存。
>
>302是临时重定向，浏览器通常不会长期缓存。
>
>302更适合临时或动态的重定向场景。
>
>对于需要频繁改变的重定向，302通常是更好的选择。

## Service和Biz层的区分

Service 层：协议转换，比如grpc转http 和一些简单的validate。

Biz层：具体的Biz业务，跟协议无关。

## 集成实时的metric
### statsviz

[官方网站](https://github.com/arl/statsviz)说明

>Visualise Go program runtime metrics data in real time: heap, objects, goroutines, GC pauses, scheduler, etc. in your browser.
>
>实时可视化Go程序运行时度量数据：在浏览器中的堆、对象、goroutine、GC暂停、调度程序等。

在服务的入口添加下面的代码
```go
imports(
    ....
    "github.com/arl/statsviz"
    ....
)
func newApp(logger log.Logger, gs *grpc.Server, hs *http.Server) *kratos.App {
	statsviz.RegisterDefault()
	....
	}
```
然后在服务监听地址(默认是http://localhost:8000)后面加上`/debug/statsviz/`访问即可。

![image-20220908220623248](https://assets.czyt.tech/img/statsviz-demo-screenshot.png)

类似的还有：

+ https://github.com/felixge/fgtrace 

  >fgtrace is an experimental profiler/tracer that is capturing wallclock timelines for each goroutine. It's very similar to the Chrome profiler.
  >
  >⚠️ fgtrace may cause noticeable stop-the-world pauses in your applications. It is intended for dev and testing environments for now.

其他性能相关库：

+ https://github.com/mosn/holmes

## 服务端跨域配置

参考[官方项目](https://github.com/go-kratos/beer-shop/blob/main/app/shop/interface/internal/server/http.go)

```go
http.Filter(handlers.CORS(
			handlers.AllowedHeaders([]string{"X-Requested-With", "Content-Type", "Authorization"}),// 允许的header
			handlers.AllowedMethods([]string{"GET", "POST", "PUT", "HEAD", "OPTIONS"}),// 允许方法
			handlers.AllowedOrigins([]string{"*"}),//允许的请求源
		)),
```

需要引用包`"github.com/gorilla/handlers"`

或者使用rs的包

```go
import "github.com/rs/cors"

http.Filter(CorsHandler()),
........
func CorsHandler() func(handler http.Handler) http.Handler {
	c := cors.New(cors.Options{
		AllowedOrigins:   []string{"*"},
		AllowCredentials: true,
		AllowedHeaders:   allowedHeaders,
		ExposedHeaders:   exposedHeaders,
		AllowedMethods:   allowedMethods,
		// Enable Debugging for testing, consider disabling in production
		Debug: false,
	})
	return func(handler http.Handler) http.Handler {
		return c.Handler(handler)
	}
}
```

## 服务https监听开关
在conf.proto 上的Http配置添加下面的内容

```protobuf
import "google/protobuf/wrappers.proto";
message HTTP {
    string network = 1;
    string addr = 2;
    .......
    google.protobuf.BoolValue use_tls_bind = 4;
    google.protobuf.StringValue server_cert_file = 5;
    google.protobuf.StringValue server_cert_key = 6;
  }
```

然后在http server的代码中添加配置的解析

```go
if c.Http.UseTlsBind != nil {
		if c.Http.UseTlsBind.Value {
			certFilePath := c.Http.ServerCertFile.Value
			certKeyPath := c.Http.ServerCertKey.Value
			if certFilePath != "" && certKeyPath != "" {
				tlsConfig, err := LoadTLSConfig(certFilePath, certKeyPath)
				if err == nil {
					opts = append(opts, http.TLSConfig(tlsConfig))
				}
			}

		}
}

....
// LoadTLSConfig 从文件加载tlsConfig
func LoadTLSConfig(certFilePath string, certKeyFilePath string) (*tls.Config, error) {
	cer, err := tls.LoadX509KeyPair(certFilePath, certKeyFilePath)
	if err != nil {
		return nil, err
	}
	return &tls.Config{
		Certificates: []tls.Certificate{cer},
	}, nil
}
```
另外可以使用我的[autotls插件](https://github.com/tiny-lib/autotls)

## 自动收集线上问题

Todo

## API鉴权

###  Cerbos
Todo
### Ladon

>引用自极客时间专栏《Go 语言项目开发实战》，参考[ladon的使用示例](https://github.com/marmotedu/geekbang-go/blob/master/LadonCondition%E4%BD%BF%E7%94%A8%E7%A4%BA%E4%BE%8B.md)

Ladon 是用 Go 语言编写的用于实现访问控制策略的库，类似于 RBAC（基于角色的访问控制系统，Role Based Access Control）和 ACL（访问控制列表，Access Control Lists）。但是与 RBAC 和 ACL 相比，Ladon 可以实现更细粒度的访问控制，并且能够在更为复杂的环境中（例如多租户、分布式应用程序和大型组织）工作。Ladon 解决了这个问题：在特定的条件下，谁能够 / 不能够对哪些资源做哪些操作。为了解决这个问题，Ladon 引入了授权策略。授权策略是一个有语法规范的文档，这个文档描述了谁在什么条件下能够对哪些资源做哪些操作。Ladon 可以用请求的上下文，去匹配设置的授权策略，最终判断出当前授权请求是否通过。下面是一个 Ladon 的授权策略样例：

```json
{ "description": "One policy to rule them all.", "subjects": ["users:", "users:maria", "groups:admins"], "actions" : ["delete", ""], "effect": "allow", "resources": [ "resources:articles:<.*>", "resources:printer" ], "conditions": { "remoteIP": { "type": "CIDRCondition", "options": { "cidr": "192.168.0.1/16" } } }}
```

策略（Policy）由若干元素构成，用来描述授权的具体信息，你可以把它们看成一组规则。核心元素包括主题（Subject）、操作（Action）、效力（Effect）、资源（Resource）以及生效条件（Condition）。元素保留字仅支持小写，它们在描述上没有顺序要求。对于没有特定约束条件的策略，Condition 元素是可选项。一条策略包含下面 6 个元素：

+ 主题（Subject），主题名是唯一的，代表一个授权主题。例如，“ken” or “printer-service.mydomain.com”。
+ 操作（Action），描述允许或拒绝的操作。效力（Effect），描述策略产生的结果是“允许”还是“拒绝”，包括 allow（允许）和 deny（拒绝）。
+ 资源（Resource），描述授权的具体数据。
+ 生效条件（Condition），描述策略生效的约束条件。描述（Description），策略的描述。有了授权策略，我们就可以传入请求上下文，由 Ladon 来决定请求是否能通过授权。

参考链接：

+ https://github.com/ory/ladon
+ https://github.com/marmotedu/iam

### OPA（Open Policy Agent）

#### 参考

+ [OPA Guidebook](https://sangkeon.github.io/opaguide/)
+ https://www.topaz.sh
+ https://www.fugue.co/blog/5-tips-for-using-the-rego-language-for-open-policy-agent-opa
+ https://github.com/anderseknert/awesome-opa

### 集成Casbin

Casbin官网 https://casbin.io

参考代码 https://github.com/go-kratos/examples/tree/main/casbin

需要补充的几点：

1. 因为kratos的url生成的是类似于`\api\v1\userInfo\{userid}`样式的，所以在policy中需要使用函数`keyMatch3`来进行policies的匹配，比如我的model.conf文件中就是这样(rbac with domain),如果业务场景中有带pathstring和querystring的情况，就需要讲KeyMatch3 换成[Keymatch5](https://github.com/casbin/casbin/pull/910)来忽略querystring参数。

   ```c
   [request_definition]
   r = sub, dom, obj, act
   
   [policy_definition]
   p = sub, dom, obj, act
   
   [role_definition]
   g = _, _, _
   
   [policy_effect]
   e = some(where (p.eft == allow))
   
   [matchers]
   m = g(r.sub, p.sub, r.dom) && r.dom == p.dom && (regexMatch(r.obj , p.obj) || keyMatch3(r.obj , p.obj)) && r.act == p.act
   ```
   
   官网贴出的casbin支持的[函数](https://casbin.org/docs/zh-CN/function)有下面这些：
   
   > | 函数       | 参数1                                      | 参数2                                                        | 示例                                                         |
   > | ---------- | ------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ |
   > | keyMatch   | 一个URL 路径，例如 `/alice_data/resource1` | 一个URL 路径或 `*` 模式下，例如 `/alice_data/*`              | [keymatch_model.conf](https://github.com/casbin/casbin/blob/master/examples/keymatch_model.conf)/[keymatch_policy.csv](https://github.com/casbin/casbin/blob/master/examples/keymatch_policy.csv) |
   > | keyGet     | 一个URL 路径，例如 `/alice_data/resource1` | 一个URL 路径或 `*` 模式下，例如 `/alice_data/*`              | [keyget_model.conf](https://github.com/casbin/casbin/blob/master/examples/keyget_model.conf)/[keymatch_policy.csv](https://github.com/casbin/casbin/blob/master/examples/keymatch_policy.csv) |
   > | keyMatch2  | 一个URL 路径，例如 `/alice_data/resource1` | 一个URL 路径或 `:` 模式下，例如 `/alice_data/:resource`      | [keymatch2_model.conf](https://github.com/casbin/casbin/blob/master/examples/keymatch2_model.conf)/[keymatch2_policy.csv](https://github.com/casbin/casbin/blob/master/examples/keymatch2_policy.csv) |
   > | keyGet2    | 一个URL 路径，例如 `/alice_data/resource1` | 一个URL 路径或 `:` 模式下，例如 `/alice_data/:resource`      | [keyget_model.conf](https://github.com/casbin/casbin/blob/master/examples/keyget2_model.conf)/[keymatch_policy.csv](https://github.com/casbin/casbin/blob/master/examples/keymatch2_policy.csv) |
   > | keyMatch3  | 一个URL 路径，例如 `/alice_data/resource1` | 一个URL 路径或 `{}` 模式下，例如 `/alice_data/{resource}`    | https://github.com/casbin/casbin/blob/277c1a2b85698272f764d71a94d2595a8d425915/util/builtin_operators_test.go#L171-L196 |
   > | keyMatch4  | 一个URL 路径，例如 `/alice_data/resource1` | 一个URL 路径或 `{}` 模式下，例如 `/alice_data//{id}/book/{id}` | https://github.com/casbin/casbin/blob/277c1a2b85698272f764d71a94d2595a8d425915/util/builtin_operators_test.go#L208-L222 |
   > | keyMatch5  | "" matches "/foo/bar"                      | /foo/bar?status=1&type=2                                     | https://github.com/casbin/casbin/blob/6c771f6f35836bf42fedec7fef1c3c0045031c63/util/builtin_operators.go#L280 |
   > | regexMatch | 任意字符串                                 | 正则表达式模式                                               | [keymatch_model.conf](https://github.com/casbin/casbin/blob/master/examples/keymatch_model.conf)/[keymatch_policy.csv](https://github.com/casbin/casbin/blob/master/examples/keymatch_policy.csv) |
   > | ipMatch    | 一个 IP 地址，例如 `192.168.2.123`         | 一个 IP 地址或一个 CIDR ，例如`192.168.2.0/24`               | [ipmatch_model.conf](https://github.com/casbin/casbin/blob/master/examples/ipmatch_model.conf)/[ipmatch_policy.csv](https://github.com/casbin/casbin/blob/master/examples/ipmatch_policy.csv) |
   > | globMatch  | 类似路径的 `/alice_data/resource1`         | 一个全局模式，例如 `/alice_data/*`                           |                                                              |



2. kratos支持除rbac之外的，还有其他的模型。如rabac with domain等等。参考[官网](https://casbin.org/docs/zh-CN/supported-models)。

3. 中间件中取得当前访问的url

   ```go
   if header, ok := transport.FromServerContext(ctx); ok {
   		// 断言成HTTP的Transport可以拿到特殊信息
   		if hr, ok := header.(*http.Transport); ok {
   			su.Method = hr.Request().Method
   			su.Path = hr.Request().RequestURI
   		}
   }
   ```

   

4. 另外一个就是casbin policy的即时刷新问题，可以通过实现watcher接口来实现，下面是一个基于channel的实现。

   ```go
   /*
    * Copyright (c) 2023.czyt  All rights reserved.
    * Author:czyt
    */
   
   package watcher
   
   import (
   	"github.com/casbin/casbin/v2/persist"
   	"time"
   )
   
   var _ persist.Watcher = (*Watcher)(nil)
   
   type Watcher struct {
   	callback func(string)
   	notify   chan struct{}
   	closed   chan struct{}
   }
   
   func NewWatcher() *Watcher {
   	notify := make(chan struct{}, 1)
   	closed := make(chan struct{})
   	return &Watcher{
   		notify: notify,
   		closed: closed,
   	}
   }
   
   func (w Watcher) SetUpdateCallback(fn func(string)) error {
   	w.callback = fn
   	go processNotify(w.notify, w.closed, fn)
   	return nil
   }
   
   func (w Watcher) Update() error {
   	w.notify <- struct{}{}
   	return nil
   }
   
   func (w Watcher) Close() {
   	w.closed <- struct{}{}
   }
   
   func processNotify(notify, closed chan struct{}, callback func(s string)) {
   	for {
   		select {
   		case _, ok := <-notify:
   			if !ok {
   				break
   			}
   			callback("callback called ")
   			time.Sleep(2 * time.Second)
   
   		case <-closed:
   			close(notify)
   			break
   		}
   	}
   }
   
   ```
   在初始化casbin中间件选项时注入，同时在data层也注入，这样就可以实现更新规则后，中间件规则刷新。
```go
import "github.com/czyt/kasbin"

casbinM.Server(
	casbinM.WithModel(m),
	casbinM.WithPolicy(a),
	casbinM.WithWatcher(watcher),
	casbinM.WithEnforcerContextCreator(authz.NewSecurityUser()),
),
```
用户UseCase
```go
func (i InitializationUseCase) createCasbinPolicies(roles []*Role) error {
		defer func(watcher *watcher.Watcher) {
			err := watcher.Update()
			if err != nil {
				i.log.Error("watcher update casbin policy", err)
			}
		}(i.watcher)
        ......
    }
```

#### 参考

+ https://github.com/Permify/permify
+ https://github.com/open-policy-agent/opa
+ https://github.com/go-cinch/auth
## 复用proto

在业务中可能需要根据职责划分多个服务，这些服务可能部分proto结构是需要复用的。

1. proto单独放在一个repo，使用protoc生成go文件并发布包（业务不敏感情况下，推荐）。

2. proto放在项目api目录内，使用protoc生成go文件并通过go replace做go mod的替换。go mod发布建议发布proto的顶层目录，下面按版本进行管理，这样后面也较为容易维护。

   ```go
   xxxx.tech/api v0.0.0
   replace (
   	xxxx.tech/api v0.0.0 => ./api/xxxx/api
   )
   ```

## 使用buf

下面的buf配置文件使用了tx7do [这个仓库](https://github.com/tx7do/kratos-uba/tree/main/backend)的配置

根目录的`buf.yaml`

```yaml
version: v1
breaking:
  use:
    - FILE
lint:
  use:
    - DEFAULT
```

api目录下的`buf.yaml`

```yaml
version: v1
build:
  excludes: [third_party]
deps:
  - buf.build/googleapis/googleapis
  - buf.build/envoyproxy/protoc-gen-validate
  - buf.build/kratos/apis
  - buf.build/tx7do/gnostic
  - buf.build/gogo/protobuf
breaking:
  use:
    - FILE
lint:
  use:
    - DEFAULT
```

`buf.work.yaml`

```yaml
version: v1
directories:
  - api
```

`buf.gen.yaml`

```yaml
version: v1
managed:
  enabled: false
plugins:
  # generate go struct code
  #- plugin: buf.build/protocolbuffers/go
  - name: go
    out: gen/api/go
    opt: paths=source_relative

  # generate grpc service code
  #- plugin: buf.build/grpc/go
  - name: go-grpc
    out: gen/api/go
    opt:
      - paths=source_relative

  # generate rest service code
  - name: go-http
    out: gen/api/go
    opt:
      - paths=source_relative

  # generate kratos errors code
  - name: go-errors
    out: gen/api/go
    opt:
      - paths=source_relative

  # generate message validator code
  #- plugin: buf.build/bufbuild/validate-go
  - name: validate
    out: gen/api/go
    opt:
      - paths=source_relative
      - lang=go
```

也可以参考[Kratos Example 项目](https://github.com/go-kratos/examples/tree/main/blog)的buf配置,这样生成的go文件和proto定义都在一个目录

`buf.gen.yaml`

```yaml
version: v1
plugins:
  # Use protoc-gen-go at v1.28.1
  - plugin: buf.build/protocolbuffers/go:v1.28.1
    out: api
    opt: paths=source_relative
  # Use the latest version of protoc-gen-go-grpc
  - plugin: buf.build/grpc/go
    out: api
    opt:
      - paths=source_relative
      - require_unimplemented_servers=false
  - plugin: go-http
    out: api
    opt:
      - paths=source_relative
  - plugin: openapi
    out: api
    opt:
      - paths=source_relative
  # Use the latest version of protoc-gen-validate
  - plugin:  buf.build/bufbuild/validate-go
    out: api
    opt:
      - paths=source_relative
  - plugin: go-errors
    out: api
    opt:
      - paths=source_relative
```

## 系统初始化任务

### 逻辑抽象

初始化的逻辑，简单抽象为是否初始化判断和初始化，可以使用下面的流程图来表示

![未命名绘图](https://assets.czyt.tech/img/kratos-initialize-flow.png)

接口简化为下面的代码

```go
type processor interface {
	// IsInit 是否需要初始化
	IsInit() bool
	// Apply 初始化数据
	Apply(seeds []interface{}) error
    // LoadSeeds 获取seeds
    LoadSeeds()(seeds []interface{}, err error)
}
```
### 参数注入

kratos 3.5.3 添加了`BeforeStart`、 `BeforeStop`、 `AfterStart`、 `AfterStop`四个Option，我们可以通过这些来进行参数注入。

```go
hs := http.NewServer()
	gs := grpc.NewServer()
	app := New(
		Name("kratos"),
		Version("v1.0.0"),
		Server(hs, gs),
		BeforeStart(func(_ context.Context) error {
			t.Log("BeforeStart...")
			return nil
		}),
		BeforeStop(func(_ context.Context) error {
			t.Log("BeforeStop...")
			return nil
		}),
		AfterStart(func(_ context.Context) error {
			t.Log("AfterStart...")
			return nil
		}),
		AfterStop(func(_ context.Context) error {
			t.Log("AfterStop...")
			return nil
		}),
		Registrar(&mockRegistry{service: make(map[string]*registry.ServiceInstance)}),
	)
	time.AfterFunc(time.Second, func() {
		_ = app.Stop()
	})
	if err := app.Run(); err != nil {
		t.Fatal(err)
	}
```
### 任务间的依赖处理

如果多个任务之间存在依赖关系，那么能否简单实现任务的自动重排么。答案是肯定的，首先，我们要实现任务的编号，编号必须是可以比较的。然后我们还要显式得提供一个接口，可以获取任务依赖的id列表。我们需要调整我们之前的接口，添加下面两个方法：

```go
type processor interface {
	// IsInit 是否需要初始化
	IsInit() bool
	// Apply 初始化数据
	Apply(seeds []interface{}) error
    // LoadSeeds 获取seeds
    LoadSeeds()(seeds []interface{}, err error)
    // GetJobId 获取任务序号
    GetJobId() int
    // GetDepends 获取依赖的序列号
    GetDepends()[]int
}
```

然后添加了多个`processor`后，就可以通过`slice.sort`进行任务重排。

## Validate配置说明
> 推荐切换到buf的https://github.com/bufbuild/protovalidate 这包括了github.com/envoyproxy/protoc-gen-validate的功能，还引入了cel表达式的支持。
>
> **240925 更新**：因为github.com/envoyproxy/protoc-gen-validate差不多转为维护状态，去掉了原来的validate语法部分，可以去[这里](https://github.com/bufbuild/protoc-gen-validate)查看。

### 工具安装配置

protoc-gen-validate需要安装的包

![image-20221116150025730](https://assets.czyt.tech/img/proto-genvalidate-plugin.png)

```bash
https://github.com/bufbuild/protoc-gen-validate/releases
```
更推荐安装https://github.com/bufbuild/protovalidate
> 字节跳动也开源了一个版本 Github仓库为 https://github.com/cloudwego/protoc-gen-validator

然后修改makefile中的api任务

```bash
.PHONY: api
# generate api proto
api:
	protoc --proto_path=./api \
	       --proto_path=./third_party \
 	       --go_out=paths=source_relative:./api \
 	       --go-http_out=paths=source_relative:./api \
 	       --go-grpc_out=paths=source_relative:./api \
 	       --validate_out=paths=source_relative,lang=go:./api \
	       --openapi_out=fq_schema_naming=true,default_response=false:. \
	       $(API_PROTO_FILES)
```
> 如果使用buf来生成，makefile是不需要的

生成以后，就可以通过调用类型的`ValidateAll`和`Validate`方法进行校验，或者使用kratos的validate中间件,参考[官方文档](https://go-kratos.dev/docs/component/middleware/validate/).


### validate在使用中的问题

#### 在部分更新场景下对全部字段校验的问题

对于常规的场景，validate是没有问题的，但是对于部分更新的场景，validate可能会导致问题，我们在做部分更新的时候，可能配合fieldmask进行部分字段更新，但是validate会校验所有字段，导致更新失败。官方repo有人提了一个[PR](https://github.com/bufbuild/protoc-gen-validate/pull/366)，但尚未合并，在官方未支持这个feature前，只能通过白名单方式来跳过vilidate中间件。

### 使用protobuf来校验配置文件

可以使用protobuf来定义配置文件，然后在配置文件的proto中定义validate规则，在程序加载配置启动之前就validate，这样做有下面几个好处：

+ 配置文件选项和二进制文件之间的绑定（非深度）
+ 在配置文件自身进行选项的值的约束，而不是在程序中来进行。

### 非protoc方式的validate

可以考虑使用非proto方式的validate，这部分代码是摘自项目[kratos-base-project]()

biz/administrator.go

```go
type Administrator struct {
	Id            int64
	Username      string `validate:"required,max=50" label:"用户名"`
	Password      string `validate:"required,max=50" label:"密码"`
	Salt          string
	Mobile        string `validate:"required,max=20" label:"手机号码"`
	Nickname      string `validate:"required,max=50" label:"昵称"`
	Avatar        string `validate:"required,max=150" label:"头像地址"`
	Status        int64  `validate:"required,oneof=1 2" label:"状态"`
	Role          string
	LastLoginTime string
	LastLoginIp   string
	CreatedAt     string
	UpdatedAt     string
	DeletedAt     string
}

func (uc *AdministratorUseCase) Create(ctx context.Context, data *Administrator) (*Administrator, error) {
	err := validate.ValidateStructCN(data)
	if err != nil {
		return &Administrator{}, errors.New(http.StatusBadRequest, errResponse.ReasonParamsError, err.Error())
	}
	return uc.repo.CreateAdministrator(ctx, data)
}
```

对应的helper方法

vilidate.go

```go
package validate

import (
	"errors"
	"github.com/go-playground/validator/v10"
	"reflect"

	"github.com/go-playground/locales/zh"
	ut "github.com/go-playground/universal-translator"
	zh_translations "github.com/go-playground/validator/v10/translations/zh"
)

// ValidateStruct Struct label数据验证器
func ValidateStruct(model interface{}) error {
	//验证
	validate := validator.New()

	//注册一个函数，获取struct tag里自定义的label作为字段名
	validate.RegisterTagNameFunc(func(fld reflect.StructField) string {
		name := fld.Tag.Get("label")
		return name
	})

	err := validate.Struct(model)
	if err != nil {
		for _, err := range err.(validator.ValidationErrors) {
			return errors.New(err.Error())
		}
	}
	return nil
}

// ValidateData 全局model数据验证器
func ValidateStructCN(data interface{}) error {
	//验证
	zh_ch := zh.New()
	validate := validator.New()
	//注册一个函数，获取struct tag里自定义的label作为字段名
	validate.RegisterTagNameFunc(func(fld reflect.StructField) string {
		name := fld.Tag.Get("label")
		return name
	})

	uni := ut.New(zh_ch)
	trans, _ := uni.GetTranslator("zh")
	//验证器注册翻译器
	zh_translations.RegisterDefaultTranslations(validate, trans)
	err := validate.Struct(data)
	if err != nil {
		for _, err := range err.(validator.ValidationErrors) {
			return errors.New(err.Translate(trans))
		}
	}
	return nil
}

```

其他类似的还有

+ https://github.com/ymz-ncnk/musgo
+ https://github.com/cohesivestack/valgo

## 插件化路由和Handler

TODO

## GraphQL

TODO

## pb类型到struct的快速复制

借助[copier](https://github.com/jinzhu/copier)，可以实现pb消息到golang struct的复制。对于一般的pb消息没有问题，但是对于wrapper的pb消息，则需要进行一定的方法扩展。copier提供了用户添加自定义转换规则的选项。我将常见的wrappervalue进行了封装 https://github.com/tiny-lib/copieroptpb 包只有一个方法。简单示例：

```go
import "github.com/tiny-lib/copieroptpb"
....
// biz层结构体
user:=&User{}
// req.User 为protobuf中定义的结构体
if err := copier.CopyWithOption(req.User, user, copieroptpb.Option()); err != nil {
    return nil, err
}
```

## 数据脱敏及安全

### 参考

- https://github.blog/2022-10-26-why-and-how-gith
- https://securecode.wiki/docs/lang/golang/ub-encrypts-sensitive-database-columns-using-activerecordencryption/
- https://github.com/bytedance/godlp
- https://github.com/sachaservan/pir
- https://github.com/ggwhite/go-masker
- https://github.com/anu1097/golang-masking-tool


## 参考


+ [三分钟小课堂 - 如何控制接口返回值](https://mp.weixin.qq.com/s/4ocdoAVXXKTvJ3U65YXltw)
+ [通过 Kratos 高扩展性整合任何框架](https://mp.weixin.qq.com/s/zHHPESkcGG82Zc0U5Meelg)
+ [微服务权鉴 - Zanzibar](https://mp.weixin.qq.com/s/0sjS6NZ1dImJaU-8sTiDRA)
+ [Google API 设计指南](https://cloud.google.com/apis/design?hl=zh-cn)

