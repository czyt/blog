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
	"time"
	"unsafe"

	"github.com/Kagami/go-face"
	"github.com/gorilla/mux"
)

// Config 配置结构
type Config struct {
	Port           string  `json:"port"`
	ModelsDir      string  `json:"models_dir"`
	UploadsDir     string  `json:"uploads_dir"`
	TempDir        string  `json:"temp_dir"`
	DataFile       string  `json:"data_file"`
	MaxFileSize    int64   `json:"max_file_size"`
	DefaultThreshold float32 `json:"default_threshold"`
	LogLevel       string  `json:"log_level"`
}

// Person 人员结构（支持多样本）
type Person struct {
	ID       int           `json:"id"`
	Name     string        `json:"name"`
	Samples  []FaceSample  `json:"samples"`
	Created  time.Time     `json:"created"`
	Updated  time.Time     `json:"updated"`
}

// FaceSample 人脸样本
type FaceSample struct {
	ID         int    `json:"id"`
	PersonID   int    `json:"person_id"`
	Descriptor string `json:"descriptor"` // base64编码的特征向量
	ImagePath  string `json:"image_path"`
	ImageURL   string `json:"image_url"`
	Quality    float32 `json:"quality"`    // 人脸质量评分
	Created    time.Time `json:"created"`
}

// RecognitionResult 识别结果
type RecognitionResult struct {
	PersonID   int     `json:"person_id"`
	PersonName string  `json:"person_name"`
	Confidence float32 `json:"confidence"`
	Distance   float32 `json:"distance"`
	SampleID   int     `json:"sample_id"`
}

// FaceDetection 人脸检测结果
type FaceDetection struct {
	Index      int                `json:"index"`
	Rectangle  map[string]int     `json:"rectangle"`
	Recognized bool               `json:"recognized"`
	Result     *RecognitionResult `json:"result,omitempty"`
	Message    string             `json:"message,omitempty"`
}

// Response 通用响应结构
type Response struct {
	Success   bool        `json:"success"`
	Message   string      `json:"message"`
	Data      interface{} `json:"data,omitempty"`
	Timestamp time.Time   `json:"timestamp"`
}

// Statistics 统计信息
type Statistics struct {
	TotalPersons     int `json:"total_persons"`
	TotalSamples     int `json:"total_samples"`
	RecognitionCount int `json:"recognition_count"`
	RegistrationCount int `json:"registration_count"`
}

// FaceService 人脸识别服务
type FaceService struct {
	config     *Config
	recognizer *face.Recognizer
	persons    map[int]*Person
	samples    map[int]*FaceSample
	mu         sync.RWMutex
	nextPersonID int
	nextSampleID int
	stats      Statistics
	
	// 用于分类的数据
	classifierSamples []face.Descriptor
	classifierCats    []int32
	classifierLabels  []string
}

// NewFaceService 初始化人脸识别服务
func NewFaceService(config *Config) (*FaceService, error) {
	// 初始化人脸识别器
	rec, err := face.NewRecognizer(config.ModelsDir)
	if err != nil {
		return nil, fmt.Errorf("无法初始化人脸识别器: %v", err)
	}

	// 创建必要的目录
	dirs := []string{config.UploadsDir, config.TempDir}
	for _, dir := range dirs {
		if err := os.MkdirAll(dir, 0755); err != nil {
			return nil, fmt.Errorf("创建目录 %s 失败: %v", dir, err)
		}
	}

	fs := &FaceService{
		config:     config,
		recognizer: rec,
		persons:    make(map[int]*Person),
		samples:    make(map[int]*FaceSample),
		nextPersonID: 1,
		nextSampleID: 1,
		classifierSamples: make([]face.Descriptor, 0),
		classifierCats:    make([]int32, 0),
		classifierLabels:  make([]string, 0),
	}

	// 加载已保存的数据
	if err := fs.loadData(); err != nil {
		log.Printf("加载数据失败: %v", err)
	}

	return fs, nil
}

// Close 关闭资源
func (fs *FaceService) Close() {
	fs.recognizer.Close()
}

// 数据持久化相关方法
func (fs *FaceService) saveData() error {
	fs.mu.RLock()
	defer fs.mu.RUnlock()

	data := struct {
		Persons      map[int]*Person      `json:"persons"`
		Samples      map[int]*FaceSample  `json:"samples"`
		NextPersonID int                  `json:"next_person_id"`
		NextSampleID int                  `json:"next_sample_id"`
		Stats        Statistics           `json:"stats"`
	}{
		Persons:      fs.persons,
		Samples:      fs.samples,
		NextPersonID: fs.nextPersonID,
		NextSampleID: fs.nextSampleID,
		Stats:        fs.stats,
	}

	file, err := os.Create(fs.config.DataFile)
	if err != nil {
		return err
	}
	defer file.Close()

	encoder := json.NewEncoder(file)
	encoder.SetIndent("", "  ")
	return encoder.Encode(data)
}

