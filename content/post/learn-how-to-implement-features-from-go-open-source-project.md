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

## 数学算法

### 快速反平方根

#### 32位算法

```go
import "math"
const magic32 = 0x5F375A86
func FastInvSqrt32(n float32) float32 {
    // If n is negative return NaN
    if n < 0 {
        return float32(math.NaN())
    }    // n2 and th are for one iteration of Newton's method later
    n2, th := n*0.5, float32(1.5)    // Use math.Float32bits to represent the float32, n, as
    // an uint32 without modification.
    b := math.Float32bits(n)    // Use the new uint32 view of the float32 to shift the bits
    // of the float32 1 to the right, chopping off 1 bit from
    // the fraction part of the float32.
    b = magic32 - (b >> 1)    // Use math.Float32frombits to convert the uint32 bits back
    // into their float32 representation, again no actual change
    // in the bits, just a change in how we treat them in memory.
    // f is now our answer of 1 / sqrt(n)
    f := math.Float32frombits(b)    // Perform one iteration of Newton's method on f to improve
    // accuracy
    f *= th - (n2 * f * f)
    
    // And return our fast inverse square root result
    return f
}
```

https://github.com/arccoza/go-fastinvsqrt

#### 64 位算法

```go
import "math"
const magic64 = 0x5FE6EB50C7B537A9
func FastInvSqrt64(n float64) float64 {
    if n < 0 {
        return math.NaN()
    }    n2, th := n*0.5, float64(1.5)
    b := math.Float64bits(n)
    b = magic64 - (b >> 1)
    f := math.Float64frombits(b)
    f *= th - (n2 * f * f)
    return f
}
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

### websocketProxy

来源 https://github.com/tobychui/zoraxy/blob/main/src/mod/websocketproxy/websocketproxy.go

```go
// Package websocketproxy is a reverse proxy for WebSocket connections.
package websocketproxy

import (
	"crypto/tls"
	"fmt"
	"io"
	"log"
	"net"
	"net/http"
	"net/url"
	"strings"

	"github.com/gorilla/websocket"
)

var (
	// DefaultUpgrader specifies the parameters for upgrading an HTTP
	// connection to a WebSocket connection.
	DefaultUpgrader = &websocket.Upgrader{
		ReadBufferSize:  1024,
		WriteBufferSize: 1024,
	}

	// DefaultDialer is a dialer with all fields set to the default zero values.
	DefaultDialer = websocket.DefaultDialer
)

// WebsocketProxy is an HTTP Handler that takes an incoming WebSocket
// connection and proxies it to another server.
type WebsocketProxy struct {
	// Director, if non-nil, is a function that may copy additional request
	// headers from the incoming WebSocket connection into the output headers
	// which will be forwarded to another server.
	Director func(incoming *http.Request, out http.Header)

	// Backend returns the backend URL which the proxy uses to reverse proxy
	// the incoming WebSocket connection. Request is the initial incoming and
	// unmodified request.
	Backend func(*http.Request) *url.URL

	// Upgrader specifies the parameters for upgrading a incoming HTTP
	// connection to a WebSocket connection. If nil, DefaultUpgrader is used.
	Upgrader *websocket.Upgrader

	//  Dialer contains options for connecting to the backend WebSocket server.
	//  If nil, DefaultDialer is used.
	Dialer *websocket.Dialer

	Verbal bool

	Options Options
}

// Additional options for websocket proxy runtime
type Options struct {
	SkipTLSValidation bool //Skip backend TLS validation
	SkipOriginCheck   bool //Skip origin check
}

// ProxyHandler returns a new http.Handler interface that reverse proxies the
// request to the given target.
func ProxyHandler(target *url.URL, options Options) http.Handler {
	return NewProxy(target, options)
}

// NewProxy returns a new Websocket reverse proxy that rewrites the
// URL's to the scheme, host and base path provider in target.
func NewProxy(target *url.URL, options Options) *WebsocketProxy {
	backend := func(r *http.Request) *url.URL {
		// Shallow copy
		u := *target
		u.Fragment = r.URL.Fragment
		u.Path = r.URL.Path
		u.RawQuery = r.URL.RawQuery
		return &u
	}
	return &WebsocketProxy{Backend: backend, Verbal: false, Options: options}
}

