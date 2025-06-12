---
title: "在你的ClaudeCode中使用DeepSeek"
date: 2025-06-12T15:36:50+08:00
draft: false
tags: ["tricks"]
author: "czyt"
---

​    最近听说Claude Code很好用，但是国内很难稳定直连Claude，手上的硅基余额还有上百块，于是突发奇想，如何把手上的硅基DeepSeek用到Claude Code上。找了下，发现[Claude Code Router](https://github.com/musistudio/claude-code-router) 这个项目。下面是使用方法。
## 安装
> 你需要有nodejs这样的环境，bun没进行测试.需要安装npm或者pnpm包管理器
> 

安装 Claude Code
```bash
pnpm install -g @anthropic-ai/claude-code
```
安装 Claude Code Router
```bash
pnpm install -g @musistudio/claude-code-router
```
## 使用
在使用之前需要在您的`$HOME/.claude-code-router/`下创建`config.json`文件，下面是我使用硅基流动的一个示例
```json
{
    "OPENAI_API_KEY": "sk-xxxxxxxx",
    "OPENAI_BASE_URL": "https://api.siliconflow.cn",
    "OPENAI_MODEL": "deepseek-ai/DeepSeek-V3"
}
```
然后通过 claude-code-router启动你的Claude Code
```bash
ccr code
```

当然你也可以创建一个alias方便使用

```
alias claude='ccr code'
```

将这个加入到您的.zshrc获取.bashrc中即可。

![image-20250612155248337](https://assets.czyt.tech/img/claude-code-router-usage)
