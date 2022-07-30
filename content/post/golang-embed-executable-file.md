---
title: "Golang嵌入可执行程序"
date: 2022-02-23
tags: ["golang", "linux", "embed"]
draft: false
---

>  reddit链接
>  On Linux it might be possible to use the memfd_create system call, but that's not portable to other operating systems.
>
>  need go 1.16 +

```go 
package main

import (
	_ "embed"
	"log"
	"os"
	"os/exec"
	"strconv"

	"golang.org/x/sys/unix"
)

//go:embed binary
var embeddedBinary []byte

func main() {
	fd, err := unix.MemfdCreate("embedded_binary", 0)
	if err != nil {
		log.Fatal(err)
	}

	path := "/proc/" + strconv.Itoa(os.Getpid()) + "/fd/" + strconv.Itoa(int(fd))
	err = os.WriteFile(path, embeddedBinary, 0755)
	if err != nil {
		log.Fatal(err)
	}
	
	cmd := exec.Command(path)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	err = cmd.Run()
	if err != nil {
		log.Fatal(err)
	}
}
```
> You should be able to replace that os.WriteFile  with  f := os.NewFile(fd, "memfd"); _, err := f.Write(embeddedBinary)  for a simpler end result.
>
> You should be able to replace the /proc  path with execveat(2)  and AT_EMPTY_PATH 

一个可用的简短函数 来源[链接](https://www.guitmz.com/running-elf-from-memory/)

```go
const (
	mfdCloexec  = 0x0001
	memfdCreate = 319
)

func runFromMemory(displayName string, binaryBytes []byte) {
	fdName := "" // *string cannot be initialized
	fd, _, _ := syscall.Syscall(memfdCreate, uintptr(unsafe.Pointer(&fdName)), uintptr(mfdCloexec), 0)
	_, _ = syscall.Write(int(fd), binaryBytes)

	fdPath := fmt.Sprintf("/proc/self/fd/%d", fd)
	_ = syscall.Exec(fdPath, []string{displayName}, nil)
}
```

