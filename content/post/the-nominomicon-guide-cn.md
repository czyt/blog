---
title: "Nom指南中文版"
date: 2024-04-29
tags: ["rust", "parser"]
draft: false
---

> 原文https://tfpk.github.io/nominomicon/introduction.html，使用Google进行机翻

# nominomicon

欢迎阅读这本关于Nom的书；使用 Nom 解析器发挥巨大作用的指南。本指南将向您介绍使用 Nom 的理论和实践。

本指南仅假设您：

- 想学习Nom，
- 已经熟悉 Rust。

Nom 是一个解析器组合器库。换句话说，它为您提供了定义以下内容的工具：

- “解析器”（接受输入并返回输出的函数），以及
- “组合器”（采用解析器并将它们组合在一起的函数！）。

通过将解析器与组合器相结合，您可以从简单的解析器构建复杂的解析器。这些复杂的解析器足以理解 HTML、mkv 或 Python！

在我们出发之前，列出一些注意事项很重要：

- 本指南适用于 Nom7。 Nom 发生了重大变化，因此如果您正在搜索文档或 StackOverflow 答案，您可能会找到较旧的文档。一些常见的表明它是旧版本的指标是：
  - 2021 年 8 月 21 日之前的文档
  - `named!` 宏的使用
  - 使用 `CompleteStr` 或 `CompleteByteArray` 。
- Nom 可以解析（几乎）任何东西；但本指南几乎完全专注于将完整的 `&str` 解析为事物。

# [第一章：Nom 方式](https://tfpk.github.io/nominomicon/chapter_1.html#chapter-1-the-nom-way)

首先，我们需要了解 nom 思考解析的方式。正如简介中所讨论的，nom 让我们构建简单的解析器，然后组合它们（使用“组合器”）。

让我们讨论一下“解析器”实际上是做什么的。解析器接受输入并返回结果，其中：

- `Ok` 表示解析器成功找到了它要查找的内容；或者
- `Err` 表示解析器找不到它要查找的内容。

如果解析器成功，它将返回一个元组。元组的第一个字段将包含解析器未处理的所有内容。第二个将包含解析器处理的所有内容。这个想法是解析器可以愉快地解析输入的第一部分，而无法解析整个内容。

如果解析器失败，则可能会返回多个错误。然而，为了简单起见，在接下来的章节中，我们将不对这些进行探讨。

```text
                                   ┌─► Ok(
                                   │      what the parser didn't touch,
                                   │      what matched the regex
                                   │   )
             ┌─────────┐           │
 my input───►│my parser├──►either──┤
             └─────────┘           └─► Err(...)
```

为了表示这个世界模型，nom 使用 `IResult<I, O>` 类型。 `Ok` 变体采用两种类型 - `I` ，输入的类型；和 `O` ，输出的类型，而 `Err` 变体存储错误。

您可以从以下位置导入：

```rust
use nom::IResult;
```

您会注意到 `I` 和 `O` 是参数化的——而本书中的大多数示例将使用 `&str` （即解析字符串）；它们不必是字符串；它们也不必是相同的类型（考虑一个简单的例子，其中 `I = &str` 和 `O = u64` ——这将字符串解析为无符号整数）。

让我们编写我们的第一个解析器！我们可以编写的最简单的解析器是一个不执行任何操作的解析器。

该解析器应该接受 `&str` ：

- 由于它应该成功，我们知道它将返回 Ok Variant。
- 由于它对我们的输入没有任何作用，因此剩余的输入与输入相同。
- 由于它不解析任何内容，因此它也应该只返回一个空字符串。

```rust
pub fn do_nothing_parser(input: &str) -> IResult<&str, &str> {
    Ok((input, ""))
}

fn main() -> Result<(), Box<dyn Error>> {
    let (remaining_input, output) = do_nothing_parser("my_input")?;
    assert_eq!(remaining_input, "my_input");
    assert_eq!(output, "");
}
```

 就是这么简单！

# 第 2 章：标签和字符类

您可以编写的最简单有用的解析器是没有特殊字符的解析器，它仅匹配字符串。

在 `nom` 中，我们将简单的字节集合称为标签。因为这些很常见，所以已经存在一个名为 `tag()` 的函数。该函数返回给定字符串的解析器。

