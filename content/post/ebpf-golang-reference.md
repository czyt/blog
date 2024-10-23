---
title: "ebpf Golang参考"
date: 2022-06-11
tags: ["golang", "ebpf"]
draft: false
---

整理一个列表，持续更新。

## 理论

+ [ebf官网](https://ebpf.io)
+ B站视频   eBPF 和 Go，超能力组合
  {{< bilibili BV14v4y1w7NK >}}  

## 实践

+ Tracing Go Functions with eBPF [part1](https://www.grant.pizza/blog/tracing-go-functions-with-ebpf-part-1/) [part2](https://www.grant.pizza/blog/tracing-go-functions-with-ebpf-part-2/)
+ [Getting Started with eBPF and Go](https://networkop.co.uk/post/2021-03-ebpf-intro/)
+ [Linux中基于eBPF的恶意利用与检测机制](https://www.cnxct.com/evil-use-ebpf-and-how-to-detect-ebpf-rootkit-in-linux/)
+ [如何用eBPF分析Golang应用](https://blog.huoding.com/2021/12/12/970)
+ [使用BPF, 将Go网络程序的吞吐提升8倍](https://colobu.com/2022/06/05/use-bpf-to-make-the-go-network-program-8x-faster/)
+ [使用ebpf跟踪rpcx微服务](https://colobu.com/2022/05/22/use-ebpf-to-trace-rpcx-microservices/)
- [BPF MAP机制](https://www.kernel.org/doc/html/latest/bpf/maps.html)
- [一种通用数据结构，可以存储不同类型数据的通用数据结构](https://man7.org/linux/man-pages/man2/bpf.2.html)
- [Andrii Nakryiko](https://nakryiko.com/posts/libbpf-bootstrap/#bpf-maps)
- [抽象数据容器(abstract data container)](https://nakryiko.com/posts/libbpf-bootstrap/#bpf-maps)
- [bpf系统调用的说明](https://man7.org/linux/man-pages/man2/bpf.2.html)
- [《使用C语言从头开发一个Hello World级别的eBPF程序》](https://tonybai.com/2022/07/05/develop-hello-world-ebpf-program-in-c-from-scratch)
- [《Linux Observability with BPF》](https://book.douban.com/subject/33398015/)
- [《揭秘BPF map前生今世》](https://www.ebpf.top/post/map_internal/)
- [bpf系统调用说明](https://man7.org/linux/man-pages/man2/bpf.2.html)
- [官方bpf map参考手册](https://www.kernel.org/doc/html/latest/bpf/maps.html)
- [bpftool参考手册](https://www.mankier.com/8/bpftool)
- [《Building BPF applications with libbpf-bootstrap》](https://nakryiko.com/posts/libbpf-bootstrap/#bpf-maps)
- https://github.com/DavadDi/bpf_study
- https://github.com/mikeroyal/eBPF-Guide#go-development

## golang 包及项目
+ https://github.com/cilium/ebpf
+ https://github.com/danger-dream/ebpf-firewall