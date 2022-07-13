---
title: "Golang Expr不完全指南"
date: 2022-07-13
tags: ["golang", "expr", "DSL"]
draft: false
---
## 安装
库的说明
> Expr package provides an engine that can compile and evaluate expressions. An expression is a one-liner that returns a value (mostly, but not limited to, booleans). It is designed for simplicity, speed and safety.

> The purpose of the package is to allow users to use expressions inside configuration for more complex logic. It is a perfect candidate for the foundation of a business rule engine.

安装

```bash
go get -u /github.com/antonmedv/expr
```

如果是gomod模式，则需要定义为

```go
github.com/antonmedv/expr latest
```

## 基础使用

### 表达式计算

```go
package main

import (
	"fmt"
	"github.com/antonmedv/expr"
)

func main() {
	env := map[string]interface{}{
		"foo": 1,
		"bar": 2,
	}

	out, err := expr.Eval("foo + bar", env)

	if err != nil {
		panic(err)
	}
	fmt.Print(out)
}
```

### 代码片段编译执行

传入基本类型

```go
package main

import (
	"fmt"

	"github.com/antonmedv/expr"
)

func main() {
	env := map[string]interface{}{
		"greet":   "Hello, %v!",
		"names":   []string{"world", "you"},
		"sprintf": fmt.Sprintf, // You can pass any functions.
	}

	code := `sprintf(greet, names[0])`

	// Compile code into bytecode. This step can be done once and program may be reused.
	// Specify environment for type check.
	program, err := expr.Compile(code, expr.Env(env))
	if err != nil {
		panic(err)
	}

	output, err := expr.Run(program, env)
	if err != nil {
		panic(err)
	}

	fmt.Print(output)
}
```

传入自定义结构体

```go
package main

import (
	"fmt"
	"time"

	"github.com/antonmedv/expr"
)

type Env struct {
	Tweets []Tweet
}

// Methods defined on such struct will be functions.
func (Env) Format(t time.Time) string { return t.Format(time.RFC822) }

type Tweet struct {
	Text string
	Date time.Time
}

func main() {
	code := `map(filter(Tweets, {len(.Text) > 0}), {.Text + Format(.Date)})`

	// We can use an empty instance of the struct as an environment.
	program, err := expr.Compile(code, expr.Env(Env{}))
	if err != nil {
		panic(err)
	}

	env := Env{
		Tweets: []Tweet{{"Oh My God!", time.Now()}, {"How you doin?", time.Now()}, {"Could I be wearing any more clothes?", time.Now()}},
	}

	output, err := expr.Run(program, env)
	if err != nil {
		panic(err)
	}

	fmt.Print(output)
}
```

### 自定义函数

```go
package main

import (
	"fmt"
	"github.com/antonmedv/expr"
)

func main() {
	env := map[string]interface{}{
		"foo": 1,
		"double": func(i int) int { return i * 2 },
	}

	out, err := expr.Eval("double(foo)", env)

	if err != nil {
		panic(err)
	}
	fmt.Print(out)
}
```

### 注入对象方法

**对象方法必须是导出的**

```go
package main

import (
	"fmt"
	"time"

	"github.com/antonmedv/expr"
)

type Env struct {
	Tweets []Tweet
}

// Methods defined on such struct will be functions.
func (Env) Format(t time.Time) string { return t.Format(time.RFC822) }

type Tweet struct {
	Text string
	Date time.Time
}

func main() {
	code := `map(filter(Tweets, {len(.Text) > 0}), {.Text + Format(.Date)})`

	// We can use an empty instance of the struct as an environment.
	program, err := expr.Compile(code, expr.Env(Env{}))
	if err != nil {
		panic(err)
	}

	env := Env{
		Tweets: []Tweet{{"Oh My God!", time.Now()}, {"How you doin?", time.Now()}, {"Could I be wearing any more clothes?", time.Now()}},
	}

	output, err := expr.Run(program, env)
	if err != nil {
		panic(err)
	}

	fmt.Print(output)
}
```

### Fast functions

Fast functions(快速函数)可以不使用反射进行调用，这将提高性能，但丢失了参数的类型。只要函数或方法的签名为下面的一种，那么就可以作为Fast functions使用。

```go
func(...interface{}) interface{}
func(...interface{}) (interface{}, error)
```

