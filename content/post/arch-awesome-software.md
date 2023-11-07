---
title: "Arch Linux 常用软件"
date: 2022-02-23
tags: ["linux", "Arch", "Manjaro", "tools"]
draft: false
weight: 9
---

> 本文部分内容基于manjaro，另外如果喜欢苹果界面，可以试下[pearos](https://pearos.xyz)
## 更换软件源

使用中国的镜像排名

```bash
sudo pacman-mirrors -i -c China -m rank //更新镜像排名
sudo pacman -Syy //更新数据源
sudo pacman-mirrors -g //排列数据源
```

添加archlinuxcn源编辑命令 `sudo nano /etc/pacman.conf` 添加下面的内容

```bash
[archlinuxcn]
 
SigLevel = Optional TrustedOnly

#中科大源

Server = https://mirrors.ustc.edu.cn/archlinuxcn/$arch

#清华源

# Server = https://mirrors.tuna.tsinghua.edu.cn/archlinuxcn/$arch

# 163源

# Server = http://mirrors.163.com/archlinux-cn/$arch
```

然后再更新软件数据源

```bash
sudo pacman -Syy
sudo pacman -S archlinux-keyring archlinuxcn-keyring
```

如何证书有问题，可以使用下面的命令进行修复,参考[官方wiki](https://wiki.archlinux.org/title/Pacman/Package_signing)

```bash
sudo pacman-key --init && sudo pacman-key --populate
```

因为本文的软件使用yay进行安装，故需要使用命令进行安装，命令为  ` sudo pacman -S yay`
设置yay的mirror

```bash
yay --aururl "https://aur.tuna.tsinghua.edu.cn" --save
```

可选安装 编译包 `yay -S base-devel` 
注：类似的包管理器还可以用 `paru` 

## SSH管理工具

Remmina 安装 `yay -S remmina`
可以选装这些插件


```bash
freerdp remmina-plugin-teamviewer remmina-plugin-webkit remmina-plugin-rdesktop remmina-plugin-anydesk-git remmina-plugin-rustdesk
```

终端：
深度终端 安装 `yay -S deepin-terminal` 
alacritty 安装 `yay -S alacritty ` 
终端渐变色工具lolcat `yay -S lolcat` 

ssh设置如果只是修改客户端选项,创建`~/.ssh/config`或者修改`/etc/ssh/ssh_config`(需要root权限),文件输入下面内容：

```bash
Host *
    ServerAliveInterval 300
    ServerAliveCountMax 2
```

如果是作为服务端，那么需要修改sshd的配置文件`/etc/ssh/sshd_config`,添加下面内容：

```bash
ClientAliveInterval 300
ClientAliveCountMax 2
```

这些设置将使 SSH 客户端或服务器每300秒(5分钟)向另一端发送一个空包，如果在2次尝试后没有收到任何响应，则放弃，此时连接很可能已被丢弃。对于客户端，可以在配置文件`/etc/ssh/sshd_config`,添加下面内容：

```
TCPKeepAlive yes
ServerAliveInterval 60
```

参考 `ssh_config`的帮助文档

> **ServerAliveCountMax**
> Sets the number of server alive messages (see below) which may be sent without ssh(1) receiving any messages back from the server. If this threshold is reached while server alive messages are being sent, ssh will disconnect from the server, terminating the session. It is important to note that the use of server alive messages is very different from TCPKeepAlive (below). The server alive messages are sent through the encrypted channel and therefore will not be spoofable. The TCP keepalive option enabled by TCPKeepAlive is spoofable. The server alive mechanism is valuable when the client or server depend on knowing when a connection has become inactive.
>
> The default value is 3. If, for example, ServerAliveInterval (see below) is set to 15 and ServerAliveCountMax is left at the default, if the server becomes unresponsive, ssh will disconnect after approximately 45 seconds. This option applies to protocol version 2 only; in protocol version 1 there is no mechanism to request a response from the server to the server alive messages, so disconnection is the responsibility of the TCP stack.
>
> **ServerAliveInterval**
> Sets a timeout interval in seconds after which if no data has been received from the server, ssh(1) will send a message through the encrypted channel to request a response from the server. The default is 0, indicating that these messages will not be sent to the server, or 300 if the BatchMode option is set. This option applies to protocol version 2 only. ProtocolKeepAlives and SetupTimeOut are Debian-specific compatibility aliases for this option.


## 浏览器

vivaldi 安装 `yay -S vivaldi vivaldi-ffmpeg-codecs` 

microsoft Edge `yay -S microsoft-edge-stable-bin`

Chrome 安装 `yay -S google-chrome chromium-codecs-ffmpeg  chromium-codecs-ffmpeg-extra`

Opera 安装 `yay -S opera opera-ffmpeg-codecs `

firefox 安装 `yay -S firefox `

> 参考
>
> - 解决打开Chrome出现 输入密码以解锁您的登录密钥环 [https://blog.csdn.net/kangear/article/details/20789451](https://blog.csdn.net/kangear/article/details/20789451)
> - bilibili视频不能播放的问题 需要安装对应浏览器的解码包。



## 翻译软件

有道词典 安装 `yay -S youdao-dict`

金山词霸 安装 `yay -S powerword-bin` 

goldendict 安装 `yay -S goldendict` [词库](https://github.com/czytcn/goldendict)


## 聊天软件

微信 安装 `yay -S deepin-wine-wechat`  (新版可能卡死，可以使用下面的命令`killall WeChatBrowser.exe && /opt/deepinwine/tools/sendkeys.sh w wechat 4`)

QQ 安装 `yay -S deepin-wine-qq`如果你喜欢各种破解，可以试试下载dreamcast的QQ，替换wine下的QQ。命令参考 `sudo mv ./QQ ~/.deepinwine/Deepin-QQ/drive_c/"Program Files"/Tencent`

新版LinuxQQ `yay -S linuxqq`

tim `yay -S com.qq.tim.spark` 

ipmsg 安装`yay -S iptux`

mattermost 安装 `yay -S mattermost-desktop`

slack 安装 `yay -S slack-desktop` 

Discord  安装 `yay -S discord`

>### Discord强制要求更新
>
>虽然discord在linux下表现很棒，但是强制更新这个确实有点恶心。有时候Manjaro的仓库里头还没有更新discord版本，但是discord客户端不更新就不让用了。好在客户端本身并不是真的不让登录，只是简单的检测了下版本号，所以应该知道怎么解决了吧。
>
>首先找到discord的路径，如下所示
>
>```
>$ ls -al `which discord`
>lrwxrwxrwx 1 root root 20 Apr 21 09:58 /usr/bin/discord -> /opt/discord/Discord
>```
>
>然后在discord文件夹找到`./resources/build_info.json`，修改里头的版本号即可。
>
>参考文章：[Discord won’t open on Linux when an update is available](https://support.discord.com/hc/en-us/community/posts/360057789311-Discord-won-t-open-on-Linux-when-an-update-is-available)

Telegram `yay -S telegram-desktop`

### 可自建的聊天软件

mattermost 安装 `yay -S mattermost` [参阅](https://wiki.archlinux.org/title/Mattermost)

rocketchat-server 安装 `yay -S rocketchat-server ` 

说明：

1. 安装微信后可能不能启动，需要修改内容，参考 [https://github.com/countstarlight/deepin-wine-wechat-arch](https://github.com/countstarlight/deepin-wine-wechat-arch)
1. 微信安装使用时，有透明的窗口问题 使用命令 `sudo sed -i 's/env WINEPREFIX/env GTK_IM_MODULE="fcitx" XMODIFIERS="@im=fcitx" QT_IM_MODULE="fcitx" WINEPREFIX/' /opt/deepinwine/apps/Deepin-WeChat/run.sh` 执行即可
1. QQ、微信不能输入中文，在微信的安装目录`/opt/deepinwine/apps/Deepin-WeChat`下的`run.sh`前面添加

```
env locale=zh_CN
export XIM="fcitx"
export XMODIFIERS="@im=fcitx"
export GTK_IM_MODULE="fcitx"
export QT_IM_MODULE="fcitx"
```

设置构建包时压缩安装包不进行压缩

```bash
sudo sed -i "s/PKGEXT='.pkg.tar.xz'/PKGEXT='.pkg.tar'/g" /etc/makepkg.conf
```

参考

 [https://printempw.github.io/setting-up-manjaro-linux/](https://printempw.github.io/setting-up-manjaro-linux/)

## 下载上传

文件蜈蚣 安装 `yay -S  filecentipede-bin ` [激活码](http://www.filecxx.com/zh_CN/activation_code.html)

MegaSync 安装 `yay -S megasync-bin`

115网盘 安装 `yay -S 115pc`

天翼云盘 安装 `yay -S cloudpan189-go`

OneDive 安装 `yay -S onedrive` 或者 `yay -S onedrive-abraunegg` (GUI `yay -S onedrivegui-git `) 或者使用onedriver（推荐） `yay -S onedriver`

百度云 安装 `yay -S baidunetdisk-bin` 或者 安装深度的版本 `yay -S deepin-baidu-pan`

坚果云 安装 `yay -S nutstore` 或者 坚果云实验版 `yay -S nutstore-experimental `

[^坚果云窗口太小，看不到输入框。]: 可以用 `sudo pacman -S gvfs libappindicator-gtk3`

DropBox 安装 `yay -S dropbox` 

resilio sync 安装 ` yay -S rslsync` 

迅雷linux版本 安装 `yay -S xunlei-bin` 

迅雷极速版 `yay -S deepin-wine-thunderspeed`

rclone 同步工具 `yay -S rclone` ([同步onedrive配置](https://rclone.org/onedrive/) [GUI](https://rclone.org/gui/))

axel 安装 `yay -S axel`

localsend 安装 `yay -S localsend-bin`

zssh 安装 `yay -S zssh` 配合lrzsz(安装命令 `yay -S lrzsz`)食用效果最佳。

>lrzsz 安装后在/usr/bin下面目录下有下面几个文件lrzsz-rb、lrzsz-rx、lrzsz-rz、lrzsz-sb、lrzsz-sx、lrzsz-sz可以使用下面的命令去掉文件名中的lrzsz- 并添加执行权限
>
>```bash
>for f in lrzsz-*; do
>    mv "$f" "${f#lrzsz-}"
>    chmod +x "${f#lrzsz-}"
>done
>```

[trzsz](https://github.com/trzsz/trzsz) 安装 `yay -S trzsz ` 

motrix 安装 `yay -S motrix`  

uget 安装 `yay -S uget`

Mega网盘安装 `yay -S megatools-git` 

qbittorrent 安装  `yay -S qbittorrent`([增强版](https://github.com/c0re100/qBittorrent-Enhanced-Edition/releases) `yay -S qbittorrent-enhanced-git` [搜索插件](https://github.com/qbittorrent/search-plugins/wiki/Unofficial-search-plugins))

moose 支持边下边播的BT工具 `yay -S moose ` 

[Spacedrive](https://www.spacedrive.com/) 安装 `yay -S spacedrive-bin`

参考

- dreamcast的网盘 http://dreamcast2.ys168.com
- zssh介绍 http://www.v5b7.com/other/zssh.html

## 办公软件

[看雪安全接入](https://ksa.kanxue.com)ksa 安装 `yay -S ksa` 

Android屏幕共享[Scrcpy](https://github.com/Genymobile/scrcpy) 安装 `yay -S scrcpy`

[tailscale](https://tailscale.com) 安装 `yay -S tailscale` 

[达芬奇视频剪辑](http://www.blackmagicdesign.com/products/davinciresolve/) 安装 `yay -S davinci-resolve` 

handbrake 视频格式转换工具 `yay -S handbrake-full`

[zettlr](https://www.zettlr.com) markdown编辑器 安装 `yay -S zettlr ` 

[vnode](https://tamlok.github.io/vnote/zh_cn/#!index.md) markdown编辑器 安装 `yay -S vnote` 

Wps 安装 `yay -S wps-office ttf-wps-fonts wps-office-mui-zh-cn  wps-office-mime`

libreoffice 安装  `yay -S libreoffice` 

flameshot 截图工具 安装 `yay -S flameshot` 

kazam录屏软件 安装 `yay -S kazam `

屏幕录制为gif 工具 peek `yay -S peek`

> 这个工具已经停止维护

geogebra 几何绘图软件 `yay -S geogebra  `

福昕pdf阅读器 `yay -S foxitreader` 

masterpdfeditor 对linux用户免费的PDF浏览及编辑器,支持实时预览 `yay -S masterpdfeditor  ` 

Teamviewer `yay -S teamviewer`如果一直显示未连接，则请退出teamviewer，执行`sudo teamviewer --daemon enable` 再打开试试

Xrdp `yay -S xrdp xorgxrdp-git` ([参考文档](https://wiki.archlinux.org/title/xrdp))

向日葵 安装 `yay -S sunloginclient` (需要设置开机启动服务 `systemctl enable runsunloginclient` 启动服务 `systemctl start runsunloginclient` )

toDesk远程工具 安装 `yay -S todesk-bin` (设置服务 `systemctl start\enable todeskd` 才能正常运行)

parsec 远程工具 安装 `yay -S parsec-bin ` 

v2ray 安装 `yay -S v2ray`  （安装配置工具`yay -S qv2ray ` qv2ray 插件 `yay -S qv2ray-plugin` ，[福利订阅](https://jiang.netlify.app) 新版已经使用AppImage格式发布，下载AppImage格式即可 或者 v2rayDesktop `yay -S v2ray-desktop` ）

clash-verge-bin `yay -S clash-verge-bin`

clash https://aur.archlinux.org/packages?K=clash [福利](https://neko-warp.nloli.xyz)

[nekoray-bin ](https://github.com/MatsuriDayo/nekoray)Qt based cross-platform GUI proxy configuration manager  安装 `yay -S nekoray-bin`( 可能需要安装相关插件 `yay -S sing-geosite sing-geoip  `)

cloudflare Warp 安装 `yay -S cloudflare-warp-bin`  [基于wiregurd](https://www.ianbashford.net/post/setupcloudflarewarplinuxarch/) [自选ip脚本](https://gitlab.com/rwkgyg/CFwarp) [自选ip脚本2](https://gitlab.com/ProjectWARP/warp-script)

n2n [VPN软件](https://www.meirenji.info/2018/02/03/N2N%E7%BB%84%E7%BD%91-%E5%AE%9E%E7%8E%B0%E5%AE%B6%E9%87%8C%E8%AE%BF%E4%B8%8E%E5%85%AC%E5%8F%B8%E7%BD%91%E7%BB%9C%E4%BA%92%E8%AE%BF-%E7%B2%BE%E7%BC%96%E7%89%88/) `yay -S n2n` 

proxychains-ng 安装 `yay -S proxychains-ng`

evernote 开源版本 nixnote2 安装 `yay -S nixnote2` 

joplin 安装 `yay -S joplin` 

Okular （[KDE上的通用文档阅读器](https://www.appinn.com/okular/)）` yay -S okular` 

Foliate [简单、现代的电子书阅读器](https://www.appinn.com/foliate-for-linux/) 安装 `yay -S foliate` 

Screen屏幕共享软件 安装 `yay -S screen-desktop ` 

U盘启动制作[etcher](https://github.com/balena-io/etcher) `yay -S etcher-bin` 

xmind-2020 安装 `yay -S xmind-2020` ([福利链接](https://mega.nz/folder/MxpkmaCZ#Il82PxQ5s9iLgLCMbMf68g))

drawio  安装` yay -S drawio-desktop-bin` 或者 ` yay -S drawio-desktop`

钉钉 安装 `yay -S  dingtalk-electron ` 

企业微信 `yay -S deepin-wine-wxwork` 

飞书 `yay -S feishu-bin`

剪切板工具 [uniclip](https://github.com/quackduck/uniclip) `yay -S uniclip`

onenote `yay -S p3x-onenote` 

realvnc-server `yay -S realvnc-vnc-server ` (安装完毕后需要注册`sudo vnclicense -add 3TH6P-DV5AE-BLHY6-PNENS-B3AQA`,启动服务 `systemctl enable vncserver-x11-serviced`)

realvnc-viewer `yay -S realvnc-vnc-viewer`

[macast-git](https://github.com/xfangfang/Macast)跨平台的 DLNA 投屏接收端 `yay -S 
macast-git`(需要安装相关pip包 `pip install -U urllib3 requests` `pip install requests[socks]`)

pdf合并工具 `yay -S pdfmerger`

在线流程图工具 [https://excalidraw.com](https://excalidraw.com)
参考

- proxychains-ng 使用 [https://wsgzao.github.io/post/proxychains/](https://wsgzao.github.io/post/proxychains/)
- Linux中制作U盘启动盘的三种方法 [https://ywnz.com/linuxjc/5620.html](https://ywnz.com/linuxjc/5620.html)

## 输入法

### fcitx

sun输入法 安装 `yay -S fcitx fcitx-im fcitx-configtool fcitx-sunpinyin fcitx-googlepinyin fcitx-cloudpinyin fcitx-libpinyin`

皮肤 安装 `yay -S fcitx-skin-material` 

百度输入法 安装 `yay -S fcitx-baidupinyin` 安装完成以后记得重启下，不然输入候选框会乱码。

讯飞输入法 安装 `yay -S  iflyime` 
or `yay -S manjaro-asian-input-support-fcitx` 

KDM, GDM, LightDM 等显示管理器，请使用 ~/.xprofile 
警告: 上述用户不要在~/.xinitrc中加入下述脚本，否则会造成无法登陆。(但在里头加了也没挂) 如果您用 startx 或者 Slim 启动，请使用~/.xinitrc 中加入

```bash
export GTK_IM_MODULE=fcitx 
export QT_IM_MODULE=fcitx 
export @=fcitx
```

如果你使用的是较新版本的GNOME，使用 Wayland 显示管理器，则请在/etc/environment中加入

```bash
GTK_IM_MODULE=fcitx 
QT_IM_MODULE=fcitx 
@=fcitx
```

安装相关字体fcitx5

```bash
yay -S wqy-bitmapfont wqy-microhei wqy-zenhei adobe-source-code-pro-fonts  adobe-source-han-sans-cn-fonts ttf-monaco noto-fonts-emoji ttf-fira-code 
ttf-ms-fonts ttf-sarasa-gothic nerd-fonts-complete noto-fonts-cjk  noto-fonts-sc
```

输入法有问题，需要重置，使用命令 `rm -r ~/.config/fcitx` 然后注销即可。

### fcitx5

基本安装 `yay -S fcitx5-im fcitx5-chinese-addons  `

或者 `yay -S manjaro-asian-input-support-fcitx5 fcitx5 fcitx5-configtool fcitx5-chinese-addons fcitx5-qt fcitx5-gtk`

安装字典 `yay -S fcitx5-pinyin-zhwiki fcitx5-pinyin-sougou`

安装皮肤：

- [fcitx5-breeze](https://aur.archlinux.org/packages/fcitx5-breeze/)：提供了与KDE默认的Breeze主题匹配的外观。
- [fcitx5-nord](https://archlinux.org/packages/?name=fcitx5-nord) ：[Nord颜色](https://github.com/tonyfettes/fcitx5-nord) 的主题
- [fcitx5-material-color](https://archlinux.org/packages/?name=fcitx5-material-color)：提供了类似微软拼音的外观。
- [fcitx5-solarized](https://aur.archlinux.org/packages/fcitx5-solarized/)：[Solarized颜色](https://ethanschoonover.com/solarized/) 主题
- [fcitx5-skin-fluentdark-git](https://aur.archlinux.org/packages/fcitx5-skin-fluentdark-git/)：具有模糊效果和阴影的 Fluent-Design 深色主题

> 编辑 `/etc/environment` 并添加以下几行，然后重新登录
>
> ```
> GTK_IM_MODULE=fcitx
> QT_IM_MODULE=fcitx
> XMODIFIERS=@im=fcitx
> SDL_IM_MODULE=fcitx
> GLFW_IM_MODULE=ibus
> ```
>
> 如果使用 en_US.UTF-8 时，遇到 GTK2 无法激活 fcitx5，可专门为该 GTK2 应用程序设置输入法为 xim，如
>
> ```
> $ env GTK_IM_MODULE=xim <your_gtk2_application>
> ```
>
> 请勿将 `GTK_IM_MODULE` 全局设置为 xim，因为它也会影响 GTK3 程序。XIM 有各种问题（比如输入法重启之后再无法输入），尽可能不要使用。
>
> **注意：**
>
> - SDL_IM_MODULE 是为了让一些使用特定版本 SDL2 库的游戏能正常使用输入法。
> - GLFW_IM_MODULE 是为了让 kitty 启用输入法支持。此环境变量的值只能为 ibus。

更多内容 参考 [wiki](https://wiki.archlinux.org/title/Fcitx5_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87))

### rime

参考官网 [传送门](https://rime.im)
基本库 `yay -S ibus ibus-qt ibus-rime` 
配置文件内容

```json
export GTK_IM_MODULE=ibus
export XMODIFIERS=@im=ibus
export QT_IM_MODULE=ibus
ibus-daemon -d -x
```

[四叶草输入法](https://github.com/fkxxyz/rime-cloverpinyin) `yay -S rime-cloverpinyin` 
参考 https://wiki.archlinux.org/index.php/Fcitx

雾凇拼音 https://github.com/iDvel/rime-ice

## 媒体软件

网易云音乐 安装 `yay -S netease-cloud-music` 

腾讯视频 安装 `yay -S tenvideo`

全聚合影视 安装 `yay -S vst-video-bin` 

OBS推流工具 `yay -S obs-studio` 

bilibili `yay -S bilibili-bin`

smPlayer `yay -S smplayer`

## 美化

### docky 安装

`yay -S docky`
或者
`yay -S plank` (这个比较简单，推荐)

> XFCE桌面下安装plank后可能会出现屏幕下方会有一条阴影直线，十分影响视觉。解决方案是在开始菜单的设置管理器(Settings Manager)-窗口管理器微调(Window Manager Tweaks)-合成器(Compositor)中去掉dock阴影(Show shadows under dock windows)前面的勾。

如果是KDE桌面
`yay -S latte-dock` 

KDE

（KDE推荐安装部件([下载网站](https://store.kde.org/),最好安装ocs-url `yay -S ocs-url`) `appication title` `全局菜单` `Launchpad plasma` `latte Spacer` `Event calendar` (个人google三色时间配置 `'<font color="#EB4334">'hh'</font>':'<font color="#35AA53">'mm'</font>':'<font color="#4586F3">'ss'</font>'` )）

KDE whitesur主题 安装 `yay -S whitesur-kde-theme-git`

XFCE whitesur主题 

+ https://github.com/vinceliuice/WhiteSur-gtk-theme
+ https://github.com/paullinuxthemer/McOS-XFCE-Edition

mcmojave-circle-icon-theme-git 图标主题 `yay -S mcmojave-circle-icon-theme-git`

xfce全局菜单([参考链接1](https://blog.csdn.net/kewen_123/article/details/115465909) [参考链接2](https://www.cnblogs.com/maxwell-blog/p/10337514.html)) `yay -S libdbusmenu-glib libdbusmenu-gtk3 libdbusmenu-gtk2  vala-panel-appmenu-xfce appmenu-gtk-module appmenu-qt4  vala-panel-appmenu-registrar xfce4-windowck-plugin-xfwm4-theme-support`   启用使用下面的命令

```
xfconf-query -c xsettings -p /Gtk/ShellShowsAppmenu -n -t bool -s true
xfconf-query -c xsettings -p /Gtk/ShellShowsMenubar -n -t bool -s true
```



[conky](https://github.com/brndnmtthws/conky) 性能显示组件 安装 `yay -S conky conky-manager`


### ohmyzh 安装

`yay -S zsh && sh -c "$(curl -fsSL https://fastgit.czyt.tech/https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"`
安装插件

```
git clone https://github.com/zsh-users/zsh-completions ~/.oh-my-zsh/custom/plugins/zsh-completions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-autosuggestions.git ~/.oh-my-zsh/plugins/zsh-autosuggestions
git clone https://github.com/qoomon/zsh-lazyload $ZSH_CUSTOM/plugins/zsh-lazyload
git clone https://github.com/skywind3000/z.lua.git $ZSH_CUSTOM/plugins/z.lua
```

配置插件 ` vim ~/.zshrc` 

```
plugins=(git z.lua zsh-lazyload zsh-syntax-highlighting docker docker-compose zsh-autosuggestions zsh-completions)
```

zsh在使用nohup执行任务的时候，可能会出现session注销后，nohup自动被终止的情况，若要保持运行，请执行`setopt NO_HUP` 参考[Zsh](http://zsh.sourceforge.net/Guide/zshguide02.html)文档

另外还有一个[SpaceShip](https://github.com/spaceship-prompt/spaceship-prompt)的插件也不错，可以试下。参考[这篇文章](https://garrytrinder.github.io/2020/12/my-wsl2-windows-terminal-setup)，下面是引用部分

> ## paceship ZSH
>
> I use [Spaceship ZSH](https://denysdovhan.com/spaceship-prompt/) as my shell theme, not only does it make my prompt look nice but it also provides extensions that helps improve my developer workflow, bringing information like the current git branch, git status, npm package version and current node version into my shell prompt for increased visibility.
>
> I ran the script at the command line to download and install.
>
> ```
> git clone https://github.com/denysdovhan/spaceship-prompt.git "$ZSH_CUSTOM/themes/spaceship-prompt" --depth=1
> ln -s "$ZSH_CUSTOM/themes/spaceship-prompt/spaceship.zsh-theme" "$ZSH_CUSTOM/themes/spaceship.zsh-theme"
> ```
>
> I set `ZSH_THEME="spaceship"` and uncommented the line in `.zshrc`.
>
> I added `SPACESHIP_PROMPT_ORDER` array to `.zshrc` above `source $ZSH/oh-my-zsh.sh` line.
>
> ```
> SPACESHIP_PROMPT_ORDER=(
>   dir           # Current directory section
>   git           # Git section (git_branch + git_status)
>   package       # Package version
>   node          # Node.js section
>   dotnet        # .NET section
>   ruby          # Ruby section
>   exec_time     # Execution time
>   line_sep      # Line break
>   battery       # Battery level and status
>   jobs          # Background jobs indicator
>   exit_code     # Exit code section
>   char          # Prompt character
> )
> ```
>
> > The `SPACESHIP_PROMPT_ORDER` array enables you to define which sections are enabled or disabled in the prompt, this is optional but can improve the performance of the prompt. The less sections are loaded the faster the shell will load, so I enable the sections that are of use to me.

> **HUP**
> ... In zsh, if you have a background job running when the shell exits, the shell will assume you want that to be killed; in this case it is sent a particular signal called SIGHUP... If you often start jobs that should go on even when the shell has exited, then you can set the option NO_HUP, and background jobs will be left alone.

[starship](https://github.com/starship/starship) 安装 `yay -S starship` (如是安装的zsh，安装完成后在~/.zshrc 加入`eval "$(starship init zsh)"`即可,[配置文档](https://starship.rs/config/)),个人配置文件(通过`mkdir -p ~/.config && touch ~/.config/starship.toml`创建)

```toml
# Get editor completions based on the config schema
"$schema" = 'https://starship.rs/config-schema.json'

# Inserts a blank line between shell prompts
add_newline = true

continuation_prompt = "▶▶"

[username]
style_user = "white bold"
style_root = "red bold"
format = "user: [$user]($style) "
disabled = false
show_always = true

# Replace the "❯" symbol in the prompt with "➜"
[character] # The name of the module we are configuring is "character"
success_symbol = "[➜](bold green)" # The "success_symbol" segment is being set to "➜" with the color "bold green"

[golang]
format = "via [🏎💨 $version](bold cyan) "

[git_status]
conflicted = "🏳"
ahead = "🏎💨"
behind = "😰"
diverged = "😵"
up_to_date = "✓"
untracked = "🤷"
stashed = "📦"
modified = "📝"
staged = '[++\($count\)](green)'
renamed = "👅"
deleted = "🗑"

[sudo]
style = "bold green"
symbol = "👩‍💻 "
disabled = false

# Disable the package module, hiding it from the prompt completely
[package]
disabled = true

```

适用于starship的Gruvbox 主题 [github](https://github.com/fang2hou/starship-gruvbox-rainbow)

还有一个[zinit](https://github.com/zdharma-continuum/zinit)也很不错。

安装 [atuin](https://github.com/ellie/atuin)

```
yay -S atuin
```

使用zsh插件

```bash
echo 'eval "$(atuin init zsh)"' >> ~/.zshrc
```

另外有个仓库也可以参考下  https://github.com/unixorn/awesome-zsh-plugins

### fish

`yay -S fish` 
安装oh-my-fish 

```bash
curl -L https://get.oh-my.fish | fish 
```

  推荐插件
wttr天气插件

```bash
omf install wttr
```

fisher

```bash
curl https://git.io/fisher --create-dirs -sLo ~/.config/fish/functions/fisher.fish
```

参考[知乎](https://zhuanlan.zhihu.com/p/35448750)这篇文章

### nushell

安装 `yay -S nushell` 

[Warp Terminal](https://www.warp.dev) （有Linux版本的计划，暂未发布）

### 自定义主题

需要事先安装软件 `yay -S gnome-tweaks chrome-gnome-shell`

#### 手动安装

##### Gnome

解压主题到 `/usr/share/themes`解压图标到 `/usr/share/icons`然后在gnome-tweaks启用即可。
参考

- https://zhuanlan.zhihu.com/p/71588449
- https://blog.triplez.cn/manjaro-quick-start
- https://zhuanlan.zhihu.com/p/37852274

##### KDE

/usr/share/plasma/desktoptheme 这是存放plasma主题
/usr//share/plasma/look-and-feel/ 存放全局主题
/usr/share/plasma/plasmoids/ 存放插件

## 编程语言

go 安装 `yay -S go`

rust 安装 `yay -S rustup`

flutter 安装 `yay -S flutter`

.net core 安装 `yay -S dotnet-sdk-bin` 

## 开发工具

[github520](https://github.com/521xueweihan/GitHub520) `sed -i "/# GitHub520 Host Start/Q" /etc/hosts && curl https://raw.hellogithub.com/hosts >> /etc/hosts` (刷新缓存 `systemctl restart nscd`)

docker-image-extract  https://github.com/jjlin/docker-image-extract

[lapce](https://github.com/lapce/lapce) `yay -S lapce`

[lazygit](https://github.com/jesseduffield/lazygit) `yay -S lazygit`

[gitui](https://github.com/extrawurst/gitui) `yay -S gitui`

github Desktop `yay -S github-desktop-bin`

代码生成图片[silicon](https://github.com/Aloxaf/silicon) `yay -S --needed pkgconf freetype2 fontconfig libxcb xclip silicon `

redis管理工具 `yay -S redis-desktop-manager` 

github-cli 安装 `yay -S github-cli-bin` 

minicom串口工具 安装 `yay -S minicom` (设置参数 `sudo minicom -s` )

串口助手 安装 `yay -S serialtool` 

[serial-studio](https://github.com/Serial-Studio/Serial-Studio/blob/master/doc/README_ZH.md) 串行数据可视化工具 安装 `yay -S serial-studio-git`

nodejs 安装 ` yay -S nodejs npm` （安装cnpm `npm install -g cnpm --registry=https://registry.npm.taobao.org  ` ）

跨平台编译工具链 安装 `yay -S arm-linux-gnueabihf-g++ arm-linux-gnueabihf-gcc` 

c/c++开发  安装 `yay -S make cmake gdb gcc` 

goland 安装 `yay -S goland goland-jre`

rustrover 安装 `yay -s rustrover rustrover-jre`

uinityHub 安装 `yay -S unityhub`

Android Studio 安装 `yay -S android-studio`

[commitizen-go](https://github.com/lintingzhen/commitizen-go) 安装 `yay -S commitizen-go `  相似的程序[gitcz](https://github.com/xiaoqidun/gitcz)

datagrip 安装 `yay -S datagrip datagrip-jre`

Android Studio 安装 `yay -S android-studio` (安卓SDK `yay -S android-sdk`) 

clion 安装 `yay -S clion clion-jre` 

pycharm 安装 `yay -S pycharm-professional` 

rider安装 `yay -S rider` 

webstorm 安装 `yay -S webstorm webstorm-jre` 

vmware 安装 `yay -S vmware-workstation`

postman 安装 `yay -S postman` [汉化文件](https://github.com/hlmd/Postman-cn)（jetbrains新版自带的resful 测试工具，可以不用安装）

apifox 安装 `yay -S apifox`

Typora markdown编辑器 安装 `yay -S typora`

>也可以试下 remarkable `yay -S remarkable `

dnspy 安装 `yay -S dnspy` (需要使用blackarch源)

tmux 终端工具 安装 `yay -S tmux`

[pre-commit](https://github.com/pre-commit/pre-commit) 安装 `yay -S python-pre-commit` (管理和维护 pre-commit hooks的工具. [官网](https://pre-commit.com/) )

byobu 终端工具 安装 `yay -S byobu`

API文档工具 zeal 安装 `yay -S zeal` 

[windterm](https://github.com/kingToolbox/WindTerm) 安装 `yay -S windterm-bin `

bcompare 安装 `yay -S bcompare ` 

tldr 简化版文档工具 ` yay -S tldr` （rust版本 `yay -S  tealdeer ` ）

vscode 安装 `yay -S visual-studio-code-bin` 

终端录屏幕[asciinema](https://asciinema.org/) 安装 `yay -S asciinema` 

[zoxide](https://github.com/ajeetdsouza/zoxide) **smarter cd command** `yay -S zoxide`

证书生成工具 mkcert 安装 `yay -S mkcert` 

netcat `yay -S  --noconfirm gnu-netcat` 或者 `yay -S --noconfirm openbsd-netcat ` 

微信开发者工具 `yay -S wechat-devtool ` 

Platform-Tools for Google Android SDK (adb and fastboot) 安装 `yay -S android-sdk-platform-tools` 

neovim `yay -S neovim` (插件 [lazyvim](https://www.lazyvim.org))

编译链工具[xmake](http://xmake.io) 安装 `yay -S xmake` 

[goreleaser](https://goreleaser.com) 安装 `yay -S goreleaser-bin`

percona-toolkit (mysql辅助分析工具) `yay -S percona-toolkit` 

注：

jetbrains系列软件，自带更新功能，但是我们一般使用非root用户进行登录，这时需要将安装目录授权给当前登录用户即可。以goland为例，只需要执行 ` chown -R $(whoami) /opt/goland ` 即可进行自动升级。 

strace `yay -S strace` 

dtrace `yay -S dtrace-utils`  (使用[教程](https://zhuanlan.zhihu.com/p/180053751))

cloudflare Argo tunnel `yay -S cloudflared` （使用[教程](https://www.blueskyxn.com/202102/4176.html)）

nmon `yay -S nmon` 

nload `yay -S nload` 

tcpflow `yay -S tcpflow` 

 pyroscope性能监测工具  `yay -S pyroscope-bin` (使用[教程](https://colobu.com/2022/01/27/pyroscope-a-continuous-profiling-platform/) [官方教程](https://pyroscope.io/docs/server-install-linux/))

crontab `yay -S cronie`

charles抓包工具  `yay -S charles ` ([注册码生成](https://www.charles.ren) [汉化](https://github.com/cuiqingandroid/CharlesZH))

参考

- vmware安装后报错的问题 https://blog.csdn.net/weixin_43968923/article/details/100184356

- 科学技术大学blackarch源使用说明 [https://lug.ustc.edu.cn/wiki/mirrors/help/blackarch](https://lug.ustc.edu.cn/wiki/mirrors/help/blackarch)

- jetbrains系列软件markdown插件无预览标签 `yay -S  java-openjfx-bin` ，参考[链接](https://intellij-support.jetbrains.com/hc/en-us/community/posts/360001515959-Markdown-Support-plugin-preview-not-working-in-Linux)

- 安装charless证书。导出根证书保存为pem格式。转换为crt格式

  `openssl x509 -in charles.pem -inform PEM -out ca.crt`

  信任证书`sudo trust anchor ca.crt`,done

## 服务器组件

### 数据库

redis `yay -S redis` 

percona-Server `yay -S percona-server`

postresql `yay -S postgresql` 

mongoDB `yay -S mongodb ` 或者 `yay -S mongodb-bin` 

percona-mongoDB `yay -S percona-server-mongodb-bin`  (mongosh `yay -S mongosh-bin`)

[Mariadb](https://wiki.archlinux.org/title/MariaDB) `yay -S mariadb`

tiup (可以快速启动tidb的playground) `curl --proto '=https' --tlsv1.2 -sSf https://tiup-mirrors.pingcap.com/install.sh | sh`

clickhouse `yay -S clickhouse` ([官方文档](https://clickhouse.com/docs/en/getting-started/install))

## 其他

screenfetch (终端打印出你的系统信息) 安装 `yay -S screenfetch`

neofetch `yay -S neofetch`

easystroke 鼠标手势 `yay -S easystroke`

![image-20220409140401125](https://assets.czyt.tech/img/image-20220409140401125.png)

copyQ (类似ditto) 安装 `yay -S copyq`

ifconfig、netstat 安装 `yay -S net-tools`

文件搜索albert（类似mac上的Spotlight） 安装 `yay -S albert`

Stow配置管理软件 安装 `yay -S stow`

snap 安装 `yay -S --noconfirm --needed snapd`

figlet 字符串logo生成工具 `yay -S figlet` 

软件包降级工具 downgrade `yay -S downgrade` 

thefuck输错命令更正工具 `yay -S thefuck` 

appimagelauncher 安装 `yay -S  appimagelauncher` 

终端文件管理器ranger 安装 `yay -S ranger` 

硬盘自动休眠 [hd-idle](http://hd-idle.sourceforge.net) 安装 `yay -S hd-idle`  （或者 `hdparam` ）

宽带连接 rp-pppoe 安装 `yay -S rp-pppoe` （参考[官方wiki](https://wiki.archlinux.org/title/NetworkManager_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87))）

磁盘清理

 ```bash
 sudo pacman -Scc
 journalctl --disk-usage
 sudo journalctl --vacuum-size=50M
 sudo rm /var/lib/systemd/coredump/*
 ```



参考

- 使用 Stow 管理多台机器配置[https://blog.csdn.net/F8qG7f9YD02Pe/article/details/104046845](https://blog.csdn.net/F8qG7f9YD02Pe/article/details/104046845)
- [https://zhuanlan.zhihu.com/p/106593833?utm_source=wechat_session&utm_medium=social&utm_oi=33332939194368](https://zhuanlan.zhihu.com/p/106593833?utm_source=wechat_session&utm_medium=social&utm_oi=33332939194368)
- 在Arch Linux/Manjaro上安装Snap [https://ywnz.com/linuxjc/4635.html](https://ywnz.com/linuxjc/4635.html)
- 修改主目录为英文 [原文](https://www.jianshu.com/p/73299b8e3f58)

```go
$ sudo pacman -S xdg-user-dirs-gtk
$ export LANG=en_US
$ xdg-user-dirs-gtk-update
# 然后会有个窗口提示语言更改，更新名称即可
$ export LANG=zh_CN.UTF-8
$ sudo pacman -Rs xdg-user-dirs-gtk

```

## 品牌笔记本支持

thinkpad thinkfan 安装`yay -S thinkfan`

> 获取温度传感器 `find /sys/devices -type f -name "temp*_input"`,Thinkpad T430 显示如下：
>
> sys/devices/platform/thinkpad_hwmon/hwmon/hwmon3/temp6_input
> /sys/devices/platform/thinkpad_hwmon/hwmon/hwmon3/temp3_input
> /sys/devices/platform/thinkpad_hwmon/hwmon/hwmon3/temp7_input
> /sys/devices/platform/thinkpad_hwmon/hwmon/hwmon3/temp4_input
> /sys/devices/platform/thinkpad_hwmon/hwmon/hwmon3/temp8_input
> /sys/devices/platform/thinkpad_hwmon/hwmon/hwmon3/temp1_input
> /sys/devices/platform/thinkpad_hwmon/hwmon/hwmon3/temp5_input
> /sys/devices/platform/thinkpad_hwmon/hwmon/hwmon3/temp2_input
> /sys/devices/platform/coretemp.0/hwmon/hwmon4/temp3_input
> /sys/devices/platform/coretemp.0/hwmon/hwmon4/temp4_input
> /sys/devices/platform/coretemp.0/hwmon/hwmon4/temp1_input
> /sys/devices/platform/coretemp.0/hwmon/hwmon4/temp5_input
> /sys/devices/platform/coretemp.0/hwmon/hwmon4/temp2_input
> /sys/devices/virtual/thermal/thermal_zone0/hwmon1/temp1_input




thinkpad 充电阀值软件 `yay -S tlp tp_smapi acpi_call  threshy threshy-gui` （ 需要 `systemctl enable tlp`）

参考

- https://wiki.archlinux.org/index.php/Laptop/Lenovo
- TLP  [https://wiki.archlinux.org/index.php/TLP_(简体中文)](https://wiki.archlinux.org/index.php/TLP_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87))
- thinkfan 配置及启动参考 https://wiki.archlinux.org/index.php/Thinkpad_Fan_Control
- [https://www.cnblogs.com/henryau/archive/2012/03/03/ubuntu_thinkfan.html](https://www.cnblogs.com/henryau/archive/2012/03/03/ubuntu_thinkfan.html)
- GDM [https://wiki.archlinux.org/index.php/GDM](https://wiki.archlinux.org/index.php/GDM)
- 强制登陆界面在主显示器上显示 [https://askubuntu.com/questions/11738/force-gdm-login-screen-to-the-primary-monitor](https://askubuntu.com/questions/11738/force-gdm-login-screen-to-the-primary-monitor)
- 指纹识别 [https://wiki.archlinux.org/index.php/Fprint](https://wiki.archlinux.org/index.php/Fprint)
- [Fix Intel CPU Throttling on Linux](https://github.com/erpalma/throttled)

## 网卡

8811cu `yay -S rtl8821cu-dkms-git `


 参考[链接](https://wiki.archlinux.org/index.php/Network_configuration/Wireless#rtl8811cu/rtl8821cu)

## 系统参数调优

### TRIM

如果你的manjaro根目录安装在固态硬盘上，那么建议你输入以下命令，TRIM会帮助清理SSD中的块，从而延长SSD的使用寿命：

```bash
sudo systemctl enable fstrim.timer
sudo systemctl start fstrim.timer
```

### SWAP设置

系统开机以后[内存](https://so.csdn.net/so/search?q=内存&spm=1001.2101.3001.7020)占用1.7g左右，通常有8-16g内存的电脑可以将swap使用率调低，这样可以提高电脑的性能。

- 查看swap使用率，一般是60，意思是60%的概率将内存整理到swap：cat /proc/sys/vm/swappiness

- 修改swap使用策略为10%，即10%的概率将内存整理到swap：sudo sysctl -w vm.swappiness=10

- 修改配置文件：sudo xed /etc/sysctl.d/99-swappiness.conf
  在文件末尾加上下面这行内容：
  vm.swappiness=10

- 重启后可查看swappiness的值，是10即可：cat /proc/sys/vm/swappiness

- 其他关于swap调整大小等等操作请参考“[ArchWiki关于Swap](https://wiki.archlinux.org/index.php/Swap)”
### Systemd journal size limit
参考 https://wiki.archlinux.org/index.php/systemd#Journal_size_limit

修改`/etc/systemd/journald.conf` 中的`SystemMaxUse`参数

```
SystemMaxUse=50M
```
### 其他

- [https://averagelinuxuser.com/10-things-to-do-after-installing-manjaro/](https://averagelinuxuser.com/10-things-to-do-after-installing-manjaro/)
- 字体渲染 [http://www.badwolfbay.cn/2020/03/17/manjaro-setting/](http://www.badwolfbay.cn/2020/03/17/manjaro-setting/)

## 常见问题
+ swappinessinvalid or corrupted package (PGP signature)

```bash
sudo rm -R /etc/pacman.d/gnupg/
sudo pacman-key --init
sudo pacman-key --populate archliswappinessnux
sudo pacman-key --populate archlinuxcn
```

+ 刷新dns[参考](https://wiki.archlinux.org/title/Systemd-resolved)

  ```bash
  sudo resolvectl flush-caches
  ```
+ KDE重建图标缓存
 `rm ~/.cache/icon-cache.kcache`

  

## 参考连接

- [swappinessarchlinux 简明指南](https://arch.icekylin.online)
- [How to Flush DNS Cache on Linux](https://www.bitslovers.com/linux-how-to-flush-dns/)
- [Manjaro 字体调优](https://wiki.manjaro.org/index.php/Improve_Font_Rendering)
- [Jetbrains License Server](https://github.com/Nasller/LicenseServer)
- [xps13(9370) Linux之路](https://github.com/kevinhwang91/xps-13-conf)