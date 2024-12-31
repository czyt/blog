---
title: "Go程序自动升级的方案探究"
date: 2024-12-31
draft: false
tags: ["golang"]
author: "czyt"
---

## 前导

2024年的最后一天看见v站的[这个](https://www.v2ex.com/t/1101408)帖子,故整理下，备忘。

## 常用的库

### cloudflare tableflip

仓库为 https://github.com/cloudflare/tableflip

 官方示例

```go
package tableflip_test

import (
	"context"
	"flag"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/cloudflare/tableflip"
)

// This shows how to use the upgrader
// with the graceful shutdown facilities of net/http.
func Example_httpShutdown() {
	var (
		listenAddr = flag.String("listen", "localhost:8080", "`Address` to listen on")
		pidFile    = flag.String("pid-file", "", "`Path` to pid file")
	)

	flag.Parse()
	log.SetPrefix(fmt.Sprintf("%d ", os.Getpid()))

	upg, err := tableflip.New(tableflip.Options{
		PIDFile: *pidFile,
	})
	if err != nil {
		panic(err)
	}
	defer upg.Stop()

	// Do an upgrade on SIGHUP
	go func() {
		sig := make(chan os.Signal, 1)
		signal.Notify(sig, syscall.SIGHUP)
		for range sig {
			err := upg.Upgrade()
			if err != nil {
				log.Println("Upgrade failed:", err)
			}
		}
	}()

	// Listen must be called before Ready
	ln, err := upg.Listen("tcp", *listenAddr)
	if err != nil {
		log.Fatalln("Can't listen:", err)
	}

	server := http.Server{
		// Set timeouts, etc.
	}

	go func() {
		err := server.Serve(ln)
		if err != http.ErrServerClosed {
			log.Println("HTTP server:", err)
		}
	}()

	log.Printf("ready")
	if err := upg.Ready(); err != nil {
		panic(err)
	}
	<-upg.Exit()

	// Make sure to set a deadline on exiting the process
	// after upg.Exit() is closed. No new upgrades can be
	// performed if the parent doesn't exit.
	time.AfterFunc(30*time.Second, func() {
		log.Println("Graceful shutdown timed out")
		os.Exit(1)
	})

	// Wait for connections to drain.
	server.Shutdown(context.Background())
}
```

这个示例实现了以下功能：

1. 创建一个新的 upgrader 实例

2. 监听 SIGHUP 信号来触发进程升级

3. 设置 HTTP 服务器监听端口

4. 通知父进程新进程已准备就绪

5. 等待退出或升级信号

6. 在退出前给予足够时间完成正在处理的请求

要触发升级，只需向进程发送 SIGHUP 信号：要触发优雅升级，只需要发送

```bash
kill -HUP <pid>
```

即可。如果使用systemd，可以在对应的systemd文件加入

```nginx
[Unit]
Description=My Service

[Service]
ExecStart=/path/to/your/binary
ExecReload=/bin/kill -HUP $MAINPID
```

这样就可以通过 `systemctl reload myservice`来触发优雅升级。

### overseer

仓库为 https://github.com/jpillora/overseer

官方例子

```go
package main

import (
	"fmt"
	"log"
	"net/http"
	"time"

	"github.com/jpillora/overseer"
	"github.com/jpillora/overseer/fetcher"
)

//create another main() to run the overseer process
//and then convert your old main() into a 'prog(state)'
func main() {
	overseer.Run(overseer.Config{
		Program: prog,
		Address: ":3000",
		Fetcher: &fetcher.HTTP{
			URL:      "http://localhost:4000/binaries/myapp",
			Interval: 1 * time.Second,
		},
	})
}

//prog(state) runs in a child process
func prog(state overseer.State) {
	log.Printf("app (%s) listening...", state.ID)
	http.Handle("/", http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, "app (%s) says hello\n", state.ID)
	}))
	http.Serve(state.Listener, nil)
}
```

### selfupdate

> 这个库fork很多版本，我这里使用的是minio的fork版本

仓库地址 https://github.com/minio/selfupdate

官方例子

```go
import (
    "fmt"
    "net/http"

    "github.com/minio/selfupdate"
)

func doUpdate(url string) error {
    resp, err := http.Get(url)
    if err != nil {
        return err
    }
    defer resp.Body.Close()
    err = selfupdate.Apply(resp.Body, selfupdate.Options{})
    if err != nil {
        // error handling
    }
    return err
}
```

## 相关文章

- https://mosn.io/docs/products/structure/smooth-upgrade/
