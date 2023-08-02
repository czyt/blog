---
title: "golang CGO参考"
date: 2023-02-03
tags: ["golang", "cgo","cpp"]
draft: false
---

## 开源项目

- https://github.com/dolthub/go-library-sample
- https://github.com/draffensperger/go-interlang
- https://github.com/kbehouse/go_call_cxx_so
- https://github.com/tailscale/libtailscale
- https://github.com/iikira/golang-msvc
- https://github.com/vladimirvivien/go-cshared-examples
- https://github.com/tailscale/libtailscale/tree/main

## 文档
- [Embedding Go in C](https://www.dolthub.com/blog/2023-02-01-embedding-go-in-c/)
- [Calling C code from go](https://karthikkaranth.me/blog/calling-c-code-from-go/)
- [C? Go? Cgo!](https://go.dev/blog/cgo)
- [CGO编程（Go语言高级编程）](https://chai2010.cn/advanced-go-programming-book/ch2-cgo/index.html)
- https://stackoverflow.com/questions/14581063/golang-cgo-converting-union-field-to-go-type
- https://sunzenshen.github.io/tutorials/2015/05/09/cgotchas-intro.html
- https://totallygamerjet.hashnode.dev/the-smallest-go-binary-5kb
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