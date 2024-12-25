---
title: "Go Ble开发实战"
date: 2024-11-02T07:20:04+08:00
draft: false
tags: ["ble","go"]
author: "czyt"
---

> ⚠️代码仅最后部分进行了测试,前面的暂未测试

## 1. 简介

BLE (Bluetooth Low Energy) 是一种低功耗蓝牙技术。Go-BLE 是 Go 语言的 BLE 库，提供了简单易用的 API 来开发 BLE 应用。本文将通过一个完整的示例来展示如何使用 Go-BLE 创建一个蓝牙服务器。

Go-BLE 主要支持 Linux 和 macOS 平台([1](https://github.com/go-ble/ble/blob/77132411213acf9a93fd0c38f006b940422fd8d4/README.md))，但需要注意 macOS 部分目前并未被积极维护。

## 2. 环境准备

### 2.1 安装依赖
```bash
# 安装 go-ble
go get -u github.com/go-ble/ble

# 安装设备支持库
go get -u github.com/go-ble/ble/examples/lib/dev

# Linux系统需要设置权限
sudo setcap 'cap_net_raw,cap_net_admin+eip' ./your_program
```

## 3. BLE基础概念

### 3.1 核心概念

+ Peripheral (外围设备)：提供服务的设备
+ Central (中心设备)：连接外围设备的设备（如手机）
+ Service (服务)：功能的集合
+ Characteristic (特征)：具体的数据点
+ Descriptor (描述符)：特征的元数据

### 3.2 常见的 UUID

1. 标准服务 UUID：
```
电池服务：0x180F
设备信息服务：0x180A
心率务：0x180D
```

2. 标准特征 UUID：
```
电池电量：0x2A19
设备名称：0x2A00
制造商名称：0x2A29
型号名称：0x2A24
序列号：0x2A25
固件版本：0x2A26
信号强度：0x2A1C
```

3. 自定义 UUID 生成：
```go
// 使用在线工具生成 UUID v4
svcUUID := ble.MustParse("19B10000-E8F2-537E-4F6C-D104768A1214")
```

### 3.3 设备类型

BLE 设备类型通过 GAP (Generic Access Profile) 广播数据中的 Flags 字段指定：

```go
const (
    FlagLimitedDiscoverable = 0x01 // LE Limited Discoverable Mode
    FlagGeneralDiscoverable = 0x02 // LE General Discoverable Mode
    FlagBREDRNotSupported  = 0x04 // BR/EDR Not Supported
    FlagLEAndBREDRController = 0x08 // LE and BR/EDR Controller
    FlagLEAndBREDRHost     = 0x10 // LE and BR/EDR Host
)
```

示例：设置设备为仅支持 BLE 的可发现设备
```go
advData := []byte{
    0x02, // Length
    0x01, // Flags type
    0x06, // Flags: LE General Discoverable + BR/EDR Not Supported
}
```

### 3.4 设备类型和外观

BLE 设备的类型和外观是通过 GAP (Generic Access Profile) 的 Appearance 特征值来定义的。这决定了设备在其他设备上显示的图标和类型。

1. 常见的外观值：
```go
const (
    // 未知设备
    AppearanceUnknown = 0x0000
    
    // 手机相关
    AppearancePhone = 0x0040
    
    // 计算机相关
    AppearanceComputer = 0x0080
    AppearanceDesktop  = 0x0081
    AppearanceLaptop   = 0x0082
    AppearanceTablet   = 0x0083
    
    // 穿戴设备
    AppearanceWatch        = 0x00C0
    AppearanceSmartWatch   = 0x00C1
    AppearanceSportsWatch  = 0x00C2
    
    // 音频设备
    AppearanceHeadset      = 0x0420
    AppearanceHeadphones   = 0x0421
    AppearancePortableAudio = 0x0422
    AppearanceCarAudio     = 0x0423
    AppearanceSetTopBox    = 0x0424
    
    // 输入设备
    AppearanceKeyboard     = 0x0440
    AppearanceMouse        = 0x0441
    AppearanceJoystick     = 0x0442
    AppearanceGamepad      = 0x0443
    AppearanceDigitizerTablet = 0x0444
    AppearanceCardReader   = 0x0445
    
    // 健康设备
    AppearanceHeartRateSensor = 0x0340
    AppearanceBloodPressure   = 0x0341
    AppearanceThermometer     = 0x0342
    AppearanceWeightScale     = 0x0343
)
```

2. 设置广播设备名字示例：

```go
package main

import (
	"context"
	"log"

	"github.com/go-ble/ble"
	"github.com/go-ble/ble/examples/lib/dev"
)

func main() {
	d, err := dev.DefaultDevice()
	if err != nil {
		log.Fatalf("初始化设备失败: %v", err)
	}
	ble.SetDefaultDevice(d)

	// 创建上下文
	ctx := context.Background()

	// 开始广播
	if err := ble.AdvertiseNameAndServices(ctx, "Gopher Device"); err != nil {
		log.Fatalf("广播失败: %v", err)
	}
}
```


3. 完整的可配置设备示：

```go
type BLEDevice struct {
	Name       string
	Appearance uint16
	Services   []*ble.Service
}

func NewBLEDevice(name string, appearance uint16) *BLEDevice {
	return &BLEDevice{
		Name:       name,
		Appearance: appearance,
	}
}

func (d *BLEDevice) AddService(svc *ble.Service) {
	d.Services = append(d.Services, svc)
}

func (d *BLEDevice) Start(ctx context.Context) error {
	// 添加服务
	for _, svc := range d.Services {
		if err := ble.AddService(svc); err != nil {
			return fmt.Errorf("添加服务失败: %v", err)
		}
	}

	// 设置广播数据
	adv := []byte{
		0x02, 0x01, 0x06, // Flags
		0x03, 0x19, // Appearance
		byte(d.Appearance & 0xFF),
		byte(d.Appearance >> 8),
	}

	// 添加设备名称
	nameBytes := []byte(d.Name)
	namePart := append([]byte{byte(len(nameBytes) + 1), 0x09}, nameBytes...)
	adv = append(adv, namePart...)

	return ble.AdvertiseRaw(ctx, adv)
}

// 使用示例
func main() {
	// 创建耳机设备
	device := NewBLEDevice("MyHeadphones", AppearanceHeadphones)
	
	// 添加音频服务
	audioSvc := createAudioService()
	device.AddService(audioSvc)
	
	// 添加电池服务
	battSvc := createBatteryService()
	device.AddService(battSvc)
	
	// 启动设备
	ctx := context.Background()
	if err := device.Start(ctx); err != nil {
		log.Fatalf("启动设备失败: %v", err)
	}
}
```

5. 广播数据格式说明：

```
广播数据包格式：
[长度][类型][数据...]

常见类型值：
0x01: Flags
0x09: 完整的本地名称
0x19: Appearance
0x03: 完整的 16-bit UUID 列表
0x16: 服务数据

示例：
[02][01][06]           - Flags
[03][19][40][04]      - Appearance (键盘)
[05][09][48][65][6C][6C][6F] - 名称 "Hello"
```

这些设备类型和外观值会影响设备在其他设备上的显示方式。例如：
- 设置为耳机类型会显示耳机图标
- 设置为鼠标类型会显示鼠标图标
- 设置为键盘类型会显示键盘图标

注意事项：
1. 不是所有设备都会显示对应的图标
2. 图标显示依赖于接收设备的实现
3. 广播数据包有长度限制（通常是31字节）
4. 某些设备类型可能需要实现特定的服务才能正常工作

>上面某些代码可能不能按预期运行.这是因为模拟一个完整的BLE设备需要考虑以下几个方面：
>
>- **硬件层：** 需要模拟BLE芯片的工作，包括无线电收发、协议栈处理等。
>
>- **软件层：** 需要实现BLE协议栈，包括GATT服务、特征、属性等，以及特定的音频或健身设备的协议。
>
>- **数据处理：** 需要处理音频数据、传感器数据等，并进行相应的编码和解码
>
> go-ble主要提供的是BLE协议栈的上层接口，不涉及底层的硬件实现和协议栈的全部细节。
>
>可以考虑使用其他的库实现,下面是一个使用`github.com/paypal/gatt`实现的例子(只支持Linux和mac)
>
>```go
>package main
>
>import (
>        "fmt"
>        "time"
>
>        "github.com/paypal/gatt"
>        "github.com/paypal/gatt/examples/option"
>)
>
>func main() {
>        // ... (省略其他代码)
>
>        // 创建一个Peripheral实例，代表模拟的BLE设备
>        peripheral, err := gatt.NewPeripheral(option.DefaultOption)
>        if err != nil {
>                panic(err)
>        }
>
>        // 添加一个服务，例如模拟耳机服务
>        service := peripheral.AddService(gatt.MustParseUUID("your_service_uuid"))
>
>        // 添加一个特征，例如模拟音频数据特征
>        characteristic := service.AddCharacteristic(gatt.MustParseUUID("your_characteristic_uuid"), gatt.CharacteristicPropertiesRead|gatt.CharacteristicPropertiesNotify, nil)
>
>        // 实现通知回调函数，定期发送模拟音频数据
>        characteristic.HandleNotify(func(req *gatt.Request) {
>                // 生成模拟音频数据
>                data := generateAudioData()
>                req.SendValue(data)
>        })
>
>        // 启动广告数据
>        peripheral.AdvertiseName("MySimulatedHeadset", false)
>
>        // 开始监听连接
>        peripheral.Start()
>
>        // 等待连接
>        fmt.Println("Waiting for connections...")
>        select {}
>}
>```


## 4. 代码示例

### 4.1 添加自定义电池服务

```go
// 自定义电池服务示例
func createBatteryService() *ble.Service {
	// 使用标准 UUID
	battSvcUUID := ble.UUID16(0x180F)  // Battery Service
	battCharUUID := ble.UUID16(0x2A19) // Battery Level
	
	battChar := ble.NewCharacteristic(battCharUUID)
	battChar.HandleRead(ble.ReadHandlerFunc(func(req ble.Request, rsp ble.ResponseWriter) {
		battLevel := byte(85) // 85%
		rsp.Write([]byte{battLevel})
	}))
	
	battSvc := ble.NewService(battSvcUUID)
	battSvc.AddCharacteristic(battChar)
	
	return battSvc
}
```

### 4.2 添加自定义设备信息服务

```go
// 自定义设备信息服务示例
func createDeviceInfoService() *ble.Service {
	// 使用标准 UUID
	svcUUID := ble.UUID16(0x180A)      // Device Information Service
	manufCharUUID := ble.UUID16(0x2A29) // Manufacturer Name String
	modelCharUUID := ble.UUID16(0x2A24) // Model Number String
	
	svc := ble.NewService(svcUUID)
	
	// 制造商名称特征
	manufChar := ble.NewCharacteristic(manufCharUUID)
	manufChar.HandleRead(ble.ReadHandlerFunc(func(req ble.Request, rsp ble.ResponseWriter) {
		rsp.Write([]byte("Gopher Corp"))
	}))
	svc.AddCharacteristic(manufChar)
	
	// 型号特征
	modelChar := ble.NewCharacteristic(modelCharUUID)
	modelChar.HandleRead(ble.ReadHandlerFunc(func(req ble.Request, rsp ble.ResponseWriter) {
		rsp.Write([]byte("Gopher-1"))
	}))
	svc.AddCharacteristic(modelChar)
	
	return svc
}
```

### 4.3 信号强度监控

```go
// 信号强度特征示例
func createRSSICharacteristic() *ble.Characteristic {
	rssiChar := ble.NewCharacteristic(ble.UUID16(0x2A1C))
	
	rssiChar.HandleNotify(ble.NotifyHandlerFunc(func(req ble.Request, n ble.Notifier) {
		ticker := time.NewTicker(1 * time.Second)
		defer ticker.Stop()
		
		for {
			select {
			case <-n.Context().Done():
				return
			case <-ticker.C:
				// 获取连接的信号强度
				rssi := req.Conn().Conn().GetRSSI()
				n.Write([]byte{byte(rssi)})
			}
		}
	}))
	
	return rssiChar
}
```

### 4.4 完整的多服务示例

```go
package main

import (
	"context"
	"errors"
	"log"
	"os"
	"os/signal"
	"time"

	"github.com/go-ble/ble"
	"github.com/go-ble/ble/examples/lib/dev"
)

var (
	// 主服务和特征
	svcUUID  = ble.MustParse("19B10000-E8F2-537E-4F6C-D104768A1214")
	charUUID = ble.MustParse("19B10001-E8F2-537E-4F6C-D104768A1214")

	// 电池服务和特征
	battSvcUUID  = ble.MustParse("19B10002-E8F2-537E-4F6C-D104768A1214")
	battCharUUID = ble.MustParse("19B10003-E8F2-537E-4F6C-D104768A1214")

	// 设备信息服务和特征
	deviceInfoSvcUUID = ble.MustParse("19B10004-E8F2-537E-4F6C-D104768A1214")
	manufCharUUID     = ble.MustParse("19B10005-E8F2-537E-4F6C-D104768A1214")
	modelCharUUID     = ble.MustParse("19B10006-E8F2-537E-4F6C-D104768A1214")
)

// 创建主服务
func createMainService() *ble.Service {
	svc := ble.NewService(svcUUID)
	char := ble.NewCharacteristic(charUUID)

	char.HandleNotify(ble.NotifyHandlerFunc(func(req ble.Request, n ble.Notifier) {
		log.Printf("客户端已订阅通知: %s", req.Conn().RemoteAddr())
		n.Write([]byte("Hello from Gopher!"))

		ticker := time.NewTicker(3 * time.Second)
		defer ticker.Stop()

		for {
			select {
			case <-n.Context().Done():
				log.Printf("客户端取消订阅: %s", req.Conn().RemoteAddr())
				return
			case <-ticker.C:
				msg := []byte("Gopher says hi!")
				log.Printf("发送消息到 %s: %s", req.Conn().RemoteAddr(), msg)
				if _, err := n.Write(msg); err != nil {
					log.Printf("发送失败: %v", err)
					return
				}
			}
		}
	}))

	svc.AddCharacteristic(char)
	return svc
}

// 创建电池服务
func createBatteryService() *ble.Service {
	svc := ble.NewService(battSvcUUID)
	battChar := ble.NewCharacteristic(battCharUUID)

	// 处理电量读取
	battChar.HandleRead(ble.ReadHandlerFunc(func(req ble.Request, rsp ble.ResponseWriter) {
		// 模拟电池量 (85%)
		rsp.Write([]byte{85})
	}))

	// 处理电量通知
	battChar.HandleNotify(ble.NotifyHandlerFunc(func(req ble.Request, n ble.Notifier) {
		log.Printf("客户端订阅电池通知: %s", req.Conn().RemoteAddr())
		ticker := time.NewTicker(30 * time.Second)
		defer ticker.Stop()

		battLevel := byte(85)
		for {
			select {
			case <-n.Context().Done():
				return
			case <-ticker.C:
				if battLevel > 0 {
					battLevel--
				}
				log.Printf("发送电量更新: %d%%", battLevel)
				n.Write([]byte{battLevel})
			}
		}
	}))

	svc.AddCharacteristic(battChar)
	return svc
}

// 创建设备信息服务
func createDeviceInfoService() *ble.Service {
	svc := ble.NewService(deviceInfoSvcUUID)

	// 制造商名称特征
	manufChar := ble.NewCharacteristic(manufCharUUID)
	manufChar.HandleRead(ble.ReadHandlerFunc(func(req ble.Request, rsp ble.ResponseWriter) {
		rsp.Write([]byte("Gopher Corp"))
	}))
	svc.AddCharacteristic(manufChar)

	// 型号特征
	modelChar := ble.NewCharacteristic(modelCharUUID)
	modelChar.HandleRead(ble.ReadHandlerFunc(func(req ble.Request, rsp ble.ResponseWriter) {
		rsp.Write([]byte("Gopher-1"))
	}))
	svc.AddCharacteristic(modelChar)

	return svc
}

func main() {
	// 初始化设备
	d, err := dev.DefaultDevice()
	if err != nil {
		log.Fatalf("初始化设备失败: %v", err)
	}
	ble.SetDefaultDevice(d)

	// 添加所有服务
	if err := ble.AddService(createMainService()); err != nil {
		log.Fatalf("添加主服务失败: %v", err)
	}
	if err := ble.AddService(createBatteryService()); err != nil {
		log.Fatalf("添加电池服务失败: %v", err)
	}
	if err := ble.AddService(createDeviceInfoService()); err != nil {
		log.Fatalf("添加设备信息服务失败: %v", err)
	}

	// 创建上下文
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	// 设置信号处理
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, os.Interrupt)
	go func() {
		<-sigChan
		log.Println("收到中断信号，正在停止...")
		cancel()
	}()

	// 开始广播
	log.Printf("开始广播...")
	if err := ble.AdvertiseNameAndServices(ctx, "Gopher Device",
		[]ble.UUID{svcUUID, battSvcUUID, deviceInfoSvcUUID}...); err != nil {
		if errors.Is(err, context.Canceled) {
			log.Println("广播已停止")
		} else {
			log.Fatalf("广播失败: %v", err)
		}
	}

	<-ctx.Done()
	log.Printf("服务已停止")
}
```

## 5. 总结

本文展示了如何使用 Go-BLE 创建一个基本的 BLE 服务器。通过这个示例，我们可以看到：

1. Go-BLE 提供了简单而强大的 API
2. 可以轻松实现设备发现和通知功能
3. 代码结构清晰，易于扩展

这个示例可以作为开发更复杂 BLE 应用的起点。根据实际需求，你可以添加更多特征、实现双向通信、增加安全机制等。

注意事项：
1. 某些系统可能需要 root 权限
2. 广播数据包长度限制为31字节
3. 使用标准 UUID 时需要确保有适当权限
4. 建议先使用 nRF Connect 等工具测试

## 6. 其他库

+ [go-ble的fork版本](https://github.com/SensefinityCloud/go-ble) 支持自定义广播信息