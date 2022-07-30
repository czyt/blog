---
title: "为Kratos prtobuf文件添加Csharp及Python编译输出"
date: 2022-04-08
tags: ["golang", "kratos", "csharp","python"]
draft: false
---

## Csharp

1. 安装Grpc.tools https://www.nuget.org/packages/Grpc.Tools/
2. 下载解压 nupkg文件（改扩展名为zip），也可以使用附件的7z包

1. 解压 找到tools中对应系统架构的软件，设置下环境变量，让系统可以找到就行。

Linux 需要创建一个符号链接 

```bash
ln -s `which grpc_csharp_plugin` /usr/bin/protoc-gen-grpc-csharp
```



1. 修改Kratos项目的Make文件

在api这个make任务中添加下面内容

```makefile
         --csharp_out=./api/pipe/v1 \
         --grpc-csharp_out=./api/pipe/v1 \
```

完整内容为

```makefile
.PHONY: api
# generate api proto
api:
 protoc --proto_path=./api \
        --proto_path=./third_party \
         --go_out=paths=source_relative:./api \
         --go-http_out=paths=source_relative:./api \
         --go-grpc_out=paths=source_relative:./api \
         --csharp_out=./api/pipe/v1 \
         --grpc-csharp_out=./api/pipe/v1 \
         --openapi_out==paths=source_relative:. \
```

参考

https://github.com/grpc/grpc/blob/master/src/csharp/BUILD-INTEGRATION.md

[📎tools.7z](https://www.yuque.com/attachments/yuque/0/2022/7z/457321/1648739141239-9bea9d30-3721-4ff0-a357-e60e3c13e47f.7z)

## Python

1. 安装必要包  `pip install grpclib protobuf `
2. 查询路径 `which protoc-gen-grpclib_python `或者` which protoc-gen-python_grpc`我这里返回信息如下：

```plain
➜  czyt which protoc-gen-grpclib_python
/usr/sbin/protoc-gen-grpclib_python
```

3. 如法炮制，创建软链接

```bash
ln -s /usr/sbin/protoc-gen-grpclib_python /usr/sbin/protoc-gen-grpc_python
```

4. 修改Makefile 添加下面的内容,再执行`make api`生成api即可。

```makefile
--python_out=./api \
--grpc_python_out=./api \
```