// ServeHTTP implements the http.Handler that proxies WebSocket connections.
func (w *WebsocketProxy) ServeHTTP(rw http.ResponseWriter, req *http.Request) {
	if w.Backend == nil {
		log.Println("websocketproxy: backend function is not defined")
		http.Error(rw, "internal server error (code: 1)", http.StatusInternalServerError)
		return
	}

	backendURL := w.Backend(req)
	if backendURL == nil {
		log.Println("websocketproxy: backend URL is nil")
		http.Error(rw, "internal server error (code: 2)", http.StatusInternalServerError)
		return
	}

	dialer := w.Dialer
	if w.Dialer == nil {
		if w.Options.SkipTLSValidation {
			//Disable TLS secure check if target allow skip verification
			bypassDialer := websocket.DefaultDialer
			bypassDialer.TLSClientConfig = &tls.Config{InsecureSkipVerify: true}
			dialer = bypassDialer
		} else {
			//Just use the default dialer come with gorilla websocket
			dialer = DefaultDialer
		}
	}

	// Pass headers from the incoming request to the dialer to forward them to
	// the final destinations.
	requestHeader := http.Header{}
	if origin := req.Header.Get("Origin"); origin != "" {
		requestHeader.Add("Origin", origin)
	}
	for _, prot := range req.Header[http.CanonicalHeaderKey("Sec-WebSocket-Protocol")] {
		requestHeader.Add("Sec-WebSocket-Protocol", prot)
	}
	for _, cookie := range req.Header[http.CanonicalHeaderKey("Cookie")] {
		requestHeader.Add("Cookie", cookie)
	}
	if req.Host != "" {
		requestHeader.Set("Host", req.Host)
	}

	// Pass X-Forwarded-For headers too, code below is a part of
	// httputil.ReverseProxy. See http://en.wikipedia.org/wiki/X-Forwarded-For
	// for more information
	// TODO: use RFC7239 http://tools.ietf.org/html/rfc7239
	if clientIP, _, err := net.SplitHostPort(req.RemoteAddr); err == nil {
		// If we aren't the first proxy retain prior
		// X-Forwarded-For information as a comma+space
		// separated list and fold multiple headers into one.
		if prior, ok := req.Header["X-Forwarded-For"]; ok {
			clientIP = strings.Join(prior, ", ") + ", " + clientIP
		}
		requestHeader.Set("X-Forwarded-For", clientIP)
	}

	// Set the originating protocol of the incoming HTTP request. The SSL might
	// be terminated on our site and because we doing proxy adding this would
	// be helpful for applications on the backend.
	requestHeader.Set("X-Forwarded-Proto", "http")
	if req.TLS != nil {
		requestHeader.Set("X-Forwarded-Proto", "https")
	}

	// Enable the director to copy any additional headers it desires for
	// forwarding to the remote server.
	if w.Director != nil {
		w.Director(req, requestHeader)
	}

	// Connect to the backend URL, also pass the headers we get from the requst
	// together with the Forwarded headers we prepared above.
	// TODO: support multiplexing on the same backend connection instead of
	// opening a new TCP connection time for each request. This should be
	// optional:
	// http://tools.ietf.org/html/draft-ietf-hybi-websocket-multiplexing-01
	connBackend, resp, err := dialer.Dial(backendURL.String(), requestHeader)
	if err != nil {
		log.Printf("websocketproxy: couldn't dial to remote backend url %s", err)
		if resp != nil {
			// If the WebSocket handshake fails, ErrBadHandshake is returned
			// along with a non-nil *http.Response so that callers can handle
			// redirects, authentication, etcetera.
			if err := copyResponse(rw, resp); err != nil {
				log.Printf("websocketproxy: couldn't write response after failed remote backend handshake: %s", err)
			}
		} else {
			http.Error(rw, http.StatusText(http.StatusServiceUnavailable), http.StatusServiceUnavailable)
		}
		return
	}
	defer connBackend.Close()

	upgrader := w.Upgrader
	if w.Upgrader == nil {
		upgrader = DefaultUpgrader
	}

	//Fixing issue #107 by bypassing request origin check
	if w.Options.SkipOriginCheck {
		upgrader.CheckOrigin = func(r *http.Request) bool {
			return true
		}
	}

	// Only pass those headers to the upgrader.
	upgradeHeader := http.Header{}
	if hdr := resp.Header.Get("Sec-Websocket-Protocol"); hdr != "" {
		upgradeHeader.Set("Sec-Websocket-Protocol", hdr)
	}
	if hdr := resp.Header.Get("Set-Cookie"); hdr != "" {
		upgradeHeader.Set("Set-Cookie", hdr)
	}

	// Now upgrade the existing incoming request to a WebSocket connection.
	// Also pass the header that we gathered from the Dial handshake.
	connPub, err := upgrader.Upgrade(rw, req, upgradeHeader)
	if err != nil {
		log.Printf("websocketproxy: couldn't upgrade %s", err)
		return
	}
	defer connPub.Close()

	errClient := make(chan error, 1)
	errBackend := make(chan error, 1)
	replicateWebsocketConn := func(dst, src *websocket.Conn, errc chan error) {
		for {
			msgType, msg, err := src.ReadMessage()
			if err != nil {
				m := websocket.FormatCloseMessage(websocket.CloseNormalClosure, fmt.Sprintf("%v", err))
				if e, ok := err.(*websocket.CloseError); ok {
					if e.Code != websocket.CloseNoStatusReceived {
						m = websocket.FormatCloseMessage(e.Code, e.Text)
					}
				}
				errc <- err
				dst.WriteMessage(websocket.CloseMessage, m)
				break
			}
			err = dst.WriteMessage(msgType, msg)
			if err != nil {
				errc <- err
				break
			}
		}
	}

	go replicateWebsocketConn(connPub, connBackend, errClient)
	go replicateWebsocketConn(connBackend, connPub, errBackend)

	var message string
	select {
	case err = <-errClient:
		message = "websocketproxy: Error when copying from backend to client: %v"
	case err = <-errBackend:
		message = "websocketproxy: Error when copying from client to backend: %v"

	}
	if e, ok := err.(*websocket.CloseError); !ok || e.Code == websocket.CloseAbnormalClosure {
		if w.Verbal {
			//Only print message on verbal mode
			log.Printf(message, err)
		}

	}
}

func copyHeader(dst, src http.Header) {
	for k, vv := range src {
		for _, v := range vv {
			dst.Add(k, v)
		}
	}
}

