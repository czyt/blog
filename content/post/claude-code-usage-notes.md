---
title: "Claude Code使用笔记"
date: 2025-06-12T15:36:50+08:00
draft: false
tags: ["tricks","claude-code"]
author: "czyt"
---

> 来自https://x.com/shao__meng/status/1950196917595754662的ClaudeCode技巧

![image-20250730111459693](https://assets.czyt.tech/img/claude-code-tricks.png)

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

正常使用，直接登录即可。也可以参考某claude code镜像提供商家的代码

setup-claude-code.sh

```bash
#!/bin/bash

# Claude Code Configuration Script for YesCode
# This script configures Claude Code to use your YesCode instance

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DEFAULT_BASE_URL="https://co.yes.vg"
CLAUDE_CONFIG_DIR="$HOME/.claude"
CLAUDE_SETTINGS_FILE="$CLAUDE_CONFIG_DIR/settings.json"

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if jq is installed
check_jq() {
    if ! command -v jq &> /dev/null; then
        print_error "jq is required but not installed."
        print_info "Please install jq:"
        print_info "  macOS: brew install jq"
        print_info "  Ubuntu/Debian: sudo apt-get install jq"
        print_info "  CentOS/RHEL: sudo yum install jq"
        exit 1
    fi
}

# Function to backup existing settings
backup_settings() {
    if [ -f "$CLAUDE_SETTINGS_FILE" ]; then
        local backup_file="${CLAUDE_SETTINGS_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$CLAUDE_SETTINGS_FILE" "$backup_file"
        print_info "Backed up existing settings to: $backup_file"
    fi
}

# Function to create settings directory
create_settings_dir() {
    if [ ! -d "$CLAUDE_CONFIG_DIR" ]; then
        mkdir -p "$CLAUDE_CONFIG_DIR"
        print_info "Created Claude configuration directory: $CLAUDE_CONFIG_DIR"
    fi
}

# Function to validate API key format
validate_api_key() {
    local api_key="$1"
    if [[ ! "$api_key" =~ ^[A-Za-z0-9_-]+$ ]]; then
        print_error "Invalid API key format. API key should contain only alphanumeric characters, hyphens, and underscores."
        return 1
    fi
    return 0
}

# Function to test API connection
test_api_connection() {
    local base_url="$1"
    local api_key="$2"
    
    print_info "Testing API connection..."
    
    # Test a simple request to the API
    local response
    response=$(curl -s -w "%{http_code}" -o /tmp/claude_test_response \
        -X GET "$base_url/api/v1/claude/balance" \
        -H "Content-Type: application/json" \
        -H "X-API-Key: $api_key" \
        2>/dev/null || echo "000")
    
    if [ "$response" = "200" ]; then
        local balance
        balance=$(cat /tmp/claude_test_response | jq -r '.balance' 2>/dev/null || echo "unknown")
        print_success "API connection successful! Current balance: \$${balance}"
        rm -f /tmp/claude_test_response
        return 0
    elif [ "$response" = "401" ]; then
        print_error "API key authentication failed. Please check your API key."
        rm -f /tmp/claude_test_response
        return 1
    elif [ "$response" = "000" ]; then
        print_error "Cannot connect to API server. Please check the URL and your internet connection."
        rm -f /tmp/claude_test_response
        return 1
    else
        print_error "API test failed with HTTP status: $response"
        rm -f /tmp/claude_test_response
        return 1
    fi
}

# Function to create Claude Code settings
create_settings() {
    local base_url="$1"
    local api_key="$2"
    
    local settings_json
    settings_json=$(cat <<EOF
{
  "env": {
    "ANTHROPIC_BASE_URL": "$base_url",
    "ANTHROPIC_AUTH_TOKEN": "$api_key",
    "CLAUDE_CODE_MAX_OUTPUT_TOKENS": 20000,
    "DISABLE_TELEMETRY": 1,
    "DISABLE_ERROR_REPORTING": 1,
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": 1,
    "CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR": 1,
    "MAX_THINKING_TOKENS": 12000
  },
  "permissions": {
    "allow": [
      "Bash(*)",
      "LS(*)",
      "Read(*)",
      "Write(*)",
      "Edit(*)",
      "MultiEdit(*)",
      "Glob(*)",
      "Grep(*)",
      "Task(*)",
      "WebFetch(*)",
      "WebSearch(*)",
      "TodoWrite(*)",
      "NotebookRead(*)",
      "NotebookEdit(*)"
    ],
    "deny": []
  },
  "model": "sonnet"
}
EOF
    )
    
    # Validate JSON
    if ! echo "$settings_json" | jq . > /dev/null 2>&1; then
        print_error "Generated settings JSON is invalid"
        return 1
    fi
    
    # Write settings file
    echo "$settings_json" > "$CLAUDE_SETTINGS_FILE"
    print_success "Claude Code settings written to: $CLAUDE_SETTINGS_FILE"
}

# Function to display current settings
display_settings() {
    if [ -f "$CLAUDE_SETTINGS_FILE" ]; then
        print_info "Current Claude Code settings:"
        echo "----------------------------------------"
        cat "$CLAUDE_SETTINGS_FILE" | jq .
        echo "----------------------------------------"
    else
        print_info "No existing Claude Code settings found."
    fi
}

# Main function
main() {
    print_info "Claude Code Configuration Script for YesCode"
    echo "======================================================="
    echo
    
    # Check dependencies
    check_jq
    
    # Parse command line arguments
    local base_url=""
    local api_key=""
    local test_only=false
    local show_settings=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -u|--url)
                base_url="$2"
                shift 2
                ;;
            -k|--key)
                api_key="$2"
                shift 2
                ;;
            -t|--test)
                test_only=true
                shift
                ;;
            -s|--show)
                show_settings=true
                shift
                ;;
            -h|--help)
                cat <<EOF
Usage: $0 [OPTIONS]

Options:
  -u, --url URL     Set the YesCode base URL (default: $DEFAULT_BASE_URL)
  -k, --key KEY     Set the API key
  -t, --test        Test API connection only (requires -u and -k)
  -s, --show        Show current settings and exit
  -h, --help        Show this help message

Examples:
  $0 --url https://co.yes.vg --key your-api-key-here
  $0 --test --url https://co.yes.vg --key your-api-key-here
  $0 --show

Interactive mode (no arguments):
  $0
EOF
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                print_info "Use --help for usage information"
                exit 1
                ;;
        esac
    done
    
    # Show settings and exit if requested
    if [ "$show_settings" = true ]; then
        display_settings
        exit 0
    fi
    
    # Interactive mode if no arguments provided
    if [ -z "$base_url" ] && [ -z "$api_key" ]; then
        print_info "Interactive setup mode"
        echo
        
        # Get base URL
        read -p "Enter YesCode URL [$DEFAULT_BASE_URL]: " base_url
        if [ -z "$base_url" ]; then
            base_url="$DEFAULT_BASE_URL"
        fi
        
        # Get API key
        while [ -z "$api_key" ]; do
            read -p "Enter your API key: " api_key
            if [ -z "$api_key" ]; then
                print_warning "API key is required"
            elif ! validate_api_key "$api_key"; then
                api_key=""
            fi
        done
    fi
    
    # Validate inputs
    if [ -z "$base_url" ] || [ -z "$api_key" ]; then
        print_error "Both URL and API key are required"
        print_info "Use --help for usage information"
        exit 1
    fi
    
    # Validate API key
    if ! validate_api_key "$api_key"; then
        exit 1
    fi
    
    # Remove trailing slash from URL
    base_url="${base_url%/}"
    
    print_info "Configuration:"
    print_info "  Base URL: $base_url"
    print_info "  API Key: ${api_key:0:8}...${api_key: -4}"
    echo
    
    # Test API connection
    if ! test_api_connection "$base_url" "$api_key"; then
        if [ "$test_only" = true ]; then
            exit 1
        fi
        
        read -p "API test failed. Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Setup cancelled"
            exit 1
        fi
    fi
    
    # Exit if test only
    if [ "$test_only" = true ]; then
        print_success "API test completed successfully"
        exit 0
    fi
    
    # Create settings directory
    create_settings_dir
    
    # Backup existing settings
    backup_settings
    
    # Create new settings
    if create_settings "$base_url" "$api_key"; then
        echo
        print_success "Claude Code has been configured successfully!"
        print_info "You can now use Claude Code with your API router."
        print_info ""
        print_info "To verify the setup, run:"
        print_info "  claude --version"
        print_info ""
        print_info "Configuration file location: $CLAUDE_SETTINGS_FILE"
        
        if [ -f "$CLAUDE_SETTINGS_FILE" ]; then
            echo
            print_info "Current settings:"
            cat "$CLAUDE_SETTINGS_FILE" | jq .
        fi
    else
        print_error "Failed to create Claude Code settings"
        exit 1
    fi
}

# Run main function
main "$@"
```

使用方式

```bash
./setup-claude-code.sh --url https://co.yes.vg --key cr_xxxxxxxxxx
```

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

[魔搭社区](https://modelscope.cn)

```json
{
  "Providers": [
    {
      "name": "modelscope",
      "api_base_url": "https://api-inference.modelscope.cn/v1/chat/completions",
      "api_key": "xxxx",
      "models": ["Qwen/Qwen3-Coder-480B-A35B-Instruct"],
      "transformer": {
        "use": [
          [
            "maxtoken",
            {
              "max_tokens": 65536
            }
          ],
          "enhancetool"
        ]
      }
    }
  ],
  "Router": {
    "default": "modelscope,Qwen/Qwen3-Coder-480B-A35B-Instruct"
  },
  "HOST": "127.0.0.1",
  "LOG": true
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

#### qwen-code

正常安装和使用qwen-code

```bash
npm install -g @qwen-code/qwen-code@latest
qwen --version
```

需要在`~/.claude-code-router/plugins` 下面创建**[qwen-cli.js](https://gist.github.com/musistudio/f5a67841ced39912fd99e42200d5ca8b)** 的插件，然后再到`~/.claude-code-router`下面的`config.json`创建对应的transformer以及provider

```json
{
    "LOG": true,
    "CLAUDE_PATH": "",
    "HOST": "0.0.0.0",
    "PORT": 3456,
    "APIKEY": "sk-czyt",
    "API_TIMEOUT_MS": "600000",
    "PROXY_URL": "",
    "transformers": [
        {
            "path": "/Users/czyt/.claude-code-router/plugins/qwen-cli.js"
        }
    ],
    "Providers": [
        {
            "name": "qwen-cli",
            "api_base_url": "https://portal.qwen.ai/v1/chat/completions",
            "api_key": "sk-czyt",
            "models": ["qwen3-coder-plus"],
            "transformer": {
                "use": ["qwen-cli"],
                "qwen3-coder-plus": { "use": ["enhancetool"] }
            }
        }
    ],
    "Router": {
        "default": "qwen-cli,qwen3-coder-plus",
        "background": "",
        "think": "",
        "longContext": "",
        "longContextThreshold": 60000,
        "webSearch": ""
    }
}
```

> 上面提到的js的内容
>
> ```javascript
> const os = require("os");
> const path = require("path");
> const fs = require("fs/promises");
> 
> const OAUTH_FILE = path.join(os.homedir(), ".qwen", "oauth_creds.json");
> 
> class QwenCLITransformer {
>   name = "qwen-cli";
> 
>   async transformRequestIn(request, provider) {
>     if (!this.oauth_creds) {
>       await this.getOauthCreds();
>     }
>     if (this.oauth_creds && this.oauth_creds.expiry_date < +new Date()) {
>       await this.refreshToken(this.oauth_creds.refresh_token);
>     }
>     return {
>       body: request,
>       config: {
>         headers: {
>           Authorization: `Bearer ${this.oauth_creds.access_token}`,
>         },
>       },
>     };
>   }
> 
>   refreshToken(refresh_token) {
>     const urlencoded = new URLSearchParams();
>     urlencoded.append("client_id", "f0304373b74a44d2b584a3fb70ca9e56");
>     urlencoded.append("refresh_token", refresh_token);
>     urlencoded.append("grant_type", "refresh_token");
>     return fetch("https://chat.qwen.ai/api/v1/oauth2/token", {
>       method: "POST",
>       headers: {
>         "Content-Type": "application/json",
>       },
>       body: urlencoded,
>     })
>       .then((response) => response.json())
>       .then(async (data) => {
>         data.expiry_date =
>           new Date().getTime() + data.expires_in * 1000 - 1000 * 60;
>         data.refresh_token = refresh_token;
>         delete data.expires_in;
>         this.oauth_creds = data;
>         await fs.writeFile(OAUTH_FILE, JSON.stringify(data, null, 2));
>       });
>   }
> 
>   async getOauthCreds() {
>     try {
>       const data = await fs.readFile(OAUTH_FILE);
>       this.oauth_creds = JSON.parse(data);
>     } catch (e) {}
>   }
> }
> 
> module.exports = QwenCLITransformer;
> ```
>
> 

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
## 复现 Kiro 的 Spec 工作流

核心提示词

````
<workflow>
1. 每当我输入新的需求的时候，为了规范需求质量和验收标准，你首先会搞清楚问题和需求
2. 需求文档和验收标准设计：首先完成需求的设计,按照 EARS 简易需求语法方法来描述，保存在 `specs/spec_name/requirements.md` 中，跟我进行确认，最终确认清楚后，需求定稿，参考格式如下

```markdown
# 需求文档

## 介绍

需求描述

## 需求

### 需求 1 - 需求名称

**用户故事：** 用户故事内容

#### 验收标准

1. 采用 ERAS 描述的子句 While <可选前置条件>, when <可选触发器>, the <系统名称> shall <系统响应>，例如 When 选择"静音"时，笔记本电脑应当抑制所有音频输出。
2. ...
...
```
2. 技术方案设计： 在完成需求的设计之后，你会根据当前的技术架构和前面确认好的需求，进行需求的技术方案设计，保存在  `specs/spec_name/design.md`  中，精简但是能够准确的描述技术的架构（例如架构、技术栈、技术选型、数据库/接口设计、测试策略、安全性），必要时可以用 mermaid 来绘图，跟我确认清楚后，才进入下阶段
3. 任务拆分：在完成技术方案设计后，你会根据需求文档和技术方案，细化具体要做的事情，保存在`specs/spec_name/tasks.md` 中, 跟我确认清楚后，才开始正式执行任务，同时更新任务的状态

格式如下

``` markdown
# 实施计划

- [ ] 1. 任务信息
- 具体要做的事情
- ...
- _需求: 相关的需求点的编号

```
</workflow>
````

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

## 国内厂商的Calude Code配置

国内的API厂商已经提供了Claude格式的API端点，可以直接通过环境变量配置使用。

### 智谱AI

```bash
export ANTHROPIC_BASE_URL=https://open.bigmodel.cn/api/anthropic
export ANTHROPIC_AUTH_TOKEN="你的 API"
```

获取apikey[地址](https://bigmodel.cn/usercenter/proj-mgmt/apikeys)

[我的邀请注册地址](https://www.bigmodel.cn/invite?icode=Y%2B9%2Fq2VTKquO2qR%2BYhdY4%2F2gad6AKpjZefIo3dVEQyA%3D)

### Kimi K2

Kimi K2直接支持在Calude Code中使用

```bash
export ANTHROPIC_AUTH_TOKEN=你的月之暗面 API Key
export ANTHROPIC_BASE_URL=https://api.moonshot.ai/anthropic
claude
```

> 月之暗面的API KEY获取途径：登录[月之暗面开发者平台](https://platform.moonshot.cn/console/account),创建 API Key即可。



## 其他技巧

> 转自x [原文链接](https://x.com/dngzsn37461/status/1951204841482756170)

+ `claude-code --context-aware analyze`：项目上下文分析深入10倍！   
+  `Ctrl+Shift+A` + `claude explain`：瞬间解析代码+性能风险！ 
+ `CLAUDE_DEBUG_MODE=true`：查看Claude的思考与决策逻辑！
+ `claude-code refactor --pattern="legacy/*"`：一键现代化旧代码库！
+  `.claude-ignore`：自动清理无用依赖，项目体积减30%！
+  `claude-code profile --deep-analysis`：发现隐藏性能瓶颈！
+ `.claude-config.json`：统一团队代码风格，智能优化建议！
+ `claude-code sync --workspace-mode`：多项目API自动同步！
+  `// @claude`：注释生成中间件或优化数据库查询！   
+ `claude-code debug --trace-execution`：定位Bug+完整推理过程！

以及下面的这些仓库

+ https://github.com/wasabeef/claude-code-cookbook
+ https://github.com/davepoon/claude-code-subagents-collection
+ https://github.com/zebbern/claude-code-guide
+ https://github.com/iannuttall/claude-agents
+ https://github.com/FradSer/dotclaude

## 其他的一些工具

+ https://github.com/charmbracelet/crush
+ https://github.com/build-with-groq/groq-code-cli
