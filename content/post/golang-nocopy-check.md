---
title: "Golang nocopy check"
date: 2022-06-17
tags: ["golang", "nocopy"]
draft: false
---
## 目的

 实现nocopy的目的在于，golang在进行参数传递时，都是传递副本的方式。但是某些情况，我们是需要进行传递对象的引用的（特别是一些指针对象，可能会导致多个指针的副本的操作造成程序陷入恐慌），为了杜绝调用者的复制，只能指针传递全局唯一对象。那么就可以通过添加nocopy来实现对go vet参数支持的no copy 检查。

## 实现
golang里面最常用的sync.WaitGroup就是通过nocopy实现的。参考定义
```go
// A WaitGroup must not be copied after first use.
type WaitGroup struct {
	noCopy noCopy

	// 64-bit value: high 32 bits are counter, low 32 bits are waiter count.
	// 64-bit atomic operations require 64-bit alignment, but 32-bit
	// compilers do not ensure it. So we allocate 12 bytes and then use
	// the aligned 8 bytes in them as state, and the other 4 as storage
	// for the sema.
	state1 [3]uint32
}
```
再看下nocopy的定义,必须实现 sync.Locker 接口
```go
// noCopy may be embedded into structs which must not be copied
// after the first use.
//
// See https://golang.org/issues/8005#issuecomment-190753527
// for details.
type noCopy struct{}

// Lock is a no-op used by -copylocks checker from `go vet`.
func (*noCopy) Lock()   {}
func (*noCopy) Unlock() {}
```
