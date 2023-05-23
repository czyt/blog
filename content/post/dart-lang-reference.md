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

又称匿名函数，下面两个函数等价

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
#### 扩展Extend

使用Extend，来为现有的类的功能创建一个子类。

```dart
class Media { 
  String title = ""; 
  String type = ""; 
   
  Media(){ type = "Class"; } 
   
  void setMediaTitle(String mediaTitle){ title = mediaTitle; } 
   
  String getMediaTitle(){ return title; } 
   
  String getMediaType(){ return type; } 
} 
class Book extends Media { 
  String author = ""; 
  String isbn = ""; 
   
  Book(){ type = "Subclass"; } 
   
  void setBookTitle(String bookTitle){ title = bookTitle; } 
   
  void setBookAuthor(String bookAuthor){ author = bookAuthor; } 
   
  void setBookISBN(String bookISBN){ isbn = bookISBN; } 
   
  String getBookTitle(){ return title; } 
   
  String getBookAuthor(){ return author; } 
   
  String getBookISBN(){ return isbn; } 
} 
void main() { 
  var myMedia = Media(); 
     myMedia.setMediaTitle('Tron'); 
  print ('Title: ${myMedia.getMediaTitle()}'); 
  print ('Type: ${myMedia.getMediaType()}'); 
   
   
  var myBook = Book(); 
  myBook.setBookTitle("Jungle Book"); 
  myBook.setBookAuthor("R Kipling"); 
  print ('Title: ${myBook.getMediaTitle()}'); 
  print ('Author: ${myBook.getBookAuthor()}'); 
  print ('Type: ${myBook.getMediaType()}'); 
}
```
#### 构造函数

##### 默认构造函数

```dart
class User {
  User();
  User.Simple(int id, String name) {
    this.id = id;
    this.name = name;
  }
 // User.Simple:this(0,"czyt");
 // User({this.id=0,this.name="czyt"});
  int id = 0;
  String name = "";
}
```
等价于下面的写法
```dart
class User {
  User(this.id,this.name);
  int id = 0;
  String name = "";
}
```
##### 可选和命名构造函数
可选参数
```dart
User([this.name]);
```
可选命名参数
```dart
User({this.name});
```
必选参数
```dart
User({required this.name});
```
##### 常量构造函数
常量构造函数可以使得构造出来的结果不可变。
```dart
class User {
  final int _id ;
  final String _name ;

   const User({int id = 0, String name = "czyt"})
      : _id = id,
        _name = name;
  const User.Simple():this();
}

void main() {
  const u = User(id: 8888, name: "czyt");
}
```
使用const的好处不仅仅在于不可变性，另外还体现在性能上。无论你调用多少次实例，只要参数是一样的，Dart只会创建一个实例，而不是创建很多的实例，这一模式在Flutter的Widget中广泛使用。
##### 工厂构造函数
```dart
class User {
  final int _id;
  final String _name;

  const User({int id = 0, String name = "czyt"})
      : _id = id,
        _name = name;
  const User.Simple() : this();

  factory User.Gopher(int id) {
    return User(id:id,name: "gopher");
  }
}
```
在命名构造函数上使用工厂构造函数，可以避免对相应类的子类进行破坏性更改。参考 https://stackoverflow.com/a/66117859
#### 静态成员
在字段或者方法前添加`static`关键字，将使字段或者方法属于类，而不是类的实例。
```dart
void main() {
  gitter.clone("github.com/czyt/czyt");
}

class gitter {
  static String repo = "";
  static clone(String repoUrl) {
    print("cloning $repoUrl to local dir");
  }
}
```
静态成员的特性可以很方便地实现`Singleton`模式。以创建一个数据库连接对象为例：

```dart
class DB {
  String connectStr = "";
  String user = "";
  String password = "";
  DB._();
  static final DB instance = DB._();

  factory DB()=>instance;
}
```
静态变量在Dart中一直是懒惰的。即在使用时才会进行相关的初始化工作。
### 可空值
在dart中使用类型后加`?` 来表示一个可能为空的类型。实际上是类型和Null的并集。