func copyResponse(rw http.ResponseWriter, resp *http.Response) error {
	copyHeader(rw.Header(), resp.Header)
	rw.WriteHeader(resp.StatusCode)
	defer resp.Body.Close()

	_, err := io.Copy(rw, resp.Body)
	return err
}
```



### wakeonlan

来源 https://github.com/tobychui/zoraxy/blob/main/src/mod/wakeonlan/wakeonlan.go

```go
package wakeonlan

import (
	"errors"
	"net"
	"time"
)

/*
	Wake On Lan
	Author: tobychui

	This module send wake on LAN signal to a given MAC address
	and do nothing else
*/

type magicPacket [102]byte

func WakeTarget(macAddr string) error {
	packet := magicPacket{}
	mac, err := net.ParseMAC(macAddr)
	if err != nil {
		return err
	}

	if len(mac) != 6 {
		return errors.New("invalid MAC address")
	}

	//Initialize the packet with all F
	copy(packet[0:], []byte{255, 255, 255, 255, 255, 255})
	offset := 6

	for i := 0; i < 16; i++ {
		copy(packet[offset:], mac)
		offset += 6
	}

	//Most devices listen to either port 7 or 9, send to both of them
	err = sendPacket("255.255.255.255:7", packet)
	if err != nil {
		return err
	}

	time.Sleep(30 * time.Millisecond)

	err = sendPacket("255.255.255.255:9", packet)
	if err != nil {
		return err
	}
	return nil
}

func sendPacket(addr string, packet magicPacket) error {
	conn, err := net.Dial("udp", addr)
	if err != nil {
		return err
	}
	defer conn.Close()

	_, err = conn.Write(packet[:])
	return err
}

