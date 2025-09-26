---
title: "Omarchy 使用笔记"
date: 2025-09-18T16:32:07+08:00
draft: false
tags: ["linux","arch"]
author: "czyt"
---
omarchy是DHH发布的一款Arch内核的Linux发行版。最近安装了下，稍作记录

## 特色功能
### 命令行
 - 可以使用 `eza`替换`ls`

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
添加输入法的时候查找`Rime`即可。其他输入法，比如 [白霜](https://github.com/gaboolic/rime-frost)操作应该类似。

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
### 启动logo
omarchy的启动logo是在主题omarchy中定义的。主题的路径是 `/usr/share/plymouth/themes/omarchy`，你需要替换或者创建一个新的主题，如果是替换，则只需要替换logo.png文件,更换logo后，可以通过命令配置或切换主题,下面是相关的命令。

查看当前正在使用的主题
```bash
plymouth-set-default-theme
```
该命令会直接输出当前默认的Plymouth主题名称。我这返回的信息
```bash
omarchy
```
查看系统所有可用的主题
```bash
plymouth-set-default-theme --list
```
或者更简化的
```bash
plymouth-set-default-theme -l
```
我这边返回的列表
```bash
bgrt
details
fade-in
glow
omarchy
script
solar
spinfinity
spinner
text
tribar
```
要设置默认的主题，我这还是选择omarchy主题
```bash
sudo update-alternatives --config omarchy.plymouth
```
应用以后，刷新Plymouth缓存：

```bash
sudo update-initramfs -u
```
最后重启系统，就能看到新的logo显示在开机动画里。
### Terminal和文件管理器的集成
omarchy使用的是Nautilus文件管理器，
#### warp terminal
我日常使用warp terminal比较多，所以这里提供warp terminal的集成方式。
> 替换默认的`super`+`enter` 快捷键打开Warp terminal
> ` bindd = SUPER, return, Warp Terminal, exec, uwsm app -- xdg-open warp://action/new_tab?path="$(omarchy-cmd-terminal-cwd)"
`
>
先创建Nautilus 脚本文件
```bash
mkdir -p ~/.local/share/nautilus/scripts
touch ~/.local/share/nautilus/scripts/open-in-warp.sh
```
然后编辑脚本文件
```bash
#!/bin/bash
# Open current directory in Warp Terminal

# 获取当前目录路径
if [ -n "$NAUTILUS_SCRIPT_SELECTED_FILE_PATHS" ]; then
    # 如果选中了文件，获取第一个选中文件所在的目录
    SELECTED_PATH=$(echo "$NAUTILUS_SCRIPT_SELECTED_FILE_PATHS" | head -n1)
    if [ -d "$SELECTED_PATH" ]; then
        # 如果选中的是目录，直接使用
        CURRENT_DIR="$SELECTED_PATH"
    else
        # 如果选中的是文件，获取其父目录
        CURRENT_DIR=$(dirname "$SELECTED_PATH")
    fi
elif [ -n "$NAUTILUS_SCRIPT_CURRENT_URI" ]; then
    # 使用当前浏览的目录
    CURRENT_DIR="$NAUTILUS_SCRIPT_CURRENT_URI"
    # 移除 file:// 前缀并进行 URL 解码
    CURRENT_DIR=${CURRENT_DIR#file://}
    CURRENT_DIR=$(python3 -c "import urllib.parse; print(urllib.parse.unquote('$CURRENT_DIR'))" 2>/dev/null)
else
    # 备用方案：使用 pwd
    CURRENT_DIR=$(pwd)
fi

# 确保路径存在且不为空
if [ -z "$CURRENT_DIR" ] || [ ! -d "$CURRENT_DIR" ]; then
    CURRENT_DIR=$(pwd)
fi

# 调试输出（可选，用于排查问题）
# echo "Current directory: $CURRENT_DIR" > /tmp/nautilus-warp-debug.log

# 启动 Warp Terminal
warp-terminal "$CURRENT_DIR" 2>/dev/null || xdg-open "warp://action/new_tab?path=$CURRENT_DIR"
```
#### Ghostty
创建文件 `~/.local/share/nautilus/scripts/open-in-ghostty.sh`
```bash
#!/bin/bash
# Open current directory in Ghostty Terminal

# 获取当前目录
if [ -n "$NAUTILUS_SCRIPT_CURRENT_URI" ]; then
    CURRENT_DIR=$(echo "$NAUTILUS_SCRIPT_CURRENT_URI" | sed 's|file://||' | python3 -c "import sys, urllib.parse; print(urllib.parse.unquote(sys.stdin.read().strip()))")
else
    CURRENT_DIR="$PWD"
fi

# 启动 Ghostty 并切换到当前目录
ghostty --working-directory="$CURRENT_DIR" &
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
### 天气插件
#### shell版本
网上找了一圈，没找到好用的waybar的天气插件，于是让ai写了一个，创建
`~/.config/waybar/scripts/weather.sh`，写入下面的内容
> apikey需要到 [https://openweathermap.org/api](https://openweathermap.org/api)去申请,然后替换下面脚本的apikey
>

```bash
#!/bin/bash
# 配置
API_KEY="${OPENWEATHER_API_KEY:-<你的apikey>}"
CITY="${CITY:-Chengdu}"
UNITS="${UNITS:-metric}"
LANG="${LANG:-zh_cn}"
CACHE_FILE="/tmp/waybar_weather_cache.json"

# 检查依赖
if ! command -v jq &> /dev/null; then
    printf '{"text":"❌ jq missing","tooltip":"jq is not installed"}\n'
    exit 0
fi

if ! command -v curl &> /dev/null; then
    printf '{"text":"❌ curl missing","tooltip":"curl is not installed"}\n'
    exit 0
fi

# 检查API密钥
if [[ -z "$API_KEY" ]]; then
    printf '{"text":"❌ No API Key","tooltip":"Please set OPENWEATHER_API_KEY"}\n'
    exit 0
fi

# 获取天气数据
fetch_weather_data() {
    local max_retries=3
    local retry_delay=2
    local attempt=1

    while [[ $attempt -le $max_retries ]]; do
        local weather_data=$(curl -s --connect-timeout 5 --max-time 15 \
            "https://api.openweathermap.org/data/2.5/weather?q=${CITY}&appid=${API_KEY}&units=${UNITS}&lang=${LANG}")
        local curl_exit_code=$?

        if [[ $curl_exit_code -eq 0 ]] && [[ -n "$weather_data" ]]; then
            local api_error=$(echo "$weather_data" | jq -r '.cod // empty' 2>/dev/null)
            if [[ "$api_error" == "200" ]]; then
                echo "$weather_data"
                return 0
            fi
        fi

        if [[ $attempt -lt $max_retries ]]; then
            sleep $retry_delay
            retry_delay=$((retry_delay * 2))
        fi

        attempt=$((attempt + 1))
    done

    return 1
}

# 解析天气数据
parse_weather_data() {
    local weather_data="$1"

    # 解析数据
    local temp=$(echo "$weather_data" | jq -r '.main.temp | round')
    local feels_like=$(echo "$weather_data" | jq -r '.main.feels_like | round')
    local temp_min=$(echo "$weather_data" | jq -r '.main.temp_min | round')
    local temp_max=$(echo "$weather_data" | jq -r '.main.temp_max | round')
    local humidity=$(echo "$weather_data" | jq -r '.main.humidity')
    local description=$(echo "$weather_data" | jq -r '.weather[0].description')
    local icon_code=$(echo "$weather_data" | jq -r '.weather[0].icon')
    local wind_speed=$(echo "$weather_data" | jq -r '.wind.speed')
    local visibility=$(echo "$weather_data" | jq -r '.visibility // 0 | . / 1000 | . * 10 | round / 10')

    # 图标和class映射
    local icon weather_class
    case "$icon_code" in
        "01d") icon="☀️"; weather_class="sunnyDay" ;;
        "01n") icon="🌙"; weather_class="clearNight" ;;
        "02d") icon="⛅"; weather_class="sunnyDay" ;;
        "02n") icon="⛅"; weather_class="clearNight" ;;
        "03d"|"04d") icon="☁️"; weather_class="cloudyFoggyDay" ;;
        "03n"|"04n") icon="☁️"; weather_class="cloudyFoggyNight" ;;
        "09d"|"10d") icon="🌧️"; weather_class="rainyDay" ;;
        "09n"|"10n") icon="🌧️"; weather_class="rainyNight" ;;
        "11d"|"11n") icon="⛈️"; weather_class="severe" ;;
        "13d") icon="❄️"; weather_class="snowyIcyDay" ;;
        "13n") icon="❄️"; weather_class="snowyIcyNight" ;;
        "50d") icon="🌫️"; weather_class="cloudyFoggyDay" ;;
        "50n") icon="🌫️"; weather_class="cloudyFoggyNight" ;;
        *) icon="🌤️"; weather_class="default" ;;
    esac

    # 单位符号
    local unit wind_unit
    case "$UNITS" in
        "metric") unit="°C"; wind_unit="m/s" ;;
        "imperial") unit="°F"; wind_unit="mph" ;;
        "kelvin") unit="K"; wind_unit="m/s" ;;
        *) unit="°C"; wind_unit="m/s" ;;
    esac

    # 构建tooltip文本
    local tooltip_text="<span size=\"xx-large\">${temp}${unit}</span>
