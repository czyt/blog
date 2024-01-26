---
title: "转换数字到Excel列字母实现"
date: 2024-01-25
tags: ["rust", "go"]
draft: false
---

## Rust

实现代码：

```rust
fn convert_to_title(mut n: i32) -> String {
    let mut result = String::new();
    while n != 0 {
        n -= 1;
        let letter = (n % 26) as u8 + b'A';
        result.insert(0, letter as char);
        n /= 26;
    }
    result
}

#[test]
fn test_convert_to_title() {
    let aa = convert_to_title(27);
    assert_eq!(aa, "AC");
}

```

## Go

实现代码：

```go
func convertToTitle(n int) string {
     result := ""
     for n > 0 {
          n--
          letter := n%26
          result = string('A'+letter) + result
          n /= 26
     }
     return result
}
```

## C#

实现代码：

```csharp
using System;
using System.Text; 

public class Solution {
    public string ConvertToTitle(int columnNumber) {
        StringBuilder columnName = new StringBuilder();
    
        while(columnNumber > 0){
            columnNumber--;
            columnName.Insert(0, (char)('A' + columnNumber % 26));
            columnNumber /= 26;
        }

        return columnName.ToString();
    }
}

public class Program 
{
    public static void Main() 
    {
        Solution solution = new Solution();
        Console.WriteLine(solution.ConvertToTitle(27)); // Outputs: AA
        Console.WriteLine(solution.ConvertToTitle(28)); // Outputs: AB
    }
}
```