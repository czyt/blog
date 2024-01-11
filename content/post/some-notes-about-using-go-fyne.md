---
title: "一些使用go-fyne的笔记"
date: 2024-01-11
tags: ["windows", "go","gui"]
draft: false
---
## 界面交互
### 中文字体设置
查阅相关资料，有下面几种解决方案，下面来依次说明。

#### 使用字体bundle

1. 安装`fyne`工具，使用下面的命令：

   ```bash
   go install fyne.io/fyne/v2/cmd/fyne@latest
   ```

2. 准备好要使用的字体，我们这里使用[思源柔黑体](http://jikasei.me/font/)，使用下面命令

   ```go
   fyne bundle GenJyuuGothic-Normal.ttf > bundle.go
   ```

3. 然后创建一个theme

   ```go
   package tinytheme
   
   import (
   	"fyne.io/fyne/v2"
   	"fyne.io/fyne/v2/theme"
   	"fyneHello/fontRes"
   	"image/color"
   )
   
   type ChineseTheme struct{}
   
   var _ fyne.Theme = (*ChineseTheme)(nil)
   
   func (m *ChineseTheme) Font(s fyne.TextStyle) fyne.Resource {
   	return fontRes.ResourceGenJyuuGothicNormalTTF
   }
   func (*ChineseTheme) Color(n fyne.ThemeColorName, v fyne.ThemeVariant) color.Color {
   	return theme.DefaultTheme().Color(n, v)
   }
   
   func (*ChineseTheme) Icon(n fyne.ThemeIconName) fyne.Resource {
   	return theme.DefaultTheme().Icon(n)
   }
   
   func (*ChineseTheme) Size(n fyne.ThemeSizeName) float32 {
   	return theme.DefaultTheme().Size(n)
   }
   
   ```

4. 在程序里面使用字体主题

   ```go
   import (
   	"fmt"
   	"fyne.io/fyne/v2"
   	"fyneHello/tinytheme"
   
   	"fyne.io/fyne/v2/app"
   	"fyne.io/fyne/v2/widget"
   )
   
   func main() {
   	myApp := app.New()
   	myApp.Settings().SetTheme(&tinytheme.ChineseTheme{})
   	myWindow := myApp.NewWindow("您好")
   	myWindow.SetContent(widget.NewLabel("Hello"))
   	myWindow.SetContent(widget.NewButton("确定", func() {
   		fmt.Println("ccccc")
   	}))
   	myWindow.Resize(fyne.NewSize(400, 700))
   	myWindow.Show()
   	myApp.Run()
   	tidyUp()
   }
   
   func tidyUp() {
   	fmt.Println("Exited")
   }
   ```
	这种方式的缺点是，bundle.go的文件大小太大，9MB的字体生成出来有50多MB，那么我们可以使用go自带的embed功能来嵌入字体，就可以很好解决这个问题，代码如下：
	
	```go
	package fontRes
	
	import (
		_ "embed"
		"fyne.io/fyne/v2"
	)
	
	//go:embed GenJyuuGothic-Normal.ttf
	var genJyuuGothicNormalPayload []byte
	var ResourceGenJyuuGothicNormalTTF = &fyne.StaticResource{
		StaticName:    "GenJyuuGothic-Normal.ttf",
		StaticContent: genJyuuGothicNormalPayload,
	}
	```
#### 使用go-findfont库
参考代码如下
```go
ackage main

import (
    "fmt"
    "fyne.io/fyne/v2"
    "fyne.io/fyne/v2/app"
    "fyne.io/fyne/v2/widget"
    "github.com/flopp/go-findfont"
    "os"
    "strings"
)

// 方式一  设置环境变量   通过go-findfont 寻找simkai.ttf 字体
func init() {
    fontPaths := findfont.List()
    for _, path := range fontPaths {
        //fmt.Println(path)
        //楷体:simkai.ttf
        //黑体:simhei.ttf
        if strings.Contains(path, "simkai.ttf") {
            fmt.Println(path)
            os.Setenv("FYNE_FONT", path) // 设置环境变量  // 取消环境变量 os.Unsetenv("FYNE_FONT")
            break
        }
    }
    fmt.Println("=============")
}

func main() {
    MyApp := app.New()
    c := MyApp.NewWindow("解决fyne支持中文")

    labels := widget.NewLabel("支持中文")

    c.SetContent(labels)
    c.Resize(fyne.NewSize(600, 600))
    c.ShowAndRun()
}
```

### 数据绑定
## 编译
### 程序元数据
文件名应为 FyneApp.toml ，位于运行 fyne 命令的目录下（通常是 main 软件包）。文件内容如下：
```toml
Website = "https://example.com"

[Details]
Icon = "Icon.png"
Name = "My App"
ID = "com.example.app"
Version = "1.0.0"
Build = 1
```

文件的顶部部分是元数据，如果您将应用程序上传到 https://apps.fyne.io 列表页面，就会用到这些元数据，因此是可选的。详细信息]部分包含有关您应用程序的数据，这些数据会被其他应用程序商店和操作系统用于发布程序。如果找到该文件，fyne 工具就会使用它，如果元数据存在，许多强制性命令参数就不是必需的。你仍然可以使用命令行参数覆盖这些值。
