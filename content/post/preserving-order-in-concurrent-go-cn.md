---
title: "在并发Go应用中保持顺序【译】"
date: 2025-09-02T08:53:04+08:00
draft: false
tags: ["go","golang"]
author: "czyt"
---

>原文链接 https://destel.dev/blog/preserving-order-in-concurrent-go

并发是 Go 语言的一大优势，但它带来一个根本性的权衡：当多个 goroutine 同时处理数据时，自然顺序会被打乱。大多数情况下，这并无大碍——无序处理已足够，且更快速、更简单。

但有时，顺序至关重要。

##  当顺序至关重要

以下是三个需要保持顺序至关重要的实际场景：

**实时日志增强** ：您正在处理高流量的日志流，通过数据库或外部 API 为每个条目添加用户元数据。顺序处理无法跟上输入速率，但并发处理会打乱顺序，使得增强后的日志对依赖时间顺序的下游消费者变得不可用。

**在文件列表中查找首个匹配项** ：您需要从云存储下载文件列表，并找到包含特定字符串的第一个文件。并发下载速度更快，但完成顺序是乱序的——第 50 个文件可能比第 5 个文件先完成，因此您不能简单地返回找到的第一个匹配项，因为无法确定更早的文件是否也包含该字符串。

**时间序列数据处理** ：这个场景激发了我的原始实现。我需要下载 90 天的交易日志（每个约 600MB），提取部分数据，然后比较连续日期的数据以进行趋势分析。顺序下载需要数小时；并发下载可实现数量级的速度提升，但会破坏我进行比较所需的时间关联性。

挑战很明确：我们需要在不牺牲结果顺序可预测性的前提下获得并发处理的速度优势。这不仅是理论问题——更是影响实际大规模系统的现实约束。

本文将探讨我在生产级 Go 应用中开发并采用的三种方法。我们将构建一个并发的 `OrderedMap` 函数，它能在保持顺序的同时将输入通道转换为输出通道，并支持具有背压机制的**无限流**处理。通过对每种方法进行基准测试，我们将理解其权衡取舍，并在此过程中发现令人惊讶的性能洞见。

## 问题：为何并发会破坏顺序

