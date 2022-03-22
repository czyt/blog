---
title:"AU3 DLL文件注册及反注册"
date: 2015-12-12
tags:[ "AU3""]
draft: false
---

# AU3 DLL文件注册及反注册


注册：
```
$sDll = @ScriptDir&'\HashTab64.dll' ; or just name
$aCall = DllCall($sDll, "long", "DllRegisterServer")
If @error Or $aCall[0] Then
 MsgBox(262144, "ERROR", "Failed to register " & FileGetLongName($sDll))
Else
 MsgBox(0,'OK','The Dll has been registered')
EndIf
```

反注册：
```
$sDll = @ScriptDir&'\HashTab64.dll' ; or just name
$aCall =  DllCall($sDll, "long", "DllUnregisterServer")
If @error Or $aCall[0] Then
 MsgBox(262144, "ERROR", "Failed to unregister " & FileGetLongName($sDll))
Else
 MsgBox(0,'OK','The Dll has been unregistered')
EndIf
```

