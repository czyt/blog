---
title: "go embed 使用小记"
date: 2020-06-23
tags: ["golang", "embed"]
draft: false
---

​      go embed 是go 1.16 开始添加的特性，允许嵌入文件及文件夹，在Go程序中进行使用。官方还为此添加了`embed.FS`的对象。下面将常用的使用场景进行简单列举：

## 嵌入单个文件

官方的例子

### 嵌入文件并绑定到字符串变量

```go
import _ "embed"

//go:embed hello.txt
var s string
print(s)
```
### 嵌入文件并绑定到字节变量
```go
import _ "embed"

//go:embed hello.txt
var b []byte
print(string(b))
```
### 嵌入文件并绑定到文件对象
```go
import "embed"

//go:embed hello.txt
var f embed.FS
data, _ := f.ReadFile("hello.txt")
print(string(data))
```



## 嵌入目录

嵌入时，可以在多行或者一行输入要嵌入的文件和文件夹。

```go
package server

import "embed"

// content holds our static web server content.
//go:embed image/* template/*
//go:embed html/index.html
var content embed.FS
```
在匹配文件夹时，embed会嵌入包括子目录下的所有除`.`和`_`开头的文件（递归），所以上面的代码大致等价于下面的代码：
```go
// content is our static web server content.
//go:embed image template html/index.html
var content embed.FS
```

区别在于  `image/*` 会嵌入`image/.tempfile` 而`image` 则不会嵌入. 也不会嵌入`image/dir/.tempfile`.如果要实现跟上面代码一样的效果，即也嵌入`image/.tempfile`和`image/dir/.tempfile`这样的文件，那么应该使用下面的这段代码:

```go
// content is our static web server content.
//go:embed all:image all:template html/index.html
var content embed.FS
```

下面是一个在网络服务器中使用Embed来嵌入静态页面的例子：

```go
http.Handle("/static/", http.StripPrefix("/static/", http.FileServer(http.FS(content))))

template.ParseFS(content, "*.tmpl")
```
## 参考

+ 官方文档:https://pkg.go.dev/embed
+ [鸟窝Go embed简明教程](https://colobu.com/2021/01/17/go-embed-tutorial/)

