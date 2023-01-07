---
title: "从Golang的开源项目中学习不同的功能实现"
date: 2022-11-25
tags: ["golang", "open source","MongoDB"]
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

## 文件生成

### 国际化I18n

```go
package i18n

import (
	"context"
	"encoding/json"
	"io/ioutil"
	"net/http"
	"os"
	"strings"

	"github.com/BurntSushi/toml"
	"github.com/grpc-ecosystem/go-grpc-middleware/util/metautils"
	"github.com/nicksnyder/go-i18n/v2/i18n"
	"github.com/zitadel/logging"
	"golang.org/x/text/language"
	"sigs.k8s.io/yaml"

	"github.com/zitadel/zitadel/internal/api/authz"
	http_util "github.com/zitadel/zitadel/internal/api/http"
	"github.com/zitadel/zitadel/internal/errors"
)

const (
	i18nPath = "/i18n"
)

type Translator struct {
	bundle             *i18n.Bundle
	cookieName         string
	cookieHandler      *http_util.CookieHandler
	preferredLanguages []string
}

type TranslatorConfig struct {
	DefaultLanguage language.Tag
	CookieName      string
}

type Message struct {
	ID   string
	Text string
}

func NewTranslator(dir http.FileSystem, defaultLanguage language.Tag, cookieName string) (*Translator, error) {
	t := new(Translator)
	var err error
	t.bundle, err = newBundle(dir, defaultLanguage)
	if err != nil {
		return nil, err
	}
	t.cookieHandler = http_util.NewCookieHandler()
	t.cookieName = cookieName
	return t, nil
}

func newBundle(dir http.FileSystem, defaultLanguage language.Tag) (*i18n.Bundle, error) {
	bundle := i18n.NewBundle(defaultLanguage)
	bundle.RegisterUnmarshalFunc("yaml", func(data []byte, v interface{}) error { return yaml.Unmarshal(data, v) })
	bundle.RegisterUnmarshalFunc("json", json.Unmarshal)
	bundle.RegisterUnmarshalFunc("toml", toml.Unmarshal)
	i18nDir, err := dir.Open(i18nPath)
	if err != nil {
		return nil, errors.ThrowNotFound(err, "I18N-MnXRie", "path not found")
	}
	defer i18nDir.Close()
	files, err := i18nDir.Readdir(0)
	if err != nil {
		return nil, errors.ThrowNotFound(err, "I18N-Gew23", "cannot read dir")
	}
	for _, file := range files {
		if err := addFileFromFileSystemToBundle(dir, bundle, file); err != nil {
			return nil, errors.ThrowNotFoundf(err, "I18N-ZS2AW", "cannot append file %s to Bundle", file.Name())
		}
	}
	return bundle, nil
}

func addFileFromFileSystemToBundle(dir http.FileSystem, bundle *i18n.Bundle, file os.FileInfo) error {
	f, err := dir.Open("/i18n/" + file.Name())
	if err != nil {
		return err
	}
	defer f.Close()
	content, err := ioutil.ReadAll(f)
	if err != nil {
		return err
	}
	_, err = bundle.ParseMessageFileBytes(content, file.Name())
	return err
}

func SupportedLanguages(dir http.FileSystem) ([]language.Tag, error) {
	i18nDir, err := dir.Open("/i18n")
	if err != nil {
		return nil, errors.ThrowNotFound(err, "I18N-Dbt42", "cannot open dir")
	}
	defer i18nDir.Close()
	files, err := i18nDir.Readdir(0)
	if err != nil {
		return nil, errors.ThrowNotFound(err, "I18N-Gh4zk", "cannot read dir")
	}
	languages := make([]language.Tag, 0, len(files))
	for _, file := range files {
		lang := language.Make(strings.TrimSuffix(file.Name(), ".yaml"))
		if lang != language.Und {
			languages = append(languages, lang)
		}
	}
	return languages, nil
}

func (t *Translator) SupportedLanguages() []language.Tag {
	return t.bundle.LanguageTags()
}

func (t *Translator) AddMessages(tag language.Tag, messages ...Message) error {
	if len(messages) == 0 {
		return nil
	}
	i18nMessages := make([]*i18n.Message, len(messages))
	for i, message := range messages {
		i18nMessages[i] = &i18n.Message{
			ID:    message.ID,
			Other: message.Text,
		}
	}
	return t.bundle.AddMessages(tag, i18nMessages...)
}

func (t *Translator) LocalizeFromRequest(r *http.Request, id string, args map[string]interface{}) string {
	return localize(t.localizerFromRequest(r), id, args)
}

func (t *Translator) LocalizeFromCtx(ctx context.Context, id string, args map[string]interface{}) string {
	return localize(t.localizerFromCtx(ctx), id, args)
}

func (t *Translator) Localize(id string, args map[string]interface{}, langs ...string) string {
	return localize(t.localizer(langs...), id, args)
}

func (t *Translator) LocalizeWithoutArgs(id string, langs ...string) string {
	return localize(t.localizer(langs...), id, map[string]interface{}{})
}

func (t *Translator) Lang(r *http.Request) language.Tag {
	matcher := language.NewMatcher(t.bundle.LanguageTags())
	tag, _ := language.MatchStrings(matcher, t.langsFromRequest(r)...)
	return tag
}

func (t *Translator) SetLangCookie(w http.ResponseWriter, r *http.Request, lang language.Tag) {
	t.cookieHandler.SetCookie(w, t.cookieName, r.Host, lang.String())
}

func (t *Translator) localizerFromRequest(r *http.Request) *i18n.Localizer {
	return t.localizer(t.langsFromRequest(r)...)
}

func (t *Translator) localizerFromCtx(ctx context.Context) *i18n.Localizer {
	return t.localizer(t.langsFromCtx(ctx)...)
}

func (t *Translator) localizer(langs ...string) *i18n.Localizer {
	return i18n.NewLocalizer(t.bundle, langs...)
}

func (t *Translator) langsFromRequest(r *http.Request) []string {
	langs := t.preferredLanguages
	if r != nil {
		lang, err := t.cookieHandler.GetCookieValue(r, t.cookieName)
		if err == nil {
			langs = append(langs, lang)
		}
		langs = append(langs, r.Header.Get("Accept-Language"))
	}
	return langs
}

func (t *Translator) langsFromCtx(ctx context.Context) []string {
	langs := t.preferredLanguages
	if ctx != nil {
		ctxData := authz.GetCtxData(ctx)
		if ctxData.PreferredLanguage != language.Und.String() {
			langs = append(langs, authz.GetCtxData(ctx).PreferredLanguage)
		}
		langs = append(langs, getAcceptLanguageHeader(ctx))
	}
	return langs
}

func (t *Translator) SetPreferredLanguages(langs ...string) {
	t.preferredLanguages = langs
}

func getAcceptLanguageHeader(ctx context.Context) string {
	acceptLanguage := metautils.ExtractIncoming(ctx).Get("accept-language")
	if acceptLanguage != "" {
		return acceptLanguage
	}
	return metautils.ExtractIncoming(ctx).Get("grpcgateway-accept-language")
}

func localize(localizer *i18n.Localizer, id string, args map[string]interface{}) string {
	s, err := localizer.Localize(&i18n.LocalizeConfig{
		MessageID:    id,
		TemplateData: args,
	})
	if err != nil {
		logging.WithFields("id", id, "args", args).WithError(err).Warnf("missing translation")
		return id
	}
	return s
}

```



