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

## 附录

### 一些常用的profile配置xml

摘自 项目https://github.com/DigiExam/simplewifi/

#### Open

```xml
<?xml version="1.0"?>
<WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1">
	<name>{0}</name>
	<SSIDConfig>
		<SSID>
			<hex>{1}</hex>
			<name>{0}</name>
		</SSID>
	</SSIDConfig>
	<connectionType>ESS</connectionType>
	<connectionMode>manual</connectionMode>
	<MSM>
		<security>
			<authEncryption>
				<authentication>open</authentication>
				<encryption>none</encryption>
				<useOneX>false</useOneX>
			</authEncryption>
		</security>
	</MSM>
</WLANProfile>

<!-- 
	0 = Name
	1 = Hex
-->
```

#### WEP

```xml
<?xml version="1.0"?>
<WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1">
	<name>{0}</name>
	<SSIDConfig>
		<SSID>
			<hex>{1}</hex>
			<name>{0}</name>
		</SSID>
	</SSIDConfig>
	<connectionType>ESS</connectionType>
	<MSM>
		<security>
			<authEncryption>
				<authentication>open</authentication>
				<encryption>WEP</encryption>
				<useOneX>false</useOneX>
			</authEncryption>
			<sharedKey>
				<keyType>networkKey</keyType>
				<protected>false</protected>
				<keyMaterial>{2}</keyMaterial>
			</sharedKey>
			<keyIndex>0</keyIndex>
		</security>
	</MSM>
</WLANProfile>

<!--
	0 = Name
	1 = HexName
	2 = Key
-->
```

#### WPA-Enterprise-PEAP-MSCHAPv2

```xml
<?xml version="1.0" encoding="us-ascii"?>
<WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1">
	<name>{0}</name>
	<SSIDConfig>
		<SSID>
			<name>{0}</name>
		</SSID>
	</SSIDConfig>
	<connectionType>ESS</connectionType>
	<connectionMode>auto</connectionMode>
	<MSM>
		<security>
			<authEncryption>
				<authentication>WPA</authentication>
				<encryption>TKIP</encryption>
				<useOneX>true</useOneX>
			</authEncryption>
			<OneX xmlns="http://www.microsoft.com/networking/OneX/v1">
				<EAPConfig>
					<EapHostConfig xmlns="http://www.microsoft.com/provisioning/EapHostConfig" xmlns:eapCommon="http://www.microsoft.com/provisioning/EapCommon" xmlns:baseEap="http://www.microsoft.com/provisioning/BaseEapMethodConfig">
						<EapMethod>
							<eapCommon:Type>25</eapCommon:Type>
							<eapCommon:AuthorId>0</eapCommon:AuthorId>
						</EapMethod>
						<Config xmlns:baseEap="http://www.microsoft.com/provisioning/BaseEapConnectionPropertiesV1" xmlns:msPeap="http://www.microsoft.com/provisioning/MsPeapConnectionPropertiesV1" xmlns:msChapV2="http://www.microsoft.com/provisioning/MsChapV2ConnectionPropertiesV1">
							<baseEap:Eap>
								<baseEap:Type>25</baseEap:Type>
								<msPeap:EapType>
									<msPeap:ServerValidation>
										<msPeap:DisableUserPromptForServerValidation>false</msPeap:DisableUserPromptForServerValidation>
										<msPeap:TrustedRootCA />
									</msPeap:ServerValidation>
									<msPeap:FastReconnect>true</msPeap:FastReconnect>
									<msPeap:InnerEapOptional>0</msPeap:InnerEapOptional>
									<baseEap:Eap>
										<baseEap:Type>26</baseEap:Type>
										<msChapV2:EapType>
											<msChapV2:UseWinLogonCredentials>false</msChapV2:UseWinLogonCredentials>
										</msChapV2:EapType>
									</baseEap:Eap>
									<msPeap:EnableQuarantineChecks>false</msPeap:EnableQuarantineChecks>
									<msPeap:RequireCryptoBinding>false</msPeap:RequireCryptoBinding>
									<msPeap:PeapExtensions />
								</msPeap:EapType>
							</baseEap:Eap>
						</Config>
					</EapHostConfig>
				</EAPConfig>
			</OneX>
		</security>
	</MSM>
</WLANProfile>

<!--
	0 = Name
-->
```

