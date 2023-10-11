---
title: "Golang命令行库bubbletea使用备忘"
date: 2023-10-11
tags: ["golang", "TUI"]
draft: true
---

## 核心概念
### Model

model是bubbletea的核心接口,定义如下：

```go
type Model interface {
    Init() Cmd
    Update(msg Msg) (Model, Cmd)
    View() string
}
```



### Command

## 参考资料

+ [Rapidly building interactive CLIs in Go with Bubbletea](https://www.inngest.com/blog/interactive-clis-with-bubbletea)
+ [Intro to Bubble Tea in Go](https://dev.to/andyhaskell/intro-to-bubble-tea-in-go-21lg)
+ [Processing user input in Bubble Tea with a menu component](https://dev.to/andyhaskell/processing-user-input-in-bubble-tea-with-a-menu-component-222i)