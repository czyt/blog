---
title: "让你的ssh连接更安全"
date: 2024-04-02
tags: ["sshd", "linux"]
draft: false
---
## 缘起

最近服务器日志有一些ssh的暴力破解登录记录。所以尝试使用下面几个方案来保证ssh的安全。

## 修改ssh配置
对 SSH 进行安全加固可以通过多种不同的策略和手段来实行，以下是一些有效的措施：

1. **禁用 Root 登录**：
   修改 SSH 配置文件 `/etc/ssh/sshd_config` 中的 `PermitRootLogin` 选项，将其设置为 `no`，以防止通过 SSH 使用 root 用户直接登录服务器。
2. **使用公钥加密**：
   如前所述，通过使用基于密钥的认证来替代密码认证可以极大地提高安全性。
3. **限制用户 SSH 访问**：
   在 `/etc/ssh/sshd_config` 中使用 `AllowUsers` 或 `AllowGroups` 指令来限制那些用户或者组可以通过 SSH 登录。同样，可以使用 `DenyUsers` 或 `DenyGroups` 以禁止特定用户或用户组的访问。
4. **SSH 协议版本**：
   确保使用的是 SSH-2，因为 SSH-1 已知存在安全漏洞。
5. **更改默认 SSH 端口**：
   修改配置文件中的 `Port` 选项，将 SSH 服务的监听端口从默认的 22 更改到其他值。
6. **使用 `TCPWrappers` 限制访问**：
   通过 `/etc/hosts.allow` 和 `/etc/hosts.deny` 控制哪些 IP 地址允许或拒绝访问。
7. **设置连接超时**：
   设置自动注销用户的超时时间，避免定期保持未使用的 SSH 会话。使用参数 `ClientAliveInterval` 和 `ClientAliveCountMax` 控制这些设置。
8. **使用 Two-Factor Authentication**（两因素认证）：
   安装并配置像 Google Authenticator 这样的两因素认证系统，要求用户在登录时提供密码以及来自手机或其他设备的一次性密码（OTP）。
9. **使用 `iptables` 或 `ufw` 防火墙**：
   配置 Linux 防火墙以只允许特定的 IP 地址或 IP 范围来进行 SSH 连接。
10. **限制最大登录尝试次数**：
    在 `/etc/ssh/sshd_config` 文件中设置 `MaxAuthTries` 限制登录尝试的次数。
11. **使用复杂且定期更新的密码**：
    再次强调即使在启用密钥登录的情况下，也应该使用强密码并定期更新。
12. **监控 SSH 访问日志**：
    定期查看 `/var/log/auth.log` 文件，分析与 SSH 相关的身份验证尝试和其他可能的安全问题。
13. **配置 `syslog` 以检测 SSH 访问尝试**：
    使用 `syslog` 或其他日志管理工具进行安全监测，你可以设置触发器来警报异常 SSH 活动。
14. **设置只读用户**：
    为需要通过 SSH 访问服务器但不需要修改任何内容的用户设置只读访问权限。
15. **使用安全套接字隧道协议（SFTP）代替 FTP**：
    对于文件传输，使用 SFTP 替代不安全的 FTP 协议。

### 修改sshd监听端口

1. **备份配置文件**：
   在更改任何配置之前，建议先对原始文件进行备份。

```bash
   sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
```

2. **编辑 SSH 配置文件**：
   打开 `/etc/ssh/sshd_config` 文件以编辑。你可以使用 `nano` 或你喜欢的任何文本编辑器进行编辑。

``` bash
   sudo nano /etc/ssh/sshd_config
```

3. **查找并更改端口号**：
   在 `sshd_config` 文件中，找到带有 `Port 22` 的行。如果这一行以 `#` 开头，表示它被注释掉了。你需要取消注释（删除 `#`）并更改为你想用的新端口号。例如，如果你想将 SSH 端口更改为 `2222`，则对应行应类似于：

``` ssh
   Port 2222
```

确保所选的新端口不与系统中任何其他服务的端口冲突，且在 `/etc/services` 中没有列出。

4. **更新防火墙规则**：
   在更改端口之前，确保新的 SSH 端口在服务器的防火墙规则中是允许的，以避免被防火墙阻止连接。

   例如，如果你使用的是 UFW（Uncomplicated Firewall），你可以这样做：

```bash
   sudo ufw allow 2222/tcp
```
如果你的服务器使用 iptables，你需要添加一个类似的规则：

```bash
   sudo iptables -A INPUT -p tcp --dport 2222 -j ACCEPT
```

5. **重新启动 SSH 服务**：
   保存文件并退出编辑器，然后重启 SSH 服务以使更改生效。

```bash
   sudo systemctl restart sshd
```