func (fs *FaceService) loadData() error {
	if _, err := os.Stat(fs.config.DataFile); os.IsNotExist(err) {
		return nil // 文件不存在，使用默认值
	}

	file, err := os.Open(fs.config.DataFile)
	if err != nil {
		return err
	}
	defer file.Close()

	var data struct {
		Persons      map[int]*Person      `json:"persons"`
		Samples      map[int]*FaceSample  `json:"samples"`
		NextPersonID int                  `json:"next_person_id"`
		NextSampleID int                  `json:"next_sample_id"`
		Stats        Statistics           `json:"stats"`
	}

	if err := json.NewDecoder(file).Decode(&data); err != nil {
		return err
	}

	fs.mu.Lock()
	fs.persons = data.Persons
	fs.samples = data.Samples
	fs.nextPersonID = data.NextPersonID
	fs.nextSampleID = data.NextSampleID
	fs.stats = data.Stats
	fs.mu.Unlock()

	// 重建分类器
	fs.updateClassifier()

	log.Printf("加载数据成功: %d个人员, %d个样本", len(fs.persons), len(fs.samples))
	return nil
}

// 特征向量转换方法
func descriptorToString(d face.Descriptor) string {
	b := (*[128 * 4]byte)(unsafe.Pointer(&d))
	return base64.StdEncoding.EncodeToString(b[:])
}

func stringToDescriptor(s string) (face.Descriptor, error) {
	b, err := base64.StdEncoding.DecodeString(s)
	if err != nil {
		return face.Descriptor{}, err
	}
	if len(b) != 128*4 {
		return face.Descriptor{}, fmt.Errorf("invalid descriptor length: %d", len(b))
	}
	return *(*face.Descriptor)(unsafe.Pointer(&b[0])), nil
}

// 计算人脸质量评分（简单实现）
func (fs *FaceService) calculateFaceQuality(faceData face.Face) float32 {
	// 基于人脸区域大小和位置计算质量评分
	rect := faceData.Rectangle
	width := rect.Max.X - rect.Min.X
	height := rect.Max.Y - rect.Min.Y
	area := width * height
	
	// 面积越大，质量越高（简化评分）
	quality := float32(area) / 10000.0
	if quality > 1.0 {
		quality = 1.0
	}
	
	return quality
}

// 更新分类器
func (fs *FaceService) updateClassifier() {
	fs.classifierSamples = make([]face.Descriptor, 0)
	fs.classifierCats = make([]int32, 0)
	fs.classifierLabels = make([]string, 0)

	catID := int32(0)
	for _, person := range fs.persons {
		for _, sample := range person.Samples {
			descriptor, err := stringToDescriptor(sample.Descriptor)
			if err != nil {
				log.Printf("解析样本 %d 的特征向量失败: %v", sample.ID, err)
				continue
			}

			fs.classifierSamples = append(fs.classifierSamples, descriptor)
			fs.classifierCats = append(fs.classifierCats, catID)
			fs.classifierLabels = append(fs.classifierLabels, fmt.Sprintf("%d:%d", person.ID, sample.ID))
			catID++
		}
	}

	if len(fs.classifierSamples) > 0 {
		fs.recognizer.SetSamples(fs.classifierSamples, fs.classifierCats)
		log.Printf("分类器更新完成: %d个样本", len(fs.classifierSamples))
	}
}

// RegisterPerson 人员登记接口
func (fs *FaceService) RegisterPerson(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		fs.sendErrorResponse(w, "只支持POST方法", http.StatusMethodNotAllowed)
		return
	}

	// 解析表单数据
	err := r.ParseMultipartForm(fs.config.MaxFileSize)
	if err != nil {
		fs.sendErrorResponse(w, "解析表单失败", http.StatusBadRequest)
		return
	}

	// 获取姓名
	name := r.FormValue("name")
	if name == "" {
		fs.sendErrorResponse(w, "姓名不能为空", http.StatusBadRequest)
		return
	}

	// 检查姓名是否已存在
	fs.mu.RLock()
	for _, person := range fs.persons {
		if person.Name == name {
			fs.mu.RUnlock()
			fs.sendErrorResponse(w, "该姓名已存在", http.StatusConflict)
			return
		}
	}
	fs.mu.RUnlock()

	// 获取上传的图片文件
	file, handler, err := r.FormFile("image")
	if err != nil {
		fs.sendErrorResponse(w, "获取图片文件失败", http.StatusBadRequest)
		return
	}
	defer file.Close()

	// 处理图片并创建样本
	sample, err := fs.processImageFile(file, handler, 0) // personID为0，稍后更新
	if err != nil {
		fs.sendErrorResponse(w, err.Error(), http.StatusBadRequest)
		return
	}

	// 创建人员记录
	fs.mu.Lock()
	person := &Person{
		ID:      fs.nextPersonID,
		Name:    name,
		Samples: []FaceSample{*sample},
		Created: time.Now(),
		Updated: time.Now(),
	}
	
	// 更新样本的人员ID
	sample.PersonID = person.ID
	
	fs.persons[person.ID] = person
	fs.samples[sample.ID] = sample
	fs.nextPersonID++
	fs.stats.TotalPersons++
	fs.stats.TotalSamples++
	fs.stats.RegistrationCount++
	
	// 更新分类器
	fs.updateClassifier()
	fs.mu.Unlock()

	// 保存数据
	go fs.saveData()

	fs.sendSuccessResponse(w, "人员登记成功", map[string]interface{}{
		"person_id":  person.ID,
		"name":       person.Name,
		"sample_id":  sample.ID,
		"image_url":  sample.ImageURL,
		"quality":    sample.Quality,
	})
}