如`int?` `String?` `Float?` `Bool?`等.
```dart
Float? height;
Bool? married;
```

Dart还自带了一些空值操作符。

`??` : If-null operator. 当左侧值为null时，使用右边值。跟c#里面的用法一样。

```dart
void main() {
  String? username;
  var displayUserName = username ?? "anonymous";
  print(displayUserName);
  // anonymous
}
```

`??=` : Null-aware assignment operator.如果左侧值是null就赋值

```dart
void main() {
  String? username;
  username ??= "anonymous";
  var displayUserName = username;
  print(displayUserName);
  // anonymous
}
```
`?. ` Null-aware access operator.如果左侧值不为空就调用

```dart
void main() {
  int? number;
  print(number?.isEven);
}
```
`! ` Null assertion operator.在Dart不能确定值是否为null但是使用者可以确信不为null的情况下，使用该操作符。

```dart
bool? isBeautiful(String? item) {
  if (item == 'flower') {
    return true;
  } else if (item == 'garbage') {
    return false;
  }
  return null;
}
bool flowerIsBeautiful = isBeautiful('flower')!;
```

`?.. ` Null-aware cascade operator.

```dart
void main() {
  User? user;
  user
    ?..name = "czyt"
    ..age = 18;
}

class User {
  String? name;
  int? age;
}
```

`?[]`  Null-aware index operator.控制索引操作符

```dart
List<String>? myDesserts = ['cake', 'pie'];
myDesserts = null;
String? dessertToday = myDesserts?[1];
```

`…?` Null‐Aware Spread Operator 如果列表本身是空的，它将省略列表。

```dart
List<String>? coffees;
final hotDrinks = ['milk tea', ...?coffees];
print(hotDrinks);
// milk tea
```

除此之外，还有一个`late` 关键字，可以实现`lazy` 初始化的功能。使用`late`意味着Dart不会立即初始化这个变量。只有在你第一次使用它时，它才进行初始化，这就像变量的拖延症。

```dart
class User {
  User(this.name);
  final String name;
  late final int _secretNumber = _calculateSecret();
  int _calculateSecret() {
    return name.length + 42;
  }
}
```
### List

