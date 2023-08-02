---
title: "使用C#以编程方式切换Windows专注模式"
date: 2023-07-24
tags: ["csharp", "pinvoke", "windows"]
draft: false
---
## 缘起

最近需要以编程方式调用windows api实现windows10专注模式的切换，但是Google一圈，没有现成代码。找到的相关帖子要么是cpp的要么是rust的，而且是undocument的Windows api。

## Csharp调用

以下是完整代码

```csharp
public static class FocusAssistToogle
{
    private const string NtdllDlDll = "ntdll.dll";
    private const uint DataBufferSize = 4;
    private static readonly byte[] DisableDataBuf = { 0x00, 0x00, 0x00, 0x00 };
    // 01仅优先通知 02 仅限闹钟 
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
调用时，最好先调用`DisableFoucusMode`方法，再调用`EnableFocusMode`,参考StackOverflow上的说明

> if one attempts to use this to enable focus mode, I recommend first disabling focus mode (pass `new byte[] {0x00, 0x00, 0x00, 0x00}` instead). Then, after a few milliseconds, one can safely enable focus mode.

ps:如果需要禁用Windows通知中心，不显示通知，可以考虑使用下面这种写入注册表的方式。

```csharp
void Main()
{
    // 调用
	EnableAllNotifications();
}

private static void SetValue(RegistryHive hive, string keyPath, string valueName, object value)
{
	try
	{
		RegistryKey key;
		if (hive == RegistryHive.CurrentUser)
		{
			key = Registry.CurrentUser.OpenSubKey(keyPath, true);
			if (key == null)
			{
				key = Registry.CurrentUser.CreateSubKey(keyPath);
			}
		}
		else if (hive == RegistryHive.LocalMachine)
		{
			key = Registry.LocalMachine.OpenSubKey(keyPath, true);
			if (key == null)
			{
				key = Registry.LocalMachine.CreateSubKey(keyPath);
			}
		}
		else
		{
			throw new ArgumentException("Invalid registry hive specified.");
		}
		key.SetValue(valueName, value);
		key.Close();
	}
	catch (Exception ex)
	{
		Console.WriteLine($"Failed to set value in registry: {ex.Message}");
	}
}
private static void DeleteValue(RegistryHive hive, string keyPath, string valueName)
{
	try
	{
		RegistryKey key;
		if (hive == RegistryHive.CurrentUser)
		{
			key = Registry.CurrentUser.OpenSubKey(keyPath, true);
		}
		else if (hive == RegistryHive.LocalMachine)
		{
			key = Registry.LocalMachine.OpenSubKey(keyPath, true);
		}
		else
		{
			throw new ArgumentException("Invalid registry hive specified.");
		}
		if (key != null)
		{
			key.DeleteValue(valueName, false);
			key.Close();
		}
	}
	catch (Exception ex)
	{
		Console.WriteLine($"Failed to delete value from registry: {ex.Message}");
	}
}
public static void EnableAllNotifications()
{
	SetValue(RegistryHive.CurrentUser, @"Software\Microsoft\Windows\CurrentVersion\Policies\Explorer", "TaskbarNoNotification", 0);
	SetValue(RegistryHive.CurrentUser, @"Software\Policies\Microsoft\Windows\CurrentVersion\PushNotifications", "NoToastApplicationNotification", 0);
	SetValue(RegistryHive.CurrentUser, @"Software\Policies\Microsoft\Windows\Explorer", "DisableNotificationCenter", 0);
	SetValue(RegistryHive.LocalMachine, @"Software\Microsoft\WcmSvc\wifinetworkmanager", "WiFiSenseCredShared",1);
	SetValue(RegistryHive.LocalMachine, @"Software\Microsoft\WcmSvc\wifinetworkmanager", "WiFiSenseOpen", 1);
	SetValue(RegistryHive.CurrentUser, @"Software\Microsoft\Windows\CurrentVersion\Notifications\Settings", "NOC_GLOBAL_SETTING_TOASTS_ENABLED", 1);
}
public static void DisableAllNotifications()
{
    DeleteValue(RegistryHive.LocalMachine, @"SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer", "TaskbarNoNotification");
    DeleteValue(RegistryHive.CurrentUser, @"Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced", "EnableBalloonTips");
    DeleteValue(RegistryHive.LocalMachine, @"SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced", "EnableBalloonTips");
    SetValue(RegistryHive.CurrentUser, @"Software\Microsoft\Windows\CurrentVersion\Policies\Explorer", "TaskbarNoNotification", 1);
    SetValue(RegistryHive.CurrentUser, @"Software\Policies\Microsoft\Windows\CurrentVersion\PushNotifications", "NoToastApplicationNotification", 1);
    SetValue(RegistryHive.CurrentUser, @"Software\Policies\Microsoft\Windows\Explorer", "DisableNotificationCenter", 1);
    SetValue(RegistryHive.LocalMachine, @"Software\Microsoft\WcmSvc\wifinetworkmanager", "WiFiSenseCredShared", 0);
    SetValue(RegistryHive.LocalMachine, @"Software\Microsoft\WcmSvc\wifinetworkmanager", "WiFiSenseOpen", 0);
    SetValue(RegistryHive.CurrentUser, @"Software\Microsoft\Windows\CurrentVersion\Notifications\Settings", "NOC_GLOBAL_SETTING_TOASTS_ENABLED", 0);

}
```
## 参考链接

+ https://stackoverflow.com/questions/55477041/toggling-focus-assist-mode-in-win-10-programmatically
+ [rust实现](https://github.com/stefnotch/dnd/blob/42b5fc62429559dff753a02d5c51fbbb2e0a69cb/src/focus_mode.rs)
