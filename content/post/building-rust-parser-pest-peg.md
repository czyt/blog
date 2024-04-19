---
title: "使用 Pest 和 PEG 构建 Rust 解析器【译】"
date: 2024-04-19
tags: ["rust", "dsl", "rust-lib"]
draft: false
---

> 本文原为为 https://blog.logrocket.com/building-rust-parser-pest-peg/，使用Google翻译进行机翻，部分内容做了细微润色。

编写一个高效的词法分析器对来解析复杂的结构可能具有挑战性。如果格式或结构是固定的，并且您必须以易于理解、维护和扩展以适应未来更改的方式编写解析器，那么这会变得更加复杂。

在这些情况下，我们可以使用解析器生成器，而不是手写解析器或手动解析我们的项目。在本文中，我们将回顾什么是解析器生成器，并探索一个名为 Pest 的 Rust 解析工具。我们将涵盖：

[TOC]

请注意，您应该能够轻松地阅读和编写基本的 Rust 代码，例如函数、结构和循环。

## 什么是解析器生成器？

解析器生成器是一些程序，它接受解析器需要考虑的规则，然后以编程方式为您生成一个解析器，该解析器将根据这些规则解析输入。

大多数时候，规则以简化语言（例如正则表达式）提供给解析器生成器。因此，当您想要通过更改规则或添加新规则来更新解析器时，您只需更新或添加规则的正则表达式即可。然后，当您运行解析器生成器时，它将重写解析器以适应这些规则。

可以想象使用这样的解析工具可以节省多少时间。许多解析器生成器还会生成词法分析器，因此您不必自己编写词法分析器。如果生成的词法分析器不适合您，您可以选择使用您自己的词法分析器运行解析器（如果需要）。

目前，Rust 生态系统中有多个解析器生成器可供您使用。其中最受欢迎的三个是 LalrPop、Nom 和 Pest。

LalrPop 与 Yacc 非常相似，它让您定义规则和相应的操作。我个人用它来为我的 8086 模拟器项目编写规则。

Nom 是一个解析器组合器库，您可以在其中将规则编写为函数组合。这更面向解析二进制输入，但也可用于解析字符串。

最后，Pest 使用 Parsing Expression Grammar 来定义解析规则。我们将在这篇文章中详细探讨 Rust 与 Pest 的解析。

## Pest 中的解析表达式语法是什么？

解析表达式语法（PEG）是用 Pest 定义 Rust 解析“规则”的方法之一。 Pest 接受具有此类规则定义的文件的输入，并生成遵循它们的 Rust 解析器。

在编写规则时，您应该考虑 Pest 和 PEG 的三个定义特征。

第一个特点是贪婪匹配。 Pest 将始终尝试将输入的最大值与规则相匹配。例如，假设我们编写了如下规则：

```
match one or more alphabets
```

在这种情况下，Pest 将消耗输入中的所有内容，直到达到数字、空格或符号。在此之前它不会停止。

要考虑的第二个特征是交替匹配是有序的。为了理解这意味着什么，假设我们给出了多个匹配来满足一条规则，如下所示：

```
rule1 | rule2 | rule3
```

Pest 将首先尝试匹配 `rule1` 。当且仅当 `rule1` 失败时，Pest才会尝试匹配 `rule2` ，依此类推。如果第一条规则匹配，Pest 将不会尝试匹配任何其他规则来找到最佳匹配。

因此，在编写此类替代方案时，我们必须将最具体的替代方案放在前面，将最一般的替代方案放在最后。下一节将对此进行更详细的解释。

第三个特性——无回溯——意味着如果规则无法匹配，解析器将不会回溯。相反，Pest 会尝试寻找更好的规则或选择最佳的替代匹配。

这与使用普通正则表达式或其他类型的解析器不同，即使没有给出替代选择，它们也可以返回一些标记并尝试找到替代规则。

您可以在 Pest 文档中更详细地了解这些和其他特征。

## 在 Pest 中使用 PEG 声明 Rust 解析器的规则

在 Pest 中，我们使用类似于正则表达式的语法来定义规则，但也有一些差异。让我们通过写一些例子来看看实际的语法。

任何规则的基本语法如下：

```
RULE_NAME = { rule definition }
```

