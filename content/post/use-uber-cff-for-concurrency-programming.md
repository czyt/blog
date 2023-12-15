---
title: "使用uber cff进行并发编程"
date: 2023-12-14
tags: ["golang",  "tools"]
draft: false
---

## 第一个项目

### 配置相关工具

**先决条件**

- Go 1.18 或更新版本
- 带有 go.mod 文件的项目

大多数围棋项目应采取以下步骤建立 cff。

1. 如果项目目录中还没有 "tools.go"，请在其中创建一个。您将在此指定开发时的依赖关系。

   ```bash
   cat > tools.go <<EOF
   //go:build tools
   
   package tools // use your project's package name here
   EOF
   ```

   确保使用与项目目录相同的软件包名称。

2. 将 `import _ "go.uber.org/cff/cmd/cff"` 添加到 tools.go 中。

   ```bash
   echo 'import _ "go.uber.org/cff/cmd/cff"' >> tools.go
   ```

3. 运行 `go mod tidy` 获取最新版本的 cff，或运行 `go get go.uber.org/cff@main` 获取当前未发布的分支。

   ```bash
   go mod tidy
   ```

4. 将 cff CLI 安装到项目的 bin/ 子目录下。

   ```bash
   GOBIN=$(pwd)/bin go install go.uber.org/cff/cmd/cff
   ```

   请随意 gitignore 此目录。

   ```bash
   echo '/bin' >> .gitignore
   ```

5. 在同一目录下的现有 Go 文件中添加以下 `go:generate` 指令。

   ```go
   //go:generate bin/cff ./...
   ```

#### 在新机器上进行设置

一旦项目已经使用 cff，在项目上工作的新机器只需将 cff CLI 安装到 bin/ 目录中即可。

```bash
GOBIN=$(pwd)/bin go install go.uber.org/cff/cmd/cff
```

我们建议将其纳入项目设置说明或脚本。

####  手动设置

或者，您也可以单独安装 cff CLI 和库：

1. 将库添加为项目的依赖项。

   ```bash
   go get go.uber.org/cff
   ```

2. 全局安装 CLI。

   ```bash
   go install go.uber.org/cff/cmd/cff
   ```
