---
title: "Zig语言快速参考"
date: 2023-07-19
tags: ["zig"]
draft: false
---

本文使用AI自动翻译，[原文链接](https://ziglearn.org/)

# 第 0 章 - 入门

## 欢迎

Zig 是一种通用编程语言和工具链，用于维护健壮、最佳和可重用的软件。

警告：最新的主要版本是 0.10.1 - Zig 仍然是 1.0 之前的版本；仍然不建议在生产中使用，并且您可能会遇到编译器错误。

要遵循本指南，我们假设您已经：

- 先前的编程经验
- 对低级编程概念的一些理解

了解 C、C++、Rust、Go、Pascal 或类似语言将有助于遵循本指南。您应该有一个可用的编辑器、终端和互联网连接。本指南是非官方的，与 Zig Software Foundation 无关，旨在从一开始就按顺序阅读。

## Installation

本指南假设您使用 Zig 的主版本而不是最新的主要版本，这意味着从网站下载二进制文件或从源代码编译；您的包管理器中的 Zig 版本可能已过时。本指南不支持 Zig 0.10.1。

1. 从以下位置下载并提取 Zig 的预构建主二进制文件：

```
https://ziglang.org/download/
```

1. 将 Zig 添加到您的路径

   - linux, macos, bsd

     将 Zig 二进制文件的位置添加到 PATH 环境变量中。对于安装，请添加 export PATH=$PATH:~/zig 或类似于 /etc/profile（系统范围）或 $HOME/.profile。如果这些更改没有立即应用，请从 shell 运行该行。

   - 视窗

     a) 系统范围（admin powershell）

     ```powershell
     [Environment]::SetEnvironmentVariable(
        "Path",
        [Environment]::GetEnvironmentVariable("Path", "Machine") + ";C:\your-path\zig-windows-x86_64-your-version",
        "Machine"
     )
     ```

     b) 用户级别（powershell）

     ```powershell
     [Environment]::SetEnvironmentVariable(
        "Path",
        [Environment]::GetEnvironmentVariable("Path", "User") + ";C:\your-path\zig-windows-x86_64-your-version",
        "User"
     )
     ```

     关闭您的终端并创建一个新终端。

2. 使用 zig 版本验证您的安装。输出应该类似于

```
$ zig version
0.11.0-dev.2777+b95cdf0ae
```

1. （可选，第三方）要在编辑器中完成并转到定义，请从以下位置安装 Zig 语言服务器：

```
https://github.com/zigtools/zls/
```

1. （可选）加入 Zig 社区。

## 你好世界

创建一个名为 main.zig 的文件，其中包含以下内容：

```zig
const std = @import("std");

pub fn main() void {
    std.debug.print("Hello, {s}!\n", .{"World"});
}
```

###### （注意：确保您的文件使用空格进行缩进、LF 行结尾和 UTF-8 编码！）

使用 zig run main.zig 构建并运行它。在此示例中，你好，世界！将被写入 stderr，并假定永远不会失败。

# 第 1 章 - 基础知识

## 赋值语句

赋值具有以下语法：(const|var) 标识符[:类型] = 值。

- const 表示标识符是存储不可变值的常量。
- var 表示标识符是一个存储可变值的变量。
- :type 是标识符的类型注释，如果可以推断 value 的数据类型，则可以省略。

```zig
const constant: i32 = 5;  // signed 32-bit constant
var variable: u32 = 5000; // unsigned 32-bit variable

// @as performs an explicit type coercion
const inferred_constant = @as(i32, 5);
var inferred_variable = @as(u32, 5000);
```

常量和变量必须有一个值。如果无法给出已知值，则只要提供类型注释，就可以使用强制为任何类型的未定义值。

```zig
const a: i32 = undefined;
var b: u32 = undefined;
```

在可能的情况下，const 值优先于 var 值。

## 数组

数组用 [N]T 表示，其中 N 是数组中元素的数量，T 是这些元素的类型（即数组的子类型）。

对于数组文字，N 可以替换为 _ 以推断数组的大小。

```zig
const a = [5]u8{ 'h', 'e', 'l', 'l', 'o' };
const b = [_]u8{ 'w', 'o', 'r', 'l', 'd' };
```

要获取数组的大小，只需访问数组的 len 字段即可。

```zig
const array = [_]u8{ 'h', 'e', 'l', 'l', 'o' };
const length = array.len; // 5
```

## if语句

Zig 的基本 if 语句很简单，因为它只接受 bool 值（值为 true 或 false）。不存在真值或假值的概念。

这里我们将介绍测试。保存以下代码并使用 zig test file-name.zig 编译+运行它。我们将使用标准库中的 Expect 函数，如果给定值 false，这将导致测试失败。当测试失败时，将显示错误和堆栈跟踪。

```zig
const expect = @import("std").testing.expect;

test "if statement" {
    const a = true;
    var x: u16 = 0;
    if (a) {
        x += 1;
    } else {
        x += 2;
    }
    try expect(x == 1);
}
```

If 语句也可以用作表达式。

```zig
test "if statement expression" {
    const a = true;
    var x: u16 = 0;
    x += if (a) 1 else 2;
    try expect(x == 1);
}
```

## while语句

Zig 的 while 循环由三个部分组成 - 条件、块和 continue 表达式。

没有 continue 表达式。

```zig
test "while" {
    var i: u8 = 2;
    while (i < 100) {
        i *= 2;
    }
    try expect(i == 128);
}
```

用继续表达。

```zig
test "while with continue expression" {
    var sum: u8 = 0;
    var i: u8 = 1;
    while (i <= 10) : (i += 1) {
        sum += i;
    }
    try expect(sum == 55);
}
```

随着继续。

```zig
test "while with continue" {
    var sum: u8 = 0;
    var i: u8 = 0;
    while (i <= 3) : (i += 1) {
        if (i == 2) continue;
        sum += i;
    }
    try expect(sum == 4);
}
```

休息一下。

```zig
test "while with break" {
    var sum: u8 = 0;
    var i: u8 = 0;
    while (i <= 3) : (i += 1) {
        if (i == 2) break;
        sum += i;
    }
    try expect(sum == 1);
}
```

## for循环

for 循环用于迭代数组（以及其他类型，稍后讨论）。 for 循环遵循此语法。与 while 一样，for 循环也可以使用 break 和 continue。这里我们必须给 _ 赋值，因为 Zig 不允许我们拥有未使用的值。

```zig
test "for" {
    //character literals are equivalent to integer literals
    const string = [_]u8{ 'a', 'b', 'c' };

    for (string, 0..) |character, index| {
        _ = character;
        _ = index;
    }

    for (string) |character| {
        _ = character;
    }

    for (string, 0..) |_, index| {
        _ = index;
    }

    for (string) |_| {}
}
```

## 函数

所有函数参数都是不可变的 - 如果需要副本，用户必须显式制作一个。与使用蛇形命名法的变量不同，函数使用驼峰式命名法。这是声明和调用简单函数的示例。

```zig
fn addFive(x: u32) u32 {
    return x + 5;
}

test "function" {
    const y = addFive(0);
    try expect(@TypeOf(y) == u32);
    try expect(y == 5);
}
```

允许递归：

```zig
fn fibonacci(n: u16) u16 {
    if (n == 0 or n == 1) return n;
    return fibonacci(n - 1) + fibonacci(n - 2);
}

test "function recursion" {
    const x = fibonacci(10);
    try expect(x == 55);
}
```

当递归发生时，编译器不再能够计算出最大堆栈大小。这可能会导致不安全的行为——堆栈溢出。有关如何实现安全递归的详细信息将在以后介绍。

通过使用 _ 代替变量或 const 声明可以忽略值。这在全局范围内不起作用（即它仅在函数和块内部起作用），并且对于忽略从函数返回的值（如果不需要它们）非常有用。

```zig
_ = 10;
```

## defer

defer 用于在退出当前块时执行语句。

```zig
test "defer" {
    var x: i16 = 5;
    {
        defer x += 2;
        try expect(x == 5);
    }
    try expect(x == 7);
}
```

当单个块中有多个 defer 时，它们将以相反的顺序执行。

```zig
test "multi defer" {
    var x: f32 = 5;
    {
        defer x += 2;
        defer x /= 2;
    }
    try expect(x == 4.5);
}
```

## 错误

错误集就像一个枚举（稍后将详细介绍 Zig 的枚举），其中集合中的每个错误都是一个值。 Zig 也不例外；错误是值。让我们创建一个错误集。

```zig
const FileOpenError = error{
    AccessDenied,
    OutOfMemory,
    FileNotFound,
};
```

错误集强制其超集。

```zig
const AllocationError = error{OutOfMemory};

test "coerce error from a subset to a superset" {
    const err: FileOpenError = AllocationError.OutOfMemory;
    try expect(err == FileOpenError.OutOfMemory);
}
```

错误集类型和正常类型可以与 ! 组合起来。运算符形成错误联合类型。这些类型的值可能是错误值，也可能是正常类型的值。

让我们创建一个错误联合类型的值。这里使用了 catch，它后面跟着一个表达式，当它前面的值是错误时，就会计算该表达式。这里的 catch 用于提供后备值，但也可以是 noreturn - 返回的类型、 while (true) 等。

```zig
test "error union" {
    const maybe_error: AllocationError!u16 = 10;
    const no_error = maybe_error catch 0;

    try expect(@TypeOf(no_error) == u16);
    try expect(no_error == 10);
}
```

函数经常返回错误联合。这是一个使用 catch 的例子，其中 |err|语法接收错误的值。这称为有效负载捕获，并且在许多地方都有类似的使用。我们将在本章后面更详细地讨论它。旁注：某些语言对 lambda 使用类似的语法 - Zig 的情况并非如此。

```zig
fn failingFunction() error{Oops}!void {
    return error.Oops;
}

test "returning an error" {
    failingFunction() catch |err| {
        try expect(err == error.Oops);
        return;
    };
}
```

try x 是 x catch |err| 的快捷方式return err，通常用于不适合处理错误的地方。 Zig 的 try-catch 与其他语言中的 try-catch 无关。

```zig
fn failFn() error{Oops}!i32 {
    try failingFunction();
    return 12;
}

test "try" {
    var v = failFn() catch |err| {
        try expect(err == error.Oops);
        return;
    };
    try expect(v == 12); // is never reached
}
```

errdefer 的工作方式与 defer 类似，但仅当函数从 errdefer 块内出现错误返回时才执行。

```zig
var problems: u32 = 98;

fn failFnCounter() error{Oops}!void {
    errdefer problems += 1;
    try failingFunction();
}

test "errdefer" {
    failFnCounter() catch |err| {
        try expect(err == error.Oops);
        try expect(problems == 99);
        return;
    };
}
```

从函数返回的错误联合可以通过没有显式错误集来推断其错误集。该推断错误集包含该函数可能返回的所有可能的错误。

```zig
fn createFile() !void {
    return error.AccessDenied;
}

test "inferred error set" {
    //type coercion successfully takes place
    const x: error{AccessDenied}!void = createFile();

    //Zig does not let us ignore error unions via _ = x;
    //we must unwrap it with "try", "catch", or "if" by any means
    _ = x catch {};
}
```

错误集可以合并。

```zig
const A = error{ NotDir, PathNotFound };
const B = error{ OutOfMemory, PathNotFound };
const C = A || B;
```

anyerror 是全局错误集，由于它是所有错误集的超集，因此可以将任何错误集强制转换为它的值。一般应避免使用它。

## switch语句

Zig 的 switch 既可以用作语句，也可以用作表达式。所有分支的类型必须强制为正在切换的类型。所有可能的值必须有一个关联的分支 - 值不能被遗漏。案件不能转至其他分支机构。

switch 语句的示例。需要 else 来满足此开关的详尽性。

```zig
test "switch statement" {
    var x: i8 = 10;
    switch (x) {
        -1...1 => {
            x = -x;
        },
        10, 100 => {
            //special considerations must be made
            //when dividing signed integers
            x = @divExact(x, 10);
        },
        else => {},
    }
    try expect(x == 1);
}
```

这是前者，但作为一个 switch 表达式。

```zig
test "switch expression" {
    var x: i8 = 10;
    x = switch (x) {
        -1...1 => -x,
        10, 100 => @divExact(x, 10),
        else => x,
    };
    try expect(x == 1);
}
```

## 运行时安全

Zig 提供一定程度的安全性，在执行过程中可能会发现问题。安全功能可以保持开启或关闭。 Zig 有很多所谓的可检测非法行为的案例，这意味着在安全打开时非法行为会被捕获（引起恐慌），但在安全关闭时会导致未定义的行为。强烈建议用户在安全的情况下开发和测试他们的软件，尽管这会降低速度。

例如，运行时安全性可以保护您免受索引越界的影响。

```zig
test "out of bounds" {
    const a = [3]u8{ 1, 2, 3 };
    var index: u8 = 5;
    const b = a[index];
    _ = b;
}
test "out of bounds"...index out of bounds
.\tests.zig:43:14: 0x7ff698cc1b82 in test "out of bounds" (test.obj)
    const b = a[index];
             ^
```

用户可以使用内置函数@setRuntimeSafety 选择禁用当前块的运行时安全。

```zig
test "out of bounds, no safety" {
    @setRuntimeSafety(false);
    const a = [3]u8{ 1, 2, 3 };
    var index: u8 = 5;
    const b = a[index];
    _ = b;
}
```

某些构建模式的安全性已关闭（稍后讨论）。

## unreachable

unreachable 是向编译器发出的断言，表明该语句将无法到达。它可以用来告诉编译器分支是不可能的，然后优化器可以利用它。达到无法达到的程度是可检测到的非法行为。

