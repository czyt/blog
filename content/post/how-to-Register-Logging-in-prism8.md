---
title: "WPF Prism 8如何注册Logging"
date: 2022-03-08
tags: ["prism", "WPF", ".net", "Log"]
draft: false
---

## Nuget包

### 基础包

+ [Microsoft Logging Abstractions](https://www.nuget.org/packages/Microsoft.Extensions.Logging.Abstractions/)
+  [Microsoft Extensions DependencyInjection](https://www.nuget.org/packages/Microsoft.Extensions.DependencyInjection)

### 可选日志包
可以按实际需求进行选择，如`NLog`等,我们这里采用的是 `Serilog `这个Nuget包[Serilog Extensions Logging](https://www.nuget.org/packages/Serilog.Extensions.Logging)

根据日志输出的目标不同，可以选择不同的扩展方法包

| 目标   |      包名      |  说明 |
|--------|:--------------:|------:|
| 文件|[Serilog.Sinks.File](https://www.nuget.org/packages/serilog.sinks.file/)|WiteTo可以使用File方法[详细说明](https://github.com/serilog/serilog-sinks-file)
|命令行|[Serilog.Sinks.Console](https://www.nuget.org/packages/Serilog.Sinks.Console/4.0.2-dev-00890)|
|调试输出|[Serilog.Sinks.Debug](https://www.nuget.org/packages/Serilog.Sinks.Debug/)|WiteTo可以使用Debug方法

其他扩展，请搜索 [点击](https://www.nuget.org/packages?q=Serilog.Sinks)

## 日志容器注册
我们使用的是 `DryIoc `进行注册，需要安装Nuget包 [DryIoc.Microsoft.DependencyInjection](https://www.nuget.org/packages/DryIoc.Microsoft.DependencyInjection)
具体代码如下：

```csharp
protected override IContainerExtension CreateContainerExtension()
{
    var serviceCollection = new ServiceCollection();
    serviceCollection.AddLogging(loggingBuilder =>
        loggingBuilder.AddSerilog(dispose: true));

    return new DryIocContainerExtension(new Container(CreateContainerRules())
        .WithDependencyInjectionAdapter(serviceCollection));
}

```


如果是Unity 则需要安装包 [Unity.Microsoft.DependencyInjection](https://www.nuget.org/packages/Unity.Microsoft.DependencyInjection) 具体代码如下：

```csharp
protected override IContainerExtension CreateContainerExtension()
{
    var serviceCollection = new ServiceCollection();
    serviceCollection.AddLogging(loggingBuilder =>
        loggingBuilder.AddSerilog(dispose: true));

    var container = new UnityContainer();
    container.BuildServiceProvider(serviceCollection);

    return new UnityContainerExtension(container);
}
```
我们对于不同的日志插件框架都是在 `AddLogging`这个地方进行添加的，需要注意的是我们不仅需要在`ServiceCollection `中注册，还需要在容器对象中注册。注意区分 `DryIoc`中的`WithDependencyInjectionAdapter `与`Unity`中的`BuildServiceProvider`使用差异。

## 日志配置

日志配置在Prism入口程序的`CreateShell`方法中

```csharp
    protected override Window CreateShell()
    {
        Log.Logger = new LoggerConfiguration()
        .Enrich.FromLogContext()
        .WriteTo.File("App.log")
        .CreateLogger();
        return Container.Resolve<MainWindow>();
    }
```

## 日志使用

注册`ILogger`接口使用日志

```csharp
public class MyService : IMyService
{
    public MyService(ILogger<MyService> logger)
    {
        logger.LogInformation("Hello World from your logger!");
    }
}
```

## 参考连接
+ [How To Register Logging in a Prism 8 WPF App](https://www.andicode.com/prism/wpf/logging/2021/05/21/Logging-In-Prism.html)