### 官方的例子
官方的例子如下
```go
//go:build cff

package main

import (
	"context"
	"fmt"
	"go.uber.org/cff"
	"log"
	"time"
)


type UberAPI interface {
	DriverByID(int) (*Driver, error)
	RiderByID(int) (*Rider, error)
	TripByID(int) (*Trip, error)
	LocationByID(int) (*Location, error)
}

type Driver struct {
	ID   int
	Name string
}

type Location struct {
	ID    int
	City  string
	State string
	// ...
}

type Rider struct {
	ID     int
	Name   string
	HomeID int
}

type Trip struct {
	ID       int
	DriverID int
	RiderID  int
}

type fakeUberClient struct{}

func (*fakeUberClient) DriverByID(id int) (*Driver, error) {
	time.Sleep(500 * time.Millisecond)
	return &Driver{
		ID:   id,
		Name: "Eleanor Nelson",
	}, nil
}

func (*fakeUberClient) LocationByID(id int) (*Location, error) {
	time.Sleep(200 * time.Millisecond)
	return &Location{
		ID:    id,
		City:  "San Francisco",
		State: "California",
	}, nil
}

func (*fakeUberClient) RiderByID(id int) (*Rider, error) {
	time.Sleep(300 * time.Millisecond)
	return &Rider{
		ID:   id,
		Name: "Richard Dickson",
	}, nil
}

func (*fakeUberClient) TripByID(id int) (*Trip, error) {
	time.Sleep(150 * time.Millisecond)
	return &Trip{
		ID:       id,
		DriverID: 42,
		RiderID:  57,
	}, nil
}

type Response struct {
	Rider    string
	Driver   string
	HomeCity string
}

var uber UberAPI = new(fakeUberClient)

func main() {
	ctx, cancel := context.WithTimeout(context.Background(), time.Second)
	defer cancel()
	var res *Response
	err := cff.Flow(ctx,
		cff.Params(12),
		cff.Results(&res),
		cff.Task(func(tripID int) (*Trip, error) {
			return uber.TripByID(tripID)
		}),
		cff.Task(func(trip *Trip) (*Driver, error) {
			return uber.DriverByID(trip.DriverID)
		}),
		cff.Task(func(trip *Trip) (*Rider, error) {
			return uber.RiderByID(trip.RiderID)
		}),
		cff.Task(func(rider *Rider) (*Location, error) {
			return uber.LocationByID(rider.HomeID)
		}),
		cff.Task(func(r *Rider, d *Driver, home *Location) *Response {
			return &Response{
				Driver:   d.Name,
				Rider:    r.Name,
				HomeCity: home.City,
			}
		}),
	)

	if err != nil {
		log.Fatal(err)
	}
	fmt.Println(res.Driver, "drove", res.Rider, "who lives in", res.HomeCity)
}

```
使用`go generate`会生成如下代码
```go
//go:build !cff

package main

import (
	"context"
	"fmt"
	"go.uber.org/cff"
	"log"
	"runtime/debug"
	"time"
)

type UberAPI interface {
	DriverByID(int) (*Driver, error)
	RiderByID(int) (*Rider, error)
	TripByID(int) (*Trip, error)
	LocationByID(int) (*Location, error)
}

type Driver struct {
	ID   int
	Name string
}

type Location struct {
	ID    int
	City  string
	State string
	// ...
}

type Rider struct {
	ID     int
	Name   string
	HomeID int
}

type Trip struct {
	ID       int
	DriverID int
	RiderID  int
}

type fakeUberClient struct{}

func (*fakeUberClient) DriverByID(id int) (*Driver, error) {
	time.Sleep(500 * time.Millisecond)
	return &Driver{
		ID:   id,
		Name: "Eleanor Nelson",
	}, nil
}

func (*fakeUberClient) LocationByID(id int) (*Location, error) {
	time.Sleep(200 * time.Millisecond)
	return &Location{
		ID:    id,
		City:  "San Francisco",
		State: "California",
	}, nil
}

func (*fakeUberClient) RiderByID(id int) (*Rider, error) {
	time.Sleep(300 * time.Millisecond)
	return &Rider{
		ID:   id,
		Name: "Richard Dickson",
	}, nil
}

func (*fakeUberClient) TripByID(id int) (*Trip, error) {
	time.Sleep(150 * time.Millisecond)
	return &Trip{
		ID:       id,
		DriverID: 42,
		RiderID:  57,
	}, nil
}

type Response struct {
	Rider    string
	Driver   string
	HomeCity string
}

var uber UberAPI = new(fakeUberClient)

func main() {
	ctx, cancel := context.WithTimeout(context.Background(), time.Second)
	defer cancel()
	var res *Response
	err := func() (err error) {

		_93_18 := ctx

		_94_14 := 12

		_95_15 := &res

		_96_12 := func(tripID int) (*Trip, error) {
			return uber.TripByID(tripID)
		}

		_99_12 := func(trip *Trip) (*Driver, error) {
			return uber.DriverByID(trip.DriverID)
		}

		_102_12 := func(trip *Trip) (*Rider, error) {
			return uber.RiderByID(trip.RiderID)
		}

		_105_12 := func(rider *Rider) (*Location, error) {
			return uber.LocationByID(rider.HomeID)
		}

		_108_12 := func(r *Rider, d *Driver, home *Location) *Response {
			return &Response{
				Driver:   d.Name,
				Rider:    r.Name,
				HomeCity: home.City,
			}
		}
		ctx := _93_18
		var v1 int = _94_14
		emitter := cff.NopEmitter()

		var (
			flowInfo = &cff.FlowInfo{
				File:   "command-line-arguments\\main.go",
				Line:   93,
				Column: 9,
			}
			flowEmitter = cff.NopFlowEmitter()

			schedInfo = &cff.SchedulerInfo{
				Name:      flowInfo.Name,
				Directive: cff.FlowDirective,
				File:      flowInfo.File,
				Line:      flowInfo.Line,
				Column:    flowInfo.Column,
			}

			// possibly unused
			_ = flowInfo
		)

		startTime := time.Now()
		defer func() { flowEmitter.FlowDone(ctx, time.Since(startTime)) }()

		schedEmitter := emitter.SchedulerInit(schedInfo)

		sched := cff.NewScheduler(
			cff.SchedulerParams{
				Emitter: schedEmitter,
			},
		)

		var tasks []*struct {
			emitter cff.TaskEmitter
			ran     cff.AtomicBool
			run     func(context.Context) error
			job     *cff.ScheduledJob
		}
		defer func() {
			for _, t := range tasks {
				if !t.ran.Load() {
					t.emitter.TaskSkipped(ctx, err)
				}
			}
		}()

		// command-line-arguments\main.go:96:12
		var (
			v2 *Trip
		)
		task0 := new(struct {
			emitter cff.TaskEmitter
			ran     cff.AtomicBool
			run     func(context.Context) error
			job     *cff.ScheduledJob
		})
		task0.emitter = cff.NopTaskEmitter()
		task0.run = func(ctx context.Context) (err error) {
			taskEmitter := task0.emitter
			startTime := time.Now()
			defer func() {
				if task0.ran.Load() {
					taskEmitter.TaskDone(ctx, time.Since(startTime))
				}
			}()

			defer func() {
				recovered := recover()
				if recovered != nil {
					taskEmitter.TaskPanic(ctx, recovered)
					err = &cff.PanicError{
						Value:      recovered,
						Stacktrace: debug.Stack(),
					}
				}
			}()

			defer task0.ran.Store(true)

			v2, err = _96_12(v1)

			if err != nil {
				taskEmitter.TaskError(ctx, err)
				return err
			} else {
				taskEmitter.TaskSuccess(ctx)
			}

			return
		}

		task0.job = sched.Enqueue(ctx, cff.Job{
			Run: task0.run,
		})
		tasks = append(tasks, task0)

		// command-line-arguments\main.go:99:12
		var (
			v3 *Driver
		)
		task1 := new(struct {
			emitter cff.TaskEmitter
			ran     cff.AtomicBool
			run     func(context.Context) error
			job     *cff.ScheduledJob
		})
		task1.emitter = cff.NopTaskEmitter()
		task1.run = func(ctx context.Context) (err error) {
			taskEmitter := task1.emitter
			startTime := time.Now()
			defer func() {
				if task1.ran.Load() {
					taskEmitter.TaskDone(ctx, time.Since(startTime))
				}
			}()

			defer func() {
				recovered := recover()
				if recovered != nil {
					taskEmitter.TaskPanic(ctx, recovered)
					err = &cff.PanicError{
						Value:      recovered,
						Stacktrace: debug.Stack(),
					}
				}
			}()

			defer task1.ran.Store(true)

			v3, err = _99_12(v2)

			if err != nil {
				taskEmitter.TaskError(ctx, err)
				return err
			} else {
				taskEmitter.TaskSuccess(ctx)
			}

			return
		}

		task1.job = sched.Enqueue(ctx, cff.Job{
			Run: task1.run,
			Dependencies: []*cff.ScheduledJob{
				task0.job,
			},
		})
		tasks = append(tasks, task1)

		// command-line-arguments\main.go:102:12
		var (
			v4 *Rider
		)
		task2 := new(struct {
			emitter cff.TaskEmitter
			ran     cff.AtomicBool
			run     func(context.Context) error
			job     *cff.ScheduledJob
		})
		task2.emitter = cff.NopTaskEmitter()
		task2.run = func(ctx context.Context) (err error) {
			taskEmitter := task2.emitter
			startTime := time.Now()
			defer func() {
				if task2.ran.Load() {
					taskEmitter.TaskDone(ctx, time.Since(startTime))
				}
			}()

			defer func() {
				recovered := recover()
				if recovered != nil {
					taskEmitter.TaskPanic(ctx, recovered)
					err = &cff.PanicError{
						Value:      recovered,
						Stacktrace: debug.Stack(),
					}
				}
			}()

			defer task2.ran.Store(true)

			v4, err = _102_12(v2)

			if err != nil {
				taskEmitter.TaskError(ctx, err)
				return err
			} else {
				taskEmitter.TaskSuccess(ctx)
			}

			return
		}

		task2.job = sched.Enqueue(ctx, cff.Job{
			Run: task2.run,
			Dependencies: []*cff.ScheduledJob{
				task0.job,
			},
		})
		tasks = append(tasks, task2)

		// command-line-arguments\main.go:105:12
		var (
			v5 *Location
		)
		task3 := new(struct {
			emitter cff.TaskEmitter
			ran     cff.AtomicBool
			run     func(context.Context) error
			job     *cff.ScheduledJob
		})
		task3.emitter = cff.NopTaskEmitter()
		task3.run = func(ctx context.Context) (err error) {
			taskEmitter := task3.emitter
			startTime := time.Now()
			defer func() {
				if task3.ran.Load() {
					taskEmitter.TaskDone(ctx, time.Since(startTime))
				}
			}()

			defer func() {
				recovered := recover()
				if recovered != nil {
					taskEmitter.TaskPanic(ctx, recovered)
					err = &cff.PanicError{
						Value:      recovered,
						Stacktrace: debug.Stack(),
					}
				}
			}()

			defer task3.ran.Store(true)

			v5, err = _105_12(v4)

			if err != nil {
				taskEmitter.TaskError(ctx, err)
				return err
			} else {
				taskEmitter.TaskSuccess(ctx)
			}

			return
		}

		task3.job = sched.Enqueue(ctx, cff.Job{
			Run: task3.run,
			Dependencies: []*cff.ScheduledJob{
				task2.job,
			},
		})
		tasks = append(tasks, task3)

		// command-line-arguments\main.go:108:12
		var (
			v6 *Response
		)
		task4 := new(struct {
			emitter cff.TaskEmitter
			ran     cff.AtomicBool
			run     func(context.Context) error
			job     *cff.ScheduledJob
		})
		task4.emitter = cff.NopTaskEmitter()
		task4.run = func(ctx context.Context) (err error) {
			taskEmitter := task4.emitter
			startTime := time.Now()
			defer func() {
				if task4.ran.Load() {
					taskEmitter.TaskDone(ctx, time.Since(startTime))
				}
			}()

			defer func() {
				recovered := recover()
				if recovered != nil {
					taskEmitter.TaskPanic(ctx, recovered)
					err = &cff.PanicError{
						Value:      recovered,
						Stacktrace: debug.Stack(),
					}
				}
			}()

			defer task4.ran.Store(true)

			v6 = _108_12(v4, v3, v5)

			taskEmitter.TaskSuccess(ctx)

			return
		}

		task4.job = sched.Enqueue(ctx, cff.Job{
			Run: task4.run,
			Dependencies: []*cff.ScheduledJob{
				task2.job,
				task1.job,
				task3.job,
			},
		})
		tasks = append(tasks, task4)

		if err := sched.Wait(ctx); err != nil {
			flowEmitter.FlowError(ctx, err)
			return err
		}

		*(_95_15) = v6 // *command-line-arguments.Response

		flowEmitter.FlowSuccess(ctx)
		return nil
	}()

	if err != nil {
		log.Fatal(err)
	}
	fmt.Println(res.Driver, "drove", res.Rider, "who lives in", res.HomeCity)
}

```
## 适用场景