由于它是 noreturn 类型，因此它与所有其他类型兼容。这里它强制为 u32。

```zig
test "unreachable" {
    const x: i32 = 1;
    const y: u32 = if (x == 2) 5 else unreachable;
    _ = y;
}
test "unreachable"...reached unreachable code
.\tests.zig:211:39: 0x7ff7e29b2049 in test "unreachable" (test.obj)
    const y: u32 = if (x == 2) 5 else unreachable;
                                      ^
```

这是在交换机中使用的不可达。

```zig
fn asciiToUpper(x: u8) u8 {
    return switch (x) {
        'a'...'z' => x + 'A' - 'a',
        'A'...'Z' => x,
        else => unreachable,
    };
}

test "unreachable switch" {
    try expect(asciiToUpper('a') == 'A');
    try expect(asciiToUpper('A') == 'A');
}
```

## 指针

Zig 中的普通指针不允许将 0 或 null 作为值。它们遵循语法 *T，其中 T 是子类型。

引用是通过 &variable 完成的，解除引用是通过variable.* 完成的。

```zig
fn increment(num: *u8) void {
    num.* += 1;
}

test "pointers" {
    var x: u8 = 1;
    increment(&x);
    try expect(x == 2);
}
```

尝试将 *T 设置为值 0 是可检测到的非法行为。

```zig
test "naughty pointer" {
    var x: u16 = 0;
    var y: *u8 = @intToPtr(*u8, x);
    _ = y;
}
test "naughty pointer"...cast causes pointer to be null
.\tests.zig:241:18: 0x7ff69ebb22bd in test "naughty pointer" (test.obj)
    var y: *u8 = @intToPtr(*u8, x);
                 ^
```

Zig 还有 const 指针，不能用来修改引用的数据。引用 const 变量将产生 const 指针。

```zig
test "const pointers" {
    const x: u8 = 1;
    var y = &x;
    y.* += 1;
}
error: cannot assign to constant
    y.* += 1;
        ^
```

A *T 强制转换为 *const T。

## 指针大小的整数

usize 和 isize 以无符号和有符号整数形式给出，其大小与指针相同。

```zig
test "usize" {
    try expect(@sizeOf(usize) == @sizeOf(*u8));
    try expect(@sizeOf(isize) == @sizeOf(*u8));
}
```

## 多项目指针

有时您可能有一个指向未知数量元素的指针。 [*]T 是这个问题的解决方案，其工作方式与 *T 类似，但也支持索引语法、指针算术和切片。与 *T 不同，它不能指向没有已知大小的类型。 *T 强制 [*]T。

这些许多指针可能指向任意数量的元素，包括 0 和 1。

## 切片

切片可以被认为是一对 [*]T（指向数据的指针）和一个 usize（元素计数）。它们的语法为 []T，其中 T 是子类型。当您需要操作任意数量的数据时，在 Zig 中大量使用切片。切片具有与指针相同的属性，这意味着也存在 const 切片。 For 循环也对切片进行操作。 Zig 中的字符串文字强制转换为 []const u8。

这里，语法 x[n..m] 用于从数组创建切片。这称为切片，并创建从 x[n] 开始到 x[m - 1] 结束的元素切片。本示例使用 const 切片作为切片指向的值不需要修改。

```zig
fn total(values: []const u8) usize {
    var sum: usize = 0;
    for (values) |v| sum += v;
    return sum;
}
test "slices" {
    const array = [_]u8{ 1, 2, 3, 4, 5 };
    const slice = array[0..3];
    try expect(total(slice) == 6);
}
```

当这些 n 和 m 值在编译时都已知时，切片实际上会生成一个指向数组的指针。这不是问题，因为指向数组的指针即 *[N]T 将强制为 []T。

```zig
test "slices 2" {
    const array = [_]u8{ 1, 2, 3, 4, 5 };
    const slice = array[0..3];
    try expect(@TypeOf(slice) == *const [3]u8);
}
```

当您想要切片到末尾时，也可以使用语法 x[n..]。

```zig
test "slices 3" {
    var array = [_]u8{ 1, 2, 3, 4, 5 };
    var slice = array[0..];
    _ = slice;
}
```

可以切片的类型有：数组、许多指针和切片。

## Enums

Zig 的枚举允许您定义具有一组受限命名值的类型。

让我们声明一个枚举。

```zig
const Direction = enum { north, south, east, west };
```

枚举类型可以具有指定的（整数）标记类型。

```zig
const Value = enum(u2) { zero, one, two };
```

Enum 的序数值从 0 开始。可以使用内置函数 @enumToInt 访问它们。

```zig
test "enum ordinal value" {
    try expect(@enumToInt(Value.zero) == 0);
    try expect(@enumToInt(Value.one) == 1);
    try expect(@enumToInt(Value.two) == 2);
}
```

值可以被覆盖，下一个值从那里继续。

```zig
const Value2 = enum(u32) {
    hundred = 100,
    thousand = 1000,
    million = 1000000,
    next,
};

test "set enum ordinal value" {
    try expect(@enumToInt(Value2.hundred) == 100);
    try expect(@enumToInt(Value2.thousand) == 1000);
    try expect(@enumToInt(Value2.million) == 1000000);
    try expect(@enumToInt(Value2.next) == 1000001);
}
```

可以将方法赋予枚举。它们充当可以使用点语法调用的命名空间函数。

```zig
const Suit = enum {
    clubs,
    spades,
    diamonds,
    hearts,
    pub fn isClubs(self: Suit) bool {
        return self == Suit.clubs;
    }
};

test "enum method" {
    try expect(Suit.spades.isClubs() == Suit.isClubs(.spades));
}
```

枚举也可以被赋予 var 和 const 声明。它们充当命名空间全局变量，它们的值与枚举类型的实例无关且不附加。

```zig
const Mode = enum {
    var count: u32 = 0;
    on,
    off,
};

test "hmm" {
    Mode.count += 1;
    try expect(Mode.count == 1);
}
```

## 结构体

结构是 Zig 最常见的复合数据类型，允许您定义可以存储一组固定命名字段的类型。 Zig 不保证结构体中字段在内存中的顺序或其大小。与数组一样，结构体也可以使用 T{} 语法整齐地构造。这是声明和填充结构的示例。

```zig
const Vec3 = struct { x: f32, y: f32, z: f32 };

test "struct usage" {
    const my_vector = Vec3{
        .x = 0,
        .y = 100,
        .z = 50,
    };
    _ = my_vector;
}
```

所有字段都必须指定一个值。

```zig
test "missing struct field" {
    const my_vector = Vec3{
        .x = 0,
        .z = 50,
    };
    _ = my_vector;
}
error: missing field: 'y'
    const my_vector = Vec3{
                        ^
```

字段可以被赋予默认值：

```zig
const Vec4 = struct { x: f32, y: f32, z: f32 = 0, w: f32 = undefined };

test "struct defaults" {
    const my_vector = Vec4{
        .x = 25,
        .y = -50,
    };
    _ = my_vector;
}
```

与枚举一样，结构也可以包含函数和声明。

结构体具有独特的属性，当给定一个指向结构体的指针时，在访问字段时会自动完成一级取消引用。请注意，在此示例中，如何在交换函数中访问 self.x 和 self.y，而无需取消引用 self 指针。

```zig
const Stuff = struct {
    x: i32,
    y: i32,
    fn swap(self: *Stuff) void {
        const tmp = self.x;
        self.x = self.y;
        self.y = tmp;
    }
};

test "automatic dereference" {
    var thing = Stuff{ .x = 10, .y = 20 };
    thing.swap();
    try expect(thing.x == 20);
    try expect(thing.y == 10);
}
```

## 联合 union

Zig 的联合允许您定义存储许多可能类型字段的一个值的类型；一次只能有一个字段处于活动状态。

裸联合类型没有保证的内存布局。因此，裸联合不能用于重新解释内存。访问联合体中未激活的字段是可检测到的非法行为。

```zig
const Result = union {
    int: i64,
    float: f64,
    bool: bool,
};

test "simple union" {
    var result = Result{ .int = 1234 };
    result.float = 12.34;
}
test "simple union"...access of inactive union field
.\tests.zig:342:12: 0x7ff62c89244a in test "simple union" (test.obj)
    result.float = 12.34;
           ^
```

标记联合是使用枚举来检测哪个字段处于活动状态的联合。这里我们再次使用有效负载捕获，打开联合的标签类型，同时捕获它包含的值。这里我们使用指针捕获；捕获的值是不可变的，但带有 |*value|语法我们可以捕获指向值的指针而不是值本身。这允许我们使用解引用来改变原始值。

```zig
const Tag = enum { a, b, c };

const Tagged = union(Tag) { a: u8, b: f32, c: bool };

test "switch on tagged union" {
    var value = Tagged{ .b = 1.5 };
    switch (value) {
        .a => |*byte| byte.* += 1,
        .b => |*float| float.* *= 2,
        .c => |*b| b.* = !b.*,
    }
    try expect(value.b == 3);
}
```

还可以推断标记联合的标记类型。这相当于上面的Tagged类型。

```zig
const Tagged = union(enum) { a: u8, b: f32, c: bool };
```

void 成员类型可以在语法中省略其类型。在这里，没有一个是 void 类型。

```zig
const Tagged2 = union(enum) { a: u8, b: f32, c: bool, none };
```

## 整数规则

Zig 支持十六进制、八进制和二进制整数文字。

```zig
const decimal_int: i32 = 98222;
const hex_int: u8 = 0xff;
const another_hex_int: u8 = 0xFF;
const octal_int: u16 = 0o755;
const binary_int: u8 = 0b11110000;
```

下划线也可以放置在数字之间作为视觉分隔符。

```zig
const one_billion: u64 = 1_000_000_000;
const binary_mask: u64 = 0b1_1111_1111;
const permissions: u64 = 0o7_5_5;
const big_address: u64 = 0xFF80_0000_0000_0000;
```

允许“整数加宽”，这意味着一种类型的整数可以强制转换为另一种类型的整数，前提是新类型可以容纳旧类型可以容纳的所有值。

```zig
test "integer widening" {
    const a: u8 = 250;
    const b: u16 = a;
    const c: u32 = b;
    try expect(c == a);
}
```

如果您存储在整数中的值无法强制转换为所需的类型，则可以使用 @intCast 显式从一种类型转换为另一种类型。如果给定的值超出目标类型的范围，则这是可检测到的非法行为。

```zig
test "@intCast" {
    const x: u64 = 200;
    const y = @intCast(u8, x);
    try expect(@TypeOf(y) == u8);
}
```

默认情况下，整数是不允许溢出的。溢出是可检测到的非法行为。有时，能够以明确定义的方式溢出整数是需要的行为。对于此用例，Zig 提供了溢出运算符。

| Normal Operator | 包裹操作符 |
| --------------- | ---------- |
| +               | +%         |
| -               | -%         |
| *               | *%         |
| +=              | +%=        |
| -=              | -%=        |
| *=              | *%=        |

```zig
test "well defined overflow" {
    var a: u8 = 255;
    a +%= 1;
    try expect(a == 0);
}
```

## float

Zig 的浮点数严格符合 IEEE 标准，除非使用 @setFloatMode(.Optimized)，这相当于 GCC 的 -ffast-math。浮点数强制为更大的浮点数类型。

```zig
test "float widening" {
    const a: f16 = 0;
    const b: f32 = a;
    const c: f128 = b;
    try expect(c == @as(f128, a));
}
```

浮点数支持多种文字。

```zig
const floating_point: f64 = 123.0E+77;
const another_float: f64 = 123.0;
const yet_another: f64 = 123.0e+77;

const hex_floating_point: f64 = 0x103.70p-5;
const another_hex_float: f64 = 0x103.70;
const yet_another_hex_float: f64 = 0x103.70P-5;
```

数字之间也可以放置下划线。

```zig
const lightspeed: f64 = 299_792_458.000_000;
const nanosecond: f64 = 0.000_000_001;
const more_hex: f64 = 0x1234_5678.9ABC_CDEFp-10;
```

整数和浮点数可以使用内置函数@intToFloat 和@floatToInt 进行转换。 @intToFloat 始终是安全的，而如果浮点值无法适合整数目标类型，则 @floatToInt 是可检测到的非法行为。

```zig
test "int-float conversion" {
    const a: i32 = 0;
    const b = @intToFloat(f32, a);
    const c = @floatToInt(i32, b);
    try expect(c == a);
}
```

## 标记块

Zig 中的块是表达式，可以给定标签，用于生成值。在这里，我们使用一个名为 blk 的标签。块产生值，这意味着它们可以用来代替值。空块 {} 的值是 void 类型的值。

```zig
test "labelled blocks" {
    const count = blk: {
        var sum: u32 = 0;
        var i: u32 = 0;
        while (i < 10) : (i += 1) sum += i;
        break :blk sum;
    };
    try expect(count == 45);
    try expect(@TypeOf(count) == u32);
}
```

这可以看作相当于C的i++。

```zig
blk: {
    const tmp = i;
    i += 1;
    break :blk tmp;
}
```

## 标记循环

可以给循环赋予标签，允许您中断并继续外循环。

```zig
test "nested continue" {
    var count: usize = 0;
    outer: for ([_]i32{ 1, 2, 3, 4, 5, 6, 7, 8 }) |_| {
        for ([_]i32{ 1, 2, 3, 4, 5 }) |_| {
            count += 1;
            continue :outer;
        }
    }
    try expect(count == 8);
}
```

## 循环作为表达式

