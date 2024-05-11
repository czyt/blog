---
title: "Avalonia使用备忘"
date: 2023-07-31
tags: ["windows", "avalonia"]
draft: false
---

## Avalonia 中的一些特性

### Binding

#### $parent

您可以使用`$parent`符号绑定到目标在逻辑上的父级：

```xaml
<Button DockPanel.Dock="Bottom"
        HorizontalAlignment="Stretch"
        HorizontalContentAlignment="Center"
        x:CompileBindings="False"
        Command="{Binding $parent[Window].DataContext.AddItem}">Add Item
</Button>
```
```xaml
<Border Tag="Hello World!">

 <TextBlock Text="{Binding $parent.Tag}"/>

 </Border>
```

也可以通过在$parent符号添加索引器绑定到父控件的父控件：

```xaml
<Border Tag="Hello World!">
 <Border>
 <TextBlock Text="{Binding $parent[1].Tag}"/>
 </Border>
 </Border>
```
索引器从0开始，因此$parent[0]等同于$parent。
还可以按类型绑定到祖先：

```xaml
<Border Tag="Hello World!">
 <Decorator>
   <TextBlock Text="{Binding $parent[Border].Tag}"/>
 </Decorator>
 </Border>
```
最后，您可以组合索引器和类型：

```xaml
<Border Tag="Hello World!">
 <Border>
  <Decorator>
  <TextBlock Text="{Binding $parent[Border;1].Tag}"/>
   </Decorator>
 </Border>
 </Border>
```
如果需要在祖先类型中包含XAML命名空间，一般使用:字符：

```xaml
<local:MyControl Tag="Hello World!">
 <Decorator>
  <TextBlock Text="{Binding $parent[local:MyControl].Tag}"/>
 </Decorator>
 </local:MyControl>
```
#### #name

如果要绑定到另一个已命名控件的属性，可以使用以`#`字符为前缀的控件名称.

```xaml
<TextBox Name="other">
 
 <!-- 绑定到命名为“other”控件的Text属性 -->
 
 <TextBlock Text="{Binding #other.Text}"/>
```

avalonia同样支持wpf中的这种写法

```xaml
<TextBox Name="other">
 
 <TextBlock Text="{Binding Text, ElementName=other}"/>
```
#### Code Behind

Avalonia 中代码的绑定工作方式与 WPF/UWP 有所不同。在底层，Avalonia 的绑定系统基于 Reactive Extensions 的 `IObservable` ，然后由 XAML 绑定（也可以在代码中实例化）构建。

##### 订阅属性变化

您可以通过调用 `GetObservable` 方法来订阅属性的更改。这将返回一个 `IObservable<T>` ，可用于侦听属性的更改：

```c#
var textBlock = new TextBlock();
var text = textBlock.GetObservable(TextBlock.TextProperty);
```

每个可以订阅的属性都有一个名为 `[PropertyName]Property` 的静态只读字段，该字段被传递到 `GetObservable` 以订阅属性的更改。`IObservable` （Reactive Extensions 的一部分，简称 rx）超出了本指南的范围，但这里有一个示例，它使用返回的 observable 将包含更改的属性值的消息打印到控制台：

```c#
var textBlock = new TextBlock();
var text = textBlock.GetObservable(TextBlock.TextProperty);
text.Subscribe(value => Console.WriteLine(value + " Changed"));
```

当返回的 observable 被订阅时，它将立即返回属性的当前值，然后每次属性发生变化时推送一个新值。如果您不需要当前值，可以使用 rx `Skip` 运算符：

```c#
var text = textBlock.GetObservable(TextBlock.TextProperty).Skip(1);
```

##### 绑定到observable

您可以使用 `AvaloniaObject.Bind` 方法将属性绑定到可观察对象：

```c#
// We use an Rx Subject here so we can push new values using OnNext
var source = new Subject<string>();
var textBlock = new TextBlock();

// Bind TextBlock.Text to source
var subscription = textBlock.Bind(TextBlock.TextProperty, source);

// Set textBlock.Text to "hello"
source.OnNext("hello");
// Set textBlock.Text to "world!"
source.OnNext("world!");

// Terminate the binding
subscription.Dispose();
```

