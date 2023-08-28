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

## 好用的库

+ https://github.com/Shopify/gomail （[源仓库](https://github.com/go-gomail/gomail) 作者已经离开人世 这个是fork继续维护的版本）
+ https://github.com/wneessen/go-mail
+ https://github.com/inbucket/inbucket