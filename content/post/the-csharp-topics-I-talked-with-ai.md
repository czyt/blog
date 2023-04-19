---
title: "我和AI讨论的一些C#话题"
date: 2023-03-24
tags: ["csharp", "ai"]
draft: false
---
 很久没有用C#，最近需要使用。下面是跟AI问的一些C#的问题，未作整理。
## 基础
### Span类型
> c# Span的应用场景及具体例子

Span是一种新的引用类型，它允许存储和操作连续的内存块。它特别适用于那些需要高效处理内存块的应用场景，例如字符串处理、IO操作和序列化/反序列化。

下面是一些具体的例子：

1. 字符串处理：Span可以用于快速地操作字符串，例如从字符串中截取子串、替换子串、查找子串等。下面是一个例子：

```
string str = "hello world";
Span<char> span = str.AsSpan(6, 5); // 从第6个字符开始，截取长度为5的子串
```

2. IO操作：Span可以用于将IO操作映射到内存中，以提高性能。下面是一个例子：

```
using (FileStream stream = File.OpenRead("file.txt"))
{
    byte[] buffer = new byte[1024 * 1024];
    while (stream.Read(buffer) > 0)
    {
        Span<byte> span = buffer.AsSpan(); // 将字节数组映射为Span
        // 处理Span
    }
}
```

3. 序列化/反序列化：Span可以用于快速地序列化和反序列化数据，尤其是在网络传输等场景中。下面是一个例子：

```
public static void Serialize<T>(T value, Span<byte> buffer) where T : struct
{
    unsafe
    {
        fixed (byte* ptr = buffer)
        {
            *(T*)ptr = value; // 将值拷贝到Span中
        }
    }
}

public static T Deserialize<T>(Span<byte> buffer) where T : struct
{
    unsafe
    {
        fixed (byte* ptr = buffer)
        {
            return *(T*)ptr; // 从Span中读取值
        }
    }
}
```
### 异步
> c#  SynchronizationContext的使用场景及例子

SynchronizationContext是一个抽象类，定义了一种同步上下文的机制，允许代码在指定的线程中执行。通常情况下，SynchronizationContext的实现会将执行代码的操作封装成一个任务，并将该任务分配到与指定的上下文相关的线程中执行。

SynchronizationContext通常用于以下情况：

1. Windows Forms应用程序中的UI线程处理
在Windows Forms应用程序中，UI线程负责处理用户界面操作。如果其他线程尝试在UI线程之外更新用户界面，则可能会引发异常。这时
，可以使用WindowsFormsSynchronizationContext类，该类可以将执行代码封装到UI线程上下文中，并在其相关的线程上执行。

例如：

```
textBox1.Invoke(new Action(() => {
    textBox1.Text = "Hello World";
}));
```

2. ASP.NET Web应用程序中的请求处理
在ASP.NET Web应用程序中，每个请求都在单独的线程上执行，处理请求时可以使用AspNetSynchronizationContext类将代码封装到请求
线程上下文中，并在其相关的线程上执行。

例如：

```
var syncContext = HttpContext.Current != null ?
    HttpContext.Current.SyncronizationContext : null;
syncContext?.Post(() => {
    Label1.Text = "Hello World";
});
```

3. 多线程编程中的线程同步
在多线程编程中，不同线程间的通信和同步常常是一个复杂的问题。SynchronizationContext可以帮助实现线程间的同步。

例如：

```
var uiContext = SynchronizationContext.Current;
var t = new Thread(() => {
    // Do some work...
    uiContext?.Post(() => {
        // Update the UI on the main thread
        Label1.Text = "Hello World";
    });
});
t.Start();
```

在以上例子中，新的线程将执行一些工作，然后使用当前同步上下文将更新UI线程中的标签。由SynchronizationContext处理线程间的同步。

> c# CancellationToken的应用场景及具体的例子

CancellationToken是在多线程编程中非常有用的一个类，它能够实现线程的取消操作，当程序需要取消某个任务时，只需要让该任务检
查CancellationToken的状态即可。

应用场景：
1. 取消一个长时间运行的线程或任务：例如下载一个大文件，在下载过程中用户可能取消下载操作，这时就可以使用CancellationToken进行取消操作，以便程序能够正确地退出或继续执行其他任务。
2. 取消一个正在等待的线程或任务：例如等待某个事件的发生，在某些情况下可能需要取消正在等待的操作，这时就可以使用CancellationToken进行取消操作，以便程序继续执行其他任务。
3. 取消多个并行运行的任务：例如同时运行多个任务，某些任务完成后可能需要取消其他任务的执行，这时就可以使用CancellationToken进行取消操作。