![image-20230523113555851](https://assets.czyt.tech/img/dart-list.png)

下面的例子包含了常见的List操作

```dart
void main() {
  var gophers = ["czyt", "chan", "rs"];
  // 添加元素
  gophers.add("rob");
  // 遍历元素
  gophers.forEach((element) {
    print(element);
  });
  // 判断元素是否存在
  print(gophers.contains("czyt"));
  // 清空
  gophers.clear();

  List<int> scores = [1, 2, 3, 4];
  // 插入9 作为列表的索引2元素
  scores.insert(2, 9);
  // 反转列表元素
  scores.reversed.forEach((element) {
    print(element);
  });
  print("before sort $scores");
  scores.sort();
  print("after sort $scores");
}

```

在Dart中，可以使用`...`操作符来进行List的复制。在go语言中也有类似的用法。看下面的这个例子：

```dart
const pastries = ['cookies', 'croissants'];
const candy = ['Junior Mints', 'Twizzlers', 'M&Ms'];
 // 方式1
final desserts = ['donuts'];
desserts.addAll(pastries);
desserts.addAll(candy);
// 方式2
const desserts1 = ['donuts', ...pastries, ...candy];
```

使用collection `if` 语句可以用来判断是否将某个值放入到数组中。比如，如果你有花生过敏症，你会想避免在糖果清单中加入某些含有花生酱添加到糖果列表中。可以用下面的代码来表达：

```dart
const peanutAllergy = true;
const sensitiveCandy = [
 'Junior Mints',
 'Twizzlers',
 if (!peanutAllergy) 'Reeses',
];
print(sensitiveCandy);
```

另外还有 collection`for `语句，它可以基于另外一个列表生成当前列表的元素：

```dart
const deserts = ['gobi', 'sahara', 'arctic'];
var bigDeserts = [
 'ARABIAN',
 for (var desert in deserts) desert.toUpperCase(),
];
print(bigDeserts);
```
空列表和可空值列表

```dart
List<String?>? drinks = ['milk', 'water', null, 'soda'];
// 1
for (String? drink in drinks) {
 // 2
 int letters = drink?.length ?? 0;
 print(letters);
}

List<int?> nullableElements = [2, 4, null, 3, 7];
```



### Set

![image-20230523114251830](https://assets.czyt.tech/img/dart-Set.png)

下面是一些Set的常见操作：

```dart
void main() {
  final Set<String> users = {"czyt", "rob"};
  print(users);
  // {czyt, rob}
  // 添加元素，已经存在的会被忽略
  users.add("czyt");
  print(users);
  // {czyt, rob}
  // 移除指定对象
  users.remove("czyt");
  print(users);
  // { rob}
  // 检查Set是否存在对象
  print(users.contains("rob"));
  // true
  // 添加多个元素
  users.addAll(["lane", "bruce", "wayne"]);
  print(users);

// Set对象遍历 方式1
  users.forEach((element) {
    print("loop with method 1:current element is $element");
  });
// Set对象遍历 方式2
  for (var element in users) {
    print("loop with method 2:current element is $element");
  }
}
```

对Set进行修改操作时，需要注意，一个Set的元素是可变的，如果将Set赋值给一个变量，这变量持有的并不是这个Set的Copy而是这个Set的引用，需要手动调用`toSet()`方法创建Set的副本：

```dart
void main() {
  final Set<String> users = {"czyt", "rob"};
  // correct way
  var forkUser = users.toSet();
  // wrong way
  // var forkUser = users;
  forkUser.clear();
  print(forkUser);
  print(users);
}
```
Set的交集和并集，分别使用`intersection`和`union`方法。

```dart
Set langSet = {'Dart', 'Kotlin', 'Swift'};
Set sdkSet = {'Flutter', 'Android', 'iOS'};
langSet.addAll(['C#', 'Java']);
sdkSet.addAll(['C#', 'Xamarin']);

commonResult = langSet.intersection(sdkSet);
print(commonResult); 

unionResult = langSet.union(sdkSet);
print(unionResult);
```

### Map

![image-20230523114343214](https://assets.czyt.tech/img/Dart-Map.png)

下面是一些Map操作的例子：

```dart
void main() {
  final Map<String, int> UserAges = {};
  UserAges["czyt"] = 20;
  print(UserAges);
  // {czyt: 20}
  UserAges["czyt"] = 18;
  UserAges["john"] = 12;
  print(UserAges);
  // {czyt: 18, john: 12}
  print(
      "property: isEmpty=> ${UserAges.isEmpty} Length: ${UserAges.length} CheckKey: ${UserAges.containsKey("czyt")}");
  // property: isEmpty=> false Length: 2
  UserAges.remove("czyt");
  print(UserAges);
  // {john: 12}

  UserAges["bill"] = 22;
  UserAges["lancy"] = 42;
  UserAges["bruce"] = 32;
  // 遍历
  for (var key in UserAges.keys) {
    print(UserAges[key]);
  }

  for (var entry in UserAges.entries) {
    print("entry: ${entry.key}: ${entry.value}");
  }
}

```

转换map为Json

```dart
import 'dart:convert';
void main() {
  final userMap = {
    'id': 1234,
    'name': 'John',
    'emails': [
      'john@example.com',
      'jhagemann@example.com',
    ],
  };
  var payload = jsonEncode(userMap);
  print(payload);
}
```
转换Json为Map
```dart
import 'dart:convert';

void main() {
  var payload =
      '{"id":1234,"name":"John","emails":["john@example.com","jhagemann@example.com"]}';

  dynamic user = jsonDecode(payload);
  if (user is Map<String, dynamic>) {
    print("you got a map:$user");
  } else {
    print("you did not get a map");
  }
}
```

### Iterable

Dart中的迭代器是任何可以让你循环浏览其元素的集合。用编程术语来讲，它是一个实现了Iterable接口的类。 

#### 迭代器转换为List

```dart
final myList = ['bread', 'cheese', 'milk'];
print(myList);
final reversedIterable = myList.reversed;
print(reversedIterable);
final reversedList = reversedIterable.toList();
print(reversedList);
```

#### 创建简单的迭代器

```dart
final myIterable = Iterable();
// Iterable<String> myIterable = ['red', 'blue', 'green'];
```

#### 访问元素

```dart
final thirdElement = myIterable.elementAt(2);
print(thirdElement);
    
final firstElement = myIterable.first;
final lastElement = myIterable.last;
print(firstElement);
print(lastElement);
```

#### 建立自己的迭代器

```dart
Iterable<int> hundredSquares() sync* {
  for (int i = 1; i <= 100; i++) {
    yield i * i;
  }
}
```

使用

```dart
final squares = hundredSquares();
for (int square in squares) {
  print(square);
}
```
自定义自己的迭代器逻辑：
```dart
class SquaredIterator implements Iterator<int> {
  int _index = 0;
  // 1
  @override
  bool moveNext() {
    _index++;
    return _index <= 100;
  }
  // 2
  @override
  int get current => _index * _index;
}
```
修改之前的代码：
```dart
class HundredSquares extends Iterable<int> {
  @override
  Iterator<int> get iterator => SquaredIterator();
}
```

## 高级话题

### Mixin

Mixin 是一种定义可在多个类层次结构中重用的代码的方法。它们旨在提供集体成员实现。要使用 mixin，请使用 with 关键字，后跟一个或多个 mixin 名称。以下示例显示了两个使用 mixins 的类：

```dart
class Musician extends Performer with Musical {
  // ···
}

class Maestro extends Person with Musical, Aggressive, Demented {
  Maestro(String maestroName) {
    name = maestroName;
    canConduct = true;
  }
}
```

要定义mixin，请使用 mixin 声明。在极少数情况下，您需要同时定义Mixin和类，您可以使用 mixin class 声明。mixin和 mixin 类不能有 extends 子句，并且不能声明任何生成构造函数。

```dart
mixin Musical {
  bool canPlayPiano = false;
  bool canCompose = false;
  bool canConduct = false;

  void entertainMe() {
    if (canPlayPiano) {
      print('Playing piano');
    } else if (canConduct) {
      print('Waving hands');
    } else {
      print('Humming to self');
    }
  }
}
```

有时你可能想限制可以使用混合的类型。例如，mixin 可能依赖于能够调用 mixin 未定义的方法。如以下示例所示，您可以通过使用 on 关键字指定所需的超类来限制mixin的使用：

```dart
class Musician {
  // ...
}
mixin MusicalPerformer on Musician {
  // ...
}
class SingerDancer extends Musician with MusicalPerformer {
  // ...
}
```

在前面的代码中，只有扩展或实现 Musician 类的类才能使用混入 MusicalPerformer 。因为 SingerDancer 扩展了 Musician ，所以 SingerDancer 可以混入 MusicalPerformer 。

另外的一个例子

```dart
class Animal {
  String name = "Animal";
  Animal(){
    print("I am Animal class constructor.");
  }
  Animal.namedConstructor(){
    print("This is parent animal named constructor.");
  }
  void showName(){
    print(this.name);
  }
  void eat(){
     print("Animals eat everything depending on what type it 
is.");
  }
}

class Dog {
  void canRun(){
    print("I can run.");
  }
}
class Cat extends Animal with Dog {//reusing another class
  //overriding parent constructor
  //although constructors are not inherited
  Cat() : super(){
    print("I am child cat class overriding super Animal class.");
  }
  Cat.namedCatConstructor() : super.namedConstructor(){
     print("The child cat named constructor overrides the parent 
animal named constructor.");
  }
  @override
  void showName(){
    print("Hi from cat.");
  }
  @override
  void eat(){
    super.eat();
    print("Cat doesn't eat vegetables..");
  }
}
main(List<String> arguments){
  var cat = Cat();
  cat.name = "Meaow";
  cat.showName();
  cat.eat();
  var anotherCat = Cat.namedCatConstructor();
  anotherCat.canRun();
}
```

输出

```
I am Animal class constructor.
I am child cat class overriding super Animal class.
Hi from cat.
Animals eat everything depending on what type it is.
Cat doesn't eat vegetables..
This is parent animal named constructor.
The child cat named constructor overrides the parent animal 
named constructor.
I can run.
```



#### `class` 、 `mixin` 还是 `mixin class` ？

mixin 声明定义了一个 mixin。 class 声明定义了一个类。 mixin class 声明定义了一个既可用作常规类又可用作mixin class 的类，具有相同的名称和相同的类型。

适用于class或mixin的任何限制也适用于mixin class：

+ Mixins 不能有 extends 或 with 子句，所以 mixin class 也不能。
+ 类不能有 on 子句，所以 mixin class 也不能。
#### abstract mixin class
您可以实现与混合类的 on 指令类似的行为。创建混入类 abstract 并定义其行为所依赖的抽象f方法：
```dart
abstract mixin class Musician {
  // No 'on' clause, but an abstract method that other types must define if 
  // they want to use (mix in or extend) Musician: 
  void playInstrument(String instrumentName);

  void playPiano() {
    playInstrument('Piano');
  }
  void playFlute() {
    playInstrument('Flute');
  }
}

class Virtuoso with Musician { // Use Musician as a mixin
  void playInstrument(String instrumentName) {
    print('Plays the $instrumentName beautifully');
  }  
} 

class Novice extends Musician { // Use Musician as a class
  void playInstrument(String instrumentName) {
    print('Plays the $instrumentName poorly');
  }  
} 
```
通过将 Musician mixin 声明为抽象的，您强制使用它的任何类型定义其行为所依赖的抽象方法。这类似于 on 指令如何通过指定该接口的超类来确保 mixin 可以访问它所依赖的任何接口。

### 接口

在Dart中，可以使用 `implements` 关键字来实现接口。接口本身是一个抽象类，不包含任何实现，只是定义了一组抽象方法和属性。实现接口的类必须实现接口中的所有方法和属性。

下面是一个简单的示例：

```dart
abstract class Runner {
  void run();
}

class Athlete implements Runner {
  @override
  void run() {
    print('Running fast');
  }
}

void main() {
  var athlete = Athlete();
  athlete.run();
}
```

在这个例子中， `Runner` 是一个接口，定义了一个 `run` 方法。`Athlete` 类实现了 `Runner` 接口，并重写了 `run` 方法。最后，我们创建了一个 `Athlete` 对象，并调用了 `run` 方法。

需要注意的是，如果 `Athlete` 没有实现 `Runner` 的所有抽象方法，则会导致编译错误。同时，Dart 中没有 `implements` 和 `extends` 关键字的多重继承。所以，如果你要实现多个接口，可以使用 `with` 关键字来实现混合式继承。

在Dart中，实现接口使用 `implements`，而继承使用 `extends`。区别在于：

- `extends` 用于类的继承，表示子类继承了父类的属性和方法，并且可以通过 `super` 关键字来引用父类的实现。
- `implements` 用于实现接口，表示类必须实现接口中定义的所有方法，这些方法在接口中只有声明而没有实现。

在实现接口时，同时可以继承一个类。如下所示：

```dart
class MyClass extends MySuperClass implements MyInterface {
  // class content
}
```

这里， `MyClass` 继承了 `MySuperClass` 类，同时也实现了 `MyInterface` 接口。需要注意的是，Dart 中没有 Java 中接口和类的区别那么大，所以抽象类在某些场景下可以替换接口的使用。但是，如果你需要保证某个类拥有某些方法，最好使用接口来进行限制和规范。

```dart
abstract class volume{
  //we can declare instance variable
  int age;
  void increase();
  void decrease();
  // a normal function
  void anyNormalFunction(int age){
    print("This is a normal function to know the $age.");
  }
}
class soundSystem extends volume{
  void increase(){
    print("Sound is up.");
  }
  void decrease(){
    print("Sound is down.");
  }
  //it is optional to override the normal function
  void anyNormalFunction(int age){
     print("This is a normal function to know how old the sound 
system is: $age.");
  }
}
```
另外一个抽象类的例子：

```dart
abstract class Mammal {
  void run();
  void walk();  void sound(){
    print("Mammals make sound");
  }
}
class Human implements Mammal {
  void run(){
    print("I am running.");
  }
  void walk(){
    print("I am walking");
  }
  void sound(){
    print("Humans make sound");
  }
}
main(List<String> arguments){
  var John = Human();
  print("John says: ");
  John.run();
  print("John says: ");
  John.walk();
  print("John makes no sound.");
  John.sound();
}
```



在Dart中抽象类有如下特点：

- 在一个抽象类中，我们可以使用普通的属性和方法。
- 方法overwrite是可选的。
- 我们可以在抽象类中定义实例变量。但抽象类本身不能被实例化。

下面这个例子，将一个普通的类作为接口进行使用：

```dart
class Vehicle {
  void steerTheVehicle() {
    print("The vehicle is moving.");
  }
}
class Engine {
  //in the interface
  final _name; //  final means single assignment and it must 
  //have an initializer as I use here
  //not in the interface, since it is a constructor
  Engine(this._name);
  String lessOilConsumption(){
    return "It consumes less oil.";
  }
}
class Car implements Vehicle, Engine{
  var _name;
  void steerTheVehicle() {
    print("The car is moving.");
  }
  String lessOilConsumption(){
    print("This model of car consumes less oil.");
  }
   void ridingExperience() => print("This car gives good ride, 
because it is an ${this._name}");
}
main(List<String> arguments){
  var car = Car();
  car._name = "Opel";
  print("Car name: ${car._name}");
  car.steerTheVehicle();
  car.lessOilConsumption();
  car.ridingExperience();
}
    
```

使用依赖注入可以帮助我们减少代码耦合性，提高可维护性。在Dart中，我们可以使用`get_it`这个第三方依赖注入库来实现依赖注入。

```
abstract class Shape {
  num getArea(); // 返回形状的面积
}
```

成员方法`getArea()`是抽象的，它只定义了方法名和返回类型。在接口中，无需给出具体的实现方法，只需要定义规范。具体的实现是由实现类来完成。

以下代码演示了如何使用`get_it`实现依赖注入：

```
import 'package:get_it/get_it.dart';

void main() {
  GetIt locator = GetIt.instance;

  // 注册一个实例，通过 locator.get() 获取
  locator.registerSingleton<Shape>(Rectangle());

  // 获取实例并使用
  Shape shape = locator.get<Shape>();
  print(shape.getArea()); // 输出矩形的面积
}

class Rectangle implements Shape {
  num width = 10;
  num height = 20;

  num getArea() {
    return width * height;
  }
}
```

以上例子中，我们定义了一个接口`Shape`和一个实现类`Rectangle`。然后我们使用`get_it`库来进行依赖注入，将`Rectangle`类的实例注册到`GetIt`实例中。在我们需要使用`Rectangle`类实例的时候，我们可以通过`GetIt`实例来获取相应的实例，从而完成依赖注入。

### 异步编程

TODO







