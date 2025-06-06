---
title: "在go中使用Semaphoregroup"
date: 2025-06-05T10:36:15+08:00
draft: false
tags: ["golang","go-lib"]
author: "czyt"
---
在[netbird](https://github.com/netbirdio/netbird)中看到一个[semaphore-group](https://github.com/netbirdio/netbird/blob/main/util/semaphore-group/semaphore_group.go)函数

```go
package semaphoregroup

import (
	"context"
	"sync"
)

// SemaphoreGroup is a custom type that combines sync.WaitGroup and a semaphore.
type SemaphoreGroup struct {
	waitGroup sync.WaitGroup
	semaphore chan struct{}
}

// NewSemaphoreGroup creates a new SemaphoreGroup with the specified semaphore limit.
func NewSemaphoreGroup(limit int) *SemaphoreGroup {
	return &SemaphoreGroup{
		semaphore: make(chan struct{}, limit),
	}
}

// Add increments the internal WaitGroup counter and acquires a semaphore slot.
func (sg *SemaphoreGroup) Add(ctx context.Context) {
	sg.waitGroup.Add(1)

	// Acquire semaphore slot
	select {
	case <-ctx.Done():
		return
	case sg.semaphore <- struct{}{}:
	}
}

// Done decrements the internal WaitGroup counter and releases a semaphore slot.
func (sg *SemaphoreGroup) Done(ctx context.Context) {
	sg.waitGroup.Done()

	// Release semaphore slot
	select {
	case <-ctx.Done():
		return
	case <-sg.semaphore:
	}
}

// Wait waits until the internal WaitGroup counter is zero.
func (sg *SemaphoreGroup) Wait() {
	sg.waitGroup.Wait()
}
```

官方测试用例

```go
package semaphoregroup

import (
	"context"
	"testing"
	"time"
)

func TestSemaphoreGroup(t *testing.T) {
	semGroup := NewSemaphoreGroup(2)

	for i := 0; i < 5; i++ {
		semGroup.Add(context.Background())
		go func(id int) {
			defer semGroup.Done(context.Background())

			got := len(semGroup.semaphore)
			if got == 0 {
				t.Errorf("Expected semaphore length > 0 , got 0")
			}

			time.Sleep(time.Millisecond)
			t.Logf("Goroutine %d is running\n", id)
		}(i)
	}

	semGroup.Wait()

	want := 0
	got := len(semGroup.semaphore)
	if got != want {
		t.Errorf("Expected semaphore length %d, got %d", want, got)
	}
}

func TestSemaphoreGroupContext(t *testing.T) {
	semGroup := NewSemaphoreGroup(1)
	semGroup.Add(context.Background())
	ctx, cancel := context.WithTimeout(context.Background(), 1*time.Second)
	t.Cleanup(cancel)
	rChan := make(chan struct{})

	go func() {
		semGroup.Add(ctx)
		rChan <- struct{}{}
	}()
	select {
	case <-rChan:
	case <-time.NewTimer(2 * time.Second).C:
		t.Error("Adding to semaphore group should not block when context is not done")
	}

	semGroup.Done(context.Background())

	ctxDone, cancelDone := context.WithTimeout(context.Background(), 1*time.Second)
	t.Cleanup(cancelDone)
	go func() {
		semGroup.Done(ctxDone)
		rChan <- struct{}{}
	}()
	select {
	case <-rChan:
	case <-time.NewTimer(2 * time.Second).C:
		t.Error("Releasing from semaphore group should not block when context is not done")
	}
}
```

这个 `SemaphoreGroup` 库结合了 `sync.WaitGroup` 和信号量（semaphore）的功能，主要用于**限制并发数量的场景**。它可以让你等待一组 goroutine 完成，同时控制同时运行的 goroutine 数量不超过指定限制。

## 主要用途

1. **限制并发处理任务** - 防止创建过多 goroutine 导致系统资源耗尽
2. **控制外部资源访问** - 限制同时访问数据库、API 或文件的连接数
3. **批量处理优化** - 在处理大量任务时保持合理的并发水平

## 使用场景举例

### 1. 批量文件处理

```go
func processFiles(files []string) {
    // 限制同时处理 5 个文件
    sg := semaphoregroup.NewSemaphoreGroup(5)
    ctx := context.Background()
    
    for _, file := range files {
        sg.Add(ctx)
        go func(filename string) {
            defer sg.Done(ctx)
            processFile(filename) // 处理单个文件
        }(file)
    }
    
    sg.Wait() // 等待所有文件处理完成
}
```

### 2. 限制 HTTP 请求并发

```go
func fetchURLs(urls []string) {
    // 限制同时发起 10 个 HTTP 请求
    sg := semaphoregroup.NewSemaphoreGroup(10)
    ctx := context.Background()
    
    for _, url := range urls {
        sg.Add(ctx)
        go func(u string) {
            defer sg.Done(ctx)
            resp, err := http.Get(u)
            if err != nil {
                log.Printf("Error fetching %s: %v", u, err)
                return
            }
            defer resp.Body.Close()
            // 处理响应...
        }(url)
    }
    
    sg.Wait()
}
```

### 3. 数据库批量操作

```go
func processUsers(userIDs []int) {
    // 限制同时 3 个数据库连接
    sg := semaphoregroup.NewSemaphoreGroup(3)
    ctx := context.Background()
    
    for _, id := range userIDs {
        sg.Add(ctx)
        go func(userID int) {
            defer sg.Done(ctx)
            updateUserData(userID) // 更新用户数据
        }(id)
    }
    
    sg.Wait()
}
```

## 优势

- **资源控制**：防止系统过载
- **简化代码**：将 WaitGroup 和 semaphore 逻辑封装在一起
- **上下文支持**：支持取消操作
- **性能优化**：在大批量任务处理中保持稳定性能

这个库特别适合需要处理大量并发任务但又要控制系统负载的场景。