---
title: "C# dllimport 备忘录"
date: 2022-10-09
tags: ["csharp", "Pinvoke"]
draft: false
---

## dllImport的入口点问题

通过[Dependencies](https://github.com/lucasg/Dependencies)查询Dll对应方法的EntryPoint

![image-20221009163930252](https://assets.czyt.tech/img/dependences-entry-points.png)

然后在dllimport的attribute中显式申明EntryPoint

```csharp
[DllImport("demo.dll", SetLastError = true,EntryPoint ="??0DemoManager@EcgParser@Gfeit@@AEAA@XZ")]
        public static extern IntPtr DemoManager();
```



## 导入类方法的问题