请注意， `Bind` 方法返回可用于终止绑定的 `IDisposable` 。如果您从不调用此函数，那么当可观察对象通过 `OnCompleted` 或 `OnError` 完成时，绑定将自动终止。

##### 在对象初始值设定项中设置绑定

在对象初始值设定项中设置绑定通常很有用。您可以使用索引器来执行此操作：

```c#
var source = new Subject<string>();
var textBlock = new TextBlock
{
    Foreground = Brushes.Red,
    MaxWidth = 200,
    [!TextBlock.TextProperty] = source.ToBinding(),
};
```

使用此方法，您还可以轻松地将一个控件上的属性绑定到另一个控件上的属性：

```c#
var textBlock1 = new TextBlock();
var textBlock2 = new TextBlock
{
    Foreground = Brushes.Red,
    MaxWidth = 200,
    [!TextBlock.TextProperty] = textBlock1[!TextBlock.TextProperty],
};
```

当然，索引器也可以在对象初始值设定项之外使用：

```c#
textBlock2[!TextBlock.TextProperty] = textBlock1[!TextBlock.TextProperty];
```

此语法的唯一缺点是不返回 `IDisposable` 。如果您需要手动终止绑定，那么您应该使用 `Bind` 方法。

##### 改变绑定值

因为我们正在使用可观察量，所以我们可以轻松地转换我们绑定的值！

```c#
var source = new Subject<string>();
var textBlock = new TextBlock
{
    Foreground = Brushes.Red,
    MaxWidth = 200,
    [!TextBlock.TextProperty] = source.Select(x => "Hello " + x).ToBinding(),
};
```

##### 使用代码中的 XAML 绑定

有时，当您需要 XAML 绑定提供的附加功能时，从代码中使用 XAML 绑定会更容易。例如，仅使用可观察量，您可以绑定到 `DataContext` 上的属性，如下所示：

```c#
var textBlock = new TextBlock();
var viewModelProperty = textBlock.GetObservable(TextBlock.DataContext)
    .OfType<MyViewModel>()
    .Select(x => x?.Name);
textBlock.Bind(TextBlock.TextProperty, viewModelProperty);
```

但是，在这种情况下，最好使用 XAML 绑定：

```xaml
var textBlock = new TextBlock
{
    [!TextBlock.TextProperty] = new Binding("Name")
};
```

或者，如果您需要 `IDisposable` 来终止绑定：

```xaml
var textBlock = new TextBlock();
var subscription = textBlock.Bind(TextBlock.TextProperty, new Binding("Name"));

subscription.Dispose();
```

##### 订阅任何对象的属性

`GetObservable` 方法返回一个可观察对象，用于跟踪单个实例上属性的更改。但是，如果您正在编写一个控件，您可能需要实现一个不绑定到对象实例的 `OnPropertyChanged` 方法。为此，您可以订阅 `AvaloniaProperty.Changed` ，它是一个可观察对象，每次在任何实例上更改属性时都会触发该可观察对象。

> 在 WPF 中，这是通过将静态 `PropertyChangedCallback` 传递到 `DependencyProperty` 注册方法来完成的，但这仅允许控件作者注册属性更改回调。

此外，还有一个 `AddClassHandler` 扩展方法，可以自动将事件路由到控件上的方法。例如，如果您想监听控件的 `Foo` 属性的更改，您可以这样做：

```c#
static MyControl()
{
    FooProperty.Changed.AddClassHandler<MyControl>(x => x.FooChanged);
}

private void FooChanged(AvaloniaPropertyChangedEventArgs e)
{
    // The 'e' parameter describes what's changed.
}
```

##### 绑定到 `INotifyPropertyChanged` 对象

也可以绑定到实现 `INotifyPropertyChanged` 的对象。

```c#
var textBlock = new TextBlock();

var binding = new Binding 
{ 
    Source = someObjectImplementingINotifyPropertyChanged, 
    Path = nameof(someObjectImplementingINotifyPropertyChanged.MyProperty)
}; 

textBlock.Bind(TextBlock.TextProperty, binding);
```

##### 绑定到Task Result