// AddSample 为已存在人员添加样本
func (fs *FaceService) AddSample(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		fs.sendErrorResponse(w, "只支持POST方法", http.StatusMethodNotAllowed)
		return
	}

	vars := mux.Vars(r)
	personIDStr := vars["person_id"]
	personID, err := strconv.Atoi(personIDStr)
	if err != nil {
		fs.sendErrorResponse(w, "无效的人员ID", http.StatusBadRequest)
		return
	}

	// 检查人员是否存在
	fs.mu.RLock()
	person, exists := fs.persons[personID]
	if !exists {
		fs.mu.RUnlock()
		fs.sendErrorResponse(w, "人员不存在", http.StatusNotFound)
		return
	}
	fs.mu.RUnlock()

	// 解析表单数据
	err = r.ParseMultipartForm(fs.config.MaxFileSize)
	if err != nil {
		fs.sendErrorResponse(w, "解析表单失败", http.StatusBadRequest)
		return
	}

	// 获取上传的图片文件
	file, handler, err := r.FormFile("image")
	if err != nil {
		fs.sendErrorResponse(w, "获取图片文件失败", http.StatusBadRequest)
		return
	}
	defer file.Close()

	// 处理图片并创建样本
	sample, err := fs.processImageFile(file, handler, personID)
	if err != nil {
		fs.sendErrorResponse(w, err.Error(), http.StatusBadRequest)
		return
	}

	// 添加样本
	fs.mu.Lock()
	person.Samples = append(person.Samples, *sample)
	person.Updated = time.Now()
	fs.samples[sample.ID] = sample
	fs.stats.TotalSamples++
	
	// 更新分类器
	fs.updateClassifier()
	fs.mu.Unlock()

	// 保存数据
	go fs.saveData()

	fs.sendSuccessResponse(w, "样本添加成功", map[string]interface{}{
		"person_id": personID,
		"sample_id": sample.ID,
		"image_url": sample.ImageURL,
		"quality":   sample.Quality,
		"total_samples": len(person.Samples),
	})
}

// processImageFile 处理上传的图片文件
func (fs *FaceService) processImageFile(file io.Reader, handler *multipart.FileHeader, personID int) (*FaceSample, error) {
	// 生成文件名
	ext := filepath.Ext(handler.Filename)
	if ext == "" {
		ext = ".jpg"
	}

	fs.mu.Lock()
	sampleID := fs.nextSampleID
	fs.nextSampleID++
	fs.mu.Unlock()

	savedImagePath := filepath.Join(fs.config.UploadsDir, fmt.Sprintf("sample_%d%s", sampleID, ext))
	imageURL := fmt.Sprintf("/uploads/sample_%d%s", sampleID, ext)

	// 保存图片文件
	dst, err := os.Create(savedImagePath)
	if err != nil {
		return nil, fmt.Errorf("保存图片失败: %v", err)
	}
	defer dst.Close()

	_, err = io.Copy(dst, file)
	if err != nil {
		os.Remove(savedImagePath)
		return nil, fmt.Errorf("保存图片失败: %v", err)
	}

	// 人脸识别
	faceResult, err := fs.recognizer.RecognizeSingleFile(savedImagePath)
	if err != nil {
		os.Remove(savedImagePath)
		var imageLoadError face.ImageLoadError
		if errors.As(err, &imageLoadError) {
			return nil, fmt.Errorf("图片格式不支持或已损坏")
		}
		return nil, fmt.Errorf("人脸识别失败: %v", err)
	}

	if faceResult == nil {
		os.Remove(savedImagePath)
		return nil, fmt.Errorf("未检测到人脸")
	}

	// 计算人脸质量
	quality := fs.calculateFaceQuality(*faceResult)

	// 创建样本
	sample := &FaceSample{
		ID:         sampleID,
		PersonID:   personID,
		Descriptor: descriptorToString(faceResult.Descriptor),
		ImagePath:  savedImagePath,
		ImageURL:   imageURL,
		Quality:    quality,
		Created:    time.Now(),
	}

	return sample, nil
}

