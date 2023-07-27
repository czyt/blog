---
title: "Golang高效解码xml文件"
date: 2023-07-26
tags: ["golang", "xml"]
draft: false 
---
xml处理需要引用`encoding/xml`包.一般推荐使用 `xml.Decoder` 替代 `xml.Unmarshal`。
`xml.Decoder` 是一个流式 XML 解码器，它可以边读取边解码，而不需要将整个 XML 文档加载到内存中。相比之下，`xm1.Unmarshal` 会将整个 XML 文档加载到内存中然后再进行解码。因此，对于大型 XML 文件，使用`xml.Decoder` 可以节省内存并提高性能。

## 小的Xml文件

下面是一个例子

```go
package main

import (
	"encoding/xml"
	"os"
	"testing"
)

type UserData struct {
	Name string `xml:"name"`
	Age  int32  `xml:"age"`
}

type Pocket struct {
	Data []UserData `xml:"users"`
}

func TestXmlDecode(t *testing.T) {
	file, err := os.Open("testdata/userdata.xml")
	if err != nil {
		t.Fatal(err)
	}
	var pocket Pocket
	if err := xml.NewDecoder(file).Decode(&pocket); err != nil {
		t.Fatal(err)
	}
	t.Log(pocket)
}

func TestXmlEncode(t *testing.T) {

	pocket := Pocket{Data: []UserData{
		{Name: "czyt", Age: 20},
		{Name: "jone", Age: 12},
		{Name: "jack", Age: 30},
	}}

	file, err := os.OpenFile("testdata/userdata.xml", os.O_RDWR|os.O_CREATE, 0755)
	if err != nil {
		t.Fatal(err)
	}
	if err := xml.NewEncoder(file).Encode(pocket); err != nil {
		t.Fatal(err)
	}
}

```

## 大的文件xml文件

​      在处理大的xml文件，推荐开启 xml.Decoder 的 `strict` 模式。在创建xml.Decoder 对象时，可以设置其 strict 字段为false，以允许解码器在遇到无法解析的 XML 特性时继续运行。这可以提高对于大型 XML 文件的容错能力。

​    有时候可能只需要解析其中的一部分数据，可以使用xml.Decoder 的`skip()` 方法跳过不需要的部分。

```go
func TestXmlStream(t *testing.T) {
	file, err := os.Open("testdata/userdata.xml")
	if err != nil {
		t.Fatal(err)
	}
	decoder := xml.NewDecoder(file)
	expectCount := 3
	foundDataCount := 0
	for {
		token, _ := decoder.Token()
		if token == nil {
			break
		}

		switch se := token.(type) {
		case xml.StartElement:
			if se.Name.Local == "users" {
				var ud UserData
				if err := decoder.DecodeElement(&ud, &se); err != nil {
					continue
				}
				foundDataCount += 1
			}
			// 跳过某些字段元素及其子元素
			if se.Name.Local == "someHugePart" {
				if err := decoder.Skip(); err != nil {
					t.Log(err)
				}
			}
		}
	}
	t.Log(expectCount == foundDataCount)
}
```

## 参考链接

+ https://eli.thegreenplace.net/2019/faster-xml-stream-processing-in-go/
+ https://blog.singleton.io/posts/2012-06-19-parsing-huge-xml-files-with-go/
