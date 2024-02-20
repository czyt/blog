---
title: "golang检测字节是否为utf-8字节的起始字节"
date: 2024-02-19
tags: ["golang", "network"]
draft: false
---

## 原理

UTF-8 编码使用不同长度的字节序列来表示 Unicode 字符。这些序列的长度从一个字节到四个字节不等，每个字节都有特定的比特模式。您可以通过观察任何字节的最高位（也就是最左边的几位比特），来判断这个字节是不是某个字符的 UTF-8 编码的起始字节或中间字节：

1. 单字节字符（U+0000 到 U+007F）以 `0xxxxxxx` 为模式，其中 `x` 可以是 `0` 或 `1`。这种单字节的高位为 `0`，表示它是 ASCII 字符的起始（也是唯一）字节。

2. UTF-8 编码的起始字节（即多字节序列的第一个字节）模式为 `110xxxxx`（对于两字节编码）、`1110xxxx`（对于三字节编码）或 `11110xxx`（对于四字节编码）。

3. 对于一个 UTF-8 字符的非起始字节（也称为连续字节或中间字节），其模式为 `10xxxxxx`。

因此，如果你看到一个字节，它的最高两位是 `10`，那么它是 UTF-8 编码中的一个连续字节。如果最高一位是 `0` 或者高位模式匹配 `110`、`1110` 或 `11110`，它就是起始字节。

举例来说：

- `0xxxxxxx` - UTF-8 字符的起始字节（单字节 ASCII 字符）
- `110xxxxx` - 两字节编码的起始字节
- `1110xxxx` - 三字节编码的起始字节
- `11110xxx` - 四字节编码的起始字节
- `10xxxxxx` - 中间字节

通过检查字节的最高位，您就可以迅速确定它是 UTF-8 编码序列的起始字节还是中间字节。

## 实现

### go语言实现

```go
package main

import (
 "fmt"
)

// isUTF8StartByte checks whether a byte is a UTF-8 start byte.
func isUTF8StartByte(b byte) bool {
 // For single-byte (ASCII), starts with 0xxxxxxx
 if b&0x80 == 0x00 {
  return true
 }
 // For multibyte sequences, if a byte starts with
 // 110xxxxx, 1110xxxx, or 11110xxx, it is a start byte.
 if (b&0xE0 == 0xC0) || (b&0xF0 == 0xE0) || (b&0xF8 == 0xF0) {
  return true
 }
 // Otherwise, it is a continuation byte (10xxxxxx).
 return false
}

func main() {
 examples := []byte{0b01110100, 0b11011110, 0b11101110, 0b10111100, 0b00111100}
 for _, b := range examples {
  if isUTF8StartByte(b) {
   fmt.Printf("Byte 0x%X is a start byte of a UTF-8 character.\n", b)
  } else {
   fmt.Printf("Byte 0x%X is a continuation or invalid byte of a UTF-8 character.\n", b)
  }
 }
}
```

