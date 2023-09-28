---
title: "go泛型备忘录【译】"
date: 2023-09-25
tags: ["golang", "generics"]
draft: false
---

> 原文 https://gosamples.dev/generics-cheatsheet/

## 入门

###  泛型发布

Go 中的泛型自 2022 年 3 月 15 日发布的 1.18 版本起可用。

###  泛型函数

使用泛型，您可以创建以类型作为参数的函数。而不是为每种类型编写单独的函数，例如：

```go
func LastInt(s []int) int {
    return s[len(s)-1]
}

func LastString(s []string) string {
    return s[len(s)-1]
}

// etc.
```

您可以编写带有类型参数的函数：

```go
func Last[T any](s []T) T {
    return s[len(s)-1]
}
```

类型参数在方括号中声明。它们描述了给定函数允许的类型：

![Diagram on how the generic function looks like](https://gosamples.dev/generics-cheatsheet/generic-function.png)

### 泛型函数调用

您可以像调用任何其他函数一样调用通用函数：

```go
func main() {
    data := []int{1, 2, 3}
    fmt.Println(Last(data))

    data2 := []string{"a", "b", "c"}
    fmt.Println(Last(data2))
}
```

您不必像下面的示例那样显式声明类型参数，因为它是根据传递的参数推断的。此功能称为类型推断，仅适用于函数。

```go
func main() {
    data := []int{1, 2, 3}
    fmt.Println(Last[int](data))

    data2 := []string{"a", "b", "c"}
    fmt.Println(Last[string](data2))
}
```

但是，当编译器无法明确检测传递的参数类型时，显式声明具体类型参数是允许的，有时甚至是必要的。

##  约束条件

###  定义

约束是描述类型参数的接口。只有满足指定接口的类型才能用作泛型函数的参数。约束始终出现在类型参数名称后面的方括号中。

在以下示例中：

```go
func Last[T any](s []T) T {
    return s[len(s)-1]
}
```

约束是 `any` 。从 Go 1.18 开始， `any` 是 `interface{}` 的别名：

```go
type any = interface{}
```

`any` 是最广泛的约束，它假设泛型函数的输入变量可以是任何类型。

###  内置约束

Go 中除了 `any` 约束之外，还有一个内置的 `comparable` 约束，它描述任何可以比较其值的类型，即我们可以使用 `==` 运算符。

```go
func contains[T comparable](elems []T, v T) bool {
    for _, s := range elems {
        if v == s {
            return true
        }
    }
    return false
}
```

###  `constraints` 包

`x/exp/constraints` 包中定义了更多约束。它包含允许例如有序类型的约束（支持运算符 `<` 、 `<=` 、 `>=` 、 `>` 的类型），浮点类型、整数类型和其他一些类型：

```go
func Last[T constraints.Complex](s []T) {}
func Last[T constraints.Float](s []T) {}
func Last[T constraints.Integer](s []T) {}
func Last[T constraints.Ordered](s []T) {}
func Last[T constraints.Signed](s []T) {}
func Last[T constraints.Unsigned](s []T) {}
```

查看 `x/exp/constraints` 包的文档以获取更多信息。

###  自定义约束

约束是接口，因此您可以使用自定义的接口作为函数类型参数的约束：

```go
type Doer interface {
    DoSomething()
}

func Last[T Doer](s []T) T {
    return s[len(s)-1]
}
```

然而，使用这样的接口作为约束与直接使用该接口没有什么不同。

从 Go 1.18 开始，接口定义具有新的语法。现在可以定义一个类型的接口：

```go
type Integer interface {
    int
}
```

仅包含一种类型的约束几乎没有实际用途。但是，当与联合运算符 `|` 结合使用时，我们可以定义类型集，没有这些类型集就不可能存在复杂的约束。

###  类型集

使用 union `|` 运算符，我们可以定义具有多种类型的接口：

```go
type Number interface {
    int | float64
}
```

这种类型的接口是一个类型集，可以包含类型或其他类型集：

```go
type Number interface {
    constraints.Integer | constraints.Float
}
```

类型集有助于定义适当的约束。例如， `x/exp/constraints` 包中的所有约束都是使用 union 运算符声明的类型集：

```go
type Integer interface {
    Signed | Unsigned
}
```

###  内联类型集

类型集接口也可以在函数声明中内联定义：

```go
func Last[T interface{ int | int8 | int16 | int32 }](s []T) T {
    return s[len(s)-1]
}
```

使用 Go 允许的简化，我们可以在声明内联类型集时省略 `interface{}` 关键字：

```go
func Last[T int | int8 | int16 | int32](s []T) T {
    return s[len(s)-1]
}
```

###  类型近似

在许多约束定义中，例如在 `x/exp/constraints` 包中，您可以在类型之前找到特殊运算符 `~` 。这意味着约束允许该类型，以及其基础类型与约束中定义的类型相同的类型。看一下例子：

```go
package main

import (
    "fmt"
)

type MyInt int

type Int interface {
    ~int | int8 | int16 | int32
}

func Last[T Int](s []T) T {
    return s[len(s)-1]
}

func main() {
    data := []MyInt{1, 2, 3}
    fmt.Println(Last(data))
}
```

如果 `Int` 约束中的 `int` 类型之前没有 `~` ，则无法在 `Last()` 类型的切片/b4> 函数，因为 `MyInt` 类型不在 `Int` 约束列表中。通过在约束中定义 `~int` ，我们允许基础类型为 `int` 的任何类型的变量。

##  通用类型

###  定义泛型类型

在 Go 中，您还可以创建与泛型函数类似定义的泛型类型：

```go
type KV[K comparable, V any] struct {
    Key   K
    Value V
}

func (v *KV[K, V]) Set(key K, value V) {
    v.Key = key
    v.Value = value
}

func (v *KV[K, V]) Get(key K) *V {
    if v.Key == key {
        return &v.Value
    }
    return nil
}
```

请注意，方法接收者是通用 `KV[K, V]` 类型。

定义泛型类型时，不能在其方法中引入其他类型参数 - 只允许使用结构类型参数。

###  使用示例

初始化新的泛型结构时，必须显式提供具体类型：

```go
func main() {
    var record KV[string, float64]
    record.Set("abc", 54.3)
    v := record.Get("abc")
    if v != nil {
        fmt.Println(*v)
    }
}
```

您可以通过创建构造函数来避免这种情况，因为可以通过类型推断功能来推断函数中的类型：

```go
func NewKV[K comparable, V any](key K, value V) *KV[K, V] {
    return &KV[K, V]{
        Key:   key,
        Value: value,
    }
}

func main() {
    record := NewKV("abc", 54.3)
    v := record.Get("abc")
    if v != nil {
        fmt.Println(*v)
    }
    NewKV("abc", 54.3)
}
```
