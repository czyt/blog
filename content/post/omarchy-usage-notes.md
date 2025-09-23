---
title: "Omarchy 使用笔记"
date: 2025-09-18T16:32:07+08:00
draft: false
tags: ["linux","arch"]
author: "czyt"
---
omarchy是DHH发布的一款Arch内核的Linux发行版。最近安装了下，稍作记录

## 快捷键
我常用到的几个
- `super` + `space` 唤起程序启动菜单
- `super`对应的是win或者🅾️键
- `super`+ `B` 打开浏览器
- `super`+ `W` 关闭
- `super`+ `enter` 打开控制台
- `super`+ `1/2/3/4/5/6/7/8/9` 切换到工作区

更多 omarchy 的快捷键，请参考 https://learn.omacom.io/2/the-omarchy-manual/53/hotkeys

## 遇见的坑

### 我的浏览器怎么了

我是vivaldi浏览器的忠实用户，在omarchy上安装了vivaldi以后发现浏览器文字超大，好像出了啥问题，但是omarchy自带的浏览器却又是正常的。后面找到设置 setup->monitors.将默认的GDK放大倍数修改为1即可。
> 其他IDE或者软件显示有问题，也可以参考这个方法

```
# Optimized for retina-class 2x displays, like 13" 2.8K, 27" 5K, 32" 6K.
env = GDK_SCALE,1
monitor=,preferred,auto,auto
```

> 我的屏幕是1920x1080分辨率的，所以看着很明显


### 不能卸载的软件
omarchy里面可以方便地进行软件卸载，但是注意不要卸载`alacritty`,现阶段（3.0版本发布）很多脚本都依赖这个tty软件，卸载掉这个软件很多功能都会失效。