与 return 一样，break 也接受一个值。这可用于从循环中产生一个值。 Zig 中的循环在循环上还有一个 else 分支，当循环未通过中断退出时，会对该分支进行求值。

```zig
fn rangeHasNumber(begin: usize, end: usize, number: usize) bool {
    var i = begin;
    return while (i < end) : (i += 1) {
        if (i == number) {
            break true;
        }
    } else false;
}

test "while loop expression" {
    try expect(rangeHasNumber(0, 10, 3));
}
```

## 选项（optional）

选项使用语法 ?T 并用于存储数据 null 或 T 类型的值。

```zig
test "optional" {
    var found_index: ?usize = null;
    const data = [_]i32{ 1, 2, 3, 4, 5, 6, 7, 8, 12 };
    for (data, 0..) |v, i| {
        if (v == 10) found_index = i;
    }
    try expect(found_index == null);
}
```

选项支持 orelse 表达式，该表达式在选项为 null 时起作用。这会将可选值展开为其子类型。

```zig
test "orelse" {
    var a: ?f32 = null;
    var b = a orelse 0;
    try expect(b == 0);
    try expect(@TypeOf(b) == f32);
}
```

.?是 orelse unreachable 的简写。当您知道可选值不可能为空，并且使用它来解包空值是可检测到的非法行为时，可以使用此方法。

```zig
test "orelse unreachable" {
    const a: ?f32 = 5;
    const b = a orelse unreachable;
    const c = a.?;
    try expect(b == c);
    try expect(@TypeOf(c) == f32);
}
```

有效负载捕获在很多地方都适用于选项，这意味着如果它非空，我们可以“捕获”它的非空值。

这里我们使用 if 可选的有效负载捕获； a 和 b 在这里是等价的。如果 (b) |值|捕获 b 的值（在 b 不为 null 的情况下），并使其可用作值。与联合示例中一样，捕获的值是不可变的，但我们仍然可以使用指针捕获来修改存储在 b 中的值。

```zig
test "if optional payload capture" {
    const a: ?i32 = 5;
    if (a != null) {
        const value = a.?;
        _ = value;
    }

    var b: ?i32 = 5;
    if (b) |*value| {
        value.* += 1;
    }
    try expect(b.? == 6);
}
```

并与 while：

```zig
var numbers_left: u32 = 4;
fn eventuallyNullSequence() ?u32 {
    if (numbers_left == 0) return null;
    numbers_left -= 1;
    return numbers_left;
}

test "while null capture" {
    var sum: u32 = 0;
    while (eventuallyNullSequence()) |value| {
        sum += value;
    }
    try expect(sum == 6); // 3 + 2 + 1
}
```

与非可选指针和可选切片类型相比，可选指针和可选切片类型不占用任何额外的内存。这是因为它们在内部使用指针的 0 值来表示 null。

这就是 Zig 中空指针的工作方式 - 在解引用之前必须将它们解包为非可选值，这样可以防止意外发生空指针解引用。

## Comptime

可以使用 comptime 关键字在编译时强制执行代码块。在此示例中，变量 x 和 y 是等效的。

```zig
test "comptime blocks" {
    var x = comptime fibonacci(10);
    _ = x;

    var y = comptime blk: {
        break :blk fibonacci(10);
    };
    _ = y;
}
```

整数文字的类型为 comptime_int。它们的特殊之处在于它们没有大小（它们不能在运行时使用！），并且它们具有任意精度。 comptime_int 值强制为任何可以容纳它们的整数类型。他们还强制浮动。字符文字就是这种类型。

```zig
test "comptime_int" {
    const a = 12;
    const b = a + 10;

    const c: u4 = a;
    _ = c;
    const d: f32 = b;
    _ = d;
}
```

comptime_float 也可用，其内部为 f128。这些不能被强制为整数，即使它们包含整数值。

Zig 中的类型是类型 type 的值。这些在编译时可用。我们之前通过检查 @TypeOf 并与其他类型进行比较来遇到过它们，但我们可以做更多。

```zig
test "branching on types" {
    const a = 5;
    const b: if (a < 10) f32 else i32 = 5;
    _ = b;
}
```

Zig 中的函数参数可以标记为 comptime。这意味着传递给该函数参数的值必须在编译时已知。让我们创建一个返回类型的函数。请注意该函数如何采用 PascalCase，因为它返回一个类型。

```zig
fn Matrix(
    comptime T: type,
    comptime width: comptime_int,
    comptime height: comptime_int,
) type {
    return [height][width]T;
}

test "returning a type" {
    try expect(Matrix(f32, 4, 4) == [4][4]f32);
}
```

我们可以使用内置的 @typeInfo 来反映类型，它接受一个类型并返回一个标记的联合。这个标记的联合类型可以在 std.builtin.TypeInfo 中找到（稍后有关如何使用导入和 std 的信息）。

```zig
fn addSmallInts(comptime T: type, a: T, b: T) T {
    return switch (@typeInfo(T)) {
        .ComptimeInt => a + b,
        .Int => |info| if (info.bits <= 16)
            a + b
        else
            @compileError("ints too large"),
        else => @compileError("only ints accepted"),
    };
}

test "typeinfo switch" {
    const x = addSmallInts(u16, 20, 30);
    try expect(@TypeOf(x) == u16);
    try expect(x == 50);
}
```

我们可以使用 @Type 函数从 @typeInfo 创建类型。 @Type 已为大多数类型实现，但对于枚举、联合、函数和结构尤其未实现。

这里匿名结构体语法与.{}一起使用，因为T{}中的T可以被推断出来。稍后将详细介绍匿名结构。在此示例中，如果未设置 Int 标记，我们将收到编译错误。

```zig
fn GetBiggerInt(comptime T: type) type {
    return @Type(.{
        .Int = .{
            .bits = @typeInfo(T).Int.bits + 1,
            .signedness = @typeInfo(T).Int.signedness,
        },
    });
}

test "@Type" {
    try expect(GetBiggerInt(u8) == u9);
    try expect(GetBiggerInt(i31) == i32);
}
```

返回结构类型是在 Zig 中创建通用数据结构的方式。这里需要使用@This，它获取最里面的结构体、联合体或枚举的类型。这里还使用 std.mem.eql 来比较两个切片。

```zig
fn Vec(
    comptime count: comptime_int,
    comptime T: type,
) type {
    return struct {
        data: [count]T,
        const Self = @This();

        fn abs(self: Self) Self {
            var tmp = Self{ .data = undefined };
            for (self.data, 0..) |elem, i| {
                tmp.data[i] = if (elem < 0)
                    -elem
                else
                    elem;
            }
            return tmp;
        }

        fn init(data: [count]T) Self {
            return Self{ .data = data };
        }
    };
}

const eql = @import("std").mem.eql;

test "generic vector" {
    const x = Vec(3, f32).init([_]f32{ 10, -10, 5 });
    const y = x.abs();
    try expect(eql(f32, &y.data, &[_]f32{ 10, 10, 5 }));
}
```

还可以通过使用anytype 代替类型来推断函数参数的类型。然后可以在参数上使用@TypeOf。

```zig
fn plusOne(x: anytype) @TypeOf(x) {
    return x + 1;
}

test "inferred function parameter" {
    try expect(plusOne(@as(u32, 1)) == 2);
}
```

Comptime 还引入了运算符 ++ 和 ** 用于连接和重复数组和切片。这些运算符在运行时不起作用。

```zig
test "++" {
    const x: [4]u8 = undefined;
    const y = x[0..];

    const a: [6]u8 = undefined;
    const b = a[0..];

    const new = y ++ b;
    try expect(new.len == 10);
}

test "**" {
    const pattern = [_]u8{ 0xCC, 0xAA };
    const memory = pattern ** 3;
    try expect(eql(u8, &memory, &[_]u8{ 0xCC, 0xAA, 0xCC, 0xAA, 0xCC, 0xAA }));
}
```

## 有效负载捕获

有效负载捕获使用语法 |value|并出现在很多地方，其中一些我们已经见过。无论它们出现在哪里，它们都被用来“捕获”某物的价值。

带有 if 语句和选项。

```zig
test "optional-if" {
    var maybe_num: ?usize = 10;
    if (maybe_num) |n| {
        try expect(@TypeOf(n) == usize);
        try expect(n == 10);
    } else {
        unreachable;
    }
}
```

使用 if 语句和错误联合。这里需要带有错误捕获的 else 。

```zig
test "error union if" {
    var ent_num: error{UnknownEntity}!u32 = 5;
    if (ent_num) |entity| {
        try expect(@TypeOf(entity) == u32);
        try expect(entity == 5);
    } else |err| {
        _ = err catch {};
        unreachable;
    }
}
```

带有 while 循环和选项。这可能有一个 else 块。

```zig
test "while optional" {
    var i: ?u32 = 10;
    while (i) |num| : (i.? -= 1) {
        try expect(@TypeOf(num) == u32);
        if (num == 1) {
            i = null;
            break;
        }
    }
    try expect(i == null);
}
```

使用 while 循环和错误联合。这里需要带有错误捕获的 else 。

```zig
var numbers_left2: u32 = undefined;

fn eventuallyErrorSequence() !u32 {
    return if (numbers_left2 == 0) error.ReachedZero else blk: {
        numbers_left2 -= 1;
        break :blk numbers_left2;
    };
}

test "while error union capture" {
    var sum: u32 = 0;
    numbers_left2 = 3;
    while (eventuallyErrorSequence()) |value| {
        sum += value;
    } else |err| {
        try expect(err == error.ReachedZero);
    }
}
```

对于循环。

```zig
test "for capture" {
    const x = [_]i8{ 1, 5, 120, -5 };
    for (x) |v| try expect(@TypeOf(v) == i8);
}
```

在标记的联合上切换案例。

```zig
const Info = union(enum) {
    a: u32,
    b: []const u8,
    c,
    d: u32,
};

test "switch capture" {
    var b = Info{ .a = 10 };
    const x = switch (b) {
        .b => |str| blk: {
            try expect(@TypeOf(str) == []const u8);
            break :blk 1;
        },
        .c => 2,
        //if these are of the same type, they
        //may be inside the same capture group
        .a, .d => |num| blk: {
            try expect(@TypeOf(num) == u32);
            break :blk num * 2;
        },
    };
    try expect(x == 20);
}
```

正如我们在上面的 Union 和Optional 部分中看到的，使用 |val| 捕获的值语法是不可变的（类似于函数参数），但我们可以使用指针捕获来修改原始值。这将值捕获为本身仍然不可变的指针，但因为该值现在是一个指针，所以我们可以通过取消引用它来修改原始值：

```zig
test "for with pointer capture" {
    var data = [_]u8{ 1, 2, 3 };
    for (&data) |*byte| byte.* += 1;
    try expect(eql(u8, &data, &[_]u8{ 2, 3, 4 }));
}
```

## 内联循环

内联循环被展开，并允许发生一些仅在编译时起作用的事情。这里我们使用 for，但 while 的工作原理类似。

```zig
test "inline for" {
    const types = [_]type{ i32, f32, u8, bool };
    var sum: usize = 0;
    inline for (types) |T| sum += @sizeOf(T);
    try expect(sum == 10);
}
```

出于性能原因，不建议使用这些方法，除非您已经测试过显式展开速度更快；编译器在这里往往会比你做出更好的决定。

## opaque

Zig 中的opaque类型具有未知（尽管非零）的大小和对齐方式。因此，这些数据类型不能直接存储。这些用于通过指向我们没有信息的类型的指针来维护类型安全。

```zig
const Window = opaque {};
const Button = opaque {};

extern fn show_window(*Window) callconv(.C) void;

test "opaque" {
    var main_window: *Window = undefined;
    show_window(main_window);

    var ok_button: *Button = undefined;
    show_window(ok_button);
}
./test-c1.zig:653:17: error: expected type '*Window', found '*Button'
    show_window(ok_button);
                ^
./test-c1.zig:653:17: note: pointer type child 'Button' cannot cast into pointer type child 'Window'
    show_window(ok_button);
                ^
```

不透明类型可以在其定义中具有声明（与结构、枚举和联合相同）。

```zig
const Window = opaque {
    fn show(self: *Window) void {
        show_window(self);
    }
};

extern fn show_window(*Window) callconv(.C) void;

test "opaque with declarations" {
    var main_window: *Window = undefined;
    main_window.show();
}
```

opaque 的典型用例是在与不公开完整类型信息的 C 代码互操作时维护类型安全。

## 匿名结构（anonymous struct）

结构体字面量中可以省略结构体类型。这些文字可能会强制转换为其他结构类型。

```zig
test "anonymous struct literal" {
    const Point = struct { x: i32, y: i32 };

    var pt: Point = .{
        .x = 13,
        .y = 67,
    };
    try expect(pt.x == 13);
    try expect(pt.y == 67);
}
```

匿名结构可以是完全匿名的，即不会被强制为另一种结构类型。

```zig
test "fully anonymous struct" {
    try dump(.{
        .int = @as(u32, 1234),
        .float = @as(f64, 12.34),
        .b = true,
        .s = "hi",
    });
}

fn dump(args: anytype) !void {
    try expect(args.int == 1234);
    try expect(args.float == 12.34);
    try expect(args.b);
    try expect(args.s[0] == 'h');
    try expect(args.s[1] == 'i');
}
```

可以创建没有字段名称的匿名结构，并将其称为元组。它们具有数组的许多属性；元组可以迭代、索引、可以与 ++ 和 ** 运算符一起使用，并且有一个 len 字段。在内部，它们具有从“0”开始的编号字段名称，可以使用特殊语法@“0”进行访问，该语法充当语法的转义符 - @“”内的内容始终被识别为标识符。

