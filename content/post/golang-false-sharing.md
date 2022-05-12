---
title: "Golang False sharing"
date: 2022-05-12
tags: ["golang"]
draft: false
---

![image-20220512210618415](https://assets.czyt.tech/img/image-20220512210618415.png)

## 缘起

来自于一段[prometheus](https://github.com/prometheus/prometheus/blob/main/tsdb/head.go#L1341)代码

```go
type stripeLock struct { 
	sync.RWMutex
	// Padding to avoid multiple locks being on the same cache line.
	_ [40]byte
}
```

简单地讲就是因为CPU读取数据的缓存机制问题，可能导致性能上的不同差异。参考资料见后文。

常见类型的内存占用大小（[Go101](https://go101.org/article/value-copy-cost.html)）：

|          Kinds of Types           |                          Value Size                          | [Required](https://golang.org/ref/spec#Size_and_alignment_guarantees) by [Go Specification](https://golang.org/ref/spec#Numeric_types) |
| :-------------------------------: | :----------------------------------------------------------: | :----------------------------------------------------------: |
|               bool                |                            1 byte                            |                        not specified                         |
|        int8, uint8 (byte)         |                            1 byte                            |                            1 byte                            |
|           int16, uint16           |                           2 bytes                            |                           2 bytes                            |
|   int32 (rune), uint32, float32   |                           4 bytes                            |                           4 bytes                            |
| int64, uint64, float64, complex64 |                           8 bytes                            |                           8 bytes                            |
|            complex128             |                           16 bytes                           |                           16 bytes                           |
|             int, uint             |                            1 word                            | architecture dependent, 4 bytes on 32-bit architectures and 8 bytes on 64-bit architectures |
|              uintptr              |                            1 word                            | large enough to store the uninterpreted bits of a pointer value |
|              string               |                           2 words                            |                        not specified                         |
|     pointer (safe or unsafe)      |                            1 word                            |                        not specified                         |
|               slice               |                           3 words                            |                        not specified                         |
|                map                |                            1 word                            |                        not specified                         |
|              channel              |                            1 word                            |                        not specified                         |
|             function              |                            1 word                            |                        not specified                         |
|             interface             |                           2 words                            |                        not specified                         |
|              struct               | (the sum of sizes of all fields) + (the number of [padding](https://go101.org/article/memory-layout.html#size-and-padding) bytes) | the size of a **struct** type is zero if it contains no fields that have a size greater than zero |
|               array               |            (element value size) * (array length)             | the size of an **array** type is zero if its element type has zero size |

## 参考

+ https://medium.com/@genchilu/whats-false-sharing-and-how-to-solve-it-using-golang-as-example-ef978a305e10
+ https://dariodip.medium.com/false-sharing-an-example-with-go-bc7e90594f3f
+ https://github.com/glebarez/false-sharing-demo
+ https://betterprogramming.pub/when-io-bound-hides-inside-cpu-e6e7f9df3187
+ https://colobu.com/2019/01/24/cacheline-affects-performance-in-go/
+ https://www.shouxicto.com/article/3984.html