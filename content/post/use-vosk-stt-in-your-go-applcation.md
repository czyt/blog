---
title: "在Go程序中使用Vosk进行语音识别STT"
date: 2025-03-17
draft: false
tags: ["golang","stt"]
author: "czyt"
---
## Vosk 介绍
Vosk是一款语音识别的工具包。Vosk的优势：
1. 支持二十+种语言 - 中文，英语，印度英语，德语，法语，西班牙语，葡萄牙语，俄语，土耳其语，越南语，意大利语，荷兰人，加泰罗尼亚语，阿拉伯, 希腊语, 波斯语, 菲律宾语，乌克兰语, 哈萨克语, 瑞典语, 日语, 世界语, 印地语, 捷克语, 波兰语, 乌兹别克语, 韩国语, 塔吉克语
2. 移动设备上脱机工作-Raspberry Pi，Android，iOS
3. 使用简单的 pip3 install vosk 安装
4. 每种语言的手提式模型只有是50Mb, 但还有更大的服务器模型可用
5. 提供流媒体API，以提供最佳用户体验（与流行的语音识别python包不同）
6. 还有用于不同编程语言的包装器-java / csharp / javascript等
7. 可以快速重新配置词汇以实现最佳准确性
8. 支持说话人识别

官方 https://alphacephei.com/vosk/

模型下载 https://alphacephei.com/vosk/models

## GO项目搭建

本文基于Linux，Windows请参考官方仓库的[说明](https://github.com/alphacep/vosk-api/tree/master/go/example)

### 创建go程序 

创建go程序内容如下：

```go
package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"log"
	"os"

	vosk "github.com/alphacep/vosk-api/go"
)

func main() {
	var filename string
	flag.StringVar(&filename, "f", "", "file to transcribe")
	flag.Parse()

	model, err := vosk.NewModel("model")
	if err != nil {
		log.Fatal(err)
	}

	// we can check if word is in the vocabulary
	// fmt.Println(model.FindWord("air"))

	sampleRate := 16000.0
	rec, err := vosk.NewRecognizer(model, sampleRate)
	if err != nil {
		log.Fatal(err)
	}
	rec.SetWords(1)

	file, err := os.Open(filename)
	if err != nil {
		panic(err)
	}
	defer file.Close()

	buf := make([]byte, 4096)

	for {
		_, err := file.Read(buf)
		if err != nil {
			if err != io.EOF {
				log.Fatal(err)
			}

			break
		}

		if rec.AcceptWaveform(buf) != 0 {
			fmt.Println(rec.Result())
		}
	}

	// Unmarshal example for final result
	var jres map[string]interface{}
	json.Unmarshal([]byte(rec.FinalResult()), &jres)
	fmt.Println(jres["text"])
}

```

### 下载模型

同时需要下载对应的模型，我这里使用中文的模型 https://alphacephei.com/vosk/models/vosk-model-small-cn-0.22.zip

下载好以后解压到程序目录，重命名为代码中模型目录的名字`model`

### 下载链接库

同时下载相关的链接库 ，最新的为 https://github.com/alphacep/vosk-api/releases/tag/v0.3.45 找到linux对应的[vosk-linux-x86_64-0.3.45.zip](https://github.com/alphacep/vosk-api/releases/download/v0.3.45/vosk-linux-x86_64-0.3.45.zip)然后也解压。

### 准备待识别的语音文件

需要wav格式的文件，好像mp3不能识别

### 运行和调试项目

运行下面的命令进行识别

```bash
 VOSK_PATH=`pwd`/vosk-linux-x86_64-0.3.45 LD_LIBRARY_PATH=$VOSK_PATH CGO_CPPFLAGS="-I $VOSK_PATH" CGO_LDFLAGS="-L $VOSK_PATH" go 
run . -f tiaoguo.wav
```

识别结果

```bash
LOG (VoskAPI:ReadDataFiles():model.cc:213) Decoding params beam=12 max-active=5000 lattice-beam=4
LOG (VoskAPI:ReadDataFiles():model.cc:216) Silence phones 1:2:3:4:5:6:7:8:9:10
LOG (VoskAPI:RemoveOrphanNodes():nnet-nnet.cc:948) Removed 0 orphan nodes.
LOG (VoskAPI:RemoveOrphanComponents():nnet-nnet.cc:847) Removing 0 orphan components.
LOG (VoskAPI:ReadDataFiles():model.cc:248) Loading i-vector extractor from model-small/ivector/final.ie
LOG (VoskAPI:ComputeDerivedVars():ivector-extractor.cc:183) Computing derived variables for iVector extractor
LOG (VoskAPI:ComputeDerivedVars():ivector-extractor.cc:204) Done.
LOG (VoskAPI:ReadDataFiles():model.cc:282) Loading HCL and G from model-small/graph/HCLr.fst model-small/graph/Gr.fst
LOG (VoskAPI:ReadDataFiles():model.cc:308) Loading winfo model-small/graph/phones/word_boundary.int
少爷

```