必须使用内联循环来迭代此处的元组，因为每个元组字段的类型可能不同。

```zig
test "tuple" {
    const values = .{
        @as(u32, 1234),
        @as(f64, 12.34),
        true,
        "hi",
    } ++ .{false} ** 2;
    try expect(values[0] == 1234);
    try expect(values[4] == false);
    inline for (values, 0..) |v, i| {
        if (i != 2) continue;
        try expect(v);
    }
    try expect(values.len == 6);
    try expect(values.@"3"[0] == 'h');
}
```

## 哨兵终止（sentinel termination）

数组、切片和许多指针可以以其子类型的值终止。这称为哨兵终止。它们遵循语法 [N:t]T、[:t]T 和 [*:t]T，其中 t 是子类型 T 的值。

哨兵终止数组的示例。内置的@bitCast用于执行不安全的按位类型转换。这表明数组的最后一个元素后面跟着一个 0 字节。

```zig
test "sentinel termination" {
    const terminated = [3:0]u8{ 3, 2, 1 };
    try expect(terminated.len == 3);
    try expect(@ptrCast(*const [4]u8, &terminated)[3] == 0);
}
```

字符串文字的类型为 *const [N:0]u8，其中 N 是字符串的长度。这允许字符串文字强制到哨兵终止的切片，并且哨兵终止许多指针。注意：字符串文字是 UTF-8 编码的。

```zig
test "string literal" {
    try expect(@TypeOf("hello") == *const [5:0]u8);
}
```

[*:0]u8 和 [*:0]const u8 完美地模拟了 C 的字符串。

```zig
test "C string" {
    const c_string: [*:0]const u8 = "hello";
    var array: [5]u8 = undefined;

    var i: usize = 0;
    while (c_string[i] != 0) : (i += 1) {
        array[i] = c_string[i];
    }
}
```

哨兵终止类型强制其非哨兵终止对应类型。

```zig
test "coercion" {
    var a: [*:0]u8 = undefined;
    const b: [*]u8 = a;
    _ = b;

    var c: [5:0]u8 = undefined;
    const d: [5]u8 = c;
    _ = d;

    var e: [:10]f32 = undefined;
    const f = e;
    _ = f;
}
```

提供了哨兵终止切片，可用于使用语法 x[n..m:t] 创建哨兵终止切片，其中 t 是终止符值。这样做是程序员的断言，即内存在应有的位置终止 - 犯此错误是可检测到的非法行为。

```zig
test "sentinel terminated slicing" {
    var x = [_:0]u8{255} ** 3;
    const y = x[0..3 :0];
    _ = y;
}
```

## 向量

Zig 为 SIMD 提供矢量类型。这些不能与数学意义上的向量或 C++ 的 std::vector 之类的向量混为一谈（为此，请参阅第 2 章中的“Arraylist”）。向量可以使用我们之前使用过的内置@Type来创建，std.meta.Vector为此提供了一个简写。

向量只能有布尔值、整数、浮点数和指针的子类型。

具有相同子类型和长度的向量之间可以进行运算。这些操作对向量中的每个值执行。std.meta.eql 此处用于检查两个向量之间的相等性（对于结构等其他类型也很有用）。

```zig
const meta = @import("std").meta;
const Vector = meta.Vector;

test "vector add" {
    const x: Vector(4, f32) = .{ 1, -10, 20, -1 };
    const y: Vector(4, f32) = .{ 2, 10, 0, 1 };
    const z = x + y;
    try expect(meta.eql(z, Vector(4, f32){ 3, 0, 20, 0 }));
}
```

向量是可索引的。

```zig
test "vector indexing" {
    const x: Vector(4, u8) = .{ 255, 0, 255, 0 };
    try expect(x[0] == 255);
}
```

内置函数 @splat 可用于构造所有值都相同的向量。这里我们用它来将向量乘以标量。

```zig
test "vector * scalar" {
    const x: Vector(3, f32) = .{ 12.5, 37.5, 2.5 };
    const y = x * @splat(3, @as(f32, 2));
    try expect(meta.eql(y, Vector(3, f32){ 25, 75, 5 }));
}
```

向量没有像数组那样的 len 字段，但仍然可以循环。这里，std.mem.len 用作 @typeInfo(@TypeOf(x)).Vector.len 的快捷方式。

```zig
const len = @import("std").mem.len;

test "vector looping" {
    const x = Vector(4, u8){ 255, 0, 255, 0 };
    var sum = blk: {
        var tmp: u10 = 0;
        var i: u8 = 0;
        while (i < 4) : (i += 1) tmp += x[i];
        break :blk tmp;
    };
    try expect(sum == 510);
}
```

向量强制到它们各自的数组。

```zig
const arr: [4]f32 = @Vector(4, f32){ 1, 2, 3, 4 };
```

值得注意的是，如果您没有做出正确的决定，使用显式向量可能会导致软件速度变慢 - 编译器的自动向量化本身就相当智能。

## import

内置函数 @import 接受一个文件，并根据该文件为您提供一个结构类型。所有标记为 pub（公共）的声明都将最终在此结构类型中，可供使用。

@import("std") 是编译器中的一个特殊情况，它使您可以访问标准库。其他 @import 将接受文件路径或包名称（稍后的章节将详细介绍包）。

我们将在后面的章节中探索更多关于标准库的内容。

## 第一章结束

在下一章中，我们将介绍标准模式，包括标准库的许多有用领域。

欢迎提供反馈和 PR。

可以在此处找到自动生成的标准库文档。安装 ZLS 还可以帮助您探索标准库，它为其提供了补全。

# 第 2 章 - 标准模式

##  Allocators

Zig 标准库提供了一种分配内存的模式，它允许程序员准确选择标准库中如何完成内存分配 - 标准库中不会在您背后发生分配。

最基本的分配器是std.heap.page_allocator。每当这个分配器进行分配时，它都会向您的操作系统请求整个内存页；单个字节的分配可能会保留多个千字节。由于向操作系统请求内存需要系统调用，这对于速度来说也是极其低效的。

这里，我们分配 100 个字节作为 []u8。请注意 defer 如何与 free 结合使用 - 这是 Zig 中内存管理的常见模式。

```zig
const std = @import("std");
const expect = std.testing.expect;

test "allocation" {
    const allocator = std.heap.page_allocator;

    const memory = try allocator.alloc(u8, 100);
    defer allocator.free(memory);

    try expect(memory.len == 100);
    try expect(@TypeOf(memory) == []u8);
}
```

std.heap.FixedBufferAllocator 是一个分配器，它将内存分配到固定缓冲区中，并且不进行任何堆分配。当不需要堆使用时（例如编写内核时），这非常有用。出于性能原因也可以考虑它。如果字节用完，它将给您错误 OutOfMemory。

```zig
test "fixed buffer allocator" {
    var buffer: [1000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    const memory = try allocator.alloc(u8, 100);
    defer allocator.free(memory);

    try expect(memory.len == 100);
    try expect(@TypeOf(memory) == []u8);
}
```

std.heap.ArenaAllocator 接受一个子分配器，并允许您分配多次，并且只释放一次。这里，在 arena 上调用 .deinit() 来释放所有内存。在此示例中使用 allocator.free 将是无操作（即不执行任何操作）。

```zig
test "arena allocator" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    _ = try allocator.alloc(u8, 1);
    _ = try allocator.alloc(u8, 10);
    _ = try allocator.alloc(u8, 100);
}
```

alloc 和 free 用于切片。对于单个项目，请考虑使用创建和销毁。

```zig
test "allocator create/destroy" {
    const byte = try std.heap.page_allocator.create(u8);
    defer std.heap.page_allocator.destroy(byte);
    byte.* = 128;
}
```

Zig 标准库还有一个通用分配器。这是一个安全的分配器，可以防止双重释放、释放后使用并可以检测泄漏。可以通过其配置结构（下面留空）关闭安全检查和线程安全。 Zig 的 GPA 是为了安全而不是性能而设计的，但仍然可能比 page_allocator 快很多倍。

```zig
test "GPA" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const deinit_status = gpa.deinit();
        //fail test; can't try in defer as defer is executed after we return
        if (deinit_status == .leak) expect(false) catch @panic("TEST FAIL");
    }

    const bytes = try allocator.alloc(u8, 100);
    defer allocator.free(bytes);
}
```

为了高性能（但安全功能很少！），可以考虑 std.heap.c_allocator。然而，这有一个缺点，需要链接 Libc，这可以通过 -lc 来完成。

Benjamin Feng 的演讲《什么是内存分配器？》更详细地讨论这个主题，并涵盖分配器的实现。

## ArrayList

std.ArrayList 在整个 Zig 中普遍使用，并用作可以更改大小的缓冲区。 std.ArrayList(T) 类似于 C++ 的 std::vector<T> 和 Rust 的 Vec<T>。 deinit() 方法释放 ArrayList 的所有内存。可以通过其切片字段 - .items 读取和写入内存。

这里我们将介绍测试分配器的用法。这是一个特殊的分配器，仅在测试中起作用，并且可以检测内存泄漏。在您的代码中，使用任何合适的分配器。

```zig
const eql = std.mem.eql;
const ArrayList = std.ArrayList;
const test_allocator = std.testing.allocator;

test "arraylist" {
    var list = ArrayList(u8).init(test_allocator);
    defer list.deinit();
    try list.append('H');
    try list.append('e');
    try list.append('l');
    try list.append('l');
    try list.append('o');
    try list.appendSlice(" World!");

    try expect(eql(u8, list.items, "Hello World!"));
}
```

## 文件系统

让我们在当前工作目录中创建并打开一个文件，对其进行写入，然后从中读取。这里我们必须使用 .seekTo 以便在读取我们写入的内容之前返回到文件的开头。

```zig
test "createFile, write, seekTo, read" {
    const file = try std.fs.cwd().createFile(
        "junk_file.txt",
        .{ .read = true },
    );
    defer file.close();

    const bytes_written = try file.writeAll("Hello File!");
    _ = bytes_written;

    var buffer: [100]u8 = undefined;
    try file.seekTo(0);
    const bytes_read = try file.readAll(&buffer);

    try expect(eql(u8, buffer[0..bytes_read], "Hello File!"));
}
```

函数 std.fs.openFileAbsolute 和类似的绝对函数存在，但我们不会在这里测试它们。

我们可以通过对文件使用 .stat() 来获取有关文件的各种信息。 Stat 还包含 .inode 和 .mode 字段，但此处未测试它们，因为它们依赖于当前操作系统的类型。

```zig
test "file stat" {
    const file = try std.fs.cwd().createFile(
        "junk_file2.txt",
        .{ .read = true },
    );
    defer file.close();
    const stat = try file.stat();
    try expect(stat.size == 0);
    try expect(stat.kind == .File);
    try expect(stat.ctime <= std.time.nanoTimestamp());
    try expect(stat.mtime <= std.time.nanoTimestamp());
    try expect(stat.atime <= std.time.nanoTimestamp());
}
```

我们可以创建目录并迭代其内容。这里我们将使用迭代器（稍后讨论）。测试完成后，该目录（及其内容）将被删除。

```zig
test "make dir" {
    try std.fs.cwd().makeDir("test-tmp");
    const iter_dir = try std.fs.cwd().openIterableDir(
        "test-tmp",
        .{},
    );
    defer {
        std.fs.cwd().deleteTree("test-tmp") catch unreachable;
    }

    _ = try iter_dir.dir.createFile("x", .{});
    _ = try iter_dir.dir.createFile("y", .{});
    _ = try iter_dir.dir.createFile("z", .{});

    var file_count: usize = 0;
    var iter = iter_dir.iterate();
    while (try iter.next()) |entry| {
        if (entry.kind == .File) file_count += 1;
    }

    try expect(file_count == 3);
}
```

## Reader和Writer

std.io.Writer 和 std.io.Reader 提供了使用 IO 的标准方法。 std.ArrayList(u8) 有一个 writer 方法，它为我们提供了一个 writer。让我们使用它吧。

```zig
test "io writer usage" {
    var list = ArrayList(u8).init(test_allocator);
    defer list.deinit();
    const bytes_written = try list.writer().write(
        "Hello World!",
    );
    try expect(bytes_written == 12);
    try expect(eql(u8, list.items, "Hello World!"));
}
```

在这里，我们将使用读取器将文件的内容复制到分配的缓冲区中。 readAllAlloc 的第二个参数是它可以分配的最大大小；如果文件大于此，将返回error.StreamTooLong。

```zig
test "io reader usage" {
    const message = "Hello File!";

    const file = try std.fs.cwd().createFile(
        "junk_file2.txt",
        .{ .read = true },
    );
    defer file.close();

    try file.writeAll(message);
    try file.seekTo(0);

    const contents = try file.reader().readAllAlloc(
        test_allocator,
        message.len,
    );
    defer test_allocator.free(contents);

    try expect(eql(u8, contents, message));
}
```

读者的一个常见用例是阅读直到下一行（例如，用于用户输入）。在这里，我们将使用 std.io.getStdIn() 文件执行此操作。

```zig
fn nextLine(reader: anytype, buffer: []u8) !?[]const u8 {
    var line = (try reader.readUntilDelimiterOrEof(
        buffer,
        '\n',
    )) orelse return null;
    // trim annoying windows-only carriage return character
    if (@import("builtin").os.tag == .windows) {
        return std.mem.trimRight(u8, line, "\r");
    } else {
        return line;
    }
}

test "read until next line" {
    const stdout = std.io.getStdOut();
    const stdin = std.io.getStdIn();

    try stdout.writeAll(
        \\ Enter your name:
    );

    var buffer: [100]u8 = undefined;
    const input = (try nextLine(stdin.reader(), &buffer)).?;
    try stdout.writer().print(
        "Your name is: \"{s}\"\n",
        .{input},
    );
}
```