![Why are my results out of order? Concurrency.](https://destel.dev/_astro/ordering-meme.BbptM_mi_ZqCeTn.webp)

让我们快速回顾一下为什么并发会打乱顺序。原因之一是各个 goroutine 处理任务的速度不同。另一个常见原因——我们无法预测 Go 运行时如何精确调度 goroutine。

例如，goroutine #2 可能在 goroutine #1 完成第 10 项之前就处理完了第 50 项，导致结果顺序错乱。这是并发处理的自然行为。

若想查看实际效果，这里有一个在 Go Playground 上的快速[演示 ](https://goplay.tools/snippet/hG1xdZvT9FX)。

## 设计理念：背压与缓冲的权衡

传统的顺序并发方法采用某种重排序缓冲区或队列。当工作线程计算出结果但尚不能写入输出时，该结果会被暂存于缓冲区中，直至能够按正确顺序写入。

在这种设计中，缓冲区通常可以无限制地增长。这种情况发生在：

- 输入存在倾斜 – 早期项目的处理时间比后续项目更长
- 下游消费者处理速度较慢

另一种常见方法是将所有结果暂存于内存中（切片/映射等）再进行排序。但我们今天的目标是构建一个流式解决方案，它能够：

- **最小化延迟** – 结果一旦准备就绪立即输出
- **处理无限输入流** – 支持任意大甚至无限的输入（例如从标准输入或网络流读取）
- **保持内存受限** – 避免不必要地在内存中累积结果

话虽如此，下面介绍的算法是背压优先的。如果工作协程还无法将结果写入输出通道，它就会阻塞。这种设计受内存限制，并保持了开发者对 Go 通道行为的预期。

> 从技术上讲，这类算法也进行缓冲处理，但不同之处在于乱序项被暂存在运行中的 goroutine 栈中。因此，在这些算法中要获得更大的“缓冲区”，只需提高并发级别即可。这在实践中效果显著，因为通常当应用程序需要更大缓冲区时，它们也需要更高的并发级别。

## 建立性能基准

要理解排序的真实成本，我们首先需要一个基准进行比较。让我们实现并基准测试一个不保持顺序的基本并发 `Map` 函数——这将准确显示排序方法带来的开销。

我们的 `Map` 函数使用用户提供的函数 `f` 将输入通道转换为输出通道。它构建在一个简单的工作池之上，该工作池会生成多个 goroutine 来并发处理输入项。

```go
// Map transforms items from the input channel using n goroutines, and the
// provided function f. Returns a new channel with transformed items.
func Map[A, B any](in <-chan A, n int, f func(A) B) <-chan B {
	out := make(chan B)
	Loop(in, n, out, func(a A) {
		out <- f(a)
	})
	return out
}

// Loop is a worker pool implementation. It calls function f for each 
// item from the input channel using n goroutines. This is a non-blocking function 
// that signals completion by closing the done channel when all work is finished.
func Loop[A, B any](in <-chan A, n int, done chan<- B, f func(A)) {
	var wg sync.WaitGroup

	for i := 0; i < n; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			for a := range in {
				f(a)
			}
		}()
	}

	go func() {
		wg.Wait()
		if done != nil {
			close(done)
		}
	}()
}

// Discard is a non-blocking function that consumes and discards
// all items from the input channel
func Discard[A any](in <-chan A) {
	go func() {
		for range in {
			// Discard the value
		}
	}()
}

func BenchmarkMap(b *testing.B) {
	for _, n := range []int{1, 2, 4, 8, 12, 50} {
		b.Run(fmt.Sprint("n=", n), func(b *testing.B) {
			in := make(chan int)
			defer close(in)
			out := Map(in, n, func(a int) int {
				//time.Sleep(50 * time.Microsecond)
				return a // no-op: just return the original value
			})
			Discard(out)

			b.ReportAllocs()
			b.ResetTimer()

			for i := 0; i < b.N; i++ {
				in <- 10 // write something to the in chan
			}
		})
	}
}
```

如你所见，`Map` 使用 `Loop` 来创建一个并发处理项目的工作池，而 `Loop` 本身则负责底层的 goroutine 管理和同步。这种关注点的分离在我们构建有序变体时将变得重要。

我们在这里具体测量什么？我们测量的是吞吐量——即我们能够以多快的速度将项目推过整个流水线。由于 `Map` 函数会产生背压（当流水线满时阻塞），因此我们向输入通道输入项目的速率可以作为整体处理速度的准确代理。让我们运行基准测试（我使用苹果 M2 Max 笔记本来运行）：

| Goroutines | 每次操作耗时 | 每次操作内存分配 |
| :--------- | -----------: | ---------------: |
| 2          |    408.6纳秒 |                0 |
| 4          |    445.1纳秒 |                0 |
| 8          |    546.4纳秒 |                0 |
| 12         |    600.2纳秒 |                0 |
| 50         |     1053纳秒 |                0 |

你可能会想：“更高的并发性难道不应该提高吞吐量吗？”在实际应用中，确实如此——但前提是有实际的工作可以并行处理。这里我使用了一个简单的无操作转换来隔离并基准测试 goroutine、通道和协调的纯开销。正如预期的那样，这种开销随着 goroutine 数量的增加而增长。

我们将在文章后面使用这个以开销为重点的基准测试进行比较，但为了证明并发性确实能提升性能，让我们再运行一个模拟了一些工作（50微秒睡眠）的基准测试：

| Goroutines | 每次操作耗时 | 加速比 | 每次操作内存分配 |
| :--------- | -----------: | -----: | ---------------: |
| 1          |    61656纳秒 |  1.0倍 |                0 |
| 2          |    30429纳秒 |  2.0倍 |                0 |
| 4          |    15207纳秒 |  4.1倍 |                0 |
| 8          |     7524纳秒 |  8.2倍 |                0 |
| 12         |     5034纳秒 | 12.2倍 |                0 |
| 50         |     1277纳秒 | 48.3倍 |                0 |

完美！这里我们看到了并发在需要处理实际工作时的显著优势。当每项任务耗时 50 微秒时，将并发从 1 个 goroutine 增加到 50 个，性能提升了近 50 倍。这充分说明了并发处理在实际应用中的巨大价值。

现在，我们准备比较这三种方法，并精确衡量为保持顺序所付出的代价。

## 方法一：ReplyTo Channels

这可能是实现有序并发最符合 Go 语言特性的方式。ReplyTo 模式在 Go 中广为人知（我在[批处理文章](https://destel.dev/blog/real-time-batching-in-go)中也使用过），但不知为何，这是我最难清晰解释的方法。

其工作原理如下：

- 一个**打包器**协程通过为每个输入项附加唯一的 `replyTo` 通道来创建任务。
- **工作器**并发处理任务，并通过这些 `replyTo` 通道发送结果。
- 一个**解包器**协程通过 `replyTo` 通道解包发送的值，并将其写入输出。

下图更详细地展示了这种模式：

![ReplyTo Pattern for Order Preservation](https://destel.dev/_astro/ordering-reply-to.uryc_8x2_20ohzX.svg)

图的左侧是顺序执行的（打包器和解包器），而右侧的工作池则并发运行。注意，只有当解包器准备好接收时，工作器才能发送结果，因为 `replyTo` 通道是无缓冲的。这形成了自然的背压机制，避免了不必要的缓冲。

```go
func OrderedMap1[A, B any](in <-chan A, n int, f func(A) B) <-chan B {
	type Job struct {
		Item    A
		ReplyTo chan B
	}

	// Packer goroutine.
	// `jobs` chan will be processed by the pool
	// `replies` chan will be consumed by unpacker goroutine
	jobs := make(chan Job)
	replies := make(chan chan B, n)
	go func() {
		for item := range in {
			replyTo := make(chan B)
			jobs <- Job{Item: item, ReplyTo: replyTo}
			replies <- replyTo
		}
		close(jobs)
		close(replies)
	}()

	// Worker pool of n goroutines.
	// Sends results back via replyTo channels
	Loop[Job, any](jobs, n, nil, func(job Job) {
		job.ReplyTo <- f(job.Item) // Calculate the result and send it back
		close(job.ReplyTo)
	})

	// Unpacker goroutine.
	// Unpacks replyTo channels in order and sends results to the `out` channel
	out := make(chan B)
	go func() {
		defer close(out)
		for replyTo := range replies {
			result := <-replyTo
			out <- result
		}
	}()
	return out
}
```

 **性能结果：**

| Goroutines | 每次操作耗时 | 与基准对比 | 每次操作内存分配 |
| :--------- | -----------: | ---------: | ---------------: |
| 2          |    818.7纳秒 |   +410纳秒 |                1 |
| 4          |    808.9纳秒 |   +364纳秒 |                1 |
| 8          |    826.8纳秒 |   +280纳秒 |                1 |
| 12         |    825.6纳秒 |   +225纳秒 |                1 |
| 50         |    772.3纳秒 |   -281纳秒 |                1 |

与我们的基准相比，这种方法为每个输入项引入了高达 410 纳秒的开销。部分成本来自于为每个项分配一个新的 `replyTo` 通道。遗憾的是，由于我们的函数是泛型的，无法使用包级别的 `sync.Pool` 来缓解这一问题——不同类型的通道不能共享同一个池。

这个结果的有趣之处还在于，随着 goroutine 数量的增加，排序带来的开销会变小。在某个时刻甚至会发生反转——`OrderedMap1` 变得比 `Map` 更快（在 50 个 goroutine 时快-281 纳秒）。

我尚未深入探究这一现象。我认为这不可能是由 `Map` 内部的低效引起的，因为它已经基于最简单的基于通道的工作池。我的一个猜测是，在 `Map` 中，我们有 50 个 goroutine 竞争写入单个输出通道。相反，在 `OrderedMap` 中，尽管有额外的移动部件，但只有一个 goroutine 在写入输出。

现在让我们转向下一种方法。

## 方法二：使用 sync.Cond 实现轮转机制

这是我需要有序并发时实现的第一个算法，它比 ReplyTo 方法更容易解释。

我们为每个项目附加一个递增索引，并将其发送到工作池。每个工作器执行计算后，会等待轮到自己的时机，再将结果写入输出通道。

这种条件等待通过受 `sync.Cond` 保护的共享 `currentIndex` 变量实现。`sync.Cond` 是标准库中一个强大但未被充分利用的并发原语，它允许 goroutine 等待特定条件，并在条件变化时被唤醒。

轮转机制的工作原理如下：

![Turn-taking with sync.Cond](https://destel.dev/_astro/ordering-sync-cond.BjoJOBJ6_Z1EaGce.svg)此处，每次写入后，所有工作器（通过广播方式）被唤醒，并重新检查“是否轮到我？”的条件。

```go
func OrderedMap2[A, B any](in <-chan A, n int, f func(A) B) <-chan B {
	type Job struct {
		Item  A
		Index int
	}

	// Indexer goroutine.
	// Assign an index to each item from the input channel
	jobs := make(chan Job)
	go func() {
		i := 0
		for item := range in {
			jobs <- Job{Item: item, Index: i}
			i++
		}
		close(jobs)
	}()

	// Shared state.
	// Index of the next result that must be written to the output channel.
	nextIndex := 0
	cond := sync.NewCond(new(sync.Mutex))

	// Worker pool of n goroutines.
	out := make(chan B)
	Loop(jobs, n, out, func(job Job) {
		result := f(job.Item) // Calculate the result

		// Cond must be used with a locked mutex (see stdlib docs)
		cond.L.Lock()

		// wait until it's our turn to write the result
		for job.Index != nextIndex {
			cond.Wait()
		}

		// Write the result
		out <- result

		// Increment the index and notify all other workers
		nextIndex++
		cond.Broadcast()

		cond.L.Unlock()
	})

	return out
}
```

 **性能结果：**

| Goroutines | 每次操作耗时 | 与基准对比 | 每次操作内存分配 |
| :--------- | -----------: | ---------: | ---------------: |
| 2          |    867.7纳秒 |   +459纳秒 |                0 |
| 4          |     1094纳秒 |   +649纳秒 |                0 |
| 8          |     1801纳秒 |  +1255纳秒 |                0 |
| 12         |     2987纳秒 |  +2387纳秒 |                0 |
| 50         |    16074纳秒 | +15021纳秒 |                0 |

结果说明——不再有逐项分配，这对内存效率极为有利。但存在一个关键缺陷：随着 goroutine 数量的增加，性能显著下降。这是因为共享状态和“惊群效应”问题：每次写入后，所有 goroutine 通过 `cond.Broadcast()` 被唤醒，但只有一个会执行有效工作。

这种低效让我开始思考：“如何只唤醒应该进行下一次写入的 goroutine 呢？”于是，第三种方法应运而生。

## 方法三：权限传递链

关键洞察在于：何时可以安全地写入输出#5？在输出#4 被写入之后。谁知道输出#4 何时被写入？正是写入它的那个 goroutine。

在此算法中，任何任务必须持有写入权限，其工作线程才能将结果发送到输出通道。我们将任务串联起来，使每个任务都明确知道下一个任务是谁，并能将权限传递给它。这是通过为每个任务附加两个通道实现的：`canWrite` 通道用于接收权限，`nextCanWrite` 通道用于将权限传递给下一个任务。

![Permission Passing Chain for Order Preservation](https://destel.dev/_astro/ordering-can-write.CSQk5VmZ_Z2uhjAb.svg)

这种链式结构使得工作线程的逻辑变得异常简单：

- **计算** ：使用提供的函数处理任务
- **等待** ：从 `canWrite` 通道接收权限
- **写入** ：将结果发送至输出通道
- **传递** ：通过 `nextCanWrite` 通道将权限传递给下一个任务

以下是展示整个流程的图表：

![Permission Passing Chain for Order Preservation](https://destel.dev/_astro/ordering-chain.CJCAX1Ri_Zygkoj.svg)

绿色箭头展示了写入权限如何沿着链从一个任务传递到另一个任务。这本质上是一种令牌传递算法，完全避免了“惊群”问题——每个 goroutine 只唤醒另一个 goroutine，实现了高效的点对点信号传递，而非代价高昂的广播。

让我们看看这如何转化为代码。实现分为两部分：一个“链接器”goroutine 负责构建链，以及遵循计算-等待-写入-传递模式的工作者：

```go
func OrderedMap3[A, B any](in <-chan A, n int, f func(A) B) <-chan B {
	type Job[A any] struct {
		Item         A
		CanWrite     chan struct{}
		NextCanWrite chan struct{} // canWrite channel of the next job
	}

	// Linker goroutine:
	// Builds a chain of jobs where each has a CanWrite channel attached.
	// Additionally, each job knows about the CanWrite channel of the next job in the chain.
	jobs := make(chan Job[A])
	go func() {
		defer close(jobs)

		var canWrite, nextCanWrite chan struct{}
		nextCanWrite = make(chan struct{}, 1)
		close(nextCanWrite) // the first job can write immediately

		for item := range in {
			canWrite, nextCanWrite = nextCanWrite, make(chan struct{}, 1)
			jobs <- Job[A]{item, canWrite, nextCanWrite}
		}
	}()

	// Worker pool of n goroutines.
	// Jobs pass the write permission along the chain.
	out := make(chan B)
	Loop(jobs, n, out, func(job Job[A]) {
		result := f(job.Item) // Calculate the result

		<-job.CanWrite          // Wait for the write permission
		out <- result           // Write to the output channel
		close(job.NextCanWrite) // Pass the permission to the next job
	})

	return out
}
```

 **性能结果：**

| Goroutines | 每次操作耗时 | 与基准对比 | 每次操作内存分配 |
| :--------- | -----------: | ---------: | ---------------: |
| 2          |    927.2纳秒 |   +519纳秒 |                1 |
| 4          |    939.8纳秒 |   +495纳秒 |                1 |
| 8          |    860.7纳秒 |   +314纳秒 |                1 |
| 12         |    823.8纳秒 |   +224纳秒 |                1 |
| 50         |    609.8纳秒 |   -443纳秒 |                1 |

这里的结果与我们在 ReplyTo 方法中看到的非常相似。几乎相同的开销，在更高并发级别出现相同的反转现象，以及每个项目相同的额外分配。但有一个不同之处…

与方法一不同，这里我们分配了一个非泛型的 `chan struct{}`。这意味着我们可以使用包级别的 `sync.Pool` 来消除这些分配——接下来让我们探讨这一点。

## 方法三 a：零分配权限传递链

让我们为 `canWrite` 通道创建一个池。实现很简单——包括池本身以及创建/释放函数。

```go
// Package-level pool for canWrite channels
type chainedItem[A any] struct {
	Value        A
	CanWrite     chan struct{}
	NextCanWrite chan struct{} // canWrite channel for the next item
}

var canWritePool sync.Pool

func makeCanWriteChan() chan struct{} {
	ch := canWritePool.Get()
	if ch == nil {
		return make(chan struct{}, 1)
	}
	return ch.(chan struct{})
}

func releaseCanWriteChan(ch chan struct{}) {
	canWritePool.Put(ch)
}
```

现在，让我们在权限传递算法中使用这个池。由于通道被重复使用，我们不能再通过关闭它们来发送信号。相反，工作者必须从这些通道读取和写入空结构体。

```go
func OrderedMap3a[A, B any](in <-chan A, n int, f func(A) B) <-chan B {
	type Job[A any] struct {
		Item         A
		CanWrite     chan struct{}
		NextCanWrite chan struct{} // canWrite channel of the next job
	}

	// Linker goroutine:
	// Builds a chain of jobs where each has a CanWrite channel attached.
	// Additionally, each job knows about the CanWrite channel of the next job in the chain.
	jobs := make(chan Job[A])
	go func() {
		defer close(jobs)

		var canWrite, nextCanWrite chan struct{}
		nextCanWrite = makeCanWriteChan()
		nextCanWrite <- struct{}{} // the first job can write immediately

		for item := range in {
			canWrite, nextCanWrite = nextCanWrite, makeCanWriteChan()
			jobs <- Job[A]{item, canWrite, nextCanWrite}
		}
	}()

	// Worker pool of n goroutines.
	// Jobs pass the write permission along the chain.
	out := make(chan B)
	Loop(jobs, n, out, func(job Job[A]) {
		result := f(job.Item) // Calculate the result

		<-job.CanWrite                    // Wait for the write permission
		out <- result                     // Write to the output channel
		releaseCanWriteChan(job.CanWrite) // Release our canWrite channel to the pool
		job.NextCanWrite <- struct{}{}    // Pass the permission to the next job
	})

	return out
}
```

**使用池化技术的性能结果：**

| Goroutines | 每次操作耗时 | 与基准对比 | 每次操作内存分配 |
| :--------- | -----------: | ---------: | ---------------: |
| 2          |    891.0纳秒 |   +482纳秒 |                0 |
| 4          |    916.5纳秒 |   +471纳秒 |                0 |
| 8          |    879.5纳秒 |   +333纳秒 |                0 |
| 12         |    872.6纳秒 |   +272纳秒 |                0 |
| 50         |    657.6纳秒 |   -395纳秒 |                0 |

完美！零内存分配且性能优异，意味着长时间运行的任务对垃圾回收（GC）的压力更小。但这种方法还有另一个妙招……

## 还有一点：构建可复用的抽象

权限传递方法与 ReplyTo 方法相比还有另一个显著优势：它控制的是**何时**写入，而非**何处**写入。

我承认——有时我会有点沉迷于构建清晰的抽象层。在开发 [rill](https://github.com/destel/rill) 时，我特别想将这种排序逻辑提取成可复用和可测试的模块。这个“何时与何处”的区别对我来说是个顿悟时刻。

由于算法不关心输出写入的位置，因此很容易将其抽象成一个独立的函数——`OrderedLoop`。其 API 与我们之前使用的 `Loop` 函数非常相似，但这里的用户函数接收两个参数——一个 `item` 和一个 `canWrite` 通道。 **重要的是** ，用户函数必须恰好从 `canWrite` 通道读取一次，以避免死锁或未定义行为。

```go
func OrderedLoop[A, B any](in <-chan A, done chan<- B, n int, f func(a A, canWrite <-chan struct{})) {
	type Job[A any] struct {
		Item         A
		CanWrite     chan struct{}
		NextCanWrite chan struct{} // canWrite channel of the next job
	}

	// Linker goroutine:
	// Builds a chain of jobs where each has a CanWrite channel attached.
	// Additionally, each job knows about the CanWrite channel of the next job in the chain.
	jobs := make(chan Job[A])
	go func() {
		defer close(jobs)

		var canWrite, nextCanWrite chan struct{}
		nextCanWrite = makeCanWriteChan()
		nextCanWrite <- struct{}{} // the first job can write immediately

		for item := range in {
			canWrite, nextCanWrite = nextCanWrite, makeCanWriteChan()
			jobs <- Job[A]{item, canWrite, nextCanWrite}
		}
	}()

	// Worker pool of n goroutines.
	// Jobs pass the write permission along the chain.
	Loop(jobs, n, done, func(job Job[A]) {
		f(job.Item, job.CanWrite) // Do the work

		releaseCanWriteChan(job.CanWrite) // Release item's canWrite channel to the pool
		job.NextCanWrite <- struct{}{}    // Pass the permission to the next job
	})
}
```

典型用法如下：

```go
OrderedLoop(in, out, n, func(a A, canWrite <-chan struct{}) {
	// [Do processing here]
	
	// Everything above this line is executed concurrently,
	// everything below it is executed sequentially and in order
	<-canWrite
	
	// [Write results somewhere]
})
```

有了这个抽象概念，构建任何有序操作就变得异常简单。例如，`OrderedMap` 仅需 7 行代码即可实现：

```go
func OrderedMap3b[A, B any](in <-chan A, n int, f func(A) B) <-chan B {
	out := make(chan B)
	OrderedLoop(in, out, n, func(a A, canWrite <-chan struct{}) {
		result := f(a)
		<-canWrite
		out <- result
	})
	return out
}
```

我们也可以轻松构建一个 `OrderedFilter`，它可以根据条件输出结果：

```
func OrderedFilter[A any](in <-chan A, n int, predicate func(A) bool) <-chan A {
	out := make(chan A)
	OrderedLoop(in, out, n, func(a A, canWrite <-chan struct{}) {
		keep := predicate(a)
		<-canWrite
		if keep {
			out <- a
		}
	})
	return out
}
```

甚至是一个 `OrderedSplit`，它根据谓词将项目分发到两个通道：

```go
func OrderedSplit[A any](in <-chan A, n int, predicate func(A) bool) (<-chan A, <-chan A) {
	outTrue := make(chan A)
	outFalse := make(chan A)
	done := make(chan struct{})
	
	OrderedLoop(in, done, n, func(a A, canWrite <-chan struct{}) {
		shouldGoToTrue := predicate(a)
		<-canWrite
		if shouldGoToTrue {
			outTrue <- a
		} else {
			outFalse <- a
		}
	})
	
	go func() {
		<-done
		close(outTrue)
		close(outFalse)
	}()
	
	return outTrue, outFalse
}
```

简而言之，这种抽象化让构建有序操作变得轻而易举。

##  性能比较

以下是所有方法在不同并发级别下的表现：

| 并发       |      基准 | 方法一  （回复） | 方法二  （同步条件变量） | 方法三  （权限） | 方法三 a  （+ 池） |
| :--------- | --------: | ---------------: | -----------------------: | ---------------: | -----------------: |
| 2          | 408.6纳秒 |        818.7纳秒 |                867.7纳秒 |        927.2纳秒 |          891.0纳秒 |
| 4          | 445.1纳秒 |        808.9纳秒 |                 1094纳秒 |        939.8纳秒 |          916.5纳秒 |
| 8          | 546.4纳秒 |        826.8纳秒 |                 1801纳秒 |        860.7纳秒 |          879.5纳秒 |
| 12         | 600.2纳秒 |        825.6纳秒 |                 2987纳秒 |        823.8纳秒 |          872.6纳秒 |
| 50         |  1053纳秒 |        772.3纳秒 |                16074纳秒 |        609.8纳秒 |          657.6纳秒 |
| **零分配** |         ✅ |                ❌ |                        ✅ |                ❌ |                  ✅ |

##  关键要点

1. **sync.Cond 不适用于有序并发** ——虽然在低并发时性能尚可，但随着 goroutine 数量的增加，由于惊群效应问题，其性能会彻底崩溃。
2. **ReplyTo 是一个强有力的竞争者** ——与基准相比，它最多仅增加约 500 纳秒的开销，但每个输入项需要额外分配一次内存，从而增加了垃圾回收的压力。
3. **权限传递成为明显赢家** ——它具备所有优势：
   - **优异性能** ：与基准相比最多仅增加约 500 纳秒的开销
   - **零内存分配** ：为长时间运行任务减轻 GC 压力
   - **清晰抽象** ：核心同步逻辑可被抽象化，用于构建各种并发操作
   - **可维护性** ：关注点分离以及直观的“计算→等待→写入→传递”模式，使得代码易于维护和理解

这项探索表明，有序并发并不一定代价高昂。采用恰当的方法，您可以同时实现并发性、顺序性和背压。特别是权限传递模式，展示了如何创造性地利用 Go 的通道来解决复杂的协调问题。

最后，这些模式已通过 [rill 并发工具包 ](https://github.com/destel/rill)（GitHub 上 1.7k 🌟）在生产环境中经过实战检验。它实现了 `Map`、`OrderedMap` 以及许多其他并发操作。Rill 专注于可组合性——操作可链接成更大的流水线——同时增加了全面的错误处理、上下文友好设计，并保持了超过 95%的测试覆盖率。

##  演练场链接：

- [本文代码](https://goplay.tools/snippet/VMCL1gSyUSX)
- [在文件列表中查找首个匹配项示例](https://goplay.tools/snippet/UuuV2t5xbN2)