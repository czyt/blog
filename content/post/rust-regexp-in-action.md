---
title: "Rust正则表达式实践"
date: 2024-11-26
draft: false
tags: ["rust","regexp"]
author: "czyt"
---

正则表达式是一种强大的文本处理工具。在 Rust 中，我们主要通过 `regex` crate 来使用正则表达式。让我们通过实际案例来学习。

## 1. 基础匹配

```rust
use regex::Regex;

fn main() {
    // 创建正则表达式对象
    let re = Regex::new(r"\d+").unwrap();
    
    // 测试匹配
    let text = "The year is 2024";
    if re.is_match(text) {
        println!("Found a number!");
    }
    
    // 提取匹配内容
    if let Some(matched) = re.find(text) {
        println!("Found number: {}", matched.as_str());
    }
}
```

## 2. 处理重复单词

根据文章中提到的一个常见问题 - 查找重复单词：

```rust
use regex::Regex;

fn remove_duplicate_words(text: &str) -> String {
    // (\w+) 捕获一个单词，\s+匹配空白字符，\1 回引用前面捕获的单词
    let re = Regex::new(r"(\w+)\s+\1").unwrap();
    re.replace_all(text, "$1").to_string()
}

fn main() {
    let text = "the little cat cat in the hat hat.";
    let result = remove_duplicate_words(text);
    println!("Original: {}", text);
    println!("Fixed: {}", result);
}
```

## 3. 使用断言优化匹配

```rust
use regex::Regex;

fn find_word_boundaries() {
    // \b 表示单词边界
    let re = Regex::new(r"\b\w+\b").unwrap();
    let text = "hello, world!";
    
    for word in re.find_iter(text) {
        println!("Found word: {}", word.as_str());
    }
}
```

## 4. 性能优化

使用 `lazy_static` 预编译正则表达式：

```rust
use lazy_static::lazy_static;
use regex::Regex;

lazy_static! {
    static ref EMAIL_RE: Regex = Regex::new(r"\b[\w\.-]+@[\w\.-]+\.\w+\b").unwrap();
    static ref PHONE_RE: Regex = Regex::new(r"\b\d{3}[-.]?\d{3}[-.]?\d{4}\b").unwrap();
}

fn validate_contact_info(text: &str) -> (bool, bool) {
    let has_email = EMAIL_RE.is_match(text);
    let has_phone = PHONE_RE.is_match(text);
    (has_email, has_phone)
}
```

在新版 Rust 中，我们可以使用 `std::sync::OnceLock` 或 `std::sync::LazyLock`（Rust 1.70.0 引入）来实现静态初始化。

**使用 `OnceLock`**：

```rust
use regex::Regex;
use std::sync::OnceLock;

static EMAIL_REGEX: OnceLock<Regex> = OnceLock::new();

fn get_email_regex() -> &'static Regex {
    EMAIL_REGEX.get_or_init(|| {
        Regex::new(r"\b[\w\.-]+@[\w\.-]+\.\w+\b").unwrap()
    })
}

fn is_valid_email(email: &str) -> bool {
    get_email_regex().is_match(email)
}
```

**使用 `LazyLock`** (需要 Rust 1.70.0+)：

```rust
use regex::Regex;
use std::sync::LazyLock;

static EMAIL_REGEX: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"\b[\w\.-]+@[\w\.-]+\.\w+\b").unwrap()
});

fn is_valid_email(email: &str) -> bool {
    EMAIL_REGEX.is_match(email)
}
```

**多个正则表达式的例子**：

```rust
use regex::Regex;
use std::sync::LazyLock;

static REGEXES: LazyLock<RegexSet> = LazyLock::new(|| {
    RegexSet {
        email: Regex::new(r"\b[\w\.-]+@[\w\.-]+\.\w+\b").unwrap(),
        phone: Regex::new(r"\b\d{3}[-.]?\d{3}[-.]?\d{4}\b").unwrap(),
        date: Regex::new(r"\d{4}-\d{2}-\d{2}").unwrap(),
    }
});

struct RegexSet {
    email: Regex,
    phone: Regex,
    date: Regex,
}

impl RegexSet {
    fn validate_email(&self, text: &str) -> bool {
        self.email.is_match(text)
    }

    fn validate_phone(&self, text: &str) -> bool {
        self.phone.is_match(text)
    }

    fn validate_date(&self, text: &str) -> bool {
        self.date.is_match(text)
    }
}

fn main() {
    let text = "Contact: john@example.com, Phone: 123-456-7890, Date: 2024-03-14";
    
    println!("Contains email: {}", REGEXES.validate_email(text));
    println!("Contains phone: {}", REGEXES.validate_phone(text));
    println!("Contains date: {}", REGEXES.validate_date(text));
}
```

