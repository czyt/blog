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

```bash
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

```bash
#!/usr/bin/env bash
echo "this is install test"
rm -rf $0
```

