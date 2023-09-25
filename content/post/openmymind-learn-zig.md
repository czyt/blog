---
title: "学习zig【译】"
date: 2023-09-23
tags: ["zig"]
draft: false
---
> 原文链接 https://www.openmymind.net/learning_zig/ 采用Google翻译机翻整理

## 安装 Zig

Zig 的下载页面包括适用于常见平台的预编译二进制文件。在此页面上，您将找到最新开发版本以及主要版本的二进制文件。本指南跟踪的最新版本可以在页面顶部找到。

对于我的计算机，我将下载 zig-macos-aarch64-0.12.0-dev.161+6a5463951.tar.xz。您可能使用的是不同的平台或更新的版本。展开存档后，您应该有一个 `zig` 二进制文件（除了其他内容之外），您需要为其添加别名或添加到您的路径中；无论你习惯什么流程。

您现在应该能够运行 `zig zen` 和 `zig version` 来测试您的设置。

# 语言概述 - 第 1 部分

Zig 是一种强类型编译语言。它支持泛型，具有强大的编译时元编程功能，并且不包含垃圾收集器。许多人认为 Zig 是 C 的现代替代品。因此，该语言的语法与 C 类似。我们正在讨论以分号结尾的语句和大括号分隔的块。

Zig 代码如下所示：

```zig
const std = @import("std");

// This code won't compile if `main` isn't `pub` (public)
pub fn main() void {
	const user = User{
		.power = 9001,
		.name = "Goku",
	};

	std.debug.print("{s}'s power is {d}\n", .{user.name, user.power});
}

pub const User = struct {
	power: u64,
	name: []const u8,
};
```

如果将上述内容保存为learning.zig并运行 `zig run learning.zig` ，您应该看到： `Goku's power is 9001` 。

这是一个简单的示例，即使您是第一次看到 Zig，也可以遵循这个示例。尽管如此，我们还是要逐行讨论它。

请参阅安装 zig 部分以快速启动并运行。

## 导入包

很少有程序是作为单个文件编写的，没有标准库或外部库。我们的第一个程序也不例外，它使用 Zig 的标准库来打印我们的输出。 Zig 的导入系统非常简单，并且依赖于 `@import` 函数和 `pub` 关键字（使代码可以在当前文件外部访问）。

以 `@` 开头的函数是内置函数。它们是由编译器提供的，而不是标准库提供的。

我们通过指定模块名称来导入模块。 Zig 的标准库可使用“std”名称。要导入特定文件，我们使用其相对于执行导入的文件的路径。例如，如果我们将 `User` 结构移动到它自己的文件中，例如 models/user.zig：

```zig
// models/user.zig
pub const User = struct {
	power: u64,
	name: []const u8,
};
```

然后我们通过以下方式导入它：

```zig
// main.zig
const User = @import("models/user.zig").User;
```

如果我们的 `User` 结构未标记为 `pub` 我们会收到以下错误：“User”未标记为“pub”。

models/user.zig 可以导出不止一项内容。例如，我们还可以导出一个常量：

```zig
// models/user.zig
pub const MAX_POWER = 100_000;

pub const User = struct {
	power: u64,
	name: []const u8,
};
```

在这种情况下，我们可以导入两者：

```zig
const user = @import("models/user.zig");
const User = user.User;
const MAX_POWER = user.MAX_POWER
```

此时，您的问题可能多于答案。在上面的代码片段中， `user` 是什么？我们还没有看到它，但是如果我们使用 `var` 而不是 `const` 呢？或者您可能想知道如何使用第三方库。这些都是好问题，但要回答这些问题，我们首先需要更多地了解 Zig。现在我们必须对所学的内容感到满意：如何导入 Zig 的标准库、如何导入其他文件以及如何导出定义。

## 代码注释

Zig 示例的下一行是注释：

```zig
// This code won't compile if `main` isn't `pub` (public)
```

Zig 没有多行注释，如 C 的 `/* ... */` 。

对基于注释的自动文档生成有实验支持。如果您看过 Zig 的标准库文档，那么您就已经看到了它的实际效果。 `//!` 被称为顶级文档注释，可以放置在文件的顶部。三斜杠注释 ( `///` )，称为文档注释，可以放在特定位置，例如声明之前。如果您尝试在错误的位置使用任一类型的文档注释，您将收到编译器错误。

## 函数

我们的下一行代码是 `main` 函数的开始：

```zig
pub fn main() void
```

每个可执行文件都需要一个名为 `main` 的函数：它是程序的入口点。如果我们将 `main` 重命名为其他名称，例如 `doIt` ，并尝试运行 `zig run learning.zig` ，我们会收到一条错误消息，指出“learning”没有名为'main'的成员。

忽略 `main's` 作为我们程序入口点的特殊角色，它是一个非常基本的函数：它不接受任何参数，也不返回任何内容，又名 `void` 。下面的内容稍微有趣一些：

```zig
const std = @import("std");

pub fn main() void {
	const sum = add(8999, 2);
	std.debug.print("8999 + 2 = {d}\n", .{sum});
}

fn add(a: i64, b: i64) i64 {
	return a + b;
}
```

C 和 C++ 程序员会注意到 Zig 不需要前向声明，即 `add` 在定义之前调用。

接下来要注意的是 `i64` 类型：64 位有符号整数。其他一些数字类型有： `u8` 、 `i8` 、 `u16` 、 `i16` 、 `u32` 、 `i32` 、 `i47` 、 `u64` 、 `i64` 、 `f32` 和 `f64` .包含 `u47` 和 `i47` 并不是为了确保您仍然清醒。 Zig 支持任意位宽整数。尽管您可能不会经常使用它们，但它们可以派上用场。您经常使用的一种类型是 `usize` ，它是一个无符号指针大小的整数，通常是表示某物的长度/大小的类型。

除了 `f32` 和 `f64` 之外，Zig 还支持 `f16` 、 `f80` 和 `f128` 浮点类型。

虽然没有充分的理由这样做，但如果我们将 `add` 的实现更改为：

```zig
fn add(a: i64, b: i64) i64 {
	a += b;
	return a;
}
```

我们会在 `a += b;` 上收到错误：无法分配给常量。这是一个重要的教训，我们稍后将更详细地回顾：函数参数是常量。

为了提高可读性，没有函数重载（使用不同的参数类型和/或参数数量定义的同一函数）。现在，这就是我们需要了解的有关函数的全部内容。

## 结构体

下一行代码是创建 `User` ，这是在代码片段末尾定义的类型。 `User` 的定义是：

```zig
pub const User = struct {
	power: u64,
	name: []const u8,
};
```

由于我们的程序是单个文件，因此 `User` 仅在定义它的文件中使用，因此我们不需要将其设为 `pub` 。

结构字段以逗号终止，并且可以指定默认值：

```zig
pub const User = struct {
	power: u64 = 0,
	name: []const u8,
};
```

当我们创建一个结构体时，必须设置每个字段。例如，在原始定义中， `power` 没有默认值，以下内容将给出错误：missing struct field: power

```zig
const user = User{.name = "Goku"};
```

但是，使用我们的默认值，上面的代码可以正常编译。

结构可以有方法，它们可以包含声明（包括其他结构），甚至可能包含零个字段，此时它们的作用更像是命名空间。

```zig
pub const User = struct {
	power: u64 = 0,
	name: []const u8,

	pub const SUPER_POWER = 9000;

	fn diagnose(user: User) void {
		if (user.power >= SUPER_POWER) {
			std.debug.print("it's over {d}!!!", .{SUPER_POWER});
		}
	}
};
```

方法只是可以使用点语法调用的普通函数。这两者都有效：

```zig
// call diagnose on user
user.diagnose();

// The above is syntactical sugar for:
User.diagnose(user);
```

大多数时候您将使用点语法，但作为普通函数的语法糖的方法可能会派上用场。

`if` 语句是我们看到的第一个控制流。这很简单，对吧？我们将在下一部分中更详细地探讨这一点。

`diagnose` 在我们的 `User` 类型中定义，并接受 `User` 作为其第一个参数。因此，我们可以使用点语法来调用它。但结构内的函数不必遵循这种模式。一个常见的例子是使用 `init` 函数来启动我们的结构：

```zig
pub const User = struct {
	power: u64 = 0,
	name: []const u8,

	pub fn init(name: []const u8, power: u64) User {
		return User{
			.name = name,
			.power = power,
		};
	}
}
```

The use of `init` is merely a convention and in some cases `open` or some other name might make more sense. If you're like me and not a C++ programmer, the syntax to initalize fields, `.$field = $value,` might be a little odd, but you'll get used to it in no time.

当我们创建“Goku”时，我们将 `user` 变量声明为 `const` ：

```zig
const user = User{
	.power = 9001,
	.name = "Goku",
};
```

这意味着我们无法修改 `user` 。要修改变量，应使用 `var` 声明它。另外，您可能已经注意到 `user's` 类型是根据分配给它的内容推断出来的。我们可以明确地说：

```zig
const user: User = User{
	.power = 9001,
	.name = "Goku",
};
```

我们会看到必须明确变量类型的情况，但大多数时候，如果没有显式类型，代码会更具可读性。类型推断也以另一种方式工作。这相当于上面的两个片段：

```zig
const user: User = .{
	.power = 9001,
	.name = "Goku",
};
```

不过这种用法很不寻常。更常见的一个地方是从函数返回结构时。这里的类型可以从函数的返回类型推断出来。我们的 `init` 函数更可能写成这样：

```zig
pub fn init(name: []const u8, power: u64) User {
	// instead of return User{...}
	return .{
		.name = name,
		.power = power,
	};
}
```

与我们迄今为止探索的大多数内容一样，我们将来在讨论语言的其他部分时将重新审视结构。但是，在大多数情况下，它们都很简单。

## 数组和切片

我们可以掩盖代码的最后一行，但考虑到我们的小片段包含两个字符串“Goku”和“{s}'s power is {d}\n”，您可能对 Zig 中的字符串感到好奇。为了更好地理解字符串，让我们首先探索数组和切片。

数组的大小是固定的，其长度在编译时已知。长度是类型的一部分，因此 4 个有符号整数的数组 `[4]i32` 与 5 个有符号整数的数组 `[5]i32` 是不同的类型。

数组长度可以从初始化中推断出来。在以下代码中，所有三个变量的类型均为 `[5]i32` ：

```zig
const a = [5]i32{1, 2, 3, 4, 5};

// we already saw this .{...} syntax with structs
// it works with arrays too
const b: [5]i32 = .{1, 2, 3, 4, 5};

// use _ to let the compiler infer the length
const c = [_]i32{1, 2, 3, 4, 5};
```

另一方面，切片是指向具有长度的数组的指针。长度在运行时已知。我们将在后面的部分中讨论指针，但您可以将切片视为数组的视图。

如果您熟悉 Go，您可能已经注意到 Zig 中的切片有点不同：它们没有容量，只有指针和长度。

 鉴于以下情况，

```zig
const a = [_]i32{1, 2, 3, 4, 5};
const b = a[1..4];
```

我很高兴能够告诉您 `b` 是一个长度为 3 的切片，并且是一个指向 `a` 的指针。但是因为我们使用编译时已知的值“切片”数组，即 `1` 和 `4` ，所以我们的长度 `3` 在编译时也是已知的时间。 Zig 计算出了所有这些，因此 `b` 不是一个切片，而是一个指向长度为 3 的整数数组的指针。具体来说，它的类型是 `*const [3]i32` 。所以这次切片的表演被齐格的聪明挫败了。

在实际代码中，您可能会更多地使用切片而不是数组。无论好坏，程序往往具有比编译时信息更多的运行时信息。但在一个小例子中，我们必须欺骗编译器来得到我们想要的东西：

```zig
const a = [_]i32{1, 2, 3, 4, 5};
var end: usize = 4;
const b = a[1..end];
```

`b` 现在是一个正确的切片，具体来说它的类型是 `[]const i32` 。您可以看到切片的长度不是类型的一部分，因为长度是运行时属性，并且类型在编译时始终是完全已知的。创建切片时，我们可以省略上限以在要切片的任何内容（数组或切片）的末尾创建切片，例如 `const c = b[2..];` 。

如果我们将 `end` 声明为 `const` 那么它将成为编译时已知值，这将导致 `b` 因此创建了一个指向数组的指针，而不是切片。我觉得这有点令人困惑，但它并不是经常出现的东西，而且也不太难掌握。我很想在这一点上跳过它，但无法找到一种诚实的方法来避免这个细节。

学习 Zig 告诉我类型是非常具有描述性的。它不仅仅是一个整数或布尔值，甚至不仅仅是一个带符号的 32 位整数数组。类型还包含其他重要信息。我们已经讨论过长度是数组类型的一部分，并且许多示例都展示了常量性如何也是数组类型的一部分。例如，在我们的最后一个示例中， `b's` 类型是 `[]const i32` 。您可以使用以下代码亲自查看这一点：

```zig
const std = @import("std");

pub fn main() void {
	const a = [_]i32{1, 2, 3, 4, 5};
	var end: usize = 4;
	const b = a[1..end];
	std.debug.print("{any}", .{@TypeOf(b)});
}
```

如果我们尝试写入 `b` ，例如 `b[2] = 5;` ，我们会收到编译时错误：无法分配给常量。这是因为 `b's` 类型。

为了解决这个问题，您可能会想要进行以下更改：

```zig
// replace const with var
var b = a[1..end];
```

但你会得到同样的错误，为什么？作为提示，什么是 `b's` 类型，或者更一般地说，什么是 `b` ？切片是指向数组[一部分]的长度和指针。切片的类型始终派生自底层数组。无论 `b` 是否声明为 `const` ，底层数组的类型都是 `[5]const i32` ，因此 b 必须是 `[]const i32` 类型。如果我们希望能够写入 `b` ，我们需要将 `a` 从 `const` 更改为 `var` 。

```zig
const std = @import("std");

pub fn main() void {
	var a = [_]i32{1, 2, 3, 4, 5};
	var end: usize = 4;
	const b = a[1..end];
	b[2] = 99;
}
```

这是有效的，因为我们的切片不再是 `[]const i32` 而是 `[]i32` 。您可能有理由想知道为什么当 `b` 仍然是 `const` 时这会起作用。但是 `b` 的常量与 `b` 本身相关，而不是 `b` 指向的数据。好吧，我不确定这是一个很好的解释，但对我来说，这段代码突出了差异：

```zig
const std = @import("std");

pub fn main() void {
	var a = [_]i32{1, 2, 3, 4, 5};
	var end: usize = 4;
	const b = a[1..end];
	b = b[1..];
}
```

这不会编译；正如编译器告诉我们的，我们不能分配给常量。但如果我们完成了 `var b = a[1..end];` ，那么代码就会起作用，因为 `b` 本身不再是常量。

我们将在研究该语言的其他方面（尤其是字符串）的同时，发现有关数组和切片的更多信息。

## 字符串

我希望我可以说 Zig 有一个 `string` 类型，而且非常棒。不幸的是，事实并非如此，他们也不是。最简单的是，Zig 字符串是字节序列（即数组或切片）( `u8` )。我们实际上通过 `name` 字段的定义看到了这一点： `name: []const u8,` 。

按照惯例，并且仅按照惯例，此类字符串应仅包含 UTF-8 值，因为 Zig 源代码本身就是 UTF-8 编码的。但这并不是强制执行的，表示 ASCII 或 UTF-8 字符串的 `[]const u8` 与表示任意二进制数据的 `[]const u8` 之间实际上没有区别。怎么可能，他们是同一类型的。

根据我们对数组和切片的了解，您可以正确猜测 `[]const u8` 是字节常量数组的切片（其中字节是无符号 8 位整数）。但是我们的代码中没有任何地方对数组进行切片，甚至没有数组，对吧？我们所做的就是将“Goku”分配给 `user.name` 。那是如何运作的？

您在源代码中看到的字符串文字具有编译时已知的长度。编译器知道“Goku”的长度为 4。因此您可能会认为“Goku”最好由数组表示，例如 `[4]const u8` 。但字符串文字有几个特殊的属性。它们存储在二进制文件中的特殊位置并进行重复数据删除。因此，字符串文字的变量将是指向这个特殊位置的指针。这意味着“Goku”的类型更接近 `*const [4]u8` ，即指向 4 字节常量数组的指针。

还有更多。字符串文字以 null 结尾。也就是说，它们的末尾总是有一个 `\0` 。与 C 交互时，空终止字符串非常重要。在内存中，“Goku”实际上看起来像： `{'G', 'o', 'k', 'u', 0}` ，因此您可能认为类型是 `*const [5]u8` 。但这充其量是不明确的，更坏的是危险的（您可以覆盖空终止符）。相反，Zig 有一种独特的语法来表示以 null 结尾的数组。 “Goku”的类型为： `*const [4:0]u8` ，指向以 null 结尾的 4 字节数组的指针。在谈论字符串时，我们关注的是以 null 结尾的字节数组（因为这就是字符串在 C 中的典型表示方式），语法更通用： `[LENGTH:SENTINEL]` 其中“SENTINEL”是在以下位置找到的特殊值：数组的末尾。因此，虽然我想不出你为什么需要它，但以下内容是完全有效的：

