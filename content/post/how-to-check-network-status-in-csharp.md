---
title: "如何使用C#检查网络连接"
date: 2023-08-31
tags: ["csharp", "network"]
draft: false
---

## 调用Windows API

在C#中可以通过Pinvoke调用windows API方式来进行网络连接的检查：

```c#
[DllImport("wininet.dll", SetLastError=true)]
extern static bool InternetGetConnectedState(out int lpdwFlags, int dwReserved);

[Flags]
enum ConnectionStates
{
    Modem = 0x1,
    LAN = 0x2,
    Proxy = 0x4,
    RasInstalled = 0x10,
    Offline = 0x20,
    Configured = 0x40,
}
```

MSDN地址 https://learn.microsoft.com/en-us/windows/win32/api/wininet/nf-wininet-internetgetconnectedstate 对应的返回值Description如下：

| Value                                  | Meaning                                                      |
| :------------------------------------- | :----------------------------------------------------------- |
| **INTERNET_CONNECTION_CONFIGURED**0x40 | Local system has a valid connection to the Internet, but it might or might not be currently connected. |
| **INTERNET_CONNECTION_LAN**0x02        | Local system uses a local area network to connect to the Internet. |
| **INTERNET_CONNECTION_MODEM**0x01      | Local system uses a modem to connect to the Internet.        |
| **INTERNET_CONNECTION_MODEM_BUSY**0x08 | No longer used.                                              |
| **INTERNET_CONNECTION_OFFLINE**0x20    | Local system is in offline mode.                             |
| **INTERNET_CONNECTION_PROXY**0x04      | Local system uses a proxy server to connect to the Internet. |
| **INTERNET_RAS_INSTALLED**0x10         | Local system has RAS installed.                              |

例子 ：

```c#
using System;
using System.Runtime.InteropServices;

namespace ConsoleApplication2
{
  internal class Program
  {
   [DllImport("wininet.dll", SetLastError = true)]
   private static extern bool InternetGetConnectedState(out int lpdwFlags, int dwReserved);

   private static void Main(string[] args)
   {
    int flags;
    bool isConnected = InternetGetConnectedState(out flags, 0);
    Console.WriteLine(string.Format("Is connected :{0} Flags:{1}", isConnected, flags));
   }
  }
}
```

## 使用NCSI

![Registry](https://i.imgur.com/Q4m4eZa.png)

Windows进行网络检查的地址是 http://www.msftconnecttest.com/connecttest.txt

这些配置可以在注册表`HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\NlaSvc\Parameters\Internet`中找到。注册表内容可以参考[这个项目](https://github.com/dantmnf/NCSIOverride/blob/master/install.reg)。下面是通过NCSI来检查网络是否连接的代码：

```c#
          public Dictionary<string, string> GetNCSIData()
        {
            RegistryKey internetKey =
                Registry.LocalMachine.OpenSubKey(@"SYSTEM\CurrentControlSet\Services\NlaSvc\Parameters\Internet");
            if (internetKey != null)
            {
                Dictionary<string, string> NCSIData = new Dictionary<string, string>();
                string[] valueNames = internetKey.GetValueNames();

                foreach (string key in valueNames)
                {
                    object value = internetKey.GetValue(key);
                    if (value is string v)
                    {
                        NCSIData.Add(key, v);
                    }
                }

                return NCSIData;
            }

            return null;
        }

        public async Task<bool> IsInternetConnected()
        {
            var ncsiDataDic = GetNCSIData();
            string probeHost = ncsiDataDic["ActiveDnsProbeHost"];
            string NCSIDnsIpAddress = ncsiDataDic["ActiveDnsProbeContent"];

            string webProbeHost = ncsiDataDic["ActiveWebProbeHost"];
            string WebProbePath = ncsiDataDic["ActiveWebProbePath"];
            string NCSITestResult = ncsiDataDic["ActiveWebProbeContent"];

            string NCSITestUrl = new UriBuilder()
            {
                Scheme = "http",
                Host = webProbeHost,
                Port = 80,
                Path = WebProbePath
            }.Uri.ToString();


            string NCSIDns = probeHost;

            try
            {
                using (var webClient = new WebClient())
                {
                    string result = await webClient.DownloadStringTaskAsync(NCSITestUrl);
                    if (result != NCSITestResult)
                    {
                        return false;
                    }
                }

                // Check NCSI DNS IP
                var dnsIpAddresses = await Dns.GetHostAddressesAsync(NCSIDns);
                return dnsIpAddresses.Any(addr => addr.ToString() == NCSIDnsIpAddress);
            }
            catch (Exception )
            {
                return false;
            }
        }
```

## 其他方式

可以参考下 Stackoverflow这个问题 https://stackoverflow.com/questions/520347/how-do-i-check-for-a-network-connection



## 参考连接

+ [How to check internet connectivity in C#](http://csharp.tips/tip/article/904-how-to-check-internet-connectivity-in-csharp)
