---
title: "使用aws go-sdk访问cloudflare R2文件"
date: 2023-05-21
tags: ["golang", "cloudflare", "aws"]
draft: false
---

## 准备

需要准备Cloudflare的`accountId`,相应的R2 `ak` `sk` 和`bucketName`等信息.

```go
var (
		accountId       = "xxxxx"
		accessKeyId     = "cbdade718b2ca877882csssssfcf"
		accessKeySecret = "04917c7d745422022e266f6b06"
		bucketName      = "gopher"
	)
```

## 完整代码

```go
package main

import (
	"context"
	"fmt"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/credentials"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"log"
)

func main() {
var (
		accountId       = "xxxxx"
		accessKeyId     = "cbdade718b2ca877882csssssfcf"
		accessKeySecret = "04917c7d745422022e266f6b06"
		bucketName      = "gopher"
	)
	var r2Resolver = aws.EndpointResolverWithOptionsFunc(func(service, region string, options ...interface{}) (aws.Endpoint, error) {
		return aws.Endpoint{
			URL: fmt.Sprintf("https://%s.r2.cloudflarestorage.com", accountId),
		}, nil
	})

	cfg, err := config.LoadDefaultConfig(context.TODO(),
		config.WithEndpointResolverWithOptions(r2Resolver),
		config.WithCredentialsProvider(credentials.NewStaticCredentialsProvider(accessKeyId, accessKeySecret, "")),
	)
	if err != nil {
		log.Fatal(err)
	}

	client := s3.NewFromConfig(cfg)

	listObjectsOutput, err := client.ListObjectsV2(context.TODO(), &s3.ListObjectsV2Input{
		Bucket: &bucketName,
	})
	if err != nil {
		log.Fatal(err)
	}
	presignClient := s3.NewPresignClient(client)

	for _, object := range listObjectsOutput.Contents {
		// 创建文件访问链接
		presignResult, err := presignClient.PresignGetObject(context.TODO(), &s3.GetObjectInput{
			Bucket: aws.String(bucketName),
			Key:    aws.String(*object.Key),
		})

		if err != nil {
			panic("Couldn't get presigned URL for PutObject")
		}

		fmt.Printf("get URL For object: %s\n", presignResult.URL)
	}

}

```