或者在某些系统中，你可能需要这样重启服务：

```bash
   sudo service ssh restart
```

6. **验证新端口**：
   在断开当前 SSH 连接之前，最好验证新端口是否可行。打开一个新的终端会话，并尝试使用新端口连接：
```bash
   ssh -p 2222 username@hostname_or_ip
```

请确保在更改端口并更改防火墙规则后，更新所有相关的系统和配置文档，以反映新的 SSH 端口号。如果你的服务器位于云平台上，同样需要确保云平台的网络安全组或防火墙规则已允许新端口的流量。

### 改用证书登录

将 SSH 登录方式改为证书（基于密钥）登录，你需要生成一对密钥（公钥和私钥），将公钥添加到服务器上，然后配置 SSH 服务以禁用密码认证。这是一种比使用密码更安全的认证方法，因为它依赖于复杂的密钥对，而不是容易被破解的密码。下面是详细步骤：

1. **在客户端生成 SSH 密钥对**：
   在客户端机器上运行 `ssh-keygen` 命令来生成一对新的 SSH 密钥。当提示你输入文件保存路径时，如果接受默认设置，请按 Enter 键。同样，你也会被提示输入 passphrase，可以选择性输入用于加强安全性的密码。

```bash
   ssh-keygen
```

2. **将公钥复制到服务器**：
   使用 `ssh-copy-id` 命令将生成的公钥复制到服务器的 `~/.ssh/authorized_keys` 文件中。在这里，你需要替换 `username` 和 `host` 为你的 SSH 用户名和服务器的地址。

```bash
   ssh-copy-id username@host
```
如果 `ssh-copy-id` 不可用，可以手动将公钥复制到服务器的 `~/.ssh/authorized_keys` 文件。公钥文件通常位于 `~/.ssh/id_rsa.pub`（或你在 `ssh-keygen` 步骤中指定的路径）。

3. **配置 SSH 服务**：
   登录到服务器，并编辑 `/etc/ssh/sshd_config` 文件。

```bash
   sudo nano /etc/ssh/sshd_config
```

4. **在 SSH 配置中禁用密码认证方法**：
   在配置文件中，找到以下行，并进行编辑：
   - 找到 `#PasswordAuthentication yes` 这一行，去除前面的 `#` 并改为 `no`：

```plaintext
     PasswordAuthentication no
```

- 确保 `PubkeyAuthentication` 设置为 `yes`，通常情况下默认是开启的，如果被注释或设置为 `no`，需要更改：

```plaintext
     PubkeyAuthentication yes
```

- 如果有 `PermitRootLogin` 这一行，推荐设置为 `without-password` 或 `prohibit-password` 来禁止使用密码登录 root 用户：

```plaintext
     PermitRootLogin prohibit-password
```

5. **重启 SSH 服务**：
   保存配置文件的更改，并重启 SSH 服务以应用新配置。
```bash
   sudo systemctl restart sshd
```
或在旧的系统上：

```bash
   sudo service ssh restart
```

6. **验证密钥认证**：
   从客户端尝试连接到服务器，确保不再需要密码认证。
```bash
   ssh username@host
```
完成这些步骤后，你的 SSH 服务应该配置为仅接受带有有效公钥的密钥进行认证。如果你设置了 passphrase，每次通过 SSH 连接时，系统会提示你输入 passphrase。如果没有设置，系统将不会提示输入密码。这种方法提高了安全性，因为即使攻击者知道你的 SSH 用户名和服务器地址，没有密钥文件，他们也无法登录。

## 第三方软件
### fail2ban

以ubuntu为例。

1. **安装 Fail2Ban**：
   使用 `apt` 来安装 Fail2Ban。打开一个终端窗口并运行以下命令：
```bash
   sudo apt update
   sudo apt install fail2ban
```
这将安装 Fail2Ban 并启动 Fail2Ban 服务。

2. **复制配置文件**：
   Fail2Ban 的配置文件位于 `/etc/fail2ban`。你首先要做的是复制默认的配置文件 `jail.conf` 到 `jail.local`：
```bash
   sudo cp /etc/fail2ban/jail.{conf,local}
```

这样做可以防止你的自定义配置在包更新时被覆盖。

3. **修改配置文件**：
   编辑 `jail.local` 文件来配置 Fail2Ban。你可以使用 `nano` 或你喜欢的任何文本编辑器：
```bash
   sudo nano /etc/fail2ban/jail.local
```
在这里，你可以设置一些基本的策略，如封禁时间、查找时间和最大尝试登录失败次数。

4. **设置针对 SSH 的规则**：
   对于 SSH，可以在 `jail.local` 文件的 `[sshd]` 部分设置你的参数。例如：