如果您需要做一些繁重的工作来加载属性的内容，您可以绑定到 `async Task<TResult>` 的结果.假设您有以下视图模型，它在长时间运行的过程中生成一些文本：

```c#
public Task<string> MyAsyncText => GetTextAsync();

private async Task<string> GetTextAsync()
{
  await Task.Delay(1000); // The delay is just for demonstration purpose
  return "Hello from async operation";
}
```

您可以通过以下方式绑定到结果：

```xaml
<TextBlock Text="{Binding MyAsyncText^, FallbackValue='Wait a second'}" />
```

> 注意：您可以使用 `FallbackValue` 显示某些加载指示器。

您可以使用 `^` 流绑定运算符订阅任务或可观察结果的结果。例如，如果 `DataContext.Name` 是 `IObservable<string>` 那么下面的示例将绑定到生成每个值时由可观察对象生成的每个字符串的长度

```xaml
<TextBlock Text="{Binding Name^.Length}"/>
```
##### 绑定到排序/过滤数据

应用程序需要执行的常见 UI 任务是显示排序和/或过滤的数据“视图”。在 Avalonia 中，这可以通过将 `SourceCache<TObject, TKey>` 或 `SourceList<T>` 连接到 `ReadOnlyObservableCollection<T>` 并绑定到该集合来完成.

`SourceCache<TObject, TKey>` 或 `SourceList<T>` 来自 ReactiveUI 示例中的动态数据：

```c#
// (x => x.Id) property that serves as the unique key for the cache
private SourceCache<TestViewModel, Guid> _sourceCache = new (x => x.Id);
```

然后可以通过 `AddOrUpdate` 方法填充 `_sourceCache`接下来，可以将 `ReadOnlyObservableCollection<T>` 绑定到过滤或排序的 `_sourceCache` 。排序/过滤的完成方式与 linq 类似。

```c#
private readonly ReadOnlyObservableCollection<TestViewModel> _testViewModels;
public ReadOnlyObservableCollection<TestViewModel> TestViewModels => _testViewModels;
...
public MainWindowViewModel(){
    // Populate the source cache via _sourceCache.AddOrUpdate
    ...
    _sourceCache.Connect()
        // Sort Ascending on the OrderIndex property
        .Sort(SortExpressionComparer<TestViewModel>.Ascending(t => t.OrderIndex))
        .Filter(x => x.Id.ToString().EndsWith('1'))
        // Bind to our ReadOnlyObservableCollection<T>
        .Bind(out _testViewModels)
        // Subscribe for changes
        .Subscribe();
}
```

现在 `_sourceCache` 已创建并填充， `ReadOnlyObservableCollection<T>` 已创建并绑定，我们可以进入视图并按照通常使用 `ObservableCollection<T>` 的方式进行绑定

```xaml
    <Design.DataContext>
        <vm:MainWindowViewModel/>
    </Design.DataContext>

    <TreeView ItemsSource="{Binding TestViewModels}">
        <TreeView.DataTemplates>
            !-- DataTemplate Definitions -->
        </TreeView.DataTemplates> 
    </TreeView>
```

##### 内置binding Converter

| Converter                           | Description                                                  |
| ----------------------------------- | ------------------------------------------------------------ |
| `Negation Operator` !               | The ! operator can be placed in front of the data binding path to return the inversion of a Boolean value. See also the note below. |
| `StringConverters.IsNullOrEmpty`    | Returns `true` if the input string is null or empty          |
| `StringConverters.IsNotNullOrEmpty` | Returns `false` if the input string is null or empty         |
| `ObjectConverters.IsNull`           | Returns `true` if the input is null                          |
| `ObjectConverters.IsNotNull`        | Returns `false` if the input is null                         |
| `BoolConverters.And`                | A multi-value converter that returns `true` if all inputs are true. |
| `BoolConverters.Or`                 | A multi-value converter that returns `true` if any input is true. |

使用例子：

```xaml
<Panel>
  <ListBox ItemsSource="{Binding Items}"/>
  <TextBlock IsVisible="{Binding !Items.Count}">No results found</TextBlock>
</Panel>
```
### Style

avalonia支持css样式风格的样式`style`。样式不像 WPF 中那样存储在 `Resources` 集合中，而是存储在单独的 `Styles` 集合中。