std.io.Writer 类型由上下文类型、错误集和写入函数组成。 write 函数必须接受上下文类型和字节片。 write 函数还必须返回 Writer 类型的错误集和写入的字节数的错误联合。让我们创建一个实现 writer 的类型。

```zig
// Don't create a type like this! Use an
// arraylist with a fixed buffer allocator
const MyByteList = struct {
    data: [100]u8 = undefined,
    items: []u8 = &[_]u8{},

    const Writer = std.io.Writer(
        *MyByteList,
        error{EndOfBuffer},
        appendWrite,
    );

    fn appendWrite(
        self: *MyByteList,
        data: []const u8,
    ) error{EndOfBuffer}!usize {
        if (self.items.len + data.len > self.data.len) {
            return error.EndOfBuffer;
        }
        std.mem.copy(
            u8,
            self.data[self.items.len..],
            data,
        );
        self.items = self.data[0 .. self.items.len + data.len];
        return data.len;
    }

    fn writer(self: *MyByteList) Writer {
        return .{ .context = self };
    }
};

test "custom writer" {
    var bytes = MyByteList{};
    _ = try bytes.writer().write("Hello");
    _ = try bytes.writer().write(" Writer!");
    try expect(eql(u8, bytes.items, "Hello Writer!"));
}
```

# 格式化

std.fmt 提供了将数据与字符串格式化的方法。

创建格式化字符串的基本示例。格式字符串必须在编译时已知。这里的 d 表示我们想要一个十进制数。

```zig
test "fmt" {
    const string = try std.fmt.allocPrint(
        test_allocator,
        "{d} + {d} = {d}",
        .{ 9, 10, 19 },
    );
    defer test_allocator.free(string);

    try expect(eql(u8, string, "9 + 10 = 19"));
}
```

作家可以方便地使用打印方法，其工作原理类似。

```zig
test "print" {
    var list = std.ArrayList(u8).init(test_allocator);
    defer list.deinit();
    try list.writer().print(
        "{} + {} = {}",
        .{ 9, 10, 19 },
    );
    try expect(eql(u8, list.items, "9 + 10 = 19"));
}
```

花点时间欣赏一下，您现在已经从上到下了解了打印 hello world 的工作原理。 std.debug.print 的工作原理相同，只是它写入 stderr 并受互斥体保护。

```zig
test "hello world" {
    const out_file = std.io.getStdOut();
    try out_file.writer().print(
        "Hello, {s}!\n",
        .{"World"},
    );
}
```

到目前为止，我们已经使用了 {s} 格式说明符来打印字符串。这里我们将使用 {any}，它为我们提供了默认格式。

```zig
test "array printing" {
    const string = try std.fmt.allocPrint(
        test_allocator,
        "{any} + {any} = {any}",
        .{
            @as([]const u8, &[_]u8{ 1, 4 }),
            @as([]const u8, &[_]u8{ 2, 5 }),
            @as([]const u8, &[_]u8{ 3, 9 }),
        },
    );
    defer test_allocator.free(string);

    try expect(eql(
        u8,
        string,
        "{ 1, 4 } + { 2, 5 } = { 3, 9 }",
    ));
}
```

让我们通过为其提供格式函数来创建具有自定义格式的类型。该函数必须标记为 pub，以便 std.fmt 可以访问它（稍后将详细介绍包）。您可能会注意到使用了 {s} 而不是 {} - 这是字符串的格式说明符（稍后将详细介绍格式说明符）。此处使用的 {} 默认为数组打印而不是字符串打印。

```zig
const Person = struct {
    name: []const u8,
    birth_year: i32,
    death_year: ?i32,
    pub fn format(
        self: Person,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;

        try writer.print("{s} ({}-", .{
            self.name, self.birth_year,
        });

        if (self.death_year) |year| {
            try writer.print("{}", .{year});
        }

        try writer.writeAll(")");
    }
};

test "custom fmt" {
    const john = Person{
        .name = "John Carmack",
        .birth_year = 1970,
        .death_year = null,
    };

    const john_string = try std.fmt.allocPrint(
        test_allocator,
        "{s}",
        .{john},
    );
    defer test_allocator.free(john_string);

    try expect(eql(
        u8,
        john_string,
        "John Carmack (1970-)",
    ));

    const claude = Person{
        .name = "Claude Shannon",
        .birth_year = 1916,
        .death_year = 2001,
    };

    const claude_string = try std.fmt.allocPrint(
        test_allocator,
        "{s}",
        .{claude},
    );
    defer test_allocator.free(claude_string);

    try expect(eql(
        u8,
        claude_string,
        "Claude Shannon (1916-2001)",
    ));
}
```

## JSON

让我们使用流解析器将 json 字符串解析为结构类型。

```zig
const Place = struct { lat: f32, long: f32 };

test "json parse" {
    var stream = std.json.TokenStream.init(
        \\{ "lat": 40.684540, "long": -74.401422 }
    );
    const x = try std.json.parse(Place, &stream, .{});

    try expect(x.lat == 40.684540);
    try expect(x.long == -74.401422);
}
```

并使用 stringify 将任意数据转换为字符串。

```zig
test "json stringify" {
    const x = Place{
        .lat = 51.997664,
        .long = -0.740687,
    };

    var buf: [100]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buf);
    var string = std.ArrayList(u8).init(fba.allocator());
    try std.json.stringify(x, .{}, string.writer());

    try expect(eql(u8, string.items,
        \\{"lat":5.19976654e+01,"long":-7.40687012e-01}
    ));
}
```

json 解析器需要 JavaScript 字符串、数组和映射类型的分配器。可以使用 std.json.parseFree 释放该内存。

```zig
test "json parse with strings" {
    var stream = std.json.TokenStream.init(
        \\{ "name": "Joe", "age": 25 }
    );

    const User = struct { name: []u8, age: u16 };

    const x = try std.json.parse(
        User,
        &stream,
        .{ .allocator = test_allocator },
    );

    defer std.json.parseFree(
        User,
        x,
        .{ .allocator = test_allocator },
    );

    try expect(eql(u8, x.name, "Joe"));
    try expect(x.age == 25);
}
```

## 随机数

这里我们使用 64 位随机种子创建一个新的 prng。 a、b、c 和 d 通过此 prng 被赋予随机值。给出 c 和 d 值的表达式是等效的。默认Prng是Xoroshiro128； std.rand 中还有其他可用的 prng。

```zig
test "random numbers" {
    var prng = std.rand.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.os.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    const rand = prng.random();

    const a = rand.float(f32);
    const b = rand.boolean();
    const c = rand.int(u8);
    const d = rand.intRangeAtMost(u8, 0, 255);

    //suppress unused constant compile error
    _ = .{ a, b, c, d };
}
```

还提供加密安全随机。

```zig
test "crypto random numbers" {
    const rand = std.crypto.random;

    const a = rand.float(f32);
    const b = rand.boolean();
    const c = rand.int(u8);
    const d = rand.intRangeAtMost(u8, 0, 255);

    //suppress unused constant compile error
    _ = .{ a, b, c, d };
}
```

## 加密

std.crypto 包含许多加密实用程序，包括：

- AES (Aes128, Aes256)
- Diffie-Hellman 密钥交换 (x25519)
- 椭圆曲线算术（curve25519、edwards25519、ristretto255）
- 加密安全哈希（blake2、Blake3、Gimli、Md5、sha1、sha2、sha3）
- MAC 函数（Gash、Poly1305）
- 流密码（ChaCha20IETF、ChaCha20With64BitNonce、XChaCha20IETF、Salsa20、XSalsa20）

该列表并不详尽。有关更深入的信息，请尝试 Zig 0.7.0 中的 std.crypto 之旅 - Frank Denis。

## 线程

Zig 提供了编写并发和并行代码的更高级方法，而 std.Thread 可用于利用操作系统线程。让我们使用操作系统线程。

```zig
fn ticker(step: u8) void {
    while (true) {
        std.time.sleep(1 * std.time.ns_per_s);
        tick += @as(isize, step);
    }
}

var tick: isize = 0;

test "threading" {
    var thread = try std.Thread.spawn(.{}, ticker, .{@as(u8, 1)});
    _ = thread;
    try expect(tick == 0);
    std.time.sleep(3 * std.time.ns_per_s / 2);
    try expect(tick == 1);
}
```

然而，如果没有线程安全策略，线程就不会特别有用。

## HashMap

标准库提供了std.AutoHashMap，它可以让您轻松地从键类型和值类型创建哈希映射类型。这些必须由分配器启动。

让我们将一些值放入哈希映射中。

```zig
test "hashing" {
    const Point = struct { x: i32, y: i32 };

    var map = std.AutoHashMap(u32, Point).init(
        test_allocator,
    );
    defer map.deinit();

    try map.put(1525, .{ .x = 1, .y = -4 });
    try map.put(1550, .{ .x = 2, .y = -3 });
    try map.put(1575, .{ .x = 3, .y = -2 });
    try map.put(1600, .{ .x = 4, .y = -1 });

    try expect(map.count() == 4);

    var sum = Point{ .x = 0, .y = 0 };
    var iterator = map.iterator();

    while (iterator.next()) |entry| {
        sum.x += entry.value_ptr.x;
        sum.y += entry.value_ptr.y;
    }

    try expect(sum.x == 10);
    try expect(sum.y == -10);
}
```

.fetchPut 将一个值放入哈希映射中，如果该键之前有一个值，则返回一个值。

```zig
test "fetchPut" {
    var map = std.AutoHashMap(u8, f32).init(
        test_allocator,
    );
    defer map.deinit();

    try map.put(255, 10);
    const old = try map.fetchPut(255, 100);

    try expect(old.?.value == 10);
    try expect(map.get(255).? == 100);
}
```

当您需要字符串作为键时，还提供了 std.StringHashMap。

```zig
test "string hashmap" {
    var map = std.StringHashMap(enum { cool, uncool }).init(
        test_allocator,
    );
    defer map.deinit();

    try map.put("loris", .uncool);
    try map.put("me", .cool);

    try expect(map.get("me").? == .cool);
    try expect(map.get("loris").? == .uncool);
}
```

std.StringHashMap 和 std.AutoHashMap 只是 std.HashMap 的包装器。如果这两个不能满足您的需求，直接使用 std.HashMap 可以为您提供更多控制。

如果需要让元素由数组支持，请尝试 std.ArrayHashMap 及其包装器 std.AutoArrayHashMap。

## 堆栈

std.ArrayList 提供了将其用作堆栈所需的方法。这是创建匹配括号列表的示例。

```zig
test "stack" {
    const string = "(()())";
    var stack = std.ArrayList(usize).init(
        test_allocator,
    );
    defer stack.deinit();

    const Pair = struct { open: usize, close: usize };
    var pairs = std.ArrayList(Pair).init(
        test_allocator,
    );
    defer pairs.deinit();

    for (string, 0..) |char, i| {
        if (char == '(') try stack.append(i);
        if (char == ')')
            try pairs.append(.{
                .open = stack.pop(),
                .close = i,
            });
    }

    for (pairs.items, 0..) |pair, i| {
        try expect(std.meta.eql(pair, switch (i) {
            0 => Pair{ .open = 1, .close = 2 },
            1 => Pair{ .open = 3, .close = 4 },
            2 => Pair{ .open = 0, .close = 5 },
            else => unreachable,
        }));
    }
}
```

## 排序

标准库提供了用于就地排序切片的实用程序。其基本用法如下。

```zig
test "sorting" {
    var data = [_]u8{ 10, 240, 0, 0, 10, 5 };
    std.sort.sort(u8, &data, {}, comptime std.sort.asc(u8));
    try expect(eql(u8, &data, &[_]u8{ 0, 0, 5, 10, 10, 240 }));
    std.sort.sort(u8, &data, {}, comptime std.sort.desc(u8));
    try expect(eql(u8, &data, &[_]u8{ 240, 10, 10, 5, 0, 0 }));
}
```

std.sort.asc 和 .desc 在 comptime 为给定类型创建比较函数；如果要对非数字类型进行排序，用户必须提供自己的比较函数。

std.sort.sort 的最佳情况为 O(n)，平均和最坏情况为 O(n*log(n))。

## Iterators

一个常见的习惯用法是，结构体类型中的 next 函数的返回类型中带有可选项，因此该函数可能会返回 null 来指示迭代已完成。

std.mem.SplitIterator（以及略有不同的 std.mem.TokenIterator）是此模式的一个示例。

```zig
test "split iterator" {
    const text = "robust, optimal, reusable, maintainable, ";
    var iter = std.mem.split(u8, text, ", ");
    try expect(eql(u8, iter.next().?, "robust"));
    try expect(eql(u8, iter.next().?, "optimal"));
    try expect(eql(u8, iter.next().?, "reusable"));
    try expect(eql(u8, iter.next().?, "maintainable"));
    try expect(eql(u8, iter.next().?, ""));
    try expect(iter.next() == null);
}
```

某些迭代器具有 !?T 返回类型，而不是 ?T。 !?T 要求我们在可选之前解压错误联合，这意味着为进入下一次迭代所做的工作可能会出错。下面是一个使用循环执行此操作的示例。必须使用迭代权限打开 cwd 才能使目录迭代器工作。

