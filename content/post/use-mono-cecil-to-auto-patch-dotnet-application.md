---
title: "使用Mono.Cecil自动补丁.net程序"
date: 2024-04-04
tags: ["dotnet"]
draft: false
---
坚果云是我常用的一个工具，但是我一般喜欢使用绿色版，不喜欢程序到处写文件，也不喜欢重装以后还要各种登录。所以要折腾“绿色版”来使用。
## 手动IL处理

一般手动处理坚果云的个人用户资料目录。需要使用dnspyEx，然后修改`NutstoreLib.dll`中的`Utils.DirectoryUtils`下的`APPDATA_NUTSTORE_DIR`,下面是我的一个手动IL修改列表：
```
0    0000    call    string NutstoreLib.Utils.DirectoryUtils::get_NUTSTORE_INSTALL_DIR()
1    0005    newobj    instance void [mscorlib]System.IO.DirectoryInfo::.ctor(string)
2    000A    call    instance class [mscorlib]System.IO.DirectoryInfo [mscorlib]System.IO.DirectoryInfo::get_Parent()
3    000F    callvirt    instance string [mscorlib]System.IO.FileSystemInfo::get_FullName()
4    0014    ldstr    "UserData"
5    0019    call    string [Pri.LongPath]Pri.LongPath.Path::Combine(string, string)
6    001E    ret
```

## 自动IL处理

借助Mono.Cecil我们可以实现上面的功能，自动进行dll的patch修改。

> 注：因为我不喜欢调用太多的库，所以`Pri.LongPath.Path::Combine(string, string)`我改为了系统的库

完整代码如下：

```c#
using System.Linq;
using Mono.Cecil;
using Mono.Cecil.Cil;

namespace NutstoreAutoPatch
{
    internal class Program
    {
        public static void Main(string[] args)
        {
           const string nutstoreLib = "NutstoreLib.dll"; 
           const string directoryutils = "NutstoreLib.Utils.DirectoryUtils"; 
           const string appdataNutstoreDir = "get_APPDATA_NUTSTORE_DIR"; 
           
           
            // Read the assembly
            var assemblyDefinition = AssemblyDefinition.ReadAssembly(nutstoreLib);
            var directoryUtil = assemblyDefinition.MainModule.Types.First(t => t.FullName == directoryutils);
            var appdataDirMethod = directoryUtil.Methods.First(m => m.Name == appdataNutstoreDir);
            
            // 清除当前指令
            appdataDirMethod.Body.Instructions.Clear();

            // 获取IL处理器
            var ilProcessor = appdataDirMethod.Body.GetILProcessor();

            // 构造调用NutstoreLib.Utils.DirectoryUtils.get_NUTSTORE_INSTALL_DIR的指令
            var getInstallDirMethod = appdataDirMethod.Module.ImportReference(
                appdataDirMethod.DeclaringType.Module.Types
                    .First(t => t.Name == "DirectoryUtils" && t.Namespace == "NutstoreLib.Utils")
                    .Methods.First(m => m.Name == "get_NUTSTORE_INSTALL_DIR")
            );
            ilProcessor.Append(ilProcessor.Create(OpCodes.Call, getInstallDirMethod));

            // 构造调用System.IO.DirectoryInfo构造函数的指令
            var directoryInfoConstructor = appdataDirMethod.Module.ImportReference(
                typeof(System.IO.DirectoryInfo).GetConstructor(new[] { typeof(string) })
            );
            ilProcessor.Append(ilProcessor.Create(OpCodes.Newobj, directoryInfoConstructor));

            // 构造获取DirectoryInfo.Parent属性的调用指令
            var getParentMethod = appdataDirMethod.Module.ImportReference(
                typeof(System.IO.DirectoryInfo).GetProperty("Parent").GetGetMethod()
            );
            ilProcessor.Append(ilProcessor.Create(OpCodes.Call, getParentMethod));

            // 构造调用System.IO.FileSystemInfo.FullName属性的指令
            var getFullNameMethod = appdataDirMethod.Module.ImportReference(
                typeof(System.IO.FileSystemInfo).GetProperty("FullName").GetGetMethod()
            );
            ilProcessor.Append(ilProcessor.Create(OpCodes.Callvirt, getFullNameMethod));

            // 加载字符串"UserData"
            ilProcessor.Append(ilProcessor.Create(OpCodes.Ldstr, "UserData"));

            // 构造调用Pri.LongPath.Path.Combine的指令
            var pathCombineMethod = appdataDirMethod.Module.ImportReference(
                    typeof(System.IO.Path).GetMethod("Combine", new[] { typeof(string), typeof(string) })
                );
            ilProcessor.Append(ilProcessor.Create(OpCodes.Call, pathCombineMethod));

          // 返回指令
            ilProcessor.Append(ilProcessor.Create(OpCodes.Ret));

            // Write the modified assembly
            assemblyDefinition.Write("NutstoreLib_patched.dll");
        }
    }
}
```

程序编译后，将最新的NutstoreLib.dll拷贝进来，执行下，再使用NutstoreLib_patched.dll替换原来安装目录的NutstoreLib.dll即可。
