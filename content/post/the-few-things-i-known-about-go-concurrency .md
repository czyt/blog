---
title: "golang并发二三事"
date: 2023-12-18
tags: ["golang", "concurrency "]
draft: false
---
> 本文主要是鸟窝《深入理解go并发编程》中的读书速记以及一些并发库的使用例子集合
## 常用的并发库使用
### sourcegraph conc

#### waitgroup

创建一组协程并等待完成：

标准库

```go
func main() {
    var wg sync.WaitGroup
    for i := 0; i < 10; i++ {
        wg.Add(1)
        go func() {
            defer wg.Done()
            // crashes on panic!
            doSomething()
        }()
    }
    wg.Wait()
}
```

conc

```go
func main() {
    var wg conc.WaitGroup
    for i := 0; i < 10; i++ {
        wg.Go(doSomething)
    }
    wg.Wait()
}
```

下面是一个官网博客的例子：

>写一个函数，给定用户的名字，通过网络获取姓氏
>
>```go
>func fetchLastName(ctx context.Context, firstName string) (string, error) {
>    req, err := http.NewRequestWithContext(
>        ctx,
>        "GET",
>        fmt.Sprintf("https://myexampleapp.com/users/%s/last_name", firstName),
>        nil,
>    )
>    if err != nil {
>        return "", err
>    }
>    resp, err := http.DefaultClient.Do(req)
>    if err != nil {
>        return "", err
>    }
>    b, err := io.ReadAll(resp.Body)
>    return string(b), err
>}
>```

#### pool

处理静态goroutine池中每个steam的元素

标准库

```go
func process(stream chan int) {
    var wg sync.WaitGroup
    for i := 0; i < 10; i++ {
        wg.Add(1)
        go func() {
            defer wg.Done()
            for elem := range stream {
                handle(elem)
            }
        }()
    }
    wg.Wait()
}
```

conc

```go
func process(stream chan int) {
    p := pool.New().WithMaxGoroutines(10)
    for elem := range stream {
        elem := elem
        p.Go(func() {
            handle(elem)
        })
    }
    p.Wait()
}
```

书接上面官网的例子：

>如果我们有一个名字列表，并且希望有效地获取每个名字的姓氏，我们可以使用 `conc` 的 `pool` 来完成此操作，如下所示。
>
>```go
>func fetchLastNames_pool(ctx context.Context, firstNames []string) ([]string, error) {
>	p := pool.NewWithResults[string]().WithContext(ctx)
>	for _, firstName := range firstNames {
>		firstName := firstName
>		p.Go(func(ctx context.Context) (string, error) {
>			return fetchLastName(ctx, firstName)
>		})
>	}
>	return p.Wait()
>}
>```

#### iter

处理静态gouroutine池中切片的每个元素

标准库

```go
func process(values []int) {
    feeder := make(chan int, 8)

    var wg sync.WaitGroup
    for i := 0; i < 10; i++ {
        wg.Add(1)
        go func() {
            defer wg.Done()
            for elem := range feeder {
                handle(elem)
            }
        }()
    }

    for _, value := range values {
        feeder <- value
    }
    close(feeder)
    wg.Wait()
}
```

conc

```go
func process(values []int) {
    iter.ForEach(values, handle)
}
```

还是说到上面官网获取姓氏的那个例子：

>使用iter则可以这样写：
>
>```go
>func fetchLastNames2(ctx context.Context, firstNames []string) ([]string, error) {
>	return iter.MapErr(firstNames, func(firstName *string) (string, error) {
>		return fetchLastName(ctx, *firstName)
>	})
>}
>```

对切片进行map操作

标准库

```go
func concMap(
    input []int,
    f func(int) int,
) []int {
    res := make([]int, len(input))
    var idx atomic.Int64

    var wg sync.WaitGroup
    for i := 0; i < 10; i++ {
        wg.Add(1)
        go func() {
            defer wg.Done()

            for {
                i := int(idx.Add(1) - 1)
                if i >= len(input) {
                    return
                }

                res[i] = f(input[i])
            }
        }()
    }
    wg.Wait()
    return res
}
```

conc

```go
func concMap(
    input []int,
    f func(*int) int,
) []int {
    return iter.Map(input, f)
}
```

#### stream

并发处理有序流

标准库

```go
func mapStream(
    in chan int,
    out chan int,
    f func(int) int,
) {
    tasks := make(chan func())
    taskResults := make(chan chan int)

    // Worker goroutines
    var workerWg sync.WaitGroup
    for i := 0; i < 10; i++ {
        workerWg.Add(1)
        go func() {
            defer workerWg.Done()
            for task := range tasks {
                task()
            }
        }()
    }

    // Ordered reader goroutines
    var readerWg sync.WaitGroup
    readerWg.Add(1)
    go func() {
        defer readerWg.Done()
        for result := range taskResults {
            item := <-result
            out <- item
        }
    }()

    // Feed the workers with tasks
    for elem := range in {
        resultCh := make(chan int, 1)
        taskResults <- resultCh
        tasks <- func() {
            resultCh <- f(elem)
        }
    }

    // We've exhausted input.
    // Wait for everything to finish
    close(tasks)
    workerWg.Wait()
    close(taskResults)
    readerWg.Wait()
}
```

conc

```go
func mapStream(
    in chan int,
    out chan int,
    f func(int) int,
) {
    s := stream.New().WithMaxGoroutines(10)
    for elem := range in {
        elem := elem
        s.Go(func() stream.Callback {
            res := f(elem)
            return func() { out <- res }
        })
    }
    s.Wait()
}
```

再举一个官网文章的例子：

> 在 Sourcegraph，我们对有序流进行大量并行处理。在搜索大量代码时，我们通常会得到需要后处理的结果流。流中的每个结果可能需要网络请求，例如，查找存储库上的权限或获取搜索结果的完整文件内容。
>
> 为此，我们始终希望：
>
> - 并行执行网络请求。
> - 尽快向用户展示结果。
> - 保持流的顺序（因为我们已经对结果进行了排名）。
>
> 同时满足所有这三个要求是很困难的，因此我在编写 `conc` 的 Stream 包时的目标之一是尽可能多地抽象出该工作流程的复杂性。
>
> 现在我可以使用类似于下面示例的代码一次获取多个文件的内容。这样可以高效、安全地获取每个文件的内容，同时仍然保持流的原始顺序。
>
> ```go
> func streamFileContents(ctx context.Context, fileNames <-chan string, fileContents chan<- string) {
> 	s := stream.New()
> 	for fileName := range fileNames {
> 		fileName := fileName
> 		s.Go(func() stream.Callback {
> 			contents := fetchFileContents(ctx, fileName)
> 			return func() { fileContents <- contents }
> 		})
> 	}
> 	s.Wait()
> }
> ```




## 参考

+ [sourcegraph conc 代码仓库](https://github.com/sourcegraph/conc)
+ https://about.sourcegraph.com/blog/building-conc-better-structured-concurrency-for-go
+ [鸟窝exp](https://github.com/smallnest/exp)