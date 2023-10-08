---
title: "golang转换任意长度[] byte为int"
date: 2022-07-30
tags: ["golang", "trick"]
draft: false 
---
```go
package main

import (
	"encoding/binary"
	"fmt"
)

func main() {
	slices := [][]byte{
		{1},
		{1, 2},
		{1, 2, 3},
		{1, 2, 3, 4},
		{1, 2, 3, 4, 5},
		{1, 2, 3, 4, 5, 6},
		{1, 2, 3, 4, 5, 6, 7},
		{1, 2, 3, 4, 5, 6, 7, 8},
	}

	for _, s := range slices {
		fmt.Println(getInt1(s), getInt2(s))
	}
}

func getInt1(s []byte) int {
	var b [8]byte
	copy(b[8-len(s):], s)
	return int(binary.BigEndian.Uint64(b[:]))
}

func getInt2(s []byte) int {
	var res int
	for _, v := range s {
		res <<= 8
		res |= int(v)
	}
	return res
}
```
参考
● https://www.reddit.com/r/golang/comments/4xn341/converting_byte_to_int32/
● https://forum.golangbridge.org/t/converting-single-byte-slice-to-int