示例

```go
package main

import (
	"fmt"
	"github.com/antonmedv/expr"
)

type Env map[string]interface{}

func (Env) FastMethod(...interface{}) interface{} {
	return "Hello, "
}

func main() {
	env := Env{
		"fast_func": func(...interface{}) interface{} { return "world" },
	}

	out, err := expr.Eval("FastMethod() + fast_func()", env)

	if err != nil {
		panic(err)
	}
	fmt.Print(out)
}
```

### 错误返回

如果函数或方法返回非nil的error，那么这个错误将返回给其对应的调用者。

```go
package main

import (
	"errors"
	"fmt"
	"github.com/antonmedv/expr"
)

func main() {
	env := map[string]interface{}{
		"foo": -1,
		"double": func(i int) (int, error) {
			if i < 0 {
				return 0, errors.New("value cannot be less than zero")
			}
			return i * 2, nil
		},
	}

	out, err := expr.Eval("double(foo)", env)

	// This `err` will be the one returned from `double` function.
	// err.Error() == "value cannot be less than zero"
	if err != nil {
		panic(err)
	}
	fmt.Print(out)
}
```

## 高阶使用

### Operator Override(运算符覆盖)

例如表达式`Now().Sub(CreatedAt) `用来计算已经创建了多长时间，你可能想改造成下面这个样子

```go
Now() - CreatedAt
```

可以使用`expr.Operator`来实现运算符覆盖：

```go
package main

import (
	"fmt"
	"time"

	"github.com/antonmedv/expr"
)

func main() {
	code := `(Now() - CreatedAt).Hours() / 24 / 365`

	// We can define options before compiling.
	options := []expr.Option{
		expr.Env(Env{}),
		expr.Operator("-", "Sub"), // Override `-` with function `Sub`.
	}

	program, err := expr.Compile(code, options...)
	if err != nil {
		panic(err)
	}

	env := Env{
		CreatedAt: time.Date(1987, time.November, 24, 20, 0, 0, 0, time.UTC),
	}

	output, err := expr.Run(program, env)
	if err != nil {
		panic(err)
	}
	fmt.Print(output)
}

type Env struct {
	datetime
	CreatedAt time.Time
}

// Functions may be defined on embedded structs as well.
type datetime struct{}

func (datetime) Now() time.Time                   { return time.Now() }
func (datetime) Sub(a, b time.Time) time.Duration { return a.Sub(b) }
```

### Visitor 

