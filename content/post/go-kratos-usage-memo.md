---
title: "go-kratos使用备忘"
date: 2022-08-12
tags: ["golang", "kratos"]
draft: false
---
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

## 集成Casbin

Casbin官网 https://casbin.io

参考代码 https://github.com/go-kratos/examples/tree/main/casbin

需要补充的几点：

1. 因为kratos的url生成的是类似于`\api\v1\userInfo\{userid}`样式的，所以在policy中需要使用函数`keyMatch3`来进行policies的匹配，比如我的model.conf文件中就是这样(rbac with domain)

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
### 参考
+ https://github.com/Permify/permify
+ https://github.com/open-policy-agent/opa
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
## Validate配置说明
### 工具安装配置

需要安装的包

![image-20221116150025730](https://assets.czyt.tech/img/proto-genvalidate-plugin.png)

```bash
https://github.com/bufbuild/protoc-gen-validate/releases
```
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
生成以后，就可以通过调用类型的`ValidateAll`和`Validate`方法进行校验，或者使用kratos的validate中间件,参考[官方文档](https://go-kratos.dev/docs/component/middleware/validate/).

### 校验语法

> [The provided constraints](https://github.com/bufbuild/protoc-gen-validate/blob/main/validate/validate.proto) are modeled largerly after those in JSON Schema. PGV rules can be mixed for the same field; the plugin ensures the rules applied to a field cannot contradict before code generation.
>
> Check the [constraint rule comparison matrix](https://github.com/bufbuild/protoc-gen-validate/blob/main/rule_comparison.md) for language-specific constraint capabilities.
>
> #### Numerics
>
> > All numeric types (`float`, `double`, `int32`, `int64`, `uint32`, `uint64` , `sint32`, `sint64`, `fixed32`, `fixed64`, `sfixed32`, `sfixed64`) share the same rules.
>
> - **const**: the field must be *exactly* the specified value.
>
>   ```
>  // x must equal 1.23 exactly
>   float x = 1 [(validate.rules).float.const = 1.23];
>   ```
> 
> - **lt/lte/gt/gte**: these inequalities (`<`, `<=`, `>`, `>=`, respectively) allow for deriving ranges in which the field must reside.
>
>   ```
>  // x must be less than 10
>   int32 x = 1 [(validate.rules).int32.lt = 10];
> 
>   // x must be greater than or equal to 20
>     uint64 x = 1 [(validate.rules).uint64.gte = 20];
> 
>   // x must be in the range [30, 40)
>     fixed32 x = 1 [(validate.rules).fixed32 = {gte:30, lt: 40}];
>   ```
> 
>   Inverting the values of `lt(e)` and `gt(e)` is valid and creates an exclusive range.
>
>   ```
>  // x must be outside the range [30, 40)
>   double x = 1 [(validate.rules).double = {lt:30, gte:40}];
>   ```
> 
> - **in/not_in**: these two rules permit specifying allow/denylists for the values of a field.
>
>   ```
>  // x must be either 1, 2, or 3
>   uint32 x = 1 [(validate.rules).uint32 = {in: [1,2,3]}];
> 
>   // x cannot be 0 nor 0.99
>     float x = 1 [(validate.rules).float = {not_in: [0, 0.99]}];
>   ```
> 
> - **ignore_empty**: this rule specifies that if field is empty or set to the default value, to ignore any validation rules. These are typically useful where being able to unset a field in an update request, or to skip validation for optional fields where switching to WKTs is not feasible.
>
>   ```
>    unint32 x = 1 [(validate.rules).uint32 = {ignore_empty: true, gte: 200}];
>   ```
> 
> #### Bools
>
> - **const**: the field must be *exactly* the specified value.
>
>   ```
>    // x must be set to true
>   bool x = 1 [(validate.rules).bool.const = true];
>     
>   // x cannot be set to true
>     bool x = 1 [(validate.rules).bool.const = false];
>   ```
> 
> #### Strings
>
> - **const**: the field must be *exactly* the specified value.
>
>   ```
>  // x must be set to "foo"
>   string x = 1 [(validate.rules).string.const = "foo"];
>   ```
> 
> - **len/min_len/max_len**: these rules constrain the number of characters ( Unicode code points) in the field. Note that the number of characters may differ from the number of bytes in the string. The string is considered as-is, and does not normalize.
>
>   ```
>  // x must be exactly 5 characters long
>   string x = 1 [(validate.rules).string.len = 5];
> 
>   // x must be at least 3 characters long
>     string x = 1 [(validate.rules).string.min_len = 3];
> 
>   // x must be between 5 and 10 characters, inclusive
>     string x = 1 [(validate.rules).string = {min_len: 5, max_len: 10}];
>   ```
> 
> - **min_bytes/max_bytes**: these rules constrain the number of bytes in the field.
>
>   ```
>  // x must be at most 15 bytes long
>   string x = 1 [(validate.rules).string.max_bytes = 15];
> 
>   // x must be between 128 and 1024 bytes long
>     string x = 1 [(validate.rules).string = {min_bytes: 128, max_bytes: 1024}];
>   ```
> 
> - **pattern**: the field must match the specified [RE2-compliant](https://github.com/google/re2/wiki/Syntax) regular expression. The included expression should elide any delimiters (ie, `/\d+/` should just be `\d+`).
>
>   ```
>  // x must be a non-empty, case-insensitive hexadecimal string
>   string x = 1 [(validate.rules).string.pattern = "(?i)^[0-9a-f]+$"];
>   ```
> 
> - **prefix/suffix/contains/not_contains**: the field must contain the specified substring in an optionally explicit location, or not contain the specified substring.
>
>   ```
>  // x must begin with "foo"
>   string x = 1 [(validate.rules).string.prefix = "foo"];
> 
>   // x must end with "bar"
>     string x = 1 [(validate.rules).string.suffix = "bar"];
> 
>   // x must contain "baz" anywhere inside it
>     string x = 1 [(validate.rules).string.contains = "baz"];
> 
>   // x cannot contain "baz" anywhere inside it
>     string x = 1 [(validate.rules).string.not_contains = "baz"];
> 
>   // x must begin with "fizz" and end with "buzz"
>     string x = 1 [(validate.rules).string = {prefix: "fizz", suffix: "buzz"}];
> 
>   // x must end with ".proto" and be less than 64 characters
>     string x = 1 [(validate.rules).string = {suffix: ".proto", max_len:64}];
>   ```
> 
> - **in/not_in**: these two rules permit specifying allow/denylists for the values of a field.
>
>   ```
>  // x must be either "foo", "bar", or "baz"
>   string x = 1 [(validate.rules).string = {in: ["foo", "bar", "baz"]}];
> 
>   // x cannot be "fizz" nor "buzz"
>     string x = 1 [(validate.rules).string = {not_in: ["fizz", "buzz"]}];
>   ```
> 
> - **ignore_empty**: this rule specifies that if field is empty or set to the default value, to ignore any validation rules. These are typically useful where being able to unset a field in an update request, or to skip validation for optional fields where switching to WKTs is not feasible.
>
>   ```
>  string CountryCode = 1 [(validate.rules).string = {ignore_empty: true, len: 2}];
>   ```
> 
> - **well-known formats**: these rules provide advanced constraints for common string patterns. These constraints will typically be more permissive and performant than equivalent regular expression patterns, while providing more explanatory failure descriptions.
>
>   ```
>    // x must be a valid email address (via RFC 5322)
>   string x = 1 [(validate.rules).string.email = true];
>     
>   // x must be a valid address (IP or Hostname).
>     string x = 1 [(validate.rules).string.address = true];
>     
>   // x must be a valid hostname (via RFC 1034)
>     string x = 1 [(validate.rules).string.hostname = true];
>     
>   // x must be a valid IP address (either v4 or v6)
>     string x = 1 [(validate.rules).string.ip = true];
>     
>   // x must be a valid IPv4 address
>     // eg: "192.168.0.1"
>   string x = 1 [(validate.rules).string.ipv4 = true];
>     
>   // x must be a valid IPv6 address
>     // eg: "fe80::3"
>   string x = 1 [(validate.rules).string.ipv6 = true];
>     
>   // x must be a valid absolute URI (via RFC 3986)
>     string x = 1 [(validate.rules).string.uri = true];
>     
>   // x must be a valid URI reference (either absolute or relative)
>     string x = 1 [(validate.rules).string.uri_ref = true];
>     
>   // x must be a valid UUID (via RFC 4122)
>     string x = 1 [(validate.rules).string.uuid = true];
>     
>   // x must conform to a well known regex for HTTP header names (via RFC 7230)
>     string x = 1 [(validate.rules).string.well_known_regex = HTTP_HEADER_NAME]
>     
>   // x must conform to a well known regex for HTTP header values (via RFC 7230) 
>     string x = 1 [(validate.rules).string.well_known_regex = HTTP_HEADER_VALUE];
>     
>   // x must conform to a well known regex for headers, disallowing \r\n\0 characters.
>     string x = 1 [(validate.rules).string {well_known_regex: HTTP_HEADER_VALUE, strict: false}];
>   ```
> 
> #### Bytes
>
> > Literal values should be expressed with strings, using escaping where necessary.
>
> - **const**: the field must be *exactly* the specified value.
>
>   ```
>  // x must be set to "foo" ("\x66\x6f\x6f")
>   bytes x = 1 [(validate.rules).bytes.const = "foo"];
> 
>   // x must be set to "\xf0\x90\x28\xbc"
>     bytes x = 1 [(validate.rules).bytes.const = "\xf0\x90\x28\xbc"];
>   ```
> 
> - **len/min_len/max_len**: these rules constrain the number of bytes in the field.
>
>   ```
>  // x must be exactly 3 bytes
>   bytes x = 1 [(validate.rules).bytes.len = 3];
> 
>   // x must be at least 3 bytes long
>     bytes x = 1 [(validate.rules).bytes.min_len = 3];
> 
>   // x must be between 5 and 10 bytes, inclusive
>     bytes x = 1 [(validate.rules).bytes = {min_len: 5, max_len: 10}];
>   ```
> 
> - **pattern**: the field must match the specified [RE2-compliant](https://github.com/google/re2/wiki/Syntax) regular expression. The included expression should elide any delimiters (ie, `/\d+/` should just be `\d+`).
>
>   ```
>  // x must be a non-empty, ASCII byte sequence
>   bytes x = 1 [(validate.rules).bytes.pattern = "^[\x00-\x7F]+$"];
>   ```
> 
> - **prefix/suffix/contains**: the field must contain the specified byte sequence in an optionally explicit location.
>
>   ```
>  // x must begin with "\x99"
>   bytes x = 1 [(validate.rules).bytes.prefix = "\x99"];
> 
>   // x must end with "buz\x7a"
>     bytes x = 1 [(validate.rules).bytes.suffix = "buz\x7a"];
> 
>   // x must contain "baz" anywhere inside it
>     bytes x = 1 [(validate.rules).bytes.contains = "baz"];
>   ```
> 
> - **in/not_in**: these two rules permit specifying allow/denylists for the values of a field.
>
>   ```
>  // x must be either "foo", "bar", or "baz"
>   bytes x = 1 [(validate.rules).bytes = {in: ["foo", "bar", "baz"]}];
> 
>   // x cannot be "fizz" nor "buzz"
>     bytes x = 1 [(validate.rules).bytes = {not_in: ["fizz", "buzz"]}];
>   ```
> 
> - **ignore_empty**: this rule specifies that if field is empty or set to the default value, to ignore any validation rules. These are typically useful where being able to unset a field in an update request, or to skip validation for optional fields where switching to WKTs is not feasible.
>
>   ```
>  bytes x = 1 [(validate.rules).bytes = {ignore_empty: true, in: ["foo", "bar", "baz"]}];
>   ```
> 
> - **well-known formats**: these rules provide advanced constraints for common patterns. These constraints will typically be more permissive and performant than equivalent regular expression patterns, while providing more explanatory failure descriptions.
>
>   ```
>    // x must be a valid IP address (either v4 or v6) in byte format
>   bytes x = 1 [(validate.rules).bytes.ip = true];
>     
>   // x must be a valid IPv4 address in byte format
>     // eg: "\xC0\xA8\x00\x01"
>   bytes x = 1 [(validate.rules).bytes.ipv4 = true];
>     
>   // x must be a valid IPv6 address in byte format
>     // eg: "\x20\x01\x0D\xB8\x85\xA3\x00\x00\x00\x00\x8A\x2E\x03\x70\x73\x34"
>   bytes x = 1 [(validate.rules).bytes.ipv6 = true];
>   ```
> 
> #### Enums
>
> > All literal values should use the numeric (int32) value as defined in the enum descriptor.
>
> The following examples use this `State` enum
>
> ```
>enum State {
>   INACTIVE = 0;
>   PENDING = 1;
>   ACTIVE = 2;
> }
> ```
> 
> - **const**: the field must be *exactly* the specified value.
>
>   ```
>  // x must be set to ACTIVE (2)
>   State x = 1 [(validate.rules).enum.const = 2];
>   ```
> 
> - **defined_only**: the field must be one of the specified values in the enum descriptor.
>
>   ```
>  // x can only be INACTIVE, PENDING, or ACTIVE
>   State x = 1 [(validate.rules).enum.defined_only = true];
>   ```
> 
> - **in/not_in**: these two rules permit specifying allow/denylists for the values of a field.
>
>   ```
>    // x must be either INACTIVE (0) or ACTIVE (2)
>   State x = 1 [(validate.rules).enum = {in: [0,2]}];
>     
>   // x cannot be PENDING (1)
>     State x = 1 [(validate.rules).enum = {not_in: [1]}];
>   ```
> 
> #### Messages
>
> > If a field contains a message and the message has been generated with PGV, validation will be performed recursively. Message's not generated with PGV are skipped.
>
> ```
>// if Person was generated with PGV and x is set,
> // x's fields will be validated.
>     Person x = 1;
> ```
> 
> - **skip**: this rule specifies that the validation rules of this field should not be evaluated.
>
>   ```
>  // The fields on Person x will not be validated.
>   Person x = 1 [(validate.rules).message.skip = true];
>   ```
> 
> - **required**: this rule specifies that the field cannot be unset.
>
>   ```
>    // x cannot be unset
>   Person x = 1 [(validate.rules).message.required = true];
>     
>   // x cannot be unset, but the validations on x will not be performed
>     Person x = 1 [(validate.rules).message = {required: true, skip: true}];
>   ```
> 
> #### Repeated
>
> - **min_items/max_items**: these rules control how many elements are contained in the field
>
>   ```
>  // x must contain at least 3 elements
>   repeated int32 x = 1 [(validate.rules).repeated.min_items = 3];
> 
>   // x must contain between 5 and 10 Persons, inclusive
>     repeated Person x = 1 [(validate.rules).repeated = {min_items: 5, max_items: 10}];
> 
>   // x must contain exactly 7 elements
>     repeated double x = 1 [(validate.rules).repeated = {min_items: 7, max_items: 7}];
>   ```
> 
> - **unique**: this rule requires that all elements in the field must be unique. This rule does not support repeated messages.
>
>   ```
>  // x must contain unique int64 values
>   repeated int64 x = 1 [(validate.rules).repeated.unique = true];
>   ```
> 
> - **items**: this rule specifies constraints that should be applied to each element in the field. Repeated message fields also have their validation rules applied unless `skip` is specified on this constraint.
>
>   ```
>  // x must contain positive float values
>   repeated float x = 1 [(validate.rules).repeated.items.float.gt = 0];
> 
>   // x must contain Persons but don't validate them
>     repeated Person x = 1 [(validate.rules).repeated.items.message.skip = true];
>   ```
> 
> - **ignore_empty**: this rule specifies that if field is empty or set to the default value, to ignore any validation rules. These are typically useful where being able to unset a field in an update request, or to skip validation for optional fields where switching to WKTs is not feasible.
>
>   ```
>    repeated int64 x = 1 [(validate.rules).repeated = {ignore_empty: true, items: {int64: {gt: 200}}}];
>   ```
> 
> #### Maps
>
> - **min_pairs/max_pairs**: these rules control how many KV pairs are contained in this field
>
>   ```
>  // x must contain at least 3 KV pairs
>   map<string, uint64> x = 1 [(validate.rules).map.min_pairs = 3];
> 
>   // x must contain between 5 and 10 KV pairs
>     map<string, string> x = 1 [(validate.rules).map = {min_pairs: 5, max_pairs: 10}];
> 
>   // x must contain exactly 7 KV pairs
>     map<string, Person> x = 1 [(validate.rules).map = {min_pairs: 7, max_pairs: 7}];
>   ```
> 
> - **no_sparse**: for map fields with message values, setting this rule to true disallows keys with unset values.
>
>   ```
>  // all values in x must be set
>   map<uint64, Person> x = 1 [(validate.rules).map.no_sparse = true];
>   ```
> 
> - **keys**: this rule specifies constraints that are applied to the keys in the field.
>
>   ```
>  // x's keys must all be negative
>   <sint32, string> x = [(validate.rules).map.keys.sint32.lt = 0];
>   ```
> 
> - **values**: this rule specifies constraints that are be applied to each value in the field. Repeated message fields also have their validation rules applied unless `skip` is specified on this constraint.
>
>   ```
>  // x must contain strings of at least 3 characters
>   map<string, string> x = 1 [(validate.rules).map.values.string.min_len = 3];
> 
>   // x must contain Persons but doesn't validate them
>     map<string, Person> x = 1 [(validate.rules).map.values.message.skip = true];
>   ```
> 
> - **ignore_empty**: this rule specifies that if field is empty or set to the default value, to ignore any validation rules. These are typically useful where being able to unset a field in an update request, or to skip validation for optional fields where switching to WKTs is not feasible.
>
>   ```
>    map<string, string> x = 1 [(validate.rules).map = {ignore_empty: true, values: {string: {min_len: 3}}}];
>   ```
> 
> #### Well-Known Types (WKTs)
>
> A set of [WKTs](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf) are packaged with protoc and common message patterns useful in many domains.
>
> #### Scalar Value Wrappers
>
> In the `proto3` syntax, there is no way of distinguishing between unset and the zero value of a scalar field. The value WKTs permit this differentiation by wrapping them in a message. PGV permits using the same scalar rules that the wrapper encapsulates.
>
> ```
>// if it is set, x must be greater than 3
>     google.protobuf.Int32Value x = 1 [(validate.rules).int32.gt = 3];
> ```
> 
> Message Rules can also be used with scalar Well-Known Types (WKTs):
>
> ```
>// Ensures that if a value is not set for age, it would not pass the validation despite its zero value being 0.
> message X {google.protobuf.Int32Value age = 1 [(validate.rules).int32.gt = -1, (validate.rules).message.required = true];}
> ```
> 
> #### Anys
>
> - **required**: this rule specifies that the field must be set
>
>   ```
>  // x cannot be unset
>   google.protobuf.Any x = 1 [(validate.rules).any.required = true];
>   ```
> 
> - **in/not_in**: these two rules permit specifying allow/denylists for the `type_url` value in this field. Consider using a `oneof` union instead of `in` if possible.
>
>   ```
>    // x must not be the Duration or Timestamp WKT
>   google.protobuf.Any x = 1 [(validate.rules).any = {not_in: [
>       "type.googleapis.com/google.protobuf.Duration",
>       "type.googleapis.com/google.protobuf.Timestamp"
>     ]}];
>   ```
> 
> #### Durations
>
> - **required**: this rule specifies that the field must be set
>
>   ```
>  // x cannot be unset
>   google.protobuf.Duration x = 1 [(validate.rules).duration.required = true];
>   ```
> 
> - **const**: the field must be *exactly* the specified value.
>
>   ```
>  // x must equal 1.5s exactly
>   google.protobuf.Duration x = 1 [(validate.rules).duration.const = {
>       seconds: 1,
>       nanos:   500000000
>     }];
>   ```
> 
> - **lt/lte/gt/gte**: these inequalities (`<`, `<=`, `>`, `>=`, respectively) allow for deriving ranges in which the field must reside.
>
>   ```
>  // x must be less than 10s
>   google.protobuf.Duration x = 1 [(validate.rules).duration.lt.seconds = 10];
> 
>   // x must be greater than or equal to 20ns
>     google.protobuf.Duration x = 1 [(validate.rules).duration.gte.nanos = 20];
> 
>   // x must be in the range [0s, 1s)
>     google.protobuf.Duration x = 1 [(validate.rules).duration = {
>       gte: {},
>       lt:  {seconds: 1}
>     }];
>   ```
> 
>   Inverting the values of `lt(e)` and `gt(e)` is valid and creates an exclusive range.
>
>   ```
>  // x must be outside the range [0s, 1s)
>   google.protobuf.Duration x = 1 [(validate.rules).duration = {
>       lt:  {},
>       gte: {seconds: 1}
>     }];
>   ```
> 
> - **in/not_in**: these two rules permit specifying allow/denylists for the values of a field.
>
>   ```
>    // x must be either 0s or 1s
>   google.protobuf.Duration x = 1 [(validate.rules).duration = {in: [
>       {},
>       {seconds: 1}
>     ]}];
>     
>   // x cannot be 20s nor 500ns
>     google.protobuf.Duration x = 1 [(validate.rules).duration = {not_in: [
>       {seconds: 20},
>       {nanos: 500}
>     ]}];
>   ```
> 
> #### Timestamps
>
> - **required**: this rule specifies that the field must be set
>
>   ```
>  // x cannot be unset
>   google.protobuf.Timestamp x = 1 [(validate.rules).timestamp.required = true];
>   ```
> 
> - **const**: the field must be *exactly* the specified value.
>
>   ```
>  // x must equal 2009/11/10T23:00:00.500Z exactly
>   google.protobuf.Timestamp x = 1 [(validate.rules).timestamp.const = {
>       seconds: 63393490800,
>       nanos:   500000000
>     }];
>   ```
> 
> - **lt/lte/gt/gte**: these inequalities (`<`, `<=`, `>`, `>=`, respectively) allow for deriving ranges in which the field must reside.
>
>   ```
>  // x must be less than the Unix Epoch
>   google.protobuf.Timestamp x = 1 [(validate.rules).timestamp.lt.seconds = 0];
> 
>   // x must be greater than or equal to 2009/11/10T23:00:00Z
>     google.protobuf.Timestamp x = 1 [(validate.rules).timestamp.gte.seconds = 63393490800];
> 
>   // x must be in the range [epoch, 2009/11/10T23:00:00Z)
>     google.protobuf.Timestamp x = 1 [(validate.rules).timestamp = {
>       gte: {},
>       lt:  {seconds: 63393490800}
>     }];
>   ```
> 
>   Inverting the values of `lt(e)` and `gt(e)` is valid and creates an exclusive range.
>
>   ```
>  // x must be outside the range [epoch, 2009/11/10T23:00:00Z)
>   google.protobuf.Timestamp x = 1 [(validate.rules).timestamp = {
>       lt:  {},
>       gte: {seconds: 63393490800}
>     }];
>   ```
> 
> - **lt_now/gt_now**: these inequalities allow for ranges relative to the current time. These rules cannot be used with the absolute rules above.
>
>   ```
>  // x must be less than the current timestamp
>   google.protobuf.Timestamp x = 1 [(validate.rules).timestamp.lt_now = true];
>   ```
> 
> - **within**: this rule specifies that the field's value should be within a duration of the current time. This rule can be used in conjunction with `lt_now` and `gt_now` to control those ranges.
>
>   ```
>    // x must be within ±1s of the current time
>   google.protobuf.Timestamp x = 1 [(validate.rules).timestamp.within.seconds = 1];
>     
>   // x must be within the range (now, now+1h)
>     google.protobuf.Timestamp x = 1 [(validate.rules).timestamp = {
>       gt_now: true,
>       within: {seconds: 3600}
>     }];
>   ```
> 
> #### Message-Global
>
> - **disabled**: All validation rules for the fields on a message can be nullified, including any message fields that support validation themselves.
>
>   ```
>  message Person {
>     option (validate.disabled) = true;
> 
>     // x will not be required to be greater than 123
>       uint64 x = 1 [(validate.rules).uint64.gt = 123];
> 
>     // y's fields will not be validated
>       Person y = 2;
>   }
>   ```
> 
> - **ignored**: Don't generate a validate method or any related validation code for this message.
>
>   ```
>    message Person {
>     option (validate.ignored) = true;
>     
>     // x will not be required to be greater than 123
>       uint64 x = 1 [(validate.rules).uint64.gt = 123];
>     
>     // y's fields will not be validated
>       Person y = 2;
>   }
>   ```
> 
> #### OneOfs
>
> - **required**: require that one of the fields in a `oneof` must be set. By default, none or one of the unioned fields can be set. Enabling this rules disallows having all of them unset.
>
>   ```markdown
>    oneof id {
>     // either x, y, or z must be set.
>     option (validate.required) = true;
>     
>     string x = 1;
>       int32  y = 2;
>     Person z = 3;
>   }
>   ```

## 插件化路由和Handler

Todo


## 参考


+ [三分钟小课堂 - 如何控制接口返回值](https://mp.weixin.qq.com/s/4ocdoAVXXKTvJ3U65YXltw)