<big>${icon} ${description}</big>
<small>Feels like ${feels_like}${unit}</small>

🔻 ${temp_min}${unit}  🔺 ${temp_max}${unit}
💨 ${wind_speed} ${wind_unit}  💧 ${humidity}%
👁 ${visibility} km"

    # 使用jq安全构建JSON (紧凑格式)
    jq -nc \
        --arg text "${icon} ${temp}${unit}" \
        --arg alt "$description" \
        --arg tooltip "$tooltip_text" \
        --arg class "$weather_class" \
        '{text: $text, alt: $alt, tooltip: $tooltip, class: $class}'
}

# 主逻辑（简化版，移除复杂的缓存时间检查）
main() {
    local weather_data
    weather_data=$(fetch_weather_data)

    if [[ $? -eq 0 ]]; then
        local output=$(parse_weather_data "$weather_data")
        echo "$output" > "$CACHE_FILE" 2>/dev/null  # 静默保存缓存
        printf '%s\n' "$output"
    else
        # 尝试读取缓存（如果存在）
        if [[ -f "$CACHE_FILE" ]]; then
            local cached_output=$(cat "$CACHE_FILE" 2>/dev/null)
            if [[ -n "$cached_output" ]]; then
                echo "$cached_output" | jq -c '.tooltip += "\n\n⚠️ Using cached data"' 2>/dev/null || echo "$cached_output"
            else
                printf '{"text":"❌ Offline","tooltip":"Network error, no cached data","class":"default"}\n'
            fi
        else
            printf '{"text":"❌ Offline","tooltip":"Network error, no cached data","class":"default"}\n'
        fi
    fi
}