// RecognizeFace 人脸识别接口
func (fs *FaceService) RecognizeFace(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		fs.sendErrorResponse(w, "只支持POST方法", http.StatusMethodNotAllowed)
		return
	}

	// 解析表单数据
	err := r.ParseMultipartForm(fs.config.MaxFileSize)
	if err != nil {
		fs.sendErrorResponse(w, "解析表单失败", http.StatusBadRequest)
		return
	}

	// 获取阈值参数
	threshold := fs.config.DefaultThreshold
	if thresholdStr := r.FormValue("threshold"); thresholdStr != "" {
		if t, err := strconv.ParseFloat(thresholdStr, 32); err == nil {
			threshold = float32(t)
		}
	}

	// 处理上传的图片
	tempFile, err := fs.saveTemporaryFile(r)
	if err != nil {
		fs.sendErrorResponse(w, err.Error(), http.StatusBadRequest)
		return
	}
	defer os.Remove(tempFile)

	fs.mu.RLock()
	if len(fs.persons) == 0 {
		fs.mu.RUnlock()
		fs.sendErrorResponse(w, "暂无已登记的人脸数据", http.StatusBadRequest)
		return
	}
	fs.mu.RUnlock()

	// 识别人脸
	detectedFace, err := fs.recognizer.RecognizeSingleFile(tempFile)
	if err != nil {
		var imageLoadError face.ImageLoadError
		if errors.As(err, &imageLoadError) {
			fs.sendErrorResponse(w, "图片格式不支持或已损坏", http.StatusBadRequest)
		} else {
			fs.sendErrorResponse(w, "人脸识别失败", http.StatusInternalServerError)
		}
		return
	}

	if detectedFace == nil {
		fs.sendErrorResponse(w, "未检测到人脸", http.StatusBadRequest)
		return
	}

	// 执行分类
	result := fs.classifyFace(detectedFace.Descriptor, threshold)
	
	fs.mu.Lock()
	fs.stats.RecognitionCount++
	fs.mu.Unlock()
	
	go fs.saveData()

	if result == nil {
		fs.sendSuccessResponse(w, "未找到匹配的人脸", map[string]interface{}{
			"recognized": false,
		})
	} else {
		fs.sendSuccessResponse(w, "人脸识别成功", map[string]interface{}{
			"recognized": true,
			"result":     result,
		})
	}
}

// RecognizeMultipleFaces 多人脸识别接口
func (fs *FaceService) RecognizeMultipleFaces(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		fs.sendErrorResponse(w, "只支持POST方法", http.StatusMethodNotAllowed)
		return
	}

	// 解析表单数据
	err := r.ParseMultipartForm(fs.config.MaxFileSize)
	if err != nil {
		fs.sendErrorResponse(w, "解析表单失败", http.StatusBadRequest)
		return
	}

	// 获取阈值参数
	threshold := fs.config.DefaultThreshold
	if thresholdStr := r.FormValue("threshold"); thresholdStr != "" {
		if t, err := strconv.ParseFloat(thresholdStr, 32); err == nil {
			threshold = float32(t)
		}
	}

	// 处理上传的图片
	tempFile, err := fs.saveTemporaryFile(r)
	if err != nil {
		fs.sendErrorResponse(w, err.Error(), http.StatusBadRequest)
		return
	}
	defer os.Remove(tempFile)

	fs.mu.RLock()
	if len(fs.persons) == 0 {
		fs.mu.RUnlock()
		fs.sendErrorResponse(w, "暂无已登记的人脸数据", http.StatusBadRequest)
		return
	}
	fs.mu.RUnlock()

	// 识别所有人脸
	faces, err := fs.recognizer.RecognizeFile(tempFile)
	if err != nil {
		var imageLoadError face.ImageLoadError
		if errors.As(err, &imageLoadError) {
			fs.sendErrorResponse(w, "图片格式不支持或已损坏", http.StatusBadRequest)
		} else {
			fs.sendErrorResponse(w, "人脸识别失败", http.StatusInternalServerError)
		}
		return
	}

	if len(faces) == 0 {
		fs.sendErrorResponse(w, "未检测到人脸", http.StatusBadRequest)
		return
	}

	// 处理每个检测到的人脸
	var detections []FaceDetection
	for i, detectedFace := range faces {
		detection := FaceDetection{
			Index: i,
			Rectangle: map[string]int{
				"left":   detectedFace.Rectangle.Min.X,
				"top":    detectedFace.Rectangle.Min.Y,
				"right":  detectedFace.Rectangle.Max.X,
				"bottom": detectedFace.Rectangle.Max.Y,
			},
		}

		// 尝试识别
		result := fs.classifyFace(detectedFace.Descriptor, threshold)
		if result != nil {
			detection.Recognized = true
			detection.Result = result
		} else {
			detection.Recognized = false
			detection.Message = "未找到匹配的人脸"
		}

		detections = append(detections, detection)
	}

	fs.mu.Lock()
	fs.stats.RecognitionCount++
	fs.mu.Unlock()
	
	go fs.saveData()

	fs.sendSuccessResponse(w, fmt.Sprintf("检测到%d张人脸", len(faces)), detections)
}

