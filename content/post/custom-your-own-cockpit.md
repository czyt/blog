---
title: "定制你自己的cockpit"
date: 2024-06-09
tags: ["linux"]
draft: false
---

## 什么是Cockpit
Cockpit，官网https://cockpit-project.org是一个基于web的服务器管理界面,可以通过浏览器访问。它提供了一个统一的管理界面,用于管理和监控Linux服务器。以下是Cockpit的一些主要特点:
### 易用性
提供直观的图形化界面,无需命令行操作
支持多种Linux发行版,如Red Hat、CentOS、Fedora、Debian、Ubuntu等
可以通过浏览器远程访问,无需安装客户端软件
### 功能特性
- 系统监控:实时查看CPU、内存、磁盘、网络等系统资源的使用情况
- 服务管理:启动、停止、重启系统服务
- 存储管理:管理磁盘分区、LVM、RAID等存储设备
- 网络配置:配置网卡、防火墙、虚拟网络等网络设置
- 日志查看:查看系统日志和审计日志
- 用户管理:添加、删除、修改系统用户和组
- 软件包管理:安装、更新、删除软件包
### 安全性
基于角色的访问控制(RBAC),可以为不同用户设置不同的权限
支持SSL/TLS加密,保护数据传输安全
可以与LDAP、Kerberos等认证系统集成
总的来说,Cockpit是一个功能强大、易用的Linux服务器管理工具,可以大大提高管理员的工作效率。它适用于各种规模的Linux服务器,是Linux系统管理的一个不错的选择。

## 安装

cockpit在主流操作系统都一键安装的包。请参考https://cockpit-project.org/running.html的Installation & Setup部分

## 自定义你的cockpit
### 修改登陆界面标题
修改 `/etc/cockpit/cockpit.conf`
```
[WebService]
LoginTitle=gophers land
```
更多参数，请参考 https://cockpit-project.org/guide/latest/cockpit.conf.5.html

### 编写一个rustdesk id viewer页面

#### 创建目录结构

```bash
mkdir -p /usr/share/cockpit/rustdesk
cd /usr/share/cockpit/rustdesk
```

> cockpit支持从下面两个位置获取配置
>  - `~/.local/share/cockpit` 在您的主目录中。它用于用户特定的包和您正在开发的包。您可以即时编辑这些内容并刷新浏览器以查看更改。
> - `/usr/share/cockpit` 和 `/usr/share/local/cockpit`是可供系统所有用户使用的已安装软件包的位置。更改此路径中的文件需要管理员（“root”）权限。在 Cockpit 运行时，不应更改这些内容。
> 因为涉及一些js库，我想复用原来的，所以我这里使用的是第二个位置。

可以通过`cockpit-bridge --packages` 查看已经安装的包：
```
apps                 Applications                             /usr/share/cockpit/apps
base1                                                         /usr/share/cockpit/base1
metrics                                                       /usr/share/cockpit/metrics
network              Networking                               /usr/share/cockpit/networkmanager
rustdesk             RustDesk ID                              /usr/share/cockpit/rustdesk
shell                                                         /usr/share/cockpit/shell
static                                                        /usr/share/cockpit/static
storage              Storage                                  /usr/share/cockpit/storaged
system               Overview, Services, Logs, Terminal       /usr/share/cockpit/systemd
updates              Software updates                         /usr/share/cockpit/packagekit
users                Accounts                                 /usr/share/cockpit/users
```

#### 创建文件

##### manifest.json

```json
{
    "name": "rustdesk",
    "title": "RustDesk ID Viewer",
    "description": "A Cockpit page to display RustDesk ID",
    "version": "1.0",
    "start": "index.html",
    "menu": {
        "index": {
            "label": "RustDesk ID",
            "order": 50
        }
    }
}
```

#####  index.html

```html
<!DOCTYPE html>
<html id="rustdesk-page">
<head>
  <title translate="yes">RustDesk ID Viewer</title>
  <meta charset="utf-8" />
  <link href="rustdesk.css" rel="stylesheet" />
  <script src="../base1/cockpit.js"></script>
  <script src="../base1/po.js"></script>
  <script src="rustdesk.js"></script>
</head>
<body class="pf-v5-m-tabular-nums">
    <div class="ct-page-fill" id="app">
        <div class="container">
            <h1>RustDesk ID Viewer</h1>
            <button id="get-id-btn">Get RustDesk ID</button>
            <div id="rustdesk-id"></div>
        </div>
    </div>
</body>
</html>
```

##### rustdesk.css

```css
.container {
    max-width: 600px;
    margin: auto;
    padding: 20px;
    text-align: center;
}

button {
    background-color: #007bff;
    color: white;
    border: none;
    padding: 10px 20px;
    text-align: center;
    text-decoration: none;
    display: inline-block;
    font-size: 16px;
    margin: 10px 0;
    cursor: pointer;
    border-radius: 5px;
}

button:hover {
    background-color: #0056b3;
}

#rustdesk-id {
    margin-top: 20px;
    font-size: 18px;
}
```

##### rustdesk.js

```javascript
document.addEventListener("DOMContentLoaded", function() {
    document.getElementById('get-id-btn').addEventListener('click', function() {
        cockpit.spawn(['sudo', 'rustdesk', '--get-id'])
            .then(function(data) {
                document.getElementById('rustdesk-id').innerText = 'RustDesk ID: ' + data.trim();
            })
            .catch(function(error) {
                document.getElementById('rustdesk-id').innerText = 'Error: ' + error;
            });
    });
});
```

最终目录结构

```
/usr/share/cockpit/rustdesk
├── index.html
├── rustdesk.js
├── rustdesk.css
├── manifest.json
```
#### 设置sudoer
在/etc/sudoers.d下创建一个文件，我们这里创建一个rustdesk的sudoer文件，`sudo nano /etc/sudoers.d/rustdesk`,输入下面的内容：
```bash
username ALL=(ALL) NOPASSWD: /usr/bin/rustdesk --get-id
```
> 请将`username`替换为你的用户名.

#### 重启服务

```bash
sudo systemctl try-restart cockpit
```
然后通过http://主机ip:9090 登录即可看到页面。

## 参考

### 文档

- https://cockpit-project.org/blog/creating-plugins-for-the-cockpit-user-interface.html
- https://cockpit-project.org/guide/latest/
### 开源插件和主题
- https://github.com/MRsagi/cockpit-temperature-plugin 温度插件
- https://github.com/45Drives/cockpit-hardware 硬件展示
- https://github.com/cyberorg/apsetup-cockpit wifi设置
- https://github.com/SecureRoam/WifiManager
- https://github.com/Viessel/cockpit-wifi-client 基于nmcli的wifi设置工具
- https://github.com/spotsnel/cockpit-cloudflared 
- https://github.com/IntelStudios/cockpit-fail2ban
- https://github.com/spotsnel/cockpit-headscale
- https://github.com/cyberorg/assist-cockpit xvnc远程控制
- https://github.com/tobiasvogel/cockpit-wol-sender wake on lan
- https://github.com/Helly1206/cockpit-smartfancontrol smartfan风扇控制
- https://github.com/retronas/cockpit-retronas 一个NAS主题
