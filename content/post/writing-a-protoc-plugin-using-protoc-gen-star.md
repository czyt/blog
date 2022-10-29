---
title: "使用protoc-gen-star编写protoc插件"
date: 2022-10-29
tags: ["golang","protobuf"]
draft: false
---

## 预备知识

### 需要安装的软件

+ protoc

+ golang

### 插件调用步骤

  假设插件名称为`diy`,则需要编译程序为`protoc-gen-diy`，并将程序加入系统Path变量，通过下面的命令调用插件。

```bash
protoc -I . --diy_out=./gen/  xxxx.proto
```
##  使用protoc-gen-star包

### 模块 Modules

### 后期处理 Post Processing

### 访问者模式 Visitor Pattern

### 构建上下文 Build Context

### 特定语言的子包 Language-Specific Subpackages

## 开始编写你的插件
### 一个简单的插件
### 延申

## 参考链接

+ [Writing a protoc plugin with google.golang.org/protobuf](https://medium.com/@tim.r.coulson/writing-a-protoc-plugin-with-google-golang-org-protobuf-cd5aa75f5777)