大括号前面可以有 `_` 和 `@` 等符号。稍后我们会看到这些符号的含义。

### 使用 Pest 中的内置规则匹配单个字符

Pest 有一些内置规则来匹配某些字符或字符集。

引号中的任何字符或字符串都与其自身匹配。例如， `"a"` 将匹配 `a` 字符， `"true"` 将匹配字符串 `true` ，依此类推。

`ANY` 是匹配任何 Unicode 字符的规则，包括空格、换行符以及逗号和分号等符号。

`ASCII_DIGIT` 将匹配数字或数字字符 - 换句话说，以下字符中的任何字符：

```
0123456789
```

`ASCII_ALPHA` 将匹配小写和大写字母字符 - 换句话说，以下字符中的任何字符：

```
abcdefghijklmnopqrstuvwxyz
ABCDEFGHIJKLMNOPQRSTUVWXYZ
```

您可以使用 `ASCII_ALPHA_LOWER` 和 `ASCII_ALPHA_UPPER` 来专门匹配各自大小写的大写和小写字符。

最后， `NEWLINE` 将匹配表示换行符的控制字符，例如 `\n` 、 `\n\r` 或 `\r` 。

Pest 文档中还解释了其他几个内置规则，但对于我们将要构建的小程序，上述规则应该足够了。

请注意，上述所有规则仅匹配其类型的单个字符，而不匹配多个字符。例如，对于输入 `abcde` ，请考虑如下规则：

```
my_rule = { ASCII_ALPHA }
```

此规则将仅匹配 `a` 字符，而输入的其余部分 - `bcde` - 将被传递以进行进一步解析。

### 使用重复匹配多个字符

现在我们知道如何匹配单个字符，让我们看看如何匹配多个字符。重复有三种重要类型，我们将在下面介绍。

加号 `+` 表示“一个或多个”。在这里，Rust 解析器将尝试匹配至少一次出现的规则。如果出现多次，Pest 将匹配所有这些。如果找不到任何匹配项，则会被视为错误。例如，我们可以这样定义一个数字：

```
NUMBER = { ASCII_DIGIT+ }
```

如果存在非数字字符（例如字母字符或符号），此规则将给出错误。

星号 `*` 表示“零个或多个”。当我们想要允许多次出现，但即使没有错误也不给出任何错误时，这很有用。例如，定义列表时，第一个值后面可以有零个或多个逗号值对。您现在可以忽略下面代码中的 tilda `~` ，因为我们将在下一节中看到它的含义：

```
LIST = { "[" ~ NUMBER ~ ("," ~ NUMBER)* "]" }
```

上面的规则规定列表以 `[` 开头，然后是 `NUMBER` ，之后可以有零对或多对 `, number` 组。它们被分组在括号中，并在整个括号组上加上星号 `*` 。最后，列表以右括号 `]` 结尾。

此规则将匹配 `[0]` 、 `[1,2]` 、 `[1,2,3]` 等。但是，它会在 `1` 上失败，因为没有左括号 `[` ，以及 `[1` ，因为没有右括号 `]` > 呈现。

最后，问号 `?` 匹配零个或一个，但不能超过一个。例如，要允许在上面的列表中使用尾随逗号，我们可以如下声明：

```
LIST = { "[" ~ NUMBER ~ ("," ~ NUMBER)* ","? "]" }
```

此更改将允许 `[1]` 和 `[1,]` 。

除了这三个选项之外，还有其他指定重复的方法，包括允许重复固定次数的方法，或最多 `n` 次，或在 `n` 和 `m`

### 与序列的隐式匹配

我们在上一节中看到的 tilda `~` 用于表示序列。例如， `A ~ B ~ C` 翻译为“匹配规则 A，然后匹配 B，然后匹配 C。”

使用显式 `~` 来表示此序列是有效的，因为 `~` 符号周围存在一些隐式的空白匹配。这是因为在许多情况下，编码规则和语法会忽略空格。例如， `if ( true)` 与 `if( true )` 和 `if (true )` 相同。

因此，Pest 生成的解析器将自动为我们执行此操作，而不是开发人员在每个地方手动检查这一点。这种隐式匹配的具体细节将在下面的后续部分中解释。