// classifyFace 分类人脸
func (fs *FaceService) classifyFace(descriptor face.Descriptor, threshold float32) *RecognitionResult {
	fs.mu.RLock()
	defer fs.mu.RUnlock()

	if len(fs.classifierSamples) == 0 {
		return nil
	}

	catID := fs.recognizer.ClassifyThreshold(descriptor, threshold)
	if catID < 0 || catID >= len(fs.classifierLabels) {
		return nil
	}

	// 解析标签（格式：personID:sampleID）
	label := fs.classifierLabels[catID]
	var personID, sampleID int
	if n, err := fmt.Sscanf(label, "%d:%d", &personID, &sampleID); n != 2 || err != nil {
		return nil
	}

	person, personExists := fs.persons[personID]
	sample, sampleExists := fs.samples[sampleID]
	if !personExists || !sampleExists {
		return nil
	}

	// 计算相似度
	sampleDescriptor, err := stringToDescriptor(sample.Descriptor)
	if err != nil {
		return nil
	}

	distance := fs.calculateDistance(descriptor, sampleDescriptor)
	confidence := (1 - distance) * 100
	if confidence < 0 {
		confidence = 0
	}

	return &RecognitionResult{
		PersonID:   person.ID,
		PersonName: person.Name,
		Confidence: confidence,
		Distance:   distance,
		SampleID:   sample.ID,
	}
}

// calculateDistance 计算欧几里得距离
func (fs *FaceService) calculateDistance(desc1, desc2 face.Descriptor) float32 {
	var sum float64
	for i := 0; i < len(desc1); i++ {
		diff := float64(desc1[i] - desc2[i])
		sum += diff * diff
	}
	return float32(math.Sqrt(sum))
}

// saveTemporaryFile 保存临时文件
func (fs *FaceService) saveTemporaryFile(r *http.Request) (string, error) {
	file, handler, err := r.FormFile("image")
	if err != nil {
		return "", fmt.Errorf("获取图片文件失败: %v", err)
	}
	defer file.Close()

	tempFile := filepath.Join(fs.config.TempDir, fmt.Sprintf("temp_%d_%s", time.Now().UnixNano(), handler.Filename))
	
	dst, err := os.Create(tempFile)
	if err != nil {
		return "", fmt.Errorf("创建临时文件失败: %v", err)
	}
	defer dst.Close()

	_, err = io.Copy(dst, file)
	if err != nil {
		os.Remove(tempFile)
		return "", fmt.Errorf("保存图片失败: %v", err)
	}

	return tempFile, nil
}

// GetPersonList 获取人员列表
func (fs *FaceService) GetPersonList(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		fs.sendErrorResponse(w, "只支持GET方法", http.StatusMethodNotAllowed)
		return
	}

	fs.mu.RLock()
	defer fs.mu.RUnlock()

	var personList []map[string]interface{}
	for _, person := range fs.persons {
		personInfo := map[string]interface{}{
			"id":           person.ID,
			"name":         person.Name,
			"sample_count": len(person.Samples),
			"created":      person.Created,
			"updated":      person.Updated,
		}

		// 添加样本信息
		var samples []map[string]interface{}
		for _, sample := range person.Samples {
			samples = append(samples, map[string]interface{}{
				"id":        sample.ID,
				"image_url": sample.ImageURL,
				"quality":   sample.Quality,
				"created":   sample.Created,
			})
		}
		personInfo["samples"] = samples

		personList = append(personList, personInfo)
	}

	fs.sendSuccessResponse(w, "获取成功", personList)
}

