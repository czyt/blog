---
title: "golang CGO参考"
date: 2023-02-03
tags: ["golang", "cgo","cpp"]
draft: false
---

## 开源项目

- https://github.com/dolthub/go-library-sample

## 文档
- [Embedding Go in C](https://www.dolthub.com/blog/2023-02-01-embedding-go-in-c/)
- [C? Go? Cgo!](https://go.dev/blog/cgo)
## 代码片段
[Convert 'C' array to golang slice](https://gist.github.com/nasitra/98bb59421be49a518c4a)
```go
func carray2slice(array *C.int, len int) []C.int {
        var list []C.int
        sliceHeader := (*reflect.SliceHeader)((unsafe.Pointer(&list)))
        sliceHeader.Cap = len
        sliceHeader.Len = len
        sliceHeader.Data = uintptr(unsafe.Pointer(array))
        return list
}
```