---
title: "12 个改变我生产力的个人go技巧【译】"
date: 2023-10-05
tags: ["golang", "trick"]
draft: false
---

> 原文链接https://dev.to/func25/12-personal-go-tricks-that-transformed-my-productivity-mne

#### 作者

我通常在 Devtrovert 分享有关系统设计和 Go 的见解。请随时查看我的 LinkedIn Phuong Le 以获取最新帖子。

------

在从事生产项目时，我注意到我经常重复代码并利用某些技术，直到后来回顾我的工作时才意识到这一点。

为了解决这个问题，我开发了一个解决方案，事实证明它对我很有帮助，而且我认为它对其他人也可能有用。

下面是从我的实用程序库中随机挑选的一些有用且通用的代码片段，没有任何特定的分类或特定于系统的技巧。

## 1.跟踪使用时间的技巧

如果您有兴趣跟踪 Go 中函数的执行时间，您可以使用一个简单而有效的技巧，只需使用“defer”关键字的一行代码即可。您所需要的只是一个 TrackTime 函数：

```
// Utility
func TrackTime(pre time.Time) time.Duration {
  elapsed := time.Since(pre)
  fmt.Println("elapsed:", elapsed)

  return elapsed
}

func TestTrackTime(t *testing.T) {
  defer TrackTime(time.Now()) // <--- THIS

  time.Sleep(500 * time.Millisecond)
}

// elapsed: 501.11125ms
```



## 1.5.两阶段延迟

Go 延迟的强大之处不仅在于任务完成后的清理工作，还在于任务完成后的清理工作。这也是为了做好准备，请考虑以下事项：

```
func setupTeardown() func() {
    fmt.Println("Run initialization")
    return func() {
        fmt.Println("Run cleanup")
    }
}

func main() {
    defer setupTeardown()() // <--------
    fmt.Println("Main function called")
}

// Output:
// Run initialization
// Main function called
// Run cleanup
```



感谢 Teiva Harsanyi 介绍了这种优雅的方法。

这个图案的美丽之处？只需一行，您就可以完成以下任务：

- 打开数据库连接，然后关闭它。
- 设置模拟环境并将其拆除。
- 获取并随后释放分布式锁。
- ...

> “好吧，这看起来很聪明，但是现实世界的实用性在哪里呢？”

还记得时间流逝的技巧吗？我们也可以这样做：

```
func TrackTime() func() {
  pre := time.Now()
  return func() {
    elapsed := time.Since(pre)
    fmt.Println("elapsed:", elapsed)
  }
}

func main() {
  defer TrackTime()()

  time.Sleep(500 * time.Millisecond)
}
```



> “可是等等！如果我连接到数据库并抛出错误怎么办？”

确实，像 `defer TrackTime()()` 或 `defer ConnectDB()()` 这样的模式不会优雅地处理错误。这个技巧最适合测试，或者当你有足够的胆量冒致命错误的风险时，请检查这个以测试为中心的方法：

```
func TestSomething(t *testing.T) {
  defer handleDBConnection(t)()
  // ...
}

func handleDBConnection(t *testing.T) func() {
  conn, err := connectDB()
  if err != nil {
    t.Fatal(err)
  }

  return func() {
    fmt.Println("Closing connection", conn)
  }
}
```



在那里，将在测试期间处理来自数据库连接的错误。

## 2. 切片预分配

根据“Go Performance Boosters”一文中分享的见解，预先分配切片或映射可以显着提高 Go 程序的性能。

然而，值得注意的是，如果我们无意中使用“append”而不是索引（如 a[i]），这种方法有时会导致错误。

您是否知道可以使用预分配的切片而不指定数组的长度（零），如上述文章中所述？这允许我们像我们一样使用追加：

```
// instead of
a := make([]int, 10)
a[0] = 1

// use this
b := make([]int, 0, 10)
b = append(b, 1)
```



##  3. 链式调用

链式调用可以应用于函数（指针）接收器。为了说明这一点，让我们考虑一个具有两个函数 `AddAge` 和 `Rename` 的 `Person` 结构，可用于修改它。

```
type Person struct {
  Name string
  Age  int
}

func (p *Person) AddAge() {
  p.Age++
}

func (p *Person) Rename(name string) {
  p.Name = name
}
```



