---
title: "iter.Seq实践【译】"
date: 2025-02-19
draft: false
tags: ["go"]
description: "一些 iter.Seq、iter.Seq2 及其 iter.Pull 的真实场景例子，他们让编码变得更轻松"
---

> 原文链接 https://blog.vertigrated.com/iterseq-in-practice

## FirstN

返回序列中的前 N 个项。

```go
// FirstN takes an iter.Seq[int] and returns a new iter.Seq[int] that
// yields only the first 'limit' items without creating intermediate slices.
func FirstN[T any](original iter.Seq[T], limit int) iter.Seq[T] {
    return iter.Seq[T](func(yield func(T) bool) {
        count := 0
        for item := range original {
            if count < limit {
                if !yield(item) {
                    return
                }
                count++
            } else {
                return
            }
        }
    })
}
```

##  SkipFirstN

跳过前 N 个元素并返回剩余的序列。

```go
func SkipFirstN[T any](seq iter.Seq[T], skip int) iter.Seq[T] {
    return iter.Seq[T](func(yield func(T) bool) {
       next, stop := iter.Pull[T](seq)
       defer stop()

       for i := 0; i <= skip; i++ {
          _, ok := next()
          if !ok {
             break
          }
       }
       for {
          v, ok := next()
          if !ok {
             break
          }
          if !yield(v) {
             return
          }
       }
    })
}
```

##  SkipLimit（SubSeq）

示例内联组合 `FirstN` 和 `SkipFirstN`

```go
// I wrapped this in a function as straw man example just to get the highlighting to work
func SkipLimit[V any](it iter.Seq[V],, skip int, limit int) iter.Seq[V] {
    return FirstN[V](SkipFirstN[V](it, skip), limit)
}

// normally youo would just inline the composition ike this
subSeq := FirstN[string](SkipFirstN[string](it, skip, limit)
```

## Chunk

从原始序列中创建一系列固定大小的序列，而不创建任何中间切片或数组。

这很有用，当你向只接受 N 个项目的 API 提供数据时。通过一些工作，这可以使其与 goroutines 和 channels 一起工作，以并行处理生成的数据块。

```go
// Chunk returns an iterator over consecutive sub-slices of up to n elements of s.
// All but the last iter.Seq chunk will have size n.
// Chunk panics if n is less than 1.
func Chunk[T any](sq iter.Seq[T], size int) iter.Seq[iter.Seq[T]] {
    if size < 0 {
       panic(errs.MinSizeExceededError.New("size %d must be >= 0", size))
    }

    return func(yield func(s iter.Seq[T]) bool) {
       next, stop := iter.Pull[T](sq)
       defer stop()
       endOfSeq := false
       for !endOfSeq {
          // get the first item for the chunk
          v, ok := next()
          // there are no more items !ok then exit loop
          // this prevents returning an extra empty iter.Seq at end of Seq
          if !ok {
             break
          }
          // create the next sequence chunk
          iterSeqChunk := func(yield func(T) bool) {
             i := 0
             for ; i < size-1; i++ {
                if ok {
                   if !ok {
                      // end of original sequence
                      // this sequence may be <= size
                      endOfSeq = true
                      break
                   }

                   if !yield(v) {
                      return
                   }
                   v, ok = next()
                }
             }
          }
          if !yield(iterSeqChunk) {
             return
          }
       }
    }
}
```

## SeqToSeq2

此函数接受一个序列和一个键生成函数，并返回一个 `iter.Seq2` ，而不创建任何中间切片或数组。

```go
func SeqToSeq2[K any, V any](is iter.Seq[V], keyFunc func(v V) K) iter.Seq2[K, V] {
    return iter.Seq2[K, V](func(yield func(K, V) bool) {
       for v := range is {
          k := keyFunc(v)
          if !yield(k, v) {
             return
          }
       }
    })
}
```

##  Map 

你们中大多数人可能认为我应该把它放在第一位。它与 Monad 在 `bind` 和 `map` 行为上最为相似，之所以命名为 Map 是有原因的。

但是这完全忽略了 `iter` 包的意义。这不仅仅关乎功能性编程，它是一种创建自定义可迭代类型的惯用方法。

这是按照定义最接近 Monad 行为的，跳过了 `bind` 语义，直接将 `map` 函数应用于值。如果你的值对象有一个名为 `ID` 的字段作为键，那么 `keyFunc` 可以是简单地返回 `v.ID` ，也可以是复杂地计算对象的 `SHA256` 哈希值作为键。或者，甚至不是映射，比如从 `Person` 结构中返回 `FirstName` 和 `LastName` 。

事实是 `K` 值被键入为 `any` 而不是 `comparable` ，这意味着它不仅适用于来自映射的键。

```go
func SeqToSeq2[K any, V any](is iter.Seq[V], keyFunc func(v V) K) iter.Seq2[K, V] {
    return iter.Seq2[K, V](func(yield func(K, V) bool) {
       for v := range is {
          k := keyFunc(v)
          if !yield(k, v) {
             return
          }
       }
    })
}
```

## DocumentIteratorToSeq

Firestore 文档迭代器被包裹在 iter.Seq 中，没有生成任何中间切片或数组。

```go
// DocumentIteratorToSeq converts a firestore.Iterator to an iter.Seq.
// value is a pointer to the type V
func DocumentIteratorToSeq[V any](dsi firestore.DocumentIterator) iter.Seq[V] {
    return func(yield func(*V) bool) {
       defer dsi.Stop()
       for {
          doc, err := dsi.Next()
          if errors.Is(err, iterator.Done) {
             return
          }
          if err != nil {
             log.Error().Err(err).Msg("error iterating through Firestore documents")
             return
          }

          var b V
          err = doc.DataTo(&b)
          if err != nil {
             log.Error().Err(err).Msgf("error unmarshalling Firestore document with ID %s", doc.Ref.ID)
             return
          }

          if !yield(&b) {
             return
          }
       }
    }
}
```

## DocumentIteratorToSeq2

与上面相同，但文档密钥用作返回的 `iter.Seq2` 中的 `K` 值作为 `string` 。

我总是使用 `string` 类型作为密钥，因此没有必要参数化密钥类型，那样会使它更复杂。

```go
// DocumentIteratorToSeq2 converts a firestore.Iterator to an iter.Seq2.
// doc.Ref.ID is used as the "key" or first value, second value is a pointer to the type V
func DocumentIteratorToSeq2[V any](dsi *firestore.DocumentIterator) iter.Seq2[string, *V] {
    return func(yield func(string, *V) bool) {
        defer dsi.Stop()
        for {
            doc, err := dsi.Next()
            if errors.Is(err, iterator.Done) {
                return
            }
            if err != nil {
                log.Error().Err(err).Msg("error iterating through Firestore documents")
                return
            }

            var b V
            err = doc.DataTo(&b)
            if err != nil {
                log.Error().Err(err).Msgf("error unmarshalling Firestore document with ID %s", doc.Ref.ID)
                continue
            }

            if !yield(doc.Ref.ID, &b) {
                return
            }
        }
    }
}
```

##  引入的包

以下是上述代码示例中使用的包列表。

```go
import (
    "iter"
    "slices"
    "strings"

    "cloud.google.com/go/firestore"
    "google.golang.org/api/iterator"
    "github.com/rs/zerolog/log"
    "github.com/joomcode/errorx"
    errs "github.com/jarrodhroberson/ossgo/errors"
)
```