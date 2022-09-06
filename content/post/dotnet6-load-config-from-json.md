---
title: ".NET6 从json获取配置"
date: 2022-09-06
tags: ["golang", "ebpf"]
draft: false
---
## 环境准备
### nuget包
+ Microsoft.Extensions.Configuration
+ Microsoft.Extensions.Configuration.Binder 
+ Microsoft.Extensions.Configuration.Json (当需要从Json文件添加记录时，安装此nuget包)
+ Microsoft.Extensions.Configuration.EnvironmentVariables (当需要从环境变量添加记录时，安装此nuget包)
### C#开发环境
+ visual studio 2019 +
+ visual Code
## 示例代码
```csharp
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

## 参考

+ [stackoverflow](https://stackoverflow.com/questions/71954271/how-can-i-read-the-appsettings-json-in-a-net-6-console-application)