```zig
const std = @import("std");

pub fn main() void {
	// an array of 3 booleans with false as the sentinel value
	const a = [3:false]bool{false, true, false};

	// This line is more advanced, and is not going to get explained!
	std.debug.print("{any}\n", .{std.mem.asBytes(&a).*});
}
```

其输出： `{ 0, 1, 0, 0}` 。

我犹豫是否要包含这个示例，因为最后一行非常高级，我不打算解释它。另一方面，如果您愿意的话，这是一个可以运行和使用的示例，可以更好地检查我们迄今为止讨论的一些内容。

如果我已经很好地解释了这一点，那么您可能仍然不确定一件事。如果“Goku”是 `*const [4:0]u8` ，我们为什么能够将它分配给 `name` 、 `[]const u8` ？答案很简单：Zig 会为您强制类型。它会在几种不同的类型之间执行此操作，但对于字符串来说最明显。这意味着如果函数具有 `[]const u8` 参数，或者结构体具有 `[]const u8` 字段，则可以使用字符串文字。因为空终止字符串是数组，并且数组具有已知的长度，所以这种强制转换很便宜，即它不需要迭代字符串来查找空终止符。

因此，当谈论字符串时，我们通常指的是 `[]const u8` 。必要时，我们显式声明一个以 null 结尾的字符串，它可以自动强制转换为 `[]const u8` 。但请记住， `[]const u8` 也用于表示任意二进制数据，因此，Zig 没有高级编程语言所具有的字符串概念。此外，Zig的标准库只有一个非常基本的unicode模块。

当然，在真实的程序中，大多数字符串（更一般地说，数组）在编译时是未知的。典型的例子是用户输入，在编译程序时是未知的。这是我们在谈论内存时必须重新讨论的问题。但简短的答案是，对于此类数据，在编译时其值未知，因此长度未知，我们将在运行时动态分配内存。我们的字符串变量（仍然是 `[]const u8` 类型）将是指向此动态分配的内存的切片。

## comptime 和anytype

在我们最后一行未探索的代码中，发生的事情比我们看到的要多得多：

```zig
std.debug.print("{s}'s power is {d}\n", .{user.name, user.power});
```

我们只是略过它，但它确实提供了一个机会来突出 Zig 的一些更强大的功能。这些是你至少应该了解的事情，即使你还没有掌握它们。

第一个是 Zig 的编译时执行概念，即 `comptime` 。这是 Zig 元编程功能的核心，顾名思义，它围绕在编译时而不是运行时运行代码。在本指南中，我们只会触及 `comptime` 可能实现的功能的表面，但它是始终存在的东西。

您可能想知道上面这行需要编译时执行的原因是什么。 `print` 函数的定义要求我们的第一个参数（字符串格式）是编译时已知的：

```zig
// notice the "comptime" before the "fmt" variable
pub fn print(comptime fmt: []const u8, args: anytype) void {
```

其原因是 `print` 会进行额外的编译时检查，这是大多数其他语言中不会进行的。什么样的检查？好吧，假设您将格式更改为 `"it's over {d}\n"` ，但保留了两个参数。你会得到一个编译时错误：‘it's over {d}’中未使用参数。它还会进行类型检查：将格式字符串更改为 `"{s}'s power is {s}\n"` ，您将得到类型“u64”的无效格式字符串“s”。如果编译时未知字符串格式，则无法在编译时执行这些检查。因此需要一个comptime已知的值。

The one place where `comptime` will immediately impact your coding is the default types for integer and float literals, the special `comptime_int` and `comptime_float`. This line of code isn't valid: `var i = 0;`. You'll get a compile-time error: *variable of type 'comptime_int' must be const or comptime*. `comptime` code can only work with data that is known at compile time and, for integers and floats, such data is identified by the special `comptime_int` and `comptime_float` types. A value of this type can be used in compile time execution. But you're likely not going to spend the majority of your time writing code for compile time execution, so it isn't a particularly useful default. What you'll need to do is give your variables an explicit type:

```zig
var i: usize = 0;
var j: f64 = 0;
```

注意，这个错误只发生在我们使用 `var` 之前。如果我们使用 `const` ，我们就不会遇到错误，因为错误的全部要点是 `comptime_int` 必须是 const。

在以后的部分中，我们将在探索泛型时更多地检查 comptime。

我们这行代码的另一个特别之处是奇怪的 `.{user.name, user.power}` ，从上面 `print` 的定义中，我们知道它映射到 `anytype` 类型的变量。这种类型不应与 Java 的 `Object` 或 Go 的 `any` （又名 `interface{}` ）等类型混淆。相反，在编译时，Zig 将专门为传递给它的所有类型创建 `print` 函数的版本。

这就引出了一个问题：我们要传递给它什么？当让编译器推断结构的类型时，我们之前已经见过 `.{...}` 表示法。这是相似的：它创建一个匿名结构文字。考虑这段代码：

```zig
pub fn main() void {
	std.debug.print("{any}\n", .{@TypeOf(.{.year = 2023, .month = 8})});
}
```

 打印：

```
struct{comptime year: comptime_int = 2023, comptime month: comptime_int = 8}
```

在这里，我们给出了匿名结构体字段名称 `year` 和 `month` 。在我们的原始代码中，我们没有。在这种情况下，字段名称会自动生成为“0”、“1”、“2”等。 `print` 函数需要具有此类字段的结构，并使用字符串格式中的序号位置来得到适当的论据。

Zig 没有函数重载，也没有 vardiadic 函数（具有任意数量参数的函数）。但它确实有一个编译器，能够根据传递的类型创建专门的函数，包括编译器本身推断和创建的类型。

# 语言概述 - 第 2 部分

这部分继续上一部分的内容：熟悉该语言。我们将探索 Zig 的控制流和结构之外的类型。连同第一部分，我们将涵盖该语言的大部分语法，使我们能够处理更多该语言和标准库的内容。

##  控制流

Zig 的控制流程可能很熟悉，但与我们尚未探索的语言的某些方面有额外的协同作用。我们将从控制流的快速概述开始，然后在讨论引起特殊控制流行为的功能时回来。

您会注意到，我们使用 `and` 和 `or` 代替逻辑运算符 `&&` 和 `||` 。与大多数语言一样， `and` 和 `or` 控制执行流程：它们短路。如果左侧为 `false` ，则不评估 `and` 的右侧；如果左侧为 `or` ，则不评估右侧是 `true` 。在 Zig 中，控制流是通过关键字完成的，因此使用 `and` 和 `or` 。

此外，比较运算符 `==` 在切片之间不起作用，例如 `[]const u8` （即字符串）。在大多数情况下，您将使用 `std.mem.eql(u8, str1, str2)` 来比较两个切片的长度和字节。

Zig 的 `if` 、 `else if` 和 `else` 很常见：

```zig
// std.mem.eql does a byte-by-byte comparison
// for a string it'll be case sensitive
if (std.mem.eql(u8, method, "GET") or std.mem.eql(u8, method, "HEAD")) {
	// handle a GET request
} else if (std.mem.eql(u8, method, "POST")) {
	// handle a POST request
} else {
	// ...
}
```

`std.mem.eql` 的第一个参数是类型，在本例中为 `u8` 。这是我们看到的第一个通用函数。我们将在后面的部分中对此进行更多探讨。

上面的示例是比较 ASCII 字符串，并且应该不区分大小写。 `std.ascii.eqlIgnoreCase(str1, str2)` 可能是更好的选择。

没有三元运算符，但您可以使用 `if/else` ，如下所示：

```zig
const super = if (power > 9000) true else false;
```

`switch` 与 if/else if/else 类似，但具有详尽的优点。也就是说，如果未涵盖所有情况，则会出现编译时错误。此代码将无法编译：

```zig
fn anniversaryName(years_married: u16) []const u8 {
	switch (years_married) {
		1 => return "paper",
		2 => return "cotton",
		3 => return "leather",
		4 => return "flower",
		5 => return "wood",
		6 => return "sugar",
	}
}
```

我们被告知：switch 必须处理所有可能性。由于我们的 `years_married` 是一个 16 位整数，这是否意味着我们需要处理所有 64K 的情况？是的，但幸运的是有一个 `else` ：

```zig
// ...
6 => return "sugar",
else => return "no more gifts for you",
```

我们可以组合多个案例或使用范围，并针对复杂情况使用块：

```zig
fn arrivalTimeDesc(minutes: u16, is_late: bool) []const u8 {
	switch (minutes) {
		0 => return "arrived",
		1, 2 => return "soon",
		3...5 => return "no more than 5 minutes",
		else => {
			if (!is_late) {
				return "sorry, it'll be a while";
			}
			// todo, something is very wrong
			return "never";
		},
	}
}
```

虽然 `switch` 在许多情况下都很有用，但在处理枚举时，它的详尽性确实很出色，我们稍后会讨论这一点。

Zig 的 `for` 循环用于迭代数组、切片和范围。例如，要检查数组是否包含值，我们可以编写：

```zig
fn contains(haystack: []const u32, needle: u32) bool {
	for (haystack) |value| {
		if (needle == value) {
			return true;
		}
	}
	return false;
}
```

`for` 循环可以同时处理多个序列，只要这些序列的长度相同。上面我们使用了 `std.mem.eql` 函数。它（几乎）看起来像这样：

```zig
pub fn eql(comptime T: type, a: []const T, b: []const T) bool {
	// if they arent' the same length, the can't be equal
	if (a.len != b.len) return false;

	for (a, b) |a_elem, b_elem| {
		if (a_elem != b_elem) return false;
	}

	return true;
}
```

最初的 `if` 检查不仅仅是一个很好的性能优化，它还是一个必要的保护。如果我们将其取出并传递不同长度的参数，我们将遇到运行时恐慌：for 循环遍历长度不等的对象。

`for` 循环还可以迭代范围，例如：

```zig
for (0..10) |i| {
	std.debug.print("{d}\n", .{i});
}
```

我们的 `switch` 范围使用三个点 `3...6` ，而此范围使用两个点 `0..10` 。这是因为 `switch` 情况包含两个数字，而 `for` 不包含上限

这与一个（或多个！）序列结合起来真的很闪耀：

```zig
fn indexOf(haystack: []const u32, needle: u32) ?usize {
	for (haystack, 0..) |value, i| {
		if (needle == value) {
			return i;
		}
	}
	return null;
}
```

这是可空类型的预览。

范围的结尾是由 `haystack` 的长度推断的，尽管我们可以惩罚自己并写： `0..hastack.len` 。 `for` 循环不支持更通用的 `init; compare; step` 习惯用法。为此，我们依赖 `while` 。

因为 `while` 更简单，采用 `while (condition) { }` 的形式，所以我们可以更好地控制迭代。例如，当计算字符串中转义序列的数量时，我们需要将迭代器增加 2 以避免重复计算 `\\` ：

```zig
var i: usize = 0;
var escape_count: usize = 0;
while (i < src.len) {
	if (src[i] == '\\') {
		i += 2;
		escape_count += 1;
	} else {
		i += 1;
	}
}
```

`while` 可以有一个 `else` 子句，该子句在条件为 false 时执行。它还接受在每次迭代后执行的语句。在 `for` 支持多个序列之前，此功能已被广泛使用。上式可以写成：

```zig
var i: usize = 0;
var escape_count: usize = 0;

//                  this part
while (i < src.len) : (i += 1) {
	if (src[i] == '\\') {
		// +1 here, and +1 above == +2
		i += 1;
		escape_count += 1;
	}
}
```

支持 `break` 和 `continue` 来跳出最内层循环或跳转到下一个迭代。

块可以被标记，并且 `break` 和 `continue` 可以针对特定标签。一个人为的例子：

```zig
outer: for (1..10) |i| {
	for (i..10) |j| {
		if (i * j > (i+i + j+j)) continue :outer;
		std.debug.print("{d} + {d} >= {d} * {d}\n", .{i+i, j+j, i, j});
	}
}
```


`break` 还有另一个有趣的行为，从块返回一个值：



```zig
const personality_analysis = blk: {
	if (tea_vote > coffee_vote) break :blk "sane";
	if (tea_vote == coffee_vote) break :blk "whatever";
	if (tea_vote < coffee_vote) break :blk "dangerous";
};
```

像这样的块必须以分号终止。

稍后，当我们探索标记联合、错误联合和可选类型时，我们将看到这些控制流还提供什么。

## 枚举

枚举是带有标签的整数常量。它们的定义很像一个结构体：

```zig
// could be "pub"
const Status = enum {
	ok,
	bad,
	unknown,
};
```

并且，像结构一样，可以包含其他定义，包括可能或可能不采用枚举作为参数的函数：

```zig
const Stage = enum {
	validate,
	awaiting_confirmation,
	confirmed,
	completed,
	err,

	fn isComplete(self: Stage) bool {
		return self == .confirmed or self == .err;
	}
};
```

如果您想要枚举的字符串表示形式，可以使用内置的 `@tagName(enum)` 函数。

回想一下，可以使用 `.{...}` 表示法根据其分配或返回类型来推断结构类型。上面，我们看到枚举类型是根据与 `self` 的比较推断出来的，后者的类型是 `Stage` 。我们可以明确地写成： `return self == Stage.confirmed or self == Stage.err;` 。但是，在处理枚举时，您经常会看到通过 `.$value` 表示法省略枚举类型

`switch` 的详尽性质使其与枚举完美搭配，因为它确保您已经处理了所有可能的情况。不过，在使用 `switch` 的 `else` 子句时要小心，因为它会匹配任何新添加的枚举值，这可能是也可能不是您想要的行为。

## union(联合)

联合定义了值可以具有的一组类型。例如，此 `Number` 联合可以是 `integer` 、 `float` 或 `nan` （不是数字）：

```zig
const std = @import("std");

pub fn main() void {
	const n = Number{.int = 32};
	std.debug.print("{d}\n", .{n.int});
}

const Number = union {
	int: i64,
	float: f64,
	nan: void,
};
```

一个联合一次只能设置一个字段；尝试访问未设置的字段是错误的。由于我们已经设置了 `int` 字段，因此如果我们随后尝试访问 `n.float` ，我们会收到错误。我们的字段之一 `nan` 具有 `void` 类型。我们如何设置它的值？使用 `{}` ：

```zig
const n = Number{.nan = {}};
```

工会面临的挑战是了解设置了哪个领域。这就是标记联合发挥作用的地方。带标记的联合将枚举与联合合并，可以在 switch 语句中使用。考虑这个例子：

```zig
pub fn main() void {
	const ts = Timestamp{.unix = 1693278411};
	std.debug.print("{d}\n", .{ts.seconds()});
}

const TimestampType = enum {
	unix,
	datetime,
};

const Timestamp = union(TimestampType) {
	unix: i32,
	datetime: DateTime,

	const DateTime = struct {
		year: u16,
		month: u8,
		day: u8,
		hour: u8,
		minute: u8,
		second: u8,
	};

	fn seconds(self: Timestamp) u16 {
		switch (self) {
			.datetime => |dt| return dt.second,
			.unix => |ts| {
				const seconds_since_midnight: i32 = @rem(ts, 86400);
				return @intCast(@rem(seconds_since_midnight, 60));
			},
		}
	}
};
```

