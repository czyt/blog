---
title: "从Golang的开源项目中学习不同的功能实现"
date: 2022-11-25
tags: ["golang", "open source","MongoDB"]
draft: false
---

## 缘起

最近看到有些go开源项目中的代码，看到其中的功能，故整理备用。

## 数据结构

### 优先级队列

项目 https://github.com/tigrisdata/tigris

```go
// Copyright 2022-2023 Tigris Data, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package container

import (
	"container/heap"

	"github.com/pkg/errors"
)

// ErrEmpty is returned for queues with no items.
var ErrEmpty = errors.New("queue is empty")

type PriorityQueue[T any] struct {
	queue queue[T]
}

// NewPriorityQueue initializes internal data structure and returns new
// PriorityQueue accepting a comparator function
// comp function decides ordering in queue, Sort `this` before `that` if True.
func NewPriorityQueue[T any](comp func(this, that *T) bool) *PriorityQueue[T] {
	return &PriorityQueue[T]{queue: queue[T]{
		data:       make([]*T, 0),
		comparator: comp,
	}}
}

// Len returns items in queue.
func (pq *PriorityQueue[T]) Len() int {
	return pq.queue.Len()
}

// Pop pops the highest priority item from queue
// The complexity is O(log n) where n = h.Len().
func (pq *PriorityQueue[T]) Pop() (*T, error) {
	if pq.Len() < 1 {
		return nil, ErrEmpty
	}
	item := heap.Pop(&pq.queue).(*T)
	return item, nil
}

// Push pushes the element x onto the heap.
// The complexity is O(log n) where n = h.Len().
func (pq *PriorityQueue[T]) Push(x *T) {
	// Copy the item value(s) so that modifications to the source item does not
	// affect the item on the queue
	clone := *x

	heap.Push(&pq.queue, &clone)
}

// queue is the internal data structure used to satisfy heap.Interface and not
// supposed to be used directly. Use PriorityQueue instead.
type queue[T any] struct {
	data       []*T
	comparator func(this, that *T) bool
}

func (q queue[T]) Len() int {
	return len(q.data)
}

func (q queue[T]) Less(i, j int) bool {
	return q.comparator(q.data[i], q.data[j])
}

func (q queue[T]) Swap(i, j int) {
	q.data[i], q.data[j] = q.data[j], q.data[i]
}

func (q *queue[T]) Push(x any) {
	item := x.(*T)
	q.data = append(q.data, item)
}

func (q *queue[T]) Pop() any {
	old := q.data
	n := len(old)
	item := old[n-1]
	old[n-1] = nil // avoid memory leak
	q.data = old[0 : n-1]
	return item
}

```

### HashSet

```go
// Copyright 2022-2023 Tigris Data, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package container

type HashSet struct {
	stringMap map[string]struct{}
}

func NewHashSet(s ...string) HashSet {
	set := HashSet{
		stringMap: make(map[string]struct{}, len(s)*2),
	}
	for _, ss := range s {
		set.Insert(ss)
	}
	return set
}

func (set *HashSet) Length() int {
	return len(set.stringMap)
}

func (set *HashSet) Insert(s ...string) {
	for _, ss := range s {
		set.stringMap[ss] = struct{}{}
	}
}

func (set *HashSet) Contains(s string) bool {
	if _, ok := set.stringMap[s]; ok {
		return true
	}
	return false
}

func (set *HashSet) ToList() []string {
	list := make([]string, 0, len(set.stringMap))
	for k := range set.stringMap {
		list = append(list, k)
	}
	return list
}

```

### *Queue*

摘自 Google https://github.com/ServiceWeaver/weaver

```go
package queue

import (
	"context"
	"sync"

	"github.com/ServiceWeaver/weaver/internal/cond"
)

// Queue is a thread-safe queue.
//
// Unlike a Go channel, Queue doesn't have any constraints on how many
// elements can be in the queue.
type Queue[T any] struct {
	mu    sync.Mutex
	elems []T
	wait  *cond.Cond
}

// Push places elem at the back of the queue.
func (q *Queue[T]) Push(elem T) {
	q.mu.Lock()
	defer q.mu.Unlock()
	q.init()
	q.elems = append(q.elems, elem)
	q.wait.Signal()
}

// Pop removes the element from the front of the queue and returns it.
// It blocks if the queue is empty.
// It returns an error if the passed-in context is canceled.
func (q *Queue[T]) Pop(ctx context.Context) (elem T, err error) {
	if err = ctx.Err(); err != nil {
		return
	}
	q.mu.Lock()
	defer q.mu.Unlock()
	q.init()
	for len(q.elems) == 0 {
		if err = q.wait.Wait(ctx); err != nil {
			return
		}
	}
	elem = q.elems[0]
	q.elems = q.elems[1:]
	return
}

// init initializes the queue.
//
// REQUIRES: q.mu is held
func (q *Queue[T]) init() {
	if q.wait == nil {
		q.wait = cond.NewCond(&q.mu)
	}
}
```

### Cond

> // *# Implementation Overview*
>
> // *When a goroutine calls cond.Wait(ctx), Wait creates a channel and appends it*
>
> // *to a queue of waiting channels inside of cond. It then performs a select on*
>
> // *ctx.Done and the newly minted channel. Signal pops the first waiting channel*
>
> // *and closes it. Broadcast pops and closes every waiting channel.*
>
> 
>
> // *Cond is a context-aware version of a sync.Cond. Like a sync.Cond, a Cond*
>
> // *must not be copied after first use.*
来源同上
```go
type Cond struct {
	L sync.Locker

	// Note that we need our own mutex instead of using L because Signal and
	// Broadcast can be called without holding L.
	m       sync.Mutex
	waiters []chan struct{}
}

// NewCond returns a new Cond with Locker l.
func NewCond(l sync.Locker) *Cond {
	return &Cond{L: l}
}

// Broadcast is identical to sync.Cond.Broadcast.
func (c *Cond) Broadcast() {
	c.m.Lock()
	defer c.m.Unlock()
	for _, wait := range c.waiters {
		close(wait)
	}
	c.waiters = nil
}

// Signal is identical to sync.Cond.Signal.
func (c *Cond) Signal() {
	c.m.Lock()
	defer c.m.Unlock()
	if len(c.waiters) == 0 {
		return
	}
	wait := c.waiters[0]
	c.waiters = c.waiters[1:]
	close(wait)
}

// Wait behaves identically to sync.Cond.Wait, except that it respects the
// provided context. Specifically, if the context is cancelled, c.L is
// reacquired and ctx.Err() is returned. Example usage:
//
//	for !condition() {
//	    if err := cond.Wait(ctx); err != nil {
//	        // The context was cancelled. cond.L is locked at this point.
//	        return err
//	    }
//	    // Wait returned normally. cond.L is still locked at this point.
//	}
func (c *Cond) Wait(ctx context.Context) error {
	wait := make(chan struct{})
	c.m.Lock()
	c.waiters = append(c.waiters, wait)
	c.m.Unlock()

	c.L.Unlock()
	var err error
	select {
	case <-ctx.Done():
		err = ctx.Err()
	case <-wait:
	}
	c.L.Lock()
	return err
}

```
### Heap
来源同上
```go
package heap

import "container/heap"

// Heap is a generic min-heap. Modifying an element while it is on the heap
// invalidates the heap.
type Heap[T any] struct {
	// Heap wraps the heap package in the standard library, making it more
	// ergonomic. For example, heap.Pop can panic when called on an empty heap,
	// whereas Heap.Pop returns a false ok value when called on an empty heap.
	// Conversely, Heap is slower than the heap package in the standard
	// library, so prefer the standard library package if you need good
	// performance.
	h *sliceheap[T]
}

// New returns a new empty heap, with elements sorted using the provided
// comparator function.
func New[T any](less func(x, y T) bool) *Heap[T] {
	h := &sliceheap[T]{less: less}
	heap.Init(h)
	return &Heap[T]{h: h}
}

// Len returns the length of the heap.
func (h *Heap[T]) Len() int {
	return h.h.Len()
}

// Push pushes an element onto the heap.
func (h *Heap[T]) Push(val T) {
	heap.Push(h.h, val)
}

// Peek returns the least element from the heap, if the heap is non-empty.
// Unlike Pop, Peek does not modify the heap.
func (h *Heap[T]) Peek() (val T, ok bool) {
	if h.h.Len() == 0 {
		return val, false
	}
	return h.h.xs[0], true
}

// Pop pops the least element from the heap, if the heap is non-empty.
func (h *Heap[T]) Pop() (val T, ok bool) {
	if h.h.Len() == 0 {
		return val, false
	}
	return heap.Pop(h.h).(T), true
}

// sliceheap is an array-backed heap that implements the heap.Interface
// interface, allowing us to call heap operations on it.
type sliceheap[T any] struct {
	less func(x, y T) bool // orders xs
	xs   []T               // the heap
}

// Len implements the heap.Interface interface.
func (h *sliceheap[T]) Len() int {
	return len(h.xs)
}

// Less implements the heap.Interface interface.
func (h *sliceheap[T]) Less(i, j int) bool {
	return h.less(h.xs[i], h.xs[j])
}

// Swap implements the heap.Interface interface.
func (h *sliceheap[T]) Swap(i, j int) {
	h.xs[i], h.xs[j] = h.xs[j], h.xs[i]
}

// Push implements the heap.Interface interface.
func (h *sliceheap[T]) Push(x interface{}) {
	h.xs = append(h.xs, x.(T))
}

// Pop implements the heap.Interface interface.
func (h *sliceheap[T]) Pop() interface{} {
	x := h.xs[len(h.xs)-1]
	h.xs = h.xs[:len(h.xs)-1]
	return x
}

```
### RingBuffer

