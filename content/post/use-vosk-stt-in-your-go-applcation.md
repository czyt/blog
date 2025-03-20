---
title: "在Go程序中使用Vosk进行语音识别STT"
date: 2025-03-17
draft: false
tags: ["golang","asr"]
author: "czyt"
---
## Vosk 介绍
Vosk是一款基于[深度学习](https://cloud.baidu.com/product/wenxinworkshop)的开源语音识别工具，能够在没有云连接的情况下进行高效的离线语音识别。它通过对语音信号进行预处理、特征提取和模型推断，将语音转换成文本。Vosk不仅支持多种主流编程语言，还覆盖了20多种语言和方言，包括英语、中文、法语、德语等，为跨语言应用提供了强大的支持。

### 工作原理

Vosk的语音识别过程可以分为以下几个关键步骤：

1. **语音信号预处理**：对输入的语音信号进行去噪、增强等处理，以提高识别准确性。
2. **特征提取**：从处理后的语音信号中提取出能够表征语音特性的关键特征。
3. **模型推断**：利用预训练的深度学习模型对提取的特征进行识别，输出对应的文本。

### 优势解析

**隐私保护**：Vosk的离线特性意味着用户的语音数据不会离开设备，有效保护了用户的隐私。

**实时性**：在设备端进行语音识别，减少了网络传输时间和延迟，使得识别过程更加实时。

**跨平台**：支持Windows、Linux、macOS以及嵌入式设备等多种平台，便于在不同场景下的应用。

**可扩展性**：作为开源项目，Vosk允许开发者根据自己的需求进行定制和优化，以适应不同的应用场景。

**多语言支持**：提供对多种语言和方言的识别能力，为跨国应用提供了便利。

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

## 其他类似项目

+ [sherpa-onnx](https://github.com/k2-fsa/sherpa-onnx/tree/master/go-api-examples)
+ [FunASR](https://github.com/modelscope/FunASR)