警告： `nom` 有多种不同的 `tag` 定义，请确保您暂时使用这个！

```rust
pub use nom::bytes::complete::tag;
```

例如，解析字符串 `"abc"` 的代码可以表示为 `tag("abc")` 。

如果您没有使用函数为值的语言进行编程，那么它们标记函数的类型签名可能会令人惊讶：

```rust
pub fn tag<T, Input, Error: ParseError<Input>>(
    tag: T
) -> impl Fn(Input) -> IResult<Input, Input, Error> where
    Input: InputTake + Compare<T>,
    T: InputLength + Clone, 
```

或者，对于 `Input` 和 `T` 都是 `&str` 的情况，并稍微简化：

```rust
fn tag(tag: &str) -> (impl Fn(&str) -> IResult<&str, Error>)
```

换句话说，这个函数 `tag` 返回一个函数。它返回的函数是一个解析器，接受 `&str` 并返回 `IResult` 。创建解析器并返回它们的函数是 Nom 中的常见模式，因此调用它很有用。

下面，我们实现了一个使用 `tag` 的函数。

```rust
fn parse_input(input: &str) -> IResult<&str, &str> {
    //  note that this is really creating a function, the parser for abc
    //  vvvvv 
    //         which is then called here, returning an IResult<&str, &str>
    //         vvvvv
    tag("abc")(input)
}

fn main() -> Result<(), Box<dyn Error>> {
    let (leftover_input, output) = parse_input("abcWorld")?;
    assert_eq!(leftover_input, "World");
    assert_eq!(output, "abc");

    assert!(parse_input("defWorld").is_err());
}
```

如果您愿意，还可以使用 `tag_no_case` 函数检查不区分大小写的标签。

## 字符类

标签非常有用，但它们也具有非常严格的限制。 Nom 功能的另一端是预先编写的解析器，它允许我们接受一组字符中的任何一个，而不仅仅是接受定义序列中的字符。

以下是其中的一些选择：

- `alpha0` ：识别零个或多个小写和大写字母字符： `/[a-zA-Z]/` 。 `alpha1` 执行相同操作，但返回至少一个字符
- `alphanumeric0` ：识别零个或多个数字和字母字符： `/[0-9a-zA-Z]/` 。 `alphanumeric1` 执行相同操作，但返回至少一个字符
- `digit0` ：识别零个或多个数字字符： `/[0-9]/` 。 `digit1` 执行相同操作，但返回至少一个字符
- `multispace0` ：识别零个或多个空格、制表符、回车符和换行符。 `multispace1` 执行相同操作，但返回至少一个字符
- `space0` ：识别零个或多个空格和制表符。 `space1` 执行相同操作，但返回至少一个字符
- `line_ending` ：识别行尾（ `\n` 和 `\r\n` ）
- `newline` ：匹配换行符 `\n`
- `tab` ：匹配制表符 `\t`

我们可以使用这些

```rust
pub use nom::character::complete::alpha0;
fn parser(input: &str) -> IResult<&str, &str> {
    alpha0(input)
}

fn main() -> Result<(), Box<dyn Error>> {
    let (remaining, letters) = parser("abc123")?;
    assert_eq!(remaining, "123");
    assert_eq!(letters, "abc");
    
}
```

一个重要的注意事项是，由于这些函数的类型签名，通常最好在返回 `IResult` 的函数中使用它们。

如果不这样做，则必须手动指定有关 `tag` 函数类型的一些信息，这可能会导致冗长的代码或令人困惑的错误。



# 第 3 章：替代方案和组合

在上一章中，我们了解了如何使用 `tag` 函数创建简单的解析器；以及 Nom 的一些预构建解析器。

在本章中，我们将探讨 Nom 的另外两个广泛使用的功能：替代项和组合。

## 备择方案

有时，我们可能想在两个解析器之间进行选择；我们对其中任何一个的使用都很满意。

Nom 通过 `alt()` 组合器为我们提供了类似的能力。

```rust
use nom::branch::alt;
```

`alt()` 组合器将执行元组中的每个解析器，直到找到一个不出错的解析器。如果全部错误，则默认情况下会给出最后一个错误的错误。

我们可以在下面看到 `alt()` 的基本示例。

