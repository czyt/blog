---
title: "如何为七牛已绑定域名的bucket获取Let's Encrypt证书"
date: 2023-08-02
tags: ["qiniu", "golang","ssl"]
draft: false
---

## 关于Let's Encrypt证书
官网的说明是
>一个为 **2.25 亿个**网站提供 TLS 证书的非盈利性证书颁发机构。
>

 官网 ： https://letsencrypt.org/zh-cn/

## 获取证书的验证方式

目前有很多自动工具可以获取，需要有相关的域名或者服务器权限。认证的方式有三种，这里引用下官网的说明。[验证方式](https://letsencrypt.org/zh-cn/docs/challenge-types/)

>当您从 Let’s Encrypt 获得证书时，我们的服务器会验证您是否使用 ACME 标准定义的验证方式来验证您对证书中域名的控制权。 大多数情况下，验证由 ACME 客户端自动处理，但如果您需要做出一些更复杂的配置决策，那么了解更多有关它们的信息会很有用。 如果您不确定怎么做，请使用您的客户端的默认设置或使用 HTTP-01。
>
>+ HTTP-01 验证
>  这是当今最常见的验证方式。 Let’s Encrypt 向您的 ACME 客户端提供一个令牌，然后您的 ACME 客户端将在您对 Web 服务器的 http://<你的域名>/.well-known/acme-challenge/<TOKEN>（用提供的令牌替换 <TOKEN>）路径上放置指定文件。 该文件包含令牌以及帐户密钥的指纹。 一旦您的 ACME 客户端告诉 Let’s Encrypt 文件已准备就绪，Let’s Encrypt 会尝试获取它（可能从多个地点进行多次尝试）。 如果我们的验证机制在您的 Web 服务器上找到了放置于正确地点的正确文件，则该验证被视为成功，您可以继续申请颁发证书。 如果验证检查失败，您将不得不再次使用新证书重新申请。
>
>我们的 HTTP-01 验证最多接受 10 次重定向。 我们只接受目标为“http:”或“https:”且端口为 80 或 443 的重定向。 我们不目标为 IP 地址的重定向。 当被重定向到 HTTPS 链接时，我们不会验证证书是否有效（因为验证的目的是申请有效证书，所以它可能会遇到自签名或过期的证书）。
>
>HTTP-01 验证只能使用 80 端口。 因为允许客户端指定任意端口会降低安全性，所以 ACME 标准已禁止此行为。
>
>优点：
>
>它可以轻松地自动化进行而不需要关于域名配置的额外知识。
>它允许托管服务提供商为通过 CNAME 指向它们的域名颁发证书。
>它适用于现成的 Web 服务器。
>缺点：
>
>如果您的 ISP 封锁了 80 端口，该验证将无法正常工作（这种情况很少见，但一些住宅 ISP 会这么做）。
>Let’s Encrypt 不允许您使用此验证方式来颁发通配符证书。
>您如果有多个 Web 服务器，则必须确保该文件在所有这些服务器上都可用。
>
>+ DNS-01 验证
>  此验证方式要求您在该域名下的 TXT 记录中放置特定值来证明您控制域名的 DNS 系统。 该配置比 HTTP-01 略困难，但可以在某些 HTTP-01 不可用的情况下工作。 它还允许您颁发通配符证书。 在 Let’s Encrypt 为您的 ACME 客户端提供令牌后，您的客户端将创建从该令牌和您的帐户密钥派生的 TXT 记录，并将该记录放在 _acme-challenge.<YOUR_DOMAIN> 下。 然后 Let’s Encrypt 将向 DNS 系统查询该记录。 如果找到匹配项，您就可以继续颁发证书！
>
>由于颁发和续期的自动化非常重要，只有当您的 DNS 提供商拥有可用于自动更新的 API 时，使用 DNS-01 验证方式才有意义。 我们的社区在此处提供了此类 DNS 提供商的列表。 您的 DNS 提供商可能与您的域名注册商（您从中购买域名的公司）相同或不同。 如果您想更改 DNS 提供商，只需在注册商处进行一些小的更改， 无需等待域名即将到期。
>
>请注意，将完整的 DNS API 凭据放在 Web 服务器上会显着增加该服务器被黑客攻击造成的影响。 最佳做法是使用权限范围受限的 API 凭据，或在单独的服务器上执行 DNS 验证并自动将证书复制到 Web 服务器上。
>
>由于 Let’s Encrypt 在查找用于 DNS-01 验证的 TXT 记录时遵循 DNS 标准，因此您可以使用 CNAME 记录或 NS 记录将验证工作委派给其他 DNS 区域。 这可以用于将 _acme-challenge 子域名委派给验证专用的服务器或区域。 如果您的 DNS 提供商更新速度很慢，那么您也可以使用此方法把验证工作委派给更新速度更快的服务器。
>
>大多数 DNS 提供商都有一个“更新时间”，它反映了从更新 DNS 记录到其在所有服务器上都可用所需的时间。 这个时间可能很难测量，因为这些提供商通常也使用任播，这意味着多个服务器可以拥有相同的 IP 地址，并且根据您在世界上的位置，您和 Let’s Encrypt 可能会与不同的服务器通信（并获得不同的应答）。 最好的情况是 DNS API 为您提供了自动检查更新是否完成的方法。 如果您的 DNS 提供商没有这样的方法，您只需将客户端配置为等待足够长的时间（通常多达一个小时），以确保在触发验证之前更新已经完全完成。
>
>您可以为同一名称提供多个 TXT 记录。 例如，如果您同时验证通配符和非通配符证书，那么这种情况可能会发生。 但是，您应该确保清理旧的 TXT 记录，因为如果响应大小太大，Let’s Encrypt 将拒绝该记录。
>
>优点：
>
>您可以使用此验证方式来颁发包含通配符域名的证书。
>即使您有多个 Web 服务器，它也能正常工作。
>缺点：
>
>在 Web 服务器上保留 API 凭据存在风险。
>您的 DNS 提供商可能不提供 API。
>您的 DNS API 可能无法提供有关更新时间的信息。
>TLS-SNI-01验证
>ACME 的草案版本中定义了这一验证方式。 它在 443 端口上进行 TLS 握手，并发送了一个特定的 [SNI] 标头以获取包含令牌的证书。 由于安全原因，该验证已于 2019 年 3 月禁用。
>
>+ TLS-ALPN-01验证
>  这一验证类型是在 TLS-SNI-01 被弃用后开发的，并且已经开发为单独的标准。 与 TLS-SNI-01 一样，它通过 443 端口上的 TLS 执行。 但是，它使用自定义的 ALPN 协议来确保只有知道此验证类型的服务器才会响应验证请求。 这还允许对此质询类型的验证请求使用与要验证的域名匹配的SNI字段，从而使其更安全。
>
>这一验证类型并不适合大多数人。 它最适合那些想要执行类似于 HTTP-01 的基于主机的验证，但希望它完全在 TLS 层进行以分离关注点的 TLS 反向代理的作者。 现在其主要使用者为大型托管服务提供商，但 Apache 和 Nginx 等主流 Web 服务器有朝一日可能会实现对其的支持（Caddy已经支持了这一验证类型）。
>
>优点：
>
>它在 80 端口不可用时仍可以正常工作。
>它可以完全仅在 TLS 层执行。
>缺点：
>
>它不支持 Apache、Nginx 和 Certbot，且很可能短期内不会兼容这些软件。
>与 HTTP-01 一样，如果您有多台服务器，则它们需要使用相同的内容进行应答。
>此方法不能用于验证通配符域名。
>
>

## 七牛的证书申请

​    目前七牛支持两种证书设置方式。自行购买和上传。自行购买需要购买七牛提供的证书，目前只有一个一年的免费。后面不清楚什么时候就要开始收费。一般自行购买的证书需要进行验证。我们可以选择文件验证。下面是一个go的例子。

```go
package main

import (
	"bytes"
	"context"
	"fmt"
	"github.com/qiniu/go-sdk/v7/auth/qbox"
	"github.com/qiniu/go-sdk/v7/storage"
)

const (
	accessKey        = "lUkkMTqUK-fY7t6Tbg7zq-p3iaopntRM3232kEEDW"
	secretKey        = "3svBHRvSBJlp0iVJMx-7urereu82mcLQPLJ1"
	bucket           = "golang"
	challengeKey     = ".well-known/pki-validation/2FA8BE94165E014EA0AE3F664EF548E8.txt"
	challengeContent = `88518DD627533E6481D735B37C1BF258DCAF3ECA120CC86ED49A243446CB7D0B
trust-provider.com
TTDzhPt2m4`
)

func main() {
	putPolicy := storage.PutPolicy{
		Scope: bucket,
	}
	mac := qbox.NewMac(accessKey, secretKey)
	upToken := putPolicy.UploadToken(mac)
	cfg := storage.Config{}
	// 空间对应的机房
	cfg.Region = &storage.ZoneXinjiapo
	// 是否使用https域名
	cfg.UseHTTPS = true
	// 上传是否使用CDN上传加速
	cfg.UseCdnDomains = false

	formUploader := storage.NewFormUploader(&cfg)
	ret := storage.PutRet{}
	putExtra := storage.PutExtra{
		Params: map[string]string{
			"x:name": challengeKey,
		},
	}
	data := []byte(challengeContent)
	dataLen := int64(len(data))
	err := formUploader.Put(context.Background(),
		&ret, upToken, challengeKey,
		bytes.NewReader(data),
		dataLen,
		&putExtra)
	if err != nil {
		fmt.Println(err)
	}
	fmt.Println(ret.Key, ret.Hash)

}
```

如果我们需要使用Let's Encrypt的免费证书，我们还要配合ACME的客户端。上面的几种认证，如果本身没有DNS的权限，但是又想更新七牛证书，那么选择http-01更感觉适合，因为七牛的bucket域名是通过dns直接绑定的，同时还要配合七牛的sdk来实现证书申请的功能。

  下面是一个go的代码：

```go
package main

import (
	"bytes"
	"context"
	"crypto"
	"crypto/ecdsa"
	"crypto/elliptic"
	"crypto/rand"
	"fmt"
	"github.com/go-acme/lego/v4/certificate"
	"github.com/go-acme/lego/v4/challenge/dns01"
	"github.com/go-acme/lego/v4/challenge/http01"
	"github.com/go-acme/lego/v4/lego"
	"github.com/go-acme/lego/v4/registration"
	"github.com/qiniu/go-sdk/v7/auth/qbox"
	"github.com/qiniu/go-sdk/v7/storage"
	"log"
)

const (
	accessKey = "xxxxx"
	secretKey = "xxxxxx"
	bucket    = "golang"
	domain    = "golang.czyt.tech"
)

// You'll need a user or account type that implements acme.User
type MyUser struct {
	Email        string
	Registration *registration.Resource
	key          crypto.PrivateKey
}

func (u *MyUser) GetEmail() string {
	return u.Email
}
func (u *MyUser) GetRegistration() *registration.Resource {
	return u.Registration
}
func (u *MyUser) GetPrivateKey() crypto.PrivateKey {
	return u.key
}

// 实现自定义的 challenge.Provider
type MyChallengeProvider struct {
}

func NewMyChallengeProvider() (*MyChallengeProvider, error) {
	return &MyChallengeProvider{}, nil
}
func (d *MyChallengeProvider) Present(domain, token, keyAuth string) error {
	_ = dns01.GetChallengeInfo(domain, keyAuth)

	putPolicy := storage.PutPolicy{
		Scope: bucket,
	}
	mac := qbox.NewMac(accessKey, secretKey)
	upToken := putPolicy.UploadToken(mac)
	cfg := storage.Config{}
	// 空间对应的机房
	cfg.Region = &storage.ZoneXinjiapo
	// 是否使用https域名
	cfg.UseHTTPS = true
	// 上传是否使用CDN上传加速
	cfg.UseCdnDomains = false

	formUploader := storage.NewFormUploader(&cfg)
	ret := storage.PutRet{}
	putExtra := storage.PutExtra{
		Params: map[string]string{
			"x:name": http01.ChallengePath(token)[1:],
		},
	}
	data := []byte(keyAuth)
	dataLen := int64(len(data))
	err := formUploader.Put(context.Background(), &ret, upToken, http01.ChallengePath(token)[1:], bytes.NewReader(data), dataLen, &putExtra)
	if err != nil {
		fmt.Println(err)
	}
	fmt.Println(ret.Key, ret.Hash)

	return nil
}

func (d *MyChallengeProvider) CleanUp(domain, token, keyAuth string) error {
	// 清理任务，可以在这里清理掉之前上传的文件
	return nil
}

func main() {
	// Create a user. New accounts need an email and private key to start.
	privateKey, err := ecdsa.GenerateKey(elliptic.P256(), rand.Reader)
	if err != nil {
		log.Fatal(err)
	}

	myUser := MyUser{
		Email: "czytcn@qq.com",
		key:   privateKey,
	}

	config := lego.NewConfig(&myUser)

	// This CA URL is configured for a local dev instance of Boulder running in Docker in a VM.
	config.CADirURL = "https://acme-staging-v02.api.letsencrypt.org/directory"

	// A client facilitates communication with the CA server.
	client, err := lego.NewClient(config)
	if err != nil {
		log.Fatal(err)
	}
	dns, err := NewMyChallengeProvider()
	if err != nil {
		log.Fatal("init provider failed:", err)
	}
	
	err = client.Challenge.SetHTTP01Provider(dns)
	if err != nil {
		log.Fatal(err)
	}
	// 新用户需要注册
	reg, err := client.Registration.Register(registration.RegisterOptions{TermsOfServiceAgreed: true})
	if err != nil {
		log.Fatal(err)
	}
	myUser.Registration = reg
	log.Println("reg info:", *reg)
	request := certificate.ObtainRequest{
		Domains: []string{domain},
		Bundle:  true,
	}
	log.Println("request:", request)
	certificates, err := client.Certificate.Obtain(request)
	if err != nil {
		log.Fatal("Obtain failed:", err)
	}

	// 证书返回
	// 私钥和 证书相关信息. 可以在这里保存到磁盘.
	fmt.Printf("%#v\n", certificates)

}
```

证书获取成功以后，再上传到七牛即可。上传的这部分代码，我在GitHub上找到了相关的go包：[源](https://github.com/tuotoo/qiniu-auto-cert/blob/master/qiniu/api.go)

调用：

```go
package qiniu

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"

	"github.com/qiniu/api.v7/auth/qbox"
)

const APIHost = "http://api.qiniu.com"

type Client struct {
	*qbox.Mac
}

func New(accessKey, secretKey string) *Client {
	return &Client{
		Mac: qbox.NewMac(accessKey, secretKey),
	}
}

func (c *Client) Request(method string, path string, body interface{}) (resData []byte,
	err error) {
	urlStr := fmt.Sprintf("%s%s", APIHost, path)
	reqData, _ := json.Marshal(body)
	req, reqErr := http.NewRequest(method, urlStr, bytes.NewReader(reqData))
	if reqErr != nil {
		err = reqErr
		return
	}

	accessToken, signErr := c.SignRequest(req)
	if signErr != nil {
		err = signErr
		return
	}

	req.Header.Add("Authorization", "QBox "+accessToken)
	req.Header.Add("Content-Type", "application/json")

	resp, respErr := http.DefaultClient.Do(req)
	if respErr != nil {
		err = respErr
		return
	}
	defer resp.Body.Close()

	resData, ioErr := ioutil.ReadAll(resp.Body)
	if ioErr != nil {
		err = ioErr
		return
	}

	return
}

func (c *Client) GetDomainInfo(domain string) (*DomainInfo, error) {
	b, err := c.Request("GET", "/domain/"+domain, nil)
	if err != nil {
		return nil, err
	}
	info := &DomainInfo{}
	if err := json.Unmarshal(b, info); err != nil {
		return nil, err
	}
	if info.Code > 200 {
		return nil, fmt.Errorf("%d: %s", info.Code, info.Error)
	}
	return info, nil
}

func (c *Client) GetCertInfo(certID string) (*CertInfo, error) {
	b, err := c.Request("GET", "/sslcert/"+certID, nil)
	if err != nil {
		return nil, err
	}
	info := &CertInfo{}
	if err := json.Unmarshal(b, info); err != nil {
		return nil, err
	}
	if info.Code > 200 {
		return nil, fmt.Errorf("%d: %s", info.Code, info.Error)
	}
	return info, nil
}

func (c *Client) UploadCert(cert Cert) (*UploadCertResp, error) {
	b, err := c.Request("POST", "/sslcert", cert)
	if err != nil {
		return nil, err
	}
	resp := &UploadCertResp{}
	if err := json.Unmarshal(b, resp); err != nil {
		return nil, err
	}
	if resp.Code > 200 {
		return nil, fmt.Errorf("%d: %s", resp.Code, resp.Error)
	}
	return resp, nil
}

func (c *Client) UpdateHttpsConf(domain, certID string) (*CodeErr, error) {
	b, err := c.Request("PUT", "/domain/"+domain+"/httpsconf", HTTPSConf{
		CertID:     certID,
		ForceHttps: true,
	})
	if err != nil {
		return nil, err
	}
	resp := &CodeErr{}
	if err := json.Unmarshal(b, resp); err != nil {
		return nil, err
	}
	if resp.Code > 200 {
		return nil, fmt.Errorf("%d: %s", resp.Code, resp.Error)
	}
	return resp, nil
}

func (c *Client) DeleteCert(certID string) (*CodeErr, error) {
	b, err := c.Request("DELETE", "/sslcert/"+certID, nil)
	if err != nil {
		return nil, err
	}
	resp := &CodeErr{}
	if err := json.Unmarshal(b, resp); err != nil {
		return nil, err
	}
	if resp.Code > 200 {
		return nil, fmt.Errorf("%d: %s", resp.Code, resp.Error)
	}
	return resp, nil
}

func (c *Client) DomainSSLize(domain, certID string) (*CodeErr, error) {
	b, err := c.Request("PUT", "/domain/"+domain+"/sslize", HTTPSConf{
		CertID:     certID,
		ForceHttps: true,
	})
	if err != nil {
		return nil, err
	}
	resp := &CodeErr{}
	if err := json.Unmarshal(b, resp); err != nil {
		return nil, err
	}
	if resp.Code > 200 {
		return nil, fmt.Errorf("%d: %s", resp.Code, resp.Error)
	}
	return resp, nil
}
```

相关结构定义

```go
package qiniu

import (
	"strconv"
	"time"
)

type CodeErr struct {
	Code  int    `json:"code"`
	Error string `json:"error"`
}

type DomainInfo struct {
	CodeErr
	Name               string    `json:"name"`
	PareDomain         string    `json:"pareDomain"`
	Type               string    `json:"type"`
	Cname              string    `json:"cname"`
	TestURLPath        string    `json:"testURLPath"`
	Protocol           string    `json:"protocol"`
	Platform           string    `json:"platform"`
	GeoCover           string    `json:"geoCover"`
	QiniuPrivate       bool      `json:"qiniuPrivate"`
	OperationType      string    `json:"operationType"`
	OperatingState     string    `json:"operatingState"`
	OperatingStateDesc string    `json:"operatingStateDesc"`
	CreateAt           time.Time `json:"createAt"`
	ModifyAt           time.Time `json:"modifyAt"`
	HTTPS              struct {
		CertID     string `json:"certId"`
		ForceHTTPS bool   `json:"forceHttps"`
	} `json:"https"`
	CouldOperateBySelf bool   `json:"couldOperateBySelf"`
	RegisterNo         string `json:"registerNo"`
}

type Cert struct {
	Name       string `json:"name"`
	CommonName string `json:"common_name"`
	CA         string `json:"ca"`
	Pri        string `json:"pri"`
}

type UploadCertResp struct {
	CodeErr
	CertID string `json:"certID"`
}

type CertInfo struct {
	CodeErr
	Cert struct {
		CertID           string    `json:"certid"`
		Name             string    `json:"name"`
		UID              int       `json:"uid"`
		CommonName       string    `json:"common_name"`
		DNSNames         []string  `json:"dnsnames"`
		CreateTime       TimeStamp `json:"create_time"`
		NotBefore        TimeStamp `json:"not_before"`
		NotAfter         TimeStamp `json:"not_after"`
		OrderID          string    `json:"orderid"`
		ProductShortName string    `json:"product_short_name"`
		ProductType      string    `json:"product_type"`
		Encrypt          string    `json:"encrypt"`
		EncryptParameter string    `json:"encryptParameter"`
		Enable           bool      `json:"enable"`
		Ca               string    `json:"ca"`
		Pri              string    `json:"pri"`
	} `json:"cert"`
}

type TimeStamp struct {
	time.Time
}

func (t *TimeStamp) UnmarshalJSON(b []byte) error {
	i, err := strconv.ParseInt(string(b), 10, 64)
	if err != nil {
		return err
	}
	t.Time = time.Unix(i, 0)
	return nil
}

type HTTPSConf struct {
	CertID     string `json:"certid"`
	ForceHttps bool   `json:"forceHttps"`
}
```

## 有用的链接

+ [七牛证书管理API](https://developer.qiniu.com/dcdn/10749/dcdn-certificate-of-relevant)