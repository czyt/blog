---
title: "我和AI讨论的一些C#话题"
date: 2022-03-24
tags: ["c#", "ai"]
draft: false
---
 很久没有用C#，最近需要使用。下面是跟AI问的一些C#的问题，未作整理。
## 数据类型
### Span
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

## WPF