```c#
<UserControl>
    <UserControl.Styles>
        <!-- Make TextBlocks with the h1 style class have a font size of 24 points -->
        <Style Selector="TextBlock.h1">
            <Setter Property="FontSize" Value="24"/>
        </Style>
    </UserControl.Styles>
    <TextBlock Classes="h1">Header</TextBlock>
<UserControl>
```
### classes属性

在Avalonia中，类（class）属性是用于为控件指定一个CSS类名的属性。通过为控件添加类属性，可以为控件应用自定义的样式。
要为控件添加类属性，可以使用Classes属性。Classes属性是控件的一个集合，用于存储控件的CSS类名。以下是添加类属性的一般步骤：
首先，在XAML中找到你要添加类属性的控件。例如，假设你要添加类属性到一个Button控件：

```xaml
<Button Content="Click me"></Button>
```

接下来，为该控件添加类属性。你可以通过在XAML中直接指定类属性的值来添加类名，或者通过在代码中动态修改Classes属性来添加或移除类名。以下是两种方法的示例：
在XAML中直接指定类名：

```xaml
<Button Content="Click me" Classes="my-button"></Button>
```

 在这个例子中，Classes属性被设置为"my-button"，这将为Button控件添加一个类名为"my-button"的CSS类。

通过代码动态修改Classes属性：

```c#
   using Avalonia.Controls;

   ...

   var myButton = new Button();
   myButton.Content = "Click me";
   myButton.Classes.Add("my-button");
```

在这个例子中，通过调用`Classes.Add("my-button")`方法，将类名"my-button"添加到myButton控件的Classes属性中。通过添加类属性，你可以为控件应用自定义的样式。你可以在CSS样式表中定义与类名对应的样式规则，并通过类属性将这些样式应用到相应的控件。需要注意的是，类属性可以用于任何继承自AvaloniaObject的对象，而不仅仅是控件。这意味着你可以为任何具有Classes属性的对象添加类名。

### Grid行列定义
列和行定义可以在 Avalonia 中使用字符串指定，避免 WPF 中笨重的语法：
  ```xaml
  <Grid ColumnDefinitions="Auto,*,32" RowDefinitions="*,Auto">
  ```

  WPF 中 `Grid` 的常见用途是将两个控件堆叠在一起。为此，在 Avalonia 中，您可以使用比 `Grid` 更轻量的 `Panel` 。

### 伪类

Avalonia 中的伪类与 CSS 中的伪类类似，是添加到选择器中的关键字，用于指定所选元素的特殊状态。它们可用于根据特定条件设置不同的控件样式。例如，按钮在按下时可以有不同的样式，或者文本框在禁用时可以有不同的样式。valonia 支持许多内置伪类，并且控件可以定义自己的伪类。

#### 使用

使用伪类，请将冒号 (:) 和伪类附加到选择器。这是一个例子：

```xaml
<Button Content="Click Me!">
  <Button.Styles>
    <Style Selector="Button:pointerover">
      <Setter Property="Background" Value="Red"/>
    </Style>
  </Button.Styles>
</Button>
```

在此示例中，由于使用了 `pointerover` 伪类，当指针悬停在按钮上方时，按钮的背景将变为红色。

内置伪类一些内置伪类包括：

- `:pointerover` ：鼠标指针位于控件上方。
- `:pressed` ：正在按下控件。
- `:disabled` ：该控件被禁用。
- `:focus` ：控件有输入焦点。
- `:watermark` ：对于 TextBox 控件，当它显示水印时。
- `:checked` ：对于可检查的控件，例如 CheckBox 或 MenuItem，当它被检查时。
- `:indeterminate` ：对于像 CheckBox 这样的控件，当它处于不确定状态时。
- `:valid` ：对于输入控件，当输入有效时。
- `:invalid` ：对于输入控件，当输入无效时。

您可以将伪类与类型选择器和类选择器结合起来以创建各种效果。

#### 自定义伪类

控件可以为特定行为定义自己的伪类。为了定义伪类，控件通常创建一个 `PseudoClass` 类型的静态只读字段，并调用 `PseudoClasses.Set()` 启用伪类，调用 `PseudoClasses.Remove()` 禁用它。

