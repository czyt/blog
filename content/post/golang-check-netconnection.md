---
title: "golang检测网络连接是否关闭"
date: 2020-06-11
tags: ["golang", "network"]
draft: false
---

```go
 _, err := conn.Read(make([]byte, 0))
if err!=io.EOF{
    // this connection is invalid
    logger.W("conn closed....",err)

}else{
    byt, _:= ioutil.ReadAll(conn);
}
```

注意：net: don't return io.EOF from zero byte reads [issue](https://github.com/golang/go/issues/15735)

参考

https://stackoverflow.com/questions/12741386/how-to-know-tcp-connection-is-closed-in-net-package