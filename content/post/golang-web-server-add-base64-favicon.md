---
title: "golang webserver with genergic base64 /favicon.ico"
date: 2022-02-23
tags: ["golang", "web", "server"]
draft: false
---

```go
package main

import (
  "fmt"
  "net/http"
)

func main() {
  http.HandleFunc("/favicon.ico", favicon)
  http.HandleFunc("/", hello)
  fmt.Printf("listening on http://localhost:8000/\n")
  http.ListenAndServe("localhost:8000", nil)

}

func favicon(w http.ResponseWriter, r *http.Request) {
  fmt.Printf("%s\n", r.RequestURI)
  w.Header().Set("Content-Type", "image/x-icon")
  w.Header().Set("Cache-Control", "public, max-age=7776000")
  fmt.Fprintln(w, "data:image/x-icon;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQEAYAAABPYyMiAAAABmJLR0T///////8JWPfcAAAACXBIWXMAAABIAAAASABGyWs+AAAAF0lEQVRIx2NgGAWjYBSMglEwCkbBSAcACBAAAeaR9cIAAAAASUVORK5CYII=\n")
}

func hello(w http.ResponseWriter, r *http.Request) {
  fmt.Printf("%s\n", r.RequestURI)
  fmt.Fprintln(w, "Hello, World!")
}
```

