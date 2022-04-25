---
title: "WPF与虚拟键盘的那些事"
date: 2022-04-25
tags: ["wpf"]
draft: false
---

## 缘起

近期项目使用到相关技术，故整理文章一篇。

## 获取可用输入设备

软件的本质无非是输入和输出，那么WPF如何获取电脑是否有可用输入设备呢？查询了Google,在StackOverflow上找到一个提问，[原帖地址](https://stackoverflow.com/questions/19085931/how-to-make-wpf-input-control-show-virtual-keyboard-when-it-got-focus-in-touch-s)，代码如下：

```c#
KeyboardCapabilities keyboardCapabilities = new Windows.Devices.Input.KeyboardCapabilities();
return  keyboardCapabilities.KeyboardPresent != 0 ? true : false;
```

如果没有可用输入设备，那么就该虚拟键盘上场了。windows里面有两个虚拟键盘的程序，一个是`TabTip.exe`一个是`osk.exe`,可以直接调用进程，也可以使用 WPF的第三方组件https://github.com/maximcus/WPFTabTip 详细实现可以参考后面的链接。

## 平板模式

下面代码将当前系统的运行模式改为平板模式

```c#
public static readonly Guid CLSID_ImmersiveShell = new Guid("C2F03A33-21F5-47FA-B4BB-156362A2F239");
[ComImport()]
[Guid("4FDA780A-ACD2-41F7-B4F2-EBE674C9BF2A")]
[InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
public interface ITabletModeController
{
    int GetMode(ref int mode);
    int SetMode(int mode, int modeTrigger);
}
[ComImport]        
[Guid("6D5140C1-7436-11CE-8034-00AA006009FA")]
[InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
internal interface IServiceProvider
{
    [return: MarshalAs(UnmanagedType.IUnknown)]
    object QueryService(ref Guid service, ref Guid riid);
}
```

调用

```c#
var pSP = (IServiceProvider)Activator.CreateInstance(Type.GetTypeFromCLSID(CLSID_ImmersiveShell));
 var pTMC = (ITabletModeController)pSP.QueryService(typeof(ITabletModeController).GUID, typeof(ITabletModeController).GUID);
 if (pTMC != null)
 {
     // 0 = Desktop, 1 = Tablet
     int nMode = 0;
     int nRet = pTMC.GetMode(ref nMode);
     nRet = pTMC.SetMode(nMode==0?1:0, 4);
 }
```

系统运行模式检测

```c#
[DllImport("user32.dll")]
static extern int GetSystemMetrics(SystemMetric smIndex);
//http://www.pinvoke.net/default.aspx/Enums/SystemMetric.html 
public enum SystemMetric
{
        SM_CXSCREEN = 0,  // 0x00
        SM_CYSCREEN = 1,  // 0x01
        SM_CXVSCROLL = 2,  // 0x02
        SM_CYHSCROLL = 3,  // 0x03
        SM_CYCAPTION = 4,  // 0x04
        SM_CXBORDER = 5,  // 0x05
        SM_CYBORDER = 6,  // 0x06
        SM_CXDLGFRAME = 7,  // 0x07
        SM_CXFIXEDFRAME = 7,  // 0x07
        SM_CYDLGFRAME = 8,  // 0x08
        SM_CYFIXEDFRAME = 8,  // 0x08
        SM_CYVTHUMB = 9,  // 0x09
        SM_CXHTHUMB = 10, // 0x0A
        SM_CXICON = 11, // 0x0B
        SM_CYICON = 12, // 0x0C
        SM_CXCURSOR = 13, // 0x0D
        SM_CYCURSOR = 14, // 0x0E
        SM_CYMENU = 15, // 0x0F
        SM_CXFULLSCREEN = 16, // 0x10
        SM_CYFULLSCREEN = 17, // 0x11
        SM_CYKANJIWINDOW = 18, // 0x12
        SM_MOUSEPRESENT = 19, // 0x13
        SM_CYVSCROLL = 20, // 0x14
        SM_CXHSCROLL = 21, // 0x15
        SM_DEBUG = 22, // 0x16
        SM_SWAPBUTTON = 23, // 0x17
        SM_CXMIN = 28, // 0x1C
        SM_CYMIN = 29, // 0x1D
        SM_CXSIZE = 30, // 0x1E
        SM_CYSIZE = 31, // 0x1F
        SM_CXSIZEFRAME = 32, // 0x20
        SM_CXFRAME = 32, // 0x20
        SM_CYSIZEFRAME = 33, // 0x21
        SM_CYFRAME = 33, // 0x21
        SM_CXMINTRACK = 34, // 0x22
        SM_CYMINTRACK = 35, // 0x23
        SM_CXDOUBLECLK = 36, // 0x24
        SM_CYDOUBLECLK = 37, // 0x25
        SM_CXICONSPACING = 38, // 0x26
        SM_CYICONSPACING = 39, // 0x27
        SM_MENUDROPALIGNMENT = 40, // 0x28
        SM_PENWINDOWS = 41, // 0x29
        SM_DBCSENABLED = 42, // 0x2A
        SM_CMOUSEBUTTONS = 43, // 0x2B
        SM_SECURE = 44, // 0x2C
        SM_CXEDGE = 45, // 0x2D
        SM_CYEDGE = 46, // 0x2E
        SM_CXMINSPACING = 47, // 0x2F
        SM_CYMINSPACING = 48, // 0x30
        SM_CXSMICON = 49, // 0x31
        SM_CYSMICON = 50, // 0x32
        SM_CYSMCAPTION = 51, // 0x33
        SM_CXSMSIZE = 52, // 0x34
        SM_CYSMSIZE = 53, // 0x35
        SM_CXMENUSIZE = 54, // 0x36
        SM_CYMENUSIZE = 55, // 0x37
        SM_ARRANGE = 56, // 0x38
        SM_CXMINIMIZED = 57, // 0x39
        SM_CYMINIMIZED = 58, // 0x3A
        SM_CXMAXTRACK = 59, // 0x3B
        SM_CYMAXTRACK = 60, // 0x3C
        SM_CXMAXIMIZED = 61, // 0x3D
        SM_CYMAXIMIZED = 62, // 0x3E
        SM_NETWORK = 63, // 0x3F
        SM_CLEANBOOT = 67, // 0x43
        SM_CXDRAG = 68, // 0x44
        SM_CYDRAG = 69, // 0x45
        SM_SHOWSOUNDS = 70, // 0x46
        SM_CXMENUCHECK = 71, // 0x47
        SM_CYMENUCHECK = 72, // 0x48
        SM_SLOWMACHINE = 73, // 0x49
        SM_MIDEASTENABLED = 74, // 0x4A
        SM_MOUSEWHEELPRESENT = 75, // 0x4B
        SM_XVIRTUALSCREEN = 76, // 0x4C
        SM_YVIRTUALSCREEN = 77, // 0x4D
        SM_CXVIRTUALSCREEN = 78, // 0x4E
        SM_CYVIRTUALSCREEN = 79, // 0x4F
        SM_CMONITORS = 80, // 0x50
        SM_SAMEDISPLAYFORMAT = 81, // 0x51
        SM_IMMENABLED = 82, // 0x52
        SM_CXFOCUSBORDER = 83, // 0x53
        SM_CYFOCUSBORDER = 84, // 0x54
        SM_TABLETPC = 86, // 0x56
        SM_MEDIACENTER = 87, // 0x57
        SM_STARTER = 88, // 0x58
        SM_SERVERR2 = 89, // 0x59
        SM_MOUSEHORIZONTALWHEELPRESENT = 91, // 0x5B
        SM_CXPADDEDBORDER = 92, // 0x5C
        SM_DIGITIZER = 94, // 0x5E
        SM_MAXIMUMTOUCHES = 95, // 0x5F

        SM_REMOTESESSION = 0x1000, // 0x1000
        SM_SHUTTINGDOWN = 0x2000, // 0x2000
        SM_REMOTECONTROL = 0x2001, // 0x2001

        SM_CONVERTABLESLATEMODE = 0x2003, 
        SM_SYSTEMDOCKED = 0x2004,
}
// should handle in event SystemEvents.UserPreferenceChanging which e.Category == UserPreferenceCategory.General
if (GetSystemMetrics(SystemMetric.SM_CONVERTABLESLATEMODE) == 0)
{
    Debug.WriteLine("detected slate mode");   
}
else if (GetSystemMetrics(SystemMetric.SM_SYSTEMDOCKED) == 0)
{
    Debug.WriteLine("detected docked mode");
}
```

修改键盘布局

[MSDN](https://docs.microsoft.com/en-gb/windows/win32/api/winuser/nf-winuser-loadkeyboardlayouta?redirectedfrom=MSDN) LoadKeyboardLayout

```c#
[DllImport("user32.dll")]
static extern IntPtr LoadKeyboardLayout(string pwszKLID, uint Flags);
```

调用例子

```c#
LoadKeyboardLayout("00010409", 1)
```



## 参考

+ https://blog.mzikmund.com/2015/09/how-to-show-touch-keyboard-on-touch-interaction-with-wpf-textboxes/

+ https://www.autohotkey.com/boards/viewtopic.php?t=15619



