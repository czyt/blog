---
title: ".NET6 从JSON获取配置"
date: 2022-09-06
tags: [".net", "json"]
draft: false
---
## 环境准备
### nuget包
+ Microsoft.Extensions.Configuration
+ Microsoft.Extensions.Configuration.Binder 
+ Serilog.Sinks.File.Archive （日志文件rotation功能）
+ Microsoft.Extensions.Configuration.Json (当需要从Json文件添加记录时，安装此nuget包)
+ Microsoft.Extensions.Configuration.EnvironmentVariables (当需要从环境变量添加记录时，安装此nuget包)
### C#开发环境
+ visual studio 2019 +
+ visual Code
## 示例代码
```c#
// See https://aka.ms/new-console-template for more information

using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Configuration.Json;

Console.WriteLine("Hello, World!");
ConfigurationBuilder configurationBuilder = new ConfigurationBuilder();
IConfiguration c = configurationBuilder.AddJsonFile("appsettings.json").AddEnvironmentVariables().Build();
var k = c.GetRequiredSection("Settings").Get<Settings>().KeyOne;
var n = 1;

public class NestedSettings
{
    public string Message { get; set; } = null!;
}
public class Settings
{
    public int KeyOne { get; set; }
    public bool KeyTwo { get; set; }
    public NestedSettings KeyThree { get; set; } = null!;
}

```
JSON 文件 (appsettings.json.**ps**:配置文件属性建议按下面属性设置)

![image-20220906115439298](https://assets.czyt.tech/img/appsetting-file-prop.png)

```json
{
    "Settings": {
        "KeyOne": 1,
        "KeyTwo": true,
        "KeyThree": {
            "Message": "Oh, that's nice..."
        }
    }
}
```
## 常见问题
### 如何自定义配置项目的Key
使用` [ConfigurationKeyName]`属性进行设置，如下面的配置：
```c#
public class ApiConfig 
{
    [ConfigurationKeyName("endpoint")]
    public string Endpoint { get; set; }
}    
```
### 配置热重载
配置热重载可以使用`ChangeToken.OnChange`来实现，参考[微软官方文档](https://docs.microsoft.com/en-us/aspnet/core/fundamentals/change-tokens?view=aspnetcore-6.0) 下面是一个例子：

```c#
// AddJsonFile("appsettings.json", false, true) 添加json时候设置重载(reloadOnChange)
ChangeToken.OnChange(
    () => GetReloadToken(), // listener to token change
    () =>
    {
        Thread.Sleep(250);
        // load config logic
        Load();
    });
```



## 参考

+ [stackoverflow](https://stackoverflow.com/questions/71954271/how-can-i-read-the-appsettings-json-in-a-net-6-console-application)