### 表达替代选择

有时您可能想要表达允许与定义的规则匹配的多个规则。例如，在 JSON 中，值可以是字符串、数组或对象，等等。

对于这种“OR”场景，我们可以使用竖线 `|` 符号来表达替代选择的想法。上面的 JSON 概念可以写成这样的规则：

```
VALUE = { STRING | ARRAY | OBJECT }
```

请注意，如上所述，在解释 PEG 特征时，这些选择是在首次匹配的基础上做出的。因此，考虑如下规则：

```
RULE = { "cat" | "cataract" | "catastrophe" }
```

此规则永远不会匹配 `cataract` 和 `catastrophe` ，因为解析器会将两者的起始 `cat-` 部分与第一条规则 `cat` 相匹配，并且那么它就不会尝试匹配任何其他字母。匹配 `cat` 后，解析器会将剩余的输入 - `-aract` 和 `-astrophe` - 传递到下一步，它可能不会匹配任何内容并导致解析失败。

为了确保竖线 `|` 达到预期效果，请记住始终在开头指定最具体的规则，在结尾指定最通用的规则。例如，上面的正确表达方式如下：

```
RULE = { "catastrophe" | "cataract" | "cat" }
```

这里， `cataract` 和 `catastrophe` 的顺序并不重要，因为它们不是彼此的子字符串，并且输入匹配一个将不会匹配另一个。让我们快速看一下可能发生这种情况的示例案例：

```
all_queues = { "queue" | "que" | "q" }
```

匹配 `queue` 及其变体 `que` 和 `q` 时使用的顺序在这里很重要，因为后面的字符串是第一个字符串的子字符串。解析器将首先尝试将输入与 `queue` 匹配；仅当失败时，解析器才会尝试将其与 `que` 匹配。如果也失败，解析器最终将尝试匹配 `q` 。

### 了解静音、原子和间距

现在让我们看看下划线 `_` 和 at `@` 符号的含义。

在 Pest 生成的解析器中，每个匹配的规则都会生成一个 `Pair` ，其中包含匹配的输入及其匹配的规则。然而，有时，我们可能想要匹配一些规则以确保遵循语法，但又想忽略这些规则的内容，因为它们并不重要。

在这些情况下，我们可以通过在该规则的左大括号 `{` 之前放置一个下划线 `_` 来将该规则表示为静默，而不是它生成我们然后在代码中忽略的标记。定义。

该策略最常见的用例是忽略注释。尽管我们希望注释遵循语法约定——例如，它们必须以 `//` 开头并以换行符结尾——但我们不希望它们在处理过程中出现。因此，为了忽略注释，我们可以这样定义它们：

```
comments = _{ "//" ~ (!NEWLINE ~ ANY)* ~ NEWLINE }
```

这将尝试匹配任何评论。如果存在任何语法错误（例如，如果注释仅以一个 `/` 开头），则会产生错误。但是，如果注释匹配成功，解析器将不会为此规则生成对。

理论上，评论可以出现在任何地方。因此，我们需要在每个规则的末尾放置一个 `comments?` ，这将是乏味的。

为了解决这个问题，Pest 提供了两个固定的规则名称 - `COMMENT` 或 `WHITESPACE` - 生成的解析器将自动允许这些表示的注释或空格存在于输入中的任何位置。如果我们定义任一规则，生成的解析器将隐式检查每个 tilda `~` 和所有重复项。

另一方面，我们并不总是想要这种行为。例如，当我们编写需要具有特定数量的空白的规则时，我们不能允许这些隐式规则消耗该空间。

作为解决方法，我们可以通过在左大括号 `{` 或美元 `$` 符号来定义原子规则（不执行隐式匹配） > 定义规则时。 `@` 使规则原子化且静默，而 `$` 将使规则原子化并像任何其他规则一样生成令牌。

### 内置输入规则的开始和结束

`SOI` 和 `EOI` 是两个特殊的内置规则，它们不匹配任何内容，而是表示输入的开始和结束。当您想要确保解析整个输入而不是其中的一部分，或者在规则开头允许空格和注释时，这些非常有用。

以上内容应该涵盖了编写 PEG 规则的重要基础知识，如果需要，可以在 Pest 文档中找到完整的详细信息。现在让我们使用我们所学到的知识构建一个示例解析器！

