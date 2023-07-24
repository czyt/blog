---
title: "使用C#切换专注模式"
date: 2023-07-24
tags: ["csharp", "pinvoke", "windows"]
draft: false
---
## 缘起

最近需要以编程方式调用windows api实现专注模式的切换，但是Google一圈，没有现成代码。找到的相关帖子要么是cpp的要么是rust的，而且是undocument的Windows api。

## Csharp调用

以下是完整代码

```csharp
public static class FocusAssistToogle
{
    private const string NtdllDlDll = "ntdll.dll";
    private const uint DataBufferSize = 4;
    private static readonly byte[] DisableDataBuf = { 0x00, 0x00, 0x00, 0x00 };
    private static readonly byte[] EnableDataBuf = { 0x02, 0x00, 0x00, 0x00 };

    [DllImport(NtdllDlDll, SetLastError = true)]
    private static extern int ZwUpdateWnfStateData(
        ref WnfSWnfStateName sWnfStateName,
        byte[] buffer,
        uint bufferSize,
        IntPtr previousStateData,
        IntPtr currentStateData,
        uint previousStateDataSize,
        uint currentStateDataSize);

    [StructLayout(LayoutKind.Sequential)]
    private struct WnfSWnfStateName
    {
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 2)]
        public uint[] Data;
    }

    private static WnfSWnfStateName _wnfSWnfShelQuietMomentShellModeChanged = new WnfSWnfStateName
    {
        Data = new uint[] { 0xa3bf5075, 0xd83063e }
    };


    public static bool EnableFocusMode()
    {
        int result = ZwUpdateWnfStateData(ref 			_wnfSWnfShelQuietMomentShellModeChanged,
            EnableDataBuf,
            DataBufferSize,
            IntPtr.Zero,
            IntPtr.Zero,
            0,
            0);
        return result == 0;
    }

    public static bool DisableFocusMode()
    {
        int result = ZwUpdateWnfStateData(ref _wnfSWnfShelQuietMomentShellModeChanged,
            DisableDataBuf,
            DataBufferSize,
            IntPtr.Zero,
            IntPtr.Zero,
            0,
            0);
        return result == 0;
    }
}
```

## 参考链接

+ https://stackoverflow.com/questions/55477041/toggling-focus-assist-mode-in-win-10-programmatically
