---
title: "Flutter开发Maven配置"
date: 2022-05-28
tags: ["flutter", "andoid"]
draft: false
---

​      在Flutter开发时，可能因为网络等原因导致maven不能正常工作，造成Flutter项目卡住的情况。下面是解决办法.
## Flutter SDK配置修改

flutter的maven设置在`<安装目录>\packages\flutter_tools\gradle\flutter.gradle` 

### 打包配置

```json
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

```json
class FlutterPlugin implements Plugin<Project> {
    // private static final String DEFAULT_MAVEN_HOST = "https://storage.googleapis.com";
        private static final String MAVEN_REPO = "https://storage.flutter-io.cn/download.flutter.io";

```

### 所有项目设置

```json
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

```json
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

  