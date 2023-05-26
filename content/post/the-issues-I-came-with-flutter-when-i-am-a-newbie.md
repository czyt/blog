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

## 相关资料

### Dart包

+ [Networking in Flutter using Dio](https://blog.logrocket.com/networking-flutter-using-dio/)
