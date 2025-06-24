---
title: "使用go编写一个简单的人脸识别服务"
date: 2025-06-24T15:26:06+08:00
draft: false
tags: ["golang"]
author: "czyt"
---

> 需要下载相关的模型 https://github.com/Kagami/go-face-testdata 下面的models

## 代码实现

代码如下

```go
package main

import (
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log"
	"math"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"sync"
	"unsafe"

	"github.com/Kagami/go-face"
	"github.com/gorilla/mux"
)

// FaceData 人脸数据结构
type FaceData struct {
	ID         int    `json:"id"`
	Name       string `json:"name"`
	Descriptor string `json:"descriptor"` // base64编码的特征向量
	ImagePath  string `json:"image_path"` // 图片文件路径
	ImageURL   string `json:"image_url"`  // 图片访问URL
}

// Response 响应结构
type Response struct {
	Success bool        `json:"success"`
	Message string      `json:"message"`
	Data    interface{} `json:"data,omitempty"`
}

// FaceService 人脸识别服务
type FaceService struct {
	recognizer *face.Recognizer
	faceData   map[int]FaceData
	mu         sync.RWMutex
	nextID     int
	// 用于分类的数据
	samples []face.Descriptor
	cats    []int32
	labels  []string
}

// NewFaceService 初始化人脸识别服务
func NewFaceService(modelsDir string) (*FaceService, error) {
	// 初始化人脸识别器
	rec, err := face.NewRecognizer(modelsDir)
	if err != nil {
		return nil, fmt.Errorf("无法初始化人脸识别器: %v", err)
	}

	// 创建图片存储目录
	uploadsDir := "uploads"
	if err := os.MkdirAll(uploadsDir, 0755); err != nil {
		return nil, fmt.Errorf("创建上传目录失败: %v", err)
	}

	return &FaceService{
		recognizer: rec,
		faceData:   make(map[int]FaceData),
		nextID:     1,
		samples:    make([]face.Descriptor, 0),
		cats:       make([]int32, 0),
		labels:     make([]string, 0),
	}, nil
}

// Close 关闭资源
func (fs *FaceService) Close() {
	fs.recognizer.Close()
}

// 将face.Descriptor转换为base64字符串
func descriptorToString(d face.Descriptor) string {
	b := (*[128 * 4]byte)(unsafe.Pointer(&d))
	return base64.StdEncoding.EncodeToString(b[:])
}

// 将base64字符串转换为face.Descriptor
func stringToDescriptor(s string) (face.Descriptor, error) {
	b, err := base64.StdEncoding.DecodeString(s)
	if err != nil {
		return face.Descriptor{}, err
	}
	if len(b) != 128*4 {
		return face.Descriptor{}, fmt.Errorf("invalid descriptor length")
	}
	return *(*face.Descriptor)(unsafe.Pointer(&b[0])), nil
}

// 更新分类器的训练数据
func (fs *FaceService) updateClassifier() {
	fs.samples = make([]face.Descriptor, 0, len(fs.faceData))
	fs.cats = make([]int32, 0, len(fs.faceData))
	fs.labels = make([]string, 0, len(fs.faceData))

	catID := int32(0)
	for _, face := range fs.faceData {
		descriptor, err := stringToDescriptor(face.Descriptor)
		if err != nil {
			continue
		}

		fs.samples = append(fs.samples, descriptor)
		fs.cats = append(fs.cats, catID)
		fs.labels = append(fs.labels, strconv.Itoa(face.ID))
		catID++
	}

	if len(fs.samples) > 0 {
		fs.recognizer.SetSamples(fs.samples, fs.cats)
	}
}

// RegisterFace 人脸登记接口
func (fs *FaceService) RegisterFace(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "只支持POST方法", http.StatusMethodNotAllowed)
		return
	}

	// 解析表单数据
	err := r.ParseMultipartForm(10 << 20) // 10MB最大文件大小
	if err != nil {
		fs.sendResponse(w, false, "解析表单失败", nil)
		return
	}

	// 获取姓名
	name := r.FormValue("name")
	if name == "" {
		fs.sendResponse(w, false, "姓名不能为空", nil)
		return
	}

	// 获取上传的图片文件
	file, handler, err := r.FormFile("image")
	if err != nil {
		fs.sendResponse(w, false, "获取图片文件失败", nil)
		return
	}
	defer file.Close()

	// 生成唯一的文件名
	ext := filepath.Ext(handler.Filename)
	if ext == "" {
		ext = ".jpg" // 默认扩展名
	}

	// 保存到uploads目录，使用ID作为文件名
	uploadsDir := "uploads"
	savedImagePath := filepath.Join(uploadsDir, fmt.Sprintf("face_%d%s", fs.nextID, ext))
	imageURL := fmt.Sprintf("/uploads/face_%d%s", fs.nextID, ext)

	dst, err := os.Create(savedImagePath)
	if err != nil {
		fs.sendResponse(w, false, "保存图片失败", nil)
		return
	}
	defer dst.Close()

	_, err = io.Copy(dst, file)
	if err != nil {
		fs.sendResponse(w, false, "保存图片失败", nil)
		return
	}

	// 使用RecognizeSingleFile进行单人脸识别
	faceRecognizeReult, err := fs.recognizer.RecognizeSingleFile(savedImagePath)
	if err != nil {
		// 如果识别失败，删除已保存的图片
		os.Remove(savedImagePath)
		// 处理具体的错误类型
		var imageLoadError face.ImageLoadError
		switch {
		case errors.As(err, &imageLoadError):
			fs.sendResponse(w, false, "图片格式不支持或已损坏", nil)
		default:
			fs.sendResponse(w, false, "人脸识别失败", nil)
		}
		return
	}

	if faceRecognizeReult == nil {
		// 如果没有检测到人脸，删除已保存的图片
		os.Remove(savedImagePath)
		fs.sendResponse(w, false, "未检测到人脸", nil)
		return
	}

	// 保存人脸数据
	fs.mu.Lock()
	faceData := FaceData{
		ID:         fs.nextID,
		Name:       name,
		Descriptor: descriptorToString(faceRecognizeReult.Descriptor),
		ImagePath:  savedImagePath,
		ImageURL:   imageURL,
	}
	fs.faceData[fs.nextID] = faceData
	fs.nextID++

	// 更新分类器
	fs.updateClassifier()
	fs.mu.Unlock()

	fs.sendResponse(w, true, "人脸登记成功", map[string]interface{}{
		"id":        faceData.ID,
		"name":      faceData.Name,
		"image_url": faceData.ImageURL,
	})
}

// RecognizeFace 人脸识别接口
func (fs *FaceService) RecognizeFace(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "只支持POST方法", http.StatusMethodNotAllowed)
		return
	}

	// 解析表单数据
	err := r.ParseMultipartForm(10 << 20)
	if err != nil {
		fs.sendResponse(w, false, "解析表单失败", nil)
		return
	}

	// 获取阈值参数（可选）
	thresholdStr := r.FormValue("threshold")
	threshold := float32(0.6) // 默认阈值
	if thresholdStr != "" {
		if t, err := strconv.ParseFloat(thresholdStr, 32); err == nil {
			threshold = float32(t)
		}
	}

	// 获取上传的图片文件
	file, handler, err := r.FormFile("image")
	if err != nil {
		fs.sendResponse(w, false, "获取图片文件失败", nil)
		return
	}
	defer file.Close()

	// 保存临时文件
	tempDir := "temp"
	os.MkdirAll(tempDir, 0755)
	tempFile := filepath.Join(tempDir, handler.Filename)

	dst, err := os.Create(tempFile)
	if err != nil {
		fs.sendResponse(w, false, "创建临时文件失败", nil)
		return
	}
	defer dst.Close()
	defer os.Remove(tempFile)

	_, err = io.Copy(dst, file)
	if err != nil {
		fs.sendResponse(w, false, "保存图片失败", nil)
		return
	}

	fs.mu.RLock()
	defer fs.mu.RUnlock()

	if len(fs.faceData) == 0 {
		fs.sendResponse(w, false, "暂无已登记的人脸数据", nil)
		return
	}

	// 使用RecognizeSingleFile进行单人脸识别
	detectedFace, err := fs.recognizer.RecognizeSingleFile(tempFile)
	if err != nil {
		var imageLoadError face.ImageLoadError
		switch {
		case errors.As(err, &imageLoadError):
			fs.sendResponse(w, false, "图片格式不支持或已损坏", nil)
		default:
			fs.sendResponse(w, false, "人脸识别失败", nil)
		}
		return
	}

	if detectedFace == nil {
		fs.sendResponse(w, false, "未检测到人脸", nil)
		return
	}

	// 使用分类器进行识别
	catID := fs.recognizer.ClassifyThreshold(detectedFace.Descriptor, threshold)

	if catID < 0 {
		fs.sendResponse(w, false, "未找到匹配的人脸", nil)
		return
	}

	// 获取识别结果
	if catID >= len(fs.labels) {
		fs.sendResponse(w, false, "分类结果无效", nil)
		return
	}

	faceIDStr := fs.labels[catID]
	faceID, err := strconv.Atoi(faceIDStr)
	if err != nil {
		fs.sendResponse(w, false, "解析人脸ID失败", nil)
		return
	}

	matchedFace, exists := fs.faceData[faceID]
	if !exists {
		fs.sendResponse(w, false, "匹配的人脸数据不存在", nil)
		return
	}

	// 计算相似度
	matchedDescriptor, err := stringToDescriptor(matchedFace.Descriptor)
	if err != nil {
		fs.sendResponse(w, false, "解析人脸特征失败", nil)
		return
	}

	distance := fs.calculateDistance(detectedFace.Descriptor, matchedDescriptor)
	confidence := (1 - distance) * 100
	if confidence < 0 {
		confidence = 0
	}

	fs.sendResponse(w, true, "人脸识别成功", map[string]interface{}{
		"id":         matchedFace.ID,
		"name":       matchedFace.Name,
		"confidence": fmt.Sprintf("%.2f%%", confidence),
		"distance":   fmt.Sprintf("%.4f", distance),
	})
}

// 计算两个人脸特征向量之间的欧几里得距离
func (fs *FaceService) calculateDistance(desc1, desc2 face.Descriptor) float32 {
	var sum float64
	for i := 0; i < len(desc1); i++ {
		diff := float64(desc1[i] - desc2[i])
		sum += diff * diff
	}
	return float32(math.Sqrt(sum))
}

// GetFaceList 获取所有已登记人脸列表
func (fs *FaceService) GetFaceList(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "只支持GET方法", http.StatusMethodNotAllowed)
		return
	}

	fs.mu.RLock()
	defer fs.mu.RUnlock()

	var faceList []map[string]interface{}
	for _, face := range fs.faceData {
		faceList = append(faceList, map[string]interface{}{
			"id":        face.ID,
			"name":      face.Name,
			"image_url": face.ImageURL,
		})
	}

	fs.sendResponse(w, true, "获取成功", faceList)
}

// DeleteFace 删除已登记人脸
func (fs *FaceService) DeleteFace(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodDelete {
		http.Error(w, "只支持DELETE方法", http.StatusMethodNotAllowed)
		return
	}

	vars := mux.Vars(r)
	idStr := vars["id"]
	id, err := strconv.Atoi(idStr)
	if err != nil {
		fs.sendResponse(w, false, "无效的ID", nil)
		return
	}

	fs.mu.Lock()
	defer fs.mu.Unlock()

	faceData, exists := fs.faceData[id]
	if !exists {
		fs.sendResponse(w, false, "人脸数据不存在", nil)
		return
	}

	// 删除图片文件
	if faceData.ImagePath != "" {
		if err := os.Remove(faceData.ImagePath); err != nil {
			log.Printf("删除图片文件失败: %v", err)
		}
	}

	// 删除数据
	delete(fs.faceData, id)

	// 更新分类器
	fs.updateClassifier()

	fs.sendResponse(w, true, "删除成功", nil)
}

// RecognizeMultipleFaces 批量识别接口（处理多人脸图片）
func (fs *FaceService) RecognizeMultipleFaces(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "只支持POST方法", http.StatusMethodNotAllowed)
		return
	}

	// 解析表单数据
	err := r.ParseMultipartForm(10 << 20)
	if err != nil {
		fs.sendResponse(w, false, "解析表单失败", nil)
		return
	}

	// 获取阈值参数（可选）
	thresholdStr := r.FormValue("threshold")
	threshold := float32(0.6) // 默认阈值
	if thresholdStr != "" {
		if t, err := strconv.ParseFloat(thresholdStr, 32); err == nil {
			threshold = float32(t)
		}
	}

	// 获取上传的图片文件
	file, handler, err := r.FormFile("image")
	if err != nil {
		fs.sendResponse(w, false, "获取图片文件失败", nil)
		return
	}
	defer file.Close()

	// 保存临时文件
	tempDir := "temp"
	os.MkdirAll(tempDir, 0755)
	tempFile := filepath.Join(tempDir, handler.Filename)

	dst, err := os.Create(tempFile)
	if err != nil {
		fs.sendResponse(w, false, "创建临时文件失败", nil)
		return
	}
	defer dst.Close()
	defer os.Remove(tempFile)

	_, err = io.Copy(dst, file)
	if err != nil {
		fs.sendResponse(w, false, "保存图片失败", nil)
		return
	}

	fs.mu.RLock()
	defer fs.mu.RUnlock()

	if len(fs.faceData) == 0 {
		fs.sendResponse(w, false, "暂无已登记的人脸数据", nil)
		return
	}

	// 识别图片中的所有人脸
	faces, err := fs.recognizer.RecognizeFile(tempFile)
	if err != nil {
		var imageLoadError face.ImageLoadError
		switch {
		case errors.As(err, &imageLoadError):
			fs.sendResponse(w, false, "图片格式不支持或已损坏", nil)
		default:
			fs.sendResponse(w, false, "人脸识别失败", nil)
		}
		return
	}

	if len(faces) == 0 {
		fs.sendResponse(w, false, "未检测到人脸", nil)
		return
	}

	// 识别每个人脸
	var results []map[string]interface{}
	for i, detectedFace := range faces {
		result := map[string]interface{}{
			"face_index": i,
			"rectangle": map[string]interface{}{
				"left":   detectedFace.Rectangle.Min.X,
				"top":    detectedFace.Rectangle.Min.Y,
				"right":  detectedFace.Rectangle.Max.X,
				"bottom": detectedFace.Rectangle.Max.Y,
			},
		}

		// 使用分类器进行识别
		catID := fs.recognizer.ClassifyThreshold(detectedFace.Descriptor, threshold)

		if catID >= 0 && catID < len(fs.labels) {
			faceIDStr := fs.labels[catID]
			faceID, err := strconv.Atoi(faceIDStr)
			if err == nil {
				if matchedFace, exists := fs.faceData[faceID]; exists {
					// 计算相似度
					matchedDescriptor, err := stringToDescriptor(matchedFace.Descriptor)
					if err == nil {
						distance := fs.calculateDistance(detectedFace.Descriptor, matchedDescriptor)
						confidence := (1 - distance) * 100
						if confidence < 0 {
							confidence = 0
						}

						result["recognized"] = true
						result["id"] = matchedFace.ID
						result["name"] = matchedFace.Name
						result["confidence"] = fmt.Sprintf("%.2f%%", confidence)
						result["distance"] = fmt.Sprintf("%.4f", distance)
					}
				}
			}
		}

		if _, exists := result["recognized"]; !exists {
			result["recognized"] = false
			result["message"] = "未找到匹配的人脸"
		}

		results = append(results, result)
	}

	fs.sendResponse(w, true, fmt.Sprintf("检测到%d张人脸", len(faces)), results)
}

// 发送JSON响应
func (fs *FaceService) sendResponse(w http.ResponseWriter, success bool, message string, data interface{}) {
	w.Header().Set("Content-Type", "application/json")

	response := Response{
		Success: success,
		Message: message,
		Data:    data,
	}

	if !success {
		w.WriteHeader(http.StatusBadRequest)
	}

	json.NewEncoder(w).Encode(response)
}

func main() {
	// 从命令行参数获取模型路径，默认为"models"
	modelsDir := "models"
	if len(os.Args) > 1 {
		modelsDir = os.Args[1]
	}

	// 初始化人脸识别服务
	faceService, err := NewFaceService(modelsDir)
	if err != nil {
		log.Fatal("初始化人脸识别服务失败:", err)
	}
	defer faceService.Close()

	// 创建路由
	r := mux.NewRouter()

	// API路由
	api := r.PathPrefix("/api/v1").Subrouter()
	api.HandleFunc("/face/register", faceService.RegisterFace).Methods("POST")
	api.HandleFunc("/face/recognize", faceService.RecognizeFace).Methods("POST")
	api.HandleFunc("/face/recognize-multiple", faceService.RecognizeMultipleFaces).Methods("POST")
	api.HandleFunc("/face/list", faceService.GetFaceList).Methods("GET")
	api.HandleFunc("/face/{id}", faceService.DeleteFace).Methods("DELETE")

	// 静态文件服务 - 提供图片访问
	r.PathPrefix("/uploads/").Handler(http.StripPrefix("/uploads/", http.FileServer(http.Dir("uploads/"))))

	// 添加CORS支持
	r.Use(func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			w.Header().Set("Access-Control-Allow-Origin", "*")
			w.Header().Set("Access-Control-Allow-Methods", "GET, POST, DELETE, OPTIONS")
			w.Header().Set("Access-Control-Allow-Headers", "Content-Type")

			if r.Method == "OPTIONS" {
				w.WriteHeader(http.StatusOK)
				return
			}

			next.ServeHTTP(w, r)
		})
	})

	port := ":8080"
	fmt.Printf("人脸识别服务启动在端口 %s\n", port)
	fmt.Printf("模型路径: %s\n", modelsDir)
	fmt.Println("API接口:")
	fmt.Println("POST /api/v1/face/register - 人脸登记")
	fmt.Println("POST /api/v1/face/recognize - 单人脸识别")
	fmt.Println("POST /api/v1/face/recognize-multiple - 多人脸识别")
	fmt.Println("GET  /api/v1/face/list - 获取人脸列表")
	fmt.Println("DELETE /api/v1/face/{id} - 删除人脸")

	log.Fatal(http.ListenAndServe(port, r))
}

```

