---
title: "ETCD一键安装脚本"
date: 2022-06-21
tags: ["etcd", "linux"]
draft: false
---
最近要使用ETCD，脚本根据官方GitHub脚本修改而来
```bash
#!/usr/bin/bash
ETCD_VER=v3.5.4

# choose either URL
GOOGLE_URL=https://storage.googleapis.com/etcd
GITHUB_URL=https://fastgit.czyt.tech/https://github.com/etcd-io/etcd/releases/download
ARCH=linux-arm64
DOWNLOAD_URL=${GITHUB_URL}
INSTALL_DIR=/opt/etcd

rm -f /tmp/etcd-${ETCD_VER}-${ARCH}.tar.gz
rm -rf ${INSTALL_DIR} && mkdir -p ${INSTALL_DIR}

curl -L ${DOWNLOAD_URL}/${ETCD_VER}/etcd-${ETCD_VER}-${ARCH}.tar.gz -o /tmp/etcd-${ETCD_VER}-${ARCH}.tar.gz
tar xzvf /tmp/etcd-${ETCD_VER}-${ARCH}.tar.gz -C ${INSTALL_DIR} --strip-components=1
rm -f /tmp/etcd-${ETCD_VER}-${ARCH}.tar.gz

${INSTALL_DIR}/etcd --version
${INSTALL_DIR}/etcdctl version
${INSTALL_DIR}/etcdutl version
```

其中的`ARCH`请根据实际情况修改。