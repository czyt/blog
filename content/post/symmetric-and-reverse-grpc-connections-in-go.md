---
title: "对称和反向gRPC连接【译】"
date: 2024-12-10
draft: true
tags: ["golang","gRPC"]
categories: []
author: "czyt"
description: ""
featured_image: ""
---

>原文链接为 https://tilde.town/~hut8/post/grpc-connections/ 使用kimi进行翻译

**背景**

gRPC是一项出色的现代技术，用于远程过程调用。它允许你在客户端创建一个“存根”对象，该对象的目的是调用服务器上的方法。它是许多情况下REST或GraphQL的绝佳替代品，通常值得学习这项技术。更多信息可以在官方文档中找到。

**网络**

概念上，我们对客户端和服务器有两种不同的想法。

+ TCP服务器和客户端 - gRPC在HTTP/2之上运行，HTTP/2在TCP之上运行，所以我将讨论TCP中“服务器”和“客户端”的含义。在TCP连接中，客户端是连接的发起者，服务器是连接的接收者。然而，一旦建立了连接，连接就是对称的；客户端和服务器都可以发送和接收消息，直到一方通过shutdown(2)关闭，或通过close(2)关闭连接。

+ gRPC服务器和客户端 - gRPC客户端通过存根调用在服务器上运行的方法。这不是对称的。服务器不能在客户端上调用方法。

**服务器/客户端类型耦合问题**

如果你有一个gRPC客户端，它也是TCP客户端（它调用connect(2)）。如果你有一个gRPC服务器，它也是TCP服务器（它调用listen(2)和accept(2)）。

因此，如果你想让两台机器可以相互调用gRPC，那么每台机器都是客户端和服务器（在TCP和gRPC两种意义上），现在你有了两个与彼此无关的TCP连接。在有两朵云实例的场景中，这种架构通常并不复杂。但TCP通常很混乱。防火墙、NAT和动态分配的IP地址可能会使客户端到服务器的单向连接变得复杂。

这里有一个这样的情况的例子：假设你的“服务器”是一个在家庭路由器后面的笔记本电脑上运行的程序，它必须接收命令（例如，远程控制）来自“客户端”（例如，云计算实例）。根据gRPC，客户端必须是云计算实例（这很容易被称为“服务器”），因为那是创建远程过程调用的一方。服务器是笔记本电脑，因为那是实际发生过程调用的地方。

当你在客户端（即云计算实例）上创建一个“存根”时，你必须创建一个TCP连接并连接到服务器（即笔记本电脑）。现在你遇到了几个可能的问题：

你不知道笔记本电脑的IP地址，所以你现在需要一个反向服务，让笔记本电脑告诉云它的IP地址。
笔记本电脑可能在NAT后面，所以一旦你找到了IP地址，笔记本电脑将不得不配置端口转发。这在企业环境中很可能是不可能的。
笔记本电脑可能在防火墙后面，这将禁止传入连接。这可能是本地机器上的，也可能是在网关路由器上的。

这些问题中的一些可能是无法解决的，所以我们需要另一种方法。

**gRPC独有的解决方案**

服务器不能在客户端gRPC上调用方法。也许你可以让客户端在服务器上调用一个方法，其唯一目的是接收描述服务器希望客户端运行的方法的消息。这可以通过流式响应来完成。但这很复杂，需要大量的代码来绕过gRPC的设计。我在其他地方看到过这个建议，但我认为这是一个丑陋的临时解决方案，它制造的问题比它解决的还要多。考虑一下，你将如何在静态类型的方式中实际调用这些“客户端方法”。

**基于隧道的解决方案**

将TCP客户端/服务器从gRPC客户端/服务器中解耦的一个好方法是实现某种隧道。在上面的例子中，笔记本电脑可以向云计算实例发起一个TCP连接，然后通过实现特定于语言的接口，“拨号”操作让云计算实例（gRPC客户端）连接到笔记本电脑（gRPC服务器）可以简单地使用现有的TCP连接。

SSH是一个不可思议的协议，它的用途比大多数用户知道的还要多。在我们的情况下，它是将我们的TCP连接从gRPC连接中解耦的完美方式。它还有其他好处：尽管gRPC提供认证和加密，但如果更方便，你可以使用SSH提供的。

