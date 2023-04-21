---
title: "浅谈windows默认Shell的替换"
date: 2022-08-31
tags: ["windows", "shell"]
draft: false
---

## Windows XP时代

Xp时代提供的是通过注册表来自定义shell

设置所有用户的shell 注册表键`HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\Shell`

设置当前用户的shell注册表键 `HKEY_Current_User\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\Shell`

注册表键值类型 `REG_SZ`

值修改为你要自定义为shell的程序的完整路径。

在windows10下使用该技巧可能会出现黑屏的现象，参考stackoverflow的回答

>Simply replacing the "explorer.exe" (HKLM\SOFTWARE\Microsoft\Window NT\Winlogon\Shell) with a custom app location provided a black screen.
>
>A much simpler way, and it works great, was to create a BATCH script to call the custom app through elevated powershell...
>
>```bash
>powershell -nologo -noprofile -executionpolicy bypass -command "start-process -verb 'runas' -filepath <full path of custom app executable>"
>```
>
>By replacing "explorer.exe" with this batch script I was able to successfully create a kiosk style lockdown under Windows 10 PRO with a non-UWP app.

## Windows 10 时代

   Windows 10 提供了Shell Launcher（展台模式），也可以实现替换shell的目的。详细的操作，请参考[微软官网文档](https://docs.microsoft.com/en-us/windows-hardware/customize/enterprise/shell-launcher)。但是只支持专业版、企业版和教育版。

​    在 Windows 客户端中可用的 Shell Launcher v1 中，只能将 Windows 桌面应用程序指定为替换 shell。在 Windows 10 版本 1809+ /Windows 11 中提供的 Shell Launcher v2 中，还可以将 UWP 应用指定为替换 shell。 若要在 Windows 10 版本 1809 中使用 Shell Launcher v2 ，需要安装 KB4551853 更新。

实现更安全的展台体验，我们建议你对设备进行以下配置更改：

> 若要实现更安全的展台体验，我们建议你对设备进行以下配置更改：
>
> - 将设备置于平板电脑模式
>
>   如果你希望用户能够使用触摸（屏幕）键盘，请转到**设置** > **系统** > **平板电脑模式**，然后选中**开**。
>
> - 在登录屏幕上隐藏轻松使用功能。
>
>   转到**控制面板** > **轻松使用** > **轻松使用设置中心**，并关闭所有辅助工具。
>
> - 禁用硬件电源按钮。
>
>   转到**电源选项** > **选择电源按钮的功能**、将设置更改为**不执行任何操作**，然后**保存更改**。
>
> - 从登录屏幕中删除电源按钮。
>
>   转到**计算机配置** > **Windows 设置** > **安全设置** > **本地策略** > **安全选项** > **关机: 允许系统在未登录的情况下关闭**，然后选择**已禁用**。
>
> - 禁用相机。
>
>   转到**设置** > **隐私** > **相机**，然后关闭**允许应用使用我的相机**。
>
> - 关闭锁屏界面上的应用通知。
>
>   转到**组策略编辑器** > **计算机配置** > **管理模板系统登录关闭锁屏界面上的应用通知**。
>
> - 禁用可移动媒体。
>
>   转到**组策略编辑器** > **计算机配置** > **管理模板系统设备安装设备安装限制**。 查看**设备安装限制**中提供的策略设置，以确保这些设置适用于你的情况。

## 参考链接

+ [Display custom legal notices & startup messages in Windows 10](https://www.thewindowsclub.com/displaying-customized-start-message-windows-8)

+ [Different Shells for Different Users](https://docs.microsoft.com/en-us/previous-versions/windows/embedded/ms838576(v=winembedded.5)?redirectedfrom=MSDN)

+ [Set up a kiosk on Windows 10 Pro, Enterprise, or Education](https://github.com/yannanwang1/win-cpub-itpro-docs/blob/master/windows/manage/set-up-a-kiosk-for-windows-10-for-desktop-editions.md)
+ [如何替换Windows的Shell](https://blog.csdn.net/a379039233/article/details/47443555?spm=a2c6h.12873639.article-detail.6.a60e2fe43iNVEM)
+ [How to run an application as shell replacement on Windows 10 Enterprise](https://stackoverflow.com/questions/33364908/how-to-run-an-application-as-shell-replacement-on-windows-10-enterprise)
+ https://github.com/xoblite/xoblite-shell
+ https://serverfault.com/questions/762717/windows-10-kiosk-modus-with-custom-shell