cff 由两部分组成：

- cff 命令行工具
- go.uber.org/cff 库

go.uber.org/cff 库定义了几个特殊函数，它们被归类为代码生成指令。例如 `cff.Flow` 、 `cff.Parallel` 和 `cff.Task` 。这些函数的实现是存根：它们实际上不做任何有用的事情。

当你编写使用这些函数的代码并运行 cff CLI 时，它会分析你的代码并搜索对这些函数的调用。一旦在一个文件（例如 `foo.go` ）中找到这些函数，它就会创建一个该文件的镜像副本（ `foo_gen.go` ），并用 cff 生成的代码替换对这些指令的调用。

```go
foo.go                                | foo_gen.go
------------------------------------- | -------------------------------------
//go:build cff                        | //go:build !cff
package foo                           | package foo
                                      |                                       
import (                              | import (                              
  "context"                           |   "context"                           
                                      |                                       
  "go.uber.org/cff"                   |   "go.uber.org/cff"                   
)                                     | )                                     
                                      |                                       
func Bar(ctx context.Context) error { | func Bar(ctx context.Context) error {
  var res Result                      |   var res Result                      
  err := cff.Flow(ctx,                |   err := func() {
    cff.Task(fn1),                    |     x := fn1()
    cff.Task(fn2),                    |     y := fn2()
    // ...                            |     // ...                            
    cff.Results(&res),                |     res = ...
  )                                   |   }()
  if err != nil {                     |   if err != nil {                     
    return err                        |     return err                        
  }                                   |   }                                   
  fmt.Println(res)                    |   fmt.Println(res)                    
}                                     | }                    
```

