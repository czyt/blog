---
title: "在树莓派3b上搭建GitHub Linux arm64 runner"
date: 2024-05-22
tags: ["github", "linux"]
draft: false
---
最近需要在GitHub Action上自动构建一些软件，但是Github 不提供Arm64的runner，自能自建。
## 树莓派设置
### Arch系统
#### 安装基本软件
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

### Ubuntu系统

#### 安装基本软件

docker 安装前的配置

```bash
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
```

>禁用https证书验证：
>
>```bash
>touch /etc/apt/apt.conf.d/99verify-peer.conf \
>&& echo >>/etc/apt/apt.conf.d/99verify-peer.conf "Acquire { https::Verify-Peer false }"
>```

安装docker

```bash
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```
然后将当前用户添加到docker的组
```bash
sudo usermod -aG docker $USER
```

其他软件

```bash
sudo apt-get install curl zip unzip tar gcc cmake ninja-build  build-essential nasm
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

这样启动runner之后，runner就会使用代理进行通信。也可以尝试下GitHub的hosts加速方式：

```bash
sudo sh -c 'sed -i "/# GitHub520 Host Start/Q" /etc/hosts && curl https://raw.hellogithub.com/hosts >> /etc/hosts'
```

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

## 常见问题

### Ubuntu报错GnuTLS recv error (-110)

```bash
apt-get install gnutls-bin
git config --global http.sslVerify false
git config --global http.postBuffer 1048576000
```

解决方案来自https://github.com/argoproj/argo-cd/issues/3994