[ast](https://pkg.go.dev/github.com/antonmedv/expr/ast?tab=doc)包提供了`ast.Visitor`接口和`ast.Walk`方法，你可以使用他们来浏览编译程序的ast树。例如，您想要获取所有的变量名。

```go
package main

import (
	"fmt"

	"github.com/antonmedv/expr/ast"
	"github.com/antonmedv/expr/parser"
)

type visitor struct {
	identifiers []string
}

func (v *visitor) Enter(node *ast.Node) {}
func (v *visitor) Exit(node *ast.Node) {
	if n, ok := (*node).(*ast.IdentifierNode); ok {
		v.identifiers = append(v.identifiers, n.Value)
	}
}

func main() {
	tree, err := parser.Parse("foo + bar")
	if err != nil {
		panic(err)
	}

	visitor := &visitor{}
	ast.Walk(&tree.Node, visitor)

	fmt.Printf("%v", visitor.identifiers) // outputs [foo bar]
}
```

### Patch

在将 AST 编译为 `expr.Compile` 函数中的字节码之前，可以应用已实现的访问者。

```go
program, err := expr.Compile(code, expr.Patch(&visitor{}))
```

这对于您想扩展 Expr 语言的功能的某些边缘情况很有用。 在下一个示例中，我们将用 list[len(list)-1] 替换表达式 list[-1]。

```go
package main

import (
	"fmt"

	"github.com/antonmedv/expr"
	"github.com/antonmedv/expr/ast"
)

func main() {
	env := map[string]interface{}{
		"list": []int{1, 2, 3},
	}

	code := `list[-1]` // will output 3

	program, err := expr.Compile(code, expr.Env(env), expr.Patch(&patcher{}))
	if err != nil {
		panic(err)
	}

	output, err := expr.Run(program, env)
	if err != nil {
		panic(err)
	}
	fmt.Print(output)
}

type patcher struct{}

func (p *patcher) Enter(_ *ast.Node) {}
func (p *patcher) Exit(node *ast.Node) {
	n, ok := (*node).(*ast.IndexNode)
	if !ok {
		return
	}
	unary, ok := n.Index.(*ast.UnaryNode)
	if !ok {
		return
	}
	if unary.Operator == "-" {
		ast.Patch(&n.Index, &ast.BinaryNode{
			Operator: "-",
			Left:     &ast.BuiltinNode{Name: "len", Arguments: []ast.Node{n.Node}},
			Right:    unary.Node,
		})
	}

}
```

对于类型信息也同样奏效。 下面是一个例子将所有的 fmt.Stringer 接口都自动转换为字符串类型的例子。

```go
package main

import (
	"fmt"
	"reflect"

	"github.com/antonmedv/expr"
	"github.com/antonmedv/expr/ast"
)

func main() {
	code := `Price == "$100"`

	program, err := expr.Compile(code, expr.Env(Env{}), expr.Patch(&stringerPatcher{}))
	if err != nil {
		panic(err)
	}

	env := Env{100_00}

	output, err := expr.Run(program, env)
	if err != nil {
		panic(err)
	}
	fmt.Print(output)
}

type Env struct {
	Price Price
}

type Price int

func (p Price) String() string {
	return fmt.Sprintf("$%v", int(p)/100)
}

var stringer = reflect.TypeOf((*fmt.Stringer)(nil)).Elem()

type stringerPatcher struct{}

func (p *stringerPatcher) Enter(_ *ast.Node) {}
func (p *stringerPatcher) Exit(node *ast.Node) {
	t := (*node).Type()
	if t == nil {
		return
	}
	if t.Implements(stringer) {
		ast.Patch(node, &ast.MethodNode{
			Node:   *node,
			Method: "String",
		})
	}

}
```

## 性能

Expr 有一堆优化，可以在编译阶段产生更优化的程序。

### In array

```go
value in ['foo', 'bar', 'baz']
```

如果 expr 在数组中找到 in 或 not in 表达式，它将被转换为：

```go
value in {"foo": true, "bar": true, "baz": true}
```

### Constant folding

具有常量的算术表达式在编译步骤中计算并替换为结果。

```go
-(2-5)**3-2/(+4-3)+-2
```

将被编译为单个数字:

```
23
```

所以在表达式中使用一些算术来提高可读性是安全的:

```
percentage > 0.3 * 100
```

因为它将被简化为:

```
percentage > 30
```

## In range

```
user.Age in 18..32
```

将替换为二元运算符:

```
18 <= user.Age && user.Age <= 32
```

`not in` 运算符也可以使用.

## Const range

```
1..10_000
```

在编译阶段计算的范围，用预先分配的切片来补充。

## Const expr

如果某个函数用 `expr.ConstExpr` 标记为常量表达式。当所有参数都是常量时，它将被调用结果替换。

```
expr.ConstExpt("fib")
fib(42)
```

将在编译步骤中替换为 `fib(42)` 的结果。 运行时无需计算。

## Reuse VM

可以在程序的重新运行之间重用虚拟机。 这会稍微提高性能（从 4% 到 40%，具体取决于程序）。

```
package main

import (
	"fmt"
	"github.com/antonmedv/expr"
	"github.com/antonmedv/expr/vm"
)

func main() {
	env := map[string]interface{}{
		"foo": 1,
		"bar": 2,
	}

	program, err := expr.Compile("foo + bar", expr.Env(env))
	if err != nil {
		panic(err)
	}

	// Reuse this vm instance between runs
	v := vm.VM{}

	out, err := v.Run(program, env)
	if err != nil {
		panic(err)
	}

	fmt.Print(out)
}
```

## Reduced use of reflect

要从结构中获取字段，从映射中获取值，通过索引获取 expr 使用反射包。 Envs 可以实现 vm.Fetcher 接口，避免使用反射：

```
type Fetcher interface {
	Fetch(interface{}) interface{}
}
```

当您需要获取字段时，将使用该方法代替反射函数。 如果未找到该字段，则 Fetch 必须返回 nil。 要为您的类型生成 Fetch，请使用 [Exprgen](https://github.com/antonmedv/expr/blob/master/docs/Exprgen.md)。