```rust
use nom::branch::alt;
use nom::bytes::complete::tag;
use nom::IResult;

fn parse_abc_or_def(input: &str) -> IResult<&str, &str> {
    alt((
        tag("abc"),
        tag("def")
    ))(input)
}

fn main() -> Result<(), Box<dyn Error>> {
    let (leftover_input, output) = parse_abc_or_def("abcWorld")?;
    assert_eq!(leftover_input, "World");
    assert_eq!(output, "abc");

    assert!(parse_abc_or_def("ghiWorld").is_err());
}
```

## 组合

现在我们可以创建更多有趣的正则表达式，我们可以将它们组合在一起。最简单的方法就是按顺序评估它们：

```rust
use nom::branch::alt;
use nom::bytes::complete::tag;
use nom::IResult;

fn parse_abc(input: &str) -> IResult<&str, &str> {
    tag("abc")(input)
}
fn parse_def_or_ghi(input: &str) -> IResult<&str, &str> {
    alt((
        tag("def"),
        tag("ghi")
    ))(input)
}

fn main() -> Result<(), Box<dyn Error>> {
    let input = "abcghi";
    let (remainder, abc) = parse_abc(input)?;
    let (remainder, def_or_ghi) = parse_def_or_ghi(remainder)?;
    println!("first parsed: {abc}; then parsed: {def_or_ghi};");
    
}
```

组合标签是一项非常常见的要求，事实上，Nom 有一些内置的组合器可以做到这一点。其中最简单的是 `tuple()` 。 `tuple()` 组合器采用解析器的元组，并且返回 `Ok` 以及所有成功解析的元组，或者返回第一个失败的 `Err` 解析器。

```rust
use nom::sequence::tuple;
use nom::branch::alt;
use nom::sequence::tuple;
use nom::bytes::complete::tag_no_case;
use nom::character::complete::{digit1};
use nom::IResult;

fn parse_base(input: &str) -> IResult<&str, &str> {
    alt((
        tag_no_case("a"),
        tag_no_case("t"),
        tag_no_case("c"),
        tag_no_case("g")
    ))(input)
}

fn parse_pair(input: &str) -> IResult<&str, (&str, &str)> {
    // the many_m_n combinator might also be appropriate here.
    tuple((
        parse_base,
        parse_base,
    ))(input)
}

fn main() -> Result<(), Box<dyn Error>> {
    let (remaining, parsed) = parse_pair("aTcG")?;
    assert_eq!(parsed, ("a", "T"));
    assert_eq!(remaining, "cG");
 
    assert!(parse_pair("Dct").is_err());

}
```

## 额外的nom工具

使用 `alt()` 和 `tuple()` 之后，您可能还会对其他一些执行类似操作的解析器感兴趣：

