---
title: "使用melody来创建正则表达式"
date: 2023-12-15
tags: ["regexp",  "tools"]
draft: false
---

[melody](https://github.com/yoav-lavi/melody)是一款rust编写的编译输出为正则表达式的语言。Arch用户可以使用 `paru -Syu melody `来安装，vscode和jetbrains系的IDE也有插件。

# 语法

下面是基于官方book的机翻语法。

## 量词

- `... of` - 用于表达特定数量的模式。相当于正则表达式 `{5}` （假设 `5 of ...` ）
- `... to ... of` - 用于表示模式范围内的数量。相当于正则表达式 `{5,9}` （假设 `5 to 9 of ...` ）
- `over ... of` - 用于表达多个模式。相当于正则表达式 `{6,}` （假设 `over 5 of ...` ）
- `some of` - 用于表达 1 个或多个模式。相当于正则表达式 `+`
- `any of` - 用于表达 0 个或多个模式。相当于正则表达式 `*`
- `option of` - 用于表示模式的 0 或 1。相当于正则表达式 `?`

所有量词前面都可以添加 `lazy` 以匹配最少数量的字符而不是最多的字符（贪婪）。相当于正则表达式 `+?` 、 `*?` 等。

##  符号

- `<char>` - 匹配任何单个字符。相当于正则表达式 `.`
- `<space>` - 匹配空格字符。相当于正则表达式``
- `<whitespace>` - 匹配任何类型的空白字符。相当于正则表达式 `\s` 或 `[ \t\n\v\f\r]`
- `<newline>` - 匹配换行符。相当于正则表达式 `\n`
- `<tab>` - 匹配制表符。相当于正则表达式 `\t`
- `<return>` - 匹配回车符。相当于正则表达式 `\r`
- `<feed>` - 匹配换页符。相当于正则表达式 `\f`
- `<null>` - 匹配空字符。相当于正则表达式 `\0`
- `<digit>` - 匹配任何单个数字。相当于正则表达式 `\d` 或 `[0-9]`
- `<vertical>` - 匹配垂直制表符。相当于正则表达式 `\v`
- `<word>` - 匹配单词字符（任何拉丁字母、任何数字或下划线）。相当于正则表达式 `\w` 或 `[a-zA-Z0-9_]`
- `<alphabetic>` - 匹配任何单个拉丁字母。相当于正则表达式 `[a-zA-Z]`
- `<alphanumeric>` - 匹配任何单个拉丁字母或任何单个数字。相当于正则表达式 `[a-zA-Z0-9]`
- `<boundary>` - 匹配 `<word>` 匹配的字符和 `<word>` 不匹配的字符之间的字符，而不消耗该字符。相当于正则表达式 `\b`
- `<backspace>` - 匹配退格控制字符。相当于正则表达式 `[\b]`

所有符号都可以在 `not` 前面，以匹配除该符号之外的任何字符

## 特殊符号

- `<start>` - 匹配字符串的开头。相当于正则表达式 `^`
- `<end>` - 匹配字符串的结尾。相当于正则表达式 `$`

## unicode

注意：在 CLI（ `-t` 或 `-f` ）中测试时不支持这些，因为使用的正则表达式引擎不支持 unicode 类别。这些需要使用 `u` 标志。

- `<category::letter>` - 来自任何语言的任何类型的字母
  - `<category::lowercase_letter>` - 具有大写变体的小写字母
  - `<category::uppercase_letter>` - 具有小写变体的大写字母。
  - `<category::titlecase_letter>` - 仅当单词的第一个字母大写时出现在单词开头的字母
  - `<category::cased_letter>` - 存在小写和大写变体的字母
  - `<category::modifier_letter>` - 像字母一样使用的特殊字符
  - `<category::other_letter>` - 没有小写和大写变体的字母或表意文字
- `<category::mark>` - 用于与另一个字符组合的字符（例如重音符号、变音符号、封闭框等）
  - `<category::non_spacing_mark>` - 旨在与另一个字符组合而不占用额外空间的字符（例如重音符号、变音符号等）
  - `<category::spacing_combining_mark>` - 用于与另一个占用额外空间的字符组合的字符（许多东方语言中的元音符号）
  - `<category::enclosing_mark>` - 包含与其组合的字符的字符（圆形、方形、键帽等）
- `<category::separator>` - 任何类型的空白或不可见分隔符
  - `<category::space_separator>` - 不可见但占用空间的空白字符
  - `<category::line_separator>` - 行分隔符 U+2028
  - `<category::paragraph_separator>` - 段落分隔符 U+2029
- `<category::symbol>` - 数学符号、货币符号、装饰符号、方框图字符等
  - `<category::math_symbol>` - 任何数学符号
  - `<category::currency_symbol>` - 任何货币符号
  - `<category::modifier_symbol>` - 组合字符（标记）作为其自身的完整字符
  - `<category::other_symbol>` - 各种非数学符号、货币符号或组合字符的符号
- `<category::number>` - 任何脚本中的任何类型的数字字符
  - `<category::decimal_digit_number>` - 除表意文字之外的任何文字中的数字 0 到 9
  - `<category::letter_number>` - 看起来像字母的数字，例如罗马数字
  - `<category::other_number>` - 上标或下标数字，或非数字 0–9 的数字（不包括表意文字的数字）
- `<category::punctuation>` - 任何类型的标点符号
  - `<category::dash_punctuation>` - 任何类型的连字符或破折号
  - `<category::open_punctuation>` - 任何类型的左括号
  - `<category::close_punctuation>` - 任何类型的右括号
  - `<category::initial_punctuation>` - 任何类型的开盘报价
  - `<category::final_punctuation>` - 任何类型的收盘价
  - `<category::connector_punctuation>` - 标点符号，例如连接单词的下划线
  - `<category::other_punctuation>` - 除破折号、括号、引号或连接符之外的任何类型的标点字符
- `<category::other>` - 不可见的控制字符和未使用的代码点
  - `<category::control>` - ASCII 或 Latin-1 控制字符：0x00–0x1F 和 0x7F–0x9F
  - `<category::format>` - 不可见的格式指示器
  - `<category::private_use>` - 保留供私人使用的任何代码点
  - `<category::surrogate>` - UTF-16 编码中代理对的一半
  - `<category::unassigned>` - 未分配字符的任何代码点

这些描述来自regular-expressions.info

## 字符范围

- `... to ...` - 与数字或字母字符一起使用来表示字符范围。相当于正则表达式 `[5-9]` （假设 `5 to 9` ）或 `[a-z]` （假设 `a to z` ）

## 文字

- `"..."` 或 `'...'` - 用于标记匹配的文字部分。 Melody 会根据需要自动转义字符。引号（与文字周围的同类）应该被转义

## Raw

- ``...`` - 直接添加到输出中，无需任何转义

## 分组

- `capture` - 用于打开 `capture` 或命名的 `capture` 块。捕获的模式稍后可在匹配列表中使用（位置匹配或命名匹配）。相当于正则表达式 `(...)`
- `match` - 用于打开 `match` 块，匹配内容而不捕获。相当于正则表达式 `(?:...)`
- `either` - 用于打开 `either` 块，匹配块内的语句之一。相当于正则表达式 `(?:...|...)`

## 断言

- `ahead` - 用于打开 `ahead` 块。相当于正则表达式 `(?=...)` 。在表达式之后使用
- `behind` - 用于打开 `behind` 块。相当于正则表达式 `(?<=...)` 。在表达式之前使用

断言前面可以添加 `not` 以创建否定断言（相当于正则表达式 `(?!...)` 、 `(?<!...)` ）

## 变量

- `let .variable_name = { ... }` - 定义语句块中的变量。稍后可以与 `.variable_name` 一起使用。变量必须在使用前声明。变量调用不能直接量化，如果要量化变量调用，请使用组

   例子：

  ```rs
  let .a_and_b = {
    "a";
    "b";
  }
  
  .a_and_b;
  "c";
  
  // abc
  ```

##  附加功能

- `/* ... */` 、 `// ...` - 用于标记注释（注意： `// ...` 注释必须单独一行）
# 使用

Todo