例如，自定义 `:custom` 伪类可能定义如下：

```xaml
public static readonly PseudoClass CustomPseudoClass = PseudoClass.Parse(":custom");

// to enable
PseudoClasses.Set(CustomPseudoClass);

// to disable
PseudoClasses.Remove(CustomPseudoClass);
```

这使得开发人员可以为他们的样式添加更多的表现力和控制力，根据非常具体的控制状态定制样式。

## 语言层面

### 与WPF的等价的表示

+ WPF 的 `HierarchicalDataTemplate `在 Avalonia 中称为 `TreeDataTemplate` （因为前者很难输入！）。除了命名之外，两者几乎完全等同。

+ WPF 的 `UIElement` 和 `FrameworkElement` 是非模板化控件基类，大致相当于 Avalonia `Control` 类。在 WPF/UWP 中，您可以从 `FrameworkElement` 类继承来创建新的自定义绘制控件，但在 Avalonia 中，您应该从 `Control.` 继承

+ WPF 的 `Control` 类是一个模板化控件 - Avalonia 的等价物是 `TemplatedControl` .在 WPF/UWP 中，您可以从 `Control` 类继承来创建新的模板化控件，但在 Avalonia 中，您应该从 `TemplatedControl.` 继承

+ `DependencyProperty` 的 Avalonia 等效项是 `StyledProperty` ，但是 Avalonia 具有比 WPF 更丰富的属性系统，并且包括用于将标准 CLR 属性转换为 Avalonia 属性的 `DirectProperty` 。 `StyledProperty` 和 `DirectProperty` 的共同基类是 `AvaloniaProperty` 。


### 与WPF不同的表示

+ Avalonia 具有隧道事件，但它们不会通过单独的 `Preview` CLR 事件处理程序公开。要订阅隧道事件，您必须使用 `RoutingStrategies.Tunnel` 调用 `AddHandler` ：
  ```c#
  target.AddHandler(InputElement.KeyDownEvent, OnPreviewKeyDown, RoutingStrategies.Tunnel);
  
  void OnPreviewKeyDown(object sender, KeyEventArgs e)
  {
      // Handler code
  }
  ```

  + 在 WPF 中，可以通过调用 EventManager.RegisterClassHandler 添加事件的类处理程序。在 WPF 中注册类处理程序的示例可能是：

  ```c#
  static MyControl()
  {
      EventManager.RegisterClassHandler(typeof(MyControl), MyEvent, HandleMyEvent));
  }
  
  private static void HandleMyEvent(object sender, RoutedEventArgs e)
  {
  }
  ```

  在Avalonia 中则是：

  ```c#
  static MyControl()
  {
      MyEvent.AddClassHandler<MyControl>((x, e) => x.HandleMyEvent(e));
  }
  
  private void HandleMyEvent(RoutedEventArgs e)
  {
  }
  ```

  请注意，在 WPF 中，您必须将类处理程序添加为静态方法，而在 Avalonia 中，类处理程序不是静态的：通知会自动定向到正确的实例。在这种情况下，事件处理程序典型的 `sender` 参数不是必需的，并且所有内容都保持强类型。

+ 侦听 WPF 中 DependencyProperties 的更改可能很复杂。当您注册 `DependencyProperty` 时，您可以提供静态 `PropertyChangedCallback` 但如果您想监听其他地方的更改，事情可能会变得复杂且容易出错。在 Avalonia 中，注册时没有 `PropertyChangedCallback` ，而是将类侦听器添加到控件的静态构造函数中，其方式与添加事件类侦听器的方式大致相同。

