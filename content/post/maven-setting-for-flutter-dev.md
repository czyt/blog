---
title: "Flutter开发Maven配置"
date: 2022-05-27
tags: ["flutter", "android"]
draft: false
---

在Flutter开发时，可能因为网络等原因导致maven不能正常工作，造成Flutter项目卡住的情况。下面是解决办法。原文链接 https://flutter.cn/community/china

> 如果你在国内使用 Flutter，那么你可能需要找一个与官方同步的可信的镜像站点，帮助你的 Flutter 命令行工具到该镜像站点下载其所需的资源。你需要为此设置两个环境变量：`PUB_HOSTED_URL` 和 `FLUTTER_STORAGE_BASE_URL`，然后再运行 Flutter 命令行工具。
>
> 以 macOS 或者与 Linux 相近的系统为例，这里有以下步骤帮助你设定镜像。在系统终端里执行如下命令设定环境变量，并通过 GitHub 检出 Flutter SDK：
>
> *content_copy*
>
> ```
> $ export PUB_HOSTED_URL=https://pub.flutter-io.cn
> $ export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
> $ git clone -b dev https://github.com/flutter/flutter.git
> $ export PATH="$PWD/flutter/bin:$PATH"
> $ cd ./flutter
> $ flutter doctor
> ```

## Flutter SDK配置修改

flutter的maven设置在`<安装目录>\packages\flutter_tools\gradle\flutter.gradle` 

### 打包配置

```
buildscript {
    repositories {
        maven { url 'https://maven.aliyun.com/repository/google' }
        maven { url 'https://maven.aliyun.com/repository/public' }
        maven { url 'https://maven.aliyun.com/repository/central' }
        maven { url 'https://maven.aliyun.com/repository/jcenter' }
        // google()
        // jcenter()
    }
    dependencies {
        /* When bumping, also update ndkVersion above. */
        classpath 'com.android.tools.build:gradle:4.1.0'
    }
}
```

### FlutterPlugin配置

```
class FlutterPlugin implements Plugin<Project> {
    // private static final String DEFAULT_MAVEN_HOST = "https://storage.googleapis.com";
        private static final String MAVEN_REPO = "https://storage.flutter-io.cn/download.flutter.io";

```

### 所有项目设置

```
rootProject.allprojects {
            repositories {
                maven {
                    url repository
                }
               // 添加下面的内容
                maven { url 'https://maven.aliyun.com/repository/google' }
                maven { url 'https://maven.aliyun.com/repository/jcenter' }
                maven { url 'https://maven.aliyun.com/repository/public' }
            }
        }
```

## Flutter项目配置修改

修改`Flutter`项目下的`android`下的`build.gradle`

```
buildscript {
    ext.kotlin_version = '1.6.10'
    repositories {
        //  google()
        //  jcenter()
        maven { url 'https://maven.aliyun.com/repository/google' }
        maven { url 'https://maven.aliyun.com/repository/jcenter' }
        maven { url 'https://maven.aliyun.com/repository/public' }
    }

    dependencies {
        classpath 'com.android.tools.build:gradle:7.1.2'
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
    }
}

allprojects {
    repositories {
        //  google()
        //  jcenter()
        maven { url 'https://maven.aliyun.com/repository/google' }
        maven { url 'https://maven.aliyun.com/repository/jcenter' }
        maven { url 'https://maven.aliyun.com/repository/public' }
    }
}
```

配置完毕。

## 相关资源

+ [在中国网络环境下使用 Flutter](https://flutter.cn/community/china)

+ [阿里云Maven中央仓库 ](https://developer.aliyun.com/mvn/guide)

  