这些例子是Go语言特有的，但你可以在任何语言中做类似的事情。gRPC服务器不需要监听端口；你可以传入任何实现了Go的`net.Listener`的类型。所以我们可以做一个`net.Listener`，它将接受SSH连接，任何时候请求我们的自定义类型的新SSH通道，我们将接受它并返回一个新的net.Conn，这是我们将实现的另一个类型，它只是通过我们的隧道传输数据。

让我们从SSHDataTunnel开始，它是我们的`net.Conn`。

```go
import (
    "net"
    "time"
    "golang.org/x/crypto/ssh"
)

// SSHDataTunnel实现了net.Conn
type SSHDataTunnel struct {
    Chan ssh.Channel
    Conn net.Conn
}

func NewSSHDataTunnel(sshChan ssh.Channel, carrier net.Conn) *SSHDataTunnel {
    return &SSHDataTunnel{
        Chan: sshChan,
        Conn: carrier,
    }
}

func (c *SSHDataTunnel) Read(b []byte) (n int, err error) {
    return c.Chan.Read(b)
}

func (c *SSHDataTunnel) Write(b []byte) (n int, err error) {
    return c.Chan.Write(b)
}

func (c *SSHDataTunnel) Close() error {
    return c.Chan.Close()
}

func (c *SSHDataTunnel) LocalAddr() net.Addr {
    return c.Conn.LocalAddr()
}

func (c *SSHDataTunnel) RemoteAddr() net.Addr {
    return c.Conn.RemoteAddr()
}

func (c *SSHDataTunnel) SetDeadline(t time.Time) error {
    return c.Conn.SetDeadline(t)
}

func (c *SSHDataTunnel) SetReadDeadline(t time.Time) error {
    return c.Conn.SetReadDeadline(t)
}

func (c *SSHDataTunnel) SetWriteDeadline(t time.Time) error {
    return c.Conn.SetWriteDeadline(t)
}

// 静态检查类型
var _ net.Conn = &SSHDataTunnel{}
```

最后一行只是确保我们的类型实际上实现了`net.Conn`，如果它没有，它将无法编译。

现在，当我们读取和写入我们的新`*SSHDataTunnel`时，数据直接通过SSH连接上的专用通道发送。

`SSHChannelListener`是我们的`net.Listener`类型，它产生了我们的`SSHDataTunnel`。

```go
type SSHChannelListener struct {
    // 通道请求本质上与传入的TCP连接相同
    Chans   <-chan ssh.NewChannel
    SSHConn ssh.Conn
    TCPConn *net.TCPConn
}

// Accept等待并返回监听器的下一个连接。
func (l *SSHChannelListener) Accept() (net.Conn, error) {
    chanRq := <-l.Chans
    if chanRq == nil {
        return nil, net.ErrClosed
    }
    if chanRq.ChannelType() != "grpc-tunnel" {
        chanRq.Reject(ssh.UnknownChannelType, "unknown channel type")
        return nil, errors.New("could not accept on ssh channel listener: unknown channel type")
    }
    channel, reqs, err := chanRq.Accept()
    if err != nil {
        return nil, err
    }
    go ssh.DiscardRequests(reqs)
    return &SSHDataTunnel{
        Chan: channel,
        Conn: l.TCPConn,
    }, nil
}

// Close关闭监听器。
// 任何阻塞的Accept操作将被取消阻塞并返回错误。
func (l *SSHChannelListener) Close() error {
    return l.SSHConn.Close()
}

// Addr返回监听器的网络地址。
func (l *SSHChannelListener) Addr() net.Addr {
    return l.SSHConn.LocalAddr()
}
```

现在我们有了用SSH代替`net.Listener`和`net.Conn`的适配器，这是gRPC所需要的。我们仍然需要设置到云计算实例的SSH连接本身，以便构建`SSHChannelListener`。这将在TCP客户端上完成，即gRPC服务器（“笔记本电脑”）。

