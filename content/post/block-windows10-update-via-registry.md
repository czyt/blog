---
title: "通过注册表禁用windows10自动更新"
date: 2022-05-19
tags: ["windows10", "update"]
draft: false
---



## 缘起

近期项目上设备会自动更新windows10为windows11，通过搜索，搜索到第三方工具[windows-update-blocker](https://www.sordum.org/9470/windows-update-blocker-v1-7/) ，因为改工具支持命令行参数，故也很方便于集成。批处理大致如下

```bash
@echo off
pushd %~dp0
echo 开始禁用windows更新服务
%~dp0Wub_x64.exe /D /P
timeout 3
```

## 背后的操作

作为技术人，还是需要知道软件做了什么背后的操作，通过TotalUninstaller监控，获取到软件写入的注册表如下,实现的手段就是镜像劫持windows更新的进程，并且更新windows的组策略选项：

```coffeescript
Windows Registry Editor Version 5.00

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer]
"NoWindowsUpdate"=dword:00000001
[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options]
"WubBlockLists"=hex(7):57,00,61,00,61,00,53,00,4D,00,65,00,64,00,69,00,63,00,\
  2E,00,65,00,78,00,65,00,00,00,57,00,61,00,61,00,73,00,4D,00,65,00,64,00,69,\
  00,63,00,41,00,67,00,65,00,6E,00,74,00,2E,00,65,00,78,00,65,00,00,00,57,00,\
  69,00,6E,00,64,00,6F,00,77,00,73,00,31,00,30,00,55,00,70,00,67,00,72,00,61,\
  00,64,00,65,00,2E,00,65,00,78,00,65,00,00,00,57,00,69,00,6E,00,64,00,6F,00,\
  77,00,73,00,31,00,30,00,55,00,70,00,67,00,72,00,61,00,64,00,65,00,72,00,41,\
  00,70,00,70,00,2E,00,65,00,78,00,65,00,00,00,55,00,70,00,64,00,61,00,74,00,\
  65,00,41,00,73,00,73,00,69,00,73,00,74,00,61,00,6E,00,74,00,2E,00,65,00,78,\
  00,65,00,00,00,55,00,73,00,6F,00,43,00,6C,00,69,00,65,00,6E,00,74,00,2E,00,\
  65,00,78,00,65,00,00,00,72,00,65,00,6D,00,73,00,68,00,2E,00,65,00,78,00,65,\
  00,00,00,45,00,4F,00,53,00,6E,00,6F,00,74,00,69,00,66,00,79,00,2E,00,65,00,\
  78,00,65,00,00,00,53,00,69,00,68,00,43,00,6C,00,69,00,65,00,6E,00,74,00,2E,\
  00,65,00,78,00,65,00,00,00,75,00,70,00,66,00,63,00,2E,00,65,00,78,00,65,00,\
  00,00,49,00,6E,00,73,00,74,00,61,00,6C,00,6C,00,41,00,67,00,65,00,6E,00,74,\
  00,2E,00,65,00,78,00,65,00,00,00,4D,00,75,00,73,00,4E,00,6F,00,74,00,69,00,\
  66,00,69,00,63,00,61,00,74,00,69,00,6F,00,6E,00,2E,00,65,00,78,00,65,00,00,\
  00,4D,00,75,00,73,00,4E,00,6F,00,74,00,69,00,66,00,69,00,63,00,61,00,74,00,\
  69,00,6F,00,6E,00,55,00,78,00,2E,00,65,00,78,00,65,00,00,00,00,00,00,00

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\EOSnotify.exe]
"Debugger"="/"

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\InstallAgent.exe]
"Debugger"="/"

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\MusNotification.exe]
"Debugger"="/"

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\MusNotificationUx.exe]
"Debugger"="/"

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\remsh.exe]
"Debugger"="/"

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\SihClient.exe]
"Debugger"="/"

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\UpdateAssistant.exe]
"Debugger"="/"

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\upfc.exe]
"Debugger"="/"

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\UsoClient.exe]
"Debugger"="/"

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\WaaSMedic.exe]
"Debugger"="/"

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\WaasMedicAgent.exe]
"Debugger"="/"

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\Windows10Upgrade.exe]
"Debugger"="/"

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\Windows10UpgraderApp.exe]
"Debugger"="/"
[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings]
"TrayIconVisibility"=dword:00000000
[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft]
"WindowsStore"=dword:00000001
[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate]
"DisableOSUpgrade"=dword:00000001
"DisableWindowsUpdateAccess"=dword:00000001
[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU]
"NoAutoUpdate"=dword:00000001
[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\DoSvc]
"Start"=dword:00000004
"WubLock"=dword:00000001
[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\UsoSvc]
"Start"=dword:00000003
[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc]
"Start"=dword:00000004
"WubLock"=dword:00000001
[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\wuauserv]
"Start"=dword:00000004
"WubLock"=dword:00000001

```

恢复为默认更新配置的注册表项

```coffeescript
Windows Registry Editor Version 5.00



[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer]
"NoWindowsUpdate"=-
[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options]
"WubBlockLists"=-

[-HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\EOSnotify.exe]

[-HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\InstallAgent.exe]

[-HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\MusNotification.exe]

[-HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\MusNotificationUx.exe]

[-HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\remsh.exe]

[-HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\SihClient.exe]

[-HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\UpdateAssistant.exe]

[-HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\upfc.exe]

[-HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\UsoClient.exe]

[-HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\WaaSMedic.exe]

[-HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\WaasMedicAgent.exe]

[-HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\Windows10Upgrade.exe]

[-HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\Windows10UpgraderApp.exe]
[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings]
"TrayIconVisibility"=-
[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft]
"WindowsStore"=-
[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate]
"DisableOSUpgrade"=-
"DisableWindowsUpdateAccess"=-
[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU]
"NoAutoUpdate"=-
[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\DoSvc]
"Start"=dword:00000002
"WubLock"=-
[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\UsoSvc]
"Start"=dword:00000002
[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc]
"Start"=dword:00000003
"WubLock"=-
[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\wuauserv]
"Start"=dword:00000002
"WubLock"=-

```

