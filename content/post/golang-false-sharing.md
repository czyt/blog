---
title: "Golang False sharing"
date: 2022-05-12
tags: ["golang"]
draft: false
---

## 缘起

来自于一段[prometheus](https://github.com/prometheus/prometheus/blob/main/tsdb/head.go#L1341)代码

```go
type stripeLock struct {Fabian Reinartz, 5 years ago: • Replace single head lock with granular locks
	sync.RWMutex
	// Padding to avoid multiple locks being on the same cache line.
	_ [40]byte
}
```

简单地讲就是因为CPU读取数据的缓存机制问题，可能导致性能上的不同差异。参考资料见后文。

## 参考

+ https://medium.com/@genchilu/whats-false-sharing-and-how-to-solve-it-using-golang-as-example-ef978a305e10
+ https://dariodip.medium.com/false-sharing-an-example-with-go-bc7e90594f3f
+ https://github.com/glebarez/false-sharing-demo
+ https://betterprogramming.pub/when-io-bound-hides-inside-cpu-e6e7f9df3187