// DeletePerson 删除人员
func (fs *FaceService) DeletePerson(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodDelete {
		fs.sendErrorResponse(w, "只支持DELETE方法", http.StatusMethodNotAllowed)
		return
	}

	vars := mux.Vars(r)
	personIDStr := vars["person_id"]
	personID, err := strconv.Atoi(personIDStr)
	if err != nil {
		fs.sendErrorResponse(w, "无效的人员ID", http.StatusBadRequest)
		return
	}

	fs.mu.Lock()
	defer fs.mu.Unlock()

	person, exists := fs.persons[personID]
	if !exists {
		fs.sendErrorResponse(w, "人员不存在", http.StatusNotFound)
		return
	}

	// 删除所有样本文件和数据
	for _, sample := range person.Samples {
		if sample.ImagePath != "" {
			if err := os.Remove(sample.ImagePath); err != nil {
				log.Printf("删除图片文件失败: %v", err)
			}
		}
		delete(fs.samples, sample.ID)
		fs.stats.TotalSamples--
	}

	// 删除人员数据
	delete(fs.persons, personID)
	fs.stats.TotalPersons--

	// 更新分类器
	fs.updateClassifier()

	// 保存数据
	go fs.saveData()

	fs.sendSuccessResponse(w, "删除成功", nil)
}

// DeleteSample 删除样本
func (fs *FaceService) DeleteSample(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodDelete {
		fs.sendErrorResponse(w, "只支持DELETE方法", http.StatusMethodNotAllowed)
		return
	}

	vars := mux.Vars(r)
	sampleIDStr := vars["sample_id"]
	sampleID, err := strconv.Atoi(sampleIDStr)
	if err != nil {
		fs.sendErrorResponse(w, "无效的样本ID", http.StatusBadRequest)
		return
	}

	fs.mu.Lock()
	defer fs.mu.Unlock()

	sample, exists := fs.samples[sampleID]
	if !exists {
		fs.sendErrorResponse(w, "样本不存在", http.StatusNotFound)
		return
	}

	person, personExists := fs.persons[sample.PersonID]
	if !personExists {
		fs.sendErrorResponse(w, "关联的人员不存在", http.StatusNotFound)
		return
	}

	// 检查是否为最后一个样本
	if len(person.Samples) <= 1 {
		fs.sendErrorResponse(w, "不能删除最后一个样本，请删除整个人员", http.StatusBadRequest)
		return
	}

	// 删除图片文件
	if sample.ImagePath != "" {
		if err := os.Remove(sample.ImagePath); err != nil {
			log.Printf("删除图片文件失败: %v", err)
		}
	}

	// 从人员的样本列表中移除
	for i, s := range person.Samples {
		if s.ID == sampleID {
			person.Samples = append(person.Samples[:i], person.Samples[i+1:]...)
			break
		}
	}
	person.Updated = time.Now()

	// 删除样本数据
	delete(fs.samples, sampleID)
	fs.stats.TotalSamples--

	// 更新分类器
	fs.updateClassifier()

	// 保存数据
	go fs.saveData()

	fs.sendSuccessResponse(w, "样本删除成功", nil)
}

// GetStatistics 获取统计信息
func (fs *FaceService) GetStatistics(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		fs.sendErrorResponse(w, "只支持GET方法", http.StatusMethodNotAllowed)
		return
	}

	fs.mu.RLock()
	stats := fs.stats
	fs.mu.RUnlock()

	fs.sendSuccessResponse(w, "获取统计信息成功", stats)
}

// GetPersonDetail 获取人员详情
func (fs *FaceService) GetPersonDetail(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		fs.sendErrorResponse(w, "只支持GET方法", http.StatusMethodNotAllowed)
		return
	}

	vars := mux.Vars(r)
	personIDStr := vars["person_id"]
	personID, err := strconv.Atoi(personIDStr)
	if err != nil {
		fs.sendErrorResponse(w, "无效的人员ID", http.StatusBadRequest)
		return
	}

	fs.mu.RLock()
	person, exists := fs.persons[personID]
	fs.mu.RUnlock()

	if !exists {
		fs.sendErrorResponse(w, "人员不存在", http.StatusNotFound)
		return
	}

	// 构建详细信息
	personDetail := map[string]interface{}{
		"id":           person.ID,
		"name":         person.Name,
		"sample_count": len(person.Samples),
		"created":      person.Created,
		"updated":      person.Updated,
	}

	// 添加样本详情
	var samples []map[string]interface{}
	for _, sample := range person.Samples {
		samples = append(samples, map[string]interface{}{
			"id":        sample.ID,
			"image_url": sample.ImageURL,
			"quality":   sample.Quality,
			"created":   sample.Created,
		})
	}
	personDetail["samples"] = samples

	fs.sendSuccessResponse(w, "获取人员详情成功", personDetail)
}

