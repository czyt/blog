---
title: "golang正则校验支付宝微信支付授权码"
date: 2022-06-17
tags: ["golang", "regexp"]
draft: false
---

参考sdk定义
```go
package main

import (
	"fmt"
	"regexp"
)

// wechat pay  用户付款码条形码规则：18位纯数字，以10、11、12、13、14、15开头
// alipay  支付授权码，25~30开头的长度为16~24位的数字，实际字符串长度以开发者获取的付款码长度为准

func main() {
	// wechat
	regwechat:=regexp.MustCompile("^(1[0-5])\\d{16}$")
	matchwechat := regwechat.MatchString("154658833119096245")
	fmt.Println(matchwechat)
	// alipay
	regalipay:=regexp.MustCompile("^(2[5-9]|30)\\d{14,22}$")
	matchalipay := regalipay.MatchString("307573774583867517336")
	fmt.Println(matchalipay)
}
```
参考

- [微信](https://pay.weixin.qq.com/wiki/doc/api/micropay_sl.php?chapter=5_1)

- [支付宝](https://docs.open.alipay.com/api_1/alipay.trade.pay)