#### WPA-Enterprise-TLS

````xml
<?xml version="1.0" encoding="us-ascii"?>
<WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1">
	<name>{0}</name>
	<SSIDConfig>
		<SSID>
			<name>{0}</name>
		</SSID>
		<nonBroadcast>false</nonBroadcast>
	</SSIDConfig>
	<connectionType>ESS</connectionType>
	<connectionMode>auto</connectionMode>
	<autoSwitch>false</autoSwitch>
	<MSM>
		<security>
			<authEncryption>
				<authentication>WPA</authentication>
				<encryption>TKIP</encryption>
				<useOneX>true</useOneX>
			</authEncryption>
			<OneX xmlns="http://www.microsoft.com/networking/OneX/v1">
				<EAPConfig>
					<EapHostConfig xmlns="http://www.microsoft.com/provisioning/EapHostConfig" xmlns:eapCommon="http://www.microsoft.com/provisioning/EapCommon" xmlns:baseEap="http://www.microsoft.com/provisioning/BaseEapMethodConfig">
						<EapMethod>
							<eapCommon:Type>13</eapCommon:Type>
							<eapCommon:AuthorId>0</eapCommon:AuthorId>
						</EapMethod>
						<Config xmlns:baseEap="http://www.microsoft.com/provisioning/BaseEapConnectionPropertiesV1" xmlns:eapTls="http://www.microsoft.com/provisioning/EapTlsConnectionPropertiesV1">
							<baseEap:Eap>
								<baseEap:Type>13</baseEap:Type>
								<eapTls:EapType>
									<eapTls:CredentialsSource>
										<eapTls:CertificateStore />
									</eapTls:CredentialsSource>
									<eapTls:ServerValidation>
										<eapTls:DisableUserPromptForServerValidation>false</eapTls:DisableUserPromptForServerValidation>
										<eapTls:ServerNames />
									</eapTls:ServerValidation>
									<eapTls:DifferentUsername>false</eapTls:DifferentUsername>
								</eapTls:EapType>
							</baseEap:Eap>
						</Config>
					</EapHostConfig>
				</EAPConfig>
			</OneX>
		</security>
	</MSM>
</WLANProfile>


<!--
	0 = Name
-->
````

#### WPA-PSK

```xml
<?xml version="1.0" encoding="us-ascii"?>
<WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1">
	<name>{0}</name>
	<SSIDConfig>
		<SSID>
			<name>{0}</name>
		</SSID>
	</SSIDConfig>
	<connectionType>ESS</connectionType>
	<connectionMode>auto</connectionMode>
	<autoSwitch>false</autoSwitch>
	<MSM>
		<security>
			<authEncryption>
				<authentication>WPAPSK</authentication>
				<encryption>TKIP</encryption>
				<useOneX>false</useOneX>
			</authEncryption>
			<sharedKey>
				<keyType>passPhrase</keyType>
				<protected>false</protected>
				<keyMaterial>{1}</keyMaterial>
			</sharedKey>
		</security>
	</MSM>
</WLANProfile>

<!--
	0 = Name
	1 = Key
-->
```

#### WPA2-Enterprise-PEAP-MSCHAPv2

