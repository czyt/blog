---
title: "golang不创建临时文件上传网络文件"
date: 2021-05-21
tags: ["golang", "ssh", "database"]
draft: false
---

```go
func UploadFromUrl(uploadUrl string, resUrl string,postFileName string, submitField string) error {
	method := "POST"

	payload := &bytes.Buffer{}
	writer := multipart.NewWriter(payload)

	if res, err := http.Get(resUrl); err != nil {
		return err
	} else {
		defer func() {
			if res != nil {
				_ = res.Body.Close()
			}

		}()
		part, _ := writer.CreateFormFile(submitField, postFileName)
		if _, copyErr := io.Copy(part, res.Body); copyErr != nil {
			return copyErr
		}
		if err := writer.Close(); err != nil {
			return err
		}
	}

	client := &http.Client{}
	req, err := http.NewRequest(method, uploadUrl, payload)

	if err != nil {
		return err
	}
	req.Header.Set("Content-Type", writer.FormDataContentType())
	resp, err := client.Do(req)
	if err != nil {
		return err
	}
	defer func() {
		_ = resp.Body.Close()
		client = nil
		writer = nil
	}()

	return nil
}
```