## 使用 Pest 演示一个简单的解析器

使用 Pest 构建解析器使您能够定义和解析任何语法，包括 Rust。在我们的示例项目中，我们将构建一个解析器，该解析器将解析 HTML 文档的简化版本，以提供与标签和属性相关的信息以及实际文本。

我们的示例使用 HTML，因为它的语法众所周知并易于理解，不需要大量解释，而且还提供了足够的复杂性，使我们可以显示解析时需要考虑的不同内容。学习这些基础知识后，您可以使用相同的知识来定义和解析您选择的任何语法。

首先，创建一个新项目并添加 `pest` 和 `pest_derive` 作为依赖项。

Pest 非常重视将规则和我们的应用程序代码分开。因此，我们必须在单独的文件中定义规则，并使用 Pest 箱给出的宏在我们的代码中构建和导入解析器。为此，我们将在 `src` 文件夹中创建一个名为 `html.pest` 的文件。

首先，我们首先将 `tag` 定义为规则。标签以小于 `<` 符号开头，紧跟零个或一个正斜杠 `/` ，然后是标签名称，以 `>` 或 `/>` 。因此，我们可以使用问号 `?` 来检测可选的 `/` 并定义规则，如下所示：

```
tag = ${ "<" ~ "/"? ~ ASCII_ALPHA+ ~ "/"? ~ ">" }
```

该规则是原子的，因为我们不希望小于号 `<` 和标签名称之间有空格。目前，这还允许像 `</abc/>` 这样的标签——这是无效的 HTML——但我们稍后会处理这个问题。由于标签名称不能为空，因此在匹配字母时我们使用加号 `+` 。

下面我们还定义了一个 `document` 规则，它包含多个标签并允许它们之间有空格：

```
document = { SOI ~ tag+ ~ EOI}
```

我们使用了加号 `+` 符号，因为文档应该至少有一个标签。

最后，我们定义一个 `WHITESPACE` 规则来允许标签之间有空格和换行符：

```
WHITESPACE = _{ " " | NEWLINE }
```

要实际构建并将其导入到我们的项目中，我们将添加以下命令：

```rust
use pest_derive::Parser;

#[derive(Parser)]
#[grammar = "html.pest"]
pub struct HtmlParser;
```

在上面的代码中，我们首先导入派生解析器所需的宏。然后，我们定义了名为 `HtmlParser` 的解析器结构，用 `#[derive(Parser)]` 对其进行标记，并为其提供其中文件的名称。我们使用 `grammar =` 指令定义了我们的规则。

要查看它当前的功能，让我们进行以下设置：

```rust
const HTML:&str = "<html> </html>";

fn main() {
    // parse the input using the rule 'document'
    let parse = HtmlParser::parse(Rule::document, HTML).unwrap();
    // make an iterator over the pairs in the rule
    for pair in parse.into_iter(){
        // match the rule, as the rule is an enum
        match pair.as_rule(){
            Rule::document =>{
                // for each sub-rule, print the inner contents
                for tag in pair.into_inner(){
                    println!("{:?}",tag);
                }
            }
            // as we have  parsed document, which is a top level rule, there
            // cannot be anything else
            _ => unreachable!()
        }
    }
}
```

以上将产生以下输出：

```
Pair { rule: tag, span: Span { str: "<html>", start: 0, end: 6 }, inner: [] }
Pair { rule: tag, span: Span { str: "</html>", start: 7, end: 14 }, inner: [] }
Pair { rule: EOI, span: Span { str: "", start: 14, end: 14 }, inner: [] }
```

这表明第一个匹配是 `<html>` 标记，然后是 `</html>` 标记，最后是输入结束。

让我们尝试添加更多标签，看看它是否仍然有效：

```rust
const HTML:&str = "<html> <head> </head> <body></body> </html>";
```

结果应该如下所示：

