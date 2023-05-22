---
title: "Dart语言参考"
date: 2023-05-21
tags: ["dart"]
draft: false
---

Dart语言学习入门过程中的一些记录，仅记录有差异的。可能会跟go等其他语言进行一个对比。

## 语言基础

### 运算符

#### 截断除法运算符（truncating division operator）

比如计算 23➗ 7

使用 `23/7` 使用下面的代码

```dart
void main (){
  print(23/7);
}
// 输出 3.2857142857142856
```

使用`~/`运算符

```dart
void main (){
  print(23~/7);
}
// 输出 3
```

### String

#### 变量值内插

Dart使用下面的方式进行值的内插

```dart
void main() {
  var greeter = "Dart🐟";
  print("打印机:$greeter");
}
```

这一点跟C#有一点相似，C#使用下面的方式：

```c#
void main() {
  var greeter = "C#🐟";
  print($"打印机:{greeter}");
}
```

Dart中如果变量需要进行值计算，那么跟开始的例子相似。

```dart
void main() {
  var greeter = "Dart🐟";
  print("打印机:${greeter.length}");
}

```

### 函数

#### 可选参数

```dart
String Fake(String UserName, [String? carIdentifier]) {
  if (carIdentifier != null) {
    return "hello,$UserName,your car is $carIdentifier";
  } else {
    return "hello,$UserName,you don't have car";
  }
}
```

#### 必选参数

```dart
String Fake({required String UserName, String? carIdentifier}) {
  if (carIdentifier != null) {
    return "hello,$UserName,your car is $carIdentifier";
  } else {
    return "hello,$UserName,you don't have car";
  }
}
// 调用时，必须要显式申明参数名称，必须参数也不能设置默认值
// √ var result = Fake(UserName: "czyt", carIdentifier: "川A12134"); 
// ×  var result = Fake("czyt", "川A12134");
```

#### 默认值

```dart
String Fake({ String UserName="czyt", String? carIdentifier}) {
  if (carIdentifier != null) {
    return "hello,$UserName,your car is $carIdentifier";
  } else {
    return "hello,$UserName,you don't have car";
  }
}
// 调用：var result = Fake(carIdentifier: "川A12134");
```

#### 箭头函数

下面两个函数等价

```dart
int add(int a, int b) {
  return a + b;
}
```

等价于

```dart
int add(int a, int b) => a + b;
```

### 类

下面是一个简单的类

```dart
class User {
  int id = 0;
  String name = "";
  // 通过重写基类的toString来实现转换到String的格式化
  @override
  String toString() {
    return "User Id:$id Name:$name";
  }
}
```

调用

```dart
void main() {
  final user = User();
  user.id = 1000;
  user.name = "czyt";
  print(user.toString());
}
```

Dart允许级联声明，那么调用的这个例子可以改为下面这样

```dart
void main() {
  final user = User()
    ..id = 1000
    ..name = "czyt";
  print(user.toString());
}
```

在Dart中，对象是通过引用传递的，如果将一个对象赋值给另外一个对象，并对另外一个对象进行修改，那么这个修改也会影响到原来的那个对象。

```dart
void main() {
  final user = User()
    ..id = 1000
    ..name = "czyt";
  print(user.toString());
  // User Id:1000 Name:czyt

  var anotherUser = user;
  anotherUser.name = "gopher";
  // User Id:1000 Name:gopher
  print(anotherUser.toString());
  // User Id:1000 Name:gopher
}
```

#### 私有字段

Dart的字段可以通过添加`_`来申明私有字段。申明为私有字段后，字段在外部将不能直接访问。可以通过添加`getter`来访问字段。下面是一个例子：

```dart
class Password {
  String _plainText = 'pass123';
  String get obfuscated {
  final length = _plainText.length;
  return '*' * length;
}
}
```

如果需要修改私有字段，那么还需要添加`setter` 

```dart
set plainText(String text) => _plainText = text;
```

在setter中还可以添加相关的校验逻辑

```dart
set plainText(String text) {
  if (text.length < 6) {
    print('Passwords must have 6 or more characters!');
    return;
  }
  _plainText = text;
}
```

#### 构造函数

TODO

#### 静态成员

TODO







