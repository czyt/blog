---
title: "在Go语言中处理带BOM的json数据"
date: 2024-12-03
draft: false
tags: ["go"]
author: "czyt"
---

## 缘起

今天开发的时候遇到一个奇怪的问题，一个JSON文件，使用文本编辑器打开复制，并使用`strings.NewReader`来decode，是正常的，但是通过文件打开同样调用的方法来decode，却是失败的。后面通过打开IDE，发现文件前面有一些空白的内容。是一些bom信息。

## 关于BOM

BOM (Byte Order Mark) 的历史原因和用途主要与字符编码和跨平台兼容性有关：

### 历史原因

1. Unicode 出现前：
- ASCII 只用 1 字节，没有字节序问题
- 各国有自己的编码标准(GB2312、Shift-JIS等)

2. Unicode 引入后：
- UTF-16 使用 2 字节表示字符
- 不同CPU架构的字节序不同：
  * Big Endian (大端序): 高位字节在前
  * Little Endian (小端序): 低位字节在前

3. 跨平台问题：
- Intel x86 使用小端序
- Motorola 68k 使用大端序
- 同一文件在不同平台解析可能出错

### BOM 的作用

1. UTF-16 的字节序标记：
- FE FF: Big Endian
- FF FE: Little Endian

2. UTF-8 的编码标识：
- EF BB BF: 表明这是 UTF-8 编码
- UTF-8 实际不需要 BOM（字节序无关）
- Windows 添加 BOM 主要为了兼容性

### 实际例子

```go
// 字符 "中" 在不同编码下的表示
text := "中"

// UTF-8: E4 B8 AD
// UTF-16BE: 4E 2D
// UTF-16LE: 2D 4E

// 示例代码
func showEncoding() {
    text := "中"
    utf8Bytes := []byte(text)                 // UTF-8
    utf16beBytes := utf16.Encode([]rune(text)) // UTF-16BE
    
    fmt.Printf("UTF-8: % X\n", utf8Bytes)
    fmt.Printf("UTF-16BE: % X\n", utf16beBytes)
}
```

### 常见问题场景

1. 文本编辑器：
- Notepad++ 可选是否添加 BOM
- VS Code 可以识别和显示 BOM
- 某些编辑器可能显示 BOM 为特殊字符

2. Web 开发：
- PHP 文件开头的 BOM 可能导致 header 错误
- HTML 文件的 BOM 可能影响布局
- JavaScript 文件的 BOM 可能导致语法错误

3. 配置文件：
- XML 文件的 BOM 可能影响解析
- INI 文件的 BOM 可能导致配置读取错误
- JSON 文件的 BOM 可能导致解析失败

### 建议

1. UTF-8 编码：
- 不建议使用 BOM
- UTF-8 是字节序无关的
- 已成为事实标准

2. 新项目：
- 统一使用 UTF-8 无 BOM
- 明确规定编码要求
- 添加编码检测机制

3. 老项目维护：
- 保持现有编码方式
- 添加编码处理代码
- 记录文件编码信息

## 解决方案

### 帮助函数