## 安装后的设置微调
### 快捷键
``` yaml
bindd = SUPER, R, WeRead, exec, omarchy-launch-webapp "https://weread.qq.com"
bindd = SUPER, E, Email, exec, omarchy-launch-webapp "https://mail.qq.com"
```
### 中文输入法
omarchy自带输入法，默认为fcitx5，可以使用fcitx5-config进行配置。
以雾凇拼音为例,需要安装基本的输入法框架
```bash
paru -S fcitx5 fcitx5-configtool fcitx5-chinese-addons fcitx5-qt fcitx5-gtk  fcitx5-rime
```
然后安装
```bash
paru -S rime-ice-git
```
并以补丁方式启用雾凇拼音，具体方法是在 `mkdir -p $HOME/.local/share/fcitx5/rime/`后，在该文件夹下创建`default.custom.yaml`文件，输入下面的内容
```yaml
patch:
  # 仅使用「雾凇拼音」的默认配置，配置此行即可
  __include: rime_ice_suggestion:/
  # 以下根据自己所需自行定义，仅做参考。
  # 针对对应处方的定制条目，请使用 <recipe>.custom.yaml 中配置，例如 rime_ice.custom.yaml
  __patch:
    key_binder/bindings/+:
      # 开启逗号句号翻页
      - { when: paging, accept: comma, send: Page_Up }
      - { when: has_menu, accept: period, send: Page_Down }
```
添加输入法的时候查找`rime`即可。其他输入法，比如 [白霜](https://github.com/gaboolic/rime-frost)操作应该类似。

### starship美化
omarchy集成了startship，修改配置文件 `~/.config/starship.toml` 为下面这个[gruvbox-rainbow主题](https://github.com/fang2hou/starship-gruvbox-rainbow)
> 如果你修改了不同的shell，我这里修改的是zsh，只需要在`~/.zshrc`中加上`eval "$(starship init zsh)"`即可。其他的shell参考 [官方文档](https://starship.rs/config/)
``` toml
"$schema" = 'https://starship.rs/config-schema.json'

format = """
[](color_orange)\
$os\
$username\
[](bg:color_yellow fg:color_orange)\
$directory\
[](fg:color_yellow bg:color_aqua)\
$git_branch\
$git_status\
[](fg:color_aqua bg:color_blue)\
$c\
$rust\
$golang\
$nodejs\
$php\
$java\
$kotlin\
$haskell\
$python\
[](fg:color_blue bg:color_bg3)\
$docker_context\
[](fg:color_bg3 bg:color_bg1)\
$time\
[ ](fg:color_bg1)\
$line_break$character"""

palette = 'gruvbox_dark'

[palettes.gruvbox_dark]
color_fg0 = '#fbf1c7'
color_bg1 = '#3c3836'
color_bg3 = '#665c54'
color_blue = '#458588'
color_aqua = '#689d6a'
color_green = '#98971a'
color_orange = '#d65d0e'
color_purple = '#b16286'
color_red = '#cc241d'
color_yellow = '#d79921'

[os]
disabled = false
style = "bg:color_orange fg:color_fg0"

[os.symbols]
Windows = "󰍲"
Ubuntu = "󰕈"
SUSE = ""
Raspbian = "󰐿"
Mint = "󰣭"
Macos = "󰀵"
Manjaro = ""
Linux = "󰌽"
Gentoo = "󰣨"
Fedora = "󰣛"
Alpine = ""
Amazon = ""
Android = ""
Arch = "󰣇"
Artix = "󰣇"
CentOS = ""
Debian = "󰣚"
Redhat = "󱄛"
RedHatEnterprise = "󱄛"
Pop = ""

[username]
show_always = true
style_user = "bg:color_orange fg:color_fg0"
style_root = "bg:color_orange fg:color_fg0"
format = '[ $user ]($style)'

[directory]
style = "fg:color_fg0 bg:color_yellow"
format = "[ $path ]($style)"
truncation_length = 3
truncation_symbol = "…/"

[directory.substitutions]
"Documents" = "󰈙 "
"Downloads" = " "
"Music" = "󰝚 "
"Pictures" = " "
"Developer" = "󰲋 "

[git_branch]
symbol = ""
style = "bg:color_aqua"
format = '[[ $symbol $branch ](fg:color_fg0 bg:color_aqua)]($style)'

[git_status]
style = "bg:color_aqua"
format = '[[($all_status$ahead_behind )](fg:color_fg0 bg:color_aqua)]($style)'

[nodejs]
symbol = ""
style = "bg:color_blue"
format = '[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)'

[c]
symbol = " "
style = "bg:color_blue"
format = '[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)'

[rust]
symbol = ""
style = "bg:color_blue"
format = '[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)'

[golang]
symbol = ""
style = "bg:color_blue"
format = '[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)'

[php]
symbol = ""
style = "bg:color_blue"
format = '[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)'

[java]
symbol = " "
style = "bg:color_blue"
format = '[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)'

[kotlin]
symbol = ""
style = "bg:color_blue"
format = '[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)'

[haskell]
symbol = ""
style = "bg:color_blue"
format = '[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)'

[python]
symbol = ""
style = "bg:color_blue"
format = '[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)'

[docker_context]
symbol = ""
style = "bg:color_bg3"
format = '[[ $symbol( $context) ](fg:#83a598 bg:color_bg3)]($style)'

[time]
disabled = false
time_format = "%R"
style = "bg:color_bg1"
format = '[[  $time ](fg:color_fg0 bg:color_bg1)]($style)'

[line_break]
disabled = false

[character]
disabled = false
success_symbol = '[](bold fg:color_green)'
error_symbol = '[](bold fg:color_red)'
vimcmd_symbol = '[](bold fg:color_green)'
vimcmd_replace_one_symbol = '[](bold fg:color_purple)'
vimcmd_replace_symbol = '[](bold fg:color_purple)'
vimcmd_visual_symbol = '[](bold fg:color_yellow)'
```
### 屏保文字自定义
通过`super`+`alt`+ `space`打开选项菜单，选择`style`->`screen saver`,打开以后，在下面的网站https://patorjk.com/software/taag/ 输入文字，字体选择`Delta Corps Priest 1`,生成完毕以后，粘贴即可。比如我生成的logo
```
▄████████  ▄██████▄  ████████▄     ▄████████    ▄████████       ▄████████  ▄███████▄  ▄██   ▄       ███
███    ███ ███    ███ ███   ▀███   ███    ███   ███    ███      ███    ███ ██▀     ▄██ ███   ██▄ ▀█████████▄
███    █▀  ███    ███ ███    ███   ███    █▀    ███    ███      ███    █▀        ▄███▀ ███▄▄▄███    ▀███▀▀██
███        ███    ███ ███    ███  ▄███▄▄▄      ▄███▄▄▄▄██▀      ███         ▀█▀▄███▀▄▄ ▀▀▀▀▀▀███     ███   ▀
███        ███    ███ ███    ███ ▀▀███▀▀▀     ▀▀███▀▀▀▀▀        ███          ▄███▀   ▀ ▄██   ███     ███
███    █▄  ███    ███ ███    ███   ███    █▄  ▀███████████      ███    █▄  ▄███▀       ███   ███     ███
███    ███ ███    ███ ███   ▄███   ███    ███   ███    ███      ███    ███ ███▄     ▄█ ███   ███     ███
████████▀   ▀██████▀  ████████▀    ██████████   ███    ███      ████████▀   ▀████████▀  ▀█████▀     ▄████▀
                                               ███    ███
```
貌似可以通过连接快速生成
```
https://patorjk.com/software/taag/?p=display&f=Delta%20Corps%20Priest%201&t=coder%20czyt&x=none
```

### 剪切板
我这里使用了`clipse-bin`这个软件，先安装
``` bash
paru -S clipse-bin
```
然后打开hyperland的配置文件，添加下面的行
```
exec-once = clipse -listen # run listener on startup
```
然后再到快捷键配置里面加上下面的内容
```
bindd = SUPER, V, Clipse, exec, $terminal -e 'clipse'
```
