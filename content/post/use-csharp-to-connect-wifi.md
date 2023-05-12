---
title: "使用C#连接wifi"
date: 2023-04-24
tags: [".net", "csharp"]
draft: false
---
## 需要安装库
+ [Managed Native Wifi](https://github.com/emoacht/ManagedNativeWifi)
## 获取Wifi列表
示例代码
```csharp
private List<AvailableNetworkPack> GetAvaliableNetworks()
{
    var networks = new List<AvailableNetworkPack>();
    foreach (var network in NativeWifi.EnumerateAvailableNetworks())
    {
        if (!networks.Contains(network))
        {
            networks.Add(network);
        }
    }
    return networks;
}
```

## 连接wifi

### 创建Profile

>应该支持这些类型**open**, **WEP** and **WPA-PSK**的网络

```csharp
private static string CreateSecurityWifiProfile(string ssid, string password)
        {
            string hex = CreateHexSSIDName(ssid);

            return string.Format(@"<?xml version=""1.0""?>
            <WLANProfile xmlns=""http://www.microsoft.com/networking/WLAN/profile/v1"">
                <name>{0}</name>
                <SSIDConfig>
                    <SSID>
                        <hex>{2}</hex>
                        <name>{0}</name>
                    </SSID>
                </SSIDConfig>
                <connectionType>ESS</connectionType>
                <connectionMode>auto</connectionMode>
                <MSM>
                    <security>
                        <authEncryption>
                            <authentication>WPA2PSK</authentication>
                            <encryption>AES</encryption>
                            <useOneX>false</useOneX>
                        </authEncryption>
                        <sharedKey>
                            <keyType>passPhrase</keyType>
                            <protected>false</protected>
                            <keyMaterial>{1}</keyMaterial>
                        </sharedKey>
                    </security>
                </MSM>
                <MacRandomization xmlns=""http://www.microsoft.com/networking/WLAN/profile/v3"">
                    <enableRandomization>false</enableRandomization>
                </MacRandomization>
            </WLANProfile>", ssid, password, hex);
        }

        private static string CreateOpenWifiProfile(string ssid)
        {
            string hex = CreateHexSSIDName(ssid);
            return string.Format(@"<?xml version=""1.0""?>
            <WLANProfile xmlns=""http://www.microsoft.com/networking/WLAN/profile/v1"">
            <name>{0}</name>
            <SSIDConfig>
              <SSID>
                <hex>{1}</hex>
                <name>{0}</name>
              </SSID>
            </SSIDConfig>
            <connectionType>ESS</connectionType>
            <connectionMode>auto</connectionMode>
            <MSM>
              <security>
                <authEncryption>
                  <authentication>open</authentication>
                  <encryption>none</encryption>
                  <useOneX>false</useOneX>
                </authEncryption>
              </security>
            </MSM>
            </WLANProfile>", ssid, hex);
        }
private static string CreateHexSSIDName(string ssid)
{
    byte[] bytes = System.Text.Encoding.UTF8.GetBytes(ssid);
    return BitConverter.ToString(bytes).Replace("-", "");
}
```

### 连接到wifi

```csharp
 var networks = GetAvaliableNetworks();
var network = networks.First(n => n.Ssid.ToString() == "gophers");
var profile = NativeWifi.EnumerateProfiles().FirstOrDefault(x => x.Name == "NTSP_CD");

if (profile is null)
{
    var profileXml = CreateProfile("gophers", "gopherspwd");
    // create a profile
    var profileResult = NativeWifi.SetProfile(network.Interface.Id, ProfileType.PerUser, profileXml, "AES", true);
}
// do connect
var wasConnected = NativeWifi.ConnectNetwork(network.Interface.Id, network.Ssid.ToString(), network.BssType);
```

Done