func IsValidMacAddress(macaddr string) bool {
	_, err := net.ParseMAC(macaddr)
	return err == nil
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

###  获取当前系统的基本信息

来源 https://github.com/cvilsmeier/moni/blob/main/internal/sampler.go

```go
package internal

import (
	"fmt"
	"math"
	"os"
	"os/exec"
	"strconv"
	"strings"
	"time"

	"github.com/cvilsmeier/monibot-go"
)

type Sampler struct {
	lastCpuStat  cpuStat
	lastDiskStat diskStat
	lastNetStat  netStat
}

func NewSampler() *Sampler {
	return &Sampler{}
}

// Sample calculates a MachineSample for the current resource usage.
func (s *Sampler) Sample() (monibot.MachineSample, error) {
	var sample monibot.MachineSample
	// load loadavg
	loadAvg, err := s.loadLoadAvg()
	if err != nil {
		return sample, fmt.Errorf("cannot loadLoadAvg: %w", err)
	}
	sample.Load1, sample.Load5, sample.Load15 = loadAvg[0], loadAvg[1], loadAvg[2]
	// load cpu usage percent
	cpuPercent, err := s.loadCpuPercent()
	if err != nil {
		return sample, fmt.Errorf("cannot loadCpuPercent: %w", err)
	}
	sample.CpuPercent = cpuPercent
	// load mem usage percent
	memPercent, err := s.loadMemPercent()
	if err != nil {
		return sample, fmt.Errorf("cannot loadMemPercent: %w", err)
	}
	sample.MemPercent = memPercent
	// load disk usage percent
	diskPercent, err := s.loadDiskPercent()
	if err != nil {
		return sample, fmt.Errorf("cannot loadDiskPercent: %w", err)
	}
	sample.DiskPercent = diskPercent
	// load disk activity
	diskAct, err := s.loadDiskActivity()
	if err != nil {
		return sample, fmt.Errorf("cannot loadDiskActivity: %w", err)
	}
	sample.DiskReads, sample.DiskWrites = diskAct[0], diskAct[1]
	// load net activity
	netAct, err := s.loadNetActivity()
	if err != nil {
		return sample, fmt.Errorf("cannot loadNetActivity: %w", err)
	}
	sample.NetRecv, sample.NetSend = netAct[0], netAct[1]
	// load local tstamp
	sample.Tstamp = time.Now().UnixMilli()
	return sample, nil
}

// loadAvg holds system load avg
//
//	[0] = load1 (1m)
//	[1] = load5 (5m)
//	[2] = load15 (15m)
type loadAvg [3]float64

// loadLoadAvg loads loadavg from /proc/loadavg
func (s *Sampler) loadLoadAvg() (loadAvg, error) {
	filename := "/proc/loadavg"
	data, err := os.ReadFile(filename)
	if err != nil {
		return loadAvg{}, fmt.Errorf("cannot read %s: %w", filename, err)
	}
	loadavg, err := parseLoadAvg(string(data))
	if err != nil {
		return loadAvg{}, fmt.Errorf("cannot parse %s %w", filename, err)
	}
	return loadavg, nil
}

// loadCpuPercent loads current cpu usage percent.
// It reads current /proc/stat and calculates CPU usage
// percent between current and lastStat.
func (s *Sampler) loadCpuPercent() (_cpuPercent int, _err error) {
	// load /proc/stat
	stat, err := loadCpuStat()
	if err != nil {
		return 0, fmt.Errorf("cannot loadCpuStat: %w", err)
	}
	// save stat for next time
	lastStat := s.lastCpuStat
	s.lastCpuStat = stat
	// if we have no lastStat, we return 0%
	if lastStat.isZero() {
		return 0, nil
	}
	// calc cpu percent as stat minus lastStat
	total := stat.total - lastStat.total
	idle := stat.idle - lastStat.idle
	used := total - idle
	percent := percentOf(used, total)
	return percent, nil
}

// loadMemPercent uses /usr/bin/free to load mem usage percent.
func (s *Sampler) loadMemPercent() (int, error) {
	filename := "/usr/bin/free"
	text, err := execCommand(filename)
	if err != nil {
		return 0, fmt.Errorf("cannot exec %s: %w", filename, err)
	}
	memPercent, err := parseMemPercent(text)
	if err != nil {
		return 0, fmt.Errorf("cannot parse %s output: %w", filename, err)
	}
	return memPercent, nil
}

// loadDiskPercent uses /usr/bin/df to load disk usage percent.
func (s *Sampler) loadDiskPercent() (int, error) {
	// /usr/bin/df --exclude-type=tmpfs --total --output=source,size,used
	text, err := execCommand("/usr/bin/df", "--exclude-type=tmpfs", "--total", "--output=source,size,used")
	if err != nil {
		return 0, fmt.Errorf("cannot execCommand: %w", err)
	}
	percent, err := parseDiskPercent(text)
	if err != nil {
		return 0, fmt.Errorf("cannot parseDiskPercent: %w", err)
	}
	return percent, nil
}

// diskActivity hold number of sectors read and written. It's used for sampling disk activity.
//
//	[0]=read
//	[1]=writes
type diskActivity [2]int64

// loadDiskActivity loads diskActivity since last invocation.
func (s *Sampler) loadDiskActivity() (diskActivity, error) {
	// load current disk stat
	stat, err := loadDiskStat()
	if err != nil {
		return diskActivity{}, fmt.Errorf("cannot loadDiskStat: %w", err)
	}
	// save stat for next time
	lastStat := s.lastDiskStat
	s.lastDiskStat = stat
	// if we have no lastStat, we return zero
	if lastStat.isZero() {
		return diskActivity{}, nil
	}
	// calc stat minus lastStat
	reads := stat.read - lastStat.read
	writes := stat.written - lastStat.written
	return diskActivity{reads, writes}, nil
}

// netActivity hold number of bytes received and sent. It's used for sampling network activity.
//
//	[0]=recv
//	[1]=send
type netActivity [2]int64

// loadNetActivity loads netActivity since last invocation.
func (s *Sampler) loadNetActivity() (netActivity, error) {
	// load current net stat
	stat, err := loadNetStat()
	if err != nil {
		return netActivity{}, fmt.Errorf("cannot loadNetStat: %w", err)
	}
	// save stat for next time
	lastStat := s.lastNetStat
	s.lastNetStat = stat
	// if we have no lastStat, we return zero
	if lastStat.isZero() {
		return netActivity{}, nil
	}
	// calc stat minus lastStat
	recv := stat.recv - lastStat.recv
	send := stat.send - lastStat.send
	return netActivity{recv, send}, nil
}

// helper functions

// parseLoadAvg parses /proc/loadavg
func parseLoadAvg(text string) (loadAvg, error) {
	// cv@cv:~$ cat /proc/loadavg
	// 0.54 0.56 0.55 1/1006 176235
	loadavg := loadAvg{0, 0, 0}
	toks := strings.Split(text, " ")
	if len(toks) < 3 {
		return loadavg, fmt.Errorf("len(toks) < 3 in %q", text)
	}
	for i := 0; i < 3; i++ {
		load, err := strconv.ParseFloat(toks[i], 64)
		if err != nil {
			return loadavg, fmt.Errorf("toks[%d]=%q: cannot ParseFloat: %w", i, toks[i], err)
		}
		loadavg[i] = load
	}
	return loadavg, nil
}

// parseMemPercent parses /usr/bin/free output
func parseMemPercent(text string) (int, error) {
	//                total        used        free      shared  buff/cache   available
	// Mem:        16072456     2864000      301288      433084    13681804    13208456
	// Swap:        1000444      161024      839420
	lines := strings.Split(text, "\n")
	for _, line := range lines {
		line = normalize(line)
		after, found := strings.CutPrefix(line, "Mem: ")
		if found {
			toks := strings.Split(after, " ")
			if len(toks) < 3 {
				return 0, fmt.Errorf("want min 3 tokens in %q but was %d", line, len(toks))
			}
			totalStr := toks[0]
			total, err := strconv.ParseInt(totalStr, 10, 64)
			if err != nil {
				return 0, fmt.Errorf("cannot parse totalStr %q in line %q: %s", totalStr, line, err)
			}
			if total <= 0 {
				return 0, fmt.Errorf("invalid total <= 0 in line %q", line)
			}
			usedStr := toks[1]
			used, err := strconv.ParseInt(usedStr, 10, 64)
			if err != nil {
				return 0, fmt.Errorf("cannot parse usedStr %q in line %q: %s", usedStr, line, err)
			}
			if used <= 0 {
				return 0, fmt.Errorf("invalid used <= 0 in line %q", line)
			}
			if used > total {
				return 0, fmt.Errorf("invalid used > total in line %q", line)
			}
			return percentOf(used, total), nil
		}
	}
	return 0, fmt.Errorf("prefix \"Mem: \" not found")
}

// parseDiskPercent parses /usr/bin/df output
func parseDiskPercent(text string) (int, error) {
	// Filesystem     1K-blocks      Used
	// udev             7995232         0
	// /dev/nvme0n1p2 981876212 235000596
	// /dev/nvme0n1p1    523248      5976
	// total          990394692 235006572
	lines := strings.Split(text, "\n")
	for _, line := range lines {
		line = normalize(line)
		after, found := strings.CutPrefix(line, "total ")
		if found {
			toks := strings.Split(after, " ")
			if len(toks) < 2 {
				return 0, fmt.Errorf("want 2 toks in %q but has only %d", line, len(toks))
			}
			totalStr := toks[0]
			total, err := strconv.ParseInt(totalStr, 10, 64)
			if err != nil {
				return 0, fmt.Errorf("parse totalStr %q from %q: %w", totalStr, line, err)
			}
			if total <= 0 {
				return 0, fmt.Errorf("invalid total %d from %q", total, line)
			}
			usedStr := toks[1]
			used, err := strconv.ParseInt(usedStr, 10, 64)
			if err != nil {
				return 0, fmt.Errorf("parse usedStr %q from %q: %w", usedStr, line, err)
			}
			if used <= 0 {
				return 0, fmt.Errorf("invalid used %d from %q", used, line)
			}
			if used > total {
				return 0, fmt.Errorf("invalid used %d > total %d from %q", used, total, line)
			}
			return percentOf(used, total), nil
		}
	}
	return 0, fmt.Errorf("prefix \"total \" not found")
}

// cpuStat holds data for a cpu usage stat from /proc/stat.
type cpuStat struct {
	total int64
	idle  int64
}

func (s cpuStat) isZero() bool {
	return s.total == 0 && s.idle == 0
}

// loadCpuStat reads /proc/stat and parses it.
func loadCpuStat() (cpuStat, error) {
	// parse /proc/stat
	filename := "/proc/stat"
	data, err := os.ReadFile(filename)
	if err != nil {
		return cpuStat{}, fmt.Errorf("cannot read %s: %w", filename, err)
	}
	stat, err := parseCpuStat(string(data))
	if err != nil {
		return cpuStat{}, fmt.Errorf("cannot parse %s: %w", filename, err)
	}
	return stat, nil
}

// parseCpuStat parses /proc/stat content.
func parseCpuStat(text string) (cpuStat, error) {
	// cpu  611762 30 136480 16065151 13896 0 5946 0 0 0
	// cpu0 75636 5 17226 2003361 1647 0 2358 0 0 0
	// cpu1 77105 6 16617 2009808 1793 0 689 0 0 0
	// ...
	lines := strings.Split(text, "\n")
	for _, line := range lines {
		line = normalize(line)
		after, found := strings.CutPrefix(line, "cpu ")
		if found {
			toks := strings.Split(after, " ")
			if len(toks) < 5 {
				return cpuStat{}, fmt.Errorf("invalid len(toks) < 5 in %q", line)
			}
			var total int64
			var idle int64
			for i := range toks {
				n, err := strconv.ParseInt(toks[i], 10, 64)
				if err != nil {
					return cpuStat{}, fmt.Errorf("cannot parse toks[%d] %q from line %q: %w", i, toks[i], line, err)
				}
				if i == 3 {
					idle = n
				}
				total += n
			}
			return cpuStat{total, idle}, nil
		}
	}
	return cpuStat{}, fmt.Errorf("prefix \"cpu \" not found")
}

// loadDiskStat reads /proc/diskstats and parses it.
func loadDiskStat() (diskStat, error) {
	filename := "/proc/diskstats"
	data, err := os.ReadFile(filename)
	if err != nil {
		return diskStat{}, fmt.Errorf("cannot read %s: %w", filename, err)
	}
	stat, err := parseDiskStat(string(data))
	if err != nil {
		return diskStat{}, fmt.Errorf("cannot parse %s: %w", filename, err)
	}
	return stat, nil
}

// parseDiskStat parses /proc/diskstats
// See https://www.kernel.org/doc/Documentation/admin-guide/iostats.rst
func parseDiskStat(text string) (diskStat, error) {
	// 259       0 nvme0n1 348631 57325 49778168 51034 237722 390973 34542122 662471 0 262444 729800 0 0 0 0 14038 16295
	// 259       1 nvme0n1p1 187 1000 13454 31 2 0 2 7 0 60 39 0 0 0 0 0 0
	// 259       2 nvme0n1p2 348152 56277 49752186 50957 237639 388315 34512056 662230 0 262220 713187 0 0 0 0 0 0
	//  12       3 sda 348631 57325 49778168 51034 237722 390973 34542122 662471 0 262444 729800 0 0 0 0 14038 16295
	//  12       4 sda1 348631 57325 49778168 51034 237722 390973 34542122 662471 0 262444 729800 0 0 0 0 14038 16295
	// ...
	lines := strings.Split(text, "\n")
	var stat diskStat
	var sampledDevices []string
	for _, line := range lines {
		line = normalize(line)
		toks := strings.Split(line, " ")
		/*
			"259",              [0] major number
			"2",                [1] minor number
			"nvme0n1p2",        [2] device name
			"362480",           [3] reads completed successfully
			"45251",            [4] reads merged
			"56219218",         [5] sectors read <------ want this
			"50895",            [6] time spent reading (ms)
			"169828",           [7] writes completed
			"284438",           [8] writes merged
			"31247016",         [9] sectors written <------ and this
			"434359",          [10] time spent writing (ms)
			"0",               [11] I/Os currently in progress
			"241188",          [12] time spent doing I/Os (ms)
			"485254",          [13] weighted time spent doing I/Os (ms)
		*/
		if len(toks) < 14 {
			continue
		}
		device := normalize(toks[2])
		// skip devices we're not interested in
		goodDevice := strings.HasPrefix(device, "sd") || strings.HasPrefix(device, "nvme")
		if !goodDevice {
			continue
		}
		// skip sub-devices
		var deviceSampledBefore bool
		for _, sampledDevice := range sampledDevices {
			if strings.HasPrefix(device, sampledDevice) {
				deviceSampledBefore = true
			}
		}
		if deviceSampledBefore {
			continue
		}
		// sample this device
		sampledDevices = append(sampledDevices, device)
		tok := toks[5] // [5] sectors read
		read, err := strconv.ParseInt(tok, 10, 64)
		if err != nil {
			return diskStat{}, fmt.Errorf("cannot parse read count %q: %w", tok, err)
		}
		tok = toks[9] // [9] sectors written
		written, err := strconv.ParseInt(tok, 10, 64)
		if err != nil {
			return diskStat{}, fmt.Errorf("cannot parse write count %q: %w", tok, err)
		}
		stat.read += read
		stat.written += written
	}
	return stat, nil
}

// diskStat holds read/write counters from /proc/diskstats.
type diskStat struct {
	read    int64 // number of sectors read since boot // TODO these might overflow
	written int64 // number of sectors written since boot // TODO these might overflow
}

func (s diskStat) isZero() bool {
	return s.read == 0 && s.written == 0
}

// loadNetStat reads /proc/net/dev and parses it.
func loadNetStat() (netStat, error) {
	filename := "/proc/net/dev"
	data, err := os.ReadFile(filename)
	if err != nil {
		return netStat{}, fmt.Errorf("cannot read %s: %w", filename, err)
	}
	stat, err := parseNetStat(string(data))
	if err != nil {
		return netStat{}, fmt.Errorf("cannot parse %s: %w", filename, err)
	}
	return stat, nil
}

// parseNetStat parses /proc/net/dev
func parseNetStat(text string) (netStat, error) {
	// Inter-|   Receive                                                      |  Transmit
	//  face |       bytes packets errs  drop fifo frame compressed multicast |    bytes packets errs drop fifo colls carrier compressed
	//     [0]         [1]     [2]  [3]   [4]  [5]   [6]        [7]       [8]        [9]
	//     lo:   117864359   32173    0     0    0     0          0         0  117864359   32173    0    0    0     0       0          0
	// enp4s0:    21640725   46246    0 13520    0     0          0      1053   13613968   31281    0    0    0     0       0          0
	// wlp0s20f3:        1       2    3     4    5     6          7         8          9      10   11   12   13    14      15         16
	lines := strings.Split(text, "\n")
	var stat netStat
	for _, line := range lines {
		line = normalize(line)
		toks := strings.Split(line, " ")
		if len(toks) < 10 {
			continue
		}
		device := normalize(toks[0])
		// skip non-device lines, e.g. header lines
		if !strings.HasSuffix(device, ":") {
			continue
		}
		// skip devices we are not interested in
		goodDevice := strings.HasPrefix(device, "e") || strings.HasPrefix(device, "w")
		if !goodDevice {
			continue
		}
		tok := toks[1]
		recv, err := strconv.ParseInt(tok, 10, 64)
		if err != nil {
			return netStat{}, fmt.Errorf("cannot parse recv %q: %w", tok, err)
		}
		tok = toks[9]
		send, err := strconv.ParseInt(tok, 10, 64)
		if err != nil {
			return netStat{}, fmt.Errorf("cannot parse send %q: %w", tok, err)
		}
		stat.recv += recv
		stat.send += send
	}
	return stat, nil
}

// netStat holds read/write counters from /proc/net/dev.
type netStat struct {
	recv int64 // number of bytes received since device startup // TODO these might overflow
	send int64 // number of bytes sent since device startup // TODO these might overflow
}

func (s netStat) isZero() bool {
	return s.recv == 0 && s.send == 0
}

// percentOf calculates percentage of used compared to total.
// The result is always in the closed interval [0;100].
func percentOf(used, total int64) int {
	percentf := float64(used) * 100.0 / float64(total)
	percent := int(math.Round(percentf))
	if percent < 0 {
		percent = 0
	}
	if percent > 100 {
		percent = 100
	}
	return int(percent)
}

// execCommand executes an external binary.
func execCommand(name string, args ...string) (string, error) {
	cmd := exec.Command(name, args...)
	cmd.WaitDelay = 10 * time.Second
	out, err := cmd.CombinedOutput()
	if err != nil {
		err = fmt.Errorf("cannot run %s: %w", name, err)
	}
	return string(out), err
}

// normalize trims and normalizes a line of text.
func normalize(s string) string {
	s = replaceAll(s, "\t", " ")
	s = replaceAll(s, "\r", "")
	s = replaceAll(s, "\n", "")
	s = replaceAll(s, "  ", " ")
	return strings.TrimSpace(s)
}

// replaceAll replaces strings, even if they occur many times.
func replaceAll(str, old, new string) string {
	var i int
	for strings.Contains(str, old) && i < 100 {
		i++
		str = strings.ReplaceAll(str, old, new)
	}
	return str
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

### 检查用户是否属于某个用户组

代码来源 https://github.com/tailscale/tailscale/blob/ea9c7f991aa8bfd19afe04ea54b7a59017450f90/util/groupmember/groupmember.go

```go
// Copyright (c) Tailscale Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

// Package groupmember verifies group membership of the provided user on the
// local system.
package groupmember

import (
	"os/user"
	"slices"
)

// IsMemberOfGroup reports whether the provided user is a member of
// the provided system group.
func IsMemberOfGroup(group, userName string) (bool, error) {
	u, err := user.Lookup(userName)
	if err != nil {
		return false, err
	}
	g, err := user.LookupGroup(group)
	if err != nil {
		return false, err
	}
	ugids, err := u.GroupIds()
	if err != nil {
		return false, err
	}
	return slices.Contains(ugids, g.Gid), nil
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

## 软件生命周期

### 平滑重启

#### shutdown

Graceful shutdown 来源 https://github.com/marmotedu/iam/blob/master/pkg/shutdown/shutdown.go

```go
package shutdown

import (
	"sync"
)

// ShutdownCallback is an interface you have to implement for callbacks.
// OnShutdown will be called when shutdown is requested. The parameter
// is the name of the ShutdownManager that requested shutdown.
type ShutdownCallback interface {
	OnShutdown(string) error
}

// ShutdownFunc is a helper type, so you can easily provide anonymous functions
// as ShutdownCallbacks.
type ShutdownFunc func(string) error

// OnShutdown defines the action needed to run when shutdown triggered.
func (f ShutdownFunc) OnShutdown(shutdownManager string) error {
	return f(shutdownManager)
}

// ShutdownManager is an interface implemnted by ShutdownManagers.
// GetName returns the name of ShutdownManager.
// ShutdownManagers start listening for shutdown requests in Start.
// When they call StartShutdown on GSInterface,
// first ShutdownStart() is called, then all ShutdownCallbacks are executed
// and once all ShutdownCallbacks return, ShutdownFinish is called.
type ShutdownManager interface {
	GetName() string
	Start(gs GSInterface) error
	ShutdownStart() error
	ShutdownFinish() error
}

// ErrorHandler is an interface you can pass to SetErrorHandler to
// handle asynchronous errors.
type ErrorHandler interface {
	OnError(err error)
}

// ErrorFunc is a helper type, so you can easily provide anonymous functions
// as ErrorHandlers.
type ErrorFunc func(err error)

// OnError defines the action needed to run when error occurred.
func (f ErrorFunc) OnError(err error) {
	f(err)
}

// GSInterface is an interface implemented by GracefulShutdown,
// that gets passed to ShutdownManager to call StartShutdown when shutdown
// is requested.
type GSInterface interface {
	StartShutdown(sm ShutdownManager)
	ReportError(err error)
	AddShutdownCallback(shutdownCallback ShutdownCallback)
}

// GracefulShutdown is main struct that handles ShutdownCallbacks and
// ShutdownManagers. Initialize it with New.
type GracefulShutdown struct {
	callbacks    []ShutdownCallback
	managers     []ShutdownManager
	errorHandler ErrorHandler
}

// New initializes GracefulShutdown.
func New() *GracefulShutdown {
	return &GracefulShutdown{
		callbacks: make([]ShutdownCallback, 0, 10),
		managers:  make([]ShutdownManager, 0, 3),
	}
}

// Start calls Start on all added ShutdownManagers. The ShutdownManagers
// start to listen to shutdown requests. Returns an error if any ShutdownManagers
// return an error.
func (gs *GracefulShutdown) Start() error {
	for _, manager := range gs.managers {
		if err := manager.Start(gs); err != nil {
			return err
		}
	}

	return nil
}

// AddShutdownManager adds a ShutdownManager that will listen to shutdown requests.
func (gs *GracefulShutdown) AddShutdownManager(manager ShutdownManager) {
	gs.managers = append(gs.managers, manager)
}

// AddShutdownCallback adds a ShutdownCallback that will be called when
// shutdown is requested.
//
// You can provide anything that implements ShutdownCallback interface,
// or you can supply a function like this:
//
//	AddShutdownCallback(shutdown.ShutdownFunc(func() error {
//		// callback code
//		return nil
//	}))
func (gs *GracefulShutdown) AddShutdownCallback(shutdownCallback ShutdownCallback) {
	gs.callbacks = append(gs.callbacks, shutdownCallback)
}

// SetErrorHandler sets an ErrorHandler that will be called when an error
// is encountered in ShutdownCallback or in ShutdownManager.
//
// You can provide anything that implements ErrorHandler interface,
// or you can supply a function like this:
//
//	SetErrorHandler(shutdown.ErrorFunc(func (err error) {
//		// handle error
//	}))
func (gs *GracefulShutdown) SetErrorHandler(errorHandler ErrorHandler) {
	gs.errorHandler = errorHandler
}

// StartShutdown is called from a ShutdownManager and will initiate shutdown.
// first call ShutdownStart on Shutdownmanager,
// call all ShutdownCallbacks, wait for callbacks to finish and
// call ShutdownFinish on ShutdownManager.
func (gs *GracefulShutdown) StartShutdown(sm ShutdownManager) {
	gs.ReportError(sm.ShutdownStart())

	var wg sync.WaitGroup
	for _, shutdownCallback := range gs.callbacks {
		wg.Add(1)
		go func(shutdownCallback ShutdownCallback) {
			defer wg.Done()

			gs.ReportError(shutdownCallback.OnShutdown(sm.GetName()))
		}(shutdownCallback)
	}

	wg.Wait()

	gs.ReportError(sm.ShutdownFinish())
}

// ReportError is a function that can be used to report errors to
// ErrorHandler. It is used in ShutdownManagers.
func (gs *GracefulShutdown) ReportError(err error) {
	if err != nil && gs.errorHandler != nil {
		gs.errorHandler.OnError(err)
	}
```

##  并发编程

race 来源于tailscale [地址](https://github.com/tailscale/tailscale/blob/ea9c7f991aa8bfd19afe04ea54b7a59017450f90/util/race/race.go)

```go
/ Copyright (c) Tailscale Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

// Package race contains a helper to "race" two functions, returning the first
// successful result. It also allows explicitly triggering the
// (possibly-waiting) second function when the first function returns an error
// or indicates that it should be retried.
package race

import (
	"context"
	"errors"
	"time"
)

type resultType int

const (
	first resultType = iota
	second
)

// queryResult is an internal type for storing the result of a function call
type queryResult[T any] struct {
	ty  resultType
	res T
	err error
}

// Func is the signature of a function to be called.
type Func[T any] func(context.Context) (T, error)

// Race allows running two functions concurrently and returning the first
// non-error result returned.
type Race[T any] struct {
	func1, func2  Func[T]
	d             time.Duration
	results       chan queryResult[T]
	startFallback chan struct{}
}

// New creates a new Race that, when Start is called, will immediately call
// func1 to obtain a result. After the timeout d or if triggered by an error
// response from func1, func2 will be called.
func New[T any](d time.Duration, func1, func2 Func[T]) *Race[T] {
	ret := &Race[T]{
		func1:         func1,
		func2:         func2,
		d:             d,
		results:       make(chan queryResult[T], 2),
		startFallback: make(chan struct{}),
	}
	return ret
}

// Start will start the "race" process, returning the first non-error result or
// the errors that occurred when calling func1 and/or func2.
func (rh *Race[T]) Start(ctx context.Context) (T, error) {
	ctx, cancel := context.WithCancel(ctx)
	defer cancel()

	// func1 is started immediately
	go func() {
		ret, err := rh.func1(ctx)
		rh.results <- queryResult[T]{first, ret, err}
	}()

	// func2 is started after a timeout
	go func() {
		wait := time.NewTimer(rh.d)
		defer wait.Stop()

		// Wait for our timeout, trigger, or context to finish.
		select {
		case <-ctx.Done():
			// Nothing to do; we're done
			var zero T
			rh.results <- queryResult[T]{second, zero, ctx.Err()}
			return
		case <-rh.startFallback:
		case <-wait.C:
		}

		ret, err := rh.func2(ctx)
		rh.results <- queryResult[T]{second, ret, err}
	}()

	// For each possible result, get it off the channel.
	var errs []error
	for i := 0; i < 2; i++ {
		res := <-rh.results

		// If this was an error, store it and hope that the other
		// result gives us something.
		if res.err != nil {
			errs = append(errs, res.err)

			// Start the fallback function immediately if this is
			// the first function's error, to avoid having
			// to wait.
			if res.ty == first {
				close(rh.startFallback)
			}
			continue
		}

		// Got a valid response! Return it.
		return res.res, nil
	}

	// If we get here, both raced functions failed. Return whatever errors
	// we have, joined together.
	var zero T
	return zero, errors.Join(errs...)
    }
```



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

## 工具类

### 证书信息检查

来源 https://github.com/mercari/certificate-expiry-monitor-controller/blob/master/source/tls_endpoint.go#L39

```go
package source

import (
	"crypto/tls"
	"crypto/x509"
	"strings"
)

var (
	// Allow certificate that signed by unknown authority.
	// Controller only concerns expiration of certificate.
	defaultTLSConfig = tls.Config{InsecureSkipVerify: true}

	// DefaultPortNumber exposes default port number to testing
	// TODO: Support port numbers other than :443
	DefaultPortNumber = "443"
)

// TLSEndpoint expressses https endpoint that using TLS.
type TLSEndpoint struct {
	Hostname string
	Port     string
}

// NewTLSEndpoint creates new TLSEndpoint instance.
// If port number is empty, set DefaultPortNumber instead.
func NewTLSEndpoint(host string, port string) *TLSEndpoint {
	if port == "" {
		port = DefaultPortNumber
	}

	return &TLSEndpoint{
		Hostname: host,
		Port:     port,
	}
}

// GetCertificates tries to get certificates from endpoint using tls.Dial
func (e *TLSEndpoint) GetCertificates() ([]*x509.Certificate, error) {

	// We cannot connect to Hostnames with wildcards, so replacing with cert-test.
	hostName := strings.Replace(e.Hostname, "*", "cert-test", -1)
	conn, err := tls.Dial("tcp", hostName+":"+e.Port, &defaultTLSConfig)
	if err != nil {
		return nil, err
	}
	defer conn.Close()

	return conn.ConnectionState().PeerCertificates, nil
}
```



## 有用的链接

+ https://github.com/TheAlgorithms/Go