main

```
在 `~/.config/waybar/style.css`添加样式
``` css
/* 天气模块基础样式 */
#custom-weather {
    margin: 0 8px; /* 左右边距 8px */
    padding: 0 6px; /* 内边距 */
    border-radius: 4px; /* 可选：圆角 */
    font-weight: 500;
}

/* 不同天气状况的颜色样式 */
#custom-weather.severe {
    color: #eb937d;
}

#custom-weather.sunnyDay {
    color: #c2ca76;
}

#custom-weather.clearNight {
    color: #2b2b2a;
}

#custom-weather.cloudyFoggyDay,
#custom-weather.cloudyFoggyNight {
    color: #c2ddda;
}

#custom-weather.rainyDay,
#custom-weather.rainyNight {
    color: #5aaca5;
}

#custom-weather.snowyIcyDay,
#custom-weather.snowyIcyNight {
    color: #d6e7e5;
}

#custom-weather.default {
    color: #dbd9d8;
}

```
在waybar的配置`config.jsonc`中启用
``` json
"custom/weather": {
    "exec": "~/.config/waybar/scripts/weather.sh",
    "format": "{text}",
    "format-alt": "{alt}",
    "return-type": "json",
    "interval": 600,
    "restart-interval": 300,
    "tooltip": true,
    "signal": 9,
  },
```
配置显示位置
```json
"modules-right": [
  "custom/weather",
  .......
],
```
#### wttrbar
使用wttrbar也可以实现类似的功能，需要先安装 `wttrbar`这个包，使用命令安装
``` bash
paru -S wttrbar
```
在配置中添加
```json
"custom/weather": {
    "format": "{}°",
    "tooltip": true,
    "interval": 3600,
    "exec": "wttrbar --lang zh",
    "return-type": "json"
},
```
参数说明
```
--ampm - display time in AM/PM format
--location STRING - pass a specific location to wttr.in
--main-indicator - decide which current_conditions key will be shown on waybar. defaults to temp_C
--date-format - defaults to %Y-%m-%d, formats the date next to the days. see reference
--nerd - use nerd font symbols instead of emojis
--hide-conditions - show a shorter descrpition next to each hour, like 7° Mist instead of 7° Mist, Overcast 81%, Sunshine 17%, Frost 15%
--fahrenheit - use fahrenheit instead of celsius
--mph - use mph instead of km/h for wind speed
--custom-indicator STRING - optional expression that will be shown instead of main indicator. current_conditions and nearest_area keys surrounded by {} can be used. For example, "{ICON} {FeelsLikeC} ({areaName})" will be transformed to "text":"🌧️ -4 (Amsterdam)" in the output
--lang LANG - set language (currently en, de, pl, tr, fr, ru, zh, be, es, pt, it, ja, uk, sv; submit a PR to add yours)
--observation-time - show the time the current weather conditions were measured
e.g. wttrbar --date-format "%m/%d" --location Paris --hide-conditions
```
放在waybar的中间，显示效果不错
``` json
"modules-center": [
    "custom/weather",
    "clock",
    "custom/update",
    "custom/screenrecording-indicator",
  ],
```
可以调整相关的样式
``` css
#custom-weather.sunny {
  background-color: yellow;
}
```


## 有用的链接
 + https://github.com/catppuccin/waybar
