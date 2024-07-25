---
title: "MacOS常用软件"
date: 2024-07-22
tags: ["mac", "awesome","tools"]
draft: false
---

## 聊天和社交

- QQ - 80，90的青春。
- 微信 - 国内TOP1社交软件。
- 钉钉 - 阿里巴巴出品协同办公软件。
- 企业微信 - 腾讯出品协同办公软件。
- 飞书 - 字节跳动出品协同办公软件。
- Telegram - 地下社交软件，通信加密。
- X（原twitter） - 地下社交软件，了解国内外大事。
- Franz 多合一聊天工具

## 邮箱工具

- Spark

## 输入法及键盘扩展

- AutoSwitchinput 当你在Mac上打开不同的软件的时候，它可以自动帮你切换中文和英文输入法
- Input Source Pro，推友开发的一个输入法自动切换工具
- [Tickeys](http://www.yingdev.com/projects/tickeys) 键盘打字风格模拟应用, 支持 Cherry轴等多种风格.
- [keycue](http://www.pc6.com/mac/116332.html) 快捷键辅助应用, 帮助记忆快捷键.
- KeyKey  macOS 上优雅好用的键盘打字练习。

## 翻译和外语学习工具

+ bob - 翻译神器
+ EasyDict
+ GoldenDict
+ 有道词典
+ deepl
+ Eudic

## 新闻及阅读

- NetNewsWire  rss阅读软件
- [Reeder](http://www.pc6.com/mac/158839.html) 界面优美的RSS订阅应用.


## 浏览器

- Chrome - Google出品，全球最流行的浏览器。
- vivaldi 我的偏爱浏览器，前opera团队开发的。
- Safari - Apple自己的浏览器，毋庸置疑的好用。
- Edge - 微软出品，基于Chromium内核，IE浏览器的替代者。
- Firefox - Mozilla出品，早年开发者必备。
- Tor - 洋葱浏览器，可浏览AW。
- 360极速浏览器Pro - 目前Mac上支持Flash的浏览器。

## 下载及同步工具
- Downie4 - 视频下载工具，可以下载YouTube，bilibili等视频网站的视频，并且是满速下载。

- Neat Download Manager - 多线程下载器，跑满你的带宽。
- 迅雷
- 坚果云
- Motrix 
- Aria2GUI

## 代理工具

- [nekoray](https://github.com/abbasnaqdi/nekoray-macos/releases)
- Shadowrocket - 代理工具，遨游世界。
- Clash - 代理工具，遨游世界。由于不可抗力因素，原作者删库，推荐这个替代。
- Stash，科学上网工具
- Clash Verge
- [ClashX Pro](https://github.com/yichengchen/clashX#install)

## 办公软件

### Office

- WPS - 国产强大的Office系列套件。
- Word - 微软Office套件之Word。
- Excel - 微软Office套件之Excel。
- PowerPoint - 微软Office套件之PPT。
- Pages - Apple出品文档编辑器，同Word。
- Number - Apple出品表格编辑器，同Excel。
- Keynote - Apple出品PPT编辑器，同PowerPoint，异常强大。

### 流程图

- Revezone
- MindNode
- OmniGraffle 

## 视频工具

- IINA - 绝对好用且强大免费的视频播放器，支持99.99%格式。
- Infuse - 支持海报墙的视频播放器，可以挂载云盘，体验接近完美，支持共享。
- VidHub - 支持海报墙的视频播放器，可以挂载云盘，体验接近infuse。
- Fileball - 文件夹式视频播放器，可以挂载云盘。
- APTV - 可以看电视直播的播放器，直播源需要自己找。
- Permute3 - Mac上简单好用的视频，音频转换工具。
- 剪映 - 字节跳动出品的视频剪辑工具。（推荐国际版）。
- Final Cut Pro - Apple出品的视频剪辑工具，功能无比强大，好莱坞大片御用。

## 文件传输

- Transmit - FTP工具。
- FileZilla - FTP工具。

### 远程控制
- rustdesk
- 向日葵
- SplashTop 
- [TeamViewer](http://www.pc6.com/mac/115425.html) 远程开发或协助必备应用.
- Parsec
- Microsoft Remote Desktop
- Jump Desktop
## 实用工具
### 时间和任务管理
- OmniFocus 
- Fantastical
- Things，很简洁的备忘 Todo 软件，正是由于太简单了，反而能够让你更加聚焦使用。
- Vitamin-R 3 番茄计划定制工作任务

### 虚拟机及虚拟化
- Parallels Desktop
- [utm](https://mac.getutm.app)
- vmware
- [lima](https://lima-vm.io) mac的Linux虚拟机
- [OrbStack](orbstack.dev ) 替换掉Docker 原生的应用
- crossover 或者 wine

### 压缩和解压缩

- Keka ：这是个压缩和解压工具，因为 macOS 玩不转 .zip 之外的压缩包，因此经常处理稀奇古怪的软件压缩包就需要这样的软件

- MacZip - 专为Mac打造的解压缩软件。

- banzip - 以前用Windows的时候就必装的压缩软件。

- Homebrew - Mac上的软件包管理器，可安装各类软件，各类库。必备神器。

  >Homebrew可以通过设置环境变量进行加速.下面是一个.zshrc的例子
  >
  >```bash
  >function proxy_off(){
  >    unset http_proxy
  >    unset https_proxy
  >    echo  "proxy is off"
  >}
  >
  >function proxy_on() {
  >    export no_proxy="localhost,127.0.0.1"
  >    export http_proxy="socks5://127.0.0.1:10808"
  >    export https_proxy=$http_proxy
  >    echo  "prxoy is on"
  >}
  >
  >function proxy_status() {
  >    echo $https_proxy
  >    curl cip.cc
  >}
  >```
  >
  >homebrew的配置可以使用https://sspai.com/post/32933中的mackup进行备份.`brew install mackup`

- FastZip - Mac强大的解压缩工具。

- Dr.Unarchiver

- The Unarchiver
### 截图和录屏
- iShot - 方便的截图软件，支持标记，长截图，OCR等功能。Pro版收费。
- Kap - 录屏工具，简单方便，比系统自带录屏的视频体积小很多。
- ScreenFlow 录制屏幕和编辑视频的软件,简单强大。
- Camtasia
- Snipaste
- Xnip
- Shottr 一个截图软件，同时也支持滚动截图、标注等功能。
- Jietu 腾讯出品的截图软件

### 格式转换

- Permute 3

### 屏幕取色
- Sip - 好用的屏幕取色软件。
- Drop，取色软件，特别是UI开发过程中，假如想去配一个好看的颜色，可以借助这个工具看看做得好的软件的颜色是什么。

### 剪切板

- CopyLess 2

### 增强插件
- Bartender - Mac右上角的状态栏图标太多的时候，就可以使用这个软件优化
- Amphetamine  一款防休眠的软件，可以让你的设备持续保持“兴奋”。如果你平时需要某些程序持续运行不被系统休眠所影响的话，这款软件非常适合。
- [Bartender 3](https://www.macbartender.com/) 菜单栏管理应用, 支持隐藏所有菜单栏图标, 还您一个干净的菜单栏.
- [Dozer](https://github.com/Mortennn/Dozer) 隐藏菜单栏项目,功能类似Bartender但是开源免费
- [CDock](http://www.pc6.com/mac/161158.html) 任务栏定制应用, 可设置Dock全透明, 还您一个清爽的任务栏.
- [TextBar](https://www.macstories.net/mac/textbar-puts-your-text-into-the-menu-bar/) 自定义菜单栏输出, 支持script运行, 支持H5渲染.
- [Growl](http://growl.info/) 自定义通知样式, 支持多种主题以及颜色, 大小, 渐隐时间等各项参数的自定义.
- [Keyboard Maestro](https://www.keyboardmaestro.com/main/) 键盘大师, mac下功能最为丰富的键盘增强应用.
- [BetterTouchTool](https://www.boastr.net/) mac触摸板增强神器.
- [Übersicht](http://sspai.com/28020) 华丽的桌面自定义应用, 类似于windows的 [`rainmeter`](http://rainmeter.cn/cms/). 支持H5.
- [Today Scripts](http://www.waerfa.com/today-scripts-for-yosemite-today-view) 个性化通知栏插件, 支持bash脚本.
- [Mountain Tweaks](http://tweaksapp.com/app/mountain-tweaks/) mac隐藏功能开启应用.
- iStat Menus - 系统监控工具，可实时监控温度，网络，电池，CPU，内存等信息。
- Stats - 系统监控工具，可实时监控温度，网络，电池，CPU，内存等信息。
- AlDente - 充电限制软件，保护电池健康度。Pro版收费。
- Alfred - Mac效率神器，没有之一，用了就离不开。
- [Magnet](https://magnet.crowdcafe.com/)：窗口管理
- Rectangle - 窗口管理工具，Magnet平替。
- [Size up](http://www.irradiatedsoftware.com/sizeup/) 分屏应用, 类似Moon的一款应用, 支持上下左右居中、4个角落快速分屏及多屏幕切换.
- [Divvy](http://www.pc6.com/mac/124992.html) 另一款分屏应用, 可将屏幕分成多宫格的形式, 然后为每个格子定义快捷键, 遗憾的是不支持多屏幕切换.
- QLMarkdown - 空格预览Markdown文件，非常棒。
- Syntax Highlight - 空格预览代码文件，支持高亮功能，非常好用。
- iBar - Mac强大的菜单栏管理工具。
- [BetterDisplay](https://github.com/waydabber/BetterDisplay) Mac 用外接显示器的必须要整一个这个软件.
- 超级右键 - Mac强大的右键菜单工具。
- Mos - 鼠标反转工具，可设置平滑滚动。
- Scroll Reverser - 鼠标反转工具。
- HandShaker - Mac连接安卓手机的工具，锤子科技出品。
- TinyCal - 好用、方便的日历状态栏。
- Top Calendar，一个菜单栏的日历软件，可以看到日历、节假日、农历，以及最近的日程，关键也是做得很美观。
- CheatSheet 安装后在「系统偏好设置 - 安全性与隐私 - 隐私 - 辅助功能」中勾选 CheatSheet 一项，即可在大多数 App 界面中长按 Command-⌘ 直接呼出该软件的全部快捷键，可以说是非常的方便了。
- Dropover  这是给 macOS 增加文件篮子的小工具，你只需要将文件、网页图片、文字拖拽至篮子里临时保存，然后再去目的地进行移动、复制操作，对于需要从多处文件夹移动文件到某一个文件夹的需求来说，极大的简化了操作。
- Loopback  一款Mac平台上的可以创建虚拟音频设备的工具，从应用程序和音频的输入的设备创建虚拟音频设备的声音，然后将其发送给音频处理应用程序。
- MessAuto，一个接收手机短信验证码并自动回填到 Mac 上的小工具，很好用，解决了每次从手机看然后手填的麻烦。
- Raycast  直接替代掉原生的 Spotlight 搜索
- Karabiner  把 HHKB 放在 mac 上的时候可以使用这款软件来禁用自带的键盘，非常方便。
- DMG Canvas，用于编辑产生 Mac dmg 安装包的工具，做得很简单易于使用。
- [KeyCastr](https://github.com/keycastr/keycastr)  在演示或录屏的时候显示快捷键
- [Thor](https://github.com/gbammc/Thor) 给你的任何软件设置启动快捷键
- [Plash ](https://github.com/sindresorhus/Plash)将任意网站设置为可交互的 MacOS 桌面壁纸
- OpenInTerminal：从 Finder 一键打开 Terminal
- Machina - 类似于neofetch的一个显示系统信息的命令行工具.
- [MonitorControl](https://github.com/MonitorControl/MonitorControl)：显示器亮度调节
- [StandUp](https://apps.apple.com/jp/app/standup/id1439378680?l=en&mt=12)：提醒站立
- [WiFriedX](https://medium.com/@mariociabarra/wifriedx-in-depth-look-at-yosemite-wifi-and-awdl-airdrop-41a93eb22e48)：关闭 AWDL/AirDrop，优化 M1 系列 Mac 的 Wifi 连接
- [SmoothScroll](https://www.smoothscroll.net/mac/)：可以让外接鼠标滚动更自然、更顺滑
- [AlDente](https://apphousekitchen.com/)：AlDente 最主要的功能就是调整电池充电阈值。在电池电量在达到指定值后，电脑会停止充电，转向电池供电，全过程无需手动插拔 MacBook 充电器。
- [Caffeine](http://www.pc6.com/mac/121734.html) 点亮mac, 避免长时间演示ppt而进入到休眠状态.
- [AirServer](http://www.airserver.com/) IOS连接mac必备.
- [Beyond Compare](http://www.beyondcompare.cc/) 文件比较应用, 支持文件, 目录, FTP远程地址比较等.
- [EasyFind](http://www.waerfa.com/easyfind) 小而强大的文件搜索应用, 媲美windows下的Everything.
- [Kaleidoscope](http://www.pc6.com/mac/113361.html) 文件和图像比较应用, 支持图片比较, 能与 git, svn 等版本控制工具完美结合.
- [HyperSwitch](https://bahoom.com/hyperswitch) 带有预览图的快速切换, 作用同Command+Tab.
- [Fruit Juice](http://www.pc6.com/mac/119197.html) 电池管理应用, 帮助延迟电池的使用时间.


## 磁盘清理

+ [Pearcleaner](https://itsalin.com/appInfo/?id=pearcleaner) 开源的 Mac 软件卸载工具 
+ [OmniDiskSweeper](http://newping.cn/322) 硬盘空间扫描应用, 帮助mac减肥.
+ [AppCleaner](http://freemacsoft.net/appcleaner/) mac应用卸载工具, 结合 [`AppCleaner`](https://github.com/Louiszhai/tool/blob/master/workflow/AppCleaner.alfredworkflow?raw=true) 的workflow, 使用效果更佳.
+ CleanMyMac X
+ 腾讯 Lemon 清理

## 编程语言

### go

- https://github.com/cortesi/modd

### rust



## 软件开发
### Terminal

- Warp - 有AI功能的终端，开箱即用。缺点是需要登录。
- iTerm2 - Mac上最好的终端之一，搭配oh-my-zsh，好用又好看，程序员必备终端。

### IDE

- VSCode - 微软出品的宇宙最强编辑器。
- HBuilderX - 专为VUE打造的编辑器，可开发HTML，VUE，各种小程序。
- IDEA - 宇宙最好用的JAVA开发IDE，JetBrains出品。
- PyCharm - 宇宙最好用的Python开发IDE，JetBrains出品。
- goland-golang开发
- rustrover - rust开发工具。
- zed - 新出的ide。默认支持多种编程语言。
- WebStorm - 强大的JavaScript开发IDE，JetBrains出品。
- Android Studio - 安卓开发IDE。
- [Script Debugger](http://www.pc6.com/mac/428096.html) 强大的AppleScript编辑器.
- Xcode - iOS，iPadOS，macOS，watchOS开发IDE。
- [GitUp](https://github.com/git-up/GitUp)：Git GUI 软件.比 SourceTree 等软件要简洁，日常开发中基本没有做不了 GUI 操作
### api调试

- Postman
- postwoman
- Apifox - 接口管理神器。接口调试，压力测试工具，力压postman。
### 抓包

- [Debookee](http://www.pc6.com/mac/129593.html) 网络抓包及数据分析应用.
- burp suite
- [charless](https://www.charlesproxy.com)

### 数据库管理工具
- Navicat - 宇宙最好用的数据库工具。
- DataGrid
### 其他
- JD-GUI - Java反编译工具，字节码文件反编译为Java文件。
- [chsrc ](https://github.com/RubyMetric/chsrc)软件换源，加速
- Dash：API 文档和代码片段管理.
- [Charles](https://www.charlesproxy.com/) 网络抓包应用, mac必备.
- [aText](http://www.trankynam.com/atext/) 输入增强应用, 比 [`TextExpander`](http://www.pc6.com/mac/146924.html) 要人性化许多，并且对中文和第三方输入法的支持都要更好.
- [Dash](https://kapeli.com/dash) mac上api集合应用, 几乎包含各种语言的api文档.
- [SnippetsLab](http://www.renfei.org/snippets-lab/) 优秀的代码片段管理工具, 轻量, 可基于菜单栏操作.
- [CodeExpander](https://codeexpander.com/) 专为开发者开发的一个集输入增强、代码片段管理(支持 Markdown)为一体跨平台云同步的开发工具。

## 黑苹果

### 辅助工具

- [Hackintool](https://github.com/benbaker76/Hackintool)
- [RapidEFI-Tool](https://github.com/JeoJay127/RapidEFI-Tool)
- [OCAuxiliaryTools](https://github.com/ic005k/OCAuxiliaryTools)
- [OpenCore Configurator](https://mackie100projects.altervista.org)

### 参考文档

- https://oc.skk.moe
- https://www.tonymacx86.com

## 参阅网站

### 软件下载

- https://xmac.app

- https://appstorrent.ru
- https://xclient.info/
- https://macwk.cn/
- https://www.minorpatch.com
- https://macapp.org.cn
- https://www.macvk.com
- https://macbv.com
- https://macked.app/
- https://foxirj.com
- https://mac.macxz.com
- https://github.com/macdao/ocds-guide-to-setting-up-mac
- https://www.macserialjunkie.com/forum/viewforum.php?f=9
- https://www.imacso.com
- https://github.com/serhii-londar/open-source-mac-os-apps
- https://www.sqlsec.com/macsoft.html
- https://github.com/SuJunming/mac-awesomeTools
- https://ports.macports.org
### 指南技巧

- https://44maker.github.io/wiki/Mac/index.html#start

- https://sumingyd.github.io/OpenCore-Post-Install/

  