**带错误处理的初始化**：

```rust
use regex::Regex;
use std::sync::LazyLock;

static REGEX_RESULT: LazyLock<Result<Regex, regex::Error>> = LazyLock::new(|| {
    Regex::new(r"^(?P<year>\d{4})-(?P<month>\d{2})-(?P<day>\d{2})$")
});

fn parse_date(text: &str) -> Result<(String, String, String), &'static str> {
    let regex = REGEX_RESULT.as_ref().map_err(|_| "Invalid regex pattern")?;
    
    let caps = regex.captures(text)
        .ok_or("No match found")?;
    
    Ok((
        caps["year"].to_string(),
        caps["month"].to_string(),
        caps["day"].to_string(),
    ))
}
```

**结合 const 表达式**：

```rust
use regex::Regex;
use std::sync::LazyLock;

const EMAIL_PATTERN: &str = r"\b[\w\.-]+@[\w\.-]+\.\w+\b";
const PHONE_PATTERN: &str = r"\b\d{3}[-.]?\d{3}[-.]?\d{4}\b";

static VALIDATORS: LazyLock<Validators> = LazyLock::new(|| Validators::new());

struct Validators {
    email: Regex,
    phone: Regex,
}

impl Validators {
    fn new() -> Self {
        Self {
            email: Regex::new(EMAIL_PATTERN).unwrap(),
            phone: Regex::new(PHONE_PATTERN).unwrap(),
        }
    }

    fn is_valid_email(&self, text: &str) -> bool {
        self.email.is_match(text)
    }

    fn is_valid_phone(&self, text: &str) -> bool {
        self.phone.is_match(text)
    }
}
```


这些新的方法相比 `lazy_static` 有以下优势：

1. 是标准库的一部分，不需要额外的依赖
2. 更简洁的语法
3. 更好的类型推导
4. 更好的性能
5. 支持 const 表达式
6. 更好的错误处理支持

使用建议：
- 对于简单的单个正则表达式，使用 `LazyLock`
- 对于需要更细粒度控制的场景，使用 `OnceLock`
- 对于多个相关的正则表达式，使用结构体组织它们
- 考虑使用 const 表达式存储正则表达式模式
- 适当处理编译错误

## 5. 复杂文本处理

```rust
use regex::Regex;

fn process_text(text: &str) -> Vec<String> {
    let re = Regex::new(r"(?P<key>\w+):\s*(?P<value>[^,]+)").unwrap();
    let mut results = Vec::new();
    
    for caps in re.captures_iter(text) {
        let key = &caps["key"];
        let value = &caps["value"];
        results.push(format!("{}={}", key, value.trim()));
    }
    
    results
}

fn main() {
    let text = "name: John Doe, age: 30, city: New York";
    let results = process_text(text);
    for item in results {
        println!("{}", item);
    }
}
```

## 6. 错误处理

```rust
use regex::Regex;

fn compile_regex(pattern: &str) -> Result<Regex, regex::Error> {
    Regex::new(pattern).map_err(|e| {
        eprintln!("Invalid regex pattern: {}", e);
        e
    })
}

fn main() {
    // 测试有效和无效的模式
    let patterns = vec![
        r"\d+",         // 有效
        r"[unclosed",   // 无效
    ];
    
    for pattern in patterns {
        match compile_regex(pattern) {
            Ok(_) => println!("Valid pattern: {}", pattern),
            Err(e) => println!("Error in pattern {}: {}", pattern, e),
        }
    }
}
```

## 注意事项

1. 正则表达式编译是比较耗费资源的操作，对于频繁使用的正则，应该使用 `lazy_static` 或者新版的延迟初始化手段进行预编译
2. 使用命名捕获组可以提高代码可读性
3. 合理使用断言（`\b`, `^`, `$`）可以提高匹配精确度
4. 避免过度复杂的正则表达式，可能导致性能问题
5. 始终处理正则表达式编译可能出现的错误