// UpdatePersonName 更新人员姓名
func (fs *FaceService) UpdatePersonName(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPut {
		fs.sendErrorResponse(w, "只支持PUT方法", http.StatusMethodNotAllowed)
		return
	}

	vars := mux.Vars(r)
	personIDStr := vars["person_id"]
	personID, err := strconv.Atoi(personIDStr)
	if err != nil {
		fs.sendErrorResponse(w, "无效的人员ID", http.StatusBadRequest)
		return
	}

	// 解析JSON请求体
	var requestData struct {
		Name string `json:"name"`
	}

	if err := json.NewDecoder(r.Body).Decode(&requestData); err != nil {
		fs.sendErrorResponse(w, "解析请求数据失败", http.StatusBadRequest)
		return
	}

	if requestData.Name == "" {
		fs.sendErrorResponse(w, "姓名不能为空", http.StatusBadRequest)
		return
	}

	fs.mu.Lock()
	defer fs.mu.Unlock()

	person, exists := fs.persons[personID]
	if !exists {
		fs.sendErrorResponse(w, "人员不存在", http.StatusNotFound)
		return
	}

	// 检查新姓名是否已存在
	for _, p := range fs.persons {
		if p.ID != personID && p.Name == requestData.Name {
			fs.sendErrorResponse(w, "该姓名已存在", http.StatusConflict)
			return
		}
	}

	// 更新姓名
	person.Name = requestData.Name
	person.Updated = time.Now()

	// 保存数据
	go fs.saveData()

	fs.sendSuccessResponse(w, "姓名更新成功", map[string]interface{}{
		"id":   person.ID,
		"name": person.Name,
	})
}

// HealthCheck 健康检查
func (fs *FaceService) HealthCheck(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		fs.sendErrorResponse(w, "只支持GET方法", http.StatusMethodNotAllowed)
		return
	}

	fs.mu.RLock()
	totalPersons := len(fs.persons)
	totalSamples := len(fs.samples)
	fs.mu.RUnlock()

	fs.sendSuccessResponse(w, "服务正常", map[string]interface{}{
		"status":        "healthy",
		"total_persons": totalPersons,
		"total_samples": totalSamples,
		"timestamp":     time.Now(),
	})
}

// 响应辅助方法
func (fs *FaceService) sendSuccessResponse(w http.ResponseWriter, message string, data interface{}) {
	fs.sendResponse(w, true, message, data, http.StatusOK)
}

func (fs *FaceService) sendErrorResponse(w http.ResponseWriter, message string, statusCode int) {
	fs.sendResponse(w, false, message, nil, statusCode)
}

func (fs *FaceService) sendResponse(w http.ResponseWriter, success bool, message string, data interface{}, statusCode int) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(statusCode)

	response := Response{
		Success:   success,
		Message:   message,
		Data:      data,
		Timestamp: time.Now(),
	}

	json.NewEncoder(w).Encode(response)
}

// 加载配置
func loadConfig(configPath string) (*Config, error) {
	// 默认配置
	config := &Config{
		Port:             ":8080",
		ModelsDir:        "models",
		UploadsDir:       "uploads",
		TempDir:          "temp",
		DataFile:         "face_data.json",
		MaxFileSize:      10 << 20, // 10MB
		DefaultThreshold: 0.6,
		LogLevel:         "info",
	}

	// 如果配置文件存在，则加载配置
	if _, err := os.Stat(configPath); err == nil {
		file, err := os.Open(configPath)
		if err != nil {
			return nil, fmt.Errorf("打开配置文件失败: %v", err)
		}
		defer file.Close()

		if err := json.NewDecoder(file).Decode(config); err != nil {
			return nil, fmt.Errorf("解析配置文件失败: %v", err)
		}
	}

	return config, nil
}

// 定期保存数据的后台任务
func (fs *FaceService) startAutoSave() {
	go func() {
		ticker := time.NewTicker(5 * time.Minute) // 每5分钟保存一次
		defer ticker.Stop()

		for range ticker.C {
			if err := fs.saveData(); err != nil {
				log.Printf("自动保存数据失败: %v", err)
			}
		}
	}()
}