```go
// 检测文件是否包含 BOM
func HasBOM(filename string) (bool, string, error) {
    file, err := os.Open(filename)
    if err != nil {
        return false, "", err
    }
    defer file.Close()

    reader := bufio.NewReader(file)
    peek, err := reader.Peek(4)
    if err != nil && err != io.EOF {
        return false, "", err
    }

    // 检查不同的 BOM
    boms := map[string][]byte{
        "UTF-8":    {0xEF, 0xBB, 0xBF},
        "UTF-16BE": {0xFE, 0xFF},
        "UTF-16LE": {0xFF, 0xFE},
        "UTF-32BE": {0x00, 0x00, 0xFE, 0xFF},
        "UTF-32LE": {0xFF, 0xFE, 0x00, 0x00},
    }

    for encoding, bom := range boms {
        if len(peek) >= len(bom) && bytes.Equal(peek[:len(bom)], bom) {
            return true, encoding, nil
        }
    }

    return false, "", nil
}

// 添加 UTF-8 BOM
func AddUTF8BOM(filename string) error {
    // 读取原文件内容
    content, err := os.ReadFile(filename)
    if err != nil {
        return err
    }

    // 检查是否已有 BOM
    if len(content) >= 3 && bytes.Equal(content[:3], []byte{0xEF, 0xBB, 0xBF}) {
        return nil // 已有 BOM，不需要添加
    }

    // 添加 BOM
    newContent := append([]byte{0xEF, 0xBB, 0xBF}, content...)
    return os.WriteFile(filename, newContent, 0644)
}

// 移除 BOM
func RemoveBOM(filename string) error {
    content, err := os.ReadFile(filename)
    if err != nil {
        return err
    }

    // 检查并移除不同类型的 BOM
    boms := map[string][]byte{
        "UTF-8":    {0xEF, 0xBB, 0xBF},
        "UTF-16BE": {0xFE, 0xFF},
        "UTF-16LE": {0xFF, 0xFE},
        "UTF-32BE": {0x00, 0x00, 0xFE, 0xFF},
        "UTF-32LE": {0xFF, 0xFE, 0x00, 0x00},
    }

    for _, bom := range boms {
        if len(content) >= len(bom) && bytes.Equal(content[:len(bom)], bom) {
            // 移除 BOM
            return os.WriteFile(filename, content[len(bom):], 0644)
        }
    }

    return nil // 没有 BOM，不需要处理
}
```

### 纯文本文件调用

```go
func main() {
    // 创建示例文件
    content := []byte("Hello, 世界！")
    tempDir := os.TempDir()
    filename := filepath.Join(tempDir, "test.txt")

    // 写入原始内容
    if err := os.WriteFile(filename, content, 0644); err != nil {
        log.Fatalf("Error writing file: %v", err)
    }
    defer os.Remove(filename)


    // 1. 检测原始文件
    hasBOM, encoding, err := DetectBOM(filename)
    if err != nil {
        log.Fatalf("Error detecting BOM: %v", err)
    }
    fmt.Printf("Original file has BOM: %v, Encoding: %s\n", hasBOM, encoding)

    // 2. 添加 BOM
    if err := AddBOM(filename); err != nil {
        log.Fatalf("Error adding BOM: %v", err)
    }
    fmt.Println("Added UTF-8 BOM to file")

    // 3. 再次检测
    hasBOM, encoding, err = DetectBOM(filename)
    if err != nil {
        log.Fatalf("Error detecting BOM: %v", err)
    }
    fmt.Printf("After adding BOM: has BOM: %v, Encoding: %s\n", hasBOM, encoding)

    // 4. 移除 BOM
    if err :=RemoveBOM(filename); err != nil {
        log.Fatalf("Error removing BOM: %v", err)
    }
    fmt.Println("Removed BOM from file")

    // 5. 最后检测
    hasBOM, encoding, err = DetectBOM(filename)
    if err != nil {
        log.Fatalf("Error detecting BOM: %v", err)
    }
    fmt.Printf("After removing BOM: has BOM: %v, Encoding: %s\n", hasBOM, encoding)

    // 读取并显示最终内容
    finalContent, err := os.ReadFile(filename)
    if err != nil {
        log.Fatalf("Error reading final content: %v", err)
    }
    fmt.Printf("Final content: %s\n", string(finalContent))
}
```

### JSON解析