## 用到的数学方法

上面的代码用到了欧几里得距离计算公式解析，下面内容来自AI

### 基本概念

欧几里得距离（Euclidean Distance）是衡量两个点在多维空间中实际距离的最常用方法。在人脸识别领域，我们用它来计算两个人脸特征向量（通常是128维或更高维）之间的相似度。

### 公式表达

在n维空间中，两点$p$和$q$之间的欧几里得距离公式为：

$$
d(p,q) = \sqrt{\sum_{i=1}^{n}(p_i - q_i)^2}
$$

其中：
- $p$ 和 $q$ 是两个特征向量
- $p_i$ 和 $q_i$ 分别是向量$p$和$q$在第$i$个维度的值
- $n$ 是特征向量的维度数

#### 在人脸识别中的具体应用

在人脸识别领域，我们处理的是128维的特征向量（由dlib的ResNet模型生成），所以公式变为：

$$
distance = \sqrt{\sum_{i=0}^{127}(d1_i - d2_i)^2}
$$

其中：
- $d1$ 和 $d2$ 是两个128维的人脸特征向量
- $d1_i$ 和 $d2_i$ 是向量在维度$i$上的值

### 相似度转换

在实现中，我们通常会将距离转换为更直观的相似度百分比：

$$
similarity = (1 - \frac{distance}{max\_possible}) \times 100\%
$$