如果您想为某人添加年龄然后重新命名，典型的方法如下：

```
func main() {
  p := Person{Name: "Aiden", Age: 30}

  p.AddAge()
  p.Rename("Aiden 2")
}
```



或者，我们可以修改 `AddAge` 和 `Rename` 函数接收器以返回修改后的对象本身，即使它们通常不返回任何内容。

```
func (p *Person) AddAge() *Person {
  p.Age++
  return p
}

func (p *Person) Rename(name string) *Person {
  p.Name = name
  return p
}
```



通过返回修改后的对象本身，我们可以轻松地将多个函数接收器链接在一起，而无需添加不必要的代码行：

```
p = p.AddAge().Rename("Aiden 2")
```



## 4. Go 1.20 允许将切片解析为数组或数组指针

当我们需要将切片转换为固定大小的数组时，我们不能像这样直接赋值：

```
a := []int{0, 1, 2, 3, 4, 5}
var b[3]int = a[0:3]

// cannot use a[0:3] (value of type []int) as [3]int value in variable 
// declaration compiler(IncompatibleAssign)
```



为了将切片转换为数组，Go 团队在 Go 1.17 中更新了此功能。随着 Go 1.20 的发布，转换过程变得更加容易，具有更方便的文字：

```
// go 1.20
func Test(t *testing.T) {
    a := []int{0, 1, 2, 3, 4, 5}
    b := [3]int(a[0:3])

  fmt.Println(b) // [0 1 2]
}

// go 1.17
func TestM2e(t *testing.T) {
  a := []int{0, 1, 2, 3, 4, 5}
  b := *(*[3]int)(a[0:3])

  fmt.Println(b) // [0 1 2]
}
```



简单说明一下：您可以使用 [:3] 而不是 [0:3]。我提到这一点是为了清楚起见。

## 5. 使用带‘_’的导入进行包初始化

有时，在库中，您可能会遇到组合下划线 ( `_` ) 的 import 语句，如下所示：

```
import (
  _ "google.golang.org/genproto/googleapis/api/annotations" 
)
```



这将执行包的初始化代码（init 函数），而不为其创建名称引用。这允许您在运行代码之前初始化包、注册连接并执行其他任务。

让我们考虑一个例子来更好地理解它是如何工作的：

```
// underscore
package underscore

func init() {
  fmt.Println("init called from underscore package")
}
// mainpackage main 
import (
  _ "lab/underscore"
)
func main() {}
// log: init called from underscore package
```



## 6. 使用带点 `.` 的导入

探索了如何使用带下划线的导入后，现在让我们看看点 `.` 运算符如何更常用。

作为开发人员，点 `.` 运算符可用于使导入包的导出标识符可用，而无需指定包名称，这对于懒惰的开发人员来说是一个有用的快捷方式。

很酷，对吧？这在处理项目中的长包名称时特别有用，例如“ `externalmodel` ”或“ `doingsomethinglonglib` ”

为了进行演示，这里有一个简短的例子：

```
package main

import (
  "fmt"
  . "math"
)

func main() {
  fmt.Println(Pi) // 3.141592653589793
  fmt.Println(Sin(Pi / 2)) // 1
}
```



## 7. Go 1.20 现在可以将多个错误包装成一个错误

Go 1.20 为错误包引入了新功能，包括对多个错误的支持以及对 `errors.Is` 和 `errors.As` 的更改。

添加到错误中的一个新函数是 Join，我们将在下面仔细研究它：

```
var (
  err1 = errors.New("Error 1st")
  err2 = errors.New("Error 2nd")
)

func main() {
  err := err1
  err = errors.Join(err, err2)

  fmt.Println(errors.Is(err, err1)) // true
  fmt.Println(errors.Is(err, err2)) // true
}
```



如果您有多个任务会导致容器出现错误，则可以使用 `Join` 函数，而不必自己手动管理数组。这简化了错误处理过程。

## 8. 编译时检查接口的技巧

假设您有一个名为 `Buffer` 的接口，其中包含一个 `Write()` 函数。此外，您还有一个名为 `StringBuffer` 的结构，它实现了此接口。

