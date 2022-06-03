---
title: "Golang反射使用指南"
date: 2022-06-02
tags: ["golang", "reflect"]
draft: false
---

   Go是一门强类型的语言，在大多数情况下，申明一个变量、函数、struct都是直截了当的。在大多数情况下，这些都是够用的，但有时你想在程序运行中来动态扩展程序的信息，也许你想把文件或网络请求中的数据映射到一个变量中;也许你想建立一个能处理不同类型的工具(虽然Go1.18有了泛型)。在这些情况下，你需要使用反射。反射使你有能力在运行时检查、修改和创建变量、函数和结构的能力。

## 反射的核心

![](https://img.draveness.me/golang-interface-to-reflection.png)

> 图片转自 [Go 语言设计与实现](https://draveness.me/golang)

反射的三大核心是***Types**, **Kinds**,  **Values**,下面将围绕这三个方面来进行讲解。

我们先定义一个struct对象。

```go
type User struct {
  Name	string
  Age int
}
```

### 类型Types

通过反射获取类型

```go
u := User{
    Name: "czyt",
    Age:  18,
}
uptr := &u
ot := reflect.TypeOf(u)
otptr := reflect.TypeOf(uptr)
log.Println(ot.Name())
// 打印 User
log.Println(otptr.Name())
// 打印 空

```

通过调用`Name()`方法返回类型的名称，某些类型，如切片或指针，没有名称，此方法返回一个空字符串。

### 种类Kinds

Kind通过调用`Kind()`得来。

```go
u := User{
    Name: "czyt",
    Age:  18,
}
uptr := &u
ot := reflect.TypeOf(u)
otptr := reflect.TypeOf(uptr)
log.Println(ot.Kind())
// 输出 struct
log.Println(otptr.Kind())
// 输出 ptr
```

`Kind()` 返回的是`kind`类型的枚举。

```go
type Kind uint

const (
	Invalid Kind = iota
	Bool
	Int
	Int8
	Int16
	Int32
	Int64
	Uint
	Uint8
	Uint16
	Uint32
	Uint64
	Uintptr
	Float32
	Float64
	Complex64
	Complex128
	Array
	Chan
	Func
	Interface
	Map
	Pointer
	Slice
	String
	Struct
	UnsafePointer
)
```

kind 和 type 之间的区别可能很难理解，但可以这样想。*如果你定义了一个名为 User的结构体，那么种类是struct，类型是 User*.

使用反射时需要注意的一件事：反射包中的所有内容都假定您知道自己在做什么，如果使用不正确，许多函数和方法调用都会出现panic。例如，如果您调用 `reflect.Type `上的方法，该方法与与当前类型不同的类型相关联，您的代码将panic。请务必记得使用你的反射类型来知道哪些方法会起作用，哪些会panic。

如果您的变量是指针、映射、切片、通道或数组，您可以使用 `varType.Elem()` 找出包含的类型。

如果您的变量是一个结构，您可以使用反射来获取结构中的字段数，并取回包含在反射.`StructField` 结构中的每个字段的结构。`reflect.StructField` 为您提供字段上的名称、顺序、类型和结构标记。

### 值Values

除了检查变量的类型之外，您还可以使用反射来读取、设置或创建值。首先，您需要使用 `refVal := reflect.ValueOf(var)` 为您的变量创建一个 `reflect.Value `实例。如果您希望能够使用反射来修改值，则必须使用` refPtrVal := reflect.ValueOf(&var)`获取指向变量的指针。如果你不这样做，你可以使用反射读取值，但你不能修改它。

一旦有了 `reflect.Value`，就可以使用 `Type()` 方法获取变量的 `reflect.Type`。

如果你想修改一个值，记住它必须是一个指针，你必须先取消引用指针。您使用 `refPtrVal.Elem().Set(newRefVal)` 进行更改，传递给 `Set() `的值也必须是 `reflect.Value`。

如果你想创建一个新值，你可以使用函数调用 `newPtrVal := reflect.New(varType)`，传入一个 `reflect.Type`。这将返回一个指针值，然后您可以对其进行修改。如上所述使用 `Elem().Set()`。

最后，您可以通过调用 `Interface()` 方法返回到普通变量。该方法返回一个 interface{} 类型的值。如果您创建了一个指针以便可以修改值，则需要使用 Elem().Interface() 取消引用反射指针。在这两种情况下，您都需要将空接口转换为实际类型才能使用它。

```go
type Foo struct {
	A int `tag1:"First Tag" tag2:"Second Tag"`
	B string
}

func main() {
	greeting := "hello"
	f := Foo{A: 10, B: "Salutations"}

	gVal := reflect.ValueOf(greeting)
	// not a pointer so all we can do is read it
	fmt.Println(gVal.Interface())

	gpVal := reflect.ValueOf(&greeting)
	// it’s a pointer, so we can change it, and it changes the underlying variable
	gpVal.Elem().SetString("goodbye")
	fmt.Println(greeting)

	fType := reflect.TypeOf(f)
	fVal := reflect.New(fType)
	fVal.Elem().Field(0).SetInt(20)
	fVal.Elem().Field(1).SetString("Greetings")
	f2 := fVal.Elem().Interface().(Foo)
	fmt.Printf("%+v, %d, %s\n", f2, f2.A, f2.B)
}
```
 `reflect.Value` 和 `reflect.Type` 都提供了 `Elem()` 方法。

其中`reflect.Value.Elem()` 会返回interface对象v指向的值或指针。当v的类型不是interface或者指针时，程序会panic，当v为该类型的零值时该函数会返回nil

`reflect.Type.Elem()` 返回该类型元素的类型。当类型是`Array`, `Chan`, `Map`, `Ptr`, `Slice`之外的类型时，程序会panic。

## 示例
### 基础示例

#### 动态调用struct方法

获取方法信息

```go
func main()  {
	// 声明一个 Person 接口，并用 Hero 作为接收器
		var person Person = &Hero{}
	// 获取接口Person的类型对象
	typeOfPerson := reflect.TypeOf(person)
	// 打印Person的方法类型和名称
	for i := 0 ; i < typeOfPerson.NumMethod(); i++{
		fmt.Printf("method is %s, type is %s, kind is %s.\n", typeOfPerson.Method(i).Name, typeOfPerson.Method(i).Type, typeOfPerson.Method(i).Type.Kind())
	}
	method, _ := typeOfPerson.MethodByName("Run")
	fmt.Printf("method is %s, type is %s, kind is %s.\n", method.Name, method.Type, method.Type.Kind())
	}


```

动态调用

```go
type M struct{}
type In struct{}
type Out struct{}

func (m *M) Example(in In) Out {
	return Out{}
}
func main() {
	v := reflect.ValueOf(&M{})
	m := v.MethodByName("Example")
	in := m.Type().In(0)
	out := m.Type().Out(0)
	fmt.Println(in, out)
       
	inVal := reflect.New(in).Elem()
        // 可以将 inVal 转为interface后进行赋值之类的操作……
	rtn := m.Call([]reflect.Value{inVal})
	fmt.Println(rtn[0])
}
```



#### 不通过Make创建slice、Map

除了创建内置和用户定义类型的实例外，您还可以使用反射来创建通常需要 `make` 函数的实例。您可以使用 `reflect.MakeSlice`、`reflect.MakeMap` 和 `reflect.MakeChan` 函数制作切片、贴图或通道。在所有情况下，您都提供了一个` reflect.Type `并取回了一个可以使用反射操作的` reflect.Value`，或者您可以分配回一个标准变量。

```go
func main() {
	// declaring these vars, so I can make a reflect.Type
	intSlice := make([]int, 0)
	mapStringInt := make(map[string]int)

	// here are the reflect.Types
	sliceType := reflect.TypeOf(intSlice)
	mapType := reflect.TypeOf(mapStringInt)

	// and here are the new values that we are making
	intSliceReflect := reflect.MakeSlice(sliceType, 0, 0)
	mapReflect := reflect.MakeMap(mapType)

	// and here we are using them
	v := 10
	rv := reflect.ValueOf(v)
	intSliceReflect = reflect.Append(intSliceReflect, rv)
	intSlice2 := intSliceReflect.Interface().([]int)
	fmt.Println(intSlice2)

	k := "hello"
	rk := reflect.ValueOf(k)
	mapReflect.SetMapIndex(rk, rv)
	mapStringInt2 := mapReflect.Interface().(map[string]int)
	fmt.Println(mapStringInt2)
}
```
#### 检查struct是否实现接口

例如下面的定义

```go
type shape interface {
    getNumSides() int
    getArea() int
}

type square struct {
    len int
}

func (s square) getNumSides() int {
    return 4
}
```

常规做法 可以使用`var _ shape = (*square)(nil)`来进行判断，但是某些情况下我们需要使用反射来实现，具体代码如下：

```go
func IsShaperImpl(checkTarget interface{}) bool {
	c := reflect.TypeOf(checkTarget)
	modelType := reflect.TypeOf((*shape)(nil)).Elem()
	return c.Implements(modelType)
}
fmt.Println(IsShaperImpl(&square{}))
// 打印 false
```



#### 通过Field offset修改struct字段值

```go
	type B_struct struct {
		B_int    int
		B_string string
		B_slice  []string
		B_map    map[int]string
	}
	type A_struct struct {
		A_int   int
		A_float float32
		A_bool  bool
		A_BPtr  *B_struct
		A_Bean  B_struct
	}
	// 在64位机器中，int占8个字节，float64占8个字节，
	//bool占1个字节，指针ptr占8个字节，string的底层是stringheader占用16个字节  
	//slice的底层结构是sliceheader,map底层结构未知，但是占用8个字节  
	//在结构体中会进行字节对齐  
	//比如在bool后面跟一个ptr，bool就会对齐为8个字节
	fmt.Println("total size of A:", reflect.TypeOf(A_struct{}).Size()) 
	fmt.Println("total size of B:", reflect.TypeOf(B_struct{}).Size())
	var type_A = reflect.TypeOf(A_struct{})
	var type_B = reflect.TypeOf(B_struct{})
	var A_bean = A_struct{}
	var start_ptr = uintptr(unsafe.Pointer(&A_bean))
	// 设置A的第一个int型成员变量
	*((*int)(unsafe.Pointer(start_ptr + type_A.Field(0).Offset))) = 100
	fmt.Println("after set int of A: ", A_bean)
	// 设置A的第二个float32成员变量
	*((*float32)(unsafe.Pointer(start_ptr + type_A.Field(1).Offset))) = 55.5
	fmt.Println("after set float32 of A: ", A_bean)
	// 设置A的第三个bool变量
	*((*bool)(unsafe.Pointer(start_ptr + type_A.Field(2).Offset))) = true
	fmt.Println("after set bool of A:", A_bean)
	// 设置A的第四个ptr变量
	var first_B = &B_struct{B_int: 1024, B_string: "hello", B_slice: []string{"lalla", "biubiu"}, B_map: map[int]string{1: "this is a one", 2: "this is a two"}}
	*((**B_struct)(unsafe.Pointer(start_ptr + type_A.Field(3).Offset))) = first_B
	fmt.Println("after set A_BPtr of A:", A_bean, "and A_bean.A_BPtr:", A_bean.A_BPtr)
	// A的第五个变量是一个B_struct结构体变量，所以可以继续通过偏移来设置
	//A的第五个变量中的第一个int变量
	*((*int)(unsafe.Pointer(start_ptr + type_A.Field(4).Offset + type_B.Field(0).Offset))) = 2048
	fmt.Println("after set B_int of A_Bbean of A:", A_bean)
	// A的第五个变量中的第二个string变量
	*((*string)(unsafe.Pointer(start_ptr + type_A.Field(4).Offset + type_B.Field(1).Offset))) = "world"
	fmt.Println("after set B_string of A_Bbean of A:", A_bean)
	// A的第五个变量中的第三个slice变量
	*((*[]string)(unsafe.Pointer(start_ptr + type_A.Field(4).Offset + type_B.Field(2).Offset))) = []string{"hehe", "heihei"}
	fmt.Println("after set B_slice of A_Bbean of A:", A_bean)
	// A的第六个变量中的第三个slice变量
	*((*map[int]string)(unsafe.Pointer(start_ptr + type_A.Field(4).Offset + type_B.Field(3).Offset))) = map[int]string{3: "this is three", 4: "this is four",}
	fmt.Println("after set B_map of A_Bbean of A:", A_bean)
```
#### 创建函数

反射不只是让你创造新的地方来存储数据。您可以使用反射来使用 `reflect.MakeFunc` 函数创建新函数。这个函数需要我们想要创建的函数的 `reflect.Type` 和一个闭包，它的输入参数是 `[]reflect.Value` 类型，其输出参数也是 `[]reflect.Value` 类型。这是一个简单的示例，它为传递给它的任何函数创建一个计时包装器：

```go
func MakeTimedFunction(f interface{}) interface{} {
	rf := reflect.TypeOf(f)
	if rf.Kind() != reflect.Func {
		panic("expects a function")
	}
	vf := reflect.ValueOf(f)
	wrapperF := reflect.MakeFunc(rf, func(in []reflect.Value) []reflect.Value {
		start := time.Now()
		out := vf.Call(in)
		end := time.Now()
		fmt.Printf("calling %s took %v\n", runtime.FuncForPC(vf.Pointer()).Name(), end.Sub(start))
		return out
	})
	return wrapperF.Interface()
}

func timeMe() {
	fmt.Println("starting")
	time.Sleep(1 * time.Second)
	fmt.Println("ending")
}

func timeMeToo(a int) int {
	fmt.Println("starting")
	time.Sleep(time.Duration(a) * time.Second)
	result := a * 2
	fmt.Println("ending")
	return result
}

func main() {
	timed := MakeTimedFunction(timeMe).(func())
	timed()
	timedToo := MakeTimedFunction(timeMeToo).(func(int) int)
	fmt.Println(timedToo(2))
}
```

#### 动态创建struct

在 Go 中使用反射还可以做一件事。您可以在运行时通过将一部分 `reflect.StructField` 实例传递给 `reflect.StructOf` 函数来创建全新的结构。这个有点奇怪；我们正在创建一个新类型，但我们没有它的名称，所以你不能真正把它变成一个“正常”的变量。您可以创建一个新实例并使用`Interface() `将值放入 `interface{}` 类型的变量中，但是如果要在其上设置任何值，则需要使用反射。

```go
func MakeStruct(vals ...interface{}) interface{} {
	var sfs []reflect.StructField
	for k, v := range vals {
		t := reflect.TypeOf(v)
		sf := reflect.StructField{
			Name: fmt.Sprintf("F%d", (k + 1)),
			Type: t,
		}
		sfs = append(sfs, sf)
	}
	st := reflect.StructOf(sfs)
	so := reflect.New(st)
	return so.Interface()
}

func main() {
	s := MakeStruct(0, "", []int{})
	// this returned a pointer to a struct with 3 fields:
	// an int, a string, and a slice of ints
	// but you can’t actually use any of these fields
	// directly in the code; you have to reflect them
	sr := reflect.ValueOf(s)

	// getting and setting the int field
	fmt.Println(sr.Elem().Field(0).Interface())
	sr.Elem().Field(0).SetInt(20)
	fmt.Println(sr.Elem().Field(0).Interface())

	// getting and setting the string field
	fmt.Println(sr.Elem().Field(1).Interface())
	sr.Elem().Field(1).SetString("reflect me")
	fmt.Println(sr.Elem().Field(1).Interface())

	// getting and setting the []int field
	fmt.Println(sr.Elem().Field(2).Interface())
	v := []int{1, 2, 3}
	rv := reflect.ValueOf(v)
	sr.Elem().Field(2).Set(rv)
	fmt.Println(sr.Elem().Field(2).Interface())
}
```

### 进阶应用
#### 动态创建通道

发送通道

```go
var k = reflect.TypeOf(0)
fmt.Println(reflect.ChanOf(reflect.SendDir, k))
// 输出 chan<- int
```
接收通道
```go
ta := reflect.ArrayOf(5, reflect.TypeOf(123))
tc := reflect.ChanOf(reflect.RecvDir, ta)
fmt.Println(tc)
// 输出 <-chan [5]int
```

#### 动态创建通道SelectCase

摘自极客时间专栏《Go语言并发编程实战》的一段代码：

```go

func main() {
    var ch1 = make(chan int, 10)
    var ch2 = make(chan int, 10)

    // 创建SelectCase
    var cases = createCases(ch1, ch2)

    // 执行10次select
    for i := 0; i < 10; i++ {
        chosen, recv, ok := reflect.Select(cases)
        if recv.IsValid() { // recv case
            fmt.Println("recv:", cases[chosen].Dir, recv, ok)
        } else { // send case
            fmt.Println("send:", cases[chosen].Dir, ok)
        }
    }
}

func createCases(chs ...chan int) []reflect.SelectCase {
    var cases []reflect.SelectCase


    // 创建recv case
    for _, ch := range chs {
        cases = append(cases, reflect.SelectCase{
            Dir:  reflect.SelectRecv,
            Chan: reflect.ValueOf(ch),
        })
    }

    // 创建send case
    for i, ch := range chs {
        v := reflect.ValueOf(i)
        cases = append(cases, reflect.SelectCase{
            Dir:  reflect.SelectSend,
            Chan: reflect.ValueOf(ch),
            Send: v,
        })
    }

    return cases
}
```

## 参考文档

+ [Reflections in Go](https://go101.org/article/reflection.html)
+ [Go语言反射的实现原理](https://draveness.me/golang/docs/part2-foundation/ch04-basic/golang-reflect/)