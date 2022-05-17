---
title: "Arch Linux 常用软件"
date: 2022-02-23
tags: ["linux", "Arch", "Manjaro", "tools"]
draft: false
---

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
remmina-plugin-teamviewer remmina-plugin-webkit remmina-plugin-rdesktop remmina-plugin-anydesk-git
```

终端：
深度终端 安装 `yay -S deepin-terminal` 
alacritty 安装 `yay -S alacritty ` 
终端渐变色工具lolcat `yay -S lolcat` 


## 浏览器

vivaldi 安装 `yay -S vivaldi`
Chrome 安装 `yay -S google-chrome`
参考

- 解决打开Chrome出现 输入密码以解锁您的登录密钥环 [https://blog.csdn.net/kangear/article/details/20789451](https://blog.csdn.net/kangear/article/details/20789451)
- bilibili视频不能播放的问题 需要安装对应浏览器的解码包。`yay -S vivaldi-ffmpeg-codecs  chromium-codecs-ffmpeg  chromium-codecs-ffmpeg-extra opera-ffmpeg-codecs`  (只需安装对应浏览器的包即可，不必全部安装)



## 翻译软件

有道词典 安装 `yay -S youdao-dict`

金山词霸 安装 `yay -S powerword-bin` 

goldendict 安装 `yay -S goldendict` [词库](https://github.com/czytcn/goldendict)


## 聊天软件

微信 安装 `yay -S deepin-wine-wechat` 

QQ 安装 `yay -S deepin-wine-qq`如果你喜欢各种破解，可以试试下载dreamcast的QQ，替换wine下的QQ。命令参考 `sudo mv ./QQ ~/.deepinwine/Deepin-QQ/drive_c/"Program Files"/Tencent`

tim `yay -S com.qq.tim.spark` 

ipmsg 安装`yay -S iptux`

mattermost 安装 `yay -S mattermost-desktop`

zoom 安装 `yay -S zoom`

slack 安装 `yay -S slack-desktop` 

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

OneDive 安装 `yay -S onedrive` 或者 `yay -S onedrive-abraunegg`

百度云 安装 `yay -S baidunetdisk-bin` 或者 安装深度的版本 `yay -S deepin-baidu-pan`

坚果云 安装 `yay -S nutstore`

DropBox 安装 `yay -S dropbox` 

resilio sync 安装 ` yay -S rslsync` 

迅雷linux版本 安装 `yay -S xunlei-bin` 

迅雷极速版 `yay -S deepin-wine-thunderspeed`

axel 安装 `yay -S axel`

zssh 安装 `yay -S zssh` 配合lrzsz(安装命令 `yay -S lrzsz`)食用效果最佳。

motrix 安装 `yay -S motrix`  

Mega网盘安装 `yay -S megatools-git` 

moose 支持边下边播的BT工具 `yay -S moose ` 

参考

- dreamcast的网盘 http://dreamcast2.ys168.com
- zssh介绍 http://www.v5b7.com/other/zssh.html

## 办公软件

[看雪安全接入](https://ksa.kanxue.com)ksa 安装 `yay -S ksa` 

[tailscale](https://tailscale.com) 安装 `yay -S tailscale` 

[达芬奇视频剪辑](http://www.blackmagicdesign.com/products/davinciresolve/) 安装 `yay -S davinci-resolve` 

[zettlr](https://www.zettlr.com) markdown编辑器 安装 `yay -S zettlr ` 

[vnode](https://tamlok.github.io/vnote/zh_cn/#!index.md) markdown编辑器 安装 `yay -S vnote` 

Wps 安装 `yay -S wps-office ttf-wps-fonts wps-office-mui-zh-cn  wps-office-mime`

libreoffice 安装  `yay -S libreoffice` 

flameshot 截图工具 安装 `yay -S flameshot` 

福昕pdf阅读器 `yay -S foxitreader` 

Teamviewer `yay -S teamviewer`如果一直显示未连接，则请退出teamviewer，执行`sudo teamviewer --daemon enable` 再打开试试

向日葵 安装 `yay -S sunloginclient` (需要设置开机启动服务 `systemctl enable runsunloginclient` 启动服务 `systemctl start runsunloginclient` )

toDesk远程工具 安装 `yay -S todesk-bin` (设置服务 `systemctl start\enable todeskd` 才能正常运行)

parsec 远程工具 安装 `yay -S parsec-bin ` 

v2ray 安装 `yay -S v2ray`  （安装配置工具`yay -S qv2ray ` ，[福利订阅](https://jiang.netlify.app) 新版已经使用AppImage格式发布，下载AppImage格式即可 或者 v2rayDesktop `yay -S v2ray-desktop` ）

n2n [VPN软件](https://www.meirenji.info/2018/02/03/N2N%E7%BB%84%E7%BD%91-%E5%AE%9E%E7%8E%B0%E5%AE%B6%E9%87%8C%E8%AE%BF%E4%B8%8E%E5%85%AC%E5%8F%B8%E7%BD%91%E7%BB%9C%E4%BA%92%E8%AE%BF-%E7%B2%BE%E7%BC%96%E7%89%88/) `yay -S n2n` 

proxychains-ng 安装 `yay -S proxychains-ng`

evernote 开源版本 nixnote2 安装 `yay -S nixnote2` 

joplin 安装 `yay -S joplin` 

Okular （[KDE上的通用文档阅读器](https://www.appinn.com/okular/)）` yay -S okular` 

Foliate [简单、现代的电子书阅读器](https://www.appinn.com/foliate-for-linux/) 安装 `yay -S foliate` 

Screen屏幕共享软件 安装 `yay -S screen-desktop ` 

U盘启动制作[etcher](https://github.com/balena-io/etcher) `yay -S etcher-bin` 

xmind-2020 安装 `yay -S xmind-2020` ([福利链接](https://mega.nz/folder/MxpkmaCZ#Il82PxQ5s9iLgLCMbMf68g))

钉钉 安装 `yay -S  dingtalk-electron ` 

企业微信 `yay -S deepin-wine-wxwork` 

剪切板工具 [uniclip](https://github.com/quackduck/uniclip) `yay -S uniclip`

onenote `yay -S p3x-onenote` 

[macast-git](https://github.com/xfangfang/Macast)跨平台的 DLNA 投屏接收端 `yay -S 
macast-git`(需要安装相关pip包 `pip install -U urllib3 requests` `pip install requests[socks]`)

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

```
GTK_IM_MODULE=fcitx 
QT_IM_MODULE=fcitx 
@=fcitx
```

安装相关字体

```
yay -S wqy-bitmapfont wqy-microhei wqy-zenhei adobe-source-code-pro-fonts  adobe-source-han-sans-cn-fonts ttf-monaco noto-fonts-emoji ttf-fira-code 
ttf-ms-fonts ttf-sarasa-gothic
```

输入法有问题，需要重置，使用命令 `rm -r ~/.config/fcitx` 然后注销即可。

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

## 媒体软件

网易云音乐 安装 `yay -S netease-cloud-music` 不能播放高清音乐，解决办法参考 https://blog.eh5.me/fix-ncm-ldac-playing/

腾讯视频 安装 `yay -S tenvideo`

全聚合影视 安装 `yay -S vst-video-bin` 

OBS推流工具 `yay -S obs-studio` 

## 美化

### docky 安装

`yay -S docky`
或者
`yay -S plank` (这个比较简单，推荐)

如果是KDE桌面
`yay -S latte-dock` 
（KDE推荐安装部件 `appication title` `全局菜单` `Launchpad plasma` `latte Spacer` `Event calendar` (个人google三色时间配置 `'<font color="#EB4334">'hh'</font>':'<font color="#35AA53">'mm'</font>':'<font color="#4586F3">'ss'</font>'` )）


### ohmyzh 安装

`yay -S zsh && sh -c "$(curl -fsSL https://fastgit.czyt.tech/https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"`
安装插件

```
git clone https://github.com/zsh-users/zsh-completions ~/.oh-my-zsh/custom/plugins/zsh-completions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-autosuggestions.git ~/.oh-my-zsh/plugins/zsh-autosuggestions
```

配置插件 ` vim ~/.zshrc` 

```
plugins=(git zsh-syntax-highlighting docker docker-compose zsh-autosuggestions zsh-completions)
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

