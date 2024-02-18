---
title: "go swith的6种用法【译】"
date: 2024-02-17
tags: ["golang"]
draft: false
---

> 文章原文链接为 https://blog.devtrovert.com/p/switch-in-go-6-ways-to-use-it

![img](https://substackcdn.com/image/fetch/w_1456,c_limit,f_auto,q_auto:good,fl_progressive:steep/https%3A%2F%2Fsubstack-post-media.s3.amazonaws.com%2Fpublic%2Fimages%2F1e500d46-8927-4436-bd63-826615a57195_800x533.jpeg)



照片由 Zbyněk Skrčený 在 Unsplash 上拍摄

Go 以其简单而闻名，但我注意到并不是每个人都熟悉 `switch` 语句在这种语言中的多功能性。

首先，如果您不熟悉 Go 的 `switch` 语句，与其他语言相比，它可能看起来有点不同。这是一个简单的例子来展示它的样子：

```go
func main() {
  var i int = 1
  
  switch i {
  case 1:
    fmt.Println("i is 1")
  case 2:
    fmt.Println("i is 2")
  default:
    fmt.Println("i is not 1 or 2")
  }
}
```

Go 的 switch 的一个很酷的事情是，一旦找到匹配项，它就会停止，你不需要在每个 case 的末尾添加一个 break 语句。

但不仅仅如此。

Go 中的 switch 语句有两部分：分号之前的部分是初始化器，分号之后的部分是我们要检查的值。

我们可以选择同时使用、使用其中之一或都不使用：

```go
switch initializer; value {}

switch initializer {}

switch value {}

switch {}
```

 有趣，对吧？

### **1. 布尔值**

有时，您可能会使用带有变量的 `switch` 语句，但这里有一种不同的方法。

考虑使用布尔值的switch。这种方法让我们可以检查多个条件，而不必只依赖于一个变量的值：

```go
func main() {
  var a int = 1
  var b int = 2

  switch true { // <--- use true literal
  case a == 1 && b == 2:
    fmt.Println("a is 1 and b is 2")
  case a == 3:
    fmt.Println("a is 3"):
  default:
    fmt.Println("a is not 1 or 3")
  }
}
```

乍一看， `switch true` 似乎没有必要且毫无意义。

感觉有点像我们在陈述显而易见的事情，但好消息是 Go 有一种更简化的方法来处理这个问题，你实际上可以像这样简化它：

```go
switch { // <--- just remove `true`
case a == 1 && b == 2:
  ...
}
```

这种简化的方法也同样有效。

此外，switch 语句可以与“false”文字一起使用，提供一种确定哪些条件不满足的方法。

### **2. 初始化值**

通常，我们会忽略 switch 语句中的初始化部分。

但它非常有用，并且与 `if` 语句或 `for` 循环中的初始值设定项类似。它允许您声明并分配一个变量，然后立即使用它。

下面是一个例子来说明这一点：

```go
switch a := 1; a {
case 1:
  fmt.Println("a is 1")
}

// similar
if a := 1; a == 1 {
  fmt.Println("a is 1")
}
```

在这些情况下， `a` 的范围仅限于 switch 语句，这意味着您不能在其外部使用。

还记得我们如何忽略开关的两个部分吗？

那么，您也可以选择仅使用初始值设定项部分，当您执行此操作时，值部分被假定为 `true` ：

```go
switch a := 1 {
case a == 1:
  fmt.Println("a is 1")
case a == 2:
  fmt.Println("a is 2")
}
```

到目前为止，我们已经了解了构建 switch 语句的四种方法：仅使用初始值设定项、仅使用值、两者都使用或都不使用。但我们的重点主要集中在switch本身。

接下来，我们将深入探讨 `case` 部分如何发挥作用以及如何在代码中充分利用它。

### **3. 具有多个值的情况**

是的，标题表明了，您可以将多个值分组在一个案例中。

这种方法可以让你的代码更简洁、更容易阅读：

```go
switch a := 1; a {
case 1, 2, 3: // <--
  fmt.Println("a is 1, 2 or 3")
}
```

我注意到许多 Go 新手并不知道这种功能。相反，他们可能会写这样的内容：

```go
switch a := 1; a {
case 1:
case 2:
case 3:
  fmt.Println("a is 1, 2 or 3")
}
```

但由于 `switch` 在 Go 中的工作方式，这种方法不太正确。

在此示例中，打印语句仅与最后一个案例（案例 3）链接。因此，如果 a 是 1 或 2，则不会发生任何情况，因为这些情况后面没有指令，因此程序将跳过它们。

### **4. 带有fallthrough关键字的案例**

该关键字允许继续执行后续情况，而不检查其条件。它与大多数语言处理 switch case 的方式有点不同。

下面的示例展示了 `fallthrough` 的工作原理：

```go
switch a := 1; a {
case 1:
  fmt.Println("a is 1")
  fallthrough
case 2:
  fmt.Println("Now in case 2")
default:
  fmt.Println("Neither 1 nor 2")
}
```

你认为输出会是什么？

在这种情况下，当 a 为 1 时，程序首先打印“a is 1”。然后，由于fallthrough关键字，它立即 `fallthrough` 下一个情况（情况2）而不检查a是否实际上是2。因此，它也会打印“Now in case 2”。

您仍然可以将 `fallthrough` 关键字放在 `case 2` 中，程序将继续下一个案例（默认）并打印“Neither 1 Nor 2”。

```go
switch a := 1; a {
case 1:
  fmt.Println("a is 1")
  fallthrough
case 2:
  fmt.Println("Now in case 2")
  fallthrough
default:
  fmt.Println("Neither 1 nor 2")
}

// Output:
// a is 1
// Now in case 2
// Neither 1 nor 2
```

请记住，Go 中的 `fallthrough` 关键字会绕过以下情况的条件检查。因此，它不用于 switch 语句的最终情况，因为没有后续情况可以转换到。

### **5. 默认情况及其细微差别**

Go 的 switch 语句中的 `default` 情况与 if 语句中的 else 部分类似。

这是当其他情况都不匹配时运行的部分，但 Go 中的默认情况有一些有趣的地方：

尽管在大多数编程语言中 `default` 大小写通常位于末尾，但在 Go 中，它可以放置在 switch 语句中的任何位置。为了清楚起见，我们大多数人都把它放在最后，但让我们看看当我们把它放在开头时会发生什么：

```go
switch a := 1; a {
default:
  fmt.Println("Neither 1 nor 2")
case 1:
  fmt.Println("a is 1")
case 2:
  fmt.Println("Now in case 2")
}
```

在此示例中，即使默认情况最先出现，它仍然被视为最后的手段，仅在没有其他情况匹配时才运行。

但还有另一层需要探索。

如果我们将默认情况与fallthrough关键字混合在一起会怎么样？让我们来看看：

```go
switch a := 3; a {
default:
  fmt.Println("Neither 1 nor 2")
  fallthrough
case 1:
  fmt.Println("a is 1")
case 2:
  fmt.Println("Now in case 2")
}

// Output:
// Neither 1 nor 2
// a is 1
```

在这种情况下，当 a 为 3 时，交换机以默认情况启动，打印“Neither 1 Nor 2”。然后，由于失败，它移动到下一个情况，打印“a is 1”。

### **6. 使用类型断言进行切换**

switch 语句不仅可以处理值，还可以处理类型。这在处理接口时特别有用。

类型断言是使这成为可能的功能，它允许您检查接口值的类型并根据该类型运行不同的代码部分：

```go
func main() {
  var i interface{} = "hello"

  switch v := i.(type) {
  case int:
    fmt.Println("i is an int and its value is", v)
  case string:
    fmt.Println("i is a string and its value is", v)
  default:
    fmt.Println("Unknown type")
  }
}
```

在本例中， `i` 是存储字符串的接口变量。

switch 语句使用 `i.(type)` 来确定 i 的类型，然后根据该类型选择一个案例来执行：

- 它检查每种情况的特定类型（如 int 或 string）。
- 在每种情况下，v 都表示 i 的值作为在该情况下检查的类型，因此您可以像使用该类型的任何变量一样使用 v。

就这样，您现在已经掌握了 Go 中的 switch case :)