```xml
<?xml version="1.0" encoding="us-ascii"?>
<WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1">
	<name>{0}</name>
	<SSIDConfig>
		<SSID>
			<name>{0}</name>
		</SSID>
	</SSIDConfig>
	<connectionType>ESS</connectionType>
	<connectionMode>auto</connectionMode>
	<MSM>
		<security>
			<authEncryption>
				<authentication>WPA2</authentication>
				<encryption>AES</encryption>
				<useOneX>true</useOneX>
			</authEncryption>
			<OneX xmlns="http://www.microsoft.com/networking/OneX/v1">
				<EAPConfig>
					<EapHostConfig xmlns="http://www.microsoft.com/provisioning/EapHostConfig" xmlns:eapCommon="http://www.microsoft.com/provisioning/EapCommon" xmlns:baseEap="http://www.microsoft.com/provisioning/BaseEapMethodConfig">
						<EapMethod>
							<eapCommon:Type>25</eapCommon:Type>
							<eapCommon:AuthorId>0</eapCommon:AuthorId>
						</EapMethod>
						<Config xmlns:baseEap="http://www.microsoft.com/provisioning/BaseEapConnectionPropertiesV1" xmlns:msPeap="http://www.microsoft.com/provisioning/MsPeapConnectionPropertiesV1" xmlns:msChapV2="http://www.microsoft.com/provisioning/MsChapV2ConnectionPropertiesV1">
							<baseEap:Eap>
								<baseEap:Type>25</baseEap:Type>
								<msPeap:EapType>
									<msPeap:ServerValidation>
										<msPeap:DisableUserPromptForServerValidation>false</msPeap:DisableUserPromptForServerValidation>
										<msPeap:TrustedRootCA />
									</msPeap:ServerValidation>
									<msPeap:FastReconnect>true</msPeap:FastReconnect>
									<msPeap:InnerEapOptional>0</msPeap:InnerEapOptional>
									<baseEap:Eap>
										<baseEap:Type>26</baseEap:Type>
										<msChapV2:EapType>
											<msChapV2:UseWinLogonCredentials>false</msChapV2:UseWinLogonCredentials>
										</msChapV2:EapType>
									</baseEap:Eap>
									<msPeap:EnableQuarantineChecks>false</msPeap:EnableQuarantineChecks>
									<msPeap:RequireCryptoBinding>false</msPeap:RequireCryptoBinding>
									<msPeap:PeapExtensions />
								</msPeap:EapType>
							</baseEap:Eap>
						</Config>
					</EapHostConfig>
				</EAPConfig>
			</OneX>
		</security>
	</MSM>
</WLANProfile>

<!--
	0 = Name
-->
```

#### WPA2-Enterprise-TLS

```xml
<?xml version="1.0" encoding="us-ascii"?>
<WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1">
	<name>{0}</name>
	<SSIDConfig>
		<SSID>
			<name>{0}</name>
		</SSID>
	</SSIDConfig>
	<connectionType>ESS</connectionType>
	<connectionMode>auto</connectionMode>
	<autoSwitch>false</autoSwitch>
	<MSM>
		<security>
			<authEncryption>
				<authentication>WPA2</authentication>
				<encryption>AES</encryption>
				<useOneX>true</useOneX>
			</authEncryption>
			<OneX xmlns="http://www.microsoft.com/networking/OneX/v1">
				<EAPConfig>
					<EapHostConfig xmlns="http://www.microsoft.com/provisioning/EapHostConfig" xmlns:eapCommon="http://www.microsoft.com/provisioning/EapCommon" xmlns:baseEap="http://www.microsoft.com/provisioning/BaseEapMethodConfig">
						<EapMethod>
							<eapCommon:Type>13</eapCommon:Type>
							<eapCommon:AuthorId>0</eapCommon:AuthorId>
						</EapMethod>
						<Config xmlns:baseEap="http://www.microsoft.com/provisioning/BaseEapConnectionPropertiesV1" xmlns:eapTls="http://www.microsoft.com/provisioning/EapTlsConnectionPropertiesV1">
							<baseEap:Eap>
								<baseEap:Type>13</baseEap:Type>
								<eapTls:EapType>
									<eapTls:CredentialsSource>
										<eapTls:CertificateStore />
									</eapTls:CredentialsSource>
									<eapTls:ServerValidation>
										<eapTls:DisableUserPromptForServerValidation>false</eapTls:DisableUserPromptForServerValidation>
										<eapTls:ServerNames />
									</eapTls:ServerValidation>
									<eapTls:DifferentUsername>false</eapTls:DifferentUsername>
								</eapTls:EapType>
							</baseEap:Eap>
						</Config>
					</EapHostConfig>
				</EAPConfig>
			</OneX>
		</security>
	</MSM>
</WLANProfile>

<!--
	0 = Name
-->
```

#### WPA2-PSK

```xml
<?xml version="1.0" encoding="us-ascii"?>
<WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1">
	<name>{0}</name>
	<SSIDConfig>
		<SSID>
			<name>{0}</name>
		</SSID>
	</SSIDConfig>
	<connectionType>ESS</connectionType>
	<connectionMode>auto</connectionMode>
	<autoSwitch>false</autoSwitch>
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
</WLANProfile>

<!--
	0 = Name
	1 = Key
-->
```