```go
package main

import (
    "bufio"
    "bytes"
    "encoding/json"
    "fmt"
    "io"
    "log"
    "os"
)

// 定义 JSON 结构
type Person struct {
    Name    string   `json:"name"`
    Age     int      `json:"age"`
    Hobbies []string `json:"hobbies"`
}

// BOM 处理函数
func skipBOM(reader *bufio.Reader) error {
    boms := map[string][]byte{
        "UTF-8":    {0xEF, 0xBB, 0xBF},
        "UTF-16BE": {0xFE, 0xFF},
        "UTF-16LE": {0xFF, 0xFE},
    }

    // 预读4个字节
    peek, err := reader.Peek(4)
    if err != nil && err != io.EOF {
        return fmt.Errorf("reading BOM: %w", err)
    }

    // 检查并跳过 BOM
    for encoding, bom := range boms {
        if len(peek) >= len(bom) && bytes.Equal(peek[:len(bom)], bom) {
            _, err = reader.Discard(len(bom))
            if err != nil {
                return fmt.Errorf("skipping BOM: %w", err)
            }
            log.Printf("Skipped %s BOM", encoding)
            return nil
        }
    }

    return nil // 没有 BOM
}

// 读取并解析 JSON 文件
func ReadJSONFile(filename string) ([]Person, error) {
    // 打开文件
    file, err := os.Open(filename)
    if err != nil {
        return nil, fmt.Errorf("opening file: %w", err)
    }
    defer file.Close()

    // 创建带缓冲的读取器
    reader := bufio.NewReader(file)

    // 处理 BOM
    if err := skipBOM(reader); err != nil {
        return nil, fmt.Errorf("handling BOM: %w", err)
    }

    // 解析 JSON
    var people []Person
    decoder := json.NewDecoder(reader)
    if err := decoder.Decode(&people); err != nil {
        return nil, fmt.Errorf("decoding JSON: %w", err)
    }

    return people, nil
}

// 创建示例 JSON 文件
func createSampleJSONFile(filename string, withBOM bool) error {
    // 示例数据
    people := []Person{
        {
            Name:    "张三",
            Age:     25,
            Hobbies: []string{"读书", "游泳"},
        },
        {
            Name:    "李四",
            Age:     30,
            Hobbies: []string{"篮球", "音乐"},
        },
    }

    // 转换为 JSON
    jsonData, err := json.MarshalIndent(people, "", "    ")
    if err != nil {
        return err
    }

    // 如果需要 BOM，添加 UTF-8 BOM
    if withBOM {
        jsonData = append([]byte{0xEF, 0xBB, 0xBF}, jsonData...)
    }

    // 写入文件
    return os.WriteFile(filename, jsonData, 0644)
}

func main() {
    // 测试文件名
    filename := "test.json"

    // 1. 创建带 BOM 的 JSON 文件
    log.Println("Creating JSON file with BOM...")
    err := createSampleJSONFile(filename, true)
    if err != nil {
        log.Fatalf("Error creating JSON file: %v", err)
    }
    defer os.Remove(filename)

    // 2. 读取并解析 JSON
    log.Println("Reading JSON file...")
    people, err := ReadJSONFile(filename)
    if err != nil {
        log.Fatalf("Error reading JSON file: %v", err)
    }

    // 3. 打印结果
    log.Printf("Successfully parsed %d records:", len(people))
    for i, person := range people {
        fmt.Printf("%d. %s (age: %d) likes %v\n",
            i+1, person.Name, person.Age, person.Hobbies)
    }

    // 4. 创建不带 BOM 的文件测试
    log.Println("\nCreating JSON file without BOM...")
    err = createSampleJSONFile(filename, false)
    if err != nil {
        log.Fatalf("Error creating JSON file: %v", err)
    }

    // 5. 再次读取
    log.Println("Reading JSON file without BOM...")
    people, err = ReadJSONFile(filename)
    if err != nil {
        log.Fatalf("Error reading JSON file: %v", err)
    }

    // 6. 打印结果
    log.Printf("Successfully parsed %d records:", len(people))
    for i, person := range people {
        fmt.Printf("%d. %s (age: %d) likes %v\n",
            i+1, person.Name, person.Age, person.Hobbies)
    }
}

```