```zig
test "iterator looping" {
    var iter = (try std.fs.cwd().openIterableDir(
        ".",
        .{},
    )).iterate();

    var file_count: usize = 0;
    while (try iter.next()) |entry| {
        if (entry.kind == .File) file_count += 1;
    }

    try expect(file_count > 0);
}
```

这里我们将实现一个自定义迭代器。这将迭代字符串切片，生成包含给定字符串的字符串。

```zig
const ContainsIterator = struct {
    strings: []const []const u8,
    needle: []const u8,
    index: usize = 0,
    fn next(self: *ContainsIterator) ?[]const u8 {
        const index = self.index;
        for (self.strings[index..]) |string| {
            self.index += 1;
            if (std.mem.indexOf(u8, string, self.needle)) |_| {
                return string;
            }
        }
        return null;
    }
};

test "custom iterator" {
    var iter = ContainsIterator{
        .strings = &[_][]const u8{ "one", "two", "three" },
        .needle = "e",
    };

    try expect(eql(u8, iter.next().?, "one"));
    try expect(eql(u8, iter.next().?, "three"));
    try expect(iter.next() == null);
}
```

## 格式化选项

std.fmt 提供用于格式化各种数据类型的选项。

std.fmt.fmtSliceHexLower 和 std.fmt.fmtSliceHexUpper 提供字符串的十六进制格式以及整数的 {x} 和 {X} 格式。

```zig
const bufPrint = std.fmt.bufPrint;

test "hex" {
    var b: [8]u8 = undefined;

    _ = try bufPrint(&b, "{X}", .{4294967294});
    try expect(eql(u8, &b, "FFFFFFFE"));

    _ = try bufPrint(&b, "{x}", .{4294967294});
    try expect(eql(u8, &b, "fffffffe"));

    _ = try bufPrint(&b, "{}", .{std.fmt.fmtSliceHexLower("Zig!")});
    try expect(eql(u8, &b, "5a696721"));
}
```

{d} 对数字类型执行十进制格式化。

```zig
test "decimal float" {
    var b: [4]u8 = undefined;
    try expect(eql(
        u8,
        try bufPrint(&b, "{d}", .{16.5}),
        "16.5",
    ));
}
```

{c} 将字节格式化为 ascii 字符。

```zig
test "ascii fmt" {
    var b: [1]u8 = undefined;
    _ = try bufPrint(&b, "{c}", .{66});
    try expect(eql(u8, &b, "B"));
}
```

std.fmt.fmtIntSizeDec 和 std.fmt.fmtIntSizeBin 以基于公制 (1000) 和 2 的幂 (1024) 的表示法输出内存大小。

```zig
test "B Bi" {
    var b: [32]u8 = undefined;

    try expect(eql(u8, try bufPrint(&b, "{}", .{std.fmt.fmtIntSizeDec(1)}), "1B"));
    try expect(eql(u8, try bufPrint(&b, "{}", .{std.fmt.fmtIntSizeBin(1)}), "1B"));

    try expect(eql(u8, try bufPrint(&b, "{}", .{std.fmt.fmtIntSizeDec(1024)}), "1.024kB"));
    try expect(eql(u8, try bufPrint(&b, "{}", .{std.fmt.fmtIntSizeBin(1024)}), "1KiB"));

    try expect(eql(
        u8,
        try bufPrint(&b, "{}", .{std.fmt.fmtIntSizeDec(1024 * 1024 * 1024)}),
        "1.073741824GB",
    ));
    try expect(eql(
        u8,
        try bufPrint(&b, "{}", .{std.fmt.fmtIntSizeBin(1024 * 1024 * 1024)}),
        "1GiB",
    ));
}
```

{b} 和 {o} 以二进制和八进制格式输出整数。

```zig
test "binary, octal fmt" {
    var b: [8]u8 = undefined;

    try expect(eql(
        u8,
        try bufPrint(&b, "{b}", .{254}),
        "11111110",
    ));

    try expect(eql(
        u8,
        try bufPrint(&b, "{o}", .{254}),
        "376",
    ));
}
```

{*} 执行指针格式化，打印地址而不是值。

```zig
test "pointer fmt" {
    var b: [16]u8 = undefined;
    try expect(eql(
        u8,
        try bufPrint(&b, "{*}", .{@intToPtr(*u8, 0xDEADBEEF)}),
        "u8@deadbeef",
    ));
}
```

{e} 输出以科学记数法表示的浮点数。

```zig
test "scientific" {
    var b: [16]u8 = undefined;

    try expect(eql(
        u8,
        try bufPrint(&b, "{e}", .{3.14159}),
        "3.14159e+00",
    ));
}
```

{s} 输出字符串。

```zig
test "string fmt" {
    var b: [6]u8 = undefined;
    const hello: [*:0]const u8 = "hello!";

    try expect(eql(
        u8,
        try bufPrint(&b, "{s}", .{hello}),
        "hello!",
    ));
}
```

此列表并非详尽无遗。

## 高级格式化

到目前为止，我们只介绍了格式说明符。格式字符串实际上遵循这种格式，其中每对方括号之间是一个必须用某些内容替换的参数。

```
{[position][specifier]:[fill][alignment][width].[precision]}
```

| 姓名      | 意义                                                      |
| --------- | --------------------------------------------------------- |
| 位置      | 应插入的参数的索引                                        |
| Specifier | 依赖于类型的格式化选项                                    |
| 充满      | 用于填充的单个字符                                        |
| 结盟      | 三个字符“<”、“^”或“>”之一；这些用于左对齐、中对齐和右对齐 |
| 宽度      | 字段总宽度（字符）                                        |
| 精确      | 格式化数字应该有多少位小数                                |

职位使用。

```zig
test "position" {
    var b: [3]u8 = undefined;
    try expect(eql(
        u8,
        try bufPrint(&b, "{0s}{0s}{1s}", .{ "a", "b" }),
        "aab",
    ));
}
```

使用的填充、对齐和宽度。

```zig
test "fill, alignment, width" {
    var b: [6]u8 = undefined;

    try expect(eql(
        u8,
        try bufPrint(&b, "{s: <5}", .{"hi!"}),
        "hi!  ",
    ));

    try expect(eql(
        u8,
        try bufPrint(&b, "{s:_^6}", .{"hi!"}),
        "_hi!__",
    ));

    try expect(eql(
        u8,
        try bufPrint(&b, "{s:!>4}", .{"hi!"}),
        "!hi!",
    ));
}
```

精确地使用说明符。

```zig
test "precision" {
    var b: [4]u8 = undefined;
    try expect(eql(
        u8,
        try bufPrint(&b, "{d:.2}", .{3.14159}),
        "3.14",
    ));
}
```

## 第 2 章结束

本章不完整。未来它将包含以下内容：

- 任意精度数学
- 链表
- 队列
- 互斥体
- 原子学
- 搜寻中
- 记录

欢迎提供反馈和 PR。

# 第 3 章 - 构建系统

## 构建模式

Zig 提供四种构建模式，其中调试模式是默认模式，因为它产生最短的编译时间。

|          | 运行时安全 | 优化       |
| -------- | ---------- | ---------- |
| Debug    | 是的       | No         |
| 释放安全 | 是的       | 是的，速度 |
| 释放小   | No         | 是的，尺寸 |
| 快速发布 | No         | 是的，速度 |

这些可以在 zig run 和 zig test 中使用参数 -O ReleaseSafe、-O ReleaseSmall 和 -O ReleaseFast 启用。

建议用户开发启用运行时安全性的软件，尽管其速度劣势较小。

## 输出可执行文件

命令 zig build-exe、zig build-lib 和 zig build-obj 可分别用于输出可执行文件、库和对象。这些命令接受源文件和参数。

一些常见的论点：

- -fsingle-threaded，断言二进制文件是单线程的。这会将互斥锁等线程安全措施转变为无操作。
- -fstrip，从二进制文件中删除调试信息。
- --dynamic，与zig build-lib结合使用，输出动态/共享库。

让我们创建一个小小的你好世界。将其保存为tiny-hello.zig，然后运行zig build-exe .\tiny-hello.zig -O ReleaseSmall -fstrip -fsingle-threaded。目前，对于 x86_64-windows，这会生成 2.5KiB 的可执行文件。

```zig
const std = @import("std");

pub fn main() void {
    std.io.getStdOut().writeAll(
        "Hello World!",
    ) catch unreachable;
}
```

## 交叉编译

默认情况下，Zig 将针对您的 CPU 和操作系统组合进行编译。这可以被 -target 覆盖。让我们将我们的小 hello world 编译到 64 位 ARM Linux 平台。

```
zig build-exe .\tiny-hello.zig -O ReleaseSmall -fstrip -fsingle-threaded -target aarch64-linux
```

QEMU 或类似的可用于方便地测试为外国平台制作的可执行文件。

您可以交叉编译的一些 CPU 架构：

- `x86_64`
- `arm`
- `aarch64`
- `i386`
- `riscv64`
- `wasm32`

您可以针对某些操作系统进行交叉编译：

- `linux`
- `macos`
- `windows`
- `freebsd`
- `netbsd`
- `dragonfly`
- `UEFI`

许多其他目标可用于编译，但目前尚未经过充分测试。有关更多信息，请参阅 Zig 的支持表；经过充分测试的目标清单正在慢慢扩大。

由于 Zig 默认情况下针对您的特定 CPU 进行编译，因此这些二进制文件可能无法在 CPU 架构略有不同的其他计算机上运行。为了获得更好的兼容性，指定特定的基准 CPU 模型可能会很有用。注意：选择较旧的CPU架构会带来更好的兼容性，但也意味着你会错过较新的CPU指令；这里需要权衡效率/速度与兼容性。

让我们为 sandybridge CPU（Intel x86_64，大约 2011 年）编译一个二进制文件，这样我们就可以合理地确定拥有 x86_64 CPU 的人可以运行我们的二进制文件。在这里，我们可以使用本机代替我们的 CPU 或操作系统，以使用我们系统的。

```
zig build-exe .\tiny-hello.zig -target x86_64-native -mcpu sandybridge
```

有关哪些架构、操作系统、CPU 和 ABI 可用的详细信息（ABI 的详细信息将在下一章中介绍）可以通过运行 zig 目标来找到。注意：输出很长，您可能希望将其通过管道传输到文件，例如Zig 目标 > Targets.json。

## build.zig

zig build 命令允许用户基于 build.zig 文件进行编译。 zig init-exe 和 zig init-lib 可用于为您提供基线项目。

让我们在新文件夹中使用 zig init-exe。这就是你会发现的。

```
.
├── build.zig
└── src
    └── main.zig
```

build.zig 包含我们的构建脚本。构建运行程序将使用此 pub fn build 函数作为其入口点 - 这是运行 zig build 时执行的内容。

```zig
const Builder = @import("std").build.Builder;

pub fn build(b: *Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "init-exe",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    // This declares intent for the executable to be installed into the
    // standard location when the user invokes the "install" step (the default
    // step when running `zig build`).
    b.installArtifact(exe);

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
```

main.zig 包含可执行文件的入口点。

```zig
const std = @import("std");

pub fn main() anyerror!void {
    std.log.info("All your codebase are belong to us.", .{});
}
```

使用 zig build 命令后，可执行文件将出现在安装路径中。这里我们没有指定安装路径，因此可执行文件将保存在./zig-out/bin中。

# Builder

Zig 的 std.Build 类型包含构建运行程序使用的信息。这包括以下信息：

- 构建目标
- 释放模式
- 图书馆地点
- 安装路径
- 构建步骤

## 编译步骤

std.build.CompileStep 类型包含构建库、可执行文件、对象或测试所需的信息。

让我们利用 Builder 并使用 Builder.addExecutable 创建一个 CompileStep，它接受名称和源根目录的路径。

```zig
const Builder = @import("std").build.Builder;

pub fn build(b: *Builder) void {
    const exe = b.addExecutable(.{
        .name = "init-exe",
        .root_source_file = .{ .path = "src/main.zig" },
    });
    b.installArtifact(exe);
}
```

## 模块

Zig 构建系统具有模块的概念，模块是用 Zig 编写的其他源文件。让我们使用一个模块。

从新文件夹中运行以下命令。

```
zig init-exe
mkdir libs
cd libs
git clone https://github.com/Sobeston/table-helper.git
```

您的目录结构应如下所示。

```
.
├── build.zig
├── libs
│   └── table-helper
│       ├── example-test.zig
│       ├── README.md
│       ├── table-helper.zig
│       └── zig.mod
└── src
    └── main.zig
```

在新创建的 build.zig 中，添加以下行。

```zig
    const table_helper = b.addModule("table-helper", .{
        .source_file = .{ .path = "libs/table-helper/table-helper.zig" }
    });
    exe.addModule("table-helper", table_helper);
```

现在，当通过 zig build 运行时，main.zig 中的 @import 将使用字符串“table-helper”。这意味着 main 有 table-helper 包。包（std.build.Pkg 类型）还有一个 ?[]const Pkg 类型的依赖项字段，默认为 null。这允许您拥有依赖于其他包的包。

将以下内容放入 main.zig 中并运行 zig build run。

```zig
const std = @import("std");
const Table = @import("table-helper").Table;

pub fn main() !void {
    try std.io.getStdOut().writer().print("{}\n", .{
        Table(&[_][]const u8{ "Version", "Date" }){
            .data = &[_][2][]const u8{
                .{ "0.7.1", "2020-12-13" },
                .{ "0.7.0", "2020-11-08" },
                .{ "0.6.0", "2020-04-13" },
                .{ "0.5.0", "2019-09-30" },
            },
        },
    });
}
```

这应该将此表打印到您的控制台。