### SVG格式的二维码

```go
package qrcode

import (
	"errors"
	"image/color"

	"github.com/ajstarks/svgo"
	"github.com/boombuler/barcode"
)

// QrSVG holds the data related to the size, location,
// and block size of the QR Code. Holds unexported fields.
type QrSVG struct {
	qr        barcode.Barcode
	qrWidth   int
	blockSize int
	startingX int
	startingY int
}

// NewQrSVG contructs a QrSVG struct. It takes a QR Code in the form
// of barcode.Barcode and sets the "pixel" or block size of QR Code in
// the SVG file.
func NewQrSVG(qr barcode.Barcode, blockSize int) QrSVG {
	return QrSVG{
		qr:        qr,
		qrWidth:   qr.Bounds().Max.X,
		blockSize: blockSize,
		startingX: 0,
		startingY: 0,
	}
}

// WriteQrSVG writes the QR Code to SVG.
func (qs *QrSVG) WriteQrSVG(s *svg.SVG) error {
	if qs.qr.Metadata().CodeKind == "QR Code" {
		currY := qs.startingY

		for x := 0; x < qs.qrWidth; x++ {
			currX := qs.startingX
			for y := 0; y < qs.qrWidth; y++ {
				if qs.qr.At(x, y) == color.Black {
					s.Rect(currX, currY, qs.blockSize, qs.blockSize, "class=\"color\"")
				} else if qs.qr.At(x, y) == color.White {
					s.Rect(currX, currY, qs.blockSize, qs.blockSize, "class=\"bg-color\"")
				}
				currX += qs.blockSize
			}
			currY += qs.blockSize
		}
		return nil
	}
	return errors.New("can not write to SVG: Not a QR code")
}

// SetStartPoint sets the top left start point of QR Code.
// This takes an X and Y value and then adds four white "blocks"
// to create the "quiet zone" around the QR Code.
func (qs *QrSVG) SetStartPoint(x, y int) {
	qs.startingX = x + (qs.blockSize * 4)
	qs.startingY = y + (qs.blockSize * 4)
}

// StartQrSVG creates a start for writing an SVG file that
// only contains a barcode. This is similar to the svg.Start() method.
// This fucntion should only be used if you only want to write a QR code
// to the SVG. Otherwise use the regular svg.Start() method to start your
// SVG file.
func (qs *QrSVG) StartQrSVG(s *svg.SVG) {
	width := (qs.qrWidth * qs.blockSize) + (qs.blockSize * 8)
	qs.SetStartPoint(0, 0)
	s.Start(width, width)
}

```



