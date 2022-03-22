---
title:"判断是否是UEFI启动的代码"
date: 2016-01-30
tags: [ "AU3"]
draft: false
---

# 判断是否是UEFI启动的代码


```
#include <WinAPI.au3>
Global Const $ERROR_INVALID_FUNCTION=0x1
DllCall("Kernel32.dll", "dword", "GetFirmwareEnvironmentVariableW", "wstr", "", "wstr", '{00000000-0000-0000-0000-000000000000}', "wstr", Null, "dword", 0)
If _WinAPI_GetLastError() = $ERROR_INVALID_FUNCTION Then
    MsgBox(0,'','Legacy BIOS')
Else
    MsgBox(0,'','UEFI Boot Mode')
EndIf


```

或者

```
#include <WinAPI.au3>
MsgBox(0,_WinAPI_GetFirmwareEnvironmentVariable(),0)
Func _WinAPI_GetFirmwareEnvironmentVariable()
    Local $sName = ""
    Local $sGUID = "{00000000-0000-0000-0000-000000000000}"
    Local $aRet = DllCall("Kernel32.dll", "dword", _
        "GetFirmwareEnvironmentVariableW", "wstr", $sName, _
        "wstr", $sGUID, "wstr", "", "dword", 4096)
    ; ERROR_INVALID_FUNCTION 1 (0x1)
    ; ERROR_NOACCESS 998 (0x3E6)
    Local $LastError = _WinAPI_GetLastError()
    If $LastError == 1 Then
        Return "Legacy"
    ElseIf $LastError == 998 Then
        Return "UEFI"
    Else
        Return "Unknown"
    EndIf
EndFunc


```

未进行测试，C++代码如下：
```
#include <windows.h>
#include <stdio.h>
int main(int argc, char* argv[])
{
        GetFirmwareEnvironmentVariableA("","{00000000-0000-0000-0000-000000000000}",NULL,0);
        if (GetLastError() == ERROR_INVALID_FUNCTION) { // This.. is.. LEGACY BIOOOOOOOOS....
                printf("Legacy");
                return 1;
        } else {
                printf("UEFI");
                return 0;
        }
        return 0;
}


```

适用于windows8及以上版本系统
<https://www.autoitscript.com/forum/topic/203061-uefi-or-bios-legacy-boot-win10-2004/>
<https://docs.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-getfirmwaretype>

```
lobal Enum $FirmwareTypeUnknown, _
        $FirmwareTypeBios, _
        $FirmwareTypeUefi, _
        $FirmwareTypeMax

ConsoleWrite("FirmwareType: " & _GetFirmwareType() & @CRLF)
ConsoleWrite("FirmwareType: " & _GetFirmwareTypeString() & @CRLF)

Func _GetFirmwareType()
    Local $aCall = DllCall("Kernel32.dll", "int", "GetFirmwareType", "int*", 0)
    If Not @error And $aCall[0] Then Return $aCall[1]
    Return SetError(1, 0, 0)EndFunc   ;==>_GetFirmwareType

Func _GetFirmwareTypeString()
    Local $iType = _GetFirmwareType()
    Local $asTypes[] = ["Unknown", "Bios", "Uefi", "Max"]
    Return $asTypes[$iType]EndFunc   ;==>_GetFirmwareTypeString
```

简易的UDF
```
#include <WinAPI.au3>

If IsUEFIBoot() Then
    MsgBox(0, '', "UEFI boot")
Else
    MsgBox(0, '', "Bios boot")
EndIf

Func IsUEFIBoot()
    Local Const $ERROR_INVALID_FUNCTION = 0x1
    Local $hDLL = DllOpen("Kernel32.dll")
    If @OSBuild > 8000 Then
        Local $aCall = DllCall($hDLL, "int", "GetFirmwareType", "int*", 0)
        DllClose($hDLL)
        If Not @error And $aCall[0] Then
            Switch $aCall[1]
                ; 1 - bios 2- uefi 3-unknown
                Case 2
                    Return True
                Case Else
                    Return False
            EndSwitch
        EndIf
        Return False

    Else
        DllCall($hDLL, "dword", "GetFirmwareEnvironmentVariableW", "wstr", "", "wstr", '{00000000-0000-0000-0000-000000000000}', "wstr", Null, "dword", 0)
        DllClose($hDLL)
        If _WinAPI_GetLastError() = $ERROR_INVALID_FUNCTION Then
            Return False
        Else
            Return True
        EndIf
    EndIf
EndFunc   ;==>IsUEFIBoot
```