```
Pair { rule: tag, span: Span { str: "<html>", start: 0, end: 6 }, inner: [] }
Pair { rule: tag, span: Span { str: "<head>", start: 7, end: 13 }, inner: [] }
Pair { rule: tag, span: Span { str: "</head>", start: 14, end: 21 }, inner: [] }
Pair { rule: tag, span: Span { str: "<body>", start: 22, end: 28 }, inner: [] }
Pair { rule: tag, span: Span { str: "</body>", start: 28, end: 35 }, inner: [] }
Pair { rule: tag, span: Span { str: "</html>", start: 36, end: 43 }, inner: [] }
Pair { rule: EOI, span: Span { str: "", start: 43, end: 43 }, inner: [] }
```

它正确识别所有标签🎉

现在让我们扩展它以允许标签内有文本。为了实现这一点，我们需要定义 `text` ，这可能很棘手。为什么？考虑以下输入：

```
<start> abc < def > </end>
```

有了上面的内容，如果我们将 `text` 定义为 `ANY+` ，它将吞噬 `abc` 字符串中从 `a` 字符开始的所有内容到并包括 `</end>` 。

如果我们将 `text` 定义为 `ASCII_ALPHANUMERIC` ，这将解决上述问题，但它会在 `abc` 符号上给我们一个错误/b3> 字符串，因为解析器希望它是标签的开头。

为了克服这个问题，我们定义 `text` 如下：

```
document = { SOI ~ ( tag ~ text?)* ~ EOI }
...
text = { (ASCII_ALPHANUMERIC | other_symbols | non_tag_start | WHITESPACE )+ }
non_tag_start = ${ "<" ~ WHITESPACE+}
other_symbols = { ">" |"@" | ";" | "," }
```

现在， `text` 被定义为重复一次或多次的任何字母数字字符 OR `other_symbols` OR `non_tag_start` OR `WHITESPACE` 。

`other_symbol` 规则负责处理我们想要包含的任何非字母数字符号。同时， `non_tag_start` 是一个原子规则，它匹配严格后跟一个或多个空格的 `<` 。这样，我们就限制了我们认为是文本的内容。我们还被迫在标签开始符号 `<` 和标签名称之间不留任何空格。这对于我们的例子来说是可行的。

现在，考虑以下输入：

```rust
const HTML:&str = "<html> <head> </head> <body> < def > </body> </html>";
```

我们会得到这些结果：

```
Pair { rule: tag, span: Span { str: "<html>", start: 0, end: 6 }, inner: [] }
Pair { rule: tag, span: Span { str: "<head>", start: 7, end: 13 }, inner: [] }
Pair { rule: tag, span: Span { str: "</head>", start: 14, end: 21 }, inner: [] }
Pair { rule: tag, span: Span { str: "<body>", start: 22, end: 28 }, inner: [] }
Pair { rule: text, span: Span { str: "< def >", start: 29, end: 36 }, inner: [...] }
Pair { rule: tag, span: Span { str: "</body>", start: 37, end: 44 }, inner: [] }
Pair { rule: tag, span: Span { str: "</html>", start: 45, end: 52 }, inner: [] }
Pair { rule: EOI, span: Span { str: "", start: 52, end: 52 }, inner: [] }
```

这正是我们所期望的。

最后，我们需要在标签中引入属性，以便我们可以开始将其解析为文档结构。为了实现这一点，我们将 `attr` 定义为一个或多个 `ASCII_ALPHA` 字符，后跟 `=` ，然后是带引号的文本：

```
attr = { ASCII_ALPHA+ ~ "=" ~ "\"" ~ text ~ "\""}
```

我们还将修改 `tag` ，如下所示：

```
tag = ${ "<" ~ "/"? ~ ASCII_ALPHA+ ~ (WHITESPACE+ ~ attr)* ~ "/"? ~ ">" }
```

如果我们在以下内容上运行它，我们已将其转换为原始字符串，这样我们就不必转义引号：

```rust
const HTML:&str = r#"<html lang=" en"> <head> </head> <body> < def > </body> </html>"#;
```

我们将得到预期的输出：