来源  [tailscale](https://github.com/tailscale/tailscale/blob/main/util/ringbuffer/ringbuffer.go)

```go
// Copyright (c) Tailscale Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

// Package ringbuffer contains a fixed-size concurrency-safe generic ring
// buffer.
package ringbuffer

import "sync"

// New creates a new RingBuffer containing at most max items.
func New[T any](max int) *RingBuffer[T] {
	return &RingBuffer[T]{
		max: max,
	}
}

// RingBuffer is a concurrency-safe ring buffer.
type RingBuffer[T any] struct {
	mu  sync.Mutex
	pos int
	buf []T
	max int
}

// Add appends a new item to the RingBuffer, possibly overwriting the oldest
// item in the buffer if it is already full.
func (rb *RingBuffer[T]) Add(t T) {
	rb.mu.Lock()
	defer rb.mu.Unlock()
	if len(rb.buf) < rb.max {
		rb.buf = append(rb.buf, t)
	} else {
		rb.buf[rb.pos] = t
		rb.pos = (rb.pos + 1) % rb.max
	}
}

// GetAll returns a copy of all the entries in the ring buffer in the order they
// were added.
func (rb *RingBuffer[T]) GetAll() []T {
	if rb == nil {
		return nil
	}
	rb.mu.Lock()
	defer rb.mu.Unlock()
	out := make([]T, len(rb.buf))
	for i := 0; i < len(rb.buf); i++ {
		x := (rb.pos + i) % rb.max
		out[i] = rb.buf[x]
	}
	return out
}

// Len returns the number of elements in the ring buffer. Note that this value
// could change immediately after being returned if a concurrent caller
// modifies the buffer.
func (rb *RingBuffer[T]) Len() int {
	if rb == nil {
		return 0
	}
	rb.mu.Lock()
	defer rb.mu.Unlock()
	return len(rb.buf)
}

// Clear will empty the ring buffer.
func (rb *RingBuffer[T]) Clear() {
	rb.mu.Lock()
	defer rb.mu.Unlock()
	rb.pos = 0
	rb.buf = nil
}
```

### LRU

tailscale项目，[源地址](https://github.com/tailscale/tailscale/blob/main/util/lru/lru.go) 另外 Hashcorp也有一个 [地址](https://github.com/hashicorp/golang-lru)

```go
// Copyright (c) Tailscale Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

// Package lru contains a typed Least-Recently-Used cache.
package lru

import (
	"container/list"
)

// Cache is container type keyed by K, storing V, optionally evicting the least
// recently used items if a maximum size is exceeded.
//
// The zero value is valid to use.
//
// It is not safe for concurrent access.
//
// The current implementation is just the traditional LRU linked list; a future
// implementation may be more advanced to avoid pathological cases.
type Cache[K comparable, V any] struct {
	// MaxEntries is the maximum number of cache entries before
	// an item is evicted. Zero means no limit.
	MaxEntries int

	ll *list.List
	m  map[K]*list.Element // of *entry[K,V]
}

// entry is the element type for the container/list.Element.
type entry[K comparable, V any] struct {
	key   K
	value V
}

// Set adds or replaces a value to the cache, set or updating its associated
// value.
//
// If MaxEntries is non-zero and the length of the cache is greater
// after any addition, the least recently used value is evicted.
func (c *Cache[K, V]) Set(key K, value V) {
	if c.m == nil {
		c.m = make(map[K]*list.Element)
		c.ll = list.New()
	}
	if ee, ok := c.m[key]; ok {
		c.ll.MoveToFront(ee)
		ee.Value.(*entry[K, V]).value = value
		return
	}
	ele := c.ll.PushFront(&entry[K, V]{key, value})
	c.m[key] = ele
	if c.MaxEntries != 0 && c.Len() > c.MaxEntries {
		c.DeleteOldest()
	}
}

// Get looks up a key's value from the cache, returning either
// the value or the zero value if it not present.
//
// If found, key is moved to the front of the LRU.
func (c *Cache[K, V]) Get(key K) V {
	v, _ := c.GetOk(key)
	return v
}

// Contains reports whether c contains key.
//
// If found, key is moved to the front of the LRU.
func (c *Cache[K, V]) Contains(key K) bool {
	_, ok := c.GetOk(key)
	return ok
}

// GetOk looks up a key's value from the cache, also reporting
// whether it was present.
//
// If found, key is moved to the front of the LRU.
func (c *Cache[K, V]) GetOk(key K) (value V, ok bool) {
	if ele, hit := c.m[key]; hit {
		c.ll.MoveToFront(ele)
		return ele.Value.(*entry[K, V]).value, true
	}
	var zero V
	return zero, false
}

// Delete removes the provided key from the cache if it was present.
func (c *Cache[K, V]) Delete(key K) {
	if e, ok := c.m[key]; ok {
		c.deleteElement(e)
	}
}

// DeleteOldest removes the item from the cache that was least recently
// accessed. It is a no-op if the cache is empty.
func (c *Cache[K, V]) DeleteOldest() {
	if c.ll != nil {
		if e := c.ll.Back(); e != nil {
			c.deleteElement(e)
		}
	}
}

func (c *Cache[K, V]) deleteElement(e *list.Element) {
	c.ll.Remove(e)
	delete(c.m, e.Value.(*entry[K, V]).key)
}

// Len returns the number of items in the cache.
func (c *Cache[K, V]) Len() int { return len(c.m) }
```

### Set

来源 [tailscale](https://github.com/tailscale/tailscale/blob/main/util/set/set.go)

```go
// Copyright (c) Tailscale Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

// Package set contains set types.
package set

// Set is a set of T.
type Set[T comparable] map[T]struct{}

// Add adds e to the set.
func (s Set[T]) Add(e T) { s[e] = struct{}{} }

// Contains reports whether s contains e.
func (s Set[T]) Contains(e T) bool {
	_, ok := s[e]
	return ok
}

// Len reports the number of items in s.
func (s Set[T]) Len() int { return len(s) }

// HandleSet is a set of T.
//
// It is not safe for concurrent use.
type HandleSet[T any] map[Handle]T

// Handle is a opaque comparable value that's used as the map key
// in a HandleSet. The only way to get one is to call HandleSet.Add.
type Handle struct {
	v *byte
}

// Add adds the element (map value) e to the set.
//
// It returns the handle (map key) with which e can be removed, using a map
// delete.
func (s *HandleSet[T]) Add(e T) Handle {
	h := Handle{new(byte)}
	if *s == nil {
		*s = make(HandleSet[T])
	}
	(*s)[h] = e
	return h

```

## 工具类

### Mak

>// Package mak helps make maps. It contains generic helpers to make/assign
>// things, notably to maps, but also slices.

来源  tailscale [源码路径](https://github.com/tailscale/tailscale/blob/main/util/mak/mak.go)

```go
// Copyright (c) Tailscale Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

// Package mak helps make maps. It contains generic helpers to make/assign
// things, notably to maps, but also slices.
package mak

import (
	"fmt"
	"reflect"
)

// Set populates an entry in a map, making the map if necessary.
//
// That is, it assigns (*m)[k] = v, making *m if it was nil.
func Set[K comparable, V any, T ~map[K]V](m *T, k K, v V) {
	if *m == nil {
		*m = make(map[K]V)
	}
	(*m)[k] = v
}

// NonNil takes a pointer to a Go data structure
// (currently only a slice or a map) and makes sure it's non-nil for
// JSON serialization. (In particular, JavaScript clients usually want
// the field to be defined after they decode the JSON.)
//
// Deprecated: use NonNilSliceForJSON or NonNilMapForJSON instead.
func NonNil(ptr any) {
	if ptr == nil {
		panic("nil interface")
	}
	rv := reflect.ValueOf(ptr)
	if rv.Kind() != reflect.Ptr {
		panic(fmt.Sprintf("kind %v, not Ptr", rv.Kind()))
	}
	if rv.Pointer() == 0 {
		panic("nil pointer")
	}
	rv = rv.Elem()
	if rv.Pointer() != 0 {
		return
	}
	switch rv.Type().Kind() {
	case reflect.Slice:
		rv.Set(reflect.MakeSlice(rv.Type(), 0, 0))
	case reflect.Map:
		rv.Set(reflect.MakeMap(rv.Type()))
	}
}

// NonNilSliceForJSON makes sure that *slicePtr is non-nil so it will
// won't be omitted from JSON serialization and possibly confuse JavaScript
// clients expecting it to be present.
func NonNilSliceForJSON[T any, S ~[]T](slicePtr *S) {
	if *slicePtr != nil {
		return
	}
	*slicePtr = make([]T, 0)
}

// NonNilMapForJSON makes sure that *slicePtr is non-nil so it will
// won't be omitted from JSON serialization and possibly confuse JavaScript
// clients expecting it to be present.
func NonNilMapForJSON[K comparable, V any, M ~map[K]V](mapPtr *M) {
	if *mapPtr != nil {
		return
	}
	*mapPtr = make(M)
}
```

### Slice

slice

```go
// Copyright (c) Tailscale Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

package set

import (
	"golang.org/x/exp/slices"
	"tailscale.com/types/views"
)

// Slice is a set of elements tracked in a slice of unique elements.
type Slice[T comparable] struct {
	slice []T
	set   map[T]bool // nil until/unless slice is large enough
}

// Slice returns the a view of the underlying slice.
// The elements are in order of insertion.
// The returned value is only valid until ss is modified again.
func (ss *Slice[T]) Slice() views.Slice[T] { return views.SliceOf(ss.slice) }

// Contains reports whether v is in the set.
// The amortized cost is O(1).
func (ss *Slice[T]) Contains(v T) bool {
	if ss.set != nil {
		return ss.set[v]
	}
	return slices.Index(ss.slice, v) != -1
}

// Remove removes v from the set.
// The cost is O(n).
func (ss *Slice[T]) Remove(v T) {
	if ss.set != nil {
		if !ss.set[v] {
			return
		}
		delete(ss.set, v)
	}
	if ix := slices.Index(ss.slice, v); ix != -1 {
		ss.slice = append(ss.slice[:ix], ss.slice[ix+1:]...)
	}
}

// Add adds each element in vs to the set.
// The amortized cost is O(1) per element.
func (ss *Slice[T]) Add(vs ...T) {
	for _, v := range vs {
		if ss.Contains(v) {
			continue
		}
		ss.slice = append(ss.slice, v)
		if ss.set != nil {
			ss.set[v] = true
		} else if len(ss.slice) > 8 {
			ss.set = make(map[T]bool, len(ss.slice))
			for _, v := range ss.slice {
				ss.set[v] = true
			}
		}
	}
}

// AddSlice adds all elements in vs to the set.
func (ss *Slice[T]) AddSlice(vs views.Slice[T]) {
	for i := 0; i < vs.Len(); i++ {
		ss.Add(vs.At(i))
	}
}
```

sliceX

```go
// Copyright (c) Tailscale Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

// Package slicesx contains some helpful generic slice functions.
package slicesx

import "math/rand"

// Interleave combines two slices of the form [a, b, c] and [x, y, z] into a
// slice with elements interleaved; i.e. [a, x, b, y, c, z].
func Interleave[S ~[]T, T any](a, b S) S {
	// Avoid allocating an empty slice.
	if a == nil && b == nil {
		return nil
	}

	var (
		i   int
		ret = make([]T, 0, len(a)+len(b))
	)
	for i = 0; i < len(a) && i < len(b); i++ {
		ret = append(ret, a[i], b[i])
	}
	ret = append(ret, a[i:]...)
	ret = append(ret, b[i:]...)
	return ret
}

// Shuffle randomly shuffles a slice in-place, similar to rand.Shuffle.
func Shuffle[S ~[]T, T any](s S) {
	// TODO(andrew): use a pooled Rand?

	// This is the same Fisher-Yates shuffle implementation as rand.Shuffle
	n := len(s)
	i := n - 1
	for ; i > 1<<31-1-1; i-- {
		j := int(rand.Int63n(int64(i + 1)))
		s[i], s[j] = s[j], s[i]
	}
	for ; i > 0; i-- {
		j := int(rand.Int31n(int32(i + 1)))
		s[i], s[j] = s[j], s[i]
	}
}

// Partition returns two slices, the first containing the elements of the input
// slice for which the callback evaluates to true, the second containing the rest.
//
// This function does not mutate s.
func Partition[S ~[]T, T any](s S, cb func(T) bool) (trues, falses S) {
	for _, elem := range s {
		if cb(elem) {
			trues = append(trues, elem)
		} else {
			falses = append(falses, elem)
		}
	}
	return
}
```

## 日志

### Zap

#### 带日志等级输出

代码源 https://github.com/illacloud/builder-backend/tree/main/internal/util

```go
var logger *zap.SugaredLogger

type LogConfig struct {
	ILLA_LOG_LEVEL int `env:"ILLA_LOG_LEVEL" envDefault:"0"`
}

func init() {
	cfg := &LogConfig{}
	err := env.Parse(cfg)
	if err != nil {
		return
	}

	logConfig := zap.NewProductionConfig()
	logConfig.Level = zap.NewAtomicLevelAt(zapcore.Level(cfg.ILLA_LOG_LEVEL))
	baseLogger, err := logConfig.Build()
	if err != nil {
		panic("failed to create the default logger: " + err.Error())
	}
	logger = baseLogger.Sugar()
}

func NewSugardLogger() *zap.SugaredLogger {
	return logger
}
```

## 文件生成

### 国际化I18n

```go
package i18n

import (
	"context"
	"encoding/json"
	"io/ioutil"
	"net/http"
	"os"
	"strings"

	"github.com/BurntSushi/toml"
	"github.com/grpc-ecosystem/go-grpc-middleware/util/metautils"
	"github.com/nicksnyder/go-i18n/v2/i18n"
	"github.com/zitadel/logging"
	"golang.org/x/text/language"
	"sigs.k8s.io/yaml"

	"github.com/zitadel/zitadel/internal/api/authz"
	http_util "github.com/zitadel/zitadel/internal/api/http"
	"github.com/zitadel/zitadel/internal/errors"
)

const (
	i18nPath = "/i18n"
)

type Translator struct {
	bundle             *i18n.Bundle
	cookieName         string
	cookieHandler      *http_util.CookieHandler
	preferredLanguages []string
}

type TranslatorConfig struct {
	DefaultLanguage language.Tag
	CookieName      string
}

type Message struct {
	ID   string
	Text string
}

func NewTranslator(dir http.FileSystem, defaultLanguage language.Tag, cookieName string) (*Translator, error) {
	t := new(Translator)
	var err error
	t.bundle, err = newBundle(dir, defaultLanguage)
	if err != nil {
		return nil, err
	}
	t.cookieHandler = http_util.NewCookieHandler()
	t.cookieName = cookieName
	return t, nil
}

func newBundle(dir http.FileSystem, defaultLanguage language.Tag) (*i18n.Bundle, error) {
	bundle := i18n.NewBundle(defaultLanguage)
	bundle.RegisterUnmarshalFunc("yaml", func(data []byte, v interface{}) error { return yaml.Unmarshal(data, v) })
	bundle.RegisterUnmarshalFunc("json", json.Unmarshal)
	bundle.RegisterUnmarshalFunc("toml", toml.Unmarshal)
	i18nDir, err := dir.Open(i18nPath)
	if err != nil {
		return nil, errors.ThrowNotFound(err, "I18N-MnXRie", "path not found")
	}
	defer i18nDir.Close()
	files, err := i18nDir.Readdir(0)
	if err != nil {
		return nil, errors.ThrowNotFound(err, "I18N-Gew23", "cannot read dir")
	}
	for _, file := range files {
		if err := addFileFromFileSystemToBundle(dir, bundle, file); err != nil {
			return nil, errors.ThrowNotFoundf(err, "I18N-ZS2AW", "cannot append file %s to Bundle", file.Name())
		}
	}
	return bundle, nil
}

func addFileFromFileSystemToBundle(dir http.FileSystem, bundle *i18n.Bundle, file os.FileInfo) error {
	f, err := dir.Open("/i18n/" + file.Name())
	if err != nil {
		return err
	}
	defer f.Close()
	content, err := ioutil.ReadAll(f)
	if err != nil {
		return err
	}
	_, err = bundle.ParseMessageFileBytes(content, file.Name())
	return err
}

func SupportedLanguages(dir http.FileSystem) ([]language.Tag, error) {
	i18nDir, err := dir.Open("/i18n")
	if err != nil {
		return nil, errors.ThrowNotFound(err, "I18N-Dbt42", "cannot open dir")
	}
	defer i18nDir.Close()
	files, err := i18nDir.Readdir(0)
	if err != nil {
		return nil, errors.ThrowNotFound(err, "I18N-Gh4zk", "cannot read dir")
	}
	languages := make([]language.Tag, 0, len(files))
	for _, file := range files {
		lang := language.Make(strings.TrimSuffix(file.Name(), ".yaml"))
		if lang != language.Und {
			languages = append(languages, lang)
		}
	}
	return languages, nil
}

func (t *Translator) SupportedLanguages() []language.Tag {
	return t.bundle.LanguageTags()
}

func (t *Translator) AddMessages(tag language.Tag, messages ...Message) error {
	if len(messages) == 0 {
		return nil
	}
	i18nMessages := make([]*i18n.Message, len(messages))
	for i, message := range messages {
		i18nMessages[i] = &i18n.Message{
			ID:    message.ID,
			Other: message.Text,
		}
	}
	return t.bundle.AddMessages(tag, i18nMessages...)
}

func (t *Translator) LocalizeFromRequest(r *http.Request, id string, args map[string]interface{}) string {
	return localize(t.localizerFromRequest(r), id, args)
}

func (t *Translator) LocalizeFromCtx(ctx context.Context, id string, args map[string]interface{}) string {
	return localize(t.localizerFromCtx(ctx), id, args)
}

func (t *Translator) Localize(id string, args map[string]interface{}, langs ...string) string {
	return localize(t.localizer(langs...), id, args)
}

func (t *Translator) LocalizeWithoutArgs(id string, langs ...string) string {
	return localize(t.localizer(langs...), id, map[string]interface{}{})
}

func (t *Translator) Lang(r *http.Request) language.Tag {
	matcher := language.NewMatcher(t.bundle.LanguageTags())
	tag, _ := language.MatchStrings(matcher, t.langsFromRequest(r)...)
	return tag
}

func (t *Translator) SetLangCookie(w http.ResponseWriter, r *http.Request, lang language.Tag) {
	t.cookieHandler.SetCookie(w, t.cookieName, r.Host, lang.String())
}

func (t *Translator) localizerFromRequest(r *http.Request) *i18n.Localizer {
	return t.localizer(t.langsFromRequest(r)...)
}

func (t *Translator) localizerFromCtx(ctx context.Context) *i18n.Localizer {
	return t.localizer(t.langsFromCtx(ctx)...)
}

func (t *Translator) localizer(langs ...string) *i18n.Localizer {
	return i18n.NewLocalizer(t.bundle, langs...)
}

func (t *Translator) langsFromRequest(r *http.Request) []string {
	langs := t.preferredLanguages
	if r != nil {
		lang, err := t.cookieHandler.GetCookieValue(r, t.cookieName)
		if err == nil {
			langs = append(langs, lang)
		}
		langs = append(langs, r.Header.Get("Accept-Language"))
	}
	return langs
}

func (t *Translator) langsFromCtx(ctx context.Context) []string {
	langs := t.preferredLanguages
	if ctx != nil {
		ctxData := authz.GetCtxData(ctx)
		if ctxData.PreferredLanguage != language.Und.String() {
			langs = append(langs, authz.GetCtxData(ctx).PreferredLanguage)
		}
		langs = append(langs, getAcceptLanguageHeader(ctx))
	}
	return langs
}

func (t *Translator) SetPreferredLanguages(langs ...string) {
	t.preferredLanguages = langs
}

func getAcceptLanguageHeader(ctx context.Context) string {
	acceptLanguage := metautils.ExtractIncoming(ctx).Get("accept-language")
	if acceptLanguage != "" {
		return acceptLanguage
	}
	return metautils.ExtractIncoming(ctx).Get("grpcgateway-accept-language")
}

func localize(localizer *i18n.Localizer, id string, args map[string]interface{}) string {
	s, err := localizer.Localize(&i18n.LocalizeConfig{
		MessageID:    id,
		TemplateData: args,
	})
	if err != nil {
		logging.WithFields("id", id, "args", args).WithError(err).Warnf("missing translation")
		return id
	}
	return s
}

```



### SVG格式的二维码

```go
package qrcode

import (
	"errors"
	"image/color"

	"github.com/ajstarks/svgo"
	"github.com/boombuler/barcode"
)

// QrSVG holds the data related to the size, location,
// and block size of the QR Code. Holds unexported fields.
type QrSVG struct {
	qr        barcode.Barcode
	qrWidth   int
	blockSize int
	startingX int
	startingY int
}

// NewQrSVG contructs a QrSVG struct. It takes a QR Code in the form
// of barcode.Barcode and sets the "pixel" or block size of QR Code in
// the SVG file.
func NewQrSVG(qr barcode.Barcode, blockSize int) QrSVG {
	return QrSVG{
		qr:        qr,
		qrWidth:   qr.Bounds().Max.X,
		blockSize: blockSize,
		startingX: 0,
		startingY: 0,
	}
}

// WriteQrSVG writes the QR Code to SVG.
func (qs *QrSVG) WriteQrSVG(s *svg.SVG) error {
	if qs.qr.Metadata().CodeKind == "QR Code" {
		currY := qs.startingY

		for x := 0; x < qs.qrWidth; x++ {
			currX := qs.startingX
			for y := 0; y < qs.qrWidth; y++ {
				if qs.qr.At(x, y) == color.Black {
					s.Rect(currX, currY, qs.blockSize, qs.blockSize, "class=\"color\"")
				} else if qs.qr.At(x, y) == color.White {
					s.Rect(currX, currY, qs.blockSize, qs.blockSize, "class=\"bg-color\"")
				}
				currX += qs.blockSize
			}
			currY += qs.blockSize
		}
		return nil
	}
	return errors.New("can not write to SVG: Not a QR code")
}

// SetStartPoint sets the top left start point of QR Code.
// This takes an X and Y value and then adds four white "blocks"
// to create the "quiet zone" around the QR Code.
func (qs *QrSVG) SetStartPoint(x, y int) {
	qs.startingX = x + (qs.blockSize * 4)
	qs.startingY = y + (qs.blockSize * 4)
}

// StartQrSVG creates a start for writing an SVG file that
// only contains a barcode. This is similar to the svg.Start() method.
// This fucntion should only be used if you only want to write a QR code
// to the SVG. Otherwise use the regular svg.Start() method to start your
// SVG file.
func (qs *QrSVG) StartQrSVG(s *svg.SVG) {
	width := (qs.qrWidth * qs.blockSize) + (qs.blockSize * 8)
	qs.SetStartPoint(0, 0)
	s.Start(width, width)
}

```

## 操作系统

### FIFO

代码来自于HashCorp的nomad项目

包说明

> *Package fifo implements functions to create and open a fifo for inter-process*
>
> *communication in an OS agnostic way. A few assumptions should be made when*
>
> *using this package. First, New() must always be called before Open(). Second*
>
> *Open() returns an io.ReadWriteCloser that is only connected with the*
>
> *io.ReadWriteCloser returned from New().*
> 

fifo_windows.go
```go
// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MPL-2.0

package fifo

import (
	"fmt"
	"io"
	"net"
	"os"
	"sync"
	"time"

	winio "github.com/Microsoft/go-winio"
)

// PipeBufferSize is the size of the input and output buffers for the windows
// named pipe
const PipeBufferSize = int32(^uint16(0))

type winFIFO struct {
	listener net.Listener
	conn     net.Conn
	connLock sync.Mutex
}

func (f *winFIFO) ensureConn() (net.Conn, error) {
	f.connLock.Lock()
	defer f.connLock.Unlock()
	if f.conn == nil {
		c, err := f.listener.Accept()
		if err != nil {
			return nil, err
		}
		f.conn = c
	}

	return f.conn, nil
}

func (f *winFIFO) Read(p []byte) (n int, err error) {
	conn, err := f.ensureConn()
	if err != nil {
		return 0, err
	}

	// If the connection is closed then we need to close the listener
	// to emulate unix fifo behavior
	n, err = conn.Read(p)
	if err == io.EOF {
		f.listener.Close()
	}
	return n, err
}

func (f *winFIFO) Write(p []byte) (n int, err error) {
	conn, err := f.ensureConn()
	if err != nil {
		return 0, err
	}

	// If the connection is closed then we need to close the listener
	// to emulate unix fifo behavior
	n, err = conn.Write(p)
	if err == io.EOF {
		conn.Close()
		f.listener.Close()
	}
	return n, err

}

func (f *winFIFO) Close() error {
	f.connLock.Lock()
	if f.conn != nil {
		f.conn.Close()
	}
	f.connLock.Unlock()
	return f.listener.Close()
}

// CreateAndRead creates a fifo at the given path and returns an io.ReadCloser open for it.
// The fifo must not already exist
func CreateAndRead(path string) (func() (io.ReadCloser, error), error) {
	l, err := winio.ListenPipe(path, &winio.PipeConfig{
		InputBufferSize:  PipeBufferSize,
		OutputBufferSize: PipeBufferSize,
	})
	if err != nil {
		return nil, fmt.Errorf("failed to create fifo: %v", err)
	}

	return func() (io.ReadCloser, error) {
		return &winFIFO{
			listener: l,
		}, nil
	}, nil
}

func OpenReader(path string) (io.ReadCloser, error) {
	l, err := winio.ListenOnlyPipe(path, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to open fifo listener: %v", err)
	}

	return &winFIFO{listener: l}, nil
}

// OpenWriter opens a fifo that already exists and returns an io.WriteCloser for it
func OpenWriter(path string) (io.WriteCloser, error) {
	return winio.DialPipe(path, nil)
}

// Remove a fifo that already exists at a given path
func Remove(path string) error {
	dur := 500 * time.Millisecond
	conn, err := winio.DialPipe(path, &dur)
	if err == nil {
		return conn.Close()
	}

	os.Remove(path)
	return nil
}

func IsClosedErr(err error) bool {
	return err == winio.ErrFileClosed
}

```
fifo_unix.go
```go
// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MPL-2.0

//go:build !windows
// +build !windows

package fifo

import (
	"fmt"
	"io"
	"os"

	"golang.org/x/sys/unix"
)

// CreateAndRead creates a fifo at the given path, and returns an open function for reading.
// For compatibility with windows, the fifo must not exist already.
//
// It returns a reader open function that may block until a writer opens
// so it's advised to run it in a goroutine different from reader goroutine
func CreateAndRead(path string) (func() (io.ReadCloser, error), error) {
	// create first
	if err := mkfifo(path, 0600); err != nil {
		return nil, fmt.Errorf("error creating fifo %v: %v", path, err)
	}

	return func() (io.ReadCloser, error) {
		return OpenReader(path)
	}, nil
}

func OpenReader(path string) (io.ReadCloser, error) {
	return os.OpenFile(path, unix.O_RDONLY, os.ModeNamedPipe)
}

// OpenWriter opens a fifo file for writer, assuming it already exists, returns io.WriteCloser
func OpenWriter(path string) (io.WriteCloser, error) {
	return os.OpenFile(path, unix.O_WRONLY, os.ModeNamedPipe)
}

// Remove a fifo that already exists at a given path
func Remove(path string) error {
	return os.Remove(path)
}

func IsClosedErr(err error) bool {
	err2, ok := err.(*os.PathError)
	if ok {
		return err2.Err == os.ErrClosed
	}
	return false
}

func mkfifo(path string, mode uint32) (err error) {
	return unix.Mkfifo(path, mode)
}

```
fifo_test.go
```go
// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MPL-2.0

package fifo

import (
	"bytes"
	"io"
	"path/filepath"
	"runtime"
	"sync"
	"testing"
	"time"

	"github.com/hashicorp/nomad/helper/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestFIFO tests basic behavior, and that reader closes when writer closes
func TestFIFO(t *testing.T) {
	require := require.New(t)
	var path string

	if runtime.GOOS == "windows" {
		path = "//./pipe/fifo"
	} else {
		path = filepath.Join(t.TempDir(), "fifo")
	}

	readerOpenFn, err := CreateAndRead(path)
	require.NoError(err)

	var reader io.ReadCloser

	toWrite := [][]byte{
		[]byte("abc\n"),
		[]byte(""),
		[]byte("def\n"),
		[]byte("nomad"),
		[]byte("\n"),
	}

	var readBuf bytes.Buffer
	var wait sync.WaitGroup
	wait.Add(1)
	go func() {
		defer wait.Done()

		var err error
		reader, err = readerOpenFn()
		assert.NoError(t, err)
		if err != nil {
			return
		}

		_, err = io.Copy(&readBuf, reader)
		assert.NoError(t, err)
	}()

	writer, err := OpenWriter(path)
	require.NoError(err)
	for _, b := range toWrite {
		n, err := writer.Write(b)
		require.NoError(err)
		require.Equal(n, len(b))
	}
	require.NoError(writer.Close())
	time.Sleep(500 * time.Millisecond)

	wait.Wait()
	require.NoError(reader.Close())

	expected := "abc\ndef\nnomad\n"
	require.Equal(expected, readBuf.String())

	require.NoError(Remove(path))
}

// TestWriteClose asserts that when writer closes, subsequent Write() fails
func TestWriteClose(t *testing.T) {
	require := require.New(t)
	var path string

	if runtime.GOOS == "windows" {
		path = "//./pipe/" + uuid.Generate()[:4]
	} else {
		path = filepath.Join(t.TempDir(), "fifo")
	}

	readerOpenFn, err := CreateAndRead(path)
	require.NoError(err)
	var reader io.ReadCloser

	var readBuf bytes.Buffer
	var wait sync.WaitGroup
	wait.Add(1)
	go func() {
		defer wait.Done()

		var err error
		reader, err = readerOpenFn()
		assert.NoError(t, err)
		if err != nil {
			return
		}

		_, err = io.Copy(&readBuf, reader)
		assert.NoError(t, err)
	}()

	writer, err := OpenWriter(path)
	require.NoError(err)

	var count int
	wait.Add(1)
	go func() {
		defer wait.Done()
		for count = 0; count < int(^uint16(0)); count++ {
			_, err := writer.Write([]byte(","))
			if err != nil && IsClosedErr(err) {
				break
			}
			require.NoError(err)
			time.Sleep(5 * time.Millisecond)
		}
	}()

	time.Sleep(500 * time.Millisecond)
	require.NoError(writer.Close())
	wait.Wait()

	require.Equal(count, len(readBuf.String()))
}

```
### rwcancel
来源 [wiregurd-go](https://git.zx2c4.com/wireguard-go/tree/)
```go
//go:build !windows && !wasm

/* SPDX-License-Identifier: MIT
 *
 * Copyright (C) 2017-2023 WireGuard LLC. All Rights Reserved.
 */

// Package rwcancel implements cancelable read/write operations on
// a file descriptor.
package rwcancel

import (
	"errors"
	"os"
	"syscall"

	"golang.org/x/sys/unix"
)

type RWCancel struct {
	fd            int
	closingReader *os.File
	closingWriter *os.File
}

func NewRWCancel(fd int) (*RWCancel, error) {
	err := unix.SetNonblock(fd, true)
	if err != nil {
		return nil, err
	}
	rwcancel := RWCancel{fd: fd}

	rwcancel.closingReader, rwcancel.closingWriter, err = os.Pipe()
	if err != nil {
		return nil, err
	}

	return &rwcancel, nil
}

func RetryAfterError(err error) bool {
	return errors.Is(err, syscall.EAGAIN) || errors.Is(err, syscall.EINTR)
}

func (rw *RWCancel) ReadyRead() bool {
	closeFd := int32(rw.closingReader.Fd())

	pollFds := []unix.PollFd{{Fd: int32(rw.fd), Events: unix.POLLIN}, {Fd: closeFd, Events: unix.POLLIN}}
	var err error
	for {
		_, err = unix.Poll(pollFds, -1)
		if err == nil || !RetryAfterError(err) {
			break
		}
	}
	if err != nil {
		return false
	}
	if pollFds[1].Revents != 0 {
		return false
	}
	return pollFds[0].Revents != 0
}

func (rw *RWCancel) ReadyWrite() bool {
	closeFd := int32(rw.closingReader.Fd())
	pollFds := []unix.PollFd{{Fd: int32(rw.fd), Events: unix.POLLOUT}, {Fd: closeFd, Events: unix.POLLOUT}}
	var err error
	for {
		_, err = unix.Poll(pollFds, -1)
		if err == nil || !RetryAfterError(err) {
			break
		}
	}
	if err != nil {
		return false
	}

	if pollFds[1].Revents != 0 {
		return false
	}
	return pollFds[0].Revents != 0
}

func (rw *RWCancel) Read(p []byte) (n int, err error) {
	for {
		n, err := unix.Read(rw.fd, p)
		if err == nil || !RetryAfterError(err) {
			return n, err
		}
		if !rw.ReadyRead() {
			return 0, os.ErrClosed
		}
	}
}

func (rw *RWCancel) Write(p []byte) (n int, err error) {
	for {
		n, err := unix.Write(rw.fd, p)
		if err == nil || !RetryAfterError(err) {
			return n, err
		}
		if !rw.ReadyWrite() {
			return 0, os.ErrClosed
		}
	}
}

func (rw *RWCancel) Cancel() (err error) {
	_, err = rw.closingWriter.Write([]byte{0})
	return
}

func (rw *RWCancel) Close() {
	rw.closingReader.Close()
	rw.closingWriter.Close()
}
```

### 获取系统可用端口

来源 [temporal](https://github.com/temporalio/temporal/-/blob/internal/temporalite/freeport.go)

```go
package temporalite

import (
	"fmt"
	"net"
)

func newPortProvider() *portProvider {
	return &portProvider{}
}

type portProvider struct {
	listeners []*net.TCPListener
}

// GetFreePort finds an open port on the system which is ready to use.
func (p *portProvider) GetFreePort() (int, error) {
	addr, err := net.ResolveTCPAddr("tcp", "127.0.0.1:0")
	if err != nil {
		if addr, err = net.ResolveTCPAddr("tcp6", "[::1]:0"); err != nil {
			return 0, fmt.Errorf("failed to get free port: %w", err)
		}
	}

	l, err := net.ListenTCP("tcp", addr)
	if err != nil {
		return 0, err
	}

	p.listeners = append(p.listeners, l)

	return l.Addr().(*net.TCPAddr).Port, nil
}

// MustGetFreePort calls GetFreePort, panicking on error.
func (p *portProvider) MustGetFreePort() int {
	port, err := p.GetFreePort()
	if err != nil {
		panic(err)
	}
	return port
}

func (p *portProvider) Close() error {
	for _, l := range p.listeners {
		if err := l.Close(); err != nil {
			return err
		}
	}
	return nil
}
```

### 检测PID的所属用户

来源 tailscale [源码路径](https://github.com/tailscale/tailscale/blob/main/util/pidowner/pidowner.go)

```go
// Copyright (c) Tailscale Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

// Package pidowner handles lookups from process ID to its owning user.
package pidowner

import (
	"errors"
	"runtime"
)

var ErrNotImplemented = errors.New("not implemented for GOOS=" + runtime.GOOS)

var ErrProcessNotFound = errors.New("process not found")

// OwnerOfPID returns the user ID that owns the given process ID.
//
// The returned user ID is suitable to passing to os/user.LookupId.
//
// The returned error will be ErrNotImplemented for operating systems where
// this isn't supported.
func OwnerOfPID(pid int) (userID string, err error) {
	return ownerOfPID(pid)
}
```

linux实现 pidowner_linux.go

```go
// Copyright (c) Tailscale Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

package pidowner

import (
	"fmt"
	"os"
	"strings"

	"tailscale.com/util/lineread"
)

func ownerOfPID(pid int) (userID string, err error) {
	file := fmt.Sprintf("/proc/%d/status", pid)
	err = lineread.File(file, func(line []byte) error {
		if len(line) < 4 || string(line[:4]) != "Uid:" {
			return nil
		}
		f := strings.Fields(string(line))
		if len(f) >= 2 {
			userID = f[1] // real userid
		}
		return nil
	})
	if os.IsNotExist(err) {
		return "", ErrProcessNotFound
	}
	if err != nil {
		return
	}
	if userID == "" {
		return "", fmt.Errorf("missing Uid line in %s", file)
	}
	return userID, nil
}
```



windows实现 pidowner_windows.go

```go
// Copyright (c) Tailscale Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

package pidowner

import (
	"fmt"
	"syscall"

	"golang.org/x/sys/windows"
)

func ownerOfPID(pid int) (userID string, err error) {
	procHnd, err := windows.OpenProcess(windows.PROCESS_QUERY_INFORMATION, false, uint32(pid))
	if err == syscall.Errno(0x57) { // invalid parameter, for PIDs that don't exist
		return "", ErrProcessNotFound
	}
	if err != nil {
		return "", fmt.Errorf("OpenProcess: %T %#v", err, err)
	}
	defer windows.CloseHandle(procHnd)

	var tok windows.Token
	if err := windows.OpenProcessToken(procHnd, windows.TOKEN_QUERY, &tok); err != nil {
		return "", fmt.Errorf("OpenProcessToken: %w", err)
	}

	tokUser, err := tok.GetTokenUser()
	if err != nil {
		return "", fmt.Errorf("GetTokenUser: %w", err)
	}

	sid := tokUser.User.Sid
	return sid.String(), nil
}
```

### 检查指定PID是否alive

linux

来源  [hashcorp/go-plugin](https://github.com/hashicorp/go-plugin/blob/main/internal/cmdrunner/process_posix.go#L16)

这段代码利用了`kill -0`信号，具体可以参考[这篇文章](https://www.linuxjournal.com/content/monitoring-processes-kill-0)

```go
// _pidAlive tests whether a process is alive or not by sending it Signal 0,
// since Go otherwise has no way to test this.
func _pidAlive(pid int) bool {
	proc, err := os.FindProcess(pid)
	if err == nil {
		err = proc.Signal(syscall.Signal(0))
	}

	return err == nil
}
```

windows [来源](https://github.com/hashicorp/go-plugin/blob/main/internal/cmdrunner/process_windows.go)

```go
const (
	// Weird name but matches the MSDN docs
	exit_STILL_ACTIVE = 259

	processDesiredAccess = syscall.STANDARD_RIGHTS_READ |
		syscall.PROCESS_QUERY_INFORMATION |
		syscall.SYNCHRONIZE
)

// _pidAlive tests whether a process is alive or not
func _pidAlive(pid int) bool {
	h, err := syscall.OpenProcess(processDesiredAccess, false, uint32(pid))
	if err != nil {
		return false
	}
	defer syscall.CloseHandle(h)

	var ec uint32
	if e := syscall.GetExitCodeProcess(h, &ec); e != nil {
		return false
	}

	return ec == exit_STILL_ACTIVE
}
```



### 服务端即时压缩

>// Package precompress provides build- and serving-time support for
>// precompressed static resources, to avoid the cost of repeatedly compressing
>// unchanging resources.

来源  tailscale [源码路径](https://github.com/tailscale/tailscale/blob/main/util/precompress/precompress.go)

```go
// Copyright (c) Tailscale Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

// Package precompress provides build- and serving-time support for
// precompressed static resources, to avoid the cost of repeatedly compressing
// unchanging resources.
package precompress

import (
	"bytes"
	"compress/gzip"
	"io"
	"io/fs"
	"net/http"
	"os"
	"path"
	"path/filepath"

	"github.com/andybalholm/brotli"
	"golang.org/x/sync/errgroup"
	"tailscale.com/tsweb"
)

// PrecompressDir compresses static assets in dirPath using Gzip and Brotli, so
// that they can be later served with OpenPrecompressedFile.
func PrecompressDir(dirPath string, options Options) error {
	var eg errgroup.Group
	err := fs.WalkDir(os.DirFS(dirPath), ".", func(p string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if d.IsDir() {
			return nil
		}
		if !compressibleExtensions[filepath.Ext(p)] {
			return nil
		}
		p = path.Join(dirPath, p)
		if options.ProgressFn != nil {
			options.ProgressFn(p)
		}

		eg.Go(func() error {
			return Precompress(p, options)
		})
		return nil
	})
	if err != nil {
		return err
	}
	return eg.Wait()
}

type Options struct {
	// FastCompression controls whether compression should be optimized for
	// speed rather than size.
	FastCompression bool
	// ProgressFn, if non-nil, is invoked when a file in the directory is about
	// to be compressed.
	ProgressFn func(path string)
}

// OpenPrecompressedFile opens a file from fs, preferring compressed versions
// generated by PrecompressDir if possible.
func OpenPrecompressedFile(w http.ResponseWriter, r *http.Request, path string, fs fs.FS) (fs.File, error) {
	if tsweb.AcceptsEncoding(r, "br") {
		if f, err := fs.Open(path + ".br"); err == nil {
			w.Header().Set("Content-Encoding", "br")
			return f, nil
		}
	}
	if tsweb.AcceptsEncoding(r, "gzip") {
		if f, err := fs.Open(path + ".gz"); err == nil {
			w.Header().Set("Content-Encoding", "gzip")
			return f, nil
		}
	}

	return fs.Open(path)
}

var compressibleExtensions = map[string]bool{
	".js":  true,
	".css": true,
}

func Precompress(path string, options Options) error {
	contents, err := os.ReadFile(path)
	if err != nil {
		return err
	}
	fi, err := os.Lstat(path)
	if err != nil {
		return err
	}

	gzipLevel := gzip.BestCompression
	if options.FastCompression {
		gzipLevel = gzip.BestSpeed
	}
	err = writeCompressed(contents, func(w io.Writer) (io.WriteCloser, error) {
		return gzip.NewWriterLevel(w, gzipLevel)
	}, path+".gz", fi.Mode())
	if err != nil {
		return err
	}
	brotliLevel := brotli.BestCompression
	if options.FastCompression {
		brotliLevel = brotli.BestSpeed
	}
	return writeCompressed(contents, func(w io.Writer) (io.WriteCloser, error) {
		return brotli.NewWriterLevel(w, brotliLevel), nil
	}, path+".br", fi.Mode())
}

func writeCompressed(contents []byte, compressedWriterCreator func(io.Writer) (io.WriteCloser, error), outputPath string, outputMode fs.FileMode) error {
	var buf bytes.Buffer
	compressedWriter, err := compressedWriterCreator(&buf)
	if err != nil {
		return err
	}
	if _, err := compressedWriter.Write(contents); err != nil {
		return err
	}
	if err := compressedWriter.Close(); err != nil {
		return err
	}
	return os.WriteFile(outputPath, buf.Bytes(), outputMode)
}
```

### 获取当前系统运行的发行版本

来源  [tailscale](https://github.com/tailscale/tailscale/blob/main/version/distro/distro.go)

```go
// Copyright (c) Tailscale Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

// Package distro reports which distro we're running on.
package distro

import (
	"bytes"
	"io"
	"os"
	"runtime"
	"strconv"

	"tailscale.com/types/lazy"
	"tailscale.com/util/lineread"
)

type Distro string

const (
	Debian    = Distro("debian")
	Arch      = Distro("arch")
	Synology  = Distro("synology")
	OpenWrt   = Distro("openwrt")
	NixOS     = Distro("nixos")
	QNAP      = Distro("qnap")
	Pfsense   = Distro("pfsense")
	OPNsense  = Distro("opnsense")
	TrueNAS   = Distro("truenas")
	Gokrazy   = Distro("gokrazy")
	WDMyCloud = Distro("wdmycloud")
	Unraid    = Distro("unraid")
	Alpine    = Distro("alpine")
)

var distro lazy.SyncValue[Distro]
var isWSL lazy.SyncValue[bool]

// Get returns the current distro, or the empty string if unknown.
func Get() Distro {
	return distro.Get(func() Distro {
		switch runtime.GOOS {
		case "linux":
			return linuxDistro()
		case "freebsd":
			return freebsdDistro()
		default:
			return Distro("")
		}
	})
}

// IsWSL reports whether we're running in the Windows Subsystem for Linux.
func IsWSL() bool {
	return runtime.GOOS == "linux" && isWSL.Get(func() bool {
		// We could look for $WSL_INTEROP instead, however that may be missing if
		// the user has started to use systemd in WSL2.
		return have("/proc/sys/fs/binfmt_misc/WSLInterop") || have("/mnt/wsl")
	})
}

func have(file string) bool {
	_, err := os.Stat(file)
	return err == nil
}

func haveDir(file string) bool {
	fi, err := os.Stat(file)
	return err == nil && fi.IsDir()
}

func linuxDistro() Distro {
	switch {
	case haveDir("/usr/syno"):
		return Synology
	case have("/usr/local/bin/freenas-debug"):
		// TrueNAS Scale runs on debian
		return TrueNAS
	case have("/etc/debian_version"):
		return Debian
	case have("/etc/arch-release"):
		return Arch
	case have("/etc/openwrt_version"):
		return OpenWrt
	case have("/run/current-system/sw/bin/nixos-version"):
		return NixOS
	case have("/etc/config/uLinux.conf"):
		return QNAP
	case haveDir("/gokrazy"):
		return Gokrazy
	case have("/usr/local/wdmcserver/bin/wdmc.xml"): // Western Digital MyCloud OS3
		return WDMyCloud
	case have("/usr/sbin/wd_crontab.sh"): // Western Digital MyCloud OS5
		return WDMyCloud
	case have("/etc/unraid-version"):
		return Unraid
	case have("/etc/alpine-release"):
		return Alpine
	}
	return ""
}

func freebsdDistro() Distro {
	switch {
	case have("/etc/pfSense-rc"):
		return Pfsense
	case have("/usr/local/sbin/opnsense-shell"):
		return OPNsense
	case have("/usr/local/bin/freenas-debug"):
		// TrueNAS Core runs on FreeBSD
		return TrueNAS
	}
	return ""
}

var dsmVersion lazy.SyncValue[int]

// DSMVersion reports the Synology DSM major version.
//
// If not Synology, it reports 0.
func DSMVersion() int {
	if runtime.GOOS != "linux" {
		return 0
	}
	return dsmVersion.Get(func() int {
		if Get() != Synology {
			return 0
		}
		// This is set when running as a package:
		v, _ := strconv.Atoi(os.Getenv("SYNOPKG_DSM_VERSION_MAJOR"))
		if v != 0 {
			return v
		}
		// But when run from the command line, we have to read it from the file:
		lineread.File("/etc/VERSION", func(line []byte) error {
			line = bytes.TrimSpace(line)
			if string(line) == `majorversion="7"` {
				v = 7
				return io.EOF
			}
			if string(line) == `majorversion="6"` {
				v = 6
				return io.EOF
			}
			return nil
		})
		return v
	})
}
```



## 账户

### 检测当前账号是否是root
代码来自于HashCorp的nomad项目
```go
// SkipTestWithoutRootAccess will skip test t if it's not running in CI environment
// and test is not running with Root access.
func SkipTestWithoutRootAccess(t *testing.T) {
	ciVar := os.Getenv("CI")
	isCI, err := strconv.ParseBool(ciVar)
	isCI = isCI && err == nil

	if !isCI && syscall.Getuid() != 0 {
		t.Skipf("Skipping test %s. To run this test, you should run it as root user", t.Name())
	}
}
```

### 邮箱验证码

代码来自于[illacloud](https://github.com/illacloud),[代码位置链接](https://github.com/illacloud/builder-backend/blob/main/pkg/smtp/service.go)

发送

```go
func (s *SMTPServer) NewVerificationCode(email, usage string) (string, error) {
	rnd := rand.New(rand.NewSource(time.Now().UnixNano()))
	vCode := fmt.Sprintf("%06v", rnd.Int31n(1000000))
	if err := email_cloud.SendVerificationEmail(email, vCode, usage); err != nil {
		return "", err
	}
	claims := &VCodeClaims{
		Email: email,
		Code:  vCode,
		Usage: usage,
		RegisteredClaims: jwt.RegisteredClaims{
			Issuer: "ILLA",
			ExpiresAt: &jwt.NumericDate{
				Time: time.Now().Add(time.Minute * 15),
			},
		},
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	codeToken, err := token.SignedString([]byte(s.Secret))
	if err != nil {
		return "", err
	}

	return codeToken, nil
}
```

验证

```go

func (s *SMTPServer) ValidateVerificationCode(codeToken, vCode, email, usage string) (bool, error) {
	vCodeClaims := &VCodeClaims{}
	token, err := jwt.ParseWithClaims(codeToken, vCodeClaims, func(token *jwt.Token) (interface{}, error) {
		return []byte(s.Secret), nil
	})
	if err != nil {
		return false, err
	}

	claims, ok := token.Claims.(*VCodeClaims)
	if !(ok && claims.Usage == usage) {
		return false, errors.New("invalid verification token")
	}
	if !(claims.Code == vCode && claims.Email == email) {
		return false, errors.New("verification code wrong")
	}
	return true, nil
}
```

## 数据库

## MongoDB

代码来自于[illacloud](https://github.com/illacloud)

连接时使用SSL选项

```go
// TLS: self-signed certificate
	var credential options.Credential
	var tlsConfig tls.Config
    // config checks
	if m.Resource.SSL.Open == true && m.Resource.SSL.CA != "" {
		credential = options.Credential{AuthMechanism: "MONGODB-X509"}
		pool := x509.NewCertPool()
		if ok := pool.AppendCertsFromPEM([]byte(m.Resource.SSL.CA)); !ok {
			return nil, errors.New("format MongoDB TLS CA Cert failed")
		}
		tlsConfig = tls.Config{RootCAs: pool}
		if m.Resource.SSL.Client != "" {
			splitIndex := bytes.Index([]byte(m.Resource.SSL.Client), []byte("-----\n-----"))
			if splitIndex <= 0 {
				return nil, errors.New("format MongoDB TLS Client Key Pair failed")
			}
			clientKeyPairSlice := []string{m.Resource.SSL.Client[:splitIndex+6], m.Resource.SSL.Client[splitIndex+6:]}
			clientCert := ""
			clientKey := ""
			if strings.Contains(clientKeyPairSlice[0], "CERTIFICATE") {
				clientCert = clientKeyPairSlice[0]
				clientKey = clientKeyPairSlice[1]
			} else {
				clientCert = clientKeyPairSlice[1]
				clientKey = clientKeyPairSlice[0]
			}
			ccBlock, _ := pem.Decode([]byte(clientCert))
			ckBlock, _ := pem.Decode([]byte(clientKey))
			if (ccBlock != nil && ccBlock.Type == "CERTIFICATE") && (ckBlock != nil || strings.Contains(ckBlock.Type, "PRIVATE KEY")) {
				cert, err := tls.X509KeyPair([]byte(clientCert), []byte(clientKey))
				if err != nil {
					return nil, err
				}
				tlsConfig.Certificates = []tls.Certificate{cert}
			}
		}
```

其他类型的数据库均有实现。

## 调试代码
### 获取panic时的调用堆栈
```go
if p := recover(); p != nil {
    buf := make([]byte, 64<<10)
    buf = buf[:runtime.Stack(buf, false)]
    log.Printf("panic captured: %v\r\n,stack:%s",
               p,
               string(buf))
    ....
}
```
可以参考七牛的代码 https://github.com/qiniu/x/blob/main/ts/callstack.go

## 时间

### Tai64n

来源 [wiregurd-go](https://git.zx2c4.com/wireguard-go/tree/)

```go
* SPDX-License-Identifier: MIT
 *
 * Copyright (C) 2017-2023 WireGuard LLC. All Rights Reserved.
 */

package tai64n

import (
	"bytes"
	"encoding/binary"
	"time"
)

const (
	TimestampSize = 12
	base          = uint64(0x400000000000000a)
	whitenerMask  = uint32(0x1000000 - 1)
)

type Timestamp [TimestampSize]byte

func stamp(t time.Time) Timestamp {
	var tai64n Timestamp
	secs := base + uint64(t.Unix())
	nano := uint32(t.Nanosecond()) &^ whitenerMask
	binary.BigEndian.PutUint64(tai64n[:], secs)
	binary.BigEndian.PutUint32(tai64n[8:], nano)
	return tai64n
}

func Now() Timestamp {
	return stamp(time.Now())
}

func (t1 Timestamp) After(t2 Timestamp) bool {
	return bytes.Compare(t1[:], t2[:]) > 0
}

func (t Timestamp) String() string {
	return time.Unix(int64(binary.BigEndian.Uint64(t[:8])-base), int64(binary.BigEndian.Uint32(t[8:12]))).String()
}
```



## 有用的链接

+ https://github.com/TheAlgorithms/Go