### cff.Flow

cff.Flow 适用于同时运行相互依赖的函数，并保证函数不会先于其依赖函数运行。

例如，使用 cff，您可以向两个不同的应用程序接口发送请求，并将请求结果反馈到向其他五个应用程序接口发送的请求中，其中一些请求又相互反馈，如此循环，直到所有请求都反馈到代表结果的两个结构体中。同时运行相互依赖的函数，并保证函数不会先于其依赖函数运行。所有这一切都要尽可能多地利用依赖关系的并发性。cc.Flow的解析过程如下假设有三个函数：

- `func f() A`
- `func g() B`
- `func h(A, B) C`

当您编写以下代码时：

```go
var c C
cff.Flow(ctx,
	cff.Task(f),
	cff.Task(g),
	cff.Task(h),
	cff.Results(&c),
)
```

找到 `cff.Flow` 调用后，cff 会检查所有提供的任务来组合数据

{{<mermaid>}}

graph TB
    f["f() A"] & g["g() B"] --feeds--> h["h(A, B) C"] --sets--> c[var c C]

{{</mermaid>}}

然后，它生成代码，用 cff 调度器调度这些任务，并正确指定和连接依赖关系，使 `f` 和 `g` 同时运行，当它们都完成时， `h` 运行它们的结果。当 `h` 完成时，它会将其结果放入 `c` 中。

>cff 调度器是一种通用任务调度器，它使用标准的工作队列模型，在一定数量的程序上运行任务。
>
>它的特别之处在于支持任务之间的依赖关系。在所有被标记为其依赖任务的任务也完成运行之前，它不会运行某个任务。

### cff.Parallel

cff.Parallel适用于同时运行独立功能。您可以选择是在第一次失败后就停下来，还是在失败后继续前进。

### cff.Slice 和cff.Map

cff.Slice 和cff.Map在map或切片的每个元素上运行相同的函数，而不会出现无限制的程序增长。
