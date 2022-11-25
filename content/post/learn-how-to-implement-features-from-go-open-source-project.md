---
title: "从Golang的开源项目中学习不同的功能实现"
date: 2022-05-27
tags: ["flutter", "android"]
draft: false
---

## 缘起

最近看到有些go开源项目中的代码，看到其中的功能，故整理备用。

## 日志

### Zap

#### 带日志等级输出

代码源 https://github.com/illacloud/builder-backend/tree/main/internal/util

```go
var logger *zap.SugaredLogger

type LogConfig struct {
	ILLA_LOG_LEVEL int `env:"ILLA_LOG_LEVEL" envDefault:"0"`
}

func init() {
	cfg := &LogConfig{}
	err := env.Parse(cfg)
	if err != nil {
		return
	}

	logConfig := zap.NewProductionConfig()
	logConfig.Level = zap.NewAtomicLevelAt(zapcore.Level(cfg.ILLA_LOG_LEVEL))
	baseLogger, err := logConfig.Build()
	if err != nil {
		panic("failed to create the default logger: " + err.Error())
	}
	logger = baseLogger.Sugar()
}

func NewSugardLogger() *zap.SugaredLogger {
	return logger
}
```



## 账户验证

### 邮箱验证码

代码来自于[illacloud](https://github.com/illacloud),[代码位置链接](https://github.com/illacloud/builder-backend/blob/main/pkg/smtp/service.go)

发送

```go
func (s *SMTPServer) NewVerificationCode(email, usage string) (string, error) {
	rnd := rand.New(rand.NewSource(time.Now().UnixNano()))
	vCode := fmt.Sprintf("%06v", rnd.Int31n(1000000))
	if err := email_cloud.SendVerificationEmail(email, vCode, usage); err != nil {
		return "", err
	}
	claims := &VCodeClaims{
		Email: email,
		Code:  vCode,
		Usage: usage,
		RegisteredClaims: jwt.RegisteredClaims{
			Issuer: "ILLA",
			ExpiresAt: &jwt.NumericDate{
				Time: time.Now().Add(time.Minute * 15),
			},
		},
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	codeToken, err := token.SignedString([]byte(s.Secret))
	if err != nil {
		return "", err
	}

	return codeToken, nil
}
```

验证

```go

func (s *SMTPServer) ValidateVerificationCode(codeToken, vCode, email, usage string) (bool, error) {
	vCodeClaims := &VCodeClaims{}
	token, err := jwt.ParseWithClaims(codeToken, vCodeClaims, func(token *jwt.Token) (interface{}, error) {
		return []byte(s.Secret), nil
	})
	if err != nil {
		return false, err
	}

	claims, ok := token.Claims.(*VCodeClaims)
	if !(ok && claims.Usage == usage) {
		return false, errors.New("invalid verification token")
	}
	if !(claims.Code == vCode && claims.Email == email) {
		return false, errors.New("verification code wrong")
	}
	return true, nil
}
```

