---
title: "Claude Code使用笔记"
date: 2025-06-12T15:36:50+08:00
draft: false
tags: ["tricks","claude-code"]
author: "czyt"
---

## 安装
> 你需要有nodejs这样的环境，bun没进行测试.需要安装npm或者pnpm包管理器
> 

### 安装 Claude Code

```bash
pnpm install -g @anthropic-ai/claude-code
```

### Claude Code Router使用

虽说[Claude Code](https://docs.anthropic.com/zh-CN/docs/claude-code/overview)很好用，但是国内很难稳定直连Claude，手上的硅基余额还有上百块，于是突发奇想，如何把手上的硅基DeepSeek用到Claude Code上。找了下，发现[Claude Code Router](https://github.com/musistudio/claude-code-router) 这个项目。安装方法：

```bash
pnpm install -g @musistudio/claude-code-router
```
## 配置
### Claude Code

正常使用，直接登录即可。当然，也可以使用[anyrouter](https://anyrouter.top/register?aff=myZ5) 这样的在线服务，配合calude使用即可，只要在您的.zsrhrc中加入下面的一个函数.

```bash
function set_claude(){
 export ANTHROPIC_AUTH_TOKEN=sk-xxxxxxx<改成您自己的key>
 export ANTHROPIC_BASE_URL=https://anyrouter.top
}
```

然后在调用claude之前set_claude即可。

claude Code可以设置自动更新

```bash
claude config set autoUpdates true --global
```

Claude Code运行需要一直确认。 每次都选择第一项或第二项，和让程序自动运行差不多。 如果想绕过确认，可在终端执行指令：

 ```bash
 bashclaude --dangerously-skip-permissions
 ```

为了方便使用，可加个别名：

```bash
alias cc="claude --dangerously-skip-permissions"
```

 只有输入cc时才启动这个模式。对于不需要交互的场景，可以使用下面的别名：

```bash
 alias ccp="claude --dangerously-skip-permissions -p"
```



### Claude Code Router

![image-20250612155248337](https://assets.czyt.tech/img/claude-code-router-usage)

在使用之前需要在您的`$HOME/.claude-code-router/`下创建`config.json`文件，下面是我使用

硅基流动示例 [邀请注册](https://cloud.siliconflow.cn/i/a7NqR0rS)

```json
{
    "OPENAI_API_KEY": "sk-xxxxxxxx",
    "OPENAI_BASE_URL": "https://api.siliconflow.cn",
    "OPENAI_MODEL": "deepseek-ai/DeepSeek-V3"
}
```
使用火山引擎的示例

```json
{
    "LOG": true,
    "OPENAI_API_KEY": "xxxxx",
    "OPENAI_BASE_URL": "https://ark.cn-beijing.volces.com/api/v3/",
    "OPENAI_MODEL": "deepseek-v3-250324"
}
```

使用OpenRouter的Kimi K2的例子

```json
{
  "Providers": [
    {
      "name": "kimi-k2",
      "api_base_url": "https://openrouter.ai/api/v1/chat/completions",
      "api_key": "OPENROUTER_API_KEY",
      "models": [
        "moonshotai/kimi-k2"
      ],
      "transformer": {
        "use": ["openrouter"]
      }
    }
  ],
  "Router": {
    "default": "kimi-k2,moonshotai/kimi-k2"
  }
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

### Kimi K2

Kimi K2直接支持在Calude Code中使用

```bash
export ANTHROPIC_AUTH_TOKEN=你的月之暗面 API Key
export ANTHROPIC_BASE_URL=https://api.moonshot.ai/anthropic
claude
```

> 月之暗面的API KEY获取途径：登录[月之暗面开发者平台](https://platform.moonshot.cn/console/account),创建 API Key即可。

## Github集成

首先先安装ClaudeCode到您的GitHub上去，[安装地址](https://github.com/apps/claude)。

然后找到对应的项目，配置项目的 Secrets，注意要配置

`ANTHROPIC_BASE_URL` 和 `CLAUDE_CODE_OAUTH_TOKEN`,假如您使用国内的月之暗面，大致就是这样的

```
ANTHROPIC_BASE_URL  → https://api.moonshot.cn/anthropic
CLAUDE_CODE_OAUTH_TOKEN →sk-xxxx
```

使用openrouter的api可以参考[这个项目](https://github.com/luohy15/y-router)

下面是一个GitHub Action的例子

```yaml
name: Claude Code

on:
  issue_comment:
    types: [created]
  pull_request_review_comment:
    types: [created]
  issues:
    types: [opened, assigned]
  pull_request_review:
    types: [submitted]

jobs:
  claude:
    if: |
      (github.event_name == 'issue_comment' && contains(github.event.comment.body, '@claude')) ||
      (github.event_name == 'pull_request_review_comment' && contains(github.event.comment.body, '@claude')) ||
      (github.event_name == 'pull_request_review' && contains(github.event.review.body, '@claude')) ||
      (github.event_name == 'issues' && (contains(github.event.issue.body, '@claude') || contains(github.event.issue.title, '@claude')))
    runs-on: ubuntu-latest
    permissions:
      contents: read
      pull-requests: read
      issues: read
      id-token: write
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
        with:
          fetch-depth: 1
      - name: Run Claude Code
        id: claude
        uses: anthropics/claude-code-action@beta
        env:
          ANTHROPIC_BASE_URL: "${{ secrets.ANTHROPIC_BASE_URL }}"
        with:
          claude_code_oauth_token: ${{ secrets.CLAUDE_CODE_OAUTH_TOKEN }}
```
## claudeCode MCP

可以安装一些mcp来优化体验

context7

```bash
claude mcp add context7 -- npx -y @upstash/context7-mcp@latest
```

Sequential Thinking

```bash
claude mcp add  server-sequential-thinking -- npx -y @modelcontextprotocol/server-sequential-thinking@latest
```

DeepWiki

```bash
claude mcp add  mcp-deepwiki -- npx -y mcp-deepwiki@latest
```

