---
title: "在局域网多台设备上执行ssh脚本"
date: 2024-06-21
tags: ["shell", "scripts"]
draft: false
---

## 需要的软件包

需要安装`sshpass`和`nmap`

## 代码示例

run_on_lan_machines.sh

```sh
#!/usr/bin/env bash

USERNAME="czyt"
PASSWORD="upwd"
SUDO_PASSWORD="supwd"
SCRIPT="install_test.sh"
REMOTE_SCRIPT_PATH="/tmp/$SCRIPT"
IP_RANGE="172.168.1.0/24"

# 扫描在线主机
echo "Scanning for hosts with open SSH ports..."
nmap -p 22 $IP_RANGE --open -oG scan_result.txt

# 提取在线主机IP地址
grep "/open/tcp//ssh/" scan_result.txt | awk '{print $2}' > ip_list.txt

# 检查是否有找到的IP地址
if [[ ! -s ip_list.txt ]]; then
    echo "No hosts with open SSH ports found."
    exit 1
fi

# 逐个IP执行脚本
while IFS= read -r ip; do
    echo "Uploading and executing script on $ip"
    
    # 上传脚本到远程主机
    sshpass -p "$PASSWORD" scp -o StrictHostKeyChecking=no "$SCRIPT" "$USERNAME@$ip:$REMOTE_SCRIPT_PATH"
    if [[ $? -ne 0 ]]; then
        echo "Failed to upload script to $ip"
        continue
    fi

    # 在远程主机上以sudo权限执行脚本
    sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "$USERNAME@$ip" << EOF
        echo '$SUDO_PASSWORD' | sudo -S bash $REMOTE_SCRIPT_PATH
EOF

    if [[ $? -ne 0 ]]; then
        echo "Failed to execute script on $ip"
        continue
    fi

    echo "Script executed successfully on $ip"

done < ip_list.txt

echo "Script execution completed on all hosts."

```

install_test.sh

```sh
#!/usr/bin/env bash
echo "this is install test"
rm -rf $0
```

## 注意事项

1. **密码安全性**：

   - 明文存储密码有一定的安全风险。建议在生产环境中使用更安全的方法，如SSH密钥认证或其他安全凭据管理工具。

2. **配置`sudoers`文件**：

   - 确保用户在`/etc/sudoers`文件中配置了不需要TTY以避免`sudo`命令失败。编辑`/etc/sudoers`文件，添加以下行：

   ```sh
   Defaults:czyt !requiretty
   ```

   替换`czyt`为实际用户名。

   >默认情况下，`sudo` 命令要求用户在交互式终端（TTY）中运行。这意味着如果你尝试在没有终端的情况下使用 `sudo`（例如，通过脚本），`sudo` 可能会拒绝执行并显示以下错误消息：
   >
   >```sh
   >sudo: sorry, you must have a tty to run sudo
   >```
   >
   >通过在 `/etc/sudoers` 文件中添加 `Defaults:czyt!requiretty`，你可以允许用户 `czyt` 在没有终端的情况下使用 `sudo` 命令。这对于自动化脚本非常有用，因为脚本通常在没有交互式终端的环境中运行。

3. **确认远程主机的访问权限**：

   - 确保你的用户`czyt`在所有目标主机上有足够的权限来执行脚本。

