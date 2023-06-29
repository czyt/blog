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
