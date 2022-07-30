---
title: "golang使用官方库实现i18n"
date: 2020-06-10
tags: ["golang", "i18n"]
draft: false
---
## 示例
```go
package main

import (
	"fmt"

	"golang.org/x/text/language"
	"golang.org/x/text/message"
	"golang.org/x/text/message/catalog"
)

func main() {
	builder := catalog.NewBuilder()
	chTag:=language.Make("zh_Hans")
	engTag:=language.Make("en")
	builder.SetString(chTag,"hello","您好")
	builder.SetString(engTag,"hello","Hello")
	fmt.Println(builder.Languages())
	option := message.Catalog(builder)
	p := message.NewPrinter(chTag,option)
	p.Printf("hello")

	p2 := message.NewPrinter(engTag,option)
	p2.Printf("hello")
}

```

## 参考

+ https://zyfdegh.github.io/post/201805-translation-go-i18n
+ https://www.alexedwards.net/blog/i18n-managing-translations
+ https://phrase.com/blog/posts/internationalisation-in-go-with-go-i18n/
+ https://lokalise.com/blog/go-internationalization-using-go-i18n/
+ https://go.googlesource.com/proposal/+/master/design/12750-localization.md