但在实践中，由于dlib模型的特性，我们更常使用：

$$
confidence = (1 - distance) \times 100\%
$$

这里需要注意：
1. 当$distance > 1$时，$confidence$会变为负数
2. 因此我们在实际应用中会将其限制为0：
```go
if confidence < 0 {
    confidence = 0
}
```

### 阈值设置

| 阈值水平     | 距离范围       | 置信度范围       | 识别结果                 |
| ------------ | -------------- | ---------------- | ------------------------ |
| 非常严格     | distance < 0.3 | confidence > 70% | 几乎可以确定是同一人     |
| 严格         | distance < 0.4 | confidence > 60% | 高度可能是同一人         |
| 正常（默认） | distance < 0.6 | confidence > 40% | 可能是同一人             |
| 宽松         | distance < 0.8 | confidence > 20% | 可能是同一人（但误差大） |
| 非常宽松     | distance < 1.0 | confidence > 0%  | 不可靠的匹配             |

### 实际应用代码

```go
// 计算两个人脸特征向量之间的欧几里得距离
func calculateDistance(desc1, desc2 face.Descriptor) float32 {
    var sum float64
    for i := 0; i < len(desc1); i++ {
        diff := float64(desc1[i] - desc2[i])
        sum += diff * diff
    }
    return float32(math.Sqrt(sum))
}

// 距离转换为相似度百分比
func distanceToConfidence(distance float32) float32 {
    confidence := (1 - distance) * 100
    if confidence < 0 {
        return 0
    }
    return confidence
}
```