```
Version Date       
------- ---------- 
0.7.1   2020-12-13 
0.7.0   2020-11-08 
0.6.0   2020-04-13 
0.5.0   2019-09-30 
```

Zig 还没有官方的包管理器。然而，一些非官方的实验性包管理器确实存在，即 gyro 和 zigmod。 table-helper 包旨在支持它们两者。

一些查找软件包的好地方包括：astrolabe.pm、zpm、awesome-zig 和 GitHub 上的 zig 标签。

## 构建步骤

构建步骤是为构建运行程序提供执行任务的一种方式。让我们创建一个构建步骤，并将其设为默认值。当您运行 zig build 时，将输出 Hello!。

```zig
const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const step = b.step("task", "do something");
    step.makeFn = myTask;
    b.default_step = step;
}

fn myTask(self: *std.build.Step, progress: *std.Progress.Node) !void {
    std.debug.print("Hello!\n", .{});
    _ = progress;
    _ = self;
}
```

我们之前调用了 b.installArtifact(exe) - 这添加了一个构建步骤，告诉构建器构建可执行文件。

## 生成文档

Zig 编译器具有自动文档生成功能。可以通过将 -femit-docs 添加到 zig build-{exe, lib, obj} 或 zig run 命令来调用。该文档作为一个小型静态网站保存到 ./docs 中。

Zig 的文档生成使用与注释类似的文档注释，使用 /// 而不是 //，以及前面的全局变量。

在这里，我们将其保存为 x.zig 并使用 zig build-lib -femit-docs x.zig -target native-windows 为其构建文档。这里有一些东西需要注意：

- 只有带有文档评论的公开内容才会出现
- 可以使用空白文档注释
- 文档注释可以使用 Markdown 的子集
- 仅当编译器对其进行分析时，事物才会出现在生成的文档中；你可能需要强制进行分析才能让事情显现出来。

```zig
const std = @import("std");
const w = std.os.windows;

///**Opens a process**, giving you a handle to it. 
///[MSDN](https://docs.microsoft.com/en-us/windows/win32/api/processthreadsapi/nf-processthreadsapi-openprocess)
pub extern "kernel32" fn OpenProcess(
    ///[The desired process access rights](https://docs.microsoft.com/en-us/windows/win32/procthread/process-security-and-access-rights)
    dwDesiredAccess: w.DWORD,
    ///
    bInheritHandle: w.BOOL,
    dwProcessId: w.DWORD,
) callconv(w.WINAPI) ?w.HANDLE;

///spreadsheet position
pub const Pos = struct{
    ///row
    x: u32,
    ///column
    y: u32,
};

pub const message = "hello!";

//used to force analysis, as these things aren't otherwise referenced.
comptime {
    _ = OpenProcess;
    _ = Pos;
    _ = message;
}

//Alternate method to force analysis of everything automatically, but only in a test build:
test "Force analysis" {
    comptime {
        std.testing.refAllDecls(@This());
    }
}
```

当使用 build.zig 时，可以通过在 CompileStep 上将 emit_docs 字段设置为 .emit 来调用它。我们可以创建一个构建步骤来生成文档，如下所示，并使用 $ zig build docs 调用它。

```zig
const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const mode = b.standardReleaseOptions();

    const lib = b.addStaticLibrary("x", "src/x.zig");
    lib.setBuildMode(mode);
    lib.install();

    const tests = b.addTest("src/x.zig");
    tests.setBuildMode(mode);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&tests.step);

    //Build step to generate docs:
    const docs = b.addTest("src/x.zig");
    docs.setBuildMode(mode);
    docs.emit_docs = .emit;
    
    const docs_step = b.step("docs", "Generate docs");
    docs_step.dependOn(&docs.step);
}
```

这一代是实验性的，并且经常因复杂的例子而失败。这是由标准库文档使用的。

合并错误集时，最左侧错误集的文档字符串优先于右侧错误集的文档字符串。在本例中，C.PathNotFound 的文档注释是 A 中提供的文档注释。

```zig
const A = error{
    NotDir,

    /// A doc comment
    PathNotFound,
};
const B = error{
    OutOfMemory,

    /// B doc comment
    PathNotFound,
};

const C = A || B;
```

## 第三章结束

本章不完整。将来它将包含 zig build 的高级用法。

欢迎提供反馈和 PR。

# 第 4 章 - 使用 C

Zig 是从头开始设计的，将 C 互操作作为一流的功能。在本节中，我们将介绍其工作原理。

## ABI

ABI（应用程序二进制接口）是一个标准，涉及：

- 类型的内存布局（即类型的大小、对齐方式、偏移量及其字段的布局）
- 符号的链接器内命名（例如名称修改）
- 函数的调用约定（即函数调用如何在二进制级别工作）

通过定义这些规则并且不破坏它们，ABI 被认为是稳定的，并且可以用于例如将单独编译的多个库、可执行文件或对象可靠地链接在一起（可能在不同的计算机上或使用不同的编译器） 。这使得 FFI（外部函数接口）得以实现，我们可以在编程语言之间共享代码。

Zig 本身支持用于外部事物的 C ABI；使用哪种 C ABI 取决于您正在编译的目标（例如 CPU 架构、操作系统）。这允许与非 Zig 编写的代码进行近乎无缝的互操作； C ABI 的使用是编程语言中的标准。

Zig 内部不使用 ABI，这意味着代码应显式符合 C ABI，其中需要可重现和定义的二进制级行为。

## C 基本类型

Zig 提供特殊的 c_ 前缀类型以符合 C ABI。它们没有固定的大小，而是根据所使用的 ABI 改变大小。

| 类型         | 相当于C        | 最小大小（位） |
| ------------ | -------------- | -------------- |
| c_short      | 短的           | 16             |
| c_ushort     | 无符号短       | 16             |
| c_int        | int            | 16             |
| c_uint       | 无符号整数     | 16             |
| c_long       | 长的           | 32             |
| c_ulong      | 无符号长       | 32             |
| c_longlong   | 长长           | 64             |
| c_ulonglong  | 无符号longlong | 64             |
| c_longdouble | 长双           | N/A            |
| c_void       | 空白           | N/A            |

注意：C 的 void（以及 Zig 的 c_void）具有未知的非零大小。 Zig 的虚空是真正的零尺寸类型。

## 调用约定

调用约定描述了如何调用函数。这包括如何将参数提供给函数（即参数的位置 - 在寄存器中还是在堆栈上，以及如何提供），以及如何接收返回值。

在 Zig 中，可以将属性 callconv 赋予函数。可用的调用约定可以在 std.builtin.CallingConvention 中找到。这里我们使用 cdecl 调用约定。

```zig
fn add(a: u32, b: u32) callconv(.C) u32 {
    return a + b;
}
```

当您从 C 调用 Zig 时，使用 C 调用约定标记您的函数至关重要。

## 外部结构

Zig 中的普通结构没有定义的布局；当您希望结构的布局与 C ABI 的布局相匹配时，需要 extern 结构。

让我们创建一个外部结构。该测试应该在带有 gnu ABI 的 x86_64 上运行，这可以通过 -target x86_64-native-gnu 来完成。

```zig
const expect = @import("std").testing.expect;

const Data = extern struct { a: i32, b: u8, c: f32, d: bool, e: bool };

test "hmm" {
    const x = Data{
        .a = 10005,
        .b = 42,
        .c = -10.5,
        .d = false,
        .e = true,
    };
    const z = @ptrCast([*]const u8, &x);

    try expect(@ptrCast(*const i32, z).* == 10005);
    try expect(@ptrCast(*const u8, z + 4).* == 42);
    try expect(@ptrCast(*const f32, z + 8).* == -10.5);
    try expect(@ptrCast(*const bool, z + 12).* == false);
    try expect(@ptrCast(*const bool, z + 13).* == true);
}
```

这就是 x 值内的内存的样子。

| 场地  | a    | a    | a    | a    | b    |      |      |      | c    | c    | c    | c    | d    | e    |      |      |
| ----- | ---- | ---- | ---- | ---- | ---- | ---- | ---- | ---- | ---- | ---- | ---- | ---- | ---- | ---- | ---- | ---- |
| Bytes | 15   | 27   | 00   | 00   | 2A   | 00   | 00   | 00   | 00   | 00   | 28   | C1   | 00   | 01   | 00   | 00   |

请注意中间和末端有间隙 - 这称为“填充”。此填充中的数据是未定义的内存，并且不会始终为零。

由于我们的 x 值是 extern 结构体的值，因此我们可以安全地将其传递到需要 Data 的 C 函数中，前提是 C 函数也使用相同的 gnu ABI 和 CPU 架构进行编译。

## 内存对齐

由于电路原因，CPU 以特定倍数访问内存中的原始值。例如，这可能意味着 f32 值的地址必须是 4 的倍数，这意味着 f32 的对齐方式为 4。这种所谓的原始数据类型的“自然对齐”取决于 CPU 架构。所有对齐都是 2 的幂。

较大比对的数据还具有每个较小比对的比对；例如，对齐方式为 16 的值也具有对齐方式 8、4、2 和 1。

我们可以使用align(x)属性来制作特殊对齐的数据。在这里，我们正在使数据更加一致。

```zig
const a1: u8 align(8) = 100;
const a2 align(8) = @as(u8, 100);
```

并使数据的对齐程度较低。注意：创建较小对齐的数据并不是特别有用。

```zig
const b1: u64 align(1) = 100;
const b2 align(1) = @as(u64, 100);
```

与 const 一样，align 也是指针的属性。

```zig
test "aligned pointers" {
    const a: u32 align(8) = 5;
    try expect(@TypeOf(&a) == *align(8) const u32);
}
```

让我们使用一个需要对齐指针的函数。

```zig
fn total(a: *align(64) const [64]u8) u32 {
    var sum: u32 = 0;
    for (a) |elem| sum += elem;
    return sum;
}

test "passing aligned data" {
    const x align(64) = [_]u8{10} ** 64;
    try expect(total(&x) == 640);
}
```

## packed struct

默认情况下，Zig 中的所有结构字段都会自然地与 @alignOf(FieldType) （ABI 大小）对齐，但没有定义的布局。有时，您可能希望结构体字段的定义布局不符合您的 C ABI。打包结构允许您对结构字段进行极其精确的控制，允许您逐位放置字段。

在打包结构内部，Zig 的整数在空间中采用位宽（即 u12 的 @bitSizeOf 为 12，这意味着它将在打包结构中占用 12 位）。布尔值也占用 1 位，这意味着您可以轻松实现位标志。

```zig
const MovementState = packed struct {
    running: bool,
    crouching: bool,
    jumping: bool,
    in_air: bool,
};

test "packed struct size" {
    try expect(@sizeOf(MovementState) == 1);
    try expect(@bitSizeOf(MovementState) == 4);
    const state = MovementState{
        .running = true,
        .crouching = true,
        .jumping = true,
        .in_air = true,
    };
    _ = state;
}
```

目前，Zig 的打包结构存在一些长期存在的编译器错误，并且目前不适用于许多用例。

## 位对齐指针

与对齐指针类似，位对齐指针在其类型中具有额外信息，用于通知如何访问数据。当数据不是字节对齐时，这些是必需的。通常需要位对齐信息来寻址打包结构内部的字段。

```zig
test "bit aligned pointers" {
    var x = MovementState{
        .running = false,
        .crouching = false,
        .jumping = false,
        .in_air = false,
    };

    const running = &x.running;
    running.* = true;

    const crouching = &x.crouching;
    crouching.* = true;

    try expect(@TypeOf(running) == *align(1:0:1) bool);
    try expect(@TypeOf(crouching) == *align(1:1:1) bool);

    try expect(@import("std").meta.eql(x, .{
        .running = true,
        .crouching = true,
        .jumping = false,
        .in_air = false,
    }));
}
```

## C 指针

到目前为止，我们已经使用了以下类型的指针：

- 单个项目指针 - *T
- 许多项目指针 - [*]T
- 切片 - []T

与前面提到的指针不同，C 指针不能处理特殊对齐的数据，并且可能指向地址 0。C 指针在整数之间来回强制，也可以强制单项和多项指针。当值为 0 的 C 指针被强制为非可选指针时，这是可检测到的非法行为。

除了自动翻译的 C 代码之外，使用 [*c] 几乎总是一个坏主意，并且几乎不应该使用。

## Translate-C

Zig 提供命令 zig translate-c 用于从 C 源代码自动翻译。

使用以下内容创建文件 main.c。

```c
#include <stddef.h>

void int_sort(int* array, size_t count) {
    for (int i = 0; i < count - 1; i++) {
        for (int j = 0; j < count - i - 1; j++) {
            if (array[j] > array[j+1]) {
                int temp = array[j];
                array[j] = array[j+1];
                array[j+1] = temp;
            }
        }
    }
}
```

运行命令 zig translate-c main.c 将等效的 Zig 代码输出到控制台 (stdout)。您可能希望使用 zig translate-c main.c > int_sort.zig 将其通过管道传输到文件中（对 Windows 用户的警告：在 powershell 中进行管道传输将生成一个编码不正确的文件 - 使用编辑器来更正此问题）。

在另一个文件中，您可以使用 @import("int_sort.zig") 来使用此函数。

尽管translate-c 成功地将大多数C 代码转换为Zig，但目前生成的代码可能过于冗长。您可能希望在将 Zig 代码编辑为更惯用的代码之前使用 translate-c 生成 Zig 代码；在代码库中从 C 逐渐转移到 Zig 是受支持的用例。

## cImport

Zig 的 @cImport 内置函数的独特之处在于它接受一个表达式，而该表达式只能接受 @cInclude、@cDefine 和 @cUndef。这与translate-c 的工作原理类似，在底层将C 代码转换为Zig。

