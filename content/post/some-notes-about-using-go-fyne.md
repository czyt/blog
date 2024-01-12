---
title: "一些使用go-fyne的笔记"
date: 2024-01-11
tags: ["windows", "go","gui"]
draft: false
---
## 界面交互
### 中文字体设置
查阅相关资料，有下面几种解决方案，下面来依次说明。

#### 环境变量

可以通过指定 `FYNE_FONT` 环境变量来使用替代字体

#### 使用字体bundle

1. 安装`fyne`工具，使用下面的命令：

   ```bash
   go install fyne.io/fyne/v2/cmd/fyne@latest
   ```

2. 准备好要使用的字体，我们这里使用[miSans](https://hyperos.mi.com/font/zh/)，使用下面命令

   ```go
   fyne bundle MiSans-Normal.ttf > bundle.go
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
   	return fontRes.ResourceMiSansTTF
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
	
	//go:embed MiSans-Normal.ttf
	var miSans []byte
	var ResourceMiSansTTF = &fyne.StaticResource{
		StaticName:    "MiSans-Normal.ttf",
		StaticContent: miSans,
	}
	```
#### 使用go-findfont库
网上的参考代码如下
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
### 容器及布局

#### Box

最常用的布局是 `layout.BoxLayout` ，它有两种变体，水平和垂直。框布局将所有元素排列在一行或一列中，并带有可选空格以帮助对齐。

水平框布局，创建方式 在单行中创建项目的排列方式 `layout.NewHBoxLayout()` 。框中的每个项目的宽度都将设置为 it `MinSize().Width` ，并且所有项目的高度将相等，这是所有 `MinSize().Height` 值中最大的。布局可以在容器中使用，也可以使用 框小部件 `widget.NewHBox()` 。

垂直框布局与此类似，但它将项目排列在列中。每个项目的高度将设置为最小值，并且所有宽度将相等，设置为最小宽度中的最大值。

若要在元素之间创建扩展空间（例如，使某些元素左对齐，其他元素右对齐），请添加 a `layout.NewSpacer()` 作为项目之一。垫片将展开以填充所有可用空间。在垂直框布局的开头添加间隔符将导致所有项目底部对齐。您可以在水平排列的起点和终点添加一个以创建中心对齐方式。

```go
package main

import (
	"image/color"

	"fyne.io/fyne/v2/app"
	"fyne.io/fyne/v2/canvas"
	"fyne.io/fyne/v2/container"
	"fyne.io/fyne/v2/layout"
)

func main() {
	myApp := app.New()
	myWindow := myApp.NewWindow("Box Layout")

	text1 := canvas.NewText("Hello", color.White)
	text2 := canvas.NewText("There", color.White)
	text3 := canvas.NewText("(right)", color.White)
	content := container.New(layout.NewHBoxLayout(), text1, text2, layout.NewSpacer(), text3)

	text4 := canvas.NewText("centered", color.White)
	centered := container.New(layout.NewHBoxLayout(), layout.NewSpacer(), text4, layout.NewSpacer())
	myWindow.SetContent(container.New(layout.NewVBoxLayout(), content, centered))
	myWindow.ShowAndRun()
}
```

#### Grid

Grid模式对容器的元素进行布局，并具有固定的列数。项目将填充一行，直到达到列数，之后将创建一个新行。垂直空间将在每行对象之间平均分配。

您可以使用 `layout.NewGridLayout(cols)` 其中 cols 是您希望在每行中拥有的项目（列）数来创建Grid布局。然后，此布局将作为第一个参数传递给 `container.New(...)` 。

如果调整容器的大小，则每个单元格的大小将相等地调整以共享可用空间。

```go
package main

import (
	"image/color"

	"fyne.io/fyne/v2/app"
	"fyne.io/fyne/v2/canvas"
	"fyne.io/fyne/v2/container"
	"fyne.io/fyne/v2/layout"
)

func main() {
	myApp := app.New()
	myWindow := myApp.NewWindow("Grid Layout")

	text1 := canvas.NewText("1", color.White)
	text2 := canvas.NewText("2", color.White)
	text3 := canvas.NewText("3", color.White)
	grid := container.New(layout.NewGridLayout(2), text1, text2, text3)
	myWindow.SetContent(grid)
	myWindow.ShowAndRun()
}
```

您可以使用 `container.NewGridWithRows` 或 `container.NewGridWithColumns` 函数来创建行或列的网格布局。如果您想要更复杂的布局，比如指定组件应该放在哪一行和哪一列，您可以使用 `container.NewGridLayout`。

以下是一个示例，展示了如何在 Fyne 中创建一个网格布局，分为特定的行和列，并将组件放置在指定的位置：

```go
goCopy codepackage main

import (
    "fyne.io/fyne/v2/app"
    "fyne.io/fyne/v2/container"
    "fyne.io/fyne/v2/widget"
)

func main() {
    myApp := app.New()
    myWindow := myApp.NewWindow("Grid Layout")

    // 创建组件
    button1 := widget.NewButton("Button 1", nil)
    button2 := widget.NewButton("Button 2", nil)
    button3 := widget.NewButton("Button 3", nil)
    button4 := widget.NewButton("Button 4", nil)

    // 创建网格布局，这里我们创建一个 2x2 的网格
    grid := container.NewGridWithColumns(2,
        container.NewGridWithRows(2, button1, button2),
        container.NewGridWithRows(2, button3, button4),
    )

    myWindow.SetContent(grid)
    myWindow.ShowAndRun()
}
```

在这个例子中，我们创建了一个 2x2 的网格布局。每一列都是用 `container.NewGridWithRows` 创建的，它们包含两个按钮。这样，按钮1和按钮2放在第一列的两行中，按钮3和按钮4放在第二列的两行中。

您可以根据需要调整行和列的数量，以及在其中放置的组件。

#### GridWrap

与前面的Grid布局一样，GridWrap布局以网格模式创建元素的排列。但是，此网格没有固定的列数，而是对每个单元格使用固定大小，然后将内容流向显示项目所需的任意数量的行。

您可以使用 `layout.NewGridWrapLayout(size)` where size 指定要应用于所有子元素的大小来创建GridWrap布局。然后，此布局将作为第一个参数传递给 `container.New(...)` 。列数和行数将根据容器的当前大小进行计算。

最初，GridWrap布局将具有一列，如果调整其大小（如右侧代码注释所示），它将重新排列子元素以填充空间。

```go
package main

import (
	"image/color"

	"fyne.io/fyne/v2"
	"fyne.io/fyne/v2/app"
	"fyne.io/fyne/v2/canvas"
	"fyne.io/fyne/v2/container"
	"fyne.io/fyne/v2/layout"
)

func main() {
	myApp := app.New()
	myWindow := myApp.NewWindow("Grid Wrap Layout")

	text1 := canvas.NewText("1", color.White)
	text2 := canvas.NewText("2", color.White)
	text3 := canvas.NewText("3", color.White)
	grid := container.New(layout.NewGridWrapLayout(fyne.NewSize(50, 50)),
		text1, text2, text3)
	myWindow.SetContent(grid)

	// myWindow.Resize(fyne.NewSize(180, 75))
	myWindow.ShowAndRun()
}
```

#### Border

边框布局可能是构建用户界面最广泛使用的布局，因为它允许将项目放置在中心元素周围，该元素将扩展以填充空间。若要创建边框容器，需要将应位于边框位置的 `fyne.CanvasObject` 传递给构造函数的前四个参数。此语法基本上与 `container.NewBorder(top, bottom, left, right, center)` 示例中所示相同。

在前四个项目之后传递到容器的任何项目都将定位到中心区域，并将扩展以填充可用空间。您还可以将要留空的边框参数传递给 `nil` 边框参数。

```go
package main

import (
	"image/color"

	"fyne.io/fyne/v2/app"
	"fyne.io/fyne/v2/canvas"
	"fyne.io/fyne/v2/container"
	"fyne.io/fyne/v2/layout"
)

func main() {
	myApp := app.New()
	myWindow := myApp.NewWindow("Border Layout")

	top := canvas.NewText("top bar", color.White)
	left := canvas.NewText("left", color.White)
	middle := canvas.NewText("content", color.White)
	content := container.NewBorder(top, nil, left, nil, middle)
	myWindow.SetContent(content)
	myWindow.ShowAndRun()
}
```

请注意，中心的所有项目都会展开以填充空间（就像它们在 `layout.MaxLayout` 容器中一样）。要自行管理该区域，您可以改用任何 `fyne.Container` 区域作为内容。

#### Form

`layout.FormLayout` 类似于 2 列网格布局，但经过调整以在应用程序中布局表单。每个项目的高度将是每行中两个最小高度中的较大者。左侧项目的宽度将是第一列中所有项目的最小宽度，而每行中的第二项将展开以填充空间。

此布局通常用于 `widget.Form` （用于验证、提交和取消按钮等），但也可以直接用于 `layout.NewFormLayout()` 传递给 `container.New(...)` 的第一个参数。

```go
package main

import (
	"fyne.io/fyne/v2/app"
	"fyne.io/fyne/v2/container"
	"fyne.io/fyne/v2/layout"
	"fyne.io/fyne/v2/widget"
)

func main() {
	myApp := app.New()
	myWindow := myApp.NewWindow("Form Layout")

	label1 := widget.NewLabel("Label 1")
	value1 := widget.NewLabel("Value")
	label2 := widget.NewLabel("Label 2")
	value2 := widget.NewLabel("Something")
	grid := container.New(layout.NewFormLayout(), label1, value1, label2, value2)
	myWindow.SetContent(grid)
	myWindow.ShowAndRun()
}
```

#### Center

`layout.CenterLayout` 将容器中的所有项目组织为在可用空间中居中。对象将按照它们传递到容器的顺序进行绘制，最后一个对象将绘制在最上面。

```go
package main

import (
	"image/color"

	"fyne.io/fyne/v2/app"
	"fyne.io/fyne/v2/canvas"
	"fyne.io/fyne/v2/container"
	"fyne.io/fyne/v2/layout"
	"fyne.io/fyne/v2/theme"
)

func main() {
	myApp := app.New()
	myWindow := myApp.NewWindow("Center Layout")

	img := canvas.NewImageFromResource(theme.FyneLogo())
	img.FillMode = canvas.ImageFillOriginal
	text := canvas.NewText("Overlay", color.Black)
	content := container.New(layout.NewCenterLayout(), img, text)

	myWindow.SetContent(content)
	myWindow.ShowAndRun()
}
```

中心布局使所有项目保持其最小大小，如果您希望展开项目以填充空间，请参阅 `layout.MaxLayout` 。

#### Max

`layout.MaxLayout` 最简单的布局，它将容器中的所有项目设置为与容器相同的大小。这在一般容器中通常没有用，但在组合小部件时可能适用。

最大布局会将容器扩展为至少为最大项的最小大小。对象将按照传递到容器的顺序绘制，最后一个对象绘制在最上面。

```go
package main

import (
	"image/color"

	"fyne.io/fyne/v2/app"
	"fyne.io/fyne/v2/canvas"
	"fyne.io/fyne/v2/container"
	"fyne.io/fyne/v2/layout"
	"fyne.io/fyne/v2/theme"
)

func main() {
	myApp := app.New()
	myWindow := myApp.NewWindow("Max Layout")

	img := canvas.NewImageFromResource(theme.FyneLogo())
	text := canvas.NewText("Overlay", color.Black)
	content := container.New(layout.NewMaxLayout(), img, text)

	myWindow.SetContent(content)
	myWindow.ShowAndRun()
}
```

#### AppTabs

AppTabs 容器用于允许用户在不同的内容面板之间切换。选项卡要么只是文本，要么是文本和图标。建议不要混合一些有图标的选项卡和一些没有图标的选项卡。选项卡容器是使用 `container.NewAppTabs(...)` 和传递 `container.TabItem` 项（可以使用 创建 `container.NewTabItem(...)` ）创建的。

可以通过设置选项卡的位置来配置选项卡容器，即 `container.TabLocationTop` 、 `container.TabLocationBottom` `container.TabLocationLeading` 和 `container.TabLocationTrailing` 。默认位置为 top。

```go
package main

import (
	"fyne.io/fyne/v2/app"
	"fyne.io/fyne/v2/container"
	//"fyne.io/fyne/v2/theme"
	"fyne.io/fyne/v2/widget"
)

func main() {
	myApp := app.New()
	myWindow := myApp.NewWindow("TabContainer Widget")

	tabs := container.NewAppTabs(
		container.NewTabItem("Tab 1", widget.NewLabel("Hello")),
		container.NewTabItem("Tab 2", widget.NewLabel("World!")),
	)

	//tabs.Append(container.NewTabItemWithIcon("Home", theme.HomeIcon(), widget.NewLabel("Home tab")))

	tabs.SetTabLocation(container.TabLocationLeading)

	myWindow.SetContent(tabs)
	myWindow.ShowAndRun()
}
```

在移动设备上加载时，选项卡位置可能会被忽略。在纵向中，前导或尾随位置将更改为底部。当处于横向时，顶部或底部位置将移至前导位置。

#### 自定义布局

在 Fyne 应用程序中，每个 `Container` 元素都使用简单的布局算法排列其子元素。Fyne 定义了 `fyne.io/fyne/v2/layout` 包中可用的许多布局。如果你看一下代码，你会看到它们都实现了接口 `Layout` 。

```go
type Layout interface {
	Layout([]CanvasObject, Size)
	MinSize(objects []CanvasObject) Size
}
```

任何应用程序都可以提供自定义布局，以非标准方式排列小部件。为此，您需要在自己的代码中实现上述接口。为了说明这一点，我们将创建一个新的布局，将元素排列在对角线上，并排列在其容器的左下角

首先，我们将定义一个新类型， `diagonal` 并定义其最小大小。为了计算这一点，我们只需将所有子元素的宽度和高度（指定为 `[]fyne.CanvasObject` 参数） `MinSize` 相加。

```go
import "fyne.io/fyne/v2"

type diagonal struct {
}

func (d *diagonal) MinSize(objects []fyne.CanvasObject) fyne.Size {
	w, h := float32(0), float32(0)
	for _, o := range objects {
		childSize := o.MinSize()

		w += childSize.Width
		h += childSize.Height
	}
	return fyne.NewSize(w, h)
}
```

对于此类型，我们添加了一个 `Layout()` 函数，该函数应将所有指定的对象移动到第二个参数中 `fyne.Size` 指定的对象中。

在我们的实现中，我们计算小部件的左上角（这是 `0` x 参数，其 y 位置是容器的高度减去所有子项高度的总和）。从顶部位置开始，我们只需按前一个子项的大小将每个项目位置向前推进。

```go
func (d *diagonal) Layout(objects []fyne.CanvasObject, containerSize fyne.Size) {
	pos := fyne.NewPos(0, containerSize.Height - d.MinSize(objects).Height)
	for _, o := range objects {
		size := o.MinSize()
		o.Resize(size)
		o.Move(pos)

		pos = pos.Add(fyne.NewPos(size.Width, size.Height))
	}
}
```

这就是创建自定义布局的全部内容。现在代码已经全部编写完毕 `container.New` ，我们可以将其用作 的 `layout` 参数。下面的代码设置了 3 `Label` 个小部件，并将它们放置在具有新布局的容器中。如果您运行此应用程序，您将看到对角线小部件排列，并且在调整窗口大小时，它们将与可用空间的左下角对齐。

```go
package main

import (
	"fyne.io/fyne/v2"
	"fyne.io/fyne/v2/app"
	"fyne.io/fyne/v2/container"
	"fyne.io/fyne/v2/widget"
)

func main() {
	a := app.New()
	w := a.NewWindow("Diagonal")

	text1 := widget.NewLabel("topleft")
	text2 := widget.NewLabel("Middle Label")
	text3 := widget.NewLabel("bottomright")

	w.SetContent(container.New(&diagonal{}, text1, text2, text3))
	w.ShowAndRun()
}
```

### 动画

fyne的动画有很多，我们这里以一个位置动画为例

```go
package main

import (
	"fyne.io/fyne/v2"
	"fyne.io/fyne/v2/app"
	"fyne.io/fyne/v2/canvas"
	"image/color"
	"time"
)

func main() {
	a := app.New()

	w := a.NewWindow("Hello World")
	text := canvas.NewText("gopher", color.Black)
	w.SetContent(text)
	w.CenterOnScreen()

	callback := func(p fyne.Position) {
		text.Move(p)
		canvas.Refresh(text)
	}

	start := fyne.NewPos(10, 10)
	end := fyne.NewPos(90, 10)
	anim := canvas.NewPositionAnimation(start, end,
		time.Second*5, callback)
	anim.Start()

	w.ShowAndRun()
}

```
在fyne中，所有动画可以设置为循环。使用下面的语句

```go
anim.RepeatCount = fyne.AnimationRepeatForever
```

如果上面的例子我们给动画加上这个属性，动画就会一直循环下去。

### 支持拖放

在Fyne框架中，支持文件拖放的功能可以通过实现`fyne.Draggable` 和 `fyne.URIReadCloser` 接口来完成，具体步骤如下：

首先，引入fyne包：
```go
import "fyne.io/fyne/v2"
```

然后创建一个自定义的类型，实现 `fyne.Draggable` 和 `fyne.URIReadCloser`接口。如下是一个简单的例子：

```go
type fileDragger struct {
 widget.BaseWidget
}

func newFileDragger() *fileDragger {
 d := &fileDragger{}
 d.ExtendBaseWidget(d)
 return d
}

func (d *fileDragger) Dragged(e *fyne.DragEvent) {
 //你可以在这里处理拖动事件
}

func (d *fileDragger) DragEnd() {
 //你可以在这里处理拖动结束事件
}

func (d *fileDragger) CreateRenderer() fyne.WidgetRenderer {
 return widget.NewSimpleRenderer(widget.NewLabel("Drag and drop a file"))
}

func (d *fileDragger) DraggedURI(uri fyne.URIReadCloser) {
 //处理文件拖放的业务逻辑
 //通过 uri.Read() 方法可以读取拖放的文件数据
}
```

其中，`Dragged(e *fyne.DragEvent)`方法是处理拖动事件的方法，`DragEnd()`方法是处理拖动结束事件的方法，`CreateRenderer() fyne.WidgetRenderer`方法用于创建渲染器（在此例中，我们创建了一个简单的label作为渲染器），`DraggedURI(uri fyne.URIReadCloser)`方法是处理文件拖放的方法。

创建好上述自定义的类型后，就可以在窗口中添加这个自定义的widget，并且这个widget可以接受文件的拖放了。

以上只是一个简单的例子，你可能需要根据实际需求来修改和完善这个例子。

### 界面缩放

fyne默认是自动缩放的。你可以使用 `fyne_settings` 应用程序或使用 `FYNE_SCALE` 环境变量设置特定比例来调整应用程序的大小。这些值可以使内容比系统设置大或小，使用 "1.5 "会使内容大 50%，设置 0.8 会使内容小 20%。

### 数据绑定

数据绑定是 Fyne 工具包的一个强大的新增功能，该工具包在 version `v2.0.0` 中引入。通过使用数据绑定，我们可以避免手动管理许多标准对象，如 `Label` s、 `Button` s 和 `List` s。

内置绑定支持许多基元类型（如 `Int` 、 等 `Float` ）、列表（如 `StringList` 、 `BoolList` `String` ）以及 `Map` 和 `Struct` 绑定。这些类型中的每一种都可以使用简单的构造函数创建。例如，要创建具有零值的新字符串绑定，可以使用 `binding.NewString()` .可以使用 `Get` 和 `Set` 方法获取或设置大多数数据绑定的值。

也可以使用类似的函数绑定到现有值，这些函数的名称以名字开头 `Bind` ，并且它们都接受指向类型绑定的指针。要绑定到现有的 `int` ，我们可以使用 `binding.BindInt(&myInt)` .通过保留对绑定值而不是原始变量的引用，我们可以配置小部件和函数以自动响应任何更改。如果直接更改外部数据，请务必调用 `Reload` （） 以确保绑定系统读取新值。

```go
package main

import (
	"log"

	"fyne.io/fyne/v2/data/binding"
)

func main() {
	boundString := binding.NewString()
	s, _ := boundString.Get()
	log.Printf("Bound = '%s'", s)

	myInt := 5
	boundInt := binding.BindInt(&myInt)
	i, _ := boundInt.Get()
	log.Printf("Source = %d, bound = %d", myInt, i)
}
```

接下来，我们开始学习简单值小部件绑定。

#### 绑定简单部件

绑定小部件的最简单形式是将绑定项作为值而不是静态值传递给它。许多小组件都提供了一个构造函数，该 `WithData` 构造函数将接受类型化数据绑定项。要设置绑定，您需要做的就是传入正确的类型。

尽管这在初始代码中看起来可能没有多大好处，但您可以看到它如何确保显示的内容始终与数据源保持同步。您会注意到，我们不需要调用 `Refresh()` 小 `Label` 部件，甚至不需要保留对它的引用，但它会适当地更新。

```go
package main

import (
	"time"

	"fyne.io/fyne/v2/app"
	"fyne.io/fyne/v2/data/binding"
	"fyne.io/fyne/v2/widget"
)

func main() {
	myApp := app.New()
	w := myApp.NewWindow("Simple")

	str := binding.NewString()
	str.Set("Initial value")

	text := widget.NewLabelWithData(str)
	w.SetContent(text)

	go func() {
		time.Sleep(time.Second * 2)
		str.Set("A new string")
	}()

	w.ShowAndRun()
}
```

在下一步中，我们将了解如何设置通过双向绑定编辑值的小部件。

#### 双向绑定

到目前为止，我们已经将数据绑定视为使用户界面元素保持最新的一种方式。然而，更常见的是需要更新 UI 小部件中的值，并使数据在任何地方保持最新。值得庆幸的是，Fyne 中提供的绑定是“双向”的，这意味着值可以被推入其中并读出。数据更改将传达给所有连接的代码，而无需任何附加代码。

若要查看其实际效果，我们可以更新最后一个测试应用，以显示绑定到相同值的 a `Label` 和 an `Entry` 。通过设置，您可以看到，通过条目编辑值也会更新标签中的文本。这一切都是可能的，而无需在我们的代码中调用 refresh 或引用小部件。

通过将应用移动为使用数据绑定，可以停止保存指向所有小组件的指针。相反，通过将数据捕获为一组绑定值，您的用户界面可以是完全独立的代码。阅读更简洁，更易于管理。

```go
package main

import (
	"fyne.io/fyne/v2/app"
	"fyne.io/fyne/v2/container"
	"fyne.io/fyne/v2/data/binding"
	"fyne.io/fyne/v2/widget"
)

func main() {
	myApp := app.New()
	w := myApp.NewWindow("Two Way")

	str := binding.NewString()
	str.Set("Hi!")

	w.SetContent(container.NewVBox(
		widget.NewLabelWithData(str),
		widget.NewEntryWithData(str),
	))

	w.ShowAndRun()
}
```

#### 数据转换

到目前为止，我们使用了数据绑定，其中数据类型与输出类型匹配（例如 `String` ，和 `Label` 或 `Entry` ）。通常，最好呈现格式不正确的数据。为此，该 `binding` 软件包提供了许多有用的转换函数。

最常见的是，这将用于将不同类型的数据转换为字符串以显示在 OR `Entry` 小部件中 `Label` 。在代码中查看我们如何将 a `Float` 转换为 `String` 使用 `binding.FloatToString` .可以通过移动滑块来编辑原始值。每次数据更改时，它都会运行转换代码并更新任何连接的小部件。

还可以使用格式字符串为用户界面添加更自然的输出。您可以看到我们的 `short` 绑定也正在将 a `Float` 转换为，但通过使用 `WithFormat` 帮助程序， `String` 我们可以传递格式字符串（类似于包） `fmt` 以提供自定义输出。

```go
package main

import (
	"fyne.io/fyne/v2/app"
	"fyne.io/fyne/v2/container"
	"fyne.io/fyne/v2/data/binding"
	"fyne.io/fyne/v2/widget"
)

func main() {
	myApp := app.New()
	w := myApp.NewWindow("Conversion")

	f := binding.NewFloat()
	str := binding.FloatToString(f)
	short := binding.FloatToStringWithFormat(f, "%0.0f%%")
	f.Set(25.0)

	w.SetContent(container.NewVBox(
		widget.NewSliderWithData(0, 100.0, f),
		widget.NewLabelWithData(str),
		widget.NewLabelWithData(short),
	))

	w.ShowAndRun()
}
```

最后，在本节中，我们将查看列表数据。

#### 列表

为了演示如何连接更复杂的类型，我们将查看 `List` 小部件以及数据绑定如何使其更易于使用。首先，我们创建一个 `StringList` 数据绑定，它是一个数据类型列表 `String` 。一旦我们有了列表类型的数据，我们就可以将其连接到标准 `List` 小部件。为此，我们使用构造函数， `widget.NewListWithData` 就像其他小部件一样。

将此代码与列表教程进行比较 您将看到 2 个主要变化，第一个是我们将数据类型作为第一个参数传递，而不是长度回调函数。第二个变化是最后一个参数，即我们的 `UpdateItem` 回调。修订后的版本采用一个 `binding.DataItem` 值而不是 `widget.ListIndexID` 。使用此回调结构时，我们应该 `Bind` 对模板标签小部件进行调用，而不是调用 `SetText` .这意味着，如果数据源中的任何字符串发生更改，表中每个受影响的行都将刷新。

```go
package main

import (
	"fmt"

	"fyne.io/fyne/v2"
	"fyne.io/fyne/v2/app"
	"fyne.io/fyne/v2/container"
	"fyne.io/fyne/v2/data/binding"
	"fyne.io/fyne/v2/widget"
)

func main() {
	myApp := app.New()
	myWindow := myApp.NewWindow("List Data")

	data := binding.BindStringList(
		&[]string{"Item 1", "Item 2", "Item 3"},
	)

	list := widget.NewListWithData(data,
		func() fyne.CanvasObject {
			return widget.NewLabel("template")
		},
		func(i binding.DataItem, o fyne.CanvasObject) {
			o.(*widget.Label).Bind(i.(binding.String))
		})

	add := widget.NewButton("Append", func() {
		val := fmt.Sprintf("Item %d", data.Length()+1)
		data.Append(val)
	})
	myWindow.SetContent(container.NewBorder(nil, add, nil, nil, list))
	myWindow.ShowAndRun()
}
```

在我们的演示代码中，有一个 “Append” `Button` ，当点击它时，它将向数据源附加一个新值。这样做将自动触发数据更改处理程序并展开 `List` 小组件以显示新数据。

#### 资源绑定

基于 Go 的应用程序通常构建为单个二进制可执行文件，这对于 Fyne 应用程序也是如此。只需一个文件，就可以更轻松地分发安装我们的软件。遗憾的是，GUI 应用程序通常需要额外的资源来呈现用户界面。为了应对这一挑战，Go 应用程序可以将资产捆绑到二进制文件本身中。Fyne 工具包更喜欢使用“fyne bundle”，因为它具有我们将在下面探讨的各种好处。

捆绑资产的基本方法是执行“fyne bundle”命令。这个工具有各种参数来自定义输出，但在其基本形式中，要捆绑的文件将被转换为可以内置到您的应用程序中的 Go 源代码。

```go
$ ls
image.png	main.go
$ fyne bundle -o bundled.go image.png
$ ls
bundled.go	image.png	main.go
$ 
```

的内容 `bundled.go` 将是资源变量列表，然后我们可以在代码中访问这些变量。例如，上面的代码将生成一个包含以下内容的文件：

```go
var resourceImagePng = &fyne.StaticResource{
	StaticName: "image.png",
	StaticContent: []byte{
...
	}}
```

如您所见，默认命名为“resource”。此文件中使用的名称和包可以在命令参数中自定义。然后，我们可以使用此名称在画布上加载图像：

```go
img := canvas.NewImageFromResource(resourceImagePng)
```

fyne 资源只是具有唯一名称的字节集合，因此它可以是字体、声音文件或您希望加载的任何其他数据。此外，还可以使用该 `-append` 参数将许多资源捆绑到单个文件中。如果要捆绑多个文件，建议将命令保存在其中一个 go 文件（不是 bundled.go）的 go：generate 标头中：

```go
//go:generate fyne bundle -o bundled.go image1.png
//go:generate fyne bundle -o bundled.go -append image2.png
```

如果您随后更改任何资产或添加新资产，则可以更新此标头并使用“go generate”运行它以更新文件 `bundled.go` 。然后，您应该添加到 `bundled.go` 版本控制中，以便其他人可以构建您的应用程序，而无需运行“fyne bundle”。

###  自定义控件

Fyne 附带的标准小部件旨在支持标准用户交互和要求。由于 GUI 通常必须提供自定义功能，因此可能需要编写自定义小部件。本文概述了如何操作。

小部件分为两个区域 - 每个区域实现一个标准接口 - 和 `fyne.Widget` `fyne.WidgetRenderer` .小部件定义行为和状态，渲染器用于定义应如何将其绘制到屏幕上。

#### fyne.Widget

Fyne 中的小部件只是一个有状态的画布对象，其渲染定义与主逻辑分离。从 `fyne.Widget` 界面中可以看出，必须实现的内容并不多。

```
type Widget interface {
	CanvasObject

	CreateRenderer() WidgetRenderer
}
```

由于小部件需要像我们从同一界面继承的任何其他画布项一样使用。为了节省编写所需的所有函数，我们可以使用处理基础知识的 `widget.BaseWidget` 类型。

每个小部件定义将包含比接口所需的更多内容。在 Fyne 小部件中，导出定义行为的字段是标准配置（就像 `canvas` 包中定义的原语一样）。

例如，查看 `widget.Button` 类型：

```go
type Button struct {
	BaseWidget
	Text  string
	Style ButtonStyle
	Icon  fyne.Resource

	OnTapped func()
}
```

您可以看到这些项目中的每一个如何存储有关小部件行为的状态，但看不到有关其呈现方式的状态。

#### fyne.WidgetRenderer

小部件渲染器负责管理 `fyne.CanvasObject` 基元列表，这些基元组合在一起以创建小部件的设计。它很像具有 `fyne.Container` 自定义布局和一些附加主题处理的功能。

每个小组件都必须提供一个呈现器，但完全可以重用另一个小组件中的呈现器 - 尤其是当您的小组件是另一个标准控件的轻量级包装器时。

```
type WidgetRenderer interface {
	Layout(Size)
	MinSize() Size

	Refresh()
	Objects() []CanvasObject
	Destroy()
}
```

正如你所看到的 `Layout(Size)` ，和 `MinSize()` 函数类似于界面， `fyne.Layout` 没有参数 `[]fyne.CanvasObject` - 这是因为确实需要布置一个小部件，但它控制将包含哪些对象。

当此呈现器绘制的小部件已更改或主题已更改时，将触发该 `Refresh()` 方法。在任何一种情况下，我们可能需要调整它的外观。最后，当不再需要此渲染器时，将调用该 `Destroy()` 方法，因此它应该清除任何可能泄漏的资源。

再次与按钮小部件进行比较 - 它的 `fyne.WidgetRenderer` 实现基于以下类型：

```go
type buttonRenderer struct {
	icon   *canvas.Image
	label  *canvas.Text
	shadow *fyne.CanvasObject

	objects []fyne.CanvasObject
	button  *Button
}
```

如您所见，它具有用于缓存实际图像、文本和阴影画布对象以进行绘图的字段。为了方便起见， `fyne.WidgetRenderer` 它会跟踪所需的对象切片。

最后，它保留对所有状态信息的 `widget.Button` 引用。在该 `Refresh()` 方法中，它将根据基础 `widget.Button` 类型的任何更改更新图形状态。

#### 整合Widget和Renderer

基本小部件将扩展 `widget.BaseWidget` 类型并声明小部件所持有的任何状态。该 `CreateRenderer()` 函数必须存在并返回一个新 `fyne.WidgetRenderer` 实例。Fyne 中的小部件和驱动程序代码将确保相应地缓存此方法 - 此方法可以多次调用（例如，如果小部件被隐藏然后显示）。如果 `CreateRenderer()` 再次调用，则应返回一个新的渲染器实例，因为旧的渲染器实例可能已被销毁。

注意不要在渲染器中保留任何重要状态 - 动画代码非常适合该位置，但用户状态则不适合。隐藏的小部件可能会破坏其渲染器，如果它再次显示，新的渲染器必须能够反映相同的小部件状态。

#### 将 SimpleRenderer 用于自定义小部件

从单个 `CanvasObject` 构建的自定义小部件，例如包装多个内置小部件的容器，可以使用 `SimpleRenderer` 实现。下面的示例是一个自定义小部件，可以用作列表视图中的项目，在左侧显示标题，如果太长将被截断，则在右侧显示注释。构造函数将从列表 `CreateItem` 的函数中调用，并在 `UpdateItem` 函数中更改标题和注释：

```go
type MyListItemWidget struct {
	widget.BaseWidget
	Title   *widget.Label
	Comment *widget.Label
}

func NewMyListItemWidget(title, comment string) *MyListItemWidget {
	item := &MyListItemWidget{
		Title:   widget.NewLabel(title),
		Comment: widget.NewLabel(comment),
	}
	item.Title.Truncation = fyne.TextTruncateEllipsis
	item.ExtendBaseWidget(item)

	return item
}

func (item *MyListItemWidget) CreateRenderer() fyne.WidgetRenderer {
	c := container.NewBorder(nil, nil, nil, item.Comment, item.Title)
	return widget.NewSimpleRenderer(c)
}
```

#### 扩展Widget

标准的 Fyne 小部件提供最低限度的功能和自定义，以支持大多数用例。在某些时候可能需要具有更高级的功能。与其让开发人员构建自己的小部件，不如扩展现有的小部件。

例如，我们将扩展图标小部件以支持被点击。为此，我们声明了一个嵌入 `widget.Icon` 该类型的新结构。我们创建一个构造函数来调用重要 `ExtendBaseWidget` 函数。

```
import (
	"fyne.io/fyne/v2"
	"fyne.io/fyne/v2/widget"
)

type tappableIcon struct {
	widget.Icon
}

func newTappableIcon(res fyne.Resource) *tappableIcon {
	icon := &tappableIcon{}
	icon.ExtendBaseWidget(icon)
	icon.SetResource(res)

	return icon
}
```

> 注意：像这样的 `widget.NewIcon` 小部件构造函数可能不会用于扩展，因为它已经调用 `ExtendBaseWidget` 了 .

然后，我们添加新函数来实现 `fyne.Tappable` 接口，添加这些函数后，每次用户点击我们的新图标时都会调用新 `Tapped` 函数。所需的接口有两个函数，和 `TappedSecondary(*PointEvent)` ， `Tapped(*PointEvent)` 因此我们将同时添加这两个函数。

```go
import "log"

func (t *tappableIcon) Tapped(_ *fyne.PointEvent) {
	log.Println("I have been tapped")
}

func (t *tappableIcon) TappedSecondary(_ *fyne.PointEvent) {
}
```

我们可以使用一个简单的应用程序来测试这个新的小部件，如下所示。

```go
import (
    "fyne.io/fyne/v2/app"
    "fyne.io/fyne/v2/theme"
)

func main() {
	a := app.New()
	w := a.NewWindow("Tappable")
	w.SetContent(newTappableIcon(theme.FyneLogo()))
	w.ShowAndRun()
}
```

### 自定义主题

应用程序能够加载自定义主题，这些主题可以对标准主题进行小的更改或提供完全独特的外观。一个主题需要实现 `fyne.Theme` 接口的功能，定义如下：

```
type Theme interface {
	Color(ThemeColorName, ThemeVariant) color.Color
	Font(TextStyle) Resource
	Icon(ThemeIconName) Resource
	Size(ThemeSizeName) float32
}
```

为了应用我们的主题更改，我们将首先定义一个实现此接口的新类型。

###  定义主题

在前面的例子，我们已经演示了自定义主题，这里我们再来温习下。我们首先定义一个新类型作为我们的主题，一个简单的空结构就可以了：

```go
type myTheme struct {}
```

断言我们实现一个接口，以便编译错误更接近定义类型是一个好主意。

```go
var _ fyne.Theme = (*myTheme)(nil)
```

此时，您可能会看到编译错误，因为我们仍然需要实现这些方法，我们从颜色开始。

####  自定义颜色

`Theme` 接口中定义的 `Color` 函数要求我们定义命名颜色，并为用户所需的变体（例如 `theme.VariantLight` 或 `theme.VariantDark` ）提供提示。在我们的主题中，我们将返回自定义背景颜色 - 使用不同的浅色和深色值。

```go
func (m myTheme) Color(name fyne.ThemeColorName, variant fyne.ThemeVariant) color.Color {
	if name == theme.ColorNameBackground {
		if variant == theme.VariantLight {
			return color.White
		}
		return color.Black
	}

	return theme.DefaultTheme().Color(name, variant)
}
```

您将看到此处的最后一行引用了 `theme.DefaultTheme()` 查找标准值。这允许我们提供自定义值，但当我们不想提供自己的值时，可以回退到标准主题。

当然，颜色比资源更简单，我们看一下自定义图标。

#### 覆盖默认图标

图标（和字体）用作 `fyne.Resource` 值，而不是简单的类型，如 `int` （大小）或 `color.Color` 颜色。我们可以使用 构建自己的资源，也可以传入使用 `fyne.NewStaticResource` 资源嵌入创建的值。

```go
func (m myTheme) Icon(name fyne.ThemeIconName) fyne.Resource {
	if name == theme.IconNameHome {
		fyne.NewStaticResource("myHome", homeBytes)
	}
	
	return theme.DefaultTheme().Icon(name)
}
```

如上所述，如果我们不想提供特定的覆盖，我们将返回默认主题图标。

####  加载主题

在我们加载主题之前，您还需要实现 `Size` 和 `Font` 方法。如果您愿意使用默认值，则可以只使用这些空实现。

```go
func (m myTheme) Font(style fyne.TextStyle) fyne.Resource {
	return theme.DefaultTheme().Font(style)
}

func (m myTheme) Size(name fyne.ThemeSizeName) float32 {
	return theme.DefaultTheme().Size(name)
}
```

若要为应用设置主题，需要添加以下代码行：

```go
app.Settings().SetTheme(&myTheme{})
```

通过这些更改，您可以应用自己的风格，进行小的调整或提供完全自定义的应用程序！

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

然后通过 `fyne package`就可以一键打包了。

> 文件的顶部部分是元数据，如果您将应用程序上传到 https://apps.fyne.io 列表页面，就会用到这些元数据，因此是可选的。`[Details]`部分包含有关您应用程序的数据，这些数据会被其他应用程序商店和操作系统用于发布程序。如果找到该文件，fyne 工具就会使用它，如果元数据存在，许多强制性命令参数就不是必需的。你仍然可以使用命令行参数覆盖这些值。每进行一次编译，`Build`都会自动递增，并在下一次编译时更新您的程序版本号。

### 代码建议

####  页面拆分设计

当你使用 Fyne 这样的 GUI 库来开发应用程序时，将页面拆分为单独的包是一种很好的做法，因为它可以提高代码的模块性和可维护性。下面是一些建议以及一个简单的示例代码，展示如何实现这一点：

##### 建议

1. **模块化设计**：确保每个包都有清晰的职责。例如，一个包可以负责创建应用程序的主窗口，而另一个包则负责处理用户的输入。
2. **接口使用**：定义接口以规范不同包之间的交互。这有助于保持代码的解耦。
3. **共享资源**：对于跨多个包使用的资源，如图像或配置文件，可以创建一个单独的包或者使用全局变量。
4. **错误处理**：确保每个包都有适当的错误处理机制。
5. **测试**：为每个包编写单元测试，以确保独立性和功能性。

##### 示例代码

假设你有一个 Fyne 应用程序，你想将主界面和一个设置页面分别放在不同的包中。

###### main.go

```go
goCopy codepackage main

import (
	"fyne-app/ui"  // 假设 'ui' 是主界面的包
	"fyne-app/settings"  // 假设 'settings' 是设置页面的包
	"fyne.io/fyne/v2/app"
)

func main() {
	myApp := app.New()
	myWindow := myApp.NewWindow("Fyne Demo")

	mainUI := ui.NewMainUI()
	settingsUI := settings.NewSettingsUI()

	// 这里可以添加逻辑来切换不同的UI
	myWindow.SetContent(mainUI)

	myWindow.ShowAndRun()
}
```

###### ui/main_ui.go

```go
goCopy codepackage ui

import "fyne.io/fyne/v2/container"

// NewMainUI 创建并返回主界面的UI组件
func NewMainUI() *fyne.Container {
	// 创建主UI组件
	return container.NewVBox(
		// 添加组件
	)
}
```

###### settings/settings_ui.go

```go
goCopy codepackage settings

import "fyne.io/fyne/v2/container"

// NewSettingsUI 创建并返回设置界面的UI组件
func NewSettingsUI() *fyne.Container {
	// 创建设置UI组件
	return container.NewVBox(
		// 添加组件
	)
}
```

这个结构允许你分别在 `ui` 和 `settings` 包中管理不同的UI部分，同时通过 `main.go` 来协调它们。记得根据你的实际需求调整包和代码结构。

#### 逻辑拆分设计
在拆分页面的过程中涉及到页面跳转时，遵循一些软件设计的最佳实践可以帮助你维护代码的清晰性和可维护性。以下是一些关键的实践和一个示例代码，展示如何在 Fyne 应用程序中实现页面跳转：

##### 最佳实践

1. **封装页面逻辑**：确保每个页面的逻辑都被封装在其各自的包中。这样，每个页面都是独立的，且可以轻松地从其他页面调用。
2. **定义清晰的接口**：对于涉及多个页面之间交互的功能，定义清晰的接口。这有助于降低页面间的耦合度。
3. **事件驱动的交互**：使用事件或回调函数来处理页面之间的交互，这样可以避免直接依赖于其他页面的内部实现。
4. **统一的导航机制**：使用统一的机制来处理页面间的导航，例如通过主窗口或导航控制器来管理不同页面的显示。
5. **避免全局状态**：尽量避免使用全局状态来管理页面间的交互，这样可以使得每个页面更加独立和可测试。

##### 示例代码

以下是一个简单的示例，展示了如何在 Fyne 应用程序中实现两个页面之间的跳转：

###### main.go

```go
goCopy codepackage main

import (
	"fyne-app/ui"  // 主界面包
	"fyne-app/settings"  // 设置页面包
	"fyne.io/fyne/v2/app"
)

func main() {
	myApp := app.New()
	myWindow := myApp.NewWindow("Fyne Demo")

	// 创建页面
	mainUI := ui.NewMainUI()
	settingsUI := settings.NewSettingsUI()

	// 页面跳转逻辑
	mainUI.OnSettingsButtonTapped(func() {
		myWindow.SetContent(settingsUI)
	})
	settingsUI.OnBackButtonTapped(func() {
		myWindow.SetContent(mainUI)
	})

	myWindow.SetContent(mainUI)
	myWindow.ShowAndRun()
}
```

###### ui/main_ui.go

```go
goCopy codepackage ui

import (
	"fyne.io/fyne/v2/container"
	"fyne.io/fyne/v2/widget"
)

// MainUI 代表主界面
type MainUI struct {
	onSettingsButtonTapped func()
}

// NewMainUI 创建并返回主界面的UI组件
func NewMainUI() *MainUI {
	ui := &MainUI{}
	// 创建主UI组件
	settingsButton := widget.NewButton("Settings", func() {
		if ui.onSettingsButtonTapped != nil {
			ui.onSettingsButtonTapped()
		}
	})
	return container.NewVBox(
		settingsButton,
		// 其他组件
	)
}

// OnSettingsButtonTapped 设置当设置按钮被点击时的回调
func (ui *MainUI) OnSettingsButtonTapped(callback func()) {
	ui.onSettingsButtonTapped = callback
}
```

###### settings/settings_ui.go

```go
goCopy codepackage settings

import (
	"fyne.io/fyne/v2/container"
	"fyne.io/fyne/v2/widget"
)

// SettingsUI 代表设置页面
type SettingsUI struct {
	onBackButtonTapped func()
}

// NewSettingsUI 创建并返回设置界面的UI组件
func NewSettingsUI() *SettingsUI {
	ui := &SettingsUI{}
	// 创建设置UI组件
	backButton := widget.NewButton("Back", func() {
		if ui.onBackButtonTapped != nil {
			ui.onBackButtonTapped()
		}
	})
	return container.NewVBox(
		backButton,
		// 其他组件
	)
}

// OnBackButtonTapped 设置当返回按钮被点击时的回调
func (ui *SettingsUI) OnBackButtonTapped(callback func()) {
	ui.onBackButtonTapped = callback
}
```

在这个示例中，`mainUI` 和 `settingsUI` 都提供了方法来设置它们按钮的回调。这种方法使得主函数可以控制页面之间的跳转，同时保持各个页面的独立性。

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
> https://github.com/fyne-io/fyne-x 包含了社区的fyne一些扩展，如响应式布局(Responsive Layout)、gif动画显示图标、日历、流程图、树状文件夹、自动完成组件、分段十六进制(Segment ("Hex") Display)、地图、以及一个Adwaita的主题等

