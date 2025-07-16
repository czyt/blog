---
title: "Zsh自动完成文件的一个例子"
date: 2025-07-16T09:41:40+08:00
draft: false
tags: ["tricks"]
author: "czyt"
---

亚马逊发布了[kiro](https://kiro.dev) ,基于Claude，于是下载安装文件，发现在它的安装文件里面有那么一个文件。

![image-20250716094659814](https://assets.czyt.tech/img/kiro-dist.png)

文件内容如下

```
#compdef kiro

local arguments

arguments=(
	'(-d --diff)'{-d,--diff}'[compare two files with each other]:file to compare:_files:file to compare with:_files'
	\*'--folder-uri[open a window with given folder uri(s)]:folder uri: '
	\*{-a,--add}'[add folder(s) to the last active window]:directory:_directories'
	'(-g --goto)'{-g,--goto}'[open a file at the path on the specified line and column position]:file\:line[\:column]:_files -r \:'
	'(-n --new-window -r --reuse-window)'{-n,--new-window}'[force to open a new window]'
	'(-n --new-window -r --reuse-window)'{-r,--reuse-window}'[force to open a file or folder in an already opened window]'
	'(-w --wait)'{-w,--wait}'[wait for the files to be closed before returning]'
	'--locale=[the locale to use (e.g. en-US or zh-TW)]:locale (e.g. en-US or zh-TW):(de en en-US es fr it ja ko ru zh-CN zh-TW bg hu pt-br tr)'
	'--user-data-dir[specify the directory that user data is kept in]:directory:_directories'
	'(- *)'{-v,--version}'[print version]'
	'(- *)'{-h,--help}'[print usage]'
	'--telemetry[show all telemetry events which VS code collects]'
	'--extensions-dir[set the root path for extensions]:root path:_directories'
	'--list-extensions[list the installed extensions]'
	'--category[filters installed extension list by category, when using --list-extensions]'
	'--show-versions[show versions of installed extensions, when using --list-extensions]'
	'--install-extension[install an extension]:id or path:_files -g "*.vsix(-.)"'
	'--uninstall-extension[uninstall an extension]:id or path:_files -g "*.vsix(-.)"'
	'--update-extensions[update the installed extensions]'
	'--enable-proposed-api[enables proposed API features for extensions]::extension id: '
	'--verbose[print verbose output (implies --wait)]'
	'--log[log level to use]:level [info]:(critical error warn info debug trace off)'
	'(-s --status)'{-s,--status}'[print process usage and diagnostics information]'
	'(-p --performance)'{-p,--performance}'[start with the "Developer: Startup Performance" command enabled]'
	'--prof-startup[run CPU profiler during startup]'
	'(--disable-extension --disable-extensions)--disable-extensions[disable all installed extensions]'
	\*'--disable-extension[disable an extension]:extension id: '
	'--inspect-extensions[allow debugging and profiling of extensions]'
	'--inspect-brk-extensions[allow debugging and profiling of extensions with the extension host being paused after start]'
	'--disable-gpu[disable GPU hardware acceleration]'
	'*:file or directory:_files'
)

_arguments -s -S $arguments

```

然后让claude 4.0来讲解下自动完成文件的编写实践。

> 试了下月之暗面的Kimi K2 跟claude的结果还是有差距。

## 一、文件结构与工作原理

### 1. 文件头声明
```zsh
#compdef kiro
```
- `#compdef` 告诉 zsh 这是一个补全定义文件
- `kiro` 指定这个补全适用于 `kiro` 命令
- 可以同时支持多个命令：`#compdef kiro code vscode`

### 2. 基本结构
```zsh
local arguments          # 声明局部变量
arguments=(              # 定义参数规则数组
    # 各种补全规则...
)
_arguments -s -S $arguments  # 执行补全
```

## 二、规则语法详解

### 1. 基本格式
```
[修饰符]选项定义[帮助文本][:消息:动作:补全函数]
```

### 2. 修饰符详解

#### 互斥组 `()`
```zsh
'(-d --diff)'{-d,--diff}'[描述]'
```
- 表示 `-d` 和 `--diff` 互斥（实际上它们是同一个选项）
- `(- *)` 表示与所有其他选项互斥

#### 重复修饰符 `*` 和 `\*`
```zsh
\*{-a,--add}'[可重复使用的选项]'
\*'--disable-extension[可多次禁用扩展]'
```
- `\*` 表示选项可以多次使用
- `*` 在行首表示匹配任意位置的参数

#### 选项组合
```zsh
'(-n --new-window -r --reuse-window)'{-n,--new-window}'[强制新窗口]'
'(-n --new-window -r --reuse-window)'{-r,--reuse-window}'[重用窗口]'
```
- 两个选项互斥，只能选择其中一个

### 3. 参数补全语法

#### 三段式格式：`消息:动作:补全函数`
```zsh
':file to compare:_files:file to compare with:_files'
```

#### 常用补全函数
- `_files` - 补全文件名
- `_directories` - 补全目录名
- `_files -g "*.vsix(-.)"` - 补全特定扩展名的文件

#### 静态选择列表
```zsh
'--log[日志级别]:(critical error warn info debug trace off)'
```

## 三、具体规则解析

### 1. 文件比较选项
```zsh
'(-d --diff)'{-d,--diff}'[compare two files with each other]:file to compare:_files:file to compare with:_files'
```
- 互斥组：`(-d --diff)`
- 选项名：`{-d,--diff}`
- 帮助文本：`[compare two files with each other]`
- 需要两个文件参数，都用 `_files` 补全

### 2. 带等号的选项
```zsh
'--locale=[locale]:locale (e.g. en-US or zh-TW):(de en en-US es fr it ja ko ru zh-CN zh-TW bg hu pt-br tr)'
```
- `=` 表示参数紧跟在选项后面
- 提供了预定义的选择列表

### 3. 可选参数
```zsh
'--enable-proposed-api[enables proposed API features for extensions]::extension id: '
```
- `::` 表示参数是可选的（而不是必需的）

### 4. 文件过滤补全
```zsh
'--install-extension[install an extension]:id or path:_files -g "*.vsix(-.)"'
```
- `_files -g "*.vsix(-.)"` 只补全 `.vsix` 文件
- `(-.)` 表示只匹配普通文件，不匹配目录

### 5. 特殊文件路径补全
```zsh
'(-g --goto)'{-g,--goto}'[open file at line:column]:file\:line[\:column]:_files -r \:'
```
- `_files -r \:` 告诉补全器冒号是文件名的一部分
- 支持 `file:line:column` 格式

## 四、_arguments 参数详解

```zsh
_arguments -s -S $arguments
```

### 常用选项：
- `-s` 允许短选项堆叠（如 `-abc` 等同于 `-a -b -c`）
- `-S` 不要对 `--` 后的参数进行选项解析
- `-A` 即使有未识别的选项也不要补全
- `-C` 修改当前上下文

## 五、高级技巧

### 1. 动态补全
```zsh
# 获取已安装扩展列表
'--uninstall-extension[uninstall extension]:extension:($(code --list-extensions 2>/dev/null))'
```

### 2. 条件补全
```zsh
# 只在特定条件下才补全
'(--list-extensions)--show-versions[show versions when listing]'
```

### 3. 自定义补全函数
```zsh
_kiro_extensions() {
    local extensions=($(kiro --list-extensions 2>/dev/null))
    _describe 'extensions' extensions
}

# 在规则中使用
'--disable-extension[disable extension]:extension:_kiro_extensions'
```

## 六、安装和使用

### 1. 文件放置
```zsh
# 系统级
/usr/share/zsh/site-functions/_kiro

# 用户级
~/.zsh/functions/_kiro
mkdir -p ~/.zsh/functions
echo 'fpath=(~/.zsh/functions $fpath)' >> ~/.zshrc
```

### 2. 重新加载补全
```zsh
# 清除缓存
rm -f ~/.zcompdump*

# 重新初始化
autoload -Uz compinit && compinit
```

### 3. 测试补全
```zsh
kiro <TAB>           # 显示所有可用选项
kiro --<TAB>         # 显示长选项
kiro --diff <TAB>    # 补全文件名
```

## 七、调试技巧

### 1. 启用调试模式
```zsh
# 查看补全过程
zstyle ':completion:*' verbose true

# 显示补全匹配详情
zstyle ':completion:*' format 'Completing %d'
```

### 2. 测试单个规则
```zsh
# 临时测试
_arguments '(-d --diff)'{-d,--diff}'[test]:file:_files'
```

### 3. 查看已加载的补全
```zsh
# 查看函数定义
which _kiro

# 查看所有可用补全
compgen -A function | grep ^_
```

## 八、常见问题和解决方案

### 1. 补全不工作
- 检查文件权限：`chmod 644 _kiro`
- 确认文件在 `$fpath` 中：`echo $fpath`
- 重新初始化：`compinit`

### 2. 语法错误
- 检查引号匹配
- 确认转义字符正确：`\*` vs `*`
- 验证数组语法

### 3. 补全不准确
- 检查互斥组定义
- 确认补全函数正确
- 测试正则表达式

这个补全文件是一个相当完整的例子，展示了 zsh 补全系统的强大功能。通过理解这些概念和技巧，你可以为任何命令行工具创建强大的自动补全功能。