请注意， `switch` 中的每个案例都会捕获字段的键入值。即 `dt` 是 `Timestamp.DateTime` ， `ts` 是 `i32` 。这也是我们第一次看到嵌套在另一种类型中的结构。 `DateTime` 可以在联合之外定义。我们还看到两个新的内置函数： `@rem` 用于获取余数， `@intCast` 用于将结果转换为 `u16` ( `@intCast` 推断我们需要返回类型中的 `u16` ，因为正在返回该值）。

正如我们从上面的示例中看到的，标记联合可以像接口一样使用，只要提前知道所有可能的实现并且可以将其烘焙到标记联合中即可。

最后，可以推断出标记联合的枚举类型。我们可以不定义 `TimestampType` ，而是这样做：

```zig
const Timestamp = union(enum) {
	unix: i32,
	datetime: DateTime,

	...
```

Zig 会根据我们联合的字段创建一个隐式枚举。

## optionals

通过在类型前面添加问号 `?` ，可以将任何值声明为可选值。可选类型可以是 `null` 或定义类型的值：

```zig
var home: ?[]const u8 = null;
var name: ?[]const u8 = "Leto";
```

对显式类型的需求应该很明确：如果我们刚刚完成了 `const name = "Leto";` ，那么推断的类型将是非可选的 `[]const u8` 。

`.?` 用于访问可选类型后面的值：

```zig
std.debug.print("{s}\n", .{name.?});
```

但是如果我们在 null 上使用 `.?` ，我们会遇到运行时恐慌。 `if` 语句可以安全地解包可选：

```zig
if (home) |h| {
	// h is a []const u8
	// we have a home value
} else {
	// we don't have a home value
}
```

`orelse` 可用于解包可选或执行代码。这通常用于指定默认值或从函数返回：

```zig
const h = home orelse "unknown"
// or maybe

// exit our function
const h = home orelse return;
```

However, `orelse` can also be given a block and execute more complex logic. Optional types also integrate with `while`, and are frequently used for creating iterators. We won't implement an iterator, but hopefully this dummy code makes sense:

```zig
while (rows.next()) |row| {
	// do something with our row
}
```

## undefined

到目前为止，我们看到的每个变量都已初始化为合理的值。但有时我们并不知道变量声明时的值。选项是一种选择，但并不总是有意义。在这种情况下，我们可以将变量设置为 `undefined` 以使它们保持未初始化状态。

通常这样做的一个地方是创建一个由某个函数填充的数组时：

```zig
var pseudo_uuid: [16]u8 = undefined;
std.crypto.random.bytes(&pseudo_uuid);
```

上面仍然创建了一个 16 字节的数组，但使内存未初始化。

## errors

Zig 具有简单实用的错误处理能力。这一切都始于错误集，其外观和行为类似于枚举：

```zig
// Like our struct in Part 1, OpenError can be marked as "pub"
// to make it accessible outside of the file it is defined in
const OpenError = error {
	AccessDenied,
	NotFound,
};
```

函数（包括 `main` ）现在可以返回此错误：

```zig
pub fn main() void {
	return OpenError.AccessDenied;
}

const OpenError = error {
	AccessDenied,
	NotFound,
};
```

If you try to run this, you'll get an error: *expected type 'void', found 'error{AccessDenied,NotFound}'*. This makes sense: we defined `main` with a `void` return type, yet we return something (an error, sure, but that's still not `void`). To solve this, we need to change our function's return type.

```zig
pub fn main() OpenError!void {
	return OpenError.AccessDenied;
}
```

这称为错误联合类型，它表明我们的函数可以返回 `OpenError` 错误或 `void` （又名，什么也没有）。到目前为止，我们已经非常明确了：我们为函数可能返回的可能错误创建了一个错误集，并在函数的错误联合返回类型中使用了该错误集。但是，当谈到错误时，Zig 几乎没有什么巧妙的技巧。首先，我们可以让 Zig 使用 `!return type` 来推断错误集，而不是将错误联合指定为 `error set!return type` 。所以我们可以而且可能会将我们的 `main` 定义为：

```zig
pub fn main() !void
```

其次，Zig 能够为我们隐式创建错误集。我们可以这样做，而不是创建错误集：

```zig
pub fn main() !void {
	return error.AccessDenied;
}
```

我们的完全显式和隐式方法并不完全等同。例如，对具有隐式错误集的函数的引用需要使用特殊的 `anyerror` 类型。库开发人员可能会看到更明确的优势，例如自记录代码。尽管如此，我认为隐式错误集和推断错误联合都是实用的；我大量使用两者。

错误联合的真正价值在于 `catch` 和 `try` 形式的内置语言支持。返回错误联合的函数调用可以包含 `catch` 子句。例如，http 服务器库可能具有如下所示的代码：

```zig
action(req, res) catch |err| {
	if (err == error.BrokenPipe or err == error.ConnectionResetByPeer) {
		return;
	} else if (err == error.BodyTooBig) {
		res.status = 431;
		res.body = "Request body is too big";
	} else {
		res.status = 500;
		res.body = "Internal Server Error";
		// todo: log err
	}
};
```

`switch` 版本更惯用：

```zig
action(req, res) catch |err| switch (err) {
	error.BrokenPipe, error.ConnectionResetByPeer) => return,
	error.BodyTooBig => {
		res.status = 431;
		res.body = "Request body is too big";
	},
	else => {
		res.status = 500;
		res.body = "Internal Server Error";
	}
};
```

这一切都非常奇特，但说实话，您在 `catch` 中最有可能要做的事情是将错误冒泡给调用者：

```zig
action(req, res) catch |err| return err;
```

这很常见， `try` 就是这样做的。我们做的不是上述，而是：

```zig
try action(req, res);
```

考虑到必须处理错误，这特别有用。您很可能会使用 `try` 或 `catch` 来执行此操作。

Go 开发人员会注意到 `try` 比 `if err != nil { return err }` 需要更少的击键次数。

大多数时候您会使用 `try` 和 `catch` ，但 `if` 和 `while` 也支持错误联合，就像可选类型。对于 `while` ，如果条件返回错误，则执行 `else` 子句。

有一个特殊的 `anyerror` 类型可以容纳任何错误。虽然我们可以将函数定义为返回 `anyerror!TYPE` 而不是 `!TYPE` ，但两者并不等效。推断的错误集是根据函数可以返回的内容创建的。 `anyerror` 是全局错误集，是程序中所有错误集的超集。因此，在函数签名中使用 `anyerror` 可能表明您的函数可以返回实际上不能返回的错误。 `anyerror` 用于可以处理任何错误的函数参数或结构字段（想象一个日志库）。

函数返回错误联合可选类型的情况并不罕见。通过推断错误集，这看起来像：

```zig
// load the last saved game
pub fn loadLast() !?Save {
	// TODO
	return null;
}
```

使用此类函数的方法有多种，但最紧凑的是使用 `try` 来解包我们的错误，然后使用 `orelse` 来解包可选。这是一个工作框架：

```zig
const std = @import("std");

pub fn main() void {
	// This is the line you want to focus on
	const save = (try Save.loadLast()) orelse Save.blank();
	std.debug.print("{any}\n", .{save});
}

pub const Save = struct {
	lives: u8,
	level: u16,

	pub fn loadLast() !?Save {
		//todo
		return null;
	}

	pub fn blank() Save {
		return .{
			.lives = 3,
			.level = 1,
		};
	}
};
```

虽然 Zig 更深入，并且某些语言特性具有更强大的功能，但我们在前两部分中看到的是该语言的重要部分。它将作为基础，使我们能够探索更复杂的主题，而不会因为语法而分心。

# styleguide

在这个简短的部分中，我们将介绍编译器强制执行的两条编码规则以及标准库的命名约定。

## 未使用的变量unused_variables

Zig 不允许变量闲置。下面给出了两个编译时错误：

```zig
const std = @import("std");

pub fn main() void {
	const sum = add(8999, 2);
}

fn add(a: i64, b: i64) i64 {
	// notice this is a + a, not a + b
	return a + a;
}
```

第一个错误是因为 `sum` 是未使用的局部常量。第二个错误是因为 `b` 是未使用的函数参数。对于这段代码来说，这些都是明显的错误。但您可能有正当理由拥有未使用的变量和函数参数。在这种情况下，您可以将变量分配给下划线（ `_` ）：

```zig
const std = @import("std");

pub fn main() void {
	_ = add(8999, 2);

	// or

	sum = add(8999, 2);
	_ = sum;
}

fn add(a: i64, b: i64) i64 {
	_ = b;
	return a + a;
}
```

作为 `_ = b;` 的替代方法，我们可以将函数参数命名为 `_` ，不过，在我看来，这会让读者猜测未使用的参数是什么：

```zig
fn add(a: i64, _: i64) i64 {
```

请注意， `std` 也未使用，但不会生成错误。在未来的某个时候，预计 Zig 也会将此视为编译时错误。

## shadowing

Zig 不允许一个标识符通过使用相同的名称来“隐藏”另一个标识符。从套接字读取的此代码无效：

```zig
fn read(stream: std.net.Stream) ![]const u8 {
	var buf: [512]u8 = undefined;
	const read = try stream.read(&buf);
	if (read == 0) {
		return error.Closed;
	}
	return buf[0..read];
}
```

我们的 `read` 变量隐藏了我们的函数名称。我不喜欢这条规则，因为它通常会导致开发人员使用简短的无意义的名称。例如，要编译此代码，我会将 `read` 更改为 `n` 。在我看来，在这种情况下，开发人员可以更好地选择最具可读性的选项。

##  命名约定naming

除了编译器强制执行的规则之外，您当然可以自由遵循您喜欢的任何命名约定。但它确实有助于理解 Zig 自己的命名约定，因为您将与之交互的大部分代码（从标准库到第三方库）都使用了它。

Zig 源代码缩进 4 个空格。我个人使用客观上更易于访问的选项卡。

函数名称为驼峰命名法，变量为小写加下划线（也称为蛇形命名法）。类型为 PascalCase。这三个规则之间有一个有趣的交叉点。引用类型的变量或返回类型的函数遵循类型规则并且采用 PascalCase。我们已经看到了这一点，尽管您可能错过了。

```zig
std.debug.print("{any}\n", .{@TypeOf(.{.year = 2023, .month = 8})});
```

我们已经看到了其他内置函数： `@import` 、 `@rem` 和 `@intCast` 。由于这些是函数，因此它们采用驼峰命名法。 `@TypeOf` 也是一个内置函数，但它是PascalCase，为什么？因为它返回一个类型，因此使用类型命名约定。如果我们使用 Zig 的命名约定将 `@TypeOf` 的结果分配给一个变量，则该变量也应该是 PascalCase：

```zig
const T = @TypeOf(3)
std.debug.print("{any}\n", .{T});
```

`zig` 可执行文件确实有一个 `fmt` 命令，给定一个文件或目录，该命令将根据 Zig 自己的样式指南格式化该文件。但它并没有涵盖所有内容，例如它将调整标识和大括号位置，但不会更改标识符大小写。

# 指针pointers

Zig 不包含垃圾收集器。管理内存的重担落在了开发人员的身上。这是一项重大责任，因为它直接影响应用程序的性能、稳定性和安全性。

我们将首先讨论指针，这本身就是一个需要讨论的重要主题，同时也开始训练我们自己从面向内存的角度看待程序的数据。如果您已经熟悉指针、堆分配和悬空指针，请随意跳过堆内存和分配器的几个部分，这是更特定于 Zig 的。

以下代码创建一个 `power` 为 1 的用户，然后调用 `levelUp` 函数，该函数将用户的权力增加 1。你能猜出输出吗？

```zig
const std = @import("std");

pub fn main() void {
	var user = User{
		.id = 1,
		.power = 100,
	};

	// this line has been added
	levelUp(user);
	std.debug.print("User {d} has power of {d}\n", .{user.id, user.power});
}

fn levelUp(user: User) void {
	user.power += 1;
}

pub const User = struct {
	id: u64,
	power: i32,
};
```

这是一个不友善的伎俩。代码无法编译：无法分配给常量。我们在第 1 部分中看到，函数参数是常量，因此 `user.power += 1;` 无效。要修复编译时错误，我们可以将 `levelUp` 函数更改为：

```zig
fn levelUp(user: User) void {
	var u = user;
	u.power += 1;
}
```

它将编译，但我们的输出是 User 1 has power of 100，即使我们代码的意图显然是 `levelUp` 将用户的权力增加到 `101` 。发生了什么？

为了理解这一点，将数据与内存以及变量视为将类型与特定内存位置相关联的标签会有所帮助。例如，在 `main` 中，我们创建一个 `User` 。内存中这些数据的简单可视化如下：

```text
user -> ------------ (id)
        |    1     |
        ------------ (power)
        |   100    |
        ------------
```

有两件重要的事情需要注意。第一个是我们的 `user` 变量指向结构的开头。第二个是字段按顺序排列。请记住，我们的 `user` 也有一个类型。该类型告诉我们 `id` 是 64 位整数， `power` 是 32 位整数。有了对数据开头和类型的引用，编译器可以将 `user.power` 转换为：访问从开头开始 64 位的 32 位整数。这就是变量的力量，它们引用内存并包含以有意义的方式理解和操作内存所需的类型信息。

默认情况下，Zig 不保证结构的内存布局。它可以按字母顺序、按大小升序或按间隙存储字段。只要它能够正确翻译我们的代码，它就可以做它想做的事。这种自由可以实现某些优化。只有声明 `packed struct` ，我们才能得到关于内存布局的强有力的保证。尽管如此，我们对 `user` 的可视化还是合理且有用的。

这是一个略有不同的可视化，其中包括内存地址。该数据开始的内存地址是我想出的随机地址。这是 `user` 变量引用的内存地址，也是我们第一个字段 `id` 的值所在的位置。然而，给定这个初始地址，所有后续地址都有一个已知的相对地址。由于 `id` 是一个64位整数，因此它需要8字节的内存。因此， `power` 必须位于 $start_address + 8：

```text
user ->   ------------  (id: 1043368d0)
          |    1     |
          ------------  (power: 1043368d8)
          |   100    |
          ------------
```

为了亲自验证这一点，我想介绍一下 addressof 运算符： `&` 。顾名思义，addressof 运算符返回变量的地址（它也可以返回函数的地址，不是吗？！）。保留现有的 `User` 定义，尝试这个 `main` ：

```zig
pub fn main() void {
	var user = User{
		.id = 1,
		.power = 100,
	};
	std.debug.print("{*}\n{*}\n{*}\n", .{&user, &user.id, &user.power});
}
```

此代码打印 `user` 、 `user.id` 和 `user.power` 的地址。根据您的平台和其他因素，您可能会得到不同的结果，但希望您会看到 `user` 和 `user.id` 的地址相同，而 `user.power` 位于 8 字节偏移处。我有：

```text
learning.User@1043368d0
u64@1043368d0
i32@1043368d8
```

addressof 运算符返回一个指向值的指针。指向值的指针是一种不同的类型。 `T` 类型的值的地址是 `*T` 。我们将其读作指向 T 的指针。因此，如果我们获取 `user` 的地址，我们将得到 `*User` 或指向 `User` 的指针：

```zig
pub fn main() void {
	var user = User{
		.id = 1,
		.power = 100,
	};

	const user_p = &user;
	std.debug.print("{any}\n", .{@TypeOf(user_p)});
}
```

我们最初的目标是通过 `levelUp` 函数将用户的 `power` 增加 1。我们得到了要编译的代码，但是当我们打印 `power` 时，它仍然是原始值。这有点跳跃，但让我们更改代码以在 `main` 和 `levelUp` 中打印 `user` 的地址：

```zig
pub fn main() void {
	const user = User{
		.id = 1,
		.power = 100,
	};

	// added this
	std.debug.print("main: {*}\n", .{&user});

	levelUp(user);
	std.debug.print("User {d} has power of {d}\n", .{user.id, user.power});
}

fn levelUp(user: User) void {
	// add this
	std.debug.print("levelUp: {*}\n", .{&user});
	var u = user;
	u.power += 1;
}
```

如果你运行这个，你会得到两个不同的地址。这意味着 `levelUp` 中修改的 `user` 与 `main` 中的 `user` 不同。发生这种情况是因为 Zig 传递了该值的副本。这似乎是一个奇怪的默认值，但好处之一是函数的调用者可以确定该函数不会修改参数（因为它不能）。在很多情况下，这是一件值得保证的好事。当然，有时，比如 `levelUp` ，我们希望函数修改参数。为了实现这一点，我们需要 `levelUp` 作用于 `main` 中的实际 `user` ，而不是副本。我们可以通过将用户的地址传递到函数中来做到这一点：

```zig
const std = @import("std");

pub fn main() void {
	var user = User{
		.id = 1,
		.power = 100,
	};

	// user -> &user
	levelUp(&user);
	std.debug.print("User {d} has power of {d}\n", .{user.id, user.power});
}

// User -> *User
fn levelUp(user: *User) void {
	user.power += 1;
}

pub const User = struct {
	id: u64,
	power: i32,
};
```

我们必须做出两项改变。第一个是使用用户地址调用 `levelUp` ，即 `&user` ，而不是 `user` 。这意味着我们的函数不再接收 `User` 。相反，它收到一个 `*User` ，这是我们的第二个更改。

该代码现在可以按预期工作。一般来说，函数参数和我们的内存模型仍然存在许多微妙之处，但我们正在取得进展。现在也许是时候提一下，除了特定的语法之外，这些都不是 Zig 所独有的。我们在这里探索的模型是最常见的，某些语言可能只是向开发人员隐藏了许多细节，从而隐藏了灵活性。

## 方法methods

您很可能将 `levelUp` 编写为 `User` 结构的方法：

```zig
pub const User = struct {
	id: u64,
	power: i32,

	fn levelUp(user: *User) void {
		user.power += 1;
	}
};
```

这就引出了一个问题：我们如何调用带有指针接收器的方法？也许我们必须做类似的事情： `&user.levelUp()` ？实际上，您只需正常调用它即可，即 `user.levelUp()` 。 Zig 知道该方法需要一个指针并正确传递该值（通过引用传递）。

我最初选择了一个函数，因为它很明确，因此更容易学习。

## 常数函数参数const_paremeters

我不止是暗示，默认情况下，Zig 将传递一个值的副本（称为“按值传递”）。很快我们就会发现现实有点微妙（提示：嵌套对象的复杂值怎么样？）