### 数学特性

1. **非负性**：$distance \geqslant 0$
2. **同一性**：$d(x,y) = 0$ 当且仅当 $x = y$
3. **对称性**：$d(x,y) = d(y,x)$
4. **三角不等式**：$d(x,z) \leqslant d(x,y) + d(y,z)$

### 性能优化考虑

1. **平方距离替代**：可以只计算平方和而不开方以提升性能：
   $$ squaredDistance = \sum_{i=0}^{127}(d1_i - d2_i)^2 $$

2. **距离提前终止**：在遍历计算过程中，如果部分和已超过阈值，可提前终止计算

3. **向量化计算**：使用SIMD指令并行处理多个维度计算（在Go中可使用`gorgonia`等库）

### 与其他距离度量的对比

| 度量方式     | 公式                        | 特点               | 适用场景           |
| ------------ | --------------------------- | ------------------ | ------------------ |
| 欧几里得距离 | $\sqrt{\sum(p_i-q_i)^2}$    | 直观性强，计算简单 | 人脸识别，图像检索 |
| 余弦相似度   | $\frac{p·q}{\|p\|\|q\|}$    | 关注方向而非大小   | 文本分析，高维空间 |
| 曼哈顿距离   | $\sum\|p_i-q_i\|$           | 计算成本低         | 网格路径规划       |
| 马氏距离     | $\sqrt{(p-q)^TΣ^{-1}(p-q)}$ | 考虑特征相关性     | 统计分类           |