```ini
   [sshd]
   enabled = true
   port = ssh
   filter = sshd
   logpath = /var/log/auth.log
   maxretry = 6
   bantime = 3600
   findtime = 300
```

这个例子中，Fail2Ban 在 300 秒内最多允许 6 次失败尝试，超过这个限制将会封禁对应 IP 地址 1 小时。

5. **启动 Fail2Ban 服务**：
   一旦完成配置，需要重启 Fail2Ban 服务：

```bash
   sudo systemctl restart fail2ban
```

6. **查看 Fail2Ban 状态**：
   要检查 Fail2Ban 是否正常工作，你可以查看服务状态和已封禁的 IP 列表：

```bash
   sudo fail2ban-client status
   sudo fail2ban-client status sshd
```

7. **自定义过滤规则**：
   如果需要更详细地控制哪些行为会触发 Fail2Ban 封禁，你可以编辑或创建过滤器文件。Fail2Ban 过滤器文件位于 `/etc/fail2ban/filter.d/`。
8. **设置防火墙规则**：
   确认防火墙设置允许 Fail2Ban 添加和移除规则。如果你的系统使用 `iptables` 或 `ufw`，Fail2Ban 将自动处理这些设置。

请注意，在更改 Fail2Ban 的配置或过滤规则后，务必重新启动 Fail2Ban 服务以应用这些更改。配置 Fail2Ban 可以有效减少恶意 SSH 访问尝试，提高服务器安全性。

### port knocking

Port knocking 是一种安全方法，通过敲击（尝试连接）一系列预设的端口来触发服务器的防火墙规则，从而暂时打开某个端口（如 SSH 端口 22）。这可以隐藏服务在标准端口上的存在，并仅允许知道特定敲门序列的用户连接。下面是如何实现 Port knocking 和使用 SSH 连接到启用了 Port knocking 的服务器的大致步骤。

#### 在服务器端设置 

1. **安装 Knockd**：
   Knockd 是一个常用的 Port knocking 实现。在 Ubuntu 上可以通过如下命令安装：
```bash
   sudo apt update
   sudo apt install knockd
```

2. **配置 Knockd**：
   编辑 Knockd 的配置文件 `/etc/knockd.conf`，设置你的敲门序列（端口和动作）和要执行的命令。
   例如，以下配置定义了打开和关闭 SSH 端口的敲门序列：

```ini
   [options]
   UseSyslog

   [openSSH]
   sequence    = 7000,8000,9000
   seq_timeout = 5
   command     = /usr/sbin/iptables -A INPUT -s %IP% -p tcp --dport 22 -j ACCEPT
   tcpflags    = syn

   [closeSSH]
   sequence    = 9000,8000,7000
   seq_timeout = 5
   command     = /usr/sbin/iptables -D INPUT -s %IP% -p tcp --dport 22 -j ACCEPT
   tcpflags    = syn
```

`sequence` 是敲门的端口序列，`seq_timeout` 是两次敲击之间的最大时间间隔（以秒为单位），`command` 是敲门成功后将执行的 iptables 命令来打开或关闭端口。

3. **启动并启用 Knockd 服务**：

```bash
   sudo systemctl start knockd
   sudo systemctl enable knockd
```

4. **更新防火墙规则**：
   确保防火墙已配置为默认情况下阻止对 SSH 端口的访问：
```bash
   sudo iptables -A INPUT -p tcp --dport 22 -j REJECT
```

确保也允许敲门序列中的端口。

#### 在客户端使用 

1. **安装 Knock 客户端**：
   你的客户端机器也需要有一个 knock 客户端。安装命令通常如下：

```bash
   sudo apt update
   sudo apt install knockd
```

请注意，Knockd 包中通常包含客户端和服务器。

2. **执行敲门序列**：
   在尝试 SSH 连接之前，首先要敲正确的端口序列。使用 `knock` 命令如下所示：

```bash
   knock server_ip 7000 8000 9000
```

上述命令敲击定义在 `openSSH` 部分的端口序列，其中 `server_ip` 是你的服务器的 IP 地址。

3. **建立 SSH 连接**：
   等待几秒钟，让服务器有时间处理敲门请求。然后，你应该能够正常通过 SSH 连接到服务器：

```bash
   ssh user@server_ip
```

4. **在断开连接后关闭端口**：
   断开 SSH 连接后，你可能想要通过敲击关闭端口的序列来关闭 SSH 端口，以保持安全性：

```bash
   knock server_ip 9000 8000 7000
```

请务必保护你的敲门序列，不要泄漏给不受信任的人。此外，为了更高的安全性，可以考虑将这些端口更改为更不容易被猜到的端口，并定期更换敲门序列。