```
Pair { rule: tag, span: Span { str: "<html lang=\" en\">", start: 0, end: 17 }, inner: [Pair { rule: attr, span: Span { str: "lang=\" en\"", start: 6, end: 16 }, inner: [Pair { rule: text, span: Span { str: " en", start: 12, end: 15 }, inner: [] }] }] }
Pair { rule: tag, span: Span { str: "<head>", start: 18, end: 24 }, inner: [] }
Pair { rule: tag, span: Span { str: "</head>", start: 25, end: 32 }, inner: [] }
Pair { rule: tag, span: Span { str: "<body>", start: 33, end: 39 }, inner: [] }
Pair { rule: text, span: Span { str: "< def >", start: 40, end: 47 }, inner: [...] }
Pair { rule: tag, span: Span { str: "</body>", start: 48, end: 55 }, inner: [] }
Pair { rule: tag, span: Span { str: "</html>", start: 56, end: 63 }, inner: [] }
Pair { rule: EOI, span: Span { str: "", start: 63, end: 63 }, inner: [] }
```

正如预期的那样，第一对的 `inner` 字段包含 `attr` 规则。

为了帮助我们确定文档的结构、标签的嵌套等，我们将像这样分开 `start_tag` 、 `end_tag` 和 `self_closing_tag` 定义：

```
tag = ${ start_tag | self_closing_tag | end_tag }
start_tag = { "<" ~ ASCII_ALPHA+ ~ (WHITESPACE+ ~ attr)* ~ ">" }
end_tag = { "</" ~ ASCII_ALPHA+ ~ (WHITESPACE+ ~ attr)* ~ ">" }
self_closing_tag = { "<" ~ ASCII_ALPHA+ ~ (WHITESPACE+ ~ attr)* ~ "/>" }
```

请注意，在这里，我们可以更改 `tag` 定义的顺序，因为它们是互斥的，这意味着任何 `start_tag` 都不能是 `self_closing_tag` 等等。

为了检查这一点，我们使用以下输入：

```rust
const HTML:&str = r#"<html lang="en"> <head> </head> <body> <div class="c1" id="id1"> <img src="path"/> </div> </body> </html>"#;
```

预期输出如下，但请注意，它是手动格式化的，并且为了更好的可读性，开始和结束位置已被截断：

```
Pair { rule: tag, span: Span { str: "<html lang=\"en\">" ... }, 
  inner: [Pair { rule: start_tag, span: Span { str: "<html lang=\"en\">" ...}, 
    inner: [Pair { rule: attr, span: Span { str: "lang=\"en\"" ... }, 
      inner: [Pair { rule: text, span: Span { str: "en"}, inner: [] }] }] }] }

Pair { rule: tag, span: Span { str: "<head>" ... }, 
  inner: [Pair { rule: start_tag, span: Span { str: "<head>" ... }, inner: [] }] }

Pair { rule: tag, span: Span { str: "</head>" ... }, 
  inner: [Pair { rule: end_tag, span: Span { str: "</head>" ... }, inner: [] }] }

Pair { rule: tag, span: Span { str: "<body>" ... }, 
  inner: [Pair { rule: start_tag, span: Span { str: "<body>" ... }, inner: [] }] }

Pair { rule: tag, span: Span { str: "<div class=\"c1\" id=\"id1\">" ... }, 
  inner: [Pair { rule: start_tag, span: Span { str: "<div class=\"c1\" id=\"id1\">" ...}, 
    inner: [Pair { rule: attr, span: Span { str: "class=\"c1\"" ... }, 
      inner: [Pair { rule: text, span: Span { str: "c1" ... }, inner: [] }] }, 
  Pair { rule: attr, span: Span { str: "id=\"id1\"" ... }, 
      inner: [Pair { rule: text, span: Span { str: "id1" ... }, inner: [] }] }] }] }

Pair { rule: tag, span: Span { str: "<img src=\"path\"/>" ... }, 
  inner: [Pair { rule: self_closing_tag, span: Span { str: "<img src=\"path\"/>"...},
    inner: [Pair { rule: attr, span: Span { str: "src=\"path\"" ... }, 
      inner: [Pair { rule: text, span: Span { str: "path" ... }, inner: [] }] }] }] }

Pair { rule: tag, span: Span { str: "</div>" ...}, 
  inner: [Pair { rule: end_tag, span: Span { str: "</div>" ... }, inner: [] }] }

Pair { rule: tag, span: Span { str: "</body>" ...}, 
  inner: [Pair { rule: end_tag, span: Span { str: "</body>" ...}, inner: [] }] }

Pair { rule: tag, span: Span { str: "</html>" ...}, 
  inner: [Pair { rule: end_tag, span: Span { str: "</html>" ... }, inner: [] }] }

Pair { rule: EOI, span: Span { str: "" ... }, inner: [] }
```