func main() {
	// 加载配置
	configPath := "config.json"
	if len(os.Args) > 1 {
		configPath = os.Args[1]
	}

	config, err := loadConfig(configPath)
	if err != nil {
		log.Printf("加载配置失败，使用默认配置: %v", err)
		config = &Config{
			Port:             ":8080",
			ModelsDir:        "models",
			UploadsDir:       "uploads",
			TempDir:          "temp",
			DataFile:         "face_data.json",
			MaxFileSize:      10 << 20,
			DefaultThreshold: 0.6,
			LogLevel:         "info",
		}
	}

	// 初始化人脸识别服务
	faceService, err := NewFaceService(config)
	if err != nil {
		log.Fatal("初始化人脸识别服务失败:", err)
	}
	defer faceService.Close()

	// 启动自动保存
	faceService.startAutoSave()

	// 创建路由
	r := mux.NewRouter()

	// API路由
	api := r.PathPrefix("/api/v1").Subrouter()
	
	// 人员管理
	api.HandleFunc("/person/register", faceService.RegisterPerson).Methods("POST")
	api.HandleFunc("/person/list", faceService.GetPersonList).Methods("GET")
	api.HandleFunc("/person/{person_id}", faceService.GetPersonDetail).Methods("GET")
	api.HandleFunc("/person/{person_id}", faceService.UpdatePersonName).Methods("PUT")
	api.HandleFunc("/person/{person_id}", faceService.DeletePerson).Methods("DELETE")
	
	// 样本管理
	api.HandleFunc("/person/{person_id}/sample", faceService.AddSample).Methods("POST")
	api.HandleFunc("/sample/{sample_id}", faceService.DeleteSample).Methods("DELETE")
	
	// 识别接口
	api.HandleFunc("/face/recognize", faceService.RecognizeFace).Methods("POST")
	api.HandleFunc("/face/recognize-multiple", faceService.RecognizeMultipleFaces).Methods("POST")
	
	// 统计和健康检查
	api.HandleFunc("/statistics", faceService.GetStatistics).Methods("GET")
	api.HandleFunc("/health", faceService.HealthCheck).Methods("GET")

	// 静态文件服务
	r.PathPrefix("/uploads/").Handler(http.StripPrefix("/uploads/", http.FileServer(http.Dir(config.UploadsDir))))

	// CORS中间件
	r.Use(func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			w.Header().Set("Access-Control-Allow-Origin", "*")
			w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
			w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")

			if r.Method == "OPTIONS" {
				w.WriteHeader(http.StatusOK)
				return
			}

			next.ServeHTTP(w, r)
		})
	})

	// 启动服务
	fmt.Printf("=== 人脸识别服务启动 ===\n")
	fmt.Printf("端口: %s\n", config.Port)
	fmt.Printf("模型路径: %s\n", config.ModelsDir)
	fmt.Printf("上传目录: %s\n", config.UploadsDir)
	fmt.Printf("数据文件: %s\n", config.DataFile)
	fmt.Printf("默认阈值: %.2f\n", config.DefaultThreshold)
	fmt.Printf("最大文件大小: %d MB\n", config.MaxFileSize/(1024*1024))
	fmt.Println("\n=== API接口列表 ===")
	fmt.Println("人员管理:")
	fmt.Println("  POST   /api/v1/person/register        - 人员登记")
	fmt.Println("  GET    /api/v1/person/list           - 获取人员列表")
	fmt.Println("  GET    /api/v1/person/{id}           - 获取人员详情")
	fmt.Println("  PUT    /api/v1/person/{id}           - 更新人员姓名")
	fmt.Println("  DELETE /api/v1/person/{id}           - 删除人员")
	fmt.Println("\n样本管理:")
	fmt.Println("  POST   /api/v1/person/{id}/sample    - 添加样本")
	fmt.Println("  DELETE /api/v1/sample/{id}           - 删除样本")
	fmt.Println("\n识别接口:")
	fmt.Println("  POST   /api/v1/face/recognize        - 单人脸识别")
	fmt.Println("  POST   /api/v1/face/recognize-multiple - 多人脸识别")
	fmt.Println("\n系统接口:")
	fmt.Println("  GET    /api/v1/statistics            - 获取统计信息")
	fmt.Println("  GET    /api/v1/health                - 健康检查")
	fmt.Println("\n静态文件:")
	fmt.Println("  GET    /uploads/*                    - 图片文件访问")

	log.Fatal(http.ListenAndServe(config.Port, r))

```

配置文件 (config.json)

```json
{
  "port": ":8080",
  "models_dir": "models",
  "uploads_dir": "uploads",
  "temp_dir": "temp",
  "data_file": "face_data.json",
  "max_file_size": 10485760,
  "default_threshold": 0.6,
  "log_level": "info"
}
```

>⚠️ 使用建议
>
> 样本采集
>
>- 每人建议采集3-8个高质量样本
>- 包含不同角度：正面、左侧、右侧
>- 包含不同表情：微笑、严肃
>- 确保良好的光线条件
>- 避免模糊、遮挡的图片
>
> 阈值设置
>
>- 默认阈值0.6适用于大多数场景
>- 安全性要求高的场景可提高到0.7-0.8
>- 便利性要求高的场景可降低到0.4-0.5
>- 建议根据实际测试效果调整

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

## 其他相关的仓库

+ [基于gocv实现的人脸识别登录](https://github.com/Mahmoud-Italy/face-recognition-login)
+ [A simple and fast face detector using gocv and har cascade classifier.](https://github.com/ashwin-rajeev/golang-face-detector)
+ [golang facial recognition project based on the go-face library](https://github.com/andre-ols/go-face-recognition)
+ [Fast face detection, pupil/eyes localization and facial landmark points detection library in pure Go.](https://github.com/esimov/pigo)
+ [Face detection and recognition using golang](https://github.com/leandroveronezi/go-recognizer)
+ [arcface-go](https://github.com/Danile71/arcface-go)
