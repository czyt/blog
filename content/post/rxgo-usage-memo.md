---
title: "Rxgo使用备忘录"
date: 2023-08-20
tags: ["rx", "go"]
draft: false
---
# 官网文档

--机器翻译内容--

## 介绍
> ReactiveX，简称 Rx，是一个用于使用 Observable 流进行编程的 API。

RxGo 实现基于管道的概念。管道是由通道连接的一系列阶段，其中每个阶段是一组运行相同功能的 goroutine。

[![img](https://github.com/ReactiveX/RxGo/raw/master/doc/rx.png)](https://github.com/ReactiveX/RxGo/blob/master/doc/rx.png)

让我们看一个具体的例子，每个框都是一个运算符：

- 我们使用 `Just` 运算符基于固定的项目列表创建一个静态 Observable。
- 我们使用 `Map` 运算符定义一个转换函数（将圆形转换为方形）。
- 我们使用 `Filter` 运算符过滤每个黄色方块。

在此示例中，最终物品在通道中发送，可供消费者使用。使用 RxGo 消费或生成数据的方法有很多种。在频道中发布结果只是其中之一。

每个算子都是一个转换阶段。默认情况下，一切都是顺序的。然而，我们可以通过定义同一运算符的多个实例来利用现代 CPU 架构。每个运算符实例都是连接到公共通道的 goroutine。

RxGo 的理念是实现 ReactiveX 概念并利用主要的 Go 原语（通道、goroutines 等），以便两个世界之间的集成尽可能顺利。

## 安装 RxGo v2

```
go get -u github.com/reactivex/rxgo/v2
```

##  入门

###  你好世界

让我们创建第一个 Observable 并使用一个项目：

```go
observable := rxgo.Just("Hello, World!")()
ch := observable.Observe()
item := <-ch
fmt.Println(item.V)
```

`Just` 运算符从静态项目列表创建一个 Observable。 `Of(value)` 根据给定值创建一个项目。如果我们想从错误中创建一个项目，我们必须使用 `Error(err)` 。这与 v1 不同，v1 直接接受值或错误而无需包装它。这一改变的理由是什么？它是为了（希望）Go 2 中的泛型功能为 RxGo 做好准备。

顺便说一下， `Just` 运算符使用柯里化作为语法糖。这样，它接受第一个参数列表中的多个项目和第二个参数列表中的多个选项。我们将在下面看到如何指定选项。

一旦创建了 Observable，我们就可以使用 `Observe()` 来观察它。默认情况下，Observable 是惰性的，因为它仅在订阅后才发出项目。 `Observe()` 返回 `<-chan rxgo.Item` 。

我们从该通道消耗了一个项目，并使用 `item.V` 打印了该项目的值。

项目是值或错误之上的包装。我们可能想首先检查类型，如下所示：

```go
item := <-ch
if item.Error() {
    return item.E
}
fmt.Println(item.V)
```

`item.Error()` 返回一个布尔值，指示项目是否包含错误。然后，我们使用 `item.E` 获取错误或 `item.V` 获取值。

默认情况下，一旦产生错误，Observable 就会停止。但是，有一些特殊的运算符可以处理错误（例如 `OnError` 、 `Retry` 等）

还可以使用回调来消费项目：

```go
observable.ForEach(func(v interface{}) {
    fmt.Printf("received: %v\n", v)
}, func(err error) {
    fmt.Printf("error: %e\n", err)
}, func() {
    fmt.Println("observable is closed")
})
```

在这个例子中，我们传递了三个函数：

- 当发出值项时触发 `NextFunc` 。
- 当发出错误项时触发 `ErrFunc` 。
- 一旦 Observable 完成，就会触发 `CompletedFunc` 。

`ForEach` 是非阻塞的。然而，它返回一个通知通道，一旦 Observable 完成，该通道将关闭。因此，要使前面的代码阻塞，我们只需使用 `<-` ：

```go
<-observable.ForEach(...)
```

###  现实世界的例子

假设我们要实现一个使用以下 `Customer` 结构的流：

```go
type Customer struct {
	ID             int
	Name, LastName string
	Age            int
	TaxNumber      string
}
```

我们创建一个生产者，它将向给定的 `chan rxgo.Item` 发出 `Customer` 并从中创建一个 Observable：

```go
// Create the input channel
ch := make(chan rxgo.Item)
// Data producer
go producer(ch)

// Create an Observable
observable := rxgo.FromChannel(ch)
```
然后，我们需要执行以下两个操作：
- 筛选18岁以下的客户。
- 用税号丰富每个客户。例如，通过执行外部 REST 调用的 IO 绑定函数来检索税号。
由于丰富步骤是 IO 绑定的，因此在给定的 goroutine 池中并行化它可能会很有趣。然而，让我们想象一下，所有 `Customer` 项都需要根据其 `ID` 顺序生成。

```go
observable.
	Filter(func(item interface{}) bool {
		// Filter operation
		customer := item.(Customer)
		return customer.Age > 18
	}).
	Map(func(_ context.Context, item interface{}) (interface{}, error) {
		// Enrich operation
		customer := item.(Customer)
		taxNumber, err := getTaxNumber(customer)
		if err != nil {
			return nil, err
		}
		customer.TaxNumber = taxNumber
		return customer, nil
	},
		// Create multiple instances of the map operator
		rxgo.WithPool(pool),
		// Serialize the items emitted by their Customer.ID
		rxgo.Serialize(func(item interface{}) int {
			customer := item.(Customer)
			return customer.ID
		}), rxgo.WithBufferedChannel(1))
```

最后，我们使用 `ForEach()` 或 `Observe()` 来消费这些项目。 `Observe()` 返回 `<-chan Item` ：

```go
for customer := range observable.Observe() {
	if customer.Error() {
		return err
	}
	fmt.Println(customer)
}
```
##  可观察类型

### 热观测值与冷观测值

在 Rx 世界中，冷 Observable 和热 Observable 是有区别的。当数据是由 Observable 本身产生时，它是一个冷 Observable。当数据在 Observable 外部产生时，它就是热 Observable。通常，当我们不想一遍又一遍地创建生产者时，我们更喜欢热 Observable。
在RxGo中，也有类似的概念。
首先，让我们使用 `FromChannel` 运算符创建一个热 Observable 并查看其含义：

```go
ch := make(chan rxgo.Item)
go func() {
    for i := 0; i < 3; i++ {
        ch <- rxgo.Of(i)
    }
    close(ch)
}()
observable := rxgo.FromChannel(ch)

// First Observer
for item := range observable.Observe() {
    fmt.Println(item.V)
}

// Second Observer
for item := range observable.Observe() {
    fmt.Println(item.V)
}
```

这次执行的结果是：

```
0
1
2
```

这意味着第一个观察者已经消耗了所有物品。也没有给别人留下什么。

尽管可以使用 Connectable Observables 来改变这种行为。

这里的要点是 goroutine 生成了这些项目。

另一方面，让我们使用 `Defer` 运算符创建一个冷 Observable：

```go
observable := rxgo.Defer([]rxgo.Producer{func(_ context.Context, ch chan<- rxgo.Item) {
    for i := 0; i < 3; i++ {
        ch <- rxgo.Of(i)
    }
}})

// First Observer
for item := range observable.Observe() {
    fmt.Println(item.V)
}

// Second Observer
for item := range observable.Observe() {
    fmt.Println(item.V)
}
```

现在，结果是：

```
0
1
2
0
1
2
```

在冷可观察的情况下，流是为每个观察者独立创建的。

再说一遍，热 Observable 与冷 Observable 与您如何消费项目无关，而是与数据的生成位置有关。

热门 Observable 的一个很好的例子是来自交易所的价格变动。

如果你教一个 Observable 从数据库中获取产品，然后一一生成它们，你将创建冷 Observable。

### Backpressure 

还有另一个名为 `FromEventSource` 的运算符，它从通道创建 Observable。 `FromChannel` 运算符的区别在于，一旦创建了 Observable，无论是否有 Observer，它都会开始发出数据。因此，没有观察者的 Observable 发出的项目会丢失（虽然它们是用 `FromChannel` 运算符缓冲的）。

例如，使用 `FromEventSource` 运算符的用例是遥测。我们可能对流一开始产生的所有数据不感兴趣，只对我们开始观察它以来的数据感兴趣。

一旦我们开始观察使用 `FromEventSource` 创建的 Observable，我们就可以配置反压策略。默认情况下，它是阻塞的（在我们观察到它之后发出的项目有保证交付）。我们可以这样重写这个策略：

```go
observable := rxgo.FromEventSource(input, rxgo.WithBackPressureStrategy(rxgo.Drop))
```

`Drop` 策略意味着如果 `FromEventSource` 之后的管道尚未准备好使用某个项目，则该项目将被丢弃。

默认情况下，连接算子的通道是非缓冲的。我们可以像这样重写这个行为：

```go
observable.Map(transform, rxgo.WithBufferedChannel(42))
```

每个运算符都有一个 `opts ...Option` 参数，允许传递此类选项。

### Lazy vs. Eager Observation

默认的观察策略是惰性的。这意味着一旦我们开始观察可观察对象，操作员就会处理它发出的项目。我们可以这样改变这种行为：

```go
observable := rxgo.FromChannel(ch).Map(transform, rxgo.WithObservationStrategy(rxgo.Eager))
```

在这种情况下，只要生成一个项目，就会触发 `Map` 运算符，即使没有任何观察者也是如此。

### Sequential vs. Parallel Operators

默认情况下，每个运算符都是顺序的。一个运算符就是一个 goroutine 实例。我们可以使用以下选项覆盖它：

```go
observable.Map(transform, rxgo.WithPool(32))
```

在此示例中，我们创建了一个由 32 个 goroutine 组成的池，它们同时消耗来自同一通道的项目。如果操作受 CPU 限制，我们可以使用 `WithCPUPool()` 选项根据逻辑 CPU 的数量创建池。

### Connectable Observable

Connectable Observable 类似于普通的 Observable，不同之处在于它不会在订阅时开始发出项目，而是仅在调用其 connect() 方法时才开始发出。通过这种方式，您可以在 Observable 开始发出项目之前等待所有预期订阅者订阅 Observable。

让我们使用 `rxgo.WithPublishStrategy` 创建一个 Connectable Observable：

```go
ch := make(chan rxgo.Item)
go func() {
	ch <- rxgo.Of(1)
	ch <- rxgo.Of(2)
	ch <- rxgo.Of(3)
	close(ch)
}()
observable := rxgo.FromChannel(ch, rxgo.WithPublishStrategy())
```

然后，我们创建两个观察者：

```go
observable.Map(func(_ context.Context, i interface{}) (interface{}, error) {
	return i.(int) + 1, nil
}).DoOnNext(func(i interface{}) {
	fmt.Printf("First observer: %d\n", i)
})

observable.Map(func(_ context.Context, i interface{}) (interface{}, error) {
	return i.(int) * 2, nil
}).DoOnNext(func(i interface{}) {
	fmt.Printf("Second observer: %d\n", i)
})
```

如果 `observable` 不是一个 Connectable Observable，当 `DoOnNext` 创建一个观察者时，源 Observable 将开始发出项目。然而，对于 Connectable Observable 来说，我们必须调用 `Connect()` ：

```go
observable.Connect()
```

一旦 `Connect()` 被调用，Connectable Observable 就开始发出项目。

常规 Observable 还有另一个重要的变化。 Connectable Observable 发布其项目。这意味着所有观察者都会收到物品的副本。

这是一个常规 Observable 的示例：

```go
ch := make(chan rxgo.Item)
go func() {
	ch <- rxgo.Of(1)
	ch <- rxgo.Of(2)
	ch <- rxgo.Of(3)
	close(ch)
}()
// Create a regular Observable
observable := rxgo.FromChannel(ch)

// Create the first Observer
observable.DoOnNext(func(i interface{}) {
	fmt.Printf("First observer: %d\n", i)
})

// Create the second Observer
observable.DoOnNext(func(i interface{}) {
	fmt.Printf("Second observer: %d\n", i)
})
```

```
First observer: 1
First observer: 2
First observer: 3
```

现在，使用可连接的 Observable：

```go
ch := make(chan rxgo.Item)
go func() {
	ch <- rxgo.Of(1)
	ch <- rxgo.Of(2)
	ch <- rxgo.Of(3)
	close(ch)
}()
// Create a Connectable Observable
observable := rxgo.FromChannel(ch, rxgo.WithPublishStrategy())

// Create the first Observer
observable.DoOnNext(func(i interface{}) {
	fmt.Printf("First observer: %d\n", i)
})

// Create the second Observer
observable.DoOnNext(func(i interface{}) {
	fmt.Printf("Second observer: %d\n", i)
})

disposed, cancel := observable.Connect()
go func() {
	// Do something
	time.Sleep(time.Second)
	// Then cancel the subscription
	cancel()
}()
// Wait for the subscription to be disposed
<-disposed
```

```
Second observer: 1
First observer: 1
First observer: 2
First observer: 3
Second observer: 2
Second observer: 3
```

### Observable, Single, and Optional Single

Iterable 是一个可以使用 `Observe(opts ...Option) <-chan Item` 观察的对象。

Iterable 可以是：

- Observable：发出 0 个或多个项目
- A Single：发出 1 项
- 可选单项：发出 0 或 1 项

##  文档

包文档：https://pkg.go.dev/github.com/reactivex/rxgo/v2

###  断言API

如何在使用 RxGo 时使用断言 API 编写单元测试。

###  操作员选项

[ 操作员选项](https://github.com/ReactiveX/RxGo/blob/master/doc/options.md)

###  创建可观察对象

- Create — 通过以编程方式调用 Observer 方法从头开始创建 Observable
- Defer — 在观察者订阅之前不要创建 Observable，并为每个观察者创建一个新的 Observable
- Empty/Never/Thrown——创建具有非常精确和有限行为的 Observables
- FromChannel — 基于惰性通道创建一个 Observable
- FromEventSource — 基于渴望通道创建一个 Observable
- Interval — 创建一个 Observable，它发出由特定时间间隔间隔的整数序列
- 只是 — 将一组对象转换为发出该或那些对象的 Observable
- JustItem — 将一个对象转换为发出该对象的 Single
- Range — 创建一个发出一系列连续整数的 Observable
- Repeat — 创建一个可重复发出特定项目或项目序列的 Observable
- Start — 创建一个发出函数返回值的 Observable
- Timer — 创建一个在指定延迟后完成的 Observable

### 转变可观测值

- Buffer——定期将 Observable 中的项目收集到包中并发出这些包，而不是一次发出一个项目
- FlatMap — 将 Observable 发出的项转换为 Observables，然后将这些项的排放扁平化为单个 Observable
- GroupBy — 将一个 Observable 划分为一组 Observable，每个 Observable 发出与原始 Observable 不同的一组项目，按键组织
- GroupByDynamic — 将一个 Observable 划分为一组动态 Observable，每个 Observable 都从原始 Observable 发出 GroupedObservable，按键组织
- Map — 通过对每个项目应用函数来转换 Observable 发出的项目
- Marshal — 通过对每个项目应用编组函数来转换 Observable 发出的项目
- Scan — 按顺序将函数应用于 Observable 发出的每个项目，并发出每个连续值
- Unmarshal — 通过对每个项目应用解组函数来转换 Observable 发出的项目
- Window — 按顺序将函数应用于 Observable 发出的每个项目，并发出每个连续值

###  过滤可观察值

- Debounce — 仅当特定时间跨度过去且未发射另一个项目时，才从 Observable 发射一个项目
- Distinct/ DistinctUntilChanged — 抑制 Observable 发出的重复项
- ElementAt — 只发出 Observable 发出的第 n 项
- Filter——仅从 Observable 中发出那些通过谓词测试的项目
- Find — 发出传递谓词的第一个项目，然后完成
- First/ FirstOrDefault — 仅发出 Observable 中的第一项或满足条件的第一项
- IgnoreElements — 不从 Observable 发出任何项目，但镜像其终止通知
- Last/ LastOrDefault — 只发出 Observable 发出的最后一个项目
- Sample — 发出 Observable 在周期性时间间隔内发出的最新项目
- Skip — 抑制 Observable 发出的前 n 个项目
- SkipLast — 抑制 Observable 发出的最后 n 个项目
- Take — 只发出 Observable 发出的前 n 个项目
- TakeLast — 只发出 Observable 发出的最后 n 个项目

###  结合观测值

- CombineLatest — 当两个 Observable 中的任何一个发出一个项目时，通过指定的函数组合每个 Observable 发出的最新项目，并根据该函数的结果发出项目
- Join — 在根据另一个 Observable 发出的项目定义的时间窗口内发出来自一个 Observable 的项目时，组合两个 Observable 发出的项目
- 合并 — 通过合并多个 Observables 的排放将其合并为一个
- StartWithIterable — 在开始从源 Iterable 发出项目之前发出指定的项目序列
- ZipFromIterable — 通过指定的函数将多个 Observable 的发射组合在一起，并根据该函数的结果为每个组合发射单个项目

### 错误处理运算符

- Catch — 通过继续无错误的序列来从 onError 通知中恢复
- Retry/ BackOffRetry — 如果源 Observable 发送 onError 通知，请重新订阅它，希望它能顺利完成

### 可观察的效用运算符

- Do - 注册一个动作来处理各种 Observable 生命周期事件
- Run — 创建一个观察者而不消耗发出的项目
- Send — 在特定通道中发送 Observable 项目
- Serialize — 强制 Observable 进行序列化调用并表现良好
- TimeInterval — 将发出项目的 Observable 转换为发出这些发射之间经过的时间量指示的 Observable
- Timestamp — 为 Observable 发出的每个项目附加一个时间戳

### 条件和布尔运算符

- All — 确定 Observable 发出的所有项目是否满足某些条件
- Amb — 给定两个或多个源 Observables，仅从这些 Observables 中的第一个发出所有项目来发出项目
- Contains — 确定 Observable 是否发出特定项
- DefaultIfEmpty — 从源 Observable 发出项目，如果源 Observable 不发出任何内容，则为默认项目
- SequenceEqual — 确定两个 Observable 是否发出相同的项目序列
- SkipWhile — 丢弃 Observable 发出的项目，直到指定条件变为 false
- TakeUntil — 在第二个 Observable 发出项目或终止后丢弃由 Observable 发出的项目
- TakeWhile — 在指定条件变为 false 后丢弃由 Observable 发出的项目

### 数学和聚合运算符

- Average — 计算 Observable 发出的数字的平均值并发出该平均值
- Concat — 发出来自两个或多个 Observables 的排放，而不将它们交错
- Count — 计算源 Observable 发出的项目数量并仅发出该值
- Max — 确定并发出由 Observable 发出的最大值项
- Min — 确定并发出 Observable 发出的最小值项
- Reduce — 按顺序将函数应用于 Observable 发出的每个项目，并发出最终值
- Sum — 计算 Observable 发出的数字的总和并发出这个总和

### 转换可观察量的运算符

- Error — 返回可观察对象抛出的第一个错误
- Errors — 返回可观察对象抛出的所有错误
- ToMap/ ToMapWithValueSelector/ ToSlice — 将 Observable 转换为另一个对象或数据结构