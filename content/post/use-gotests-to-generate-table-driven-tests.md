---
title: "使用gotests生成表驱动测试"
date: 2022-07-22
tags: ["golang", "test", "generate", "tools"]
draft: false
---

   使用`gotests`可以很方便的生成表驱动测试代码，表驱动测试的具体内容，请参考[go官方的wiki](https://github.com/golang/go/wiki/TableDrivenTests)。下面是具体的使用方法。
## 安装
使用下面命令进行安装
```bash
go install github.com/cweill/gotests/gotests@latest
```

如果是go1.16之前的版本，可以使用命令` go get -u github.com/cweill/gotests/...`来进行安装。

## 使用

`gotests`支持的参数如下：

```
Usage of C:\Users\czyt\go\bin\gotests.exe:
  -all
        generate tests for all functions and methods
  -excl string
        regexp. generate tests for functions and methods that don't match. Takes precedence over -only, -exported, and -all
  -exported
        generate tests for exported functions and methods. Takes precedence over -only and -all
  -i    print test inputs in error messages
  -nosubtests
        disable generating tests using the Go 1.7 subtests feature
  -only string
        regexp. generate tests for functions and methods that match only. Takes precedence over -all
  -parallel
        enable generating parallel subtests
  -template string
        optional. Specify custom test code templates, e.g. testify. This can also be set via environment variable GOTESTS_TEMPLATE
  -template_dir string
        optional. Path to a directory containing custom test code templates. Takes precedence over -template. This can also be set via environment variable GOTESTS_TEMPLATE_DIR
  -template_params string
        read external parameters to template by json with stdin
  -template_params_file string
        read external parameters to template by json with file
  -w    write output to (test) files instead of stdout
```

### 小试牛刀

新建一个go文件，命名为`greeter.go`

```go
package greeter

import "fmt"

func Greeter(user string) string {
	return fmt.Sprintf("您好啊！%s",user)
}
```

使用`gotests -all -w greeter.go `生成测试文件`greeter_test.go`，文件内容如下：

```go
package greeter

import "testing"

func TestGreeter(t *testing.T) {
	type args struct {
		user string
	}
	tests := []struct {
		name string
		args args
		want string
	}{
		// TODO: Add test cases.
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := Greeter(tt.args.user); got != tt.want {
				t.Errorf("Greeter() = %v, want %v", got, tt.want)
			}
		})
	}
}

```