| combinator                                                   | usage                                                   | input            | output                          | comment |
| ------------------------------------------------------------ | ------------------------------------------------------- | ---------------- | ------------------------------- | ------- |
| [delimited](https://docs.rs/nom/latest/nom/sequence/fn.delimited.html) | `delimited(char('('), take(2), char(')'))`              | `"(ab)cd"`       | `Ok(("cd", "ab"))`              |         |
| [preceded](https://docs.rs/nom/latest/nom/sequence/fn.preceded.html) | `preceded(tag("ab"), tag("XY"))`                        | `"abXYZ"`        | `Ok(("Z", "XY"))`               |         |
| [terminated](https://docs.rs/nom/latest/nom/sequence/fn.terminated.html) | `terminated(tag("ab"), tag("XY"))`                      | `"abXYZ"`        | `Ok(("Z", "ab"))`               |         |
| [pair](https://docs.rs/nom/latest/nom/sequence/fn.pair.html) | `pair(tag("ab"), tag("XY"))`                            | `"abXYZ"`        | `Ok(("Z", ("ab", "XY")))`       |         |
| [separated_pair](https://docs.rs/nom/latest/nom/sequence/fn.separated_pair.html) | `separated_pair(tag("hello"), char(','), tag("world"))` | `"hello,world!"` | `Ok(("!", ("hello", "world")))` |         |

# 第 4 章：具有自定义返回类型的解析器

到目前为止，我们已经看到大多数函数接受 `&str` 并返回 `IResult<&str, &str>` 。将字符串分割成更小的字符串当然很有用，但这并不是 Nom 唯一能做的事情！

解析时一个有用的操作是类型之间的转换；例如从 `&str` 解析为另一个原语，例如 `bool` 。

为了让解析器返回不同的类型，我们需要做的就是将 `IResult` 的第二个类型参数更改为所需的返回类型。例如，要返回 bool，请返回 `IResult<&str, bool>` 。

回想一下， `IResult` 的第一个类型参数是输入类型，因此即使您返回不同的内容，如果您的输入是 `&str` ， `IResult` 应该也是。

在您阅读有关错误的章节之前，我们强烈建议避免使用 Rust 内置的解析器（如 `str.parse` ）；因为它们需要特殊处理才能与 Nom 良好配合。

也就是说，进行类型转换的一种 Nom 本机方法是使用 `value` 组合器将成功的解析转换为特定值。

以下代码将包含 `"true"` 或 `"false"` 的字符串转换为相应的 `bool` 。

```rust
use nom::IResult;
use nom::bytes::complete::tag;
use nom::combinator::value;
use nom::branch::alt;

fn parse_bool(input: &str) -> IResult<&str, bool> {
    // either, parse `"true"` -> `true`; `"false"` -> `false`, or error.
    alt((
      value(true, tag("true")),
      value(false, tag("false")),
    ))(input)
}

fn main() -> Result<(), Box<dyn Error>> {
    // Parses the `"true"` out.
    let (remaining, parsed) = parse_bool("true|false")?;
    assert_eq!(parsed, true);
    assert_eq!(remaining, "|false");
   
    // If we forget about the "|", we get an error.
    let parsing_error = parse_bool(remaining);
    assert!(parsing_error.is_err());
    
    // Skipping the first byte gives us `false`!
    let (remaining, parsed) = parse_bool(&remaining[1..])?;
    assert_eq!(parsed, false);
    assert_eq!(remaining, "");
    
    

}
```

## Nom 的内置解析器函数

Nom 内置了大量解析器。以下是识别特定字符的解析器列表。

其中一些我们之前在第 2 章中已经见过，但现在我们也可以尝试返回不同类型的解析器，例如 `i32` 。下一节将显示此解析器的示例。

## 构建一个更复杂的示例

解析自定义类型的一个更复杂的示例可能是解析 2D 坐标。

让我们尝试弄清楚如何设计它。

- 我们知道我们想要获取一个字符串，例如 `"(3, -2)"` ，并将其转换为 `Coordinate` 结构。
- 我们可以将其分为三个部分：

```ignore
(vvvvvvvvvvvvv) # The outer brackets.
  vvvv , vvvv   # The comma, separating values.
    3     -2    # The actual integers.
```

- 因此，我们需要三个解析器来处理这个问题：
  1. 整数解析器，它将处理原始数字。
  2. 逗号分隔对的解析器，它将把它分成整数。
  3. 外括号的解析器。
- 我们可以在下面看到我们如何实现这一目标：

```rust
use nom::IResult;
use nom::bytes::complete::tag;
use nom::sequence::{separated_pair, delimited};

// This is the type we will parse into.
#[derive(Debug,PartialEq)]
pub struct Coordinate {
  pub x:   i32,
  pub y:   i32,
}

// 1. Nom has an in-built i32 parser.
use nom::character::complete::i32;

// 2. Use the `separated_pair` parser to combine two parsers (in this case,
//    both `i32`), ignoring something in-between.
fn parse_integer_pair(input: &str) -> IResult<&str, (i32, i32)> {
    separated_pair(
        i32,
        tag(", "),
        i32
    )(input)
}

// 3. Use the `delimited` parser to apply a parser, ignoring the results
//    of two surrounding parsers.
fn parse_coordinate(input: &str) -> IResult<&str, Coordinate> {
    let (remaining, (x, y)) = delimited(
        tag("("),
        parse_integer_pair,
        tag(")")
    )(input)?;
    
    // Note: we could construct this by implementing `From` on `Coordinate`,
    // We don't, just so it's obvious what's happening.
    Ok((remaining, Coordinate {x, y}))
    
}

fn main() -> Result<(), Box<dyn Error>> {
    let (_, parsed) = parse_coordinate("(3, 5)")?;
    assert_eq!(parsed, Coordinate {x: 3, y: 5});
   
    let (_, parsed) = parse_coordinate("(2, -4)")?;
    assert_eq!(parsed, Coordinate {x: 2, y: -4});
    
    let parsing_error = parse_coordinate("(3,)");
    assert!(parsing_error.is_err());
    
    let parsing_error = parse_coordinate("(,3)");
    assert!(parsing_error.is_err());
    
    let parsing_error = parse_coordinate("Ferris");
    assert!(parsing_error.is_err());
    

}
```

作为练习，您可能想探索如何使该解析器优雅地处理输入中的空格。

# 第 5 章：用谓词重复

就像编程时，简单的 while 循环可以解锁许多有用的功能；在 Nom 中，多次重复解析器可能非常有用

然而，有两种方法可以将重复功能包含到 Nom 中——由谓词控制的解析器；和重复解析器的组合器。

## 使用谓词的解析器

`predicate` 是一个返回布尔值的函数（即给定一些输入，它返回 `true` 或 `false` ）。这些在解析时非常常见——例如，谓词 `is_vowel` 可能决定一个字符是否是英语元音（a、e、i、o 或 u）。

这些可用于制作 Nom 未内置的解析器。例如，下面的解析器将采用尽可能多的元音。

有几种不同类别的谓词解析器值得一提：

- 对于字节，解析器分为三种不同类别： `take_till` 、 `take_until` 和 `take_while` 。 `take_till` 将继续消耗输入，直到其输入满足谓词。 `take_while` 将继续消耗输入，直到其输入不满足谓词。 `take_until` 看起来很像谓词解析器，但只是消耗直到字节模式第一次出现。
- 一些解析器有一个“双胞胎”，其名称末尾带有 `1` ——例如， `take_while` 有 `take_while1` 。它们之间的区别在于，如果第一个字节不满足谓词，则 `take_while` 可能返回空切片。如果不满足谓词， `take_while1` 将返回错误。
- 作为一种特殊情况， `take_while_m_n` 类似于 `take_while` ，但保证它将消耗至少 `m` 字节，并且不超过 `n` 字节。

```rust
use nom::IResult;
use nom::bytes::complete::{tag, take_until, take_while};
use nom::character::{is_space};
use nom::sequence::{terminated};

fn parse_sentence(input: &str) -> IResult<&str, &str> {
    terminated(take_until("."), take_while(|c| c == '.' || c == ' '))(input)
}

fn main() -> Result<(), Box<dyn Error>> {
    let (remaining, parsed) = parse_sentence("I am Tom. I write Rust.")?;
    assert_eq!(parsed, "I am Tom");
    assert_eq!(remaining, "I write Rust.");
   
    let parsing_error = parse_sentence("Not a sentence (no period at the end)");
    assert!(parsing_error.is_err());
    

}
```

有关详细示例，请参阅他们的文档，如下所示：

| combinator                                                   | usage                       | input           | output                    | comment                                                      |
| ------------------------------------------------------------ | --------------------------- | --------------- | ------------------------- | ------------------------------------------------------------ |
| [take_while](https://docs.rs/nom/latest/nom/bytes/complete/fn.take_while.html) | `take_while(is_alphabetic)` | `"abc123"`      | `Ok(("123", "abc"))`      | 返回所提供函数返回 true 的最长字节列表。 `take_while1` 的作用相同，但必须至少返回一个字符。 `take_while_m_n` 执行相同的操作，但必须在 `m` 和 `n` 字符之间返回。 |
| [take_till](https://docs.rs/nom/latest/nom/bytes/complete/fn.take_till.html) | `take_till(is_alphabetic)`  | `"123abc"`      | `Ok(("abc", "123"))`      | 返回最长的字节或字符列表，直到提供的函数返回 true。 `take_till1` 的作用相同，但必须至少返回一个字符。这是 `take_while` 的相反行为： `take_till(f)` 相当于 `take_while(\|c\| !f(c))` |
| [take_until](https://docs.rs/nom/latest/nom/bytes/complete/fn.take_until.html) | `take_until("world")`       | `"Hello world"` | `Ok(("world", "Hello "))` | 返回最长的字节或字符列表，直到找到提供的标签。 `take_until1` 作用相同，但必须返回至少一个字符 |

# 第 6 章：重复解析器

重复谓词的单个解析器很有用，但更有用的是重复解析器的组合器。 Nom 有多个按此原理运行的组合器；其中最明显的是 `many0` ，它尽可能多次地应用解析器；并返回这些解析结果的向量。这是一个例子：

```rust
use nom::IResult;
use nom::multi::many0;
use nom::bytes::complete::tag;

fn parser(s: &str) -> IResult<&str, Vec<&str>> {
  many0(tag("abc"))(s)
}

fn main() {
    assert_eq!(parser("abcabc"), Ok(("", vec!["abc", "abc"])));
    assert_eq!(parser("abc123"), Ok(("123", vec!["abc"])));
    assert_eq!(parser("123123"), Ok(("123123", vec![])));
    assert_eq!(parser(""), Ok(("", vec![])));
}
```

有许多不同的解析器可供选择：

| combinator                                                   | usage                                                        | input         | output                                | comment                                                      |
| ------------------------------------------------------------ | ------------------------------------------------------------ | ------------- | ------------------------------------- | ------------------------------------------------------------ |
| [count](https://docs.rs/nom/latest/nom/multi/fn.count.html)  | `count(take(2), 3)`                                          | `"abcdefgh"`  | `Ok(("gh", vec!["ab", "cd", "ef"]))`  | 应用子解析器指定的次数                                       |
| [many0](https://docs.rs/nom/latest/nom/multi/fn.many0.html)  | `many0(tag("ab"))`                                           | `"abababc"`   | `Ok(("c", vec!["ab", "ab", "ab"]))`   | 应用解析器 0 次或多次并以 Vec 形式返回结果列表。 `many1` 执行相同的操作，但必须返回至少一个元素 |
| [many_m_n](https://docs.rs/nom/latest/nom/multi/fn.many_m_n.html) | `many_m_n(1, 3, tag("ab"))`                                  | `"ababc"`     | `Ok(("c", vec!["ab", "ab"]))`         | 应用解析器 m 到 n 次（包括 n 次）并以 Vec 形式返回结果列表   |
| [many_till](https://docs.rs/nom/latest/nom/multi/fn.many_till.html) | `many_till(tag( "ab" ), tag( "ef" ))`                        | `"ababefg"`   | `Ok(("g", (vec!["ab", "ab"], "ef")))` | 应用第一个解析器直到第二个解析器应用。返回一个元组，其中包含 Vec 中第一个结果和第二个结果的列表 |
| [separated_list0](https://docs.rs/nom/latest/nom/multi/fn.separated_list0.html) | `separated_list0(tag(","), tag("ab"))`                       | `"ab,ab,ab."` | `Ok((".", vec!["ab", "ab", "ab"]))`   | `separated_list1` 与 `separated_list0` 类似，但必须至少返回一个元素 |
| [fold_many0](https://docs.rs/nom/latest/nom/multi/fn.fold_many0.html) | `fold_many0(be_u8, \|\| 0, \|acc, item\| acc + item)`        | `[1, 2, 3]`   | `Ok(([], 6))`                         | 应用解析器 0 次或多次并折叠返回值列表。 `fold_many1` 版本必须至少应用一次子解析器 |
| [fold_many_m_n](https://docs.rs/nom/latest/nom/multi/fn.fold_many_m_n.html) | `fold_many_m_n(1, 2, be_u8, \|\| 0, \|acc, item\| acc + item)` | `[1, 2, 3]`   | `Ok(([3], 3))`                        | 应用解析器 m 到 n 次（包括 n 次）并折叠返回值列表            |
| [length_count](https://docs.rs/nom/latest/nom/multi/fn.length_count.html) | `length_count(number, tag("ab"))`                            | `"2ababab"`   | `Ok(("ab", vec!["ab", "ab"]))`        | 从第一个解析器获取一个数字，然后多次应用第二个解析器         |

# 第 7 章：使用 Nom 之外的错误

[Nom 还有其他有关错误的文档，因此请阅读本页来代替本章。](https://github.com/Geal/nom/blob/main/doc/error_management.md)

## 特别说明

- 使用 `map_res` 函数特别有用。它允许您将外部错误转换为名义错误。有关示例，请参阅首页上的 Nom 示例。