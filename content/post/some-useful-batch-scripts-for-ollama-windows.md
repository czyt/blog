---
title: "Windows ollama一些有用的批处理脚本"
date: 2024-05-09
tags: ["ollama",  "tricks"]
draft: false
---

## 模型设置

### 模型路径设置

```bat
@echo off
echo set models storage path to current Dir %~dp0models
SETX OLLAMA_MODELS  %~dp0models
echo setup done
timeout 5
```

> 这个脚本会将模型的存储路径放在批处理相同目录的models目录下

## 启动

### 一键启动ollam和对应模型

```cmd
@echo off
echo start ollama...
start  %~dp0ollama.exe serve
echo boot model
start %~dp0ollama.exe run phi3
```

