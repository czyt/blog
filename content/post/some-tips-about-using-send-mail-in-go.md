---
title: "使用go发送邮件的注意事项"
date: 2023-08-25
tags: ["golang", "email",  "tricks"]
draft: false
---

## 服务器设置

### SPF设置

如果你使用的是企业邮箱，可能需要添加SPF记录。SPF（Sender Policy Framework） 是电子邮件系统中发送方策略框架的缩写，它的内容写在DNS的txt类型的记录里面；作用是防止别人伪造你的邮件地址进行发信，是一种非常高效的反垃圾邮件解决方案。**如果你的服务器没有设置邮件的SPF，那么在发送邮件到Gmail等邮箱地址时，会发生退信**。

一般给域名添加SPF记录的方式是添加一条TXT记录。以腾讯企业邮箱为例，添加的TXT记录值是`v=spf1 include:spf.mail.qq.com -all`

使用go可以实现查询域名的TXT信息。

```go
func TestNetLookupTxt(t *testing.T) {
	txt, err := net.LookupTXT("czyt.tech")
	if err != nil {
		t.Fatal(err)
	}
	t.Log(txt)
}
```
### DKIM

[腾讯企业邮箱 DKIM配置说明](https://open.work.weixin.qq.com/help2/pc/19647?person_id=1)

### DMARC

 DMARC（Domain-based Message Authentication, Reporting & Conformance）是一种基于现有的SPF和DKIM协议的可扩展电子邮件认证协议，邮件收发双方建立了邮件反馈机制，便于邮件发送方和邮件接收方共同对域名的管理进行完善和监督。对于未通过前述检查的邮件，接收方则按照发送方指定的策略进行处理，如直接投入垃圾箱或拒收。从而有效识别并拦截欺诈邮件和钓鱼邮件，保障用户个人信息安全。这里同样以腾讯企业邮箱为例。在DNS管理的地方添加以下DMARC记录：

主机记录：` _dmarc`

记录类型：`TXT`

记录值: `v=DMARC1; p=none; rua=mailto:mailauth-reports@qq.com`

> 注意：DMARC记录里，有一个值可由你来自定义：
> p：用于告知收件方，当检测到某封邮件存在伪造发件人的情况，收件方要做出什么处理；
>
> p=none; 为收件方不作任何处理
>
> p=quarantine; 为收件方将邮件标记为垃圾邮件
>
> p=reject; 为收件方拒绝该邮件
>
> rua：用于在收件方检测后，将一段时间的汇总报告，发送到哪个邮箱地址。
>
> ruf：用于当检测到伪造邮件时，收件方须将该伪造信息的报告发送到哪个邮箱地址。`ruf=mailto:xxx@xxxxxx.com;`
>
> DMARC是基于DKIM和SPF的，所以开启DMARC必须先开启DKIM或SPF任意一种

## 消息体

### Message-Id

对于Gmail等邮箱，如果你在发送邮箱的时候没有带上`Message-Id`也会触发退信。这时需要你在邮件发送的Header中添加`Message-Id`.例如`<4867a3d78a50438bad95c0f6d072fca5@mailbox01.contoso.com>`。可以参考[微软的相关文档](https://learn.microsoft.com/zh-cn/exchange/mail-flow/transport-logs/message-tracking?view=exchserver-2019)

### 邮件模板

对于常见的邮件模板，可以使用[Hermes](https://github.com/matcornic/hermes)这个Golang库。下面是一个例子：

```go
package main

import (
	"github.com/matcornic/hermes/v2"
)

type inviteCode struct {
}

func (w *inviteCode) Name() string {
	return "invite_code"
}

func (w *inviteCode) Email() hermes.Email {
	return hermes.Email{
		Body: hermes.Body{
			Name: "Jon Snow",
			Intros: []string{
				"Welcome to Hermes! We're very excited to have you on board.",
			},
			Actions: []hermes.Action{
				{
					Instructions: "Please copy your invite code:",
					InviteCode: "123456",
				},
			},
			Outros: []string{
				"Need help, or have questions? Just reply to this email, we'd love to help.",
			},
		},
	}
}
```

## 参考资料

+ https://taoshu.in/net/email-dns.html

## 好用的库

+ https://github.com/Shopify/gomail （[源仓库](https://github.com/go-gomail/gomail) 作者已经离开人世 这个是fork继续维护的版本）

> 这个库有个问题就是如果批量发送邮件的时候，接收人的邮箱有一个不存在，就会导致发送失败，如果有批量发送的逻辑，建议使用`Rcpt`指令进行对收件人邮箱进行检测。参考代码：
>
> ```go
> package main
> 
> import (
> 	"fmt"
> 	"net"
> 	"net/mail"
> 	"net/smtp"
> 	"strings"
> 	"time"
> )
> 
> func VerifyEmailSMTP(email string) (bool, error) {
> 	addr, err := mail.ParseAddress(email)
> 	if err != nil {
> 		return false, fmt.Errorf("无效的邮箱地址格式: %w", err)
> 	}
> 	domain := strings.SplitN(addr.Address, "@", 2)[1]
> 
> 	mx, err := net.LookupMX(domain)
> 	if err != nil {
> 		return false, fmt.Errorf("找不到邮箱域名 %s 的 MX 记录: %w", domain, err)
> 	}
> 
> 	client, err := smtp.Dial(fmt.Sprintf("%s:%d", mx[0].Host, 25)) // 默认 SMTP 端口 25
> 	if err != nil {
> 		return false, fmt.Errorf("连接到 SMTP 服务器失败: %w", err)
> 	}
> 	defer client.Close()
> 
> 	// 设置超时 (可选，防止长时间等待)
> 	client.Timeout = 5 * time.Second
> 
> 	err = client.Hello("example.com") // 发送 HELO/EHLO 命令 (你的域名或任意域名)
> 	if err != nil {
> 		return false, fmt.Errorf("SMTP HELO 失败: %w", err)
> 	}
> 
> 	err = client.Mail("test@example.com") // 发送 MAIL FROM 命令 (任意发件人地址)
> 	if err != nil {
> 		return false, fmt.Errorf("SMTP MAIL FROM 失败: %w", err)
> 	}
> 
> 	err = client.Rcpt(email) // 发送 RCPT TO 命令 (目标邮箱地址)
> 	if err != nil {
> 		if strings.Contains(err.Error(), "550") || strings.Contains(err.Error(), "551") || strings.Contains(err.Error(), "501") || strings.Contains(err.Error(), "500") {
> 			// 常见的邮箱不存在或无效错误代码 (可能需要根据实际情况调整判断)
> 			return false, nil // 邮箱可能不存在
> 		}
> 		return false, fmt.Errorf("SMTP RCPT TO 失败: %w", err) // 其他错误，可能是服务器问题或其他原因
> 	}
> 
> 	// 如果 RCPT TO 没有返回错误，可能表示邮箱存在 (但不能完全保证)
> 	return true, nil
> }
> 
> func main() {
> 	emails := []string{
> 		"test@gmail.com",       // 可能是存在的邮箱
> 		"nonexistent@gmail.com", // 可能是不存在的邮箱
> 		"invalid-format",      // 无效格式
> 		"test@example.invalid", // 域名无效
> 	}
> 
> 	for _, email := range emails {
> 		exists, err := VerifyEmailSMTP(email)
> 		if err != nil {
> 			fmt.Printf("校验邮箱 %s 出错: %v\n", email, err)
> 		} else {
> 			fmt.Printf("邮箱 %s 是否可能存在: %t\n", email, exists)
> 		}
> 	}
> }
> 
> ```
>
> 下面的这个go-mail的库已经支持自动检测，发送邮件是部分失败。

+ https://github.com/wneessen/go-mail
+ https://github.com/inbucket/inbucket



> 可以在 Google Postmaster Tools 认证一下你的域名 .主要有以下作用
>
> 1. 检查邮箱配置的正确性.
> 2. 查询 Gmail 的邮件有多少被当作了 Spam
>
> 地址: https://postmaster.google.com/managedomains?pli=1