@cInclude 接受一个路径字符串，可以将路径添加到包含列表中。

@cDefine 和 @cUndef 定义和取消定义导入的内容。

这三个函数的工作方式与您期望它们在 C 代码中的工作方式完全一样。

与 @import 类似，它返回带有声明的结构类型。通常建议在应用程序中仅使用 @cImport 的一个实例，以避免符号冲突；一个 cImport 中生成的类型与另一 cImport 中生成的类型不同。

cImport 仅在链接 libc 时可用。

## 链接 libc

链接 libc 可以通过命令行通过 -lc 完成，或者通过 build.zig 使用 exe.linkLibC(); 完成。使用的 libc 是编译目标的 libc； Zig 为许多目标提供了 libc。

## Zig cc, Zig c++

Zig 可执行文件内嵌了 Clang，以及针对其他操作系统和架构进行交叉编译所需的库和标头。

这意味着 zig cc 和 zig c++ 不仅可以编译 C 和 C++ 代码（使用 Clang 兼容的参数），而且还可以在尊重 Zig 的目标三重参数的情况下这样做；您安装的单个 Zig 二进制文件能够为多个不同的目标进行编译，而无需安装多个版本的编译器或任何插件。使用 zig cc 和 zig c++ 还可以利用 Zig 的缓存系统来加快您的工作流程。

使用 Zig，人们可以轻松地为使用 C 和/或 C++ 编译器的语言构建交叉编译工具链。

一些野外例子：

- [使用zig cc将LuaJIT从x86_64-linux交叉编译到aarch64-linux](https://andrewkelley.me/post/zig-cc-powerful-drop-in-replacement-gcc-clang.html)
- [使用zig cc和zig c++结合cgo将hugo从aarch64-macos交叉编译到x86_64-linux，并具有完全静态链接](https://twitter.com/croloris/status/1349861344330330114)

## 第 4 章结束

本章不完整。未来它将包含以下内容：

- 从 Zig 调用 C 代码，反之亦然
- 使用混合了 C 和 Zig 代码的 Zig 构建

欢迎提供反馈和 PR。

# 第5章-Async

警告：当前版本的编译器尚不支持异步

## Async 

要充分理解 Zig 的异步，需要熟悉调用堆栈的概念。如果您以前没有听说过这一点，请查看维基百科页面。

传统的函数调用由三部分组成：

1. 使用其参数启动被调用函数，推送函数的堆栈帧
2. 将控制权转移到函数
3. 函数完成后，将控制权交还给调用者，检索函数的返回值并弹出函数的堆栈帧

使用 Zig 的异步函数，我们可以做更多的事情，控制权的转移是一个持续的双向对话（即我们可以将控制权交给函数并多次收回）。因此，在异步上下文中调用函数时必须特别注意；我们不能再像平常一样推送和弹出堆栈帧（因为堆栈是易失性的，并且当前堆栈帧“上方”的内容可能会被覆盖），而是显式存储异步函数的帧。虽然大多数人不会使用其完整功能集，但这种异步风格对于创建更强大的结构（例如事件循环）非常有用。

Zig 的异步风格可以描述为可挂起的无堆栈协程。 Zig 的异步与具有堆栈的操作系统线程之类的东西非常不同，并且只能由内核挂起。此外，Zig 的异步可以为您提供控制流结构和代码生成；异步并不意味着并行或线程的使用。

## 暂停/恢复

在上一节中，我们讨论了异步函数如何将控制权交还给调用者，以及异步函数如何稍后收回控制权。此功能由关键字 suspend 和resume 提供。当函数挂起时，控制流返回到上次恢复的地方；当通过异步调用调用函数时，这是隐式恢复。

这些示例中的注释指示了执行顺序。这里有几点需要注意：

- async 关键字用于调用异步上下文中的函数。
- async func() 返回函数的框架。
- 我们必须存储这个框架。
- resume 关键字在帧上使用，而 suspend 则在被调用函数中使用。

此示例有一个暂停，但没有匹配的恢复。

```zig
const expect = @import("std").testing.expect;

var foo: i32 = 1;

test "suspend with no resume" {
    var frame = async func(); //1
    _ = frame;
    try expect(foo == 2);     //4
}

fn func() void {
    foo += 1;                 //2
    suspend {}                //3
    foo += 1;                 //never reached!
}
```

在格式良好的代码中，每个挂起都与一个恢复相匹配。

```zig
var bar: i32 = 1;

test "suspend with resume" {
    var frame = async func2();  //1
    resume frame;               //4
    try expect(bar == 3);       //6
}

fn func2() void {
    bar += 1;                   //2
    suspend {}                  //3
    bar += 1;                   //5
}
```

## 异步/等待

与格式良好的代码在每次恢复时都会暂停类似，每个具有返回值的异步函数调用都必须与等待相匹配。异步帧上的等待产生的值对应于函数的返回。

您可能会注意到，这里的 func3 是一个普通函数（即它没有暂停点 - 它不是一个异步函数）。尽管如此，当从异步调用中调用时，func3 可以用作异步函数； func3 的调用约定不必更改为异步 - func3 可以是任何调用约定。

```zig
fn func3() u32 {
    return 5;
}

test "async / await" {
    var frame = async func3();
    try expect(await frame == 5);
}
```

在可能挂起的函数的异步帧上使用await只能从异步函数中实现。因此，在异步函数框架上使用await 的函数也被视为异步函数。如果您可以确定潜在的挂起不会发生，则 nosuspend wait 将阻止这种情况发生。

## 无暂停

当调用一个被确定为异步的函数（即它可能挂起）而没有异步调用时，调用它的函数也被视为异步。当确定具体（非异步）调用约定的函数具有挂起点时，这是一个编译错误，因为异步需要其自己的调用约定。例如，这意味着 main 不能是异步的。

```zig
pub fn main() !void {
    suspend {}
}
```

（从windows编译）

```
C:\zig\lib\zig\std\start.zig:165:1: error: function with calling convention 'Stdcall' cannot be async
fn WinStartup() callconv(.Stdcall) noreturn {
^
C:\zig\lib\zig\std\start.zig:173:65: note: async function call here
    std.os.windows.kernel32.ExitProcess(initEventLoopAndCallMain());
                                                                ^
C:\zig\lib\zig\std\start.zig:276:12: note: async function call here
    return @call(.{ .modifier = .always_inline }, callMain, .{});
           ^
C:\zig\lib\zig\std\start.zig:334:37: note: async function call here
            const result = root.main() catch |err| {
                                    ^
.\main.zig:12:5: note: suspends here
    suspend {}
    ^
```

如果您想在不使用异步调用的情况下调用异步函数，并且函数的调用者也不是异步的，则 nosuspend 关键字会派上用场。通过断言潜在的挂起不会发生，这允许异步函数的调用者也不是异步的。

```zig
const std = @import("std");

fn doTicksDuration(ticker: *u32) i64 {
    const start = std.time.milliTimestamp();

    while (ticker.* > 0) {
        suspend {}
        ticker.* -= 1;
    }

    return std.time.milliTimestamp() - start;
}

pub fn main() !void {
    var ticker: u32 = 0;
    const duration = nosuspend doTicksDuration(&ticker);
}
```

在上面的代码中，如果我们将ticker的值更改为大于0，这是可检测到的非法行为。如果我们运行该代码，我们将在安全构建模式下遇到这样的错误。与 Zig 中的其他非法行为类似，在不安全模式下发生这些行为将导致未定义的行为。

```
async function called in nosuspend scope suspended
.\main.zig:16:47: 0x7ff661dd3414 in main (main.obj)
    const duration = nosuspend doTicksDuration(&ticker);
                                              ^
C:\zig\lib\zig\std\start.zig:173:65: 0x7ff661dd18ce in std.start.WinStartup (main.obj)
    std.os.windows.kernel32.ExitProcess(initEventLoopAndCallMain());
                                                                ^
```

## 异步帧、挂起块

@Frame(function) 返回函数的帧类型。这适用于异步函数和没有特定调用约定的函数。

```zig
fn add(a: i32, b: i32) i64 {
    return a + b;
}

test "@Frame" {
    var frame: @Frame(add) = async add(1, 2);
    try expect(await frame == 3);
}
```

@frame() 返回指向当前函数的帧的指针。与挂起点类似，如果在函数中找到此调用，则将其推断为异步。所有指向帧的指针都强制转换为特殊类型anyframe，您可以在其上使用resume。

例如，这使我们能够编写一个可以自行恢复的函数。

```zig
fn double(value: u8) u9 {
    suspend {
        resume @frame();
    }
    return value * 2;
}

test "@frame 1" {
    var f = async double(1);
    try expect(nosuspend await f == 2);
}
```

或者，更有趣的是，我们可以用它来告诉其他函数恢复我们的工作。这里我们引入挂起块。进入挂起块后，异步函数已被视为挂起（即可以恢复）。这意味着我们可以通过除最后一个恢复程序之外的其他程序来恢复我们的功能。

```zig
const std = @import("std");

fn callLater(comptime laterFn: fn () void, ms: u64) void {
    suspend {
        wakeupLater(@frame(), ms);
    }
    laterFn();
}

fn wakeupLater(frame: anyframe, ms: u64) void {
    std.time.sleep(ms * std.time.ns_per_ms);
    resume frame;
}

fn alarm() void {
    std.debug.print("Time's Up!\n", .{});
}

test "@frame 2" {
    nosuspend callLater(alarm, 1000);
}
```

使用anyframe数据类型可以被认为是一种类型擦除，因为我们不再确定函数或函数框架的具体类型。这很有用，因为它仍然允许我们恢复框架 - 在很多代码中，我们不会关心细节，只想恢复它。这为我们提供了一个可用于异步逻辑的具体类型。

Anyframe 的天然缺点是我们丢失了类型信息，并且我们不再知道函数的返回类型是什么。这意味着我们不能等待任意帧。 Zig 对此的解决方案是anyframe->T 类型，其中T 是帧的返回类型。

```zig
fn zero(comptime x: anytype) x {
    return 0;
}

fn awaiter(x: anyframe->f32) f32 {
    return nosuspend await x;
}

test "anyframe->T" {
    var frame = async zero(f32);
    try expect(awaiter(&frame) == 0);
}
```

## 基本事件循环实现

事件循环是一种设计模式，其中事件被调度和/或等待。这意味着某种服务或运行时会在满足条件时恢复挂起的异步帧。这是 Zig 异步最强大、最有用的用例。

这里我们将实现一个基本的事件循环。这将允许我们提交要在给定时间内执行的任务。我们将使用它来提交成对的任务，这些任务将打印自程序启动以来的时间。这是输出的示例。

```
[task-pair b] it is now 499 ms since start!
[task-pair a] it is now 1000 ms since start!
[task-pair b] it is now 1819 ms since start!
[task-pair a] it is now 2201 ms since start!
```

这是实现。

```zig
const std = @import("std");

// used to get monotonic time, as opposed to wall-clock time
var timer: ?std.time.Timer = null;
fn nanotime() u64 {
    if (timer == null) {
        timer = std.time.Timer.start() catch unreachable;
    }
    return timer.?.read();
}

// holds the frame, and the nanotime of
// when the frame should be resumed
const Delay = struct {
    frame: anyframe,
    expires: u64,
};

// suspend the caller, to be resumed later by the event loop
fn waitForTime(time_ms: u64) void {
    suspend timer_queue.add(Delay{
        .frame = @frame(),
        .expires = nanotime() + (time_ms * std.time.ns_per_ms),
    }) catch unreachable;
}

fn waitUntilAndPrint(
    time1: u64,
    time2: u64,
    name: []const u8,
) void {
    const start = nanotime();

    // suspend self, to be woken up when time1 has passed
    waitForTime(time1);
    std.debug.print(
        "[{s}] it is now {} ms since start!\n",
        .{ name, (nanotime() - start) / std.time.ns_per_ms },
    );

    // suspend self, to be woken up when time2 has passed
    waitForTime(time2);
    std.debug.print(
        "[{s}] it is now {} ms since start!\n",
        .{ name, (nanotime() - start) / std.time.ns_per_ms },
    );
}

fn asyncMain() void {
    // stores the async frames of our tasks
    var tasks = [_]@Frame(waitUntilAndPrint){
        async waitUntilAndPrint(1000, 1200, "task-pair a"),
        async waitUntilAndPrint(500, 1300, "task-pair b"),
    };
    // |*t| is used, as |t| would be a *const @Frame(...)
    // which cannot be awaited upon
    for (tasks) |*t| await t;
}

// priority queue of tasks
// lower .expires => higher priority => to be executed before
var timer_queue: std.PriorityQueue(Delay, void, cmp) = undefined;
fn cmp(context: void, a: Delay, b: Delay) std.math.Order {
    _ = context;
    return std.math.order(a.expires, b.expires);
}

pub fn main() !void {
    timer_queue = std.PriorityQueue(Delay, void, cmp).init(
        std.heap.page_allocator, undefined
    );
    defer timer_queue.deinit();

    var main_task = async asyncMain();

    // the body of the event loop
    // pops the task which is to be next executed
    while (timer_queue.removeOrNull()) |delay| {
        // wait until it is time to execute next task
        const now = nanotime();
        if (now < delay.expires) {
            std.time.sleep(delay.expires - now);
        }
        // execute next task
        resume delay.frame;
    }

    nosuspend await main_task;
}
```

## 第五章结束

本章不完整，将来应该包含 std.event.Loop 和事件 IO 的使用。

欢迎提供反馈和 PR。