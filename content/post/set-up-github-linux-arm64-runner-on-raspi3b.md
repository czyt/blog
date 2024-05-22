---
title: "在树莓派3b上搭建GitHub Linux arm64 runner"
date: 2024-05-22
tags: ["github", "linux"]
draft: false
---
最近需要在GitHub Action上自动构建一些软件，但是Github 不提供Arm64的runner，自能自建。
## 树莓派设置
### 安装基本软件
#### 编译相关的软件
安装下面的这些软件，不同的构建可能有所区别：
```bash
sudo pacman -S curl zip unzip tar cmake ninja
```
#### docker
Github Action 依赖于docker，所以我们需要安装好docker
```bash
sudo pacman -S docker
```
然后将当前用户添加到docker的组
```bash
sudo usermod -aG docker $USER
```
查看和确认:
```bash
grep docker /etc/group 
```

### 权限确认

请确认要安装runner的目录，当前用户有相应的权限。runner是不允许以root身份运行的。所以在安装runner之前最好选择一个当前用户用完整权限的目录。

## 安装Runner

更详细的安装文档，请参考[GIthub](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/about-self-hosted-runners)

### 安装Runner

1. **访问你的GitHub仓库或组织的设置**：在GitHub的UI中，前往你希望添加自托管runner的仓库或组织的"Settings"。
2. **添加Runner**：在"Actions" > "Runners"部分，点击"Add runner"。
3. **选择操作系统与架构**：选择"Linux"作为操作系统，"ARM64"作为架构。
4. **按照GitHub给出的指示操作**：GitHub会提供一系列命令，帮助你在你的ARM64设备上设置runner。这包括下载runner软件，解压，配置并启动。

### 设置Runner代理

在runner安装的目录创建`.env`文件，然后加入你的代理配置，下面是一个示例：

```toml
https_proxy=http://proxy.local:8080
http_proxy=http://proxy.local:8080
```

这样启动runner之后，runner就会使用代理进行通信。

## 运行Runner

在你的GitHub仓库中，你可能已经有了一个或多个工作流（YAML文件），它们位于`.github/workflows`目录下。你需要调整这些工作流文件，明确指定某些任务(job)应在自托管的ARM64 Runner上执行。

打开或创建一个工作流文件，然后在相应的作业(job)上添加`runs-on`字段并指定自定义的runner标签。假设你给自托管的ARM64 Runner设置了`self-hosted`、`linux`、和`arm64`标签，你可以这样配置：

```yaml
jobs:
  build:
    runs-on: [self-hosted, linux, arm64]
    steps:
    - name: Check out repository
      uses: actions/checkout@v2
    # 其他步骤...
```

当你完成上述配置后，提交并推送这些更改。GitHub Actions会根据工作流配置，在触发事件发生时（如push到特定分支）自动运行工作流，并尝试在自托管的ARM64 Runner上执行指定的作业。

你可以在GitHub仓库的"Actions"标签页下查看工作流的运行状态和日志，以确保它们正确地在ARM64 Runner上执行。

>**注意事项**
>
>- 确保你的自托管Runner保持在线且正常运行。
>- 考虑为自托管Runner设置适当的安全措施，如防火墙规则和访问控制。
>- 根据需要调整Runner的标签，以便能在工作流中精准地引用。
>- 通过利用Runner的标签，你可以灵活地管理和分配不同配置和能力的Runner。
