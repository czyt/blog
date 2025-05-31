---
title: "TIL：Bash 脚本中的超时【译】"
date: 2025-05-30T08:55:18+08:00
draft: false
tags: ["bash","trick"]
author: "czyt"
---

> 原文链接 https://heitorpb.github.io/bla/timeout/

前几天在工作中，我们有一个 Bash 脚本，用于设置一个 Web 服务器，并等待它启动后再继续执行后续操作。这个脚本运行正常，我们也没有遇到任何问题，直到出现了一个无限循环。

我们使用 Bash 内置的 `until` 来检查 Web 服务器是否正常：

```bash
until curl --silent --fail-with-body 10.0.0.1:8080/health; do
	sleep 1
done
```

这很好用。除非我们的 Web 服务器在启动过程中崩溃，并且我们 `sleep 1` 永远等待。

这里有一个实用的工具：`timeout`。顾名思义，这个命令可以为其他命令添加超时功能。您指定想要等待命令的时间限制，如果该时间已过，`timeout` 会发送一个信号来终止它，并以非零状态退出。默认情况下，`timeout` 发送的是 `SIGTERM` 信号，但您可以通过 `--signal` 标志来更改它，例如 `timeout --signal=SIGKILL 1s foo` 。

例如，`timeout 1s sleep 5` 将向 `sleep` 发送 `SIGTERM` 信号 1秒后：

```bash
$ time timeout 1s sleep 4

real    0m1,004s
user    0m0,000s
sys     0m0,005s

$ echo $?
124
```

那么接下来应该将 `timeout` 和 `until` 结合起来：

```bash
timeout 1m until curl --silent --fail-with-body 10.0.0.1:8080/health; do
	sleep 1
done
```

唯一的问题是这行不通。``timeout`` 需要一个可终止的命令，而 ``until`` 是一个 shell 关键字：你不能 ``SIGTERM``until``。我们无法使用 `timeout` 与任何 shell 内建命令一起使用。

前进的方向是将那个 `until` 包裹在一个 Bash 进程中：

```bash
timeout 1m bash -c "until curl --silent --fail-with-body 10.0.0.1:8080/health; do
	sleep 1
done"
```

另一种方法是将要移动到单独的 Bash 脚本中的 `until`，并使用 `timeout` it:

```bash
timeout 1m ./until.sh
```

很遗憾我们无法直接使用 `timeout` 与 `until` 结合，那将非常方便。但将其包装在 Bash 进程/脚本中即可完成任务。