---
title: "Go语言中的指数加权移动平均"
date: 2025-06-06T16:07:37+08:00
draft: false
tags: ["golang"]
author: "czyt"
---

Tailscale中有很多实用的代码，下面是EWMA的一个实现，[源码](https://github.com/tailscale/tailscale/blob/main/maths/ewma.go)

```go
// Copyright (c) Tailscale Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

// Package maths contains additional mathematical functions or structures not
// found in the standard library.
package maths

import (
	"math"
	"time"
)

// EWMA is an exponentially weighted moving average supporting updates at
// irregular intervals with at most nanosecond resolution.
// The zero value will compute a half-life of 1 second.
// It is not safe for concurrent use.
// TODO(raggi): de-duplicate with tstime/rate.Value, which has a more complex
// and synchronized interface and does not provide direct access to the stable
// value.
type EWMA struct {
	value    float64 // current value of the average
	lastTime int64   // time of last update in unix nanos
	halfLife float64 // half-life in seconds
}

// NewEWMA creates a new EWMA with the specified half-life. If halfLifeSeconds
// is 0, it defaults to 1.
func NewEWMA(halfLifeSeconds float64) *EWMA {
	return &EWMA{
		halfLife: halfLifeSeconds,
	}
}

// Update adds a new sample to the average. If t is zero or precedes the last
// update, the update is ignored.
func (e *EWMA) Update(value float64, t time.Time) {
	if t.IsZero() {
		return
	}
	hl := e.halfLife
	if hl == 0 {
		hl = 1
	}
	tn := t.UnixNano()
	if e.lastTime == 0 {
		e.value = value
		e.lastTime = tn
		return
	}

	dt := (time.Duration(tn-e.lastTime) * time.Nanosecond).Seconds()
	if dt < 0 {
		// drop out of order updates
		return
	}

	// decay = 2^(-dt/halfLife)
	decay := math.Exp2(-dt / hl)
	e.value = e.value*decay + value*(1-decay)
	e.lastTime = tn
}

// Get returns the current value of the average
func (e *EWMA) Get() float64 {
	return e.value
}

// Reset clears the EWMA to its initial state
func (e *EWMA) Reset() {
	e.value = 0
	e.lastTime = 0
}
```

这个库实现了 **EWMA（指数加权移动平均）**，是一种用来平滑数据波动的数学工具。让我用简单的方式解释一下：

## 什么是 EWMA？

想象你在观察一个城市的温度变化：

- 普通平均：把过去10天的温度加起来除以10
- EWMA：**最近的温度更重要**，越早的温度影响越小

比如今天30°C，昨天25°C，前天20°C：

- 普通平均：(30+25+20)/3 = 25°C
- EWMA：30°C × 0.5 + 25°C × 0.3 + 20°C × 0.2 = 26°C（今天的温度影响最大）

## 核心概念：半衰期（Half-life）

半衰期决定了"遗忘"旧数据的速度：

- 半衰期1秒：1秒后，旧数据的影响减半
- 半衰期10秒：10秒后，旧数据的影响减半

## 实际应用场景

```go
package main

import (
	"fmt"
	"math"
	"time"
)

// 复制原始的 EWMA 实现
type EWMA struct {
	value    float64
	lastTime int64
	halfLife float64
}

func NewEWMA(halfLifeSeconds float64) *EWMA {
	return &EWMA{
		halfLife: halfLifeSeconds,
	}
}

func (e *EWMA) Update(value float64, t time.Time) {
	if t.IsZero() {
		return
	}
	hl := e.halfLife
	if hl == 0 {
		hl = 1
	}
	tn := t.UnixNano()
	if e.lastTime == 0 {
		e.value = value
		e.lastTime = tn
		return
	}
	dt := (time.Duration(tn-e.lastTime) * time.Nanosecond).Seconds()
	if dt < 0 {
		return
	}
	decay := math.Exp2(-dt / hl)
	e.value = e.value*decay + value*(1-decay)
	e.lastTime = tn
}

func (e *EWMA) Get() float64 {
	return e.value
}

func (e *EWMA) Reset() {
	e.value = 0
	e.lastTime = 0
}

func main() {
	fmt.Println("=== EWMA 实际应用示例 ===\n")
	
	// 示例1：网络延迟监控
	fmt.Println("1. 网络延迟监控（半衰期5秒）")
	latencyEWMA := NewEWMA(5.0) // 5秒半衰期
	
	// 模拟网络延迟数据（毫秒）
	latencies := []struct {
		delay time.Duration
		ping  float64
	}{
		{0 * time.Second, 10.0},    // 正常延迟
		{1 * time.Second, 12.0},    // 稍高
		{2 * time.Second, 8.0},     // 较低
		{3 * time.Second, 50.0},    // 突然很高（网络抖动）
		{4 * time.Second, 15.0},    // 恢复正常
		{5 * time.Second, 11.0},    // 正常
		{6 * time.Second, 9.0},     // 正常
	}
	
	baseTime := time.Now()
	for _, l := range latencies {
		latencyEWMA.Update(l.ping, baseTime.Add(l.delay))
		fmt.Printf("时间: %ds, 实际延迟: %.1fms, EWMA: %.2fms\n", 
			int(l.delay.Seconds()), l.ping, latencyEWMA.Get())
	}
	
	fmt.Println("\n分析：EWMA 平滑了延迟突刺，提供更稳定的网络质量指标")
	
	// 示例2：CPU使用率监控
	fmt.Println("\n2. CPU使用率监控（半衰期10秒）")
	cpuEWMA := NewEWMA(10.0) // 10秒半衰期，变化更缓慢
	
	cpuUsages := []struct {
		delay time.Duration
		usage float64
	}{
		{0 * time.Second, 20.0},    // 正常CPU使用率
		{2 * time.Second, 25.0},    
		{4 * time.Second, 80.0},    // 突然高CPU（可能是病毒或大任务）
		{6 * time.Second, 85.0},    // 持续高CPU
		{8 * time.Second, 30.0},    // 任务结束，CPU降低
		{10 * time.Second, 22.0},   // 恢复正常
		{12 * time.Second, 18.0},   
	}
	
	baseTime2 := time.Now()
	for _, c := range cpuUsages {
		cpuEWMA.Update(c.usage, baseTime2.Add(c.delay))
		fmt.Printf("时间: %ds, 实际CPU: %.1f%%, EWMA: %.2f%%\n", 
			int(c.delay.Seconds()), c.usage, cpuEWMA.Get())
	}
	
	fmt.Println("\n分析：EWMA 避免了因临时高CPU而触发过多告警")
	
	// 示例3：股价趋势分析
	fmt.Println("\n3. 股价趋势分析（对比不同半衰期）")
	shortEWMA := NewEWMA(2.0)  // 短期趋势（2秒半衰期）
	longEWMA := NewEWMA(8.0)   // 长期趋势（8秒半衰期）
	
	prices := []struct {
		delay time.Duration
		price float64
	}{
		{0 * time.Second, 100.0},
		{1 * time.Second, 102.0},
		{2 * time.Second, 98.0},
		{3 * time.Second, 105.0},
		{4 * time.Second, 103.0},
		{5 * time.Second, 107.0},
		{6 * time.Second, 104.0},
		{7 * time.Second, 106.0},
	}
	
	baseTime3 := time.Now()
	fmt.Println("时间\t实际价格\t短期EWMA\t长期EWMA\t信号")
	for _, p := range prices {
		shortEWMA.Update(p.price, baseTime3.Add(p.delay))
		longEWMA.Update(p.price, baseTime3.Add(p.delay))
		
		signal := "持有"
		if shortEWMA.Get() > longEWMA.Get()+1 {
			signal = "买入信号"
		} else if shortEWMA.Get() < longEWMA.Get()-1 {
			signal = "卖出信号"
		}
		
		fmt.Printf("%ds\t%.1f\t\t%.2f\t\t%.2f\t\t%s\n", 
			int(p.delay.Seconds()), p.price, shortEWMA.Get(), longEWMA.Get(), signal)
	}
	
	fmt.Println("\n分析：短期EWMA响应快，长期EWMA稳定，两者交叉可产生交易信号")
	
	// 示例4：半衰期的影响
	fmt.Println("\n4. 半衰期对响应速度的影响")
	fast := NewEWMA(1.0)    // 1秒半衰期，快速响应
	medium := NewEWMA(3.0)  // 3秒半衰期，中等响应
	slow := NewEWMA(10.0)   // 10秒半衰期，慢速响应
	
	// 模拟数据从10突然跳到20
	testData := []struct {
		delay time.Duration
		value float64
	}{
		{0 * time.Second, 10.0},
		{1 * time.Second, 20.0}, // 突然变化
		{2 * time.Second, 20.0},
		{3 * time.Second, 20.0},
		{4 * time.Second, 20.0},
		{5 * time.Second, 20.0},
	}
	
	baseTime4 := time.Now()
	fmt.Println("时间\t实际值\t快速EWMA\t中等EWMA\t慢速EWMA")
	for _, d := range testData {
		fast.Update(d.value, baseTime4.Add(d.delay))
		medium.Update(d.value, baseTime4.Add(d.delay))
		slow.Update(d.value, baseTime4.Add(d.delay))
		
		fmt.Printf("%ds\t%.1f\t%.2f\t\t%.2f\t\t%.2f\n", 
			int(d.delay.Seconds()), d.value, fast.Get(), medium.Get(), slow.Get())
	}
	
	fmt.Println("\n分析：半衰期越短，响应越快；半衰期越长，越稳定但响应慢")
	
	// 示例5：时间间隔不规律的数据
	fmt.Println("\n5. 处理不规律时间间隔的数据")
	irregularEWMA := NewEWMA(5.0)
	
	irregularData := []struct {
		delay time.Duration
		value float64
	}{
		{0 * time.Second, 100.0},
		{1 * time.Second, 110.0},    // 1秒后
		{1500 * time.Millisecond, 120.0}, // 0.5秒后
		{4 * time.Second, 90.0},     // 2.5秒后
		{10 * time.Second, 95.0},    // 6秒后
	}
	
	baseTime5 := time.Now()
	fmt.Println("时间间隔\t实际值\tEWMA")
	lastTime := 0.0
	for _, d := range irregularData {
		irregularEWMA.Update(d.value, baseTime5.Add(d.delay))
		interval := d.delay.Seconds() - lastTime
		fmt.Printf("%.1fs后\t\t%.1f\t%.2f\n", interval, d.value, irregularEWMA.Get())
		lastTime = d.delay.Seconds()
	}
	
	fmt.Println("\n分析：EWMA会根据实际时间间隔自动调整权重，时间间隔越长，旧数据影响越小")
}
```

## 关键优势

1. **自动适应时间间隔**：不管数据是每秒一个还是每10秒一个，EWMA都会根据实际时间间隔计算正确的权重
2. **平滑波动**：过滤掉短期的异常值，显示真正的趋势
3. **内存效率**：只需要存储当前值，不需要保存历史数据
4. **实时性**：每次新数据来时立即更新，适合实时监控

## 数学原理（简化版）

EWMA的核心公式：

```latex
新的平均值 = 旧平均值 × 衰减因子 + 新数据 × (1 - 衰减因子)
衰减因子 = 2^(-时间间隔/半衰期)
```

- 时间间隔越长，衰减因子越小，旧数据影响越小
- 半衰期越短，对新数据反应越敏感

这个库特别适合用于：

- 网络监控（延迟、带宽）
- 系统监控（CPU、内存使用率）
- 金融数据分析
- 传感器数据平滑
- 任何需要实时趋势分析的场景