```go
// Connect从TCP客户端（即gRPC服务器）到TCP服务器发起一个出站隧道连接
func Connect() (*SSHChannelListener, error) {
    // 解析并建立TCP连接
    addr, err := net.ResolveTCPAddr("tcp4", ServerAddress)
    if err != nil {
        // 真正的错误处理在这里
        return nil, err
    }
    conn, err := net.DialTCP("tcp", nil, addr)
    if err != nil {
        // 真正的错误处理在这里
        return nil, err
    }

    // 使用我们的TCP连接，建立一个SSH连接
    sshConn, chans, requests, err := ssh.NewClientConn(conn, ServerAddress, c.ClientConfig)
    if err != nil {
        // 真正的错误处理在这里
        return nil, err
    }
    // 忽略所有请求（这不包括新通道）
    go ssh.DiscardRequests(reqs)

    return &SSHChannelListener{
        Chans:   chans,
        SSHConn: sshConn,
        TCPConn: conn,
    }, nil
}
```

使用SSHChannelListener在笔记本电脑上使用gRPC很容易。假设你在协议包中有一个名为XServer的服务：

```go
listener, err := Connect()
if err != nil {
    // 真正的错误处理在这里
    panic(err)
}

s := grpc.NewServer()
protocol.RegisterXServer(s, &xServer{})
s.Serve(listener)
```

在云计算实例上（TCP服务器/gRPC客户端），我们也可以很容易地连接gRPC。首先，我们将定义一个满足`grpc.WithContextDialer`的函数：

```go
func (c *Client) SSHConnDialer(context.Context, string) (net.Conn, error) {
    sshChan, reqs, err := c.sshConn.OpenChannel("grpc-tunnel", nil)
    if err != nil {
        return nil, err
    }
    go ssh.DiscardRequests(reqs)
    conn := &SSHConn{
        Chan: sshChan,
        Conn: nConn,
    }
    return conn, nil
}
```

现在我们将在云计算实例上使用该拨号器构建gRPC客户端：

```go
grpcConn, err := grpc.Dial(ServerAddress,
    grpc.WithContextDialer(sshConnDialer),
    grpc.WithBlock(),
    grpc.WithTransportCredentials(insecure.NewCredentials()))
if err != nil {
    // 真正的错误处理在这里
    panic(err)
}
defer grpcConn.Close()

svc := protocol.NewXClient(grpcConn)

// 现在你可以像使用普通客户端一样使用svc：

svc.Frobulate()
```

**处理断开连接**

检测和处理gRPC的断开连接可能有点棘手，所以我将在这里概述一种方法。与其在客户端调用方法并得到一个错误（这当然是检测断开连接的一种方式），我们可以使用`grpc.Handler`在检测到断开连接时提供某种通知。使用`chan`使得这变得非常容易。云计算实例（TCP服务器/gRPC客户端）将需要一些额外的代码。

```go
type DisconnectDetector struct {
    // 如果需要，还可以添加一个日志记录器
    CloseChan chan struct{}
}

// NewDisconnectDetector返回一个有效的DisconnectDetector
func NewDisconnectDetector() *DisconnectDetector {
    return &DisconnectDetector{
        CloseChan: make(chan struct{}),
    }
}

// TagRPC是一个无操作函数
func (h *DisconnectDetector) TagRPC(context.Context, *stats.RPCTagInfo) context.Context {
    return context.Background()
}

// HandleRPC是一个无操作函数
func (h *DisconnectDetector) HandleRPC(context.Context, stats.RPCStats) {}

// TagConn是一个无操作函数
func (h *DisconnectDetector) TagConn(context.Context, *stats.ConnTagInfo) context.Context {
    return context.Background()
}

// HandleConn处理Conn统计数据。
func (h *DisconnectDetector) HandleConn(c context.Context, s stats.ConnStats) {
    switch s.(type) {
    case *stats.ConnEnd:
        h.CloseChan <- struct{}{}
    }
}
```

在上面的grpc.Dial调用中，我们可以添加另一个参数：

```go
disconnectDetector := NewDisconnectDetector()

grpc.Dial( // 和之前一样，再加上：
    grpc.WithStatsHandler(disconnectDetector))
```

现在，每当你想要在断开连接时得到通知（在单独的goroutine中），只需使用：

```go
<- disconnectDetector.CloseChan

// ... 断开连接时运行的代码
```
