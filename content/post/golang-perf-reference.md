---
title: "Go性能优化参考"
date: 2022-06-11
tags: ["golang", "perf"]
draft: false
---


## 电子书

+ [编写和优化Go代码](https://github.com/dgryski/go-perfbook)
+ [Go Optimizations 101](https://go101.org/optimizations/101.html)
+ https://github.com/dgryski/go-perfbook
+ https://github.com/DataDog/go-profiler-notes
+ https://github.com/bobstrecansky/HighPerformanceWithGo/

## Go package

+ https://github.com/aclements/go-perf
+ https://github.com/256dpi/god

## 文章

+ [官方博客 Profiling Go Programs](https://go.dev/blog/pprof)

+ https://sumercip.com/posts/inside-the-go-cpu-profiler/

+ How to Write Benchmarks in Go : https://dave.cheney.net/2013/06/30/how-to-write-benchmarks-in-go
+ [Improving Observability of GoLang Services](https://flow.com/engineering-blogs/golang-services-improving-observability)
+ Debugging performance issues in Go programs : https://github.com/golang/go/wiki/Performance
+ Go execution tracer : https://blog.gopheracademy.com/advent-2017/go-execution-tracer/ (see also the The tracer design doc link)
+ A whirlwind tour of Go’s runtime environment variables (see godebug) : https://dave.cheney.net/2015/11/29/a-whirlwind-tour-of-gos-runtime-environment-variables
+ benchstat : https://godoc.org/golang.org/x/perf/cmd/benchstat
+ [pyroscope: 一个简单易用的持续剖析平台](https://colobu.com/2022/01/27/pyroscope-a-continuous-profiling-platform/)
+ [VSCODE可视化调试Go程序](https://mp.weixin.qq.com/s/pmNCkj55UeCx2LosjF9mjA)
+ [Jetbrains官方Goland代码调试文档](https://www.jetbrains.com/help/go/debugging-code.html)
+ https://github.com/cch123/perf_workshop_2021
+ [GO高性能编程精华](https://zhuanlan.zhihu.com/p/482107438)
+ [Go 语言中各式各样的优化手段](https://zhuanlan.zhihu.com/p/403417640)
+ [Go 中简单的内存节省技巧](https://mp.weixin.qq.com/s/iaYpz51xe45RJfNWPyIqHw)
+ [Five Steps to Make Your Go Code Faster & More Efficient](https://docs.google.com/presentation/d/1MD_Vlb9d32aMDPu9MOlyVO796mK1Y6GrRcXOl63C7g4/edit?usp=sharing)
+ [Making a Go program run 1.7x faster with a one character change](https://hmarr.com/blog/go-allocation-hunting/)
+ [Simple Byte Hacking](https://eblog.fly.dev/bytehacking.html)
+ [a tale of two stacks: optimizing gin’s panic recovery handler](https://eblog.fly.dev/faststack.html)
+ [Golang Quirks & Intermediate Tricks, Pt 1: Declarations, Control Flow, & Typesystem](https://eblog.fly.dev/quirks.html)

## 性能监控系统

+ [pyroscope](https://pyroscope.io)
+ [gov](https://github.com/256dpi/gov)