但是，如果您犯了拼写错误，写成了 `Writeee()` 而不是 `Write()` ，该怎么办？

```
type Buffer interface {
  Write(p []byte) (n int, err error)
}

type StringBuffer struct{}

func (s *StringBuffer) Writeee(p []byte) (n int, err error) {
  return 0, nil
}
```



在运行时之前，您无法检查 StringBuffer 是否已正确实现 Buffer 接口。但是，通过使用此技巧，编译器将通过 IDE 错误消息提醒您：

```
var _ Buffer = (*StringBuffer)(nil)

// cannot use (*StringBuffer)(nil) (value of type *StringBuffer) 
// as Buffer value in variable declaration: *StringBuffer 
// does not implement Buffer (missing method Write)
```



## 9.三元与泛型

Go 不像许多其他编程语言那样内置对三元运算符的支持：

```
# python 
min = a if a < b else b
```



```
// c#
min = x < y ? x : y
```



借助 Go 版本 1.18 中的泛型，我们现在能够创建一个实用程序，只需一行代码即可实现类似三元的功能：

```
// our utility
func Ter[T any](cond bool, a, b T) T {
  if cond {
    return a
  }

  return b
}

func main() {
  fmt.Println(Ter(true, 1, 2)) // 1 
  fmt.Println(Ter(false, 1, 2)) // 2
}
```



## 10.避免裸参数

当处理具有多个参数的函数时，仅通过阅读其用法来理解每个参数的含义可能会令人困惑。考虑以下示例：

```
printInfo("foo", true, true)
```



如果不检查 printInfo，第一个“true”和第二个“true”是什么意思？当您的函数具有多个参数时，理解参数的含义可能会令人困惑。

但是，我们可以使用注释来使代码更具可读性。例如：

```
// func printInfo(name string, isLocal, done bool)

printInfo("foo", true /* isLocal */, true /* done */)
```



某些 IDE 还通过在函数调用建议中显示注释来支持此功能，但可能需要在设置中启用。

## 11. 验证接口是否真的为 nil 的方法

即使一个接口的值为 nil，也并不一定意味着该接口本身就是 nil。这可能会导致 Go 程序出现意外错误。因此，了解如何检查接口是否实际上为 nil 非常重要。

```
func main() {
  var x interface{}
  var y *int = nil
  x = y

  if x != nil {
    fmt.Println("x != nil") // <-- actual
  } else {
    fmt.Println("x == nil")
  }

  fmt.Println(x)
}

// x != nil
// <nil>
```



如果你不熟悉这个概念，我建议你参考我的文章《Go 的 Interface{} 秘密：Nil 不是 Nil》。

我们如何判断一个interface{}值是否为nil？幸运的是，有一个简单的实用程序可以帮助我们实现这一目标：

```
func IsNil(x interface{}) bool {
  if x == nil {
    return true
  }

  return reflect.ValueOf(x).IsNil()
}
```



## 12. 解组 JSON 中的 time.Duration

解析 JSON 时，使用 `time.Duration` 可能是一个麻烦的过程，因为它需要在 1 秒后添加 9 个零（即 1000000000）。为了简化这个过程，我创建了一个名为 `Duration` 的新类型：

```
type Duration time.Duration
```



为了能够将 `1s` 或 `20h5m` 等字符串解析为 `int64` 持续时间，我还为这种新类型实现了自定义解组逻辑：

```
func (d *Duration) UnmarshalJSON(b []byte) error {
  var s string
  if err := json.Unmarshal(b, &s); err != nil {
    return err
  }
  dur, err := time.ParseDuration(s)
  if err != nil {
    return err
  }
  *d = Duration(dur)
  return nil
}
```



然而，重要的是要注意变量“ `d` ”不应该为零，因为它可能会导致编组错误。或者，您还可以在函数的开头包含对“d”的检查。”

------

我不想让帖子太长并且难以理解，因为这些技巧不依赖于任何特定主题并且涵盖各种类别。

如果您发现这些技巧有用或者有任何自己的见解可以分享，请随时发表评论。我重视您的反馈，并很乐意在这篇文章中点赞或推荐您的想法。

 **祝你使用这些技巧愉快！**