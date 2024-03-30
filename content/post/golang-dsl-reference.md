---
title: "Golang DSL参考"
date: 2022-07-11
tags: ["dsl", "golang"]
draft: false
---
#  ANTLR 4
## 图书

+ The definitive ANTLR 4 reference (2014) [英文版下载](https://libgen.czyt.tech/book/index.php?md5=6C0EB707351F336CA286F2F7E39274AC) [中文版下载](https://kodbox.xiaozao520.cn:81/?sitemap/file/7XVzZXAQ&view=ANTLR%204%E6%9D%83%E5%A8%81%E6%8C%87%E5%8D%97/ANTLR%204%E6%9D%83%E5%A8%81%E6%8C%87%E5%8D%97.pdf)

## 文章
+ [使用ANTLR和Go实现DSL入门](https://tonybai.com/2022/05/10/introduction-of-implement-dsl-using-antlr-and-go/)
+ 手把手教你使用ANTLR和Go实现一门DSL语言[part1](https://tonybai.com/2022/05/24/an-example-of-implement-dsl-using-antlr-and-go-part1/) [part2](https://tonybai.com/2022/05/25/an-example-of-implement-dsl-using-antlr-and-go-part2/)[part3](https://tonybai.com/2022/05/27/an-example-of-implement-dsl-using-antlr-and-go-part3/)[part4](https://tonybai.com/2022/05/28/an-example-of-implement-dsl-using-antlr-and-go-part4/)[part5](https://tonybai.com/2022/05/30/an-example-of-implement-dsl-using-antlr-and-go-part5/)
+ [Parsing with ANTLR 4 and Go](https://blog.gopheracademy.com/advent-2017/parsing-with-antlr4-and-go/)

## 实例代码
+ bilibili gengine [link](https://github.com/bilibili/gengine/blob/main/internal/iantlr)
+ go-zero [link](https://github.com/zeromicro/go-zero/tree/master/tools/goctl/api/parser)
+ [grule-rule-engine](https://github.com/hyperjumptech/grule-rule-engine)
+ https://github.com/kulics-works/feel-go
+ [monkey.go](https://github.com/andydude/monkey.go)
## windows 环境配置

配置好Java环境，然后将下面的批处理加入系统环境变量：

antlr.cmd

```bash
@echo off
java -classpath %~dp0antlr-4.12.0-complete.jar org.antlr.v4.Tool %*
```

grun.cmd

```bash
@echo off
java -classpath %~dp0antlr-4.12.0-complete.jar org.antlr.v4.gui.TestRig %*
```




# Others

## 图书

+ Writing A Compiler In Go
+ Writing an Interpreter in Go
+ [µGo语言实现——从头开发一个迷你Go语言编译器](https://github.com/wa-lang/ugo-compiler-book)



## 文章
+ [Build your own DSL with Go & HCL](https://blog.devgenius.io/build-your-own-dsl-with-go-hcl-602c92ce24c0)

+ [How to Write Syntax Tree-Based Domain-Specific Languages in Go](https://betterprogramming.pub/how-to-write-syntax-tree-based-domain-specific-languages-in-go-b15537f0d2f3)

+ [Handwritten Parsers & Lexers in Go](https://blog.gopheracademy.com/advent-2014/parsers-lexers/)

+ [goyacc实战](https://zhuanlan.zhihu.com/p/264367718)

+ [TiDB SQL Parser 的实现](https://pingcap.com/zh/blog/tidb-source-code-reading-5)

+ [GopherCon 2018 - How to Write a Parser in Go](https://about.sourcegraph.com/blog/go/gophercon-2018-how-to-write-a-parser-in-go)

## 实例代码
+ [expr](https://github.com/antonmedv/expr)
+ [hof](https://github.com/hofstadter-io)
+ [Go Parser Tutorial](https://github.com/sougou/parser_tutorial)