+ WPF 和 Avalonia 中的 RenderTransformOrigins 不同：如果应用 `RenderTransform` ，请记住 Avalonia 中 RenderTransformOrigin 的默认值为 `RelativePoint.Center` 。在 WPF 中，默认值为 `RelativePoint.TopLeft` (0, 0)。在像 Viewbox 这样的控件中，相同的代码将导致不同的渲染行为。在 AvaloniaUI 中，为了获得相同的比例变换，我们应该指示 RenderTransformOrigin 是 Visual 的左上角部分。
  在wpf:
  ![WPF](https://files.gitter.im/AvaloniaUI/Avalonia/cDrM/image.png)
  在avalonia：
  ![Avalonia](https://files.gitter.im/AvaloniaUI/Avalonia/KGk7/image.png)

## 资产文件

### 一般资产文件

许多应用程序需要包含位图、样式和资源字典等资源。资源字典包含可以在 XAML 中声明的图形基础知识。样式也可以用 XAML 编写，但位图资源是二进制文件，例如 PNG 和 JPEG 格式。
![img](https://docs.avaloniaui.net/img/gitbook-import/assets/image%20(8).png)

您可以通过在项目文件中使用 `<AvaloniaResource>` 元素将资源包含在应用程序中。例如，Avalonia .NET Core MVVM 应用解决方案模板创建一个名为 `Assets` 的文件夹（包含 `avalonia-logo.ico` 文件），并向项目文件添加一个元素以包含位于其中的所有文件。如下：
```xml
<ItemGroup>
  <AvaloniaResource Include="Assets\**"/>
</ItemGroup>
```

您可以通过在此项目组中添加其他 `<AvaloniaResource>` 元素来包含所需的任何文件。包含资产文件后，可以根据需要在定义 UI 的 XAML 中引用它们。例如，通过指定它们的相对路径来引用这些资源：
```xaml
<Image Source="icon.png"/>
<Image Source="images/icon.png"/>
<Image Source="../icon.png"/>
```

作为替代方案，您可以使用根路径：

```xml
<Image Source="/Assets/icon.png"/>
```
### 类库资产文件

同样地，在类库中也会包含资产文件
![img](https://docs.avaloniaui.net/img/gitbook-import/assets/image.png)
如果资源包含在与 XAML 文件不同的程序集中，则可以使用 `avares:` URI 方案。例如，如果资源包含在 `Assets` 文件夹中名为 `MyAssembly.dll` 的程序集中，则可以使用：

```xml
<Image Source="avares://MyAssembly/Assets/icon.png"/>
```
### 资产类型转换

Avalonia UI 具有内置转换器，可以立即加载位图、图标和字体的资源。因此资产 Uri 可以自动转换为以下任意一种：

- 图片 - `Image` 类型
- 位图 - `Bitmap` 类型
- 窗口图标 - `WindowIcon` 类型
- 字体 - `FontFamily` 类型

您可以使用 `AssetLoader` 静态类编写代码来加载资源。例如：

```xaml
var bitmap = new Bitmap(AssetLoader.Open(new Uri(uri)));
```

上述代码中的 `uri` 变量可以包含具有 `avares:` 方案的任何有效 URI（如上所述）。

> Avalonia UI 不提供对 `file://` 、 `http://` 或 `https://` 方案的支持。如果要从磁盘或 Web 加载文件，则必须自己实现该功能或使用社区实现。Avalonia UI 在 https://github.com/AvaloniaUtils/AsyncImageLoader.Avalonia 上有一个图像加载器的社区实现

使用自己的字体
```xaml
<TextBlock Text="{Binding Greeting}" 
           FontSize="70" 
           FontFamily="{StaticResource NunitoFont}" 
           HorizontalAlignment="Center" VerticalAlignment="Center"/>
```

## 常见任务

### 查找控件

在Avalonia中，可以使用FindControl方法来根据名称查找控件。FindControl方法是通过递归搜索视觉树来查找具有指定名称的控件。以下是根据名称查找控件的一般步骤：

首先，确保你的控件在XAML中具有一个唯一的Name属性。例如：

```xaml
<Button Name="myButton" Content="Click me"></Button>
```

在这个例子中，Button控件的Name属性被设置为`myButton`。

接下来，在你的代码中，使用FindControl方法来查找具有指定名称的控件。例如：

```c#
using Avalonia.Controls;

...

var myButton = this.FindControl<Button>("myButton");

if (myButton != null)

{

  // 找到了具有指定名称的按钮控件

  // 可以在这里对按钮进行操作或设置事件处理程序等

}
```

在这个例子中，`FindControl<Button>("myButton")`将根据名称`myButton`查找Button控件，并将其赋值给myButton变量。如果找到了具有指定名称的控件，myButton将不为空。

需要注意的是，FindControl方法是通过递归搜索视觉树来查找控件的，因此它从当前控件开始搜索，并向下搜索其子控件。如果要在整个视觉树中搜索控件，可以从窗口或容器控件开始调用FindControl方法。

使用FindControl方法，你可以根据名称获取对应的控件实例，并在代码中对其进行操作。

### UI线程

Avalonia UI 应用程序有一个主线程，用于处理 UI。当您有一个密集或长时间运行的进程时，您通常会选择在不同的线程上运行它。然后您可能会遇到想要更新主 UI 线程的情况（例如进度更新）。调度程序提供用于管理任何特定线程上的工作项的服务。在 Avalonia UI 中，您已经拥有处理 UI 线程的调度程序。当您需要从不同的线程更新 UI 时，您可以通过此调度程序访问它，如下所示：

```c#
Dispatcher.UIThread
```

您可以使用 `Post` 方法或 `InvokeAsync` 方法在 UI 线程上运行进程。

+ 当您只想开始一项作业，但不需要等待作业完成，也不需要结果时，请使用 `Post` ：这是“即发即忘”调度程序方法。
+ 当您需要等待结果并且可能想要接收结果时，请使用 `InvokeAsync` 。

上述两种方法都有一个调度程序优先级参数。您可以将其与 `DispatcherPriority` 枚举一起使用来指定应赋予给定作业的队列优先级。

> 有关 `DispatcherPriority` 枚举的可能值，请参见[此处](http://reference.avaloniaui.net/api/Avalonia.Threading/DispatcherPriority/)。

#### Post示例

在此示例中，文本块用于显示长时间运行的任务的结果，按钮用于开始工作。在此版本中，使用“即发即忘” `Post` 方法：

xaml

```xaml
<StackPanel Margin="20">    
  <Button x:Name="RunButton" Content="Run long running process" 
          Click="ButtonClickHandler" />
  <TextBlock x:Name="ResultText" Margin="10"/>
</StackPanel>
```

Task

```c#
using System.Threading.Tasks;
...
private async Task LongRunningTask()
{
    this.FindControl<Button>("RunButton").IsEnabled = false;
    this.FindControl<TextBlock>("ResultText").Text = "I'm working ...";
    await Task.Delay(5000);
    this.FindControl<TextBlock>("ResultText").Text = "Done";
    this.FindControl<Button>("RunButton").IsEnabled = true;
}
```

Post logic

```c#
private void ButtonClickHandler(object sender, RoutedEventArgs e)
{
    // Start the job and return immediately
    Dispatcher.UIThread.Post(() => LongRunningTask(), 
                                            DispatcherPriority.Background);
}
```

请注意，由于长时间运行的任务是在其自己的线程上执行，因此 UI 不会失去响应能力。

#### InvokeAsync例子

为了从长时间运行的任务中获取结果，XAML 是相同的，但此版本使用 `InvokeAsync` 方法：

xaml

```xaml
<StackPanel Margin="20">    
  <Button x:Name="RunButton" Content="Run long running process" 
          Click="ButtonClickHandler" />
  <TextBlock x:Name="ResultText" Margin="10"/>
```

Task

```c#
using System.Threading.Tasks;
...
private async Task<string> LongRunningTask()
{
    this.FindControl<Button>("RunButton").IsEnabled = false;
    this.FindControl<TextBlock>("ResultText").Text = "I'm working ...";
    await Task.Delay(5000);    
    return "Success";
}
```

InvokeAsync 

```c#
private async void ButtonClickHandler(object sender, RoutedEventArgs e)
{
    var result = await Dispatcher.UIThread.InvokeAsync(LongRunningTask, 
                                    DispatcherPriority.Background);
    //result returns here
    this.FindControl<TextBlock>("ResultText").Text = result;
    this.FindControl<Button>("RunButton").IsEnabled = true;
}
```



### 弹出对话框

在Avalonia中，可以使用Interaction来弹出对话框。Interaction是一种用于在视图模型中触发交互操作的机制。以下是使用Interaction来弹出对话框的一般步骤：

首先，在你的视图模型中创建一个Interaction对象，并定义一个命令来触发对话框的显示。例如：

```xaml
using Avalonia.Controls;

using Avalonia.Interactivity;

...

public class MyViewModel{
  public Interaction<string> ShowDialog { get*; } = new Interaction<string>();
  private void OnShowDialog(){
    ShowDialog.Raise("Hello, World!");
  }
}
```

在这个例子中，ShowDialog是一个Interaction<string>对象，用于传递对话框需要显示的消息。

接下来，在你的视图中，将Interaction对象与对应的命令进行绑定。这可以通过在XAML中使用EventToCommand绑定来实现。例如：

```xaml
<Button Content="Show Dialog"
 Command="{Binding ShowDialog}"
 CommandParameter="Hello, World!">
</Button>
```

在这个例子中，按钮的Command属性绑定到ShowDialog命令，并且CommandParameter属性设置为对话框需要显示的消息。

最后，在你的视图或其他适当的地方，订阅Interaction对象的Requested事件，并在事件处理程序中显示对话框。例如：

```c#
public class MyView : UserControl

{

  public MyView(){

    InitializeComponent();
     DataContextChanged += OnDataContextChanged;

  }

  private void OnDataContextChanged(object sender, EventArgs e)
  {
   if (DataContext is MyViewModel viewModel){
    viewModel.ShowDialog.Requested += ShowDialogRequested;
   }
  }

  private async void ShowDialogRequested(object sender, InteractionRequestedEventArgs<string> e){

   var message = e.Context;

  await MessageBox.Show(message, "Dialog");
   e.Callback?.Invoke();
  }

}
```



在这个例子中，ShowDialogRequested方法订阅了ShowDialog的Requested事件，并在事件处理程序中使用MessageBox来显示对话框。在对话框关闭后，通过调用`e.Callback?.Invoke()`来通知视图模型对话框已关闭。通过这种方式，你可以在视图模型中触发对话框的显示，并在视图中处理对话框的逻辑。

## 常见问题

### Linux

####  Default font family name can't be null or empty

需要添加相应的字体设置，我这里是统一设置为某个字体

```c#
class Program
{
    // Initialization code. Don't use any Avalonia, third-party APIs or any
    // SynchronizationContext-reliant code before AppMain is called: things aren't initialized
    // yet and stuff might break.
    [STAThread]
    public static void Main(string[] args) => BuildAvaloniaApp()
        .StartWithClassicDesktopLifetime(args);
    
    string GetDefaultFontFamily()
    {
        if (OperatingSystem.IsLinux())
        {
            return "<Linux Default Font Family Name Here>";
        }

        if (OperatingSystem.IsMacOS())
        {
            return "<macOS Default Font Family Name Here>";
        }

        return "<Windows Default Font Family Name Here>";
    }
    
    // 这里可以根据不同的操作系统进行设置，通过调用GetDefaultFontFamily()
   private  static FontManagerOptions _options = new(){DefaultFamilyName = "Menlo"};
   
    

// Avalonia configuration, don't remove; also used by visual designer.
    public static AppBuilder BuildAvaloniaApp()
        => AppBuilder.Configure<App>()
            .UsePlatformDetect()
            .WithInterFont()
            .LogToTrace()
            .With(_options);

}
```



## 参考资料

+ [Avalonia官方文档](https://docs.avaloniaui.net/docs/getting-started/)
+ [Avalonia Example](https://github.com/AvaloniaUI/Avalonia.Samples)
+ [Avalonia Community](https://github.com/AvaloniaCommunity)
+ [AvaloniaUtils](https://github.com/AvaloniaUtils)
+ https://dev.to/t/avalonia
+ https://github.com/quamotion/dotnet-packaging
+ [.net 跨平台桌面程序 avalonia：从项目创建到打包部署linux-64系统deepin 或 ubuntu。](https://www.cnblogs.com/Fengyinyong/p/13346642.html)
+ [Avalonia中用FluentAvalonia+DialogHost.Avalonia实现界面弹窗和对话框](https://www.raokun.top/archives/avalonia-zhong-yong-fluentavaloniadialoghostavalonia-shi-xian-jie-mian-dan-chuang-he-dui-hua-kuang)
