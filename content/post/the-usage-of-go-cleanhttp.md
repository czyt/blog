---
title: "使用Hashcorp的cleanhttp"
date: 2023-08-23
tags: ["golang", "http"]
draft: false
---

## 缘起

早上在某地方看到这样一张图

![image-20230823065753035](https://assets.czyt.tech/img/go-http-round-trip.png)

大意是说任何第三方库都可以拦截您的所有 HTTP 调用，然后推荐了一个库 [cleanhttp](https://github.com/hashicorp/go-cleanhttp)

官网的介绍：

>Functions for accessing "clean" Go http.Client values
>用于访问“干净”Go http.Client 值的函数
>
>------
>
>The Go standard library contains a default `http.Client` called `http.DefaultClient`. It is a common idiom in Go code to start with `http.DefaultClient` and tweak it as necessary, and in fact, this is encouraged; from the `http` package documentation:
>Go 标准库包含一个名为 `http.DefaultClient` 的默认 `http.Client` 。在 Go 代码中，以 `http.DefaultClient` 开头并根据需要进行调整是一种常见的习惯用法，事实上，这是值得鼓励的；来自 `http` 包文档：
>
>> The Client's Transport typically has internal state (cached TCP connections), so Clients should be reused instead of created as needed. Clients are safe for concurrent use by multiple goroutines.
>> 客户端的传输通常具有内部状态（缓存的 TCP 连接），因此客户端应该被重用，而不是根据需要创建。多个 goroutine 并发使用客户端是安全的。
>
>Unfortunately, this is a shared value, and it is not uncommon for libraries to assume that they are free to modify it at will. With enough dependencies, it can be very easy to encounter strange problems and race conditions due to manipulation of this shared value across libraries and goroutines (clients are safe for concurrent use, but writing values to the client struct itself is not protected).
>不幸的是，这是一个共享值，类库认为可以随意修改它的情况并不少见。有了足够的依赖项，由于跨库和 goroutine 操作此共享值，很容易遇到奇怪的问题和竞争条件（客户端可以安全地并发使用，但将值写入客户端结构本身不受保护）。
>
>Making things worse is the fact that a bare `http.Client` will use a default `http.Transport` called `http.DefaultTransport`, which is another global value that behaves the same way. So it is not simply enough to replace `http.DefaultClient` with `&http.Client{}`.
>更糟糕的是，裸露的 `http.Client` 将使用名为 `http.DefaultTransport` 的默认 `http.Transport` ，这是另一个行为方式相同的全局值。因此，仅仅用 `&http.Client{}` 替换 `http.DefaultClient` 是不够的。
>
>This repository provides some simple functions to get a "clean" `http.Client` -- one that uses the same default values as the Go standard library, but returns a client that does not share any state with other clients.
>这个存储库提供了一些简单的函数来获得“干净的” `http.Client` ——它使用与Go标准库相同的默认值，但返回一个不与其他客户端共享任何状态的客户端。

## 源代码分析

这个库的代码很简单，它封装了自己的`http.Transport`构造方法和`http.Client`构造方法（使用了它它生成的`http.Transport`）并且是每次都创建新的`http.Transport`实例，这个它介绍中提到的
> 返回一个不与其他客户端共享任何状态的客户端

功能上是保持一致的。
```go
// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MPL-2.0

package cleanhttp

import (
	"net"
	"net/http"
	"runtime"
	"time"
)

// DefaultTransport returns a new http.Transport with similar default values to
// http.DefaultTransport, but with idle connections and keepalives disabled.
func DefaultTransport() *http.Transport {
	transport := DefaultPooledTransport()
	transport.DisableKeepAlives = true
	transport.MaxIdleConnsPerHost = -1
	return transport
}

// DefaultPooledTransport returns a new http.Transport with similar default
// values to http.DefaultTransport. Do not use this for transient transports as
// it can leak file descriptors over time. Only use this for transports that
// will be re-used for the same host(s).
func DefaultPooledTransport() *http.Transport {
	transport := &http.Transport{
		Proxy: http.ProxyFromEnvironment,
		DialContext: (&net.Dialer{
			Timeout:   30 * time.Second,
			KeepAlive: 30 * time.Second,
			DualStack: true,
		}).DialContext,
		MaxIdleConns:          100,
		IdleConnTimeout:       90 * time.Second,
		TLSHandshakeTimeout:   10 * time.Second,
		ExpectContinueTimeout: 1 * time.Second,
		ForceAttemptHTTP2:     true,
		MaxIdleConnsPerHost:   runtime.GOMAXPROCS(0) + 1,
	}
	return transport
}

// DefaultClient returns a new http.Client with similar default values to
// http.Client, but with a non-shared Transport, idle connections disabled, and
// keepalives disabled.
func DefaultClient() *http.Client {
	return &http.Client{
		Transport: DefaultTransport(),
	}
}

// DefaultPooledClient returns a new http.Client with similar default values to
// http.Client, but with a shared Transport. Do not use this function for
// transient clients as it can leak file descriptors over time. Only use this
// for clients that will be re-used for the same host(s).
func DefaultPooledClient() *http.Client {
	return &http.Client{
		Transport: DefaultPooledTransport(),
	}
}
```

然后在Handler中则又主要是对url中的不安全（不可打印）的参数进行清除。

```go
// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MPL-2.0

package cleanhttp

import (
	"net/http"
	"strings"
	"unicode"
)

// HandlerInput provides input options to cleanhttp's handlers
type HandlerInput struct {
	ErrStatus int
}

// PrintablePathCheckHandler is a middleware that ensures the request path
// contains only printable runes.
func PrintablePathCheckHandler(next http.Handler, input *HandlerInput) http.Handler {
	// Nil-check on input to make it optional
	if input == nil {
		input = &HandlerInput{
			ErrStatus: http.StatusBadRequest,
		}
	}

	// Default to http.StatusBadRequest on error
	if input.ErrStatus == 0 {
		input.ErrStatus = http.StatusBadRequest
	}

	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r != nil {
			// Check URL path for non-printable characters
			idx := strings.IndexFunc(r.URL.Path, func(c rune) bool {
				return !unicode.IsPrint(c)
			})

			if idx != -1 {
				w.WriteHeader(input.ErrStatus)
				return
			}

			if next != nil {
				next.ServeHTTP(w, r)
			}
		}

		return
	})
}
```

代码源仓库 [地址](https://github.com/hashicorp/go-cleanhttp)