## 账户

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

## 数据库

## MongoDB

代码来自于[illacloud](https://github.com/illacloud)

连接时使用SSL选项

```go
// TLS: self-signed certificate
	var credential options.Credential
	var tlsConfig tls.Config
    // config checks
	if m.Resource.SSL.Open == true && m.Resource.SSL.CA != "" {
		credential = options.Credential{AuthMechanism: "MONGODB-X509"}
		pool := x509.NewCertPool()
		if ok := pool.AppendCertsFromPEM([]byte(m.Resource.SSL.CA)); !ok {
			return nil, errors.New("format MongoDB TLS CA Cert failed")
		}
		tlsConfig = tls.Config{RootCAs: pool}
		if m.Resource.SSL.Client != "" {
			splitIndex := bytes.Index([]byte(m.Resource.SSL.Client), []byte("-----\n-----"))
			if splitIndex <= 0 {
				return nil, errors.New("format MongoDB TLS Client Key Pair failed")
			}
			clientKeyPairSlice := []string{m.Resource.SSL.Client[:splitIndex+6], m.Resource.SSL.Client[splitIndex+6:]}
			clientCert := ""
			clientKey := ""
			if strings.Contains(clientKeyPairSlice[0], "CERTIFICATE") {
				clientCert = clientKeyPairSlice[0]
				clientKey = clientKeyPairSlice[1]
			} else {
				clientCert = clientKeyPairSlice[1]
				clientKey = clientKeyPairSlice[0]
			}
			ccBlock, _ := pem.Decode([]byte(clientCert))
			ckBlock, _ := pem.Decode([]byte(clientKey))
			if (ccBlock != nil && ccBlock.Type == "CERTIFICATE") && (ckBlock != nil || strings.Contains(ckBlock.Type, "PRIVATE KEY")) {
				cert, err := tls.X509KeyPair([]byte(clientCert), []byte(clientKey))
				if err != nil {
					return nil, err
				}
				tlsConfig.Certificates = []tls.Certificate{cert}
			}
		}
```

其他类型的数据库均有实现。
