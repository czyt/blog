---
title: "golang http客户端使用自定义dns"
date: 2022-08-22
tags: ["golang", "dns"]
draft: false·
---
摘自互联网 [原文](https://koraygocmen.com/blog/custom-dns-resolver-for-the-default-http-client-in-go)

```go
package main

import (
"context"
"io/ioutil"
"log"
"net"
"net/http"
"time"
)

func main() {
var (
	dnsResolverIP = "8.8.8.8:53" // Google DNS resolver.
	dnsResolverProto = "udp" // Protocol to use for the DNS resolver
	dnsResolverTimeoutMs = 5000 // Timeout (ms) for the DNS resolver (optional)
)

dialer := &net.Dialer{
Resolver: &net.Resolver{
	PreferGo: true,
	Dial: func(ctx context.Context, network, address string) (net.Conn, error) {
		d := net.Dialer{
			Timeout: time.Duration(dnsResolverTimeoutMs) * time.Millisecond,
		}
		return d.DialContext(ctx, dnsResolverProto, dnsResolverIP)
	},
},
}

dialContext := func(ctx context.Context, network, addr string) (net.Conn, error) {
	return dialer.DialContext(ctx, network, addr)
}

http.DefaultTransport.(*http.Transport).DialContext = dialContext
httpClient := &http.Client{}

// Testing the new HTTP client with the custom DNS resolver.
resp, err := httpClient.Get("https://www.violetnorth.com")
if err != nil {
	log.Fatalln(err)
}
defer resp.Body.Close()

body, err := ioutil.ReadAll(resp.Body)
if err != nil {
log.Fatalln(err)
}

log.Println(string(body))
```