具体例子：
1. 在使用Task.Run方法时，可以传入CancellationToken，如下所示：

```
CancellationTokenSource cts = new CancellationTokenSource();
CancellationToken token = cts.Token;

Task.Run(() =>
{
    while (true)
    {
        if (token.IsCancellationRequested)
        {
            break;
        }
        // do something
    }
}, token);
```

2. 在使用async/await时，可以使用CancellationToken来取消异步操作，如下所示：

```
CancellationTokenSource cts = new CancellationTokenSource();
CancellationToken token = cts.Token;

async Task DownloadFileAsync(string url, CancellationToken token)
{
    using (var client = new HttpClient())
    using (var response = await client.GetAsync(url, token))
    {
        var content = await response.Content.ReadAsStringAsync();
        // do something
    }
}

await DownloadFileAsync(url, token);
```

3. 在使用Parallel.ForEach方法时，可以使用CancellationToken来取消并行操作，如下所示：

```
CancellationTokenSource cts = new CancellationTokenSource();
CancellationToken token = cts.Token;

Parallel.ForEach(list, new ParallelOptions { CancellationToken = token }, item =>
{
    // do something
});
```

## 其他

### 网络

#### 在多网卡情况下，如何获取上网卡IP
```csharp
var networkInterfaces = NetworkInterface.GetAllNetworkInterfaces();

// 获取当前活动网卡
var activeInterface = networkInterfaces.FirstOrDefault(n =>
n.OperationalStatus == OperationalStatus.Up &&
(
    n.NetworkInterfaceType == NetworkInterfaceType.Wireless80211 ||
    n.NetworkInterfaceType == NetworkInterfaceType.Ethernet)
);

// 获取活动网卡属性
var ipProperties = activeInterface.GetIPProperties();

// 获取活动网卡的Ip
Console.WriteLine(ipProperties.UnicastAddresses.FirstOrDefault(x => x.Address.AddressFamily == AddressFamily.InterNetwork)?.Address);
```

### 系统

#### c#检测系统是否空闲

在 C# 中，可以使用 `System.Windows.Forms.Application.Idle` 事件来检测系统空闲状态。该事件将在消息队列中没有其它的消息时触发，例如鼠标和键盘输入等。可以在 `Application.Idle` 事件处理程序中记录最近一次用户输入的时间，并通过比较当前时间与最近一次输入时间的差值来判断当前系统是否空闲。以下是一个示例代码：

```csharp
using System;
using System.Windows.Forms;
using System.Diagnostics;

public static void CheckIfSystemIsIdle()
{
    TimeSpan idleThreshold = new TimeSpan(0, 0, 5);  // 系统空闲阈值为 5 秒钟
    DateTime lastInputTime = DateTime.Now;

    Application.Idle += (sender, e) =>
    {
        // 计算距离上次用户输入的时间
        TimeSpan idleTime = DateTime.Now - lastInputTime;

        // 如果系统空闲时间超过指定的阈值，则做相应的处理
        if (idleTime >= idleThreshold)
        {
            Console.WriteLine("System is idle.");
            // 这里可以编写相应的处理逻辑
        }
    };

    // 在初始化时记录当前时间作为最近一次用户输入的时间
    lastInputTime = DateTime.Now - TimeSpan.FromMilliseconds(GetLastInputTime());
}

// 获取最近一次输入的时间（单位：毫秒）
public static uint GetLastInputTime()
{
    uint idleTime = 0;
    NativeMethods.LASTINPUTINFO lastInputInfo = new NativeMethods.LASTINPUTINFO();
    lastInputInfo.cbSize = (uint)System.Runtime.InteropServices.Marshal.SizeOf(lastInputInfo);
    lastInputInfo.dwTime = 0;

    if (NativeMethods.GetLastInputInfo(ref lastInputInfo))
    {
        uint lastInputTime = lastInputInfo.dwTime;
        idleTime = (uint)Environment.TickCount - lastInputTime;
    }

    return idleTime;
}

internal class NativeMethods
{
    [System.Runtime.InteropServices.DllImport("user32.dll")]
    public static extern bool GetLastInputInfo(ref LASTINPUTINFO plii);

    public struct LASTINPUTINFO
    {
        public uint cbSize;
        public uint dwTime;
    }
}
```

该示例代码定义了一个系统空闲阈值变量 `idleThreshold`，然后在 `Application.Idle` 事件处理程序中计算距离上次用户输入的时间。如果系统空闲时间超过指定的阈值，则触发相应的处理逻辑，例如在控制台打印一条消息。同时，为了获取最近一次用户输入的时间，示例代码中使用了 `GetLastInputTime()` 函数来获取最近一次输入时间，该函数使用了 Win32 API `GetLastInputInfo()`。

