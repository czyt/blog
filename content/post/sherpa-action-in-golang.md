---
title: "Sherpa Go语言实战"
date: 2025-03-20
draft: false
tags: ["tts","kws","golang"]
author: "czyt"

---

## 简介

sherpa 是 [`Next-gen Kaldi`](https://k2-fsa.org/zh-CN/) 项目的部署框架。

## 使用

### VAD

语音活动检测（Voice Activity Detection，简称VAD）是一种技术，用于检测音频信号中是否存在语音或其他声音活动。它在语音处理、语音识别、音频压缩等领域有广泛的应用。

#### VAD的主要功能

- **语音识别系统**：通过VAD，系统可以在检测到语音时启动识别过程，提高效率。
- **音频压缩**：在语音通信中，VAD可以帮助压缩算法仅对有效语音信号进行压缩，减少传输数据量。
- **噪声抑制系统**：通过检测语音活动，系统可以在静默时段增强噪声抑制效果。

#### 在GO中使用

todo

### KWS

关键词唤醒（Keyword Spotting，简称KWS）是一种技术，用于检测音频信号中特定的关键词或短语。它广泛应用于语音助手、智能家居设备、车载系统等领域，通过识别特定关键词来激活设备或执行特定命令。

#### 主要功能

- **关键词检测**：识别音频信号中是否包含预定义的关键词或短语。
- **唤醒设备**：当检测到关键词时，激活设备或应用程序。
- **提高用户体验**：通过语音命令简化操作流程，增强用户体验。

#### 自定义keywords

通过官方的工具sherpa-onnx-cli，可以实现自定义关键字，下面是简单的介绍 [原文](https://k2-fsa.github.io/sherpa/onnx/kws/index.html)

```bash
# Note: You need to run pip install sherpa-onnx to get the commandline tool: sherpa-onnx-cli


sherpa-onnx-cli text2token --help
Usage: sherpa-onnx-cli text2token [OPTIONS] INPUT OUTPUT

Options:

  --text TEXT         Path to the input texts. Each line in the texts contains the original phrase, it might also contain some extra items,
                      for example, the boosting score (startting with :), the triggering threshold
                      (startting with #, only used in keyword spotting task) and the original phrase (startting with @).
                      Note: extra items will be kept in the output.

                      example input 1 (tokens_type = ppinyin):
                          小爱同学 :2.0 #0.6 @小爱同学
                          你好问问 :3.5 @你好问问
                          小艺小艺 #0.6 @小艺小艺
                      example output 1:
                          x iǎo ài tóng x ué :2.0 #0.6 @小爱同学
                          n ǐ h ǎo w èn w èn :3.5 @你好问问
                          x iǎo y ì x iǎo y ì #0.6 @小艺小艺

                      example input 2 (tokens_type = bpe):
                          HELLO WORLD :1.5 #0.4
                          HI GOOGLE :2.0 #0.8
                          HEY SIRI #0.35
                      example output 2:
                          ▁HE LL O ▁WORLD :1.5 #0.4
                          ▁HI ▁GO O G LE :2.0 #0.8
                          ▁HE Y ▁S I RI #0.35

  --tokens TEXT       The path to tokens.txt.
  --tokens-type TEXT  The type of modeling units, should be cjkchar, bpe, cjkchar+bpe, fpinyin or ppinyin.
                      fpinyin means full pinyin, each cjkchar has a pinyin(with tone). ppinyin
                      means partial pinyin, it splits pinyin into initial and final,
  --bpe-model TEXT    The path to bpe.model. Only required when tokens-type is bpe or cjkchar+bpe.
  --help              Show this message and exit.
```

我这里只是记录下`小爱同学 :2.0 #0.6 @小爱同学` 这部分。在这个例子里面`:数字` 是增强得分（boosting score），`#数字` 是触发阈值（triggering threshold）。

关于关键词识别中增强得分和触发阈值的优化技巧，我从AI那里获取了一些建议：

##### 增强得分(Boosting Score)优化技巧

1. **优先级分配**：
   - 为重要指令设置更高的增强得分（如"暂停"、"结束"可设为3.0-4.0）
   - 为常用指令设置中等增强得分（如"开始"、"跳过"可设为2.0-2.5）
   - 为非关键指令设置较低增强得分（如"确认"、"是"可设为1.0-1.5）

2. **长短句区分**：
   - 短词通常需要更高的增强得分，因为它们更容易被误触发（如单字词"是"、"否"可设为3.0）
   - 较长的短语可以使用相对较低的增强得分（如"跳过这个动作"可设为1.5-2.0）

3. **音素相似性处理**：
   - 对于音素相似的关键词，可以为更重要的词设置更高的增强得分
   - 例如，"开始"和"结束"音素差异大，但"暂停"和"跳过"部分音素相似，可适当调整

##### 触发阈值(Triggering Threshold)优化技巧

1. **重要性区分**：
   - 紧急指令（如"结束"、"暂停"）可设置较低的触发阈值（如#0.5），使其更容易被触发
   - 非紧急指令可设置较高的阈值（如#0.7），避免误触发

2. **环境适应**：
   - 在噪音大的环境中使用时，可增加阈值（如#0.7-0.8）减少误触发
   - 在安静环境中，可适当降低阈值（如#0.5-0.6）提高响应速度

3. **常用性考虑**：
   - 常用指令可设置适中的阈值（如#0.6）
   - 不常用但重要的指令可设置较低的阈值（如#0.5）确保在需要时能被识别

##### 测试和优化方法

1. **渐进式调整**：
   - 从默认值开始（如增强得分:2.0，阈值#0.6）
   - 在真实使用场景中测试并记录误触发和漏触发情况
   - 基于测试结果逐步调整参数

2. **交叉测试**：
   - 在不同环境下（安静/嘈杂）进行测试
   - 由不同人（不同口音、性别）测试同一组关键词
   - 综合调整达到最佳平衡

3. **优先级矩阵**：
   创建类似下面的优先级矩阵来分配参数：

   | 关键词优先级 | 低噪音环境 | 中噪音环境 | 高噪音环境 |
   |------------|-----------|-----------|-----------|
   | 高优先级    | :3.0 #0.5 | :3.5 #0.6 | :4.0 #0.7 |
   | 中优先级    | :2.0 #0.5 | :2.5 #0.6 | :3.0 #0.7 |
   | 低优先级    | :1.5 #0.6 | :2.0 #0.7 | :2.5 #0.8 |

根据具体应用场景，建议从中等参数开始（如:2.0 #0.6），然后根据实际表现进行微调。最终目标是在减少误触发的同时保证必要指令能被可靠识别。

### ASR

自动语音识别（Automatic Speech Recognition，简称ASR）是一种技术，用于将口语转换为文本或命令。它广泛应用于语音助手、语音输入系统、语音控制设备等领域，通过识别语音内容来执行相应的操作。

#### 主要功能

- **语音转文本**：将口语转换为对应的文本信息。
- **语音命令识别**：识别语音中的命令或指令，并执行相应的操作。
- **提高效率**：通过语音输入简化操作流程，提高用户效率。

### TTS

文本转语音（Text-to-Speech，简称TTS）是一种技术，用于将文本信息转换为合成语音。它广泛应用于语音助手、有声读物、导航系统等领域，通过合成语音来传达信息。

#### 主要功能

- **文本转换**：将输入的文本转换为自然语音。
- **语音合成**：使用算法生成类似人类的声音。
- **提高可访问性**：通过TTS技术，视障人士可以更方便地获取信息。
