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

### 界面缩放

fyne默认是自动缩放的。你可以使用 `fyne_settings` 应用程序或使用 `FYNE_SCALE` 环境变量设置特定比例来调整应用程序的大小。这些值可以使内容比系统设置大或小，使用 "1.5 "会使内容大 50%，设置 0.8 会使内容小 20%。

### 数据绑定

###  自定义控件

## 开发及编译
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

### 软件包列表

fyne 项目分为多个软件包，每个软件包提供不同类型的功能。具体如下

- fyne.io/fyne/v2 该导入提供了所有 Fyne 代码通用的基本定义包括数据类型和接口。
- fyne.io/fyne/v2/app app软件包提供启动新应用程序的应用程序接口。通常只需要 app.New() 或 app.NewWithID() 。
- fyne.io/fyne/v2/canvas canvas提供了 Fyne 中所有的绘图 API。完整的 Fyne 工具包由这些原始图形类型组成。
- fyne.io/fyne/v2/container container提供了用于布局和组织应用程序的容器。
- fyne.io/fyne/v2/data/binding binding包含将数据源绑定到 widget 的方法。
- fyne.io/fyne/v2/data/validation validation包提供了用于验证部件内部数据的工具。
- fyne.io/fyne/v2/dialog dialog包包含确认、错误和文件保存/打开等对话框。
- fyne.io/fyne/v2/layout layout包提供了各种布局实现，用于容器（将在后续教程中讨论）。
- fyne.io/fyne/v2/storage storage包提供存储访问和管理功能。
- fyne.io/fyne/v2/test 使用test包可以更轻松地测试应用程序包装
- fyne.io/fyne/v2/widget 大多数图形应用程序都是使用部件集合创建的。Fyne 中的所有小工具和互动元素都在这个软件包中。