## 开发工具

redis `yay -S redis` 

mongoDB `yay -S mongodb-bin` (mongosh `yay -S mongosh-bin`)

redis管理工具 `yay -S redis-desktop-manager` 

github-cli 安装 `yay -S github-cli-bin` 

minicom串口工具 安装 `yay -S minicom` (设置参数 `sudo minicom -s` )

串口助手 安装 `yay -S serialtool` 

nodejs 安装 ` yay -S nodejs npm` （安装cnpm `npm install -g cnpm --registry=https://registry.npm.taobao.org  ` ）

跨平台编译工具链 安装 `yay -S arm-linux-gnueabihf-g++ arm-linux-gnueabihf-gcc` 

c/c++开发  安装 `yay -S make cmake gdb gcc` 

goland 安装 `yay -S goland goland-jre`

[commitizen-go](https://github.com/lintingzhen/commitizen-go) 安装 `yay -S commitizen-go `  相似的程序[gitcz](https://github.com/xiaoqidun/gitcz)

datagrip 安装 `yay -S datagrip datagrip-jre`

Android Studio 安装 `yay -S android-studio` (安卓SDK `yay -S android-sdk`) 

clion 安装 `yay -S clion clion-jre` 

pycharm 安装 `yay -S pycharm pycharm-jre` 

rider安装 `yay -S rider` 

webstorm 安装 `yay -S webstorm webstorm-jre` 

vmware 安装 `yay -S vmware-workstation`

postman 安装 `yay -S postman` [汉化文件](https://github.com/hlmd/Postman-cn)（jetbrains新版自带的resful 测试工具，可以不用安装）

Typora markdown编辑器 安装 `yay -S typora`

dnspy 安装 `yay -S dnspy` (需要使用blackarch源)

tmux 终端工具 安装 `yay -S tmux`

byobu 终端工具 安装 `yay -S byobu`

API文档工具 zeal 安装 `yay -S zeal` 

[windterm](https://github.com/kingToolbox/WindTerm) 安装 `yay -S windterm-bin `

bcompare 安装 `yay -S bcompare ` 

tldr 简化版文档工具 ` yay -S tldr` （rust版本 `yay -S  tealdeer ` ）

.net core 安装 `yay -S dotnet-sdk-bin` 

vscode 安装 `yay -S visual-studio-code-bin` 

终端录屏幕[asciinema](https://asciinema.org/) 安装 `yay -S asciinema` 

证书生成工具 mkcert 安装 `yay -S mkcert` 

netcat `yay -S  --noconfirm gnu-netcat` 或者 `yay -S --noconfirm openbsd-netcat ` 

微信开发者工具 `yay -S wechat-devtool ` 

Platform-Tools for Google Android SDK (adb and fastboot) 安装 `yay -S android-sdk-platform-tools` 

编译链工具[xmake](http://xmake.io) 安装 `yay -S xmake` 

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



参考

- vmware安装后报错的问题 https://blog.csdn.net/weixin_43968923/article/details/100184356
- 科学技术大学blackarch源使用说明 [https://lug.ustc.edu.cn/wiki/mirrors/help/blackarch](https://lug.ustc.edu.cn/wiki/mirrors/help/blackarch)
- jetbrains系列软件markdown插件无预览标签 `yay -S  java-openjfx-bin` ，参考[链接](https://intellij-support.jetbrains.com/hc/en-us/community/posts/360001515959-Markdown-Support-plugin-preview-not-working-in-Linux)

## 服务器组件

### 数据库

percona-Server `yay -S percona-server`

postresql `yay -S postgresql` 

mongoDB `yay -S mongodb ` 

percona-mongoDB `yay -S percona-server-mongodb-bin`

[Mariadb](https://wiki.archlinux.org/title/MariaDB) `yay -S mariadb`

tiup (可以快速启动tidb的playground) `curl --proto '=https' --tlsv1.2 -sSf https://tiup-mirrors.pingcap.com/install.sh | sh`

clickhouse `yay -S clickhouse` ([官方文档](https://clickhouse.com/docs/en/getting-started/install))

## 其他

screenfetch (终端打印出你的系统信息) 安装 `yay -S screenfetch`

neofetch `yay -S neofetch`

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
参考

- https://wiki.archlinux.org/index.php/Laptop/Lenovo
- TLP  [https://wiki.archlinux.org/index.php/TLP_(简体中文)](https://wiki.archlinux.org/index.php/TLP_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87))
- thinkfan 配置及启动参考 https://wiki.archlinux.org/index.php/Thinkpad_Fan_Control
- [https://www.cnblogs.com/henryau/archive/2012/03/03/ubuntu_thinkfan.html](https://www.cnblogs.com/henryau/archive/2012/03/03/ubuntu_thinkfan.html)
- GDM [https://wiki.archlinux.org/index.php/GDM](https://wiki.archlinux.org/index.php/GDM)
- 强制登陆界面在主显示器上显示 [https://askubuntu.com/questions/11738/force-gdm-login-screen-to-the-primary-monitor](https://askubuntu.com/questions/11738/force-gdm-login-screen-to-the-primary-monitor)
- 指纹识别 [https://wiki.archlinux.org/index.php/Fprint](https://wiki.archlinux.org/index.php/Fprint)

## 网卡

8811cu `yay -S rtl8821cu-dkms-git `

 参考[链接](https://wiki.archlinux.org/index.php/Network_configuration/Wireless#rtl8811cu/rtl8821cu)

## 系统参数调优

- [https://averagelinuxuser.com/10-things-to-do-after-installing-manjaro/](https://averagelinuxuser.com/10-things-to-do-after-installing-manjaro/)
- 字体渲染 [http://www.badwolfbay.cn/2020/03/17/manjaro-setting/](http://www.badwolfbay.cn/2020/03/17/manjaro-setting/)

## 常见问题
- invalid or corrupted package (PGP signature)

```bash
sudo rm -R /etc/pacman.d/gnupg/
sudo pacman-key --init
sudo pacman-key --populate archlinux
sudo pacman-key --populate archlinuxcn
```