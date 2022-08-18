---
title: "go-kratos使用备忘"
date: 2022-08-12
tags: ["golang", "kratos"]
draft: false
---
## 自定义接口返回内容
+ 正常的响应序列化逻辑通过[Response Encoder](https://go-kratos.dev/docs/component/transport/http#responseencoderen-encoderesponsefunc-serveroption)实现。
+ 错误的序列化逻辑通过[ErrorEncoder](https://go-kratos.dev/docs/component/transport/http#errorencoderen-encodeerrorfunc-serveroption)实现。

## 通过Context取得信息

Server端取JWT中的key数据

```go
func getPayloadFromCtx(ctx context.Context, partName string) (string, error) {
	if claims, ok := jwt.FromContext(ctx); ok {
		if m, ok := claims.(jwtV4.MapClaims); ok {
			if v, ok := m[partName].(string); ok {
				return v, nil
			}
		}
	}
	return "", errors.New("invalid Jwt")
}
```

middleware中，还可以将context转换为`http.Transport`获取更多的信息。

```go
if tr, ok := transport.FromServerContext(ctx); ok {
    // 可以取header等信息
    if hr, ok := tr.(*http.Transport); ok {
      // 可以取request等信息
   }
}

```

## 日志脱敏与过滤

需要对日志进行脱敏和过滤，使用 kratos的[日志过滤](https://go-kratos.dev/docs/component/log#filter-%E6%97%A5%E5%BF%97%E8%BF%87%E6%BB%A4)

```go
h := NewHelper(
    NewFilter(logger,
        // 等级过滤
        FilterLevel(log.LevelError),

        // 按key遮蔽
        FilterKey("username"),

        // 按value遮蔽
        FilterValue("hello"),

        // 自定义过滤函数
        FilterFunc(
            func (level Level, keyvals ...interface{}) bool {
                if level == LevelWarn {
                    return true
                }
                for i := 0; i < len(keyvals); i++ {
                    if keyvals[i] == "password" {
                        keyvals[i+1] = fuzzyStr
                    }
                }
                return false
            }
        ),
    ),
)

```

> - `FilterFunc(f func(level Level, keyvals ...interface{}) bool)` 使用自定义的函数来对日志进行处理，keyvals里为key和对应的value，按照奇偶进行读取即可

TODO:按奇偶进行读取的意思

## 参考

+ [三分钟小课堂 - 如何控制接口返回值](https://mp.weixin.qq.com/s/4ocdoAVXXKTvJ3U65YXltw)

