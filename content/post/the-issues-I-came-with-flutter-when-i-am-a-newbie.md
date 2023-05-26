---
title: "初学Flutter时我遇到的问题汇总"
date: 2023-05-25
tags: ["flutter", "issues"]
draft: false
---
这些是我学习Flutter过程中遇到的问题列表
## 项目问题
### Android Studio丢失Image Asset新建项

![image-20230525201100880](https://assets.czyt.tech/img/project-opt-for-image-asset.png)

这样会在新的界面打开IDE，等同步完成，然后就有新建项了。

![image-20230525200813317](https://assets.czyt.tech/img/new-image-asset-dialog.png)

## 调试

### 隐藏Debug 条幅

在代码的theme入口代码添加`debugShowCheckedModeBanner: false,`,完整代码如下：

```dart
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}
```
### AndroidStudio可以显示设备但是Flutter的设备选择没有设备
先检查Android SDK
```
PS C:\Windows\system32> flutter doctor --android-licenses
Flutter assets will be downloaded from https://storage.flutter-io.cn. Make sure you trust this source!
Unable to locate Android SDK.
```
然后设置Android SDK路径
```
PS C:\Windows\system32> flutter config --android-sdk "D:\Android"
Setting "android-sdk" value to "D:\Android".

You may need to restart any open editors for them to read new settings.
```
再次验证并查看设备列表
```
PS C:\Windows\system32> flutter doctor
Flutter assets will be downloaded from https://storage.flutter-io.cn. Make sure you trust this source!
Doctor summary (to see all details, run flutter doctor -v):
[√] Flutter (Channel stable, 3.10.2, on Microsoft Windows [版本 10.0.19045.3031], locale zh-CN)
[√] Windows Version (Installed version of Windows is version 10 or higher)
[!] Android toolchain - develop for Android devices (Android SDK version 33.0.2)
    X No Java Development Kit (JDK) found; You must have the environment variable JAVA_HOME set and the java binary in
      your PATH. You can download the JDK from https://www.oracle.com/technetwork/java/javase/downloads/.
[X] Chrome - develop for the web (Cannot find Chrome executable at .\Google\Chrome\Application\chrome.exe)
    ! Cannot find Chrome. Try setting CHROME_EXECUTABLE to a Chrome executable.
[√] Visual Studio - develop for Windows (Visual Studio 生成工具 2022 17.5.5)
[√] Android Studio (version 2022.2)
[!] Android Studio
    X android-studio-dir = D:\Android\Sdk
    X Unable to find bundled Java version.
[√] Connected device (3 available)
[√] Network resources

! Doctor found issues in 3 categories.
```
查看设备详细列表
```
PS C:\Windows\system32> flutter devices
Flutter assets will be downloaded from https://storage.flutter-io.cn. Make sure you trust this source!
3 connected devices:

MI 12s (mobile)     • 308710d3 • android-arm64  • Android 13 (API 33)
Windows (desktop) • windows  • windows-x64    • Microsoft Windows [版本 10.0.19045.3031]
Edge (web)        • edge     • web-javascript • Microsoft Edge 92.0.902.67
```
## 样式
### 主题复制修改
在某些情况下，想要继承某个主题，并修改某些属性，可以使用下面的方式：
```dart
Widget build(BuildContext context) {
    return  MaterialApp(
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.orange,
        scaffoldBackgroundColor: Colors.teal
      ),
     .....
}
```

## 相关资料

### Dart包

+ [Networking in Flutter using Dio](https://blog.logrocket.com/networking-flutter-using-dio/)
