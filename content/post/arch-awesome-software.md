---
title: "Arch Linux 常用软件"
date: 2022-02-23
tags: ["linux", "Arch", "Manjaro", "tools"]
draft: false
weight: 9
---

> 本文部分内容基于manjaro，另外如果喜欢苹果界面，可以试下[pearos](https://pearos.xyz)。理论上基于Arch的发行版都可以使用本文进行安装。如果您安装好了manajro但是又不想重装系统，可以试下[这个脚本](https://github.com/saeziae/manjaro2archlinux)来将Manjaro自动转换为Arch,。
## Arch 安装后必装的软件

通过archinstall 安装以后，是没图形界面的。需要安装下面的一些软件和配置

>安装时，声音后端的选择：
>
>- PulseAudio，历史悠久、最为常用；
>- PipeWire，新生代，采用全新架构，整合多种音频后端（PulseAudio、ALSA和JACK），提供低延迟的音频体验

### 连接无线网

```bash
iwctl 
# 进入交互式命令行

device list 
# 列出无线网卡设备名，比如无线网卡看到叫 wlan0

station wlan0 scan 
# 扫描网络

station wlan0 get-networks 
# 列出所有 wifi 网络

station wlan0 connect wifi-name 
# 进行连接，注意这里无法输入中文。回车后输入密码即可

exit 
# 连接成功后退出
```

### 启用网络

```bash
systemctl enable dhcpcd
systemctl enable wpa_supplicant
systemctl enable NetworkManager
```

### 蓝牙

```bash
sudo systemctl enable --now bluetooth
```

>如果没这个服务，可能需要通过 `paru -S bluetooth`进行安装。
>
>如果需要启用蓝牙音频支持，请安装 `paru -S pulseaudio-bluetooth`
>
>蓝牙高级管理工具 `paru -S blueman`
>
>蓝牙协议支持与管理`paru -S bluez bluez-utils blueman `

### 微码

```bash
pacman -S intel-ucode 
# Intel
pacman -S amd-ucode 
# AMD
```

### 打印机

```bash
paru -S cups ghostscript gsfont
```

然后启动服务

```bash
sudo systemctl enable --now cups
// 可能需要启动
sudo systemctl enable --now cups-browsed
```

打印机驱动

```bash
paru -S foomatic-db foomatic-db-ppds   # 基本驱动
paru -S foomatic-db-nonfree foomatic-db-nonfree-ppds # 非自由软件驱动
```

### 启用MTP/PTP支持

和Windows一样，Linux也支持MTP、PTP设备，这样就可以方便地与安卓手机、数码相机等外设连接，管理文件。不过对这类设备的支持并非与生俱来，而是有赖于GVFS（Gnome Virtual File System），它把对其他设备或网络环境的访问抽象成一系列I/O接口，意味着可以像平时读写磁盘那样访问它们。

安装以下组件，分别启用GVFS本体，以及MTP、PTP支持。安装之后，无需额外设置，直接插入你的相关设备，即可识别。

```
sudo pacman -S gvfs gvfs-mtp gvfs-gphoto2
```

### NTFS支持

```bash
paru -S ntfs-3g ntfs-3g-fuse
```

> 注意：根据[Arch linux的wiki的说明](https://wiki.archlinuxcn.org/wiki/NTFS)
>
> >所有 5.15 及更新版本的[官方支持的内核](https://wiki.archlinuxcn.org/wiki/内核#官方支持的内核)都默认使用了 `CONFIG_NTFS3_FS=m` 参数，因此支持该驱动。在 5.15 版本前，NTFS 读写支持由 [NTFS-3G](https://wiki.archlinuxcn.org/wiki/NTFS-3G) FUSE 文件系统提供。或者也可以通过 [ntfs3-dkms](https://aur.archlinux.org/packages/ntfs3-dkms/)AUR 使用向后移植的 NTFS3。
> >
> 
> 新版本的都不需要安装上述组件.挂载失败后，可以通过`dmesg`查看失败原因，一般比较常遇到的是`sda1: volume is dirty and "force" flag is not set!`这个错误，可以通过 `ntfsfix -d /dev/sdx`进行修复就可以正常挂载了。

### 语言编码配置

在某些时候进入系统以后，发现编码没配置好，中文乱码，可以编辑 /etc/locale.gen，去掉 en_US.UTF-8 UTF-8 以及 zh_CN.UTF-8 UTF-8 行前的注释。

```bash
vim /etc/locale.gen
```

然后生成 locale-gen：

```bash
locale-gen
```

在/etc/locale.conf 输入内容：

```bash
echo 'LANG=en_US.UTF-8'  > /etc/locale.conf
```

### 更改时区

可以使用`timedatectl`命令来进行时区等信息的调整。常见命令如下：

+ `timedatectl set-time YYYY-MM-DD` 更改日期

+ `timedatectl set-time HH:MM:SS` 更改时间

+ `timedatectl list-timezones `列出所有时区

+ `timedatectl set-timezone time-zone` 设置时区

+ `timedatectl set-ntp boolean` 设置NTP服务器

也可以通过下面的命令设置时区
`ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime`
同步时间到硬件：`hwclock --systohc`

### deb包

在 Arch Linux 安装 .deb 包不是直接支持的，因为 Arch 使用的是 .pkg.tar.xz 作为其包格式。不过，你可以使用 debtap 这个工具来转换 .deb 包到 Arch Linux 可以识别的格式，之后再进行安装。这里是如何做到这点的步骤：
首先，你需要从 AUR 安装 debtap 工具。你可以使用 yay 或任何其他 AUR 帮助器来安装它，如果你没有安装 AUR 帮助器，可以手动克隆 debtap 的 AUR 仓库并构建它：

```bash
paru -S debtap
```

然后，你需要更新 debtap 的数据库：
```bash
sudo debtap -u
```

注意，你可能需要多次运行此命令，直到不再显示有新的更新。
接下来，将 .deb 包转换为 Arch Linux 包格式：

```bash
debtap <package-name>.deb
```

转换之后，生成的 PKG 文件可以使用 pacman 进行安装：
```bash
sudo pacman -U <package-name>.pkg.tar.xz
```

### 安装桌面

#### KDE

安装KDE软件

```bash
paru -S plasma-meta sddm
```

启用登录

```bash
sudo systemctl enable --now sddm
```

其他KDE软件

```bash
paru -S konsole kde-utilities ark dolphin
```

>KDE提供了全家桶套装。可以按需选用：
>
>| kde-utilities  | 系统工具，包含了KDE桌面环境所需的基本应用，如文件管理器Dolphin、终端工具Konsole。**应当安装。** |
>| -------------- | ------------------------------------------------------------ |
>| kde-multimedia | 多媒体工具，包含几款多媒体播放器（如Dragon）和编辑器等。     |
>| kde-graphics   | 图形工具，包含图片查看器Gwenview、PDF查看器Okular、截图工具Spectacle等。**建议安装。** |
>| kde-education  | 教育工具，包括虚拟地球仪Marble、日语学习工具Kiten、海龟绘图工具KTurtle等。 |
>| kde-network    | 网络应用程序，包含全功能浏览器Konqueror、即时通讯工具Telepathy、远程桌面工具KRDC等。 |
>| kde-games      | KDE团队开发的一系列游戏，不妨一试。                          |

由于 KDE 自带的文件索引程序 baloo 可能严重拖慢计算机性能，建议您关闭 baloo。具体命令为

```bash
$ balooctl suspend
$ balooctl disable
```

#### XFCE

```bash
paru --needed xfce4-goodies
```

### 中文字体

```bash
paru -S adobe-source-han-sans-cn-fonts adobe-source-han-serif-cn-fonts noto-fonts-cjk wqy-microhei wqy-microhei-lite wqy-bitmapfont wqy-zenhei ttf-arphic-ukai ttf-arphic-uming
```

其他配置选项参考 [Arch wiki 简体中文本地化](https://wiki.archlinuxcn.org/wiki/%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87%E6%9C%AC%E5%9C%B0%E5%8C%96)

### cinnamon 

```bash
sudo pacman -S cinnamon gnome-terminal xorg lightdm lightdm-gtk-greeter
```

添加 lightdm 守护进程并进入桌面环境：

```bash
sudo systemctl enable --now lightdm
```



## 更换软件源

Arch可以使用 reflector 来选择速度比较好的源：

```bash
reflector -p https -c China --delay 3 --completion-percent 95 --sort score 
```

> 2020 年，archlinux 安装镜像中加入了 reflector 服务，它会自己更新 mirrorlist。在特定情况下，它会误删某些有用的源信息。这里进入安装环境后的第一件事就是将其禁用。也许它是一个好用的工具，但是很明显，因为地理上造成的特殊网络环境，这项服务并不适合加入到守护进程。使用下列命令禁用：
>
> ```bash
> systemctl disable reflector.service
> ```

Manjaro可以使用中国的镜像排名

```bash
sudo pacman-mirrors -i -c China -m rank //更新镜像排名
sudo pacman-mirrors -g //排列数据源
```

然后更新下

```bash
sudo pacman -Syy //更新数据源
```

添加[archlinuxcn](https://www.archlinuxcn.org/archlinux-cn-repo-and-mirror/)源 ,修改 `sudo nano /etc/pacman.conf` 添加下面的内容

```bash
[archlinuxcn]
Server = https://repo.archlinuxcn.org/$arch
```

如果使用镜像源，可以使用下面清华和中科大的镜像配置

```bash
[archlinuxcn]
SigLevel = Optional TrustAll
Server = https://mirrors.tuna.tsinghua.edu.cn/archlinuxcn/$arch
Server = https://mirrors.ustc.edu.cn/archlinuxcn/$arch
```
强烈建议开启 pacman 的颜色和多线程下载功能，编辑 **`/etc/pacman.conf`** 文件，将对应位置前 **#** 删除即可：

```shell
...
#UseSyslog
Color
#NoProgressBar
CheckSpace
#VerbosePkgLists
ParallelDownloads = 4
...
```

安装 [archlinuxcn-mirrorlist-git](https://github.com/archlinuxcn/repo/tree/master/archlinuxcn/archlinuxcn-mirrorlist-git) 包可以获得一份镜像列表，以便在 pacman.conf 中直接引入

```bash
sudo pacman -S archlinuxcn-mirrorlist-git
```

然后再更新软件数据源

```bash
sudo pacman -Syy
sudo pacman -S archlinux-keyring archlinuxcn-keyring
```

>由于开发者退休，导致新安装的系统中，farseerfc 的 GPG key 是勉强信任的，如遇“error: archlinuxcn-keyring: Signature from "Jiachen YANG (Arch Linux Packager Signing Key) " is marginal trust”报错，请手动信任一下该 key：[[1\]](https://wiki.archlinuxcn.org/wiki/Arch_Linux_中文社区仓库#cite_note-1)
>
>```
>sudo pacman-key --lsign-key "farseerfc@archlinux.org
>```

如何证书有问题，可以使用下面的命令进行修复,参考[官方wiki](https://wiki.archlinux.org/title/Pacman/Package_signing)

```bash
sudo pacman-key --init && sudo pacman-key --populate
```

使用 pacman 安装和更新软件包时，软件包会下载到 /var/cache/pacman/pkg/ 目录下。久而久之，缓存会占据大量的存储空间。因此，定期清理软件包缓存是必要的。请安装 pacman-contrib 软件包，然后开机自动启动 paccache.timer，以便每周自动清理不使用的软件包缓存。

```bash
# pacman -S pacman-contrib
# systemctl enable paccache.timer
```

因为本文的软件使用paru进行安装，故需要使用命令进行安装，命令为  ` sudo pacman -S paru`

> 注：类似的包管理器还有 `yay` 可以使用 `sudo pacman -S yay`进行安装
> 设置yay的mirror
>
> ```bash
> yay --aururl "https://aur.tuna.tsinghua.edu.cn" --save
> ```
> yay的配置文件路径为 `$XDG_CONFIG_HOME/yay/` 如果使用有问题，可以删除config.json实现重置。

可选安装 编译包 `paru -S base-devel` 


>`paru <target>` -- Interactively search and install `<target>`.
>
>`paru` -- Alias for `paru -Syu`.
>
>`paru -S <target>` -- Install a specific package.
>
>`paru -Sua` -- Upgrade AUR packages.
>
>`paru -Qua` -- Print available AUR updates.
>
>`paru -G <target>` -- Download the PKGBUILD and related files of `<target>`.
>
>`paru -Gp <target>` -- Print the PKGBUILD of `<target>`.
>
>`paru -Gc <target>` -- Print the AUR comments of `<target>`.
>
>`paru --gendb` -- Generate the devel database for tracking `*-git` packages. This is only needed when you initially start using paru.
>
>`paru -Bi .` -- Build and install a PKGBUILD in the current directory.

一些基础命令，如hostname的包 `paru -S inetutils `

## 窗口管理Wayland

> 这部分取自文章 [ArchLinux下Hyprland配置指北](https://www.bilibili.com/read/cv22707313/)

# 安装Wayland

首先使用以下命令安装Wayland所需环境，如果需要兼容 xorg 软件记得加上 **xorg-xwayland** 软件包：

```shell
sudo pacman -S xorg-xwayland qt5-wayland qt6-wayland glfw-wayland
```

要查看当前有哪些客户端是使用 xorg 的，可以安装 **xorg-xlsclients** 然后查看：

```shell
sudo pacman -S xorg-xlsclients
 # 查看
 xlsclients
```

# 安装 Hyprland

Hyprland 是 Wayland 环境下的一个很棒的合成器，支持窗口透明、模糊、圆角、插件和动画效果等，不过目前还没有发布正式稳定版，所以很多发行版都没有上架，目前支持的发行版在官方安装教程里面列出了：Hyprland Installation 。虽然没有发布稳定版，但是日常使用已经没有什么问题了。

如果安装了 AUR 工具，那么可以直接进行安装，不用自己配置：**`paru -S hyprland-bin`** 。这里演示一下源码安装：

1. 安装依赖

```shell
paru -S gdb ninja gcc cmake meson libxcb xcb-proto xcb-util xcb-util-keysyms libxfixes libx11 libxcomposite xorg-xinput libxrender pixman wayland-protocols cairo pango seatd libxkbcommon xcb-util-wm xorg-xwayland libinput
```

1. 下载源码

```shell
git clone --recursive https://github.com/hyprwm/Hyprland
```

1. 编译安装

```shell
cd Hyprland
meson _build
ninja -C _build
ninja -C _build install
```

# 复制配置文件

安装好 Hyprland 后记得复制配置文件到用户文件夹：

```shell
mkdir -pv ~/.config/hypr
 # 如果是 AUR 安装
 sudo cp /usr/share/hyprland/hyprland.conf ~/.config/hypr/
 # 如果是源码安装
 sudo cp /usr/local/share/hyprland/hyprland.conf ~/.config/hypr
 # 配置文件内都有详细注释，虽然全是英文～
```

# 配置登录启动

此处配置适用于不使用登录服务器的，如果使用登录服务器请参考 登录服务器启动Hyprland 。

由于使用 Wayland ，所以就不能像 Xorg 下使用 startx 快速启动桌面环境了，我一般手动登录后，输入 **start_hyprland** 进行桌面环境，首先编辑 **`~/.bash_profile`** 文件，如果使用 **fish 、zsh** 等请参考其配置文件名称：

```shell
# 启动 wayland 桌面前设置一些环境变量
 function set_wayland_env
 {
  cd ${HOME}
  # 设置语言环境为中文
  export LANG=zh_CN.UTF-8
  # 解决QT程序缩放问题
  export QT_AUTO_SCREEN_SCALE_FACTOR=1
  # QT使用wayland和gtk
  export QT_QPA_PLATFORM="wayland;xcb"
  export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
  # 使用qt5ct软件配置QT程序外观
  export QT_QPA_PLATFORMTHEME=qt5ct

  # 一些游戏使用wayland
  export SDL_VIDEODRIVER=wayland
  # 解决java程序启动黑屏错误
  export _JAVA_AWT_WM_NONEREPARENTING=1
  # GTK后端为 wayland和x11,优先wayland
  export GDK_BACKEND="wayland,x11"

 }

 # 命令行输入这个命令启动hyprland,可以自定义
 function start_hyprland
 {
  set_wayland_env

  export XDG_SESSION_TYPE=wayland
  export XDG_SESSION_DESKTOP=Hyprland
  export XDG_CURRENT_DESKTOP=Hyprland
  # 启动 Hyprland程序
  exec Hyprland

 }
```

可以参考下https://github.com/JaKooLit/Arch-Hyprland 安装脚本如下：

```bash
git clone --depth=1 https://github.com/JaKooLit/Arch-Hyprland.git ~/Arch-Hyprland
cd ~/Arch-Hyprland
chmod +x install.sh
./install.sh
```

# 常用软件安装和启用

现在直接进入 Hyprland 环境你会发现什么东西都没有，不用着急，下面的内容就是补全这些内容，让你使用起来更方便。

# 配置壁纸

进入桌面最先看到的应该是壁纸才对，**Sway** 是个很好的窗口管理器，不仅是它好用，还有它提供的一套好用的类似 i3 的软件包，比如配置壁纸就可以使用 **swaybg** 。

使用命令行安装 swaybg 然后在 Hyprland 配置文件中启动（窗口管理器不像桌面环境，很多软件都需要我们手动启动，好在 Hyprland提供了启动这些软件的方法）：

```shell
# 安装 swaybg
 sudo pacman -S swaybg
 # 编辑 ~/.config/hypr/hyprland.conf 文件
 #---------------------------------------
 $wallpaper_path=<你放壁纸的完整路径>
 exec-once=swaybg -i $wallpaper_path -m fill
 #---------------------------------------

exec-once 表示我们只需要在 Hyprland 启动的时候执行，在每次保存配置文件后，Hyprland 会自动读取配置，如果要每次配置完都执行，可以使用 exec 。如果要配置随机壁纸，请将壁纸放在一个文件夹下，然后替换上面的配置为：

 $wallpaper_dir=<你存放壁纸的目录>
 exec-once=swaybg -i $(find $wallpaper_dir -type f | shuf -n 1) -m fill
```

# 配置顶栏

这个顶栏很好理解，用来显示系统的一些信息，比如工作区、网络、声音、亮度、电量、系统托盘等。wayland 下可以使用 **waybar** ，支持很多模块显示，不过官方版本对 Hyprland 的工作区有点问题，建议安装 AUR 上对工作区进行修复的版本：

```shell
# 安装官方版本
 sudo pacman -S waybar
 # 安装 Hyprland 工作区修复版本
 paru -S waybar-hyprland
```

waybar 配置文件在 **`~/.config/waybar`** 目录下的 **config.json** 和 **style.css** 文件，如果自己不会配置可以在 Github 上搜索 **waybar theme** 使用别人配置好的，篇幅原因这里不进行介绍。

配置文件弄好后还需要在 Hypeland 配置文件中启动：**`exec-once=waybar`** 。

# 软件启动器

桌面环境下，我们可以点击桌面图标和软件菜单启动程序，wayland 窗口管理器下一般使用 bmenu 或者 rofi，**rofi** 更加美观，推荐使用，不过需要使用经过修复的 rofi ，否则无法正常工作，使用 AUR 安装：**`paru -S rofi-lbonn-wayland-only-git`** 。其配置文件位于 **`~/.config/rofi/`** 目录下，美化不进行介绍，可以参考 waybar 方法在 Github 上查找。

在 hyprland 配置文件中绑定快捷键即可：

```shell
$menu=rofi -show drun
bind = SUPER, R, exec, $menu
```

# 通知守护程序

平时使用，接收通知是必须的，wayland 下可以使用 **dunst、mako** 等守护程序：

```shell
# 安装 mako
 sudo pacman -S mako
 # hyprland 配置
 #--------------------
 exec-once=mako
 #--------------------
```

如果需要使用命令行发送通知，可以安装 **`toastify`** ，之后使用 `notify-send "通知内容"` 可以发送通知。

# 复制与粘贴

剪切板管理工具也经常用到，wayland 下可以使用 **clipman(只能管理文字) 或 cliphist(文字加图片)** ：

```shell
paru -S cliphist wl-clipboard
 # 基本使用方法
 # 拷贝
 echo "Hello World" | wl-copy
 # 粘贴
 wl-paste

在配置文件里启用：

 # 这个会自动监控剪切板，然后将复制的内容保存到本地数据库中。
 exec-once=wl-paste --type text --watch cliphist store
 exec-once=wl-paste --type image --watch cliphist store
 # 在一个软件内复制，这软件关闭后无法进行粘贴，需要配置快捷键显示剪切板历史
 bind=SUPER_SHIFT, V, exec, cliphist list | rofi -dmenu | cliphist decode | wl-copy
 # 内容太多记得手动删除哟，cliphist每提供一键删除，必须差评！
 for i in $(cliphist list | awk -F. '{ print $2 }'); do cliphist delete-query "$i"; done
```

## AI工具

[ollama](https://ollama.com) 在本地启动并运行大型语言模型`paru -S ollama `

chatbox 聚合聊天工具 `paru -S chatbox-appimage`

[mods](https://github.com/charmbracelet/mods) `paru -S mods`


## SSH管理工具

### 终端工具

深度终端 安装 `paru -S deepin-terminal` 

alacritty 安装 `paru -S alacritty ` 

终端渐变色工具lolcat `paru -S lolcat` 

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

vivaldi 安装 `paru -S vivaldi vivaldi-ffmpeg-codecs` 

microsoft Edge `paru -S microsoft-edge-stable-bin`

Chrome 安装 `paru -S google-chrome chromium-codecs-ffmpeg  chromium-codecs-ffmpeg-extra`

Opera 安装 `paru -S opera opera-ffmpeg-codecs `

brave浏览器 `paru -S brave-bin `

firefox 安装 `paru -S firefox `

社区维护版本firefox `paru -S librewolf-bin`

> 参考
>
> - 解决打开Chrome出现 输入密码以解锁您的登录密钥环 [https://blog.csdn.net/kangear/article/details/20789451](https://blog.csdn.net/kangear/article/details/20789451)
> - bilibili视频不能播放的问题 需要安装对应浏览器的解码包。

tor `paru -S tor-browser-bin `

## 翻译软件

有道词典 安装 `paru -S youdao-dict`

金山词霸 安装 `paru -S powerword-bin` 

goldendict 安装 `paru -S goldendict` [词库](https://github.com/czytcn/goldendict)

[crow-translate](https://github.com/crow-translate/crow-translate) 翻译工具`paru -S crow-translate`


## 聊天软件

微信 安装 `paru -S deepin-wine-wechat`  (新版可能卡死，可以使用下面的命令`killall WeChatBrowser.exe && /opt/deepinwine/tools/sendkeys.sh w wechat 4`)

 [微信Spark Store版本](https://aur.archlinux.org/packages/com.qq.weixin.spark) `paru -S com.qq.weixin.spark`

> 这各版本的微信新版本会安装deepin-wine8,如果出现中文字体方框，需要安装文泉驿微米黑字体 `paru -S wqy-microhei`

微信Linux原生版本  `paru -S wechat-universal-bwrap`

> 更多请参考 https://wiki.archlinuxcn.org/zh/%E5%BE%AE%E4%BF%A1

QQ 安装 `paru -S deepin-wine-qq`如果你喜欢各种破解，可以试试下载dreamcast的QQ，替换wine下的QQ。命令参考 `sudo mv ./QQ ~/.deepinwine/Deepin-QQ/drive_c/"Program Files"/Tencent`

新版LinuxQQ `paru -S linuxqq`

tim `paru -S com.qq.tim.spark` 

ipmsg 安装`paru -S iptux`

mattermost 安装 `paru -S mattermost-desktop`

slack 安装 `paru -S slack-desktop` 

Discord  安装 `paru -S discord`

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
>
>### Discord设置代理
>
>编辑`/usr/share/applications`下的discord.desktop文件
>
>修改Exec部分为下面内容
>
>```ini
>Exec=http_proxy=socks5://127.0.0.1:10808 https_proxy=socks5://127.0.0.1:10808 ALL_PROXY=socks5://127.0.0.1:10808 /usr/bin/discord --proxy-server="socks5://127.0.0.1:10808"
>```
>
>完整的文件内容如下：
>
>```bash
>[Desktop Entry]
>Name=Discord
>StartupWMClass=discord
>Comment=All-in-one voice and text chat for gamers that's free, secure, and works on both your desktop and phone.
>GenericName=Internet Messenger
>Exec=http_proxy=socks5://127.0.0.1:10808 https_proxy=socks5://127.0.0.1:10808 ALL_PROXY=socks5://127.0.0.1:10808 /usr/bin/discord --proxy-server="socks5://127.0.0.1:10808"
>Icon=discord
>Type=Application
>Categories=Network;InstantMessaging;
>Path=/usr/bin
>
>```
>
>参考 https://gist.github.com/mzpqnxow/ca4b4ae0accf2d3b275537332ccbe86e

Telegram `paru -S telegram-desktop` 

> telegram的中文语言包
>
> 简体语言包 只收录翻译完整度超过50%的汉化包
> 标准中文语言包：
> * 中文(简体)-聪聪:  t.me/setlanguage/zhcncc
> * 中文(简体)-@zh_CN:  t.me/setlanguage/classic-zh-cn
> * 中文(简体)-简体:  t.me/setlanguage/classic-zh （停更）
> * 中文(简体)-zh-hans:  t.me/setlanguage/zh-hans-beta
> * 中文(简体)-小蛙： t.me/setlanguage/xiaowawa 纯粹中文
> * 中文(简体)-@cnmoe:  t.me/setlanguage/moecn
> * 中文(简体)-@teslacn:  t.me/setlanguage/vexzh
> * 中文(简体)-:  t.me/setlanguage/cnsimplified
>
> 个性化语言包 
> * 中文(简体)-@oxoao：花里胡哨: t.me/setlanguage/qingwa 🌸
> * 中文(简体)-@oxoao：稀奇古怪: t.me/setlanguage/xiaowa 🥸
> * 中文(简体)-@oxoao：羊村主题: t.me/setlanguage/wayang 🌴
> * 中文(简体)-@oxoao：色色主题: t.me/setlanguage/ydorz 👅
> * 中文(简体)-@MiaoCN:  喵体中文: t.me/setlanguage/meowcn 🐱
> * 中文(简体)-江湖中文版:  t.me/setlanguage/jianghu 🗡
> * 中文(简体)-江湖侠客版:  t.me/setlanguage/baoku  🗡
> * 中文(简体)-瓜体中文:  t.me/setlanguage/duang-zh-cn 🍉 （停更）
> * 中文(简体)-瓜皮中文:  t.me/setlanguage/duangr-zhcn 🍉
>
> 繁体中文语言包
> * 中文(香港)-简体中文:  t.me/setlanguage/zh-hans-raw
> * 中文(香港)-繁体1:  t.me/setlanguage/hongkong
> * 中文(香港)-繁体2:  t.me/setlanguage/zh-hant-raw
> * 中文(香港)-人口语:   t.me/setlanguage/hongkonger （不支持桌面）
> * 中文(香港)-廣東話:  t.me/setlanguage/cantonese
> * 中文(香港)-郭桓桓:  t.me/setlanguage/zhong-taiwan-traditional
> * 中文(台灣)-正体:  t.me/setlanguage/taiwan
> * 中文(台灣)-繁体:  t.me/setlanguage/zh-hant-beta
> * 中文(台灣)-文言:  t.me/setlanguage/chinese-ancient
> * 中文(台灣)-魔法師:  t.me/setlanguage/encha

### 可自建的聊天软件

mattermost 安装 `paru -S mattermost` [参阅](https://wiki.archlinux.org/title/Mattermost)

rocketchat-server 安装 `paru -S rocketchat-server ` 

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

文件蜈蚣 安装 `paru -S  filecentipede-bin ` [激活码](http://www.filecxx.com/zh_CN/activation_code.html)

MegaSync 安装 `paru -S megasync-bin` 或 `paru -S megasync`

115网盘 安装 `paru -S 115pc`

天翼云盘 安装 `paru -S cloudpan189-go`

OneDive 安装 `paru -S onedrive` 或者 `paru -S onedrive-abraunegg` (GUI `paru -S onedrivegui-git `) 或者使用onedriver（推荐） `paru -S onedriver`

百度云 安装 `paru -S baidunetdisk-bin` 或者 安装深度的版本 `paru -S deepin-baidu-pan`

坚果云 安装 `paru -S nutstore` 或者 坚果云实验版 `paru -S nutstore-experimental `(推荐)

[^坚果云窗口太小，看不到输入框。]: 可以用 `sudo pacman -S gvfs libappindicator-gtk3`

DropBox 安装 `paru -S dropbox` 

resilio sync 安装 ` paru -S rslsync` 

迅雷linux版本 安装 `paru -S xunlei-bin` 

迅雷极速版 `paru -S deepin-wine-thunderspeed`

rclone 同步工具 `paru -S rclone` ([同步onedrive配置](https://rclone.org/onedrive/) [GUI](https://rclone.org/gui/))

axel 安装 `paru -S axel`

localsend 安装 `paru -S localsend-bin`

zssh 安装 `paru -S zssh` 配合lrzsz(安装命令 `paru -S lrzsz`)食用效果最佳。

>lrzsz 安装后在/usr/bin下面目录下有下面几个文件lrzsz-rb、lrzsz-rx、lrzsz-rz、lrzsz-sb、lrzsz-sx、lrzsz-sz可以使用下面的命令去掉文件名中的lrzsz- 并添加执行权限
>
>```bash
>for f in lrzsz-*; do
>    mv "$f" "${f#lrzsz-}"
>    chmod +x "${f#lrzsz-}"
>done
>```

[trzsz](https://github.com/trzsz/trzsz) 安装 `paru -S trzsz ` 

motrix 安装 `paru -S motrix`  

gopeed 安装 `paru -S gopeed-bin`

uget 安装 `paru -S uget`

Mega网盘安装 `paru -S megatools-git` 

qbittorrent 安装  `paru -S qbittorrent`([增强版](https://github.com/c0re100/qBittorrent-Enhanced-Edition/releases) `paru -S qbittorrent-enhanced-git` [搜索插件](https://github.com/qbittorrent/search-plugins/wiki/Unofficial-search-plugins))

moose 支持边下边播的BT工具 `paru -S moose ` 

youtube视频下载器 `paru -S yt-dlp `或者 `paru -S yt-dlp-git `

[Spacedrive](https://www.spacedrive.com/) 安装 `paru -S spacedrive-bin`

参考

- dreamcast的网盘 http://dreamcast2.ys168.com
- zssh介绍 http://www.v5b7.com/other/zssh.html

## 办公软件

钉钉 安装 `paru -S  dingtalk-electron ` 

企业微信 `paru -S deepin-wine-wxwork` 

腾讯会议 `paru -S wemeet-bin`

飞书 `paru -S feishu-bin`

[tailscale](https://tailscale.com) 安装 `paru -S tailscale` 

[达芬奇视频剪辑](http://www.blackmagicdesign.com/products/davinciresolve/) 安装 `paru -S davinci-resolve` 

handbrake 视频格式转换工具 `paru -S handbrake-full`

[zettlr](https://www.zettlr.com) markdown编辑器 安装 `paru -S zettlr ` 

[vnode](https://tamlok.github.io/vnote/zh_cn/#!index.md) markdown编辑器 安装 `paru -S vnote` 

Wps 安装 `paru -S wps-office ttf-wps-fonts wps-office-mui-zh-cn  wps-office-mime`

> 安装wps国内版可以使用 `paru -S wps-office-cn wps-office-mui-zh-cn ttf-wps-fonts`

libreoffice 安装  `paru -S libreoffice` 
geogebra 几何绘图软件 `paru -S geogebra  `

labplot科学绘图 `paru -S labplot ` 
xmind-2020 安装 `paru -S xmind-2020` ([福利链接](https://mega.nz/folder/MxpkmaCZ#Il82PxQ5s9iLgLCMbMf68g))

yed 安装 `paru -S yed`

drawio  安装` paru -S drawio-desktop-bin` 或者 ` paru -S drawio-desktop`

在线流程图工具 [https://excalidraw.com](https://excalidraw.com)

### 截图及录屏工具

flameshot 截图工具 安装 `paru -S flameshot` 

Snipaste 截图工具  安装 `paru -S Snipaste  `

kazam录屏软件 安装 `paru -S kazam `

屏幕录制为gif 工具 peek `paru -S peek`

> 这个工具已经停止维护

### 阅读工具

福昕pdf阅读器 `paru -S foxitreader` 

masterpdfeditor 对linux用户免费的PDF浏览及编辑器,支持实时预览 `paru -S masterpdfeditor  `

Okular （[KDE上的通用文档阅读器](https://www.appinn.com/okular/)）` paru -S okular` 

Foliate [简单、现代的电子书阅读器](https://www.appinn.com/foliate-for-linux/) 安装 `paru -S foliate` 

pdf合并工具 `paru -S pdfmerger`

### 远程工具

Remmina 安装 `paru -S remmina`
可以选装这些插件


```bash
freerdp remmina-plugin-teamviewer remmina-plugin-webkit remmina-plugin-rdesktop remmina-plugin-anydesk-git remmina-plugin-rustdesk
```

Teamviewer `paru -S teamviewer`如果一直显示未连接，则请退出teamviewer，执行`sudo teamviewer --daemon enable` 再打开试试

Xrdp `paru -S xrdp xorgxrdp-git` ([参考文档](https://wiki.archlinux.org/title/xrdp))

rustdesk `paru -S rustdesk-bin`

向日葵 安装 `paru -S sunloginclient` (需要设置开机启动服务 `systemctl enable runsunloginclient` 启动服务 `systemctl start runsunloginclient` )

toDesk远程工具 安装 `paru -S todesk-bin` (设置服务 `systemctl start\enable todeskd` 才能正常运行)

parsec 远程工具 安装 `paru -S parsec-bin ` 
realvnc-server `paru -S realvnc-vnc-server ` (安装完毕后需要注册`sudo vnclicense -add 3TH6P-DV5AE-BLHY6-PNENS-B3AQA`,启动服务 `systemctl enable vncserver-x11-serviced`)

realvnc-viewer `paru -S realvnc-vnc-viewer`

### 网络代理工具

[看雪安全接入](https://ksa.kanxue.com)ksa 安装 `paru -S ksa` 
v2ray 安装 `paru -S v2ray`  （安装配置工具`paru -S qv2ray ` qv2ray 插件 `paru -S qv2ray-plugin` ，[福利订阅](https://jiang.netlify.app) 新版已经使用AppImage格式发布，下载AppImage格式即可 或者 v2rayDesktop `paru -S v2ray-desktop` ）

gost 安装 `paru -S gost` 

>我们一般当客户端使用，连接服务器：
>
>```bash
> `sudo gost -L=:1080 -F=quic://xx.xxx.tech:11111`
>```

clash-verge-bin `paru -S clash-verge-bin`

clash https://aur.archlinux.org/packages?K=clash [福利](https://neko-warp.nloli.xyz)

[nekoray-bin ](https://github.com/MatsuriDayo/nekoray)Qt based cross-platform GUI proxy configuration manager  安装 `paru -S nekoray-bin`( 可能需要安装相关插件 `paru -S sing-geosite sing-geoip sing-geoip-common sing-geoip-db sing-geoip-rule-set sing-geosite-common sing-geosite-db sing-geosite-rule-set `然后核心位置填写`/usr/share/sing-box`)

cloudflare Warp 安装 `paru -S cloudflare-warp-bin`  [基于wiregurd](https://www.ianbashford.net/post/setupcloudflarewarplinuxarch/) [自选ip脚本](https://gitlab.com/rwkgyg/CFwarp) [自选ip脚本2](https://gitlab.com/ProjectWARP/warp-script)

>如报错： DNS connectivity check failed with reason DNSLookupFailed，请尝试
>
>1. 在 `/etc/systemd/resolved.conf`中加入下面这一行内容
>
>```
>ResolveUnicastSingleLabel=yes
>```
>
>2. 重启服务
>
>```
>$ sudo systemctl restart systemd-resolved.service
>```
>
>更多问题解决，请参考 [Cloudflare Troubleshooting](https://github.com/cloudflare/cloudflare-docs/blob/production/content/cloudflare-one/faq/teams-troubleshooting.md)


n2n [VPN软件](https://www.meirenji.info/2018/02/03/N2N%E7%BB%84%E7%BD%91-%E5%AE%9E%E7%8E%B0%E5%AE%B6%E9%87%8C%E8%AE%BF%E4%B8%8E%E5%85%AC%E5%8F%B8%E7%BD%91%E7%BB%9C%E4%BA%92%E8%AE%BF-%E7%B2%BE%E7%BC%96%E7%89%88/) `paru -S n2n` 

proxychains-ng 安装 `paru -S proxychains-ng`

tsockets 安装 `paru -S tsocks-tools`

### 笔记软件

evernote 开源版本 nixnote2 安装 `paru -S nixnote2` 

joplin 安装 `paru -S joplin` or `paru -S joplin-desktop`

onenote `paru -S p3x-onenote` 

Zotero  `paru -S zotero-bin`

AFFiNE `paru -S affine-bin` or  `paru -S affine-latest-bin`

### U盘启动制作


U盘启动制作[etcher](https://github.com/balena-io/etcher) `paru -S etcher-bin` 

[ isoimagewriter](https://aur.archlinux.org/packages/isoimagewriter) `paru -S isoimagewriter`

[rpi-imager](https://aur.archlinux.org/packages/rpi-imager) 树莓派的镜像写入工具 `paru -S rpi-imager `

### 其他

剪切板工具 [uniclip](https://github.com/quackduck/uniclip) `paru -S uniclip`

Screen屏幕共享软件 安装 `paru -S screen-desktop ` 

### 字体

windows11 字体 `paru -S ttf-ms-win11-auto `

>如果是针对某种语言，可以按下面内容进行安装：
>
>ttf-ms-win11-auto-japanese			Microsoft Windows 11 Japanese TrueType fonts
>ttf-ms-win11-auto-korean Microsoft Windows 11 Korean TrueType fonts
>ttf-ms-win11-auto-sea		Microsoft Windows 11 Southeast Asian TrueType fonts
>ttf-ms-win11-auto-thai	Microsoft Windows 11 Thai TrueType fonts	
>ttf-ms-win11-auto-zh_cn	Microsoft Windows 11 Simplified Chinese TrueType fonts
>ttf-ms-win11-auto-zh_tw	Microsoft Windows 11 Traditional Chinese TrueType fonts
>ttf-ms-win11-auto-other


参考

- proxychains-ng 使用 [https://wsgzao.github.io/post/proxychains/](https://wsgzao.github.io/post/proxychains/)
- Linux中制作U盘启动盘的三种方法 [https://ywnz.com/linuxjc/5620.html](https://ywnz.com/linuxjc/5620.html)

## 输入法

### fcitx

sun输入法 安装 `paru -S fcitx fcitx-im fcitx-configtool fcitx-sunpinyin fcitx-googlepinyin fcitx-cloudpinyin fcitx-libpinyin`

皮肤 安装 `paru -S fcitx-skin-material` 

百度输入法 安装 `paru -S fcitx-baidupinyin` 安装完成以后记得重启下，不然输入候选框会乱码。

讯飞输入法 安装 `paru -S  iflyime` 
or `paru -S manjaro-asian-input-support-fcitx` 

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
paru -S wqy-bitmapfont wqy-microhei wqy-zenhei adobe-source-code-pro-fonts  adobe-source-han-sans-cn-fonts ttf-monaco noto-fonts-emoji 
ttf-ms-fonts ttf-sarasa-gothic noto-fonts-cjk  noto-fonts-sc 
```

下面是一些编程字体

```bash
paru -S ttf-fira-code nerd-fonts-complete ttf-lilex otf-monaspace nerd-fonts-sarasa-term ttf-maple-latest 	ttc-iosevka
```

输入法有问题，需要重置，使用命令 `rm -r ~/.config/fcitx` 然后注销即可。

### fcitx5

基本安装 `paru -S fcitx5-im fcitx5-chinese-addons  `

或者 `paru -S manjaro-asian-input-support-fcitx5 fcitx5 fcitx5-configtool fcitx5-chinese-addons fcitx5-qt fcitx5-gtk`

安装字典 `paru -S fcitx5-pinyin-zhwiki fcitx5-pinyin-sougou`

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

详细介绍[wiki](https://wiki.archlinuxcn.org/wiki/Rime)

参考官网 [传送门](https://rime.im)
基本库 `paru -S ibus ibus-qt ibus-rime` 
在`$HOME/.bashrc`加入下面的配置内容

```json
export GTK_IM_MODULE=ibus
export XMODIFIERS=@im=ibus
export QT_IM_MODULE=ibus
ibus-daemon -d -x
```

> ⚠️执行 `ibus-setup`进行配置。在*setting*->*Region & Language*下的*input sources*中加入Other->Chinese(Rime)。重启即可。

[四叶草输入法](https://github.com/fkxxyz/rime-cloverpinyin) `paru -S rime-cloverpinyin` 
参考 https://wiki.archlinux.org/index.php/Fcitx

#### 有用的仓库

+ [雾凇拼音]( https://github.com/iDvel/rime-ice)  可以通过 `paru -S  rime-ice-git `进行安装

+ [oh-my-rime薄荷输入法](https://github.com/Mintimate/oh-my-rime)

+ [Rime auto deploy](https://github.com/Mark24Code/rime-auto-deploy)

+ https://github.com/yanhuacuo/rimetool

## 模拟器

Vita3K PlayStation Vita emulator 安装 `paru -S vita3k-bin`

## 媒体软件

网易云音乐 安装 `paru -S netease-cloud-music` 

腾讯视频 安装 `paru -S tenvideo`

全聚合影视 安装 `paru -S vst-video-bin` 

OBS推流工具 `paru -S obs-studio` 

bilibili `paru -S bilibili-bin`

smPlayer `paru -S smplayer`

[kdenlive](https://kdenlive.org)非线性视频编辑器 `paru -S kdenlive`

[yt-dlp](https://github.com/yt-dlp/yt-dlp) youtube 下载软件 `paru -S yt-dlp`

[macast-git](https://github.com/xfangfang/Macast)跨平台的 DLNA 投屏接收端 `paru -S 
macast-git`(需要安装相关pip包 `pip install -U urllib3 requests` `pip install requests[socks]`)

## 美化

### docky 安装

`paru -S docky`
或者
`paru -S plank` (这个比较简单，推荐)

> XFCE桌面下安装plank后可能会出现屏幕下方会有一条阴影直线，十分影响视觉。解决方案是在开始菜单的设置管理器(Settings Manager)-窗口管理器微调(Window Manager Tweaks)-合成器(Compositor)中去掉dock阴影(Show shadows under dock windows)前面的勾。

如果是KDE桌面
`paru -S latte-dock` 

KDE

（KDE推荐安装部件([下载网站](https://store.kde.org/),最好安装ocs-url `paru -S ocs-url`) `appication title` `全局菜单` `Launchpad plasma` `latte Spacer` `Event calendar` (个人google三色时间配置 `'<font color="#EB4334">'hh'</font>':'<font color="#35AA53">'mm'</font>':'<font color="#4586F3">'ss'</font>'` )）

KDE whitesur主题 安装 `paru -S plasma5-themes-whitesur-git `（推荐）或者`paru -S plasma5-themes-macsonoma-git`

>另外还可以使用https://github.com/vinceliuice/MacSonoma-kde

XFCE whitesur主题 

+ https://github.com/vinceliuice/WhiteSur-gtk-theme
+ https://github.com/paullinuxthemer/McOS-XFCE-Edition

mcmojave-circle-icon-theme-git 图标主题 `paru -S mcmojave-circle-icon-theme-git`

xfce全局菜单([参考链接1](https://blog.csdn.net/kewen_123/article/details/115465909) [参考链接2](https://www.cnblogs.com/maxwell-blog/p/10337514.html)) `paru -S libdbusmenu-glib libdbusmenu-gtk3 libdbusmenu-gtk2  vala-panel-appmenu-xfce appmenu-gtk-module appmenu-qt4  vala-panel-appmenu-registrar xfce4-windowck-plugin-xfwm4-theme-support`   启用使用下面的命令

```
xfconf-query -c xsettings -p /Gtk/ShellShowsAppmenu -n -t bool -s true
xfconf-query -c xsettings -p /Gtk/ShellShowsMenubar -n -t bool -s true
```



[conky](https://github.com/brndnmtthws/conky) 性能显示组件 安装 `paru -S conky conky-manager`

### Kitty

使用命令安装 `paru -S kitty` 或者 `paru -S kitty-git`

配置文件使用 [荒野无灯的配置文件](https://github.com/ttys3/my-kitty-config) 及 [文章](https://ttys3.dev/blog/kitty)

这个配置的按键映射

#### config

keybindings explain:

ctrl+a>R means: press `ctrl` + `a` in the same time, release and then, press R (`shift`+`r`)

| key      | description   |
| -------- | ------------- |
| ctrl+a>R | reload config |
| ctrl+a>E | edit config   |
| ctrl+a>D | debug config  |



#### session

| key      | description                         |
| -------- | ----------------------------------- |
| ctrl+a>s | save current layout to session file |

#### tab

| key          | description        |
| ------------ | ------------------ |
| ctrl+shift+← | goto previus tab   |
| ctrl+shift+→ | goto next tab      |
| ctrl+shift+, | move tab backward  |
| ctrl+shift+. | move tab forward   |
| ctrl+a>,     | change tab title   |
| ctrl+a>c     | create new tab     |
| ctrl+a>x     | close window / tab |

#### os window

| key    | description       |
| ------ | ----------------- |
| ctrl+q | quit kitty        |
| f11    | toggle fullscreen |

#### window

| key            | description                  |
| -------------- | ---------------------------- |
| ctrl+a>-       | horizontal split with cwd    |
| ctrl+a>shift+- | horizontal split             |
| ctrl+a>\       | vertial split with cwd       |
| ctrl+a>shift+\ | vertial split                |
| ctrl+a>x       | close window                 |
| ctrl+a>z       | zoom (maxmize) window        |
| ctrl+shift+r   | resize window                |
| ctrl+←         | goto left window             |
| ctrl+→         | goto right window            |
| ctrl+↑         | goto up window               |
| ctrl+↓         | goto down window             |
| ctrl+a>h       | goto left window             |
| ctrl+a>l       | goto right window            |
| ctrl+a>k       | goto up window               |
| ctrl+a>j       | goto down window             |
| shift+←        | move current window to left  |
| shift+→        | move current window to right |
| shift+↑        | move current window to up    |
| shift+↓        | move current window to down  |
| alt+n          | resize window narrower       |
| alt+w          | resize window wider          |
| alt+u          | resize window taller         |
| alt+d          | resize window shorter        |
| ctrl+home      | resize window reset          |

#### font

| key    | description     |
| ------ | --------------- |
| ctrl+= | font size +     |
| ctrl+- | font size -     |
| ctrl+0 | font size reset |

#### misc

| key           | description                                                  |
| ------------- | ------------------------------------------------------------ |
| ctrl+a>t      | kitten theme                                                 |
| ctrl+a>space  | copy pasting with hints like [tmux-thumbs](https://github.com/fcsonline/tmux-thumbs) |
| ctrl+a>ctrl+a | send real ctrl+a (emacs shortcut Home                        |

更多请参考官网 https://sw.kovidgoyal.net/kitty/ 的[快捷键](https://sw.kovidgoyal.net/kitty/conf/#keyboard-shortcuts)章节

### zim 安装

>Modular, customizable, and blazing fast Zsh framework

安装

```bash
curl -fsSL https://raw.githubusercontent.com/zimfw/install/master/install.zsh | zsh
```

或者

```bash
wget -nv -O - https://raw.githubusercontent.com/zimfw/install/master/install.zsh | zsh
```

更多，请参考 [github ](https://github.com/zimfw/zimfw#manual-installation)或者  https://zimfw.sh 下面是我自己的配置：

~/.zimrc

```
zmodule asciiship
zmodule zsh-users/zsh-completions --fpath src
zmodule completion
zmodule zsh-users/zsh-autosuggestions
zmodule sindresorhus/pure --source async.zsh
zmodule romkatv/powerlevel10k --use degit
zmodule Aloxaf/fzf-tab
zmodule zdharma-continuum/fast-syntax-highlighting
zmodule skywind3000/z.lua --cmd 'eval "$(lua {}/z.lua --init zsh enhanced once)"'
zmodule ohmyzsh/ohmyzsh --root plugins/extract
```

~/.zshrc

```
export PATH=$HOME/bin:/usr/local/bin:$HOME/go/bin:$PATH
# eval "$(atuin init zsh)"
# eval "$(starship init zsh)"

zstyle ':zim:zmodule' use 'degit'
ZIM_HOME=~/.zim

# Download zimfw plugin manager if missing.
if [[ ! -e ${ZIM_HOME}/zimfw.zsh ]]; then
  curl -fsSL --create-dirs -o ${ZIM_HOME}/zimfw.zsh \
      https://fastgit.czyt.tech/https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
fi

# Install missing modules, and update ${ZIM_HOME}/init.zsh if missing or outdated.
if [[ ! ${ZIM_HOME}/init.zsh -nt ${ZDOTDIR:-${HOME}}/.zimrc ]]; then
  source ${ZIM_HOME}/zimfw.zsh init -q
fi
# Initialize modules.
source ${ZIM_HOME}/init.zsh
```

### ohmyzh 安装

使用命令一键安装

```bash
paru -S zsh && sh -c "$(curl -fsSL https://fastgit.czyt.tech/https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

或者使用华中科技大学的国内镜像

```bash
REMOTE=https://mirrors.hust.edu.cn/git/ohmyzsh.git sh -c "$(curl -fsSL https://mirrors.hust.edu.cn/ohmyzsh.git/install.sh)"
```

>如果已经安装了 Oh My Zsh，可以将 git 仓库的 remote 设置为华中科技大学的镜像站点地址，使用如下命令：
>
>```bash
>git -C $ZSH remote set-url origin https://mirrors.hust.edu.cn/git/ohmyzsh.git
>git -C $ZSH pull
>```

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

[starship](https://github.com/starship/starship) 安装 `paru -S starship` (如是安装的zsh，安装完成后在~/.zshrc 加入`eval "$(starship init zsh)"`即可,[配置文档](https://starship.rs/config/)),个人配置文件(通过`mkdir -p ~/.config && touch ~/.config/starship.toml`创建)

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
paru -S atuin
```

使用zsh插件

```bash
echo 'eval "$(atuin init zsh)"' >> ~/.zshrc
```

另外有个仓库也可以参考下  https://github.com/unixorn/awesome-zsh-plugins

### fish

`paru -S fish` 
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

安装 `paru -S nushell` 

[Warp Terminal](https://www.warp.dev)  `paru -S warp-terminal`

>安装之前需要执行下面的脚本
>
>```bash
>sudo sh -c "echo -e '\n[warpdotdev]\nServer = https://releases.warp.dev/linux/pacman/\$repo/\$arch' >> /etc/pacman.conf"
>sudo pacman-key -r "linux-maintainers@warp.dev"
>sudo pacman-key --lsign-key "linux-maintainers@warp.dev"
>```
>
>[官网说明](https://docs.warp.dev/getting-started/getting-started-with-warp#installing-and-running-warp)

### 自定义主题

需要事先安装软件 `paru -S gnome-tweaks chrome-gnome-shell`

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

go 安装 `paru -S go`

rust 安装 `paru -S rustup`

flutter 安装 `paru -S flutter`

.net core 安装 `paru -S dotnet-sdk-bin` 

bun `paru -S bun-bin`

## 开发工具

[vfox SDK管理工具](https://github.com/version-fox/vfox) 安装 `curl -sSL https://raw.githubusercontent.com/version-fox/vfox/main/install.sh | bash`

[Homebrew](https://brew.sh) 安装 `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"` ([设置镜像源](https://mirrors.tuna.tsinghua.edu.cn/help/homebrew/) [使用指南](https://sspai.com/post/56009))

>国内安装
>
>```
>rm Homebrew.sh ; wget https://gitee.com/cunkai/HomebrewCN/raw/master/Homebrew.sh ; bash Homebrew.sh
>```
>
>国内卸载
>
>```
>rm HomebrewUninstall.sh ; wget https://gitee.com/cunkai/HomebrewCN/raw/master/HomebrewUninstall.sh ; bash HomebrewUninstall.sh
>```

[pixi(支持Python, C++,  R的包管理器 )](https://github.com/prefix-dev/pixi) 安装 `paru -S pixi`

[fleek ]( https://getfleek.dev) "Home as Code" for Humans

wireshark    GUI `paru -S  wireshark-qt `  Cli `paru -S wireshark-cli`

> wireshark的一篇好文章 https://www.ilikejobs.com/posts/wireshark/

Android屏幕共享[Scrcpy](https://github.com/Genymobile/scrcpy) 安装 `paru -S scrcpy`

[Tiny RDM](https://github.com/tiny-craft/tiny-rdm)(**a modern lightweight cross-platform Redis desktop manager** ) `paru -S tiny-rdm-bin`

[github520](https://github.com/521xueweihan/GitHub520) `sed -i "/# GitHub520 Host Start/Q" /etc/hosts && curl https://raw.hellogithub.com/hosts >> /etc/hosts` (刷新缓存 `systemctl restart nscd`)

>配合switchHost更好用.使用 `paru -S switchhosts`或者 `paru -S switchhosts-bin`进行安装

 Rstudio `paru -S rstudio-desktop-bin`

docker-image-extract  https://github.com/jjlin/docker-image-extract

[lapce](https://github.com/lapce/lapce) `paru -S lapce`

[lazygit](https://github.com/jesseduffield/lazygit) `paru -S lazygit`

[gitui](https://github.com/extrawurst/gitui) `paru -S gitui`

[inshellisense](https://github.com/microsoft/inshellisense#inshellisense)  `paru -S nodejs-inshellisense`

![](https://github.com/microsoft/inshellisense/blob/main/docs/demo.gif)

> inshellisense provides IDE style autocomplete for shells. It's a terminal native runtime for autocomplete which has support for 600+ command line tools. inshellisense supports Windows, Linux, & MacOS.

github Desktop `paru -S github-desktop-bin`

代码生成图片[silicon](https://github.com/Aloxaf/silicon) `paru -S --needed pkgconf freetype2 fontconfig libxcb xclip silicon `

redis管理工具 `paru -S redis-desktop-manager` 

github-cli 安装 `paru -S github-cli-bin` 

minicom串口工具 安装 `paru -S minicom` (设置参数 `sudo minicom -s` )

串口助手 安装 `paru -S serialtool` 

[serial-studio](https://github.com/Serial-Studio/Serial-Studio/blob/master/doc/README_ZH.md) 串行数据可视化工具 安装 `paru -S serial-studio-git`

nodejs 安装 ` paru -S nodejs npm` （安装cnpm `npm install -g cnpm --registry=https://registry.npm.taobao.org  ` ）

跨平台编译工具链 安装 `paru -S arm-linux-gnueabihf-g++ arm-linux-gnueabihf-gcc` 

c/c++开发  安装 `paru -S make cmake gdb gcc` 

goland 安装 `paru -S goland goland-jre`

lazarus 安装 `paru -S lazarus `

>lazarus 是Delphi 的开源继承者，使用 Free Pascal （支持 Delphi 语法扩展）+ Free VCL （跨平台的 VCL 开源版）实现，主打简单，快速，可能仍然是目前开发速度最快的 GUI 解决方案，可以轻松开发：Windows / macOS / Linux 的桌面程序

rustrover 安装 `paru -S rustrover rustrover-jre`

uinityHub 安装 `paru -S unityhub`

Android Studio 安装 `paru -S android-studio`

[commitizen-go](https://github.com/lintingzhen/commitizen-go) 安装 `paru -S commitizen-go `  相似的程序[gitcz](https://github.com/xiaoqidun/gitcz)

datagrip 安装 `paru -S datagrip datagrip-jre`

studio 3T (mongoDB开发工具) `paru -S studio-3t`

mongodb compass `paru -S mongodb-compass`

Android Studio 安装 `paru -S android-studio` (安卓SDK `paru -S android-sdk`) 

clion 安装 `paru -S clion clion-jre` 

> 可选下面这些包
>
> + clion-cmake （JetBrains packaged CMake tools for CLion）
> + clion-gdb	(JetBrains packaged GNU Debugger for CLion)
> + clion-lldb	(JetBrains packaged LLVM Debugger for CLion)

pycharm 安装 `paru -S pycharm-professional` 

rider安装 `paru -S rider` 

webstorm 安装 `paru -S webstorm webstorm-jre` 

vmware 安装 `paru -S vmware-workstation`

postman 安装 `paru -S postman-bin` [汉化文件](https://github.com/hlmd/Postman-cn)（jetbrains新版自带的resful 测试工具，可以不用安装）

apifox 安装 `paru -S apifox`

[HTTPie Desktop](https://httpie.io/download) `paru -S httpie-desktop-bin`

[Yaak](https://yaak.app/) api调试工具

[hoppscotch](https://hoppscotch.io)安装 `yay -S  hoppscotch-bin`

[insomnia](https://insomnia.rest) API调试客户端 安装 `paru -S insomnia-bin`

insomnium api调试工具 `paru -S insomnium-bin`

Typora markdown编辑器 安装 `paru -S typora`

>也可以试下 remarkable `paru -S remarkable `

[picgo](https://github.com/Molunerfinn/PicGo) 安装 `paru -S picgo-appimage`

[freeze](https://github.com/charmbracelet/freeze)(将代码或终端输出转换为图片) 安装 `paru -S freeze`

dnspy 安装 `paru -S dnspy` (需要使用blackarch源)

tmux 终端工具 安装 `paru -S tmux`

[pre-commit](https://github.com/pre-commit/pre-commit) 安装 `paru -S python-pre-commit` (管理和维护 pre-commit hooks的工具. [官网](https://pre-commit.com/) )

byobu 终端工具 安装 `paru -S byobu`

kitty 漂亮的终端 安装 `paru -S kitty-git` 或者 `paru -S kitty `

API文档工具 zeal 安装 `paru -S zeal` 

[windterm](https://github.com/kingToolbox/WindTerm) 安装 `paru -S windterm-bin `

bcompare 安装 `paru -S bcompare ` 

tldr 简化版文档工具 ` paru -S tldr` （rust版本 `paru -S  tealdeer ` ）

vscode 安装 `paru -S visual-studio-code-bin` 

[zed editor](https://zed.dev) 安装 `paru -S zed-editor`

终端录屏幕[asciinema](https://asciinema.org/) 安装 `paru -S asciinema` 

[zoxide](https://github.com/ajeetdsouza/zoxide) **smarter cd command** `paru -S zoxide`

证书生成工具 mkcert 安装 `paru -S mkcert` 

netcat `paru -S  --noconfirm gnu-netcat` 或者 `paru -S --noconfirm openbsd-netcat ` 

微信开发者工具 `paru -S wechat-devtool ` 

Platform-Tools for Google Android SDK (adb and fastboot) 安装 `paru -S android-sdk-platform-tools` 

neovim `paru -S neovim` (插件 [lazyvim](https://www.lazyvim.org))

>下面是其他的一些nvim的资料：
>
>+ [nvim配置rust编程环境](https://rsdlt.github.io/posts/rust-nvim-ide-guide-walkthrough-development-debug/)
>+ [巢鹏大佬的nvim配置](https://github.com/chaopeng/nvim-config) 需要安装nerd fonts `paru -S nerd-fonts-sf-mono`
>+ [NeoVim setup for golang programming](https://medium.com/@yanglyu5201/neovim-setup-for-golang-programming-68ebf59336d9)

[sublime-text-4](https://aur.archlinux.org/packages/sublime-text-4)  `paru -S sublime-text-4 `

编译链工具[xmake](http://xmake.io) 安装 `paru -S xmake` 

[goreleaser](https://goreleaser.com) 安装 `paru -S goreleaser-bin`

percona-toolkit (mysql辅助分析工具) `paru -S percona-toolkit` 

注：

jetbrains系列软件，自带更新功能，但是我们一般使用非root用户进行登录，这时需要将安装目录授权给当前登录用户即可。以goland为例，只需要执行 ` chown -R $(whoami) /opt/goland ` 即可进行自动升级。 

strace `paru -S strace` 

dtrace `paru -S dtrace-utils`  (使用[教程](https://zhuanlan.zhihu.com/p/180053751))

cloudflare Argo tunnel `paru -S cloudflared` （使用[教程](https://www.blueskyxn.com/202102/4176.html)）

nmon `paru -S nmon` 

[nmap](https://nmap.org/man/zh/) `paru -S nmap`

>示例:扫描局域网的22端口
>
>```bash
>nmap -p 22  --open 192.168.1.0/24 
>```

nload `paru -S nload` 

tcpflow `paru -S tcpflow` 

 pyroscope性能监测工具  `paru -S pyroscope-bin` (使用[教程](https://colobu.com/2022/01/27/pyroscope-a-continuous-profiling-platform/) [官方教程](https://pyroscope.io/docs/server-install-linux/))

crontab `paru -S cronie`

charles抓包工具  `paru -S charles ` ([注册码生成](https://www.charles.ren) [汉化](https://github.com/cuiqingandroid/CharlesZH))

[notepadnext](https://github.com/dail8859/NotepadNext) Notepad++ 跨平台版本实现 `paru -S notepadnext `

参考

- vmware安装后报错的问题 https://blog.csdn.net/weixin_43968923/article/details/100184356

- 科学技术大学blackarch源使用说明 [https://lug.ustc.edu.cn/wiki/mirrors/help/blackarch](https://lug.ustc.edu.cn/wiki/mirrors/help/blackarch)

- jetbrains系列软件markdown插件无预览标签 `paru -S  java-openjfx-bin` ，参考[链接](https://intellij-support.jetbrains.com/hc/en-us/community/posts/360001515959-Markdown-Support-plugin-preview-not-working-in-Linux)

- 安装charless证书。导出根证书保存为pem格式。转换为crt格式

  `openssl x509 -in charles.pem -inform PEM -out ca.crt`

  信任证书`sudo trust anchor ca.crt`,done

## 服务器组件

### 数据库

redis `paru -S redis` 

percona-Server `paru -S percona-server`

postresql `paru -S postgresql` 

mongoDB `paru -S mongodb ` 或者 `paru -S mongodb-bin` 

percona-mongoDB `paru -S percona-server-mongodb-bin`  (mongosh `paru -S mongosh-bin`)

[Mariadb](https://wiki.archlinux.org/title/MariaDB) `paru -S mariadb`

tiup (可以快速启动tidb的playground) `curl --proto '=https' --tlsv1.2 -sSf https://tiup-mirrors.pingcap.com/install.sh | sh`

clickhouse `paru -S clickhouse` ([官方文档](https://clickhouse.com/docs/en/getting-started/install))

## 其他

screenfetch (终端打印出你的系统信息) 安装 `paru -S screenfetch`

neofetch `paru -S neofetch` 

> neofetch 已经停止维护，后续更新版本为hyfetch 安装命令为`paru -S hyfetch`

easystroke 鼠标手势 `paru -S easystroke`

![image-20220409140401125](https://assets.czyt.tech/img/image-20220409140401125.png)

copyQ (类似ditto) 安装 `paru -S copyq`

ifconfig、netstat 安装 `paru -S net-tools`

文件搜索albert（类似mac上的Spotlight） 安装 `paru -S albert`

Stow配置管理软件 安装 `paru -S stow`

snap 安装 `paru -S --noconfirm --needed snapd`

figlet 字符串logo生成工具 `paru -S figlet` 

libnewt （包含[whiptail](https://whiptail.readthedocs.io/en/latest/)等实用工具 text mode windowing with slang） `paru -S libnewt `

软件包降级工具 downgrade `paru -S downgrade` 

thefuck输错命令更正工具 `paru -S thefuck` 

appimagelauncher 安装 `paru -S  appimagelauncher` 

终端文件管理器ranger 安装 `paru -S ranger` 

ventoy U盘启动制作 `paru -S ventoy-bin`

硬盘自动休眠 [hd-idle](http://hd-idle.sourceforge.net) 安装 `paru -S hd-idle`  （或者 `hdparam` ）

宽带连接 rp-pppoe 安装 `paru -S rp-pppoe` （参考[官方wiki](https://wiki.archlinux.org/title/NetworkManager_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87))）

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

```bash
$ sudo pacman -S xdg-user-dirs-gtk
$ export LANG=en_US
$ xdg-user-dirs-gtk-update
# 然后会有个窗口提示语言更改，更新名称即可
$ export LANG=zh_CN.UTF-8
$ sudo pacman -Rs xdg-user-dirs-gtk

```

## 品牌笔记本支持

[howdy](https://wiki.archlinuxcn.org/wiki/Howdy) 安装 `paru -S howdy`

>  Howdy是Linux 上一个类似 Windows Hello，通过电脑的红外传感器识别人脸，解锁电脑的程序

thinkpad thinkfan 安装`paru -S thinkfan`

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

thinkpad 充电阀值软件 `paru -S tlp tp_smapi acpi_call  threshy threshy-gui` （ 需要 `systemctl enable tlp`）

参考

- https://wiki.archlinux.org/index.php/Laptop/Lenovo
- TLP  [https://wiki.archlinux.org/index.php/TLP_(简体中文)](https://wiki.archlinux.org/index.php/TLP_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87))
- thinkfan 配置及启动参考 https://wiki.archlinux.org/index.php/Thinkpad_Fan_Control
- [https://www.cnblogs.com/henryau/archive/2012/03/03/ubuntu_thinkfan.html](https://www.cnblogs.com/henryau/archive/2012/03/03/ubuntu_thinkfan.html)
- GDM [https://wiki.archlinux.org/index.php/GDM](https://wiki.archlinux.org/index.php/GDM)
- 强制登陆界面在主显示器上显示 [https://askubuntu.com/questions/11738/force-gdm-login-screen-to-the-primary-monitor](https://askubuntu.com/questions/11738/force-gdm-login-screen-to-the-primary-monitor)
- 指纹识别 [https://wiki.archlinux.org/index.php/Fprint](https://wiki.archlinux.org/index.php/Fprint)
- [Fix Intel CPU Throttling on Linux](https://github.com/erpalma/throttled)

dell充电阀值设置 
安装 `paru -S dell-command-configure` 可用于修改设置，而无需重新启动进入 UEFI 菜单。例如，配置电池在 75% 时停止充电，只有在耗尽至 60% 时才重新开始充电：

```bash
cctk --PrimaryBattChargeCfg=Custom:60-75 
```

## 显卡

英伟达显卡驱动 `paru -S nvidia nvidia-settings lib32-nvidia-utils`

## 网卡

8811cu `paru -S rtl8821cu-dkms-git `


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

+ 高分辨率屏幕登录界面如何放大

  修改 /etc/sddm.conf 配置文件， 在 `ServerArguments=-nolisten tcp` 行后面增加 `-dpi 196`， 放大登录界面的分辨率为2倍.可以参考[Arch Linux的wiki](https://wiki.archlinuxcn.org/wiki/SDDM)

## 参考连接

- [swappinessarchlinux 简明指南](https://arch.icekylin.online)
- https://github.com/Liu-WeiHu/hyprdots
- https://github.com/Liu-WeiHu/arch-scripts
- [How to Flush DNS Cache on Linux](https://www.bitslovers.com/linux-how-to-flush-dns/)
- [Manjaro 字体调优](https://wiki.manjaro.org/index.php/Improve_Font_Rendering)
- [Jetbrains License Server](https://github.com/Nasller/LicenseServer)
- [xps13(9370) Linux之路](https://github.com/kevinhwang91/xps-13-conf)
- [Arch Linux 配置 -- 驱动和软件安装](https://xland.cyou/p/arch-linux-configuration-driver-and-software/)
- https://www.imwxz.com/posts/fc1dd509.html
- https://wiki.archlinux.org/title/Dell_XPS_13_(9370)