正如我们所看到的，每个标签都被正确标识为 `start_tag` 或 `end_tag` ，但 `img` 标签除外，它被标识为 `self_closing_tag` 。

现在您可以使用这些标记来构建文档树结构。该项目的 GitHub 存储库实现了将其转换为树结构的代码。这段代码可以解析以下内容：

```rust
<html lang="en" l="abc"> 
<head> 
</head> 
<body> 
    <div class="c1" id="id1"> 
        Hello 
        <img src="path"/> 
    </div> 
    <div>
        <p>
            <p>
                abc
    </div>
    <p>
        jkl
    </p>
    <img/>
    </p> 
    </div>
</body> 
</html>
```

然后它可以打印层次结构，其应类似于以下内容：

```
- html
  - head
  - body
    - div
      - text(Hello)
      - img
    - div
      - p
        - p
          - text(abc)
    - p
      - text(jkl)
    - img
```

## 为 Rust 或您自己的语言编写解析器

使用我们在前面几节中看到的概念，您可以为现有语言编写类似的解析器，或者定义自己的语法并为您自己的语言编写解析器。

作为一个例子，让我们考虑为 Rust 语法的子集编写一个解析器。由于为 Rust 编写完整的解析器本质上是为 Rust 编译器编写前端，因此我们不会在这里介绍完整的语法，也不会显示详细的代码示例。

首先，让我们考虑内置类型和关键字。我们可以为这些字符串编写解析规则，如下所示：

```
LET_KW = { "let" }
FOR_KW = { "for" }
...
U8_TYP = { "u8" }
I8_TYP = { "i8" }
...
TYPES = { U8_TYP | I8_TYP | ..}
```

完成此操作后，我们可以为包含 `ASCII_ALPHA` 字符、 `ASCII_DIGIT` 字符和下划线 `_` 符号的字符集合定义一个变量名称，如下所示：

```
VAR_NAME = @{ ("_"|ASCII_ALPHA)~(ASCII_ALPHA | ASCII_DIGIT | "_")* }
```

这将允许变量名称以下划线或字母字符开头，并且名称可以包含字母字符、数字或下划线。

之后，定义一个 let 表达式来声明一个没有值的变量就很简单了 –

```
VAR_DECL = {LET_KW ~ VAR_NAME ~ (":" ~ TYPES)? ~ ("=" ~ VALUE)?~ ";"}
```

我们从 `let` 关键字开始，后面是变量名称，然后是可选的变量类型和要分配的可选值（以必需的分号结尾）。该值本身可以定义为数字、字符串或另一个变量：

```
VALUE = { NUMBER | STRING | VAR_NAME }
```

通过这种方式，我们可以定义支持的结构并解析任何语言的语法。

除了 Rust 的语法之外，我们还可以定义自定义语法：

```
VAR_DECL = { "let there be" VAR_NAME ~( "which stores" ~ TYPES )? ~ ("which is equal to" ~ VALUE)? "." }
```

这将允许我们以以下格式声明变量：

```
let there be num which stores i8 which is equal to 5.
let there be counter which is equal to 7.
let there be greeting which stores string.
```

这样，我们就可以定义自己的语法和文法，使用Pest进行解析，构建自己的语言。

##  结论

在本文中，我们了解了为什么需要使用解析器生成器来生成解析器而不是手动编写它们。我们还探索了 Pest 解析器生成器并使用 PEG。最后，我们看到了一个示例 Rust 解析器项目，使用 Pest 来解析简化的 HTML 文档的语法。

相关代码（包括构建文档结构）可以在[我的 GitHub 存储库](https://github.com/YJDoc2/LogRocket-Blog-Code/tree/main/parser-with-pest)中找到。谢谢阅读！



> 下面是一些参考资料和工具：
>
> + [陈天.再探 Parser 和 Parse Combinator](https://zhuanlan.zhihu.com/p/355364928)
> + https://pest.rs/book/
> + https://github.com/pest-parser/awesome-pest