即使坚持使用简单类型，事实是 Zig 可以随心所欲地传递参数，只要它能保证保留代码的意图即可。在我们原来的 `levelUp` 中，参数是 `User` ，Zig 可以传递用户的副本或对 `main.user` 的引用，只要它可以保证该函数不会改变它。 （我知道我们最终确实希望它发生变异，但是通过创建类型 `User` ，我们告诉编译器我们不希望它发生变异）。

这种自由度使得 Zig 能够根据参数类型使用最优策略。小类型，例如 `User` 可以廉价地按值传递（即复制）。通过引用传递较大的类型可能会更便宜。 Zig 可以使用任何方法，只要保留代码的意图即可。在某种程度上，这是通过具有恒定的函数参数来实现的。

现在您知道函数参数是常量的原因之一。

也许您想知道即使与复制非常小的结构相比，通过引用传递如何会更慢。接下来我们会更清楚地看到这一点，但要点是，当 `user` 是指针时执行 `user.power` 会增加一点点开销。编译器必须权衡复制的成本与通过指针间接访问字段的成本。

## 指针到指针pointer_to_pointer

我们之前查看了 `main` 函数中 `user` 的内存是什么样的。现在我们已经改变了 `levelUp` 它的内存会是什么样子？：

```text
main:
user -> ------------  (id: 1043368d0)  <---
        |    1     |                      |
        ------------  (power: 1043368d8)  |
        |   100    |                      |
        ------------                      |
                                          |
        .............  empty space        |
        .............  or other data      |
                                          |
levelUp:                                  |
user -> -------------  (*User)            |
        | 1043368d0 |----------------------
        -------------
```

在 `levelUp` 中， `user` 是指向 `User` 的指针。它的值是一个地址。当然，不仅仅是任何地址，而是 `main.user` 的地址。值得明确的是 `levelUp` 中的 `user` 变量代表一个具体值。这个值恰好是一个地址。而且，它不仅仅是一个地址，它也是一种类型，一个 `*User` 。这一切都非常一致，无论我们是否谈论指针并不重要：变量将类型信息与地址相关联。关于指针的唯一特殊之处是，当我们使用点语法时，例如 `user.power` ，Zig 知道 `user` 是一个指针，会自动跟随地址。

通过指针访问字段时，某些语言需要不同的符号。

重要的是要理解 `levelUp` 中的 `user` 变量本身存在于内存中的某个地址。就像我们之前所做的一样，我们可以亲眼看到这一点：

```zig
fn levelUp(user: *User) void {
	std.debug.print("{*}\n{*}\n", .{&user, user});
	user.power += 1;
}
```

上面打印了 `user` 变量引用的地址及其值，即 `main` 中 `user` 的地址。

如果 `user` 是 `*User` ，那么 `&user` 是什么？它是一个 `**User` ，或者一个指向 `User` 的指针。我可以这样做，直到我们其中一个人的内存耗尽为止！

有多个间接级别的用例，但这不是我们现在需要的。本节的目的是表明指针并不特殊，它们只是一个值，即地址和类型。

## 嵌套指针nested_pointers

到目前为止，我们的 `User` 很简单，包含两个整数。很容易将其记忆形象化，并且当我们谈论“复制”时，没有任何歧义。但是，当 `User` 变得更加复杂并包含指针时会发生什么？

```zig
pub const User = struct {
	id: u64,
	power: i32,
	name: []const u8,
};
```

我们添加了 `name` ，它是一个切片。回想一下，切片是一个长度和一个指针。如果我们用 `"Goku"` 的名称初始化 `user` ，它在内存中会是什么样子？

```text
user -> -------------  (id: 1043368d0)
        |     1     |
        -------------  (power: 1043368d8)
        |    100    |
        -------------  (name.len: 1043368dc)
        |     4     |
        -------------  (name.ptr: 1043368e4)
  ------| 1182145c0 |
  |     -------------
  |
  |     .............  empty space
  |     .............  or other data
  |
  --->  -------------  (1182145c0)
        |    'G'    |
        -------------
        |    'o'    |
        -------------
        |    'k'    |
        -------------
        |    'u'    |
        -------------
```

The new `name` field is a slice which is made up of a `len` and `ptr` field. These are laid out in sequence along with all the other fields. On a 64 bit platform both `len` and `ptr` will be 64 bits, or 8 bytes. The interesting part is the value of `name.ptr`: it's an address to some other place in memory.

由于我们使用了字符串文字，因此 `user.name.ptr` 将指向二进制文件中存储所有常量的区域内的特定位置。

通过深度嵌套，类型可能会变得比这复杂得多。但简单或复杂，它们的行为都是相同的。具体来说，如果我们回到原始代码，其中 `levelUp` 采用普通的 `User` 并且 Zig 提供了一个副本，那么现在我们有了一个嵌套指针，那会是什么样子呢？

答案是仅制作该值的浅表副本。或者，正如某些人所说，仅复制可立即由变量寻址的内存。看起来 `levelUp` 会得到 `user` 的半生不熟的副本，可能带有无效的 `name` 。但请记住，指针（如我们的 `user.name.ptr` ）是一个值，而该值是一个地址。地址的副本仍然是同一个地址：

```text
main: user ->    -------------  (id: 1043368d0)
                 |     1     |
                 -------------  (power: 1043368d8)
                 |    100    |
                 -------------  (name.len: 1043368dc)
                 |     4     |
                 -------------  (name.ptr: 1043368e4)
                 | 1182145c0 |-------------------------
levelUp: user -> -------------  (id: 1043368ec)       |
                 |     1     |                        |
                 -------------  (power: 1043368f4)    |
                 |    100    |                        |
                 -------------  (name.len: 1043368f8) |
                 |     4     |                        |
                 -------------  (name.ptr: 104336900) |
                 | 1182145c0 |-------------------------
                 -------------                        |
                                                      |
                 .............  empty space           |
                 .............  or other data         |
                                                      |
                 -------------  (1182145c0)        <---
                 |    'G'    |
                 -------------
                 |    'o'    |
                 -------------
                 |    'k'    |
                 -------------
                 |    'u'    |
                 -------------
```

从上面我们可以看出，浅复制是可以工作的。由于指针的值是一个地址，复制该值意味着我们得到相同的地址。这对于可变性具有重要意义。我们的函数无法改变 `main.user` 直接访问的字段，因为它有一个副本，但它确实可以访问相同的 `name` ，那么它可以改变它吗？在这种特定情况下，不， `name` 是 `const` 。另外，我们的值“Goku”是一个始终不可变的字符串文字。但是，通过一些工作，我们可以看到浅复制的含义：

```zig
const std = @import("std");

pub fn main() void {
	var name = [4]u8{'G', 'o', 'k', 'u'};
	var user = User{
		.id = 1,
		.power = 100,
		// slice it, [4]u8 -> []u8
		.name = name[0..],
	};
	levelUp(user);
	std.debug.print("{s}\n", .{user.name});
}

fn levelUp(user: User) void {
	user.name[2] = '!';
}

pub const User = struct {
	id: u64,
	power: i32,
	// []const u8 -> []u8
	name: []u8
};
```

上面的代码打印“Go!u”。我们必须将 `name's` 类型从 `[]const u8` 更改为 `[]u8` ，并创建一个数组并对其进行切片，而不是始终不可变的字符串文字。有些人可能会看到这里的不一致。按值传递可以防止函数改变直接字段，但不能改变指针后面有值的字段。如果我们确实希望 `name` 是不可变的，我们应该将其声明为 `[]const u8` 而不是 `[]u8` 。

有些语言有不同的实现，但许多语言的工作原理与此完全相同（或非常接近）。虽然所有这些看起来似乎深奥，但它是日常编程的基础。好消息是，您可以使用简单的示例和片段来掌握这一点；它不会随着系统其他部分复杂性的增加而变得更加复杂。

## 递归结构recursive_structures

有时您需要一个递归结构。保留现有代码，让我们向 `User` 添加一个 `?User` 类型的可选 `manager` 。当我们这样做时，我们将创建两个 `Users` 并将一个分配给另一个作为经理：

```zig
const std = @import("std");

pub fn main() void {
	const leto = User{
		.id = 1,
		.power = 9001,
		.manager = null,
	};

	const duncan = User{
		.id = 1,
		.power = 9001,
		.manager = leto,
	};

	std.debug.print("{any}\n{any}", .{leto, duncan});
}

pub const User = struct {
	id: u64,
	power: i32,
	manager: ?User,
};
```

此代码无法编译：struct 'learning.User' 取决于其自身。这会失败，因为每种类型都必须具有已知的编译时大小。

当我们添加 `name` 时，我们没有遇到这个问题，即使名称的长度可以不同。问题不在于值的大小，而在于类型本身的大小。 Zig 需要这些知识来完成我们上面讨论的所有事情，例如根据偏移位置访问字段。 `name` 是一个切片，即 `[]const u8` ，其大小已知：16 字节 - `len` 为 8 字节， `ptr` .

您可能认为这对于任何可选或联合都会出现问题。但对于选项和联合，最大可能的大小是已知的，Zig 可以使用它。递归结构没有这样的上限，该结构可以递归一次、两次或数百万次。该数字从 `User` 到 `User` 不等，并且在编译时未知。

我们通过 `name` 看到了答案：使用指针。指针始终占用 `usize` 字节。在 64 位平台上，即 8 个字节。就像实际名称“Goku”没有与我们的 `user` 一起存储一样，使用指针意味着我们的管理器不再依赖于 `user's` 内存布局。

```zig
const std = @import("std");

pub fn main() void {
	const leto = User{
		.id = 1,
		.power = 9001,
		.manager = null,
	};

	const duncan = User{
		.id = 1,
		.power = 9001,
		// changed from leto -> &leto
		.manager = &leto,
	};

	std.debug.print("{any}\n{any}", .{leto, duncan});
}

pub const User = struct {
	id: u64,
	power: i32,
	// changed from ?const User -> ?*const User
	manager: ?*const User,
};
```

您可能永远不需要递归结构，但这与数据建模无关。这是关于理解指针和内存模型以及更好地理解编译器的用途。

许多开发人员都为指针而烦恼，它们可能有些难以捉摸。它们不像整数、字符串或 `User` 那样具体。所有这些都不必非常清楚才能让您继续前进。但它值得掌握，而且不仅仅是为了 Zig。这些细节可能隐藏在 Ruby、Python 和 JavaScript 等语言中，在较小程度上隐藏在 C#、Java 和 Go 中，但它们仍然存在，影响着您编写代码的方式以及代码的运行方式。因此，请花点时间，尝试一下示例，添加调试打印语句来查看变量及其地址。你探索得越多，它就会变得越清晰。

#  堆栈内存stack_memory

深入研究指针可以深入了解变量、数据和内存之间的关系。我们已经了解了内存的样子，但我们还没有讨论数据以及内存是如何管理的。对于短暂且简单的脚本来说，这可能并不重要。在 32GB 笔记本电脑时代，您可以启动程序，使用几百兆的 RAM 读取文件并解析 HTTP 响应，执行一些令人惊奇的操作，然后退出。在程序退出时，操作系统知道它为程序提供的任何内存现在都可以用于其他用途。

但对于运行数天、数月甚至数年的程序来说，内存成为一种有限且宝贵的资源，可能会受到同一台计算机上运行的其他进程的追捧。根本没有办法等到程序退出来释放内存。这是垃圾收集器的主要工作：了解哪些数据不再使用并释放其内存。在 Zig 中，你是垃圾收集者。

您编写的大多数程序都会使用三个内存“区域”。第一个是全局空间，它是存储程序常量（包括字符串文字）的地方。所有全局数据都被烘焙到二进制文件中，在编译时（因此运行时）完全已知并且不可变。这些数据在程序的整个生命周期中都存在，永远不需要更多或更少的内存。除了它对二进制文件大小的影响之外，这根本不是我们需要担心的事情。

内存的第二个区域是调用堆栈，这是本部分的主题。第三个区域是堆，这是我们下一部分的主题。

内存区域之间没有真正的物理差异，它是操作系统和可执行文件创建的概念。

## 堆栈帧stack_frames

到目前为止，我们看到的所有数据都是存储在二进制或局部变量的全局数据部分中的常量。 “局部”表示该变量仅在其声明的范围内有效。在 Zig 中，作用域以花括号 `{ ... }` 开始和结束。大多数变量的作用域都是函数，包括函数参数或控制流块，例如 `if` 。但是，正如我们所看到的，您可以创建任意块，从而创建任意范围。

在上一部分中，我们可视化了 `main` 和 `levelUp` 函数的内存，每个函数都有一个 `User` ：

```text
main: user ->    -------------  (id: 1043368d0)
                 |     1     |
                 -------------  (power: 1043368d8)
                 |    100    |
                 -------------  (name.len: 1043368dc)
                 |     4     |
                 -------------  (name.ptr: 1043368e4)
                 | 1182145c0 |-------------------------
levelUp: user -> -------------  (id: 1043368ec)       |
                 |     1     |                        |
                 -------------  (power: 1043368f4)    |
                 |    100    |                        |
                 -------------  (name.len: 1043368f8) |
                 |     4     |                        |
                 -------------  (name.ptr: 104336900) |
                 | 1182145c0 |-------------------------
                 -------------                        |
                                                      |
                 .............  empty space           |
                 .............  or other data         |
                                                      |
                 -------------  (1182145c0)        <---
                 |    'G'    |
                 -------------
                 |    'o'    |
                 -------------
                 |    'k'    |
                 -------------
                 |    'u'    |
                 -------------
```

`levelUp` 紧接在 `main` 之后是有原因的：这是我们的[简化的]调用堆栈。当我们的程序启动时， `main` 及其局部变量被推入调用堆栈。当 `levelUp` 被调用时，它的参数和任何局部变量都会被压入调用堆栈。重要的是，当 `levelUp` 返回时，它会从堆栈中弹出。在 `levelUp` 返回并且控制权返回到 `main` 后，我们的调用堆栈如下所示：

```text
main: user ->    -------------  (id: 1043368d0)
                 |     1     |
                 -------------  (power: 1043368d8)
                 |    100    |
                 -------------  (name.len: 1043368dc)
                 |     4     |
                 -------------  (name.ptr: 1043368e4)
                 | 1182145c0 |-------------------------
                 -------------
                                                      |
                 .............  empty space           |
                 .............  or other data         |
                                                      |
                 -------------  (1182145c0)        <---
                 |    'G'    |
                 -------------
                 |    'o'    |
                 -------------
                 |    'k'    |
                 -------------
                 |    'u'    |
                 -------------
```

当调用一个函数时，它的整个堆栈帧都会被压入调用堆栈。这是我们需要知道每种类型的大小的原因之一。虽然在执行该特定代码行之前我们可能不知道用户名的长度（假设它不是常量字符串文字），但我们确实知道我们的函数有一个 `User` 并且，此外对于其他字段，我们需要 8 个字节的 `name.len` 和 8 个字节的 `name.ptr` 。

当函数返回时，最后推入调用堆栈的堆栈帧将被弹出。神奇的事情发生了： `levelUp` 使用的内存已自动释放！虽然从技术上讲，内存可以返回给操作系统，但据我所知，没有任何实现实际上会缩小调用堆栈（尽管实现会在必要时动态增长它）。尽管如此，用于存储 `levelUp's` 堆栈帧的内存现在可以在我们的进程中自由地用于另一个堆栈帧。

在正常的程序中，调用堆栈可能会变得相当大。在典型程序使用的所有框架代码和库之间，您最终会得到深度嵌套的函数。通常，这不是问题，但有时，您可能会遇到某种类型的堆栈溢出错误。当我们的调用堆栈空间不足时，就会发生这种情况。通常，这种情况发生在递归函数中——一个调用自身的函数。

与我们的全局数据一样，调用堆栈由操作系统和可执行文件管理。在程序启动时，以及之后启动的每个线程，都会创建一个调用堆栈（其大小通常可以在操作系统中配置）。调用堆栈在程序的生命周期内存在，或者在线程的情况下，在线程的生命周期内存在。在程序或线程退出时，调用堆栈被释放。但是，当我们的全局数据具有所有程序全局数据时，调用堆栈仅具有当前执行的函数层次结构的堆栈帧。这在内存使用方面以及将堆栈帧推入和弹出堆栈的简单性方面都是高效的。

## 悬空指针danling_pointers

调用堆栈因其简单性和效率而令人惊叹。但它也很可怕：当函数返回时，它的任何本地数据都将变得无法访问。这听起来可能很合理，毕竟它是本地数据，但它可能会带来严重的问题。考虑这段代码：

```zig
const std = @import("std");

pub fn main() void {
	var user1 = User.init(1, 10);
	var user2 = User.init(2, 20);

	std.debug.print("User {d} has power of {d}\n", .{user1.id, user1.power});
	std.debug.print("User {d} has power of {d}\n", .{user2.id, user2.power});
}

pub const User = struct {
	id: u64,
	power: i32,

	fn init(id: u64, power: i32) *User{
		var user = User{
			.id = id,
			.power = power,
		};
		return &user;
	}
};
```

乍一看，可以合理地预期以下输出：

```text
User 1 has power of 10
User 2 has power of 20
```

 我有：

```text
User 2 has power of 20
User 9114745905793990681 has power of 0
```

您可能会得到不同的结果，但根据我的输出， `user1` 继承了 `user2` 的值，而 `user2` 值是无意义的。此代码的关键问题是 `User.init` 返回本地用户的地址 `&user` 。这称为悬空指针，即引用无效内存的指针。这是许多段错误的根源。

当堆栈帧从调用堆栈中弹出时，我们对该内存的任何引用都是无效的。尝试访问该内存的结果是未定义的。您可能会得到无意义的数据或段错误。我们可以尝试从我的输出中理解一些意义，但这不是我们想要、甚至不能依赖的行为。

此类错误的一个挑战是，在具有垃圾收集器的语言中，上述代码完全没问题。例如，Go 会检测本地 `user` 超出其作用域 `init` 函数的寿命，并在需要时确保其有效性（Go 如何做到这一点是一个实现细节，但它有一些选项，包括将数据移动到堆，这就是下一部分的内容）。

我很遗憾地说，另一个问题是它可能很难发现错误。在上面的示例中，我们显然返回了本地人的地址。但这种行为可能隐藏在嵌套函数和复杂数据类型的内部。您是否发现以下不完整代码可能存在问题：

```zig
fn read() !void {
	const input = try readUserInput();
	return Parser.parse(input);
}
```

无论 `Parser.parse` 返回什么都比 `input` 更长寿。如果 `Parser` 持有对 `input` 的引用，那将是一个悬空指针，等待着我们的应用程序崩溃。理想情况下，如果 `Parser` 需要 `input` 存活得和它一样长，它会制作它的副本，并且该副本将与它自己的生命周期相关联（下一篇将详细介绍这一点）部分）。但这里没有任何东西可以执行这个合同。 `Parser's` 文档可能会阐明它对 `input` 的期望或它的用途。如果缺少这一点，我们可能需要深入研究代码才能弄清楚。

解决我们最初的错误的简单方法是更改 `init` ，使其返回 `User` 而不是 `*User` （指向 `User` ).然后我们就可以 `return user;` 而不是 `return &user;` 。但这并不总是可能的。数据通常必须超越功能范围的严格界限。为此，我们有第三个内存区域，即堆，这是下一部分的主题。

在深入讨论堆之前，请注意，在本指南结束之前我们将看到一个悬空指针的最后一个示例。到那时，我们就已经涵盖了足够多的语言内容，可以给出一个看起来不那么复杂的例子了。我想重新讨论这个主题，因为对于来自垃圾收集语言的开发人员来说，这可能会导致错误和挫败感。这是你会掌握的事情。归根结底是要了解数据存在的位置和时间。

# 堆内存和分配器heap_memory

到目前为止，我们所看到的一切都受到预先尺寸要求的限制。数组始终具有编译时已知的长度（事实上，长度是类型的一部分）。我们所有的字符串都是字符串文字，它们具有编译时已知的长度。

此外，我们已经看到的两种类型的内存管理策略，全局数据和调用堆栈，虽然简单而高效，但也有局限性。两者都不能处理动态大小的数据，并且在数据生命周期方面都是严格的。

这部分分为两个主题。第一个是对第三个内存区域（堆）的总体概述。另一个是 Zig 管理堆内存的简单但独特的方法。即使您熟悉堆内存（例如使用 C 的 `malloc` ），您也需要阅读第一部分，因为它是 Zig 特有的。

##  堆heap

堆是我们可以使用的第三个也是最后一个内存区域。与全局数据和调用堆栈相比，堆有点狂野西部：任何事情都会发生。具体来说，在堆中，我们可以在运行时创建具有运行时已知大小的内存，并完全控制其生命周期。

调用堆栈令人惊奇，因为它管理数据的方式简单且可预测（通过推送和弹出堆栈帧）。这个好处也是一个缺点：数据的生命周期与其在调用堆栈上的位置相关。堆则恰恰相反。它没有内置的生命周期，因此我们的数据可以根据需要存在很长或很短的时间。这个好处也是它的缺点：它没有内置的生命周期，所以如果我们不释放数据，没有人会这样做。

让我们看一个例子：

```zig
const std = @import("std");

pub fn main() !void {
	// we'll be talking about allocators shortly
	var gpa = std.heap.GeneralPurposeAllocator(.{}){};
	const allocator = gpa.allocator();

	// ** The next two lines are the important ones **
	var arr = try allocator.alloc(usize, try getRandomCount());
	defer allocator.free(arr);

	for (0..arr.len) |i| {
		arr[i] = i;
	}
	std.debug.print("{any}\n", .{arr});
}

fn getRandomCount() !u8 {
	var seed: u64 = undefined;
	try std.os.getrandom(std.mem.asBytes(&seed));
	var random = std.rand.DefaultPrng.init(seed);
	return random.random().uintAtMost(u8, 5) + 5;
}
```

我们很快就会介绍 Zig 分配器，现在知道 `allocator` 是 `std.mem.Allocator` 。我们使用它的两个方法： `alloc` 和 `free` 。因为我们使用 `try` 调用 `allocator.alloc` ，所以我们知道它可能会失败。目前，唯一可能的错误是 `OutOfMemory` 。它的参数主要告诉我们它是如何工作的：它需要一个类型（ `T` ）和一个计数，如果成功，返回一个 `[]T` 的切片。这种分配发生在运行时——它必须发生，我们的计数只有在运行时才知道。

作为一般规则，每个 `alloc` 都会有一个相应的 `free` 。 `alloc` 分配内存， `free` 释放它。不要让这个简单的代码限制了您的想象力。这种 `try alloc` + `defer free` 模式很常见，并且有充分的理由：释放靠近我们分配的位置是相对万无一失的。但同样常见的是在一个地方分配而在另一个地方释放。正如我们之前所说，堆没有内置的生命周期管理。您可以在 HTTP 处理程序中分配内存并在后台线程中释放内存，这是代码的两个完全独立的部分。

## 延迟与错误延迟

作为一个小绕道，上面的代码引入了一个新的语言功能： `defer` ，它在作用域退出时执行给定的代码或块。 “范围退出”包括到达范围的末尾或从范围返回。 `defer` 与分配器或内存管理并不严格相关；您可以使用它来执行任何代码。但上面的用法很常见。

Zig 的 defer 与 Go 的 defer 类似，但有一个主要区别。在 Zig 中，延迟将在其包含范围的末尾运行。在 Go 中，defer 在包含函数的末尾运行。 Zig 的方法可能并不令人惊讶，除非您是 Go 开发人员。

`defer` 的相对对象是 `errdefer` ，它同样在作用域退出时执行给定的代码或块，但仅在返回错误时执行。当进行更复杂的设置并且由于错误而必须撤消先前的分配时，这非常有用。

下面的例子是复杂性的跳跃。它展示了 `errdefer` 和看到 `init` 分配和 `deinit` 释放的常见模式：

```zig
const std = @import("std");
const Allocator = std.mem.Allocator;

pub const Game = struct {
	players: []Player,
	history: []Move,
	allocator: Allocator,

	fn init(allocator: Allocator, player_count: usize) !Game {
		var players = try allocator.alloc(Player, player_count);
		errdefer allocator.free(players);

		// store 10 most recent moves per player
		var history = try allocator.alloc(Move, player_count * 10);

		return .{
			.players = players,
			.history = history,
			.allocator = allocator,
		};
	}

	fn deinit(game: Game) void {
		const allocator = game.allocator;
		allocator.free(game.players);
		allocator.free(game.history);
	}
};
```

希望这突出了两件事。首先， `errdefer` 的用处。正常情况下， `players` 在 `init` 中分配，在 `deinit` 中释放。但是，当 `history` 初始化失败时，会出现一种边缘情况。在这种情况下，也只有在这种情况下，我们需要撤消 `players` 的分配。

此代码的第二个值得注意的方面是我们的两个动态分配的切片 `players` 和 `history` 的生命周期基于我们的应用程序逻辑。没有规则规定何时必须调用 `deinit` 或谁必须调用它。这很好，因为它给了我们任意的生命周期，但也很糟糕，因为我们可能会因为不调用 `deinit` 或多次调用它而把它搞砸。

名称 `init` 和 `deinit` 并不特殊。它们正是 Zig 标准库所使用的以及社区所采用的。在某些情况下，包括在标准库中，使用 `open` 和 `close` 或其他更合适的名称。

## 双重释放和内存泄漏memory_leaks

就在上面，我提到没有任何规则来规定何时必须释放某些东西。但这并不完全正确，有一些重要的规则，除非您自己小心谨慎，否则它们不会被强制执行。

第一条规则是不能两次释放相同的内存。

```zig
const std = @import("std");

pub fn main() !void {
	var gpa = std.heap.GeneralPurposeAllocator(.{}){};
	const allocator = gpa.allocator();

	var arr = try allocator.alloc(usize, 4);
	allocator.free(arr);
	allocator.free(arr);

	std.debug.print("This won't get printed\n", .{});
}
```

该代码的最后一行是预言性的，它不会被打印。这是因为我们 `free` 相同的内存两次。这称为双重释放并且无效。这看起来很容易避免，但在具有复杂生命周期的大型项目中，可能很难追踪。

第二条规则是你不能释放没有引用的内存。这听起来似乎很明显，但并不总是清楚谁负责释放它。以下创建一个新的小写字符串：

```zig
const std = @import("std");
const Allocator = std.mem.Allocator;

fn allocLower(allocator: Allocator, str: []const u8) ![]const u8 {
	var dest = try allocator.alloc(u8, str.len);

	for (str, 0..) |c, i| {
		dest[i] = switch (c) {
			'A'...'Z' => c + 32,
			else => c,
		};
	}

	return dest;
}
```

上面的代码没问题。但以下用法不是：

```zig
// For this specific code, we should have used std.ascii.eqlIgnoreCase
fn isSpecial(allocator: Allocator, name: [] const u8) !bool {
	const lower = try allocLower(allocator, name);
	return std.mem.eql(u8, lower, "admin");
}
```

这是内存泄漏。 `allocLower` 中创建的内存永远不会被释放。不仅如此，一旦 `isSpecial` 返回，它就永远无法被释放。在具有垃圾收集器的语言中，当数据变得无法访问时，垃圾收集器最终将释放它。但在上面的代码中，一旦 `isSpecial` 返回，我们就失去了对已分配内存的唯一引用，即 `lower` 变量。内存会消失，直到我们的进程退出。我们的函数可能只会泄漏几个字节，但如果它是一个长时间运行的进程并且重复调用该函数，它就会累积起来，最终会耗尽内存。

至少在双重释放的情况下，我们会遭遇严重崩溃。内存泄漏可能是阴险的。这不仅仅是根本原因难以识别。非常小的泄漏或不经常执行的代码中的泄漏甚至很难检测到。这是一个非常常见的问题，Zig 确实提供了帮助，我们将在讨论分配器时看到这一点。

## create

`std.mem.Allocator` 的 `alloc` 方法返回一个切片，其长度作为第二个参数传递。如果您想要单个值，请使用 `create` 和 `destroy` 而不是 `alloc` 和 `free` 。前面几部分，在学习指针时，我们创建了一个 `User` 并尝试增强其功能。这是使用 `create:` 的该代码的基于堆的工作版本

```zig
const std = @import("std");

pub fn main() !void {
	// again, we'll talk about allocators soon!
	var gpa = std.heap.GeneralPurposeAllocator(.{}){};
	const allocator = gpa.allocator();

	// create a User on the heap
	var user = try allocator.create(User);

	// free the memory allocated for the user at the end of this scope
	defer allocator.destroy(user);

	user.id = 1;
	user.power = 100;

	// this line has been added
	levelUp(user);
	std.debug.print("User {d} has power of {d}\n", .{user.id, user.power});
}

fn levelUp(user: *User) void {
	user.power += 1;
}

pub const User = struct {
	id: u64,
	power: i32,
};
```

`create` 方法采用单个参数，即类型 ( `T` )。它返回指向该类型或错误的指针，即 `!*T` 。也许您想知道如果我们创建了 `user` 但没有设置 `id` 和/或 `power` ，会发生什么。这就像将这些字段设置为 `undefined` 并且行为是未定义的。

当我们探索悬空指针时，我们有一个函数错误地返回本地用户的地址：

```zig
pub const User = struct {
	fn init(id: u64, power: i32) *User{
		var user = User{
			.id = id,
			.power = power,
		};
		// this is a dangling pointer
		return &user;
	}
};
```

在这种情况下，返回 `User` 可能更有意义。但有时您会希望函数返回指向它创建的内容的指针。当您希望生命周期摆脱调用堆栈的僵化时，您可以这样做。为了解决上面的悬空指针问题，我们可以使用 `create` ：

```zig
// our return type changed, since init can now fail
// *User -> !*User
fn init(allocator: std.mem.Allocator, id: u64, power: i32) !*User{
	var user = try allocator.create(User);
	user.* = .{
		.id = id,
		.power = power,
	};
	return user;
}
```

我引入了新语法 `user.* = .{...}` 。这有点奇怪，我不喜欢它，但你会看到的。右侧是您已经看到的内容：它是具有推断类型的结构初始值设定项。我们可以明确地使用： `user.* = User{...}` 。左侧 `user.*` 是我们取消引用指针的方式。 `&` 接受 `T` 并给我们 `*T` 。 `.*` 是相反的，应用于 `*T` 类型的值，它给我们 `T` 。请记住， `create` 返回 `!*User` ，因此我们的 `user` 类型为 `*User` 。

## 分配器allocators

Zig 的核心原则之一是无隐藏内存分配。根据您的背景，这可能听起来不太特别。但这与 C 语言中使用标准库的 `malloc` 函数分配内存的情况形成鲜明对比。在 C 中，如果您想知道函数是否分配内存，您需要阅读源代码并查找对 `malloc` 的调用。

Zig 没有默认分配器。在上述所有示例中，分配内存的函数都采用 `std.mem.Allocator` 参数。按照惯例，这通常是第一个参数。 Zig 的所有标准库和大多数第三方库都要求调用者在打算分配内存时提供分配器。

这种明确性可以采取两种形式之一。在简单的情况下，分配器在每个函数调用上提供。这方面的例子有很多，但 `std.fmt.allocPrint` 可能是您迟早需要的一个。它与我们一直使用的 `std.debug.print` 类似，但分配并返回一个字符串，而不是将其写入 stderr：

```zig
const say = std.fmt.allocPrint(allocator, "It's over {d}!!!", .{user.power});
defer allocator.free(say);
```

另一种形式是将分配器传递给 `init` ，然后由对象在内部使用。我们在上面的 `Game` 结构中看到了这一点。这不太明确，因为您已经为对象提供了一个要使用的分配器，但您不知道哪个方法调用将实际分配。这种方法对于长寿命的对象更实用。

注入分配器的优点不仅在于明确，而且还在于灵活性。 `std.mem.Allocator` 是一个提供 `alloc` 、 `free` 、 `create` 和 `destroy` 函数以及一些功能的接口其他的。到目前为止，我们只看到了 `std.heap.GeneralPurposeAllocator` ，但标准库或第三方库中提供了其他实现。

Zig 没有用于创建界面的良好语法糖。接口生命行为的一种模式是标记联合，尽管与真正的接口相比，它相对受到限制。其他模式已经出现并在整个标准库中使用，例如 `std.mem.Allocator` 。本指南不探讨这些界面模式。

如果您正在构建一个库，那么最好接受 `std.mem.Allocator` 并让您的库的用户决定使用哪个分配器实现。否则，您需要选择正确的分配器，并且正如我们将看到的，这些分配器并不相互排斥。有充分的理由在程序中创建不同的分配器。

## 通用分配器heap_memory gpa

顾名思义， `std.heap.GeneralPurposeAllocator` 是一个全面的“通用”线程安全分配器，可以用作应用程序的主分配器。对于许多程序来说，这将是唯一需要的分配器。在程序启动时，会创建一个分配器并将其传递给需要它的函数。我的 HTTP 服务器库中的示例代码就是一个很好的例子：

```zig
const std = @import("std");
const httpz = @import("httpz");

pub fn main() !void {
	// create our general purpose allocator
	var gpa = std.heap.GeneralPurposeAllocator(.{}){};

	// get an std.mem.Allocator from it
	const allocator = gpa.allocator();

	// pass our allocator to functions and libraries that require it
	var server = try httpz.Server().init(allocator, .{.port = 5882});

	var router = server.router();
	router.get("/api/user/:id", getUser);

	// blocks the current thread
	try server.listen();
}
```

我们创建 `GeneralPurposeAllocator` ，从中获取 `std.mem.Allocator` 并将其传递给 HTTP 服务器的 `init` 函数。在更复杂的项目中， `allocator` 将被传递到代码的多个部分，每个部分都可能将其传递给自己的函数、对象和依赖项。

您可能会注意到创建 `gpa` 的语法有点奇怪。这是什么： `GeneralPurposeAllocator(.{}){}` ？这些都是我们以前见过的东西，只是粉碎在一起。 `std.heap.GeneralPurposeAllocator` 是一个函数，由于它使用 PascalCase，我们知道它返回一个类型。 （我们将在下一部分中详细讨论泛型）。知道它返回一个类型，也许这个更明确的版本会更容易破译：

```zig
const T = std.heap.GeneralPurposeAllocator(.{});
var gpa = T{};

// is the same as:

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
```

也许您仍然不确定 `.{}` 的含义。这也是我们之前见过的：它是一个具有隐式类型的结构初始值设定项。类型是什么以及字段在哪里？该类型是 `std.heap.general_purpose_allocator.Config` ，尽管它没有像这样直接公开，这是我们不明确的原因之一。没有设置任何字段，因为 `Config` 结构定义了我们将使用的默认值。这是配置/选项的常见模式。事实上，当我们将 `.{.port = 5882}` 传递给 `init` 时，我们会在几行后再次看到它。在本例中，我们对除一个字段 `port` 之外的所有字段使用默认值。

## 测试testing

希望当我们谈论内存泄漏时您已经感到足够的困扰，并且当我提到 Zig 可以提供帮助时您渴望了解更多信息。此帮助来自 `std.testing.allocator` ，它是一个 `std.mem.Allocator` 。目前它是使用 `GeneralPurposeAllocator` 实现的，并在 Zig 的测试运行器中添加了集成，但这只是一个实现细节。重要的是，如果我们在测试中使用 `std.testing.allocator` ，我们就可以捕获大多数内存泄漏。

您可能已经熟悉动态数组，通常称为 ArrayList。在许多动态编程语言中，所有数组都是动态数组。动态数组支持可变数量的元素。 Zig 有一个合适的通用 ArrayList，但我们将专门创建一个来保存整数并演示泄漏检测：

```zig
pub const IntList = struct {
	pos: usize,
	items: []i64,
	allocator: Allocator,

	fn init(allocator: Allocator) !IntList {
		return .{
			.pos = 0,
			.allocator = allocator,
			.items = try allocator.alloc(i64, 4),
		};
	}

	fn deinit(self: IntList) void {
		self.allocator.free(self.items);
	}

	fn add(self: *IntList, value: i64) !void {
		const pos = self.pos;
		const len = self.items.len;

		if (pos == len) {
			// we've run out of space
			// create a new slice that's twice as large
			var larger = try self.allocator.alloc(i64, len * 2);

			// copy the items we previously added to our new space
			@memcpy(larger[0..len], self.items);

			self.items = larger;
		}

		self.items[pos] = value;
		self.pos = pos + 1;
	}
};
```

有趣的部分发生在 `add` 中，此时 `pos == len` 表明我们已经填充了当前数组并需要创建一个更大的数组。我们可以像这样使用 `IntList` ：

```zig
const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn main() !void {
	var gpa = std.heap.GeneralPurposeAllocator(.{}){};
	const allocator = gpa.allocator();

	var list = try IntList.init(allocator);
	defer list.deinit();

	for (0..10) |i| {
		try list.add(@intCast(i));
	}

	std.debug.print("{any}\n", .{list.items[0..list.pos]});
}
```

代码运行并打印正确的结果。然而，即使我们确实在 `list` 上调用了 `deinit` ，仍然存在内存泄漏。如果您没有注意到也没关系，因为我们将编写一个测试并使用 `std.testing.allocator` ：

```zig
const testing = std.testing;
test "IntList: add" {
	// We're using testing.allocator here!
	var list = try IntList.init(testing.allocator);
	defer list.deinit();

	for (0..5) |i| {
		try list.add(@intCast(i+10));
	}

	try testing.expectEqual(@as(usize, 5), list.pos);
	try testing.expectEqual(@as(i64, 10), list.items[0]);
	try testing.expectEqual(@as(i64, 11), list.items[1]);
	try testing.expectEqual(@as(i64, 12), list.items[2]);
	try testing.expectEqual(@as(i64, 13), list.items[3]);
	try testing.expectEqual(@as(i64, 14), list.items[4]);
}
```

`@as` 是执行类型强制的内置函数。如果您想知道为什么我们的测试必须使用这么多它们，那么您并不是唯一一个。从技术上讲，这是因为第二个参数“实际”被强制为第一个参数“预期”。在上面，我们的“预期”都是 `comptime_int` ，这会导致问题。许多人，包括我自己，都认为这是一种奇怪而不幸的行为。

如果您按照步骤操作，请将测试放在与 `IntList` 和 `main` 相同的文件中。 Zig 测试通常写在同一个文件中，通常靠近他们正在测试的代码。当我们使用 `zig test learning.zig` 运行测试时，我们遇到了惊人的失败：

```text
Test [1/1] test.IntList: add... [gpa] (err): memory address 0x101154000 leaked:
/code/zig/learning.zig:26:32: 0x100f707b7 in init (test)
   .items = try allocator.alloc(i64, 2),
                               ^
/code/zig/learning.zig:55:29: 0x100f711df in test.IntList: add (test)
 var list = try IntList.init(testing.allocator);

... MORE STACK INFO ...

[gpa] (err): memory address 0x101184000 leaked:
/code/test/learning.zig:40:41: 0x100f70c73 in add (test)
   var larger = try self.allocator.alloc(i64, len * 2);
                                        ^
/code/test/learning.zig:59:15: 0x100f7130f in test.IntList: add (test)
  try list.add(@intCast(i+10));
```

We have multiple memory leaks. Thankfully the testing allocator tells us exactly where the leaking memory was allocated. Are you able to spot the leak now? If not, remember that, in general, every `alloc` should have a corresponding `free`. Our code calls `free` once, in `deinit`. However, `alloc` is called once in `init` and then every time `add` is called and we need more space. Every time we `alloc` more space, we need to `free` the previous `self.items`:

```zig
// existing code
var larger = try self.allocator.alloc(i64, len * 2);
@memcpy(larger[0..len], self.items);

// Added code
// free the previous allocation
self.allocator.free(self.items);
```

将项目复制到 `larger` 切片后添加最后一行即可解决问题。如果运行 `zig test learning.zig` ，应该不会出现错误。

## arena

GeneralPurposeAllocator 是一个合理的默认值，因为它在所有可能的情况下都能很好地工作。但在程序中，您可能会遇到可以从更专门的分配器中受益的分配模式。一个例子是需要短暂的状态，当处理完成时可以将其丢弃。解析器经常有这样的需求。骨架 `parse` 函数可能如下所示：

```zig
fn parse(allocator: Allocator, input: []const u8) !Something {
	var state = State{
		.buf = try allocator.alloc(u8, 512),
		.nesting = try allocator.alloc(NestType, 10),
	};
	defer allocator.free(state.buf);
	defer allocator.free(state.nesting);

	return parseInternal(allocator, state, input);
}
```

虽然这不太难管理，但 `parseInternal` 可能需要其他需要释放的短期分配。作为一种替代方案，我们可以创建一个 ArenaAllocator，它允许我们一次性释放所有分配：

```zig
fn parse(allocator: Allocator, input: []const u8) !Something {
	// create an ArenaAllocator from the supplied allocator
	var arena = std.heap.ArenaAllocator.init(allocator);

	// this will free anything created from this arena
	defer arena.deinit();

	// create an std.mem.Allocator from the arena, this will be
	// the allocator we'll use internally
	const aa = arena.allocator();

	var state = State{
		// we're using aa here!
		.buf = try aa.alloc(u8, 512),

		// we're using aa here!
		.nesting = try aa.alloc(NestType, 10),
	};

	// we're passing aa here, so any we're guaranteed that
	// any other allocation will be in our arena
	return parseInternal(aa, state, input);
}
```

`ArenaAllocator` 采用一个子分配器，在本例中是传递给 `init` 的分配器，并创建一个新的 `std.mem.Allocator` 。当这个新的分配器用于分配或创建内存时，我们不需要调用 `free` 或 `destroy` 。当我们在 `arena` 上调用 `deinit` 时，所有内容都会被释放。事实上，ArenaAllocator 的 `free` 和 `destroy` 不执行任何操作。

`ArenaAllocator` 必须小心使用。由于无法释放单独的分配，因此您需要确保竞技场的 `deinit` 将在合理的内存增长范围内被调用。有趣的是，这些知识可以是内部的，也可以是外部的。例如，在上面的框架中，从解析器内部利用 ArenaAllocator 是有意义的，因为状态生命周期的细节是内部事务。

像 ArenaAllocator 这样具有释放所有先前分配机制的分配器可能会打破每个 `alloc` 应该有一个相应的 `free` 的规则。但是，如果您收到 `std.mem.Allocator` ，则不应对底层实现做出任何假设。

对于我们的 `IntList` 却不能这样说。它可以用来存储 10 或 1000 万个值。它的生命周期可以以毫秒或几周为单位。它无法决定要使用的分配器类型。使用 `IntList` 的代码具有这些知识。最初，我们像这样管理 `IntList` ：

```zig
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

var list = try IntList.init(allocator);
defer list.deinit();
```

我们可以选择提供 ArenaAllocator：

```zig
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

var arena = std.heap.ArenaAllocator.init(allocator);
defer arena.deinit();
const aa = arena.allocator();

var list = try IntList.init(aa);

// I'm honestly torn on whether or not we should call list.deinit.
// Technically, we don't have to since we call defer arena.deinit() above.
defer list.deinit();

...
```

我们不需要更改 `IntList` 因为它只处理 `std.mem.Allocator` 。如果 `IntList` 确实在内部创建了自己的竞技场，那也可以。您没有理由不能在竞技场中创建竞技场。

作为最后一个简单的例子，我上面提到的 HTTP 服务器在 `Response` 上公开了一个 arena 分配器。一旦发送响应，竞技场就会被清空。 arena 的可预测生命周期（从请求开始到请求结束）使其成为一个有效的选择。在性能和易用性方面高效。

## 固定缓冲区fixedbuffer

我们要查看的最后一个分配器是 `std.heap.FixedBufferAllocator` ，它从我们提供的缓冲区（即 `[]u8` ）分配内存。这个分配器有两个主要好处。首先，由于它可能使用的所有内存都是预先创建的，因此速度很快。其次，它自然限制了可以分配的内存量。这种硬性限制也可以被视为一个缺点。另一个缺点是 `free` 和 `destroy` 仅适用于最后分配/创建的项目（想想堆栈）。释放非最后的分配可以安全地调用，但不会执行任何操作。

```zig
const std = @import("std");

pub fn main() !void {
	var buf: [150]u8 = undefined;
	var fa = std.heap.FixedBufferAllocator.init(&buf);
	defer fa.reset();

	const allocator = fa.allocator();

	const json = try std.json.stringifyAlloc(allocator, .{
		.this_is = "an anonymous struct",
		.above = true,
		.last_param = "are options",
	}, .{.whitespace = .indent_2});

	std.debug.print("{s}\n", .{json});
}
```

 以上打印：

```text
{
  "this_is": "an anonymous struct",
  "above": true,
  "last_param": "are options"
}
```

但是将我们的 `buf` 更改为 `[120]u8` ，您将收到 `OutOfMemory` 错误。

固定缓冲区分配器（以及较小程度上的竞技场分配器）的常见模式是 `reset` 它们并重用它们。这将释放所有以前的分配并允许重新使用分配器。

由于没有默认分配器，Zig 在分配方面既透明又灵活。 `std.mem.Allocator` 接口功能强大，允许专门的分配器包装更通用的分配器，正如我们在 `ArenaAllocator` 中看到的那样。

更一般地说，堆分配的权力和相关责任是显而易见的。分配具有任意生命周期的任意大小的内存的能力对于大多数程序来说至关重要。

然而，由于动态内存带来的复杂性，您应该密切关注替代方案。例如，上面我们使用了 `std.fmt.allocPrint` 但标准库也有一个 `std.fmt.bufPrint` 。后者采用缓冲区而不是分配器：

```zig
const std = @import("std");

pub fn main() !void {
	const name = "Leto";

	var buf: [100]u8 = undefined;
	const greeting = try std.fmt.bufPrint(&buf, "Hello {s}", .{name});

	std.debug.print("{s}\n", .{greeting});
}
```

此 API 将内存管理负担转移给调用者。如果我们有更长的 `name` 或更小的 `buf` ，我们的 `bufPrint` 可能会返回 `NoSpaceLeft` 错误。但在很多情况下，应用程序都有已知的限制，例如最大名称长度。在这些情况下， `bufPrint` 更安全、更快。

动态分配的另一种可能的替代方案是将数据流式传输到 `std.io.Writer` 。与我们的 `Allocator` 一样， `Writer` 是由许多类型（例如文件）实现的接口。上面，我们使用 `stringifyAlloc` 将 JSON 序列化为动态分配的字符串。我们可以使用 `stringify` 并提供 `Writer` ：

```zig
pub fn main() !void {
	const out = std.io.getStdOut();

	try std.json.stringify(.{
		.this_is = "an anonymous struct",
		.above = true,
		.last_param = "are options",
	}, .{.whitespace = .indent_2}, out.writer());
}
```

虽然分配器通常作为函数的第一个参数给出，但编写器通常是最后一个参数。 ಠ_ಠ

在许多情况下，将我们的编写器包装在 `std.io.BufferedWriter` 中会带来很好的性能提升。

目标不是消除所有动态分配。这是行不通的，因为这些替代方案仅在特定情况下才有意义。但现在您有很多选择可供选择。从堆栈帧到通用分配器，以及介于两者之间的所有东西，例如静态缓冲区、流写入器和专用分配器。

# 泛型generics

在上一部分中，我们构建了一个名为 `IntList` 的简单动态数组。数据结构的目标是存储动态数量的值。尽管我们使用的算法适用于任何类型的数据，但我们的实现与 `i64` 值相关。输入泛型，其目标是从特定类型中抽象算法和数据结构。

许多语言使用特殊语法和特定于泛型的规则来实现泛型。对于 Zig，泛型不再是特定功能，而是语言能力的表达。具体来说，泛型利用 Zig 强大的编译时元编程。

我们首先看一个愚蠢的例子，只是为了了解我们的方向：

```zig
const std = @import("std");

pub fn main() !void {
	var arr: IntArray(3) = undefined;
	arr[0] = 1;
	arr[1] = 10;
	arr[2] = 100;
	std.debug.print("{any}\n", .{arr});
}

fn IntArray(comptime length: usize) type {
	return [length]i64;
}
```

上面打印 `{ 1, 10, 100 }` 。有趣的是，我们有一个返回 `type` 的函数（因此该函数是 PascalCase）。不仅仅是任何类型，而是基于函数参数的类型。这段代码之所以有效，是因为我们将 `length` 声明为 `comptime` 。也就是说，我们要求任何调用 `IntArray` 的人传递一个编译时已知的 `length` 参数。这是必要的，因为我们的函数返回 `type` 和 `types` 必须始终在编译时已知。

函数可以返回任何类型，而不仅仅是基元和数组。例如，通过一个小的改变，我们可以让它返回一个结构：

```zig
const std = @import("std");

pub fn main() !void {
	var arr: IntArray(3) = undefined;
	arr.items[0] = 1;
	arr.items[1] = 10;
	arr.items[2] = 100;
	std.debug.print("{any}\n", .{arr.items});
}

fn IntArray(comptime length: usize) type {
	return struct {
		items: [length]i64,
	};
}
```

这可能看起来很奇怪，但 `arr's` 类型确实是 `IntArray(3)` 。它是与任何其他类型类似的类型，并且 `arr` 是与任何其他值类似的值。如果我们调用 `IntArray(7)` 那将是不同的类型。也许我们可以让事情变得更整洁：

```zig
const std = @import("std");

pub fn main() !void {
	var arr = IntArray(3).init();
	arr.items[0] = 1;
	arr.items[1] = 10;
	arr.items[2] = 100;
	std.debug.print("{any}\n", .{arr.items});
}

fn IntArray(comptime length: usize) type {
	return struct {
		items: [length]i64,

		fn init() IntArray(length) {
			return .{
				.items = undefined,
			};
		}
	};
}
```

乍一看，这可能看起来不太整洁。但除了无名和嵌套在函数中之外，我们的结构看起来与我们迄今为止见过的所有其他结构一样。它有字段，它有功能。你知道他们怎么说，如果它看起来像一只鸭子……嗯，这看起来、游泳和嘎嘎叫都像一个正常的结构，因为它确实是。

我们采用这种方法是为了熟悉返回类型的函数和附带的语法。为了获得更典型的泛型，我们需要进行最后一项更改：我们的函数必须采用 `type` 。实际上，这是一个很小的变化，但是 `type` 感觉比 `usize` 更抽象，所以我们慢慢来。让我们进行一次飞跃，修改之前的 `IntList` 以适用于任何类型。我们将从一个骨架开始：

```zig
fn List(comptime T: type) type {
	return struct {
		pos: usize,
		items: []T,
		allocator: Allocator,

		fn init(allocator: Allocator) !List(T) {
			return .{
				.pos = 0,
				.allocator = allocator,
				.items = try allocator.alloc(T, 4),
			};
		}
	}
};
```

上面的 `struct` 与我们的 `IntList` 几乎相同，只是 `i64` 已替换为 `T` 。 `T` 可能看起来很特殊，但它只是一个变量名。我们可以将其称为 `item_type` 。但是，根据 Zig 的命名约定， `type` 类型的变量采用 PascalCase。

无论好坏，使用单个字母来表示类型参数比 Zig 更古老。 `T` 是大多数语言中的常见默认值，但您会看到特定于上下文的变体，例如使用 `K` 和 `V` 作为其键和值参数的哈希映射类型。

如果您不确定我们的骨架，请考虑我们使用 `T` 的两个地方： `items: []T` 和 `allocator.alloc(T, 4)` 。当我们想要使用这个泛型类型时，我们将使用以下方法创建一个实例：

```zig
var list = try List(u32).init(allocator);
```

编译代码时，编译器通过查找每个 `T` 并将其替换为 `u32` 来创建新类型。如果我们再次使用 `List(u32)` ，编译器将重新使用之前创建的类型。如果我们为 `T` 指定新值，例如 `List(bool)` 或 `List(User)` ，则会创建新类型。

为了完成我们的通用 `List` ，我们可以逐字复制并粘贴 `IntList` 代码的其余部分，并将 `i64` 替换为 `T` 。这是一个完整的工作示例：

```zig
const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn main() !void {
	var gpa = std.heap.GeneralPurposeAllocator(.{}){};
	const allocator = gpa.allocator();

	var list = try List(u32).init(allocator);
	defer list.deinit();

	for (0..10) |i| {
		try list.add(@intCast(i));
	}

	std.debug.print("{any}\n", .{list.items[0..list.pos]});
}

fn List(comptime T: type) type {
	return struct {
		pos: usize,
		items: []T,
		allocator: Allocator,

		fn init(allocator: Allocator) !List(T) {
			return .{
				.pos = 0,
				.allocator = allocator,
				.items = try allocator.alloc(T, 4),
			};
		}

		fn deinit(self: List(T)) void {
			self.allocator.free(self.items);
		}

		fn add(self: *List(T), value: T) !void {
			const pos = self.pos;
			const len = self.items.len;

			if (pos == len) {
				// we've run out of space
				// create a new slice that's twice as large
				var larger = try self.allocator.alloc(T, len * 2);

				// copy the items we previously added to our new space
				@memcpy(larger[0..len], self.items);

				self.allocator.free(self.items);

				self.items = larger;
			}

			self.items[pos] = value;
			self.pos = pos + 1;
		}
	};
}
```

我们的 `init` 函数返回 `List(T)` ，而我们的 `deinit` 和 `add` 函数采用 `List(T)` 和 `*List(T)` 。在我们的简单类中，这很好，但对于大型数据结构，编写完整的通用名称可能会变得有点乏味，特别是如果我们有多个类型参数（例如，哈希映射需要单独的 `type` 作为其键和值）。 `@This()` 内置函数从调用它的地方返回最里面的 `type` 。最有可能的是，我们的 `List(T)` 会写成：

```zig
fn List(comptime T: type) type {
	return struct {
		pos: usize,
		items: []T,
		allocator: Allocator,

		// Added
		const Self = @This();

		fn init(allocator: Allocator) !Self {
			// ... same code
		}

		fn deinit(self: Self) void {
			// .. same code
		}

		fn add(self: *Self, value: T) !void {
			// .. same code
		}
	};
}
```

`Self` 不是一个特殊的名称，它只是一个变量，并且它是 PascalCase 因为它的值是 `type` 。我们可以在之前使用 `List(T)` 的地方使用 `Self` 。

我们可以创建更复杂的示例，具有多个类型参数和更高级的算法。但是，最终，核心通用代码将与上面的简单示例没有什么不同。在下一部分中，当我们查看标准库的 `ArrayList(T)` 和 `StringHashMap(V)` 时，我们将再次触及泛型。

# 使用zig进行编程

现在已经涵盖了大部分语言，我们将通过重新审视一些主题并研究使用 Zig 的一些更实际的方面来结束本文。在此过程中，我们将介绍更多的标准库并提供一些不那么琐碎的代码片段。

## 悬空指针danling_pointers

我们首先查看更多悬空指针的示例。这似乎是一件奇怪的事情，但如果您来自垃圾收集语言，这可能是您将面临的最大挑战。

你能猜出下面的输出是什么吗？

```zig
const std = @import("std");

pub fn main() !void {
	var gpa = std.heap.GeneralPurposeAllocator(.{}){};
	const allocator = gpa.allocator();

	var lookup = std.StringHashMap(User).init(allocator);
	defer lookup.deinit();

	const goku = User{.power = 9001};

	try lookup.put("Goku", goku);
	const entry = lookup.getPtr("Goku").?;

	// returns an optional, .? would panic if "Goku"
	// wasn't in our hashmap
	const entry = lookup.getPtr("Goku").?;

	std.debug.print("Goku's power is: {d}\n", .{entry.power});

	// returns true/false depending on if the item was removed
	_ = lookup.remove("Goku");

	std.debug.print("Goku's power is: {d}\n", .{entry.power});
}

const User = struct {
	power: i32,
};
```

当我运行这个时，我得到：

```text
Goku's power is: 9001
Goku's power is: -1431655766
```

此代码介绍了 Zig 的通用 `std.StringHashMap` ，它是 `std.AutoHashMap` 的专门版本，键类型设置为 `[]const u8` 。即使您不能 100% 确定发生了什么，也可以很好地猜测我的输出与我们的第二个 `print` 发生在我们 `remove` 来自 `lookup` 。注释掉对 `remove` 的调用，输出正常。

理解上述代码的关键是要了解数据/内存存在的位置，或者换句话说，谁拥有它。请记住，Zig 参数是按值传递的，也就是说，我们传递值的[浅]副本。 `lookup` 中的 `User` 与 `goku` 引用的内存不同。我们上面的代码有两个用户，每个用户都有自己的所有者。 `goku` 归 `main` 所有，其副本归 `lookup` 所有。

`getPtr` 方法返回一个指向映射中值的指针，在我们的例子中，它返回一个 `*User` 。问题就在这里， `remove` 使我们的 `entry` 指针无效。在此示例中， `getPtr` 和 `remove` 的接近使问题变得有些明显。但不难想象代码调用 `remove` 而不知道对该条目的引用保存在其他地方。

当我写这个例子时，我不确定会发生什么。 `remove` 可以通过设置内部标志来实现，将实际删除延迟到稍后的事件。如果是这样的话，上面的方法可能在我们的简单情况下“有效”，但在更复杂的情况下会失败。听起来调试起来非常困难。

除了不调用 `remove` 之外，我们还可以通过几种不同的方法来解决这个问题。首先，我们可以使用 `get` 而不是 `getPtr` 。这将返回 `User` 而不是 `*User` ，因此将返回 `lookup` 中值的副本。然后我们就有了三个 `Users` 。

1. 我们原来的 `goku` ，与函数相关联。
2. `lookup` 中的副本，由查找拥有。
3. 我们的副本 `entry` 的副本也与该函数相关联。

由于 `entry` 现在将是其自己的独立用户副本，因此从 `lookup` 中删除它不会使其无效。

另一种选择是将 `lookup's` 类型从 `StringHashMap(User)` 更改为 `StringHashMap(*const User)` 。这段代码的工作原理：

```zig
const std = @import("std");

pub fn main() !void {
	var gpa = std.heap.GeneralPurposeAllocator(.{}){};
	const allocator = gpa.allocator();

	// User -> *const User
	var lookup = std.StringHashMap(*const User).init(allocator);
	defer lookup.deinit();

	const goku = User{.power = 9001};

	// goku -> &goku
	try lookup.put("Goku", &goku);

	// getPtr -> get
	const entry = lookup.get("Goku").?;

	std.debug.print("Goku's power is: {d}\n", .{entry.power});
	_ = lookup.remove("Goku");
	std.debug.print("Goku's power is: {d}\n", .{entry.power});
}

const User = struct {
	power: i32,
};
```

上面的代码有很多微妙之处。首先，我们现在有一个 `User` 、 `goku` 。 `lookup` 和 `entry` 中的值都是对 `goku` 的引用。我们对 `remove` 的调用仍然会从 `lookup` 中删除该值，但该值只是 `user` 的地址，而不是 `user` 本身。如果我们坚持使用 `getPtr` ，我们会得到一个无效的 `**User` ，由于 `remove` 而无效。在这两种解决方案中，我们都必须使用 `get` 而不是 `getPtr` ，但在这种情况下，我们只是复制地址，而不是完整的 `User` 。对于大型物体，这可能是一个显着的差异。

由于所有内容都在一个函数中并且值很小，例如 `User` ，这仍然感觉像是一个人为创建的问题。我们需要一个合理地使数据所有权成为紧迫问题的例子。

## 所有权ownership

我喜欢哈希映射，因为它们是每个人都知道并且每个人都使用的东西。它们还有许多不同的用例，其中大多数您可能已经亲身体验过。虽然它们可以用作短期查找，但它们通常是长期存在的，因此需要同样长期存在的值。

此代码使用您在终端中输入的名称填充我们的 `lookup` 。空名称会停止提示循环。最后，它检测“Leto”是否是提供的名称之一。

```zig
const std = @import("std");

pub fn main() !void {
	var gpa = std.heap.GeneralPurposeAllocator(.{}){};
	const allocator = gpa.allocator();

	var lookup = std.StringHashMap(User).init(allocator);
	defer lookup.deinit();

	// stdin is an std.io.Reader
	// the opposite of an std.io.Writer, which we already saw
	const stdin = std.io.getStdIn().reader();

	// stdout is an std.io.Writer
	const stdout = std.io.getStdOut().writer();

	var i: i32 = 0;
	while (true) : (i += 1) {
		var buf: [30]u8 = undefined;
		try stdout.print("Please enter a name: ", .{});
		if (try stdin.readUntilDelimiterOrEof(&buf, '\n')) |name| {
			if (name.len == 0) {
				break;
			}
			try lookup.put(name, .{.power = i});
		}
	}

	const has_leto = lookup.contains("Leto");
	std.debug.print("{any}\n", .{has_leto});
}

const User = struct {
	power: i32,
};
```

代码区分大小写，但无论我们输入“Leto”有多完美， `contains` 始终返回 `false` 。让我们通过迭代 `lookup` 并转储键和值来调试它：

```zig
// Place this code after the while loop

var it = lookup.iterator();
while (it.next()) |kv| {
	std.debug.print("{s} == {any}\n", .{kv.key_ptr.*, kv.value_ptr.*});
}
```

这种迭代器模式在 Zig 中很常见，并且依赖于 `while` 和可选类型之间的协同作用。我们的迭代器项返回指向键和值的指针，因此我们使用 `.*` 取消引用它们以访问实际值而不是地址。输出将取决于您输入的内容，但我得到：

```text
Please enter a name: Paul
Please enter a name: Teg
Please enter a name: Leto
Please enter a name:

�� == learning.User{ .power = 1 }

��� == learning.User{ .power = 0 }

��� == learning.User{ .power = 2 }
false
```

值看起来不错，但键不行。如果你不确定发生了什么，那可能是我的错。早些时候，我故意误导了你的注意力。我说过哈希映射通常是长期存在的，因此需要长期存在的值。事实是，它们需要长期存在的值以及长期存在的密钥！请注意， `buf` 是在 `while` 循环内定义的。当我们调用 `put` 时，我们为哈希映射提供了一个比哈希映射本身的生命周期短得多的键。将 `buf` 移到 `while` 循环之外可以解决我们的生命周期问题，但该缓冲区会在每次迭代中重用。它仍然不起作用，因为我们正在改变底层关键数据。

对于我们上面的代码，实际上只有一种解决方案：我们的 `lookup` 必须拥有密钥。我们需要添加一行并更改另一行：

```zig
// replace the existing lookup.put with these two lines
const owned_name = try allocator.dupe(u8, name);

// name -> owned_name
try lookup.put(owned_name, .{.power = i});
```

`dupe` 是我们以前没有见过的 `std.mem.Allocator` 的方法。它分配给定值的重复项。代码现在可以工作了，因为我们的键现在位于堆上，比 `lookup` 更长寿。事实上，我们在延长这些字符串的生命周期方面做得太好了：我们引入了内存泄漏。

您可能认为当我们调用 `lookup.deinit` 时，我们的键和值将会被释放。但没有一种 `StringHashMap` 可以使用的万能解决方案。首先，键可能是字符串文字，无法释放。其次，它们可能是用不同的分配器创建的。最后，虽然更高级，但在某些合法情况下，哈希映射可能不拥有密钥。

唯一的解决方案是我们自己释放密钥。此时，创建我们自己的 `UserLookup` 类型并将此清理逻辑封装在我们的 `deinit` 函数中可能是有意义的。我们会让事情变得混乱：

```zig
// replace the existing:
//   defer lookup.deinit();
// with:
defer {
	var it = lookup.keyIterator();
	while (it.next()) |key| {
		allocator.free(key.*);
	}
	lookup.deinit();
}
```

我们的 `defer` 逻辑是我们在块中看到的第一个逻辑，它释放每个键，然后取消初始化 `lookup` 。我们使用 `keyIterator` 仅迭代键。迭代器值是指向哈希映射中键条目的指针，即 `*[]const u8` 。我们想要释放实际值，因为这是我们通过 `dupe` 分配的值，因此我们使用 `.*` 取消引用该值。

我保证，我们已经讨论完了悬空指针和内存管理。我们所讨论的内容可能仍然不清楚或过于抽象。当您有更多实际问题需要解决时，最好重新审视这一点。也就是说，如果您打算编写任何重要的内容，那么您几乎肯定需要掌握这一点。当您感觉可以时，我强烈建议您采用提示循环示例并自己使用它。引入一个 `UserLookup` 类型来封装我们必须执行的所有内存管理。尝试使用 `*User` 值而不是 `User` ，在堆上创建用户并释放它们，就像我们释放键一样。编写涵盖新结构的测试，使用 `std.testing.allocator` 确保不会泄漏任何内存。

## ArrayList

您会很高兴知道您可以忘记我们的 `IntList` 和我们创建的通用替代方案。 Zig 有一个正确的动态数组实现： `std.ArrayList(T)` 。

这是非常标准的东西，但它是一种普遍需要和使用的数据结构，值得一看它的实际应用：

```zig
const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn main() !void {
	var gpa = std.heap.GeneralPurposeAllocator(.{}){};
	const allocator = gpa.allocator();

	var arr = std.ArrayList(User).init(allocator);
	defer {
		for (arr.items) |user| {
			user.deinit(allocator);
		}
		arr.deinit();
	}

	// stdin is an std.io.Reader
	// the opposite of an std.io.Writer, which we already saw
	const stdin = std.io.getStdIn().reader();

	// stdout is an std.io.Writer
	const stdout = std.io.getStdOut().writer();

	var i: i32 = 0;
	while (true) : (i += 1) {
		var buf: [30]u8 = undefined;
		try stdout.print("Please enter a name: ", .{});
		if (try stdin.readUntilDelimiterOrEof(&buf, '\n')) |name| {
			if (name.len == 0) {
				break;
			}
			const owned_name = try allocator.dupe(u8, name);
			try arr.append(.{.name = owned_name, .power = i});
		}
	}

	var has_leto = false;
	for (arr.items) |user| {
		if (std.mem.eql(u8, "Leto", user.name)) {
			has_leto = true;
			break;
		}
	}

	std.debug.print("{any}\n", .{has_leto});
}

const User = struct {
	name: []const u8,
	power: i32,

	fn deinit(self: User, allocator: Allocator) void {
		allocator.free(self.name);
	}
};
```

上面是我们的哈希映射代码的复制，但使用了 `ArrayList(User)` 。所有相同的生命周期和内存管理规则都适用。请注意，我们仍在创建名称的 `dupe` ，并且在 `deinit` `ArrayList` 之前我们仍在释放每个名称。

现在是指出 Zig 没有属性或私有字段的好时机。当我们访问 `arr.items` 来迭代这些值时，您可以看到这一点。不拥有属性的原因是为了消除意外的来源。在 Zig 中，如果它看起来像现场访问，那么它就是现场访问。就我个人而言，我认为缺乏私有字段是一个错误，但这肯定是我们可以解决的问题。我已经在字段前加上下划线来表示“仅供内部使用”。

由于字符串“type”是 `[]u8` 或 `[]const u8` ，因此 `ArrayList(u8)` 是字符串生成器的适当类型，例如 .NET 的 `StringBuilder` 或 Go 的 `strings.Builder` 。事实上，当函数接受 `Writer` 并且您想要一个字符串时，您经常会使用它。我们之前看到过一个使用 `std.json.stringify` 将 JSON 输出到 stdout 的示例。以下是如何使用 `ArrayList(u8)` 将其放入变量中：

```zig
const std = @import("std");

pub fn main() !void {
	var gpa = std.heap.GeneralPurposeAllocator(.{}){};
	const allocator = gpa.allocator();

	var out = std.ArrayList(u8).init(allocator);
	defer out.deinit();

	try std.json.stringify(.{
		.this_is = "an anonymous struct",
		.above = true,
		.last_param = "are options",
	}, .{.whitespace = .indent_2}, out.writer());

	std.debug.print("{s}\n", .{out.items});
}
```

## anytype

在第 1 部分中，我们简要讨论了 `anytype` 。这是编译时鸭子类型的一种非常有用的形式。这是一个简单的记录器：

```zig
pub const Logger = struct {
	level: Level,

	// "error" is reserved, names inside an @"..." are always
	// treated as identifiers
	const Level = enum {
		debug,
		info,
		@"error",
		fatal,
	};

	fn info(logger: Logger, msg: []const u8, out: anytype) !void {
		if (@intFromEnum(logger.level) <= @intFromEnum(Level.info)) {
			try out.writeAll(msg);
		}
	}
};
```

`info` 函数的 `out` 参数的类型为 `anytype` 。这意味着我们的 `Logger` 可以将消息记录到具有接受 `[]const u8` 并返回 `!void` 的 `writeAll` 方法的任何结构。这不是运行时功能。类型检查发生在编译时，并且对于使用的每种类型，都会创建一个类型正确的函数。如果我们尝试使用不具有所有必要功能的类型（在本例中只有 `writeAll` ）调用 `info` ，我们将收到编译时错误：

```zig
var l = Logger{.level = .info};
try l.info("sever started", true);
```

给我们：“bool”中没有名为“writeAll”的字段或成员函数。使用 `ArrayList(u8)` 的 `writer` 可以：

```zig
pub fn main() !void {
	var gpa = std.heap.GeneralPurposeAllocator(.{}){};
	const allocator = gpa.allocator();

	var l = Logger{.level = .info};

	var arr = std.ArrayList(u8).init(allocator);
	defer arr.deinit();

	try l.info("sever started", arr.writer());
	std.debug.print("{s}\n", .{arr.items});
}
```

`anytype` 的一大缺点是文档。这是我们使用过几次的 `std.json.stringify` 函数的签名：

```zig
// I **hate** multi-line function definitions
// But I'll make an exception for a guide which
// you might be reading on a small screen.

fn stringify(
	value: anytype,
	options: StringifyOptions,
	out_stream: anytype
) @TypeOf(out_stream).Error!void
```

第一个参数 `value: anytype` 很明显。它是要序列化的值，它可以是任何东西（实际上，有些东西 Zig 的 JSON 序列化器无法序列化）。我们可以猜测 `out_stream` 是编写 JSON 的位置，但是对于它需要实现哪些方法，您的猜测和我的一样好。解决这个问题的唯一方法是阅读源代码，或者传递一个虚拟值并使用编译器错误作为我们的文档。通过更好的自动文档生成器可能会改善这一点。但是，我并不是第一次希望 Zig 有接口。

## @TypeOf
在前面的部分中，我们使用 `@TypeOf` 来帮助我们检查各种变量的类型。从我们的用法来看，您可能会认为它以字符串形式返回类型的名称。但是，鉴于它是一个 PascalCase 函数，您应该更了解：它返回一个 `type` 。

我最喜欢的 `anytype` 用法之一是将其与 `@TypeOf` 和 `@hasField` 内置函数配对来编写测试助手。尽管我们见过的每种 `User` 类型都非常简单，但我会要求您想象一个包含许多字段的更复杂的结构。在我们的许多测试中，我们需要 `User` ，但我们只想指定与测试相关的字段。让我们创建一个 `userFactory` ：

```zig
fn userFactory(data: anytype) User {
	const T = @TypeOf(data);
	return .{
		.id = if (@hasField(T, "id")) data.id else 0,
		.power = if (@hasField(T, "power")) data.power else 0,
		.active  = if (@hasField(T, "active")) data.name else true,
		.name  = if (@hasField(T, "name")) data.name else "",
	};
}

pub const User = struct {
	id: u64,
	power: u64,
	active: bool,
	name: [] const u8,
};
```

可以通过调用 `userFactory(.{})` 创建默认用户，或者我们可以使用 `userFactory(.{.id = 100, .active = false})` 覆盖特定字段。这是一个很小的图案，但我真的很喜欢它。这也是进入元编程世界的美好一步。

更常见的是 `@TypeOf` 与 `@typeInfo` 配对，后者返回 `std.builtin.Type` 。这是一个功能强大的标记联合，可以完整地描述类型。 `std.json.stringify` 函数在提供的 `value` 上递归地使用它来确定如何序列化它。

## Zig的编译build

如果您已经阅读了整个指南，等待深入了解设置具有多个依赖项和各种目标的更复杂的项目，那么您将会感到失望。 Zig 拥有强大的构建系统，以至于越来越多的非 Zig 项目正在使用它，例如 libsodium。不幸的是，所有这些功能意味着，对于更简单的需求，它并不是最容易使用或理解的。

事实是，我对 Zig 的构建系统的理解还不够深入，无法解释它。

尽管如此，我们至少可以得到一个简短的概述。为了运行 Zig 代码，我们使用了 `zig run learning.zig` 。有一次，我们也使用 `zig test learning.zig` 来运行测试。 `run` 和 `test` 命令非常适合使用，但如果要处理更复杂的情况，则需要使用 `build` 命令。 `build` 命令依赖于具有特殊 `build` 入口点的 `build.zig` 文件。这是一个骨架：

```zig
// build.zig

const std = @import("std");

pub fn build(b: *std.Build) !void {
	_ = b;
}
```

每个构建都有一个默认的“安装”步骤，您现在可以使用 `zig build install` 运行该步骤，但由于我们的文件大部分是空的，因此您不会获得任何有意义的工件。我们需要告诉我们的构建我们的程序的入口点，它位于 `learning.zig` 中：

```zig
const std = @import("std");

pub fn build(b: *std.Build) !void {
	const target = b.standardTargetOptions(.{});
	const optimize = b.standardOptimizeOption(.{});

	// setup executable
	const exe = b.addExecutable(.{
		.name = "learning",
		.target = target,
		.optimize = optimize,
		.root_source_file = .{ .path = "learning.zig" },
	});
	b.installArtifact(exe);
}
```

现在，如果您运行 `zig build install` ，您将在 `./zig-out/bin/learning` 处获得二进制文件。使用标准目标和优化允许我们覆盖默认的命令行参数。例如，要为 Windows 构建程序的大小优化版本，我们会这样做：

```zig
zig build install -Doptimize=ReleaseSmall -Dtarget=x86_64-windows-gnu
```

除了默认的“安装”之外，可执行文件通常还有两个附加步骤：“运行”和“测试”。库可能只有一个“测试”步骤。对于基本的无参数 `run` ，我们需要在构建的末尾添加四行：

```zig
// add after: b.installArtifact(exe);

const run_cmd = b.addRunArtifact(exe);
run_cmd.step.dependOn(b.getInstallStep());

const run_step = b.step("run", "Start learning!");
run_step.dependOn(&run_cmd.step);
```

这通过两次调用 `dependOn` 创建了两个依赖项。第一个将我们的新运行命令与内置安装步骤联系起来。第二个将“运行”步骤与我们新创建的“运行”命令联系起来。您可能想知道为什么需要运行命令和运行步骤。我相信这种分离的存在是为了支持更复杂的设置：依赖于多个命令的步骤，或跨多个步骤使用的命令。如果您运行 `zig build --help` 并滚动到顶部，您将看到我们新的“运行”步骤。您现在可以通过执行 `zig build run` 来运行该程序。

要添加“测试”步骤，您将复制我们刚刚添加的大部分运行代码，但不是 `b.addExecutable` ，而是使用 `b.addTest` 开始：

```zig
const tests = b.addTest(.{
	.target = target,
	.optimize = optimize,
	.root_source_file = .{ .path = "learning.zig" },
});

const test_cmd = b.addRunArtifact(tests);
test_cmd.step.dependOn(b.getInstallStep());
const test_step = b.step("test", "Run the tests");
test_step.dependOn(&test_cmd.step);
```

我们将这一步命名为“测试”。运行 `zig build --help` 现在应该显示另一个可用步骤“test”。由于我们没有任何测试，因此很难判断这是否有效。在 `learning.zig` 中，添加：

```zig
test "dummy build test" {
	try std.testing.expectEqual(false, true);
}
```

现在，当您运行 `zig build test` 时，您应该会遇到测试失败。如果您修复测试并再次运行 `zig build test` ，您将不会得到任何输出。默认情况下，Zig 的测试运行程序仅在失败时输出。如果像我一样，无论通过还是失败，您总是想要一个摘要，请使用 `zig build test --summary all` 。

这是启动和运行所需的最低配置。但请放心，如果您需要构建它，Zig 可能可以处理它。最后，您可以而且可能应该在项目根目录中使用 `zig init-exe` 或 `zig init-lib` 让 Zig 为您创建一个记录良好的 build.zig 文件。

## 第三方依赖库

Zig 的内置包管理器相对较新，因此存在许多缺陷。虽然还有改进的空间，但它可以按原样使用。我们需要查看两个部分：创建包和使用包。我们将完整地讨论这一点。

首先，创建一个名为 `calc` 的新文件夹并创建三个文件。第一个是 `add.zig` ，内容如下：

```zig
// Oh, a hidden lesson, look at the type of b
// and the return type!!

pub fn add(a: anytype, b: @TypeOf(a)) @TypeOf(a) {
	return a + b;
}

const testing = @import("std").testing;
test "add" {
	try testing.expectEqual(@as(i32, 32), add(30, 2));
}
```

这有点傻，一个完整的包只是添加两个值，但它会让我们专注于包装方面。接下来我们将添加一个同样愚蠢的： `calc.zig` ：

```zig
pub const add = @import("add.zig").add;

test {
	// By default, only tests in the specified file
	// are included. This magic line of code will
	// cause a reference to all nested containers
	// to be tested.
	@import("std").testing.refAllDecls(@This());
}
```

我们将其分为 `calc.zig` 和 `add.zig` 来证明 `zig build` 将自动构建和打包我们的所有项目文件。最后，我们可以添加一个 `build.zig` ：

```zig
const std = @import("std");

pub fn build(b: *std.Build) !void {
	const target = b.standardTargetOptions(.{});
	const optimize = b.standardOptimizeOption(.{});

	const tests = b.addTest(.{
		.target = target,
		.optimize = optimize,
		.root_source_file = .{ .path = "calc.zig" },
	});

	const test_cmd = b.addRunArtifact(tests);
	test_cmd.step.dependOn(b.getInstallStep());
	const test_step = b.step("test", "Run the tests");
	test_step.dependOn(&test_cmd.step);
}
```

这都是我们在上一节中看到的内容的重复。这样，您就可以运行 `zig build test --summary all` 。

回到我们的 `learning` 项目和之前创建的 `build.zig` 。我们首先添加本地 `calc` 作为依赖项。我们需要做三点补充。首先，我们将创建一个指向 `calc.zig` 的模块：

```zig
// You can put this near the top of the build
// function, before the call to addExecutable.

const calc_module = b.addModule("calc", .{
	.source_file = .{ .path = "PATH_TO_CALC_PROJECT/calc.zig" },
});
```

您需要将路径调整为 `calc.zig` 。我们现在需要将此模块添加到现有的 `exe` 和 `tests` 变量中：

```zig
const exe = b.addExecutable(.{
	.name = "learning",
	.target = target,
	.optimize = optimize,
	.root_source_file = .{ .path = "learning.zig" },
});
// add this
exe.addModule("calc", calc_module);
b.installArtifact(exe);

....

const tests = b.addTest(.{
	.target = target,
	.optimize = optimize,
	.root_source_file = .{ .path = "learning.zig" },
});
// add this
tests.addModule("calc", calc_module);
```

在您的项目中，您现在可以 `@import("calc")` ：

```zig
const calc = @import("calc");
...
calc.add(1, 2);
```

添加远程依赖需要花费更多的精力。首先，我们需要回到 `calc` 项目并定义一个模块。你可能会认为项目本身就是一个模块，但是一个项目可以暴露多个模块，所以我们需要显式地创建它。我们使用相同的 `addModule` ，但丢弃返回值。只需调用 `addModule` 就足以定义其他项目可以导入的模块。

```zig
_ = b.addModule("calc", .{
	.source_file = .{ .path = "calc.zig" },
});
```

这是我们需要对库进行的唯一更改。因为这是一个远程依赖练习，所以我已将这个 `calc` 项目推送到 Github，以便我们可以将其导入到我们的学习项目中。它可以在 https://github.com/karlseguin/calc.zig 上找到。

回到我们的学习项目，我们需要一个新文件 `build.zig.zon` 。 “ZON”代表 Zig 对象表示法，它允许 Zig 数据以人类可读的格式表示，并将该人类可读的格式转换为 Zig 代码。 `build.zig.zon` 的内容将是：

```zig
.{
  .name = "learning",
  .version = "0.0.0",
  .dependencies = .{
    .calc = .{
      .url = "https://github.com/karlseguin/calc.zig/archive/e43c576da88474f6fc6d971876ea27effe5f7572.tar.gz",
      .hash = "12ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"
    },
  },
}
```

该文件中有两个有问题的值，第一个是 `url` 中的 `e43c576da88474f6fc6d971876ea27effe5f7572` 。这就是 git 提交哈希。第二个是 `hash` 的值。据我所知，目前还没有很好的方法来告诉这个值应该是多少，所以我们暂时使用一个虚拟值。

要使用此依赖项，我们需要对 `build.zig` 进行一项更改：

```zig
// replace this:
const calc_module = b.addModule("calc", .{
	.source_file = .{ .path = "calc/calc.zig" },
});

// with this:
const calc_dep = b.dependency("calc", .{.target = target,.optimize = optimize});
const calc_module = calc_dep.module("calc");
```

在 `build.zig.zon` 中，我们将依赖项命名为 `calc` ，这就是我们在此处加载的依赖项。从这个依赖项中，我们获取 `calc` 模块，这就是我们在 `calc's` `build.zig` 中命名的模块。

如果您尝试运行 `zig build test` ，您应该会看到错误：

```text
error: hash mismatch:
expected:
12ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff,

found:
122053da05e0c9348d91218ef015c8307749ef39f8e90c208a186e5f444e818672d4
```

将正确的哈希值复制并粘贴回 `build.zig.zon` 中，然后再次尝试运行 `zig build test` 。现在一切都应该正常了。

听起来很多，我希望事情能简化。但它主要是您可以从其他项目复制和粘贴的内容，一旦设置完毕，您就可以继续。

警告一句，我发现 Zig 的依赖缓存过于激进。如果您尝试更新依赖项，但 Zig 似乎没有检测到更改...好吧，我会删除项目的 `zig-cache` 文件夹以及 `~/.cache/zig` 。

我们已经涵盖了很多基础知识，探索了一些核心数据结构，并将之前部分的大部分内容整合在一起。我们的代码变得更加复杂了，更少关注特定的语法，看起来更像真实的代码。我很兴奋的是，尽管代码很复杂，但大部分都是有意义的。如果没有，请不要放弃。选择一个示例并打破它，添加打印语句，为其编写一些测试。亲自动手编写代码，编写自己的代码，然后回来阅读那些没有意义的部分。

# 结论conclusion

有些读者可能会认出我是各种“The Little $TECH Book”的作者，并想知道为什么这本书不被称为“The Little Zig Book”。事实上，我不确定 Zig 是否适合“The Little”格式。部分挑战在于，Zig 的复杂性和学习曲线将根据您自己的背景和经验而有很大差异。如果您是一位经验丰富的 C 或 C++ 程序员，那么该语言的简洁摘要可能就很好，但是您可能会依赖 Zig 语言参考。

虽然我们在本指南中介绍了很多内容，但仍有大量内容我们尚未触及。我不想让你气馁或不知所措。所有语言都是多层次的，您现在有了基础和参考，可以开始掌握。坦率地说，我没有涵盖的部分我根本就不太理解，无法解释。这并没有阻止我在 Zig 中使用和构建有意义的东西，比如流行的 http 服务器库。

我确实想强调一件被完全忽略的事情。您可能已经知道这一点，但 Zig 特别适用于 C 代码。由于生态系统还很年轻，而且标准库很小，因此您可能会遇到使用 C 库是最佳选择的情况。例如，Zig 的标准库中没有正则表达式模块，一种合理的选择是使用 C 库。我已经为 SQLite 和 DuckDB 编写了 Zig 库，而且非常简单。如果您基本上遵循了本指南中的所有内容，那么您应该不会遇到任何问题。

我希望这个资源对您有所帮助，并且希望您编程愉快。
