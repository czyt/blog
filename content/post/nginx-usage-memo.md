---
title: "Nginx使用备忘"
date: 2023-06-21
tags: ["nginx", "server"]
draft: false
---
# 安装和更新
## 安装
以ArchLinux为例

`yay -S nginx`

生成的systemctl单元如下

```yaml
[Unit]
Description=A high performance web server and a reverse proxy server
After=network.target network-online.target nss-lookup.target

[Service]
Type=forking
PIDFile=/run/nginx.pid
PrivateDevices=yes
SyslogLevel=err

ExecStart=/usr/bin/nginx -g 'pid /run/nginx.pid; error_log stderr;'
ExecReload=/usr/bin/nginx -s reload
KillMode=mixed

[Install]
WantedBy=multi-user.target
```

## 更新
查看现有Nginx的编译参数
```bash
➜  ~ nginx -V
nginx version: nginx/1.22.1
built with OpenSSL 3.0.7 1 Nov 2022 (running with OpenSSL 3.0.8 7 Feb 2023)
TLS SNI support enabled
configure arguments: --prefix=/etc/nginx --conf-path=/etc/nginx/nginx.conf --sbin-path=/usr/bin/nginx --pid-path=/run/nginx.pid --lock-path=/run/lock/nginx.lock --user=http --group=http --http-log-path=/var/log/nginx/access.log --error-log-path=stderr --http-client-body-temp-path=/var/lib/nginx/client-body --http-proxy-temp-path=/var/lib/nginx/proxy --http-fastcgi-temp-path=/var/lib/nginx/fastcgi --http-scgi-temp-path=/var/lib/nginx/scgi --http-uwsgi-temp-path=/var/lib/nginx/uwsgi --with-cc-opt='-march=armv8-a -O2 -pipe -fstack-protector-strong -fno-plt -fexceptions -Wp,-D_FORTIFY_SOURCE=2 -Wformat -Werror=format-security -fstack-clash-protection -fPIC' --with-ld-opt=-Wl,-O1,--sort-common,--as-needed,-z,relro,-z,now --with-compat --with-debug --with-file-aio --with-http_addition_module --with-http_auth_request_module --with-http_dav_module --with-http_degradation_module --with-http_flv_module --with-http_geoip_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_mp4_module --with-http_realip_module --with-http_secure_link_module --with-http_slice_module --with-http_ssl_module --with-http_stub_status_module --with-http_sub_module --with-http_v2_module --with-mail --with-mail_ssl_module --with-pcre-jit --with-stream --with-stream_geoip_module --with-stream_realip_module --with-stream_ssl_module --with-stream_ssl_preread_module --with-threads
```

下载最新的nginx源码 `wget https://nginx.org/download/nginx-1.25.1.tar.gz` 然后解压。切换到`configure`所在目录,并使用上面的参数编译nginx

```bash
➜  nginx-1.25.1 ./configure --prefix=/etc/nginx --conf-path=/etc/nginx/nginx.conf --sbin-path=/usr/bin/nginx --pid-path=/run/nginx.pid --lock-path=/run/lock/nginx.lock --user=http --group=http --http-log-path=/var/log/nginx/access.log --error-log-path=stderr --http-client-body-temp-path=/var/lib/nginx/client-body --http-proxy-temp-path=/var/lib/nginx/proxy --http-fastcgi-temp-path=/var/lib/nginx/fastcgi --http-scgi-temp-path=/var/lib/nginx/scgi --http-uwsgi-temp-path=/var/lib/nginx/uwsgi --with-cc-opt='-march=armv8-a -O2 -pipe -fstack-protector-strong -fno-plt -fexceptions -Wp,-D_FORTIFY_SOURCE=2 -Wformat -Werror=format-security -fstack-clash-protection -fPIC' --with-ld-opt=-Wl,-O1,--sort-common,--as-needed,-z,relro,-z,now --with-compat --with-debug --with-file-aio --with-http_addition_module --with-http_auth_request_module --with-http_dav_module --with-http_degradation_module --with-http_flv_module --with-http_geoip_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_mp4_module --with-http_realip_module --with-http_secure_link_module --with-http_slice_module --with-http_ssl_module --with-http_stub_status_module --with-http_sub_module --with-http_v2_module --with-mail --with-mail_ssl_module --with-pcre-jit --with-stream --with-stream_geoip_module --with-stream_realip_module --with-stream_ssl_module --with-stream_ssl_preread_module --with-threads
```

等待Makefile生成完毕。执行`make`进行编译，编译好以后，在obj开头的目录下，找到最新的nginx程序，替换现有的nginx即可。

可以通过`nginx -v`来查看更新是否成功

```bash
➜  nginx-1.25.1 nginx -v
nginx version: nginx/1.25.1
```

`   nginx -t` 检查nginx服务的配置文件是否正确。

`nginx -s reload` 重新加载配置文件。

# 配置



