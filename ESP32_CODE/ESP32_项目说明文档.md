# ESP32-S3 智能消防灭火系统 说明文档

## 目录

1. [项目概述](#1-项目概述)
2. [系统功能](#2-系统功能)
3. [代码架构](#3-代码架构)
4. [设计模式与原则](#4-设计模式与原则)
5. [WiFi连接详解](#5-wifi连接详解)
6. [MQTT通信详解](#6-mqtt通信详解)
7. [硬件引脚配置](#7-硬件引脚配置)
8. [模块说明](#8-模块说明)

---

## 1. 项目概述

本项目基于 **ESP32-S3** 微控制器开发，实现了一套完整的**智能消防灭火系统**。系统能够实时监测环境温度、湿度、烟雾浓度，并通过K230视觉模块进行火焰识别，当检测到火灾时自动启动灭火程序（风扇排烟、水泵喷水、蜂鸣器报警），同时通过 **MQTT 协议**将数据上报至云端，支持手机APP远程监控和控制。

### 技术栈

| 类别 | 技术/组件 |
|------|-----------|
| 主控芯片 | ESP32-S3-DevKitC-1 (16MB Flash, PSRAM) |
| 开发框架 | Arduino + PlatformIO |
| 操作系统 | FreeRTOS (ESP-IDF内置) |
| 网络协议 | WiFi + MQTT |
| 数据格式 | JSON (ArduinoJson库) |
| 传感器 | DHT11 (温湿度)、MQ-2 (烟雾)、K230 (视觉火焰检测) |
| 执行器 | 继电器控制的风扇、水泵、蜂鸣器 |

---

## 2. 系统功能

### 2.1 核心功能

```
┌─────────────────────────────────────────────────────────────┐
│                    智能消防灭火系统                           │
├─────────────────────────────────────────────────────────────┤
│  传感器采集          │  智能决策           │  执行动作        │
│  ├─ 温度监测         │  ├─ 火灾判定        │  ├─ 风扇排烟     │
│  ├─ 湿度监测         │  ├─ 自动/手动模式   │  ├─ 水泵喷水     │
│  ├─ 烟雾检测         │  └─ 安全恢复判定    │  └─ 蜂鸣器报警   │
│  └─ 火焰识别(K230)   │                     │                  │
├─────────────────────────────────────────────────────────────┤
│  网络通信：WiFi连接 + MQTT协议上报 + 手机APP远程控制         │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 火灾判定逻辑

系统采用**多传感器融合**的火灾判定策略：

| 触发条件 | 阈值 | 响应动作 |
|----------|------|----------|
| 高温报警 | 温度 > 50°C | 开启风扇 |
| 烟雾报警 | 烟雾浓度 > 30% 或 MQ-2数字报警 | 开启风扇 |
| 视觉火焰检测 | K230发送"fire"命令 | 开启风扇 + 水泵喷水 + 蜂鸣器报警 |

### 2.3 安全恢复逻辑

| 恢复条件 | 阈值 | 响应动作 |
|----------|------|----------|
| 温度安全 | 温度 < 40°C | 可关闭风扇 |
| 烟雾安全 | 烟雾浓度 < 15% 且无报警 | 可关闭风扇 |
| 火焰消失 | K230超过5秒未发送"fire" | 关闭灭火系统 |

---

## 3. 代码架构

### 3.1 项目目录结构

```
FireSuppressionSystem/
├── platformio.ini          # PlatformIO配置文件
├── include/                # 头文件目录
│   ├── MY_DHT11.h         # DHT11温湿度传感器接口
│   ├── MY_MQ2.h           # MQ-2烟雾传感器接口
│   ├── MY_K230.h          # K230视觉模块接口
│   ├── MY_Fan.h           # 风扇控制模块接口
│   ├── MY_Pump.h          # 水泵控制模块接口
│   ├── MY_Buzzer.h        # 蜂鸣器控制模块接口
│   ├── MY_Sensor.h        # 传感器数据聚合接口
│   └── MY_MQTT.h          # WiFi/MQTT通信接口
├── src/                   # 源文件目录
│   ├── main.cpp           # 主程序入口
│   ├── MY_DHT11.cpp       # DHT11实现
│   ├── MY_MQ2.cpp         # MQ-2实现
│   ├── MY_K230.cpp        # K230实现
│   ├── MY_Fan.cpp         # 风扇控制实现
│   ├── MY_Pump.cpp        # 水泵控制实现
│   ├── MY_Buzzer.cpp      # 蜂鸣器控制实现
│   ├── MY_Sensor.cpp      # 传感器聚合实现
│   └── MY_MQTT.cpp        # WiFi/MQTT通信实现
└── docs/                  # 文档目录
```

### 3.2 模块依赖关系

```
                    ┌──────────────┐
                    │   main.cpp   │
                    │   (入口点)    │
                    └──────┬───────┘
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
        ▼                  ▼                  ▼
┌───────────────┐  ┌───────────────┐  ┌───────────────┐
│  MY_Sensor    │  │   MY_MQTT     │  │   MY_K230     │
│ (传感器聚合)   │  │ (网络通信)    │  │ (视觉检测)    │
└───────┬───────┘  └───────┬───────┘  └───────┬───────┘
        │                  │                  │
        ▼                  ▼                  ▼
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│  MY_DHT11   │    │   MY_Fan    │    │   MY_Pump   │
│  MY_MQ2     │    │  MY_Buzzer  │    │             │
└─────────────┘    └─────────────┘    └─────────────┘
```

### 3.3 FreeRTOS 多任务架构

系统采用 **FreeRTOS 双核多任务** 架构，充分利用ESP32-S3的双核特性：

| 任务名称 | 运行核心 | 优先级 | 栈大小 | 功能描述 |
|----------|---------|--------|--------|----------|
| `Sensor_Task` | Core 1 | 5 | 4KB | 传感器数据采集 |
| `K230_Task` | Core 0 | 4 | 4KB | K230视觉火焰检测 |
| `Pump_Task` | Core 0 | 3 | 4KB | 水泵自动控制 |
| `Fan_Task` | Core 0 | 2 | 4KB | 风扇自动控制 |
| `Buzzer_Task` | Core 0 | 1 | 2KB | 蜂鸣器警报控制 |
| `MQTT_Task` | Core 1 | 1 | 16KB | MQTT通信 |

**任务分配原则：**
- **Core 0**: 执行器控制任务（风扇、水泵、蜂鸣器、K230）—— 实时性要求高
- **Core 1**: 网络通信任务（MQTT）和传感器采集 —— 允许一定延迟

---

## 4. 设计模式与原则

### 4.1 模块化设计

每个硬件模块（传感器/执行器）封装为独立的 `.h` 和 `.cpp` 文件，遵循**单一职责原则**：

```cpp
// 每个模块包含：
// 1. 硬件配置宏定义
// 2. 状态枚举和结构体
// 3. 初始化函数 setupXxx()
// 4. 控制函数 xxxOn(), xxxOff()
// 5. 状态获取函数 getXxxState()
// 6. FreeRTOS任务函数 xxxTask()
```

### 4.2 状态机设计

执行器模块采用**有限状态机（FSM）**设计：

```cpp
// 风扇状态机
typedef enum {
    FAN_OFF = 0,    // 关闭状态
    FAN_ON = 1      // 开启状态
} FanState;

// 水泵状态机（带冷却保护）
typedef enum {
    PUMP_OFF = 0,       // 关闭状态
    PUMP_ON = 1,        // 工作状态
    PUMP_COOLDOWN = 2   // 冷却状态
} PumpState;
```

### 4.3 互斥锁保护

所有共享资源都使用 **FreeRTOS 互斥锁（Mutex）** 保护，避免多任务并发访问冲突：

```cpp
SemaphoreHandle_t fanMutex = NULL;      // 风扇状态互斥锁
SemaphoreHandle_t pumpMutex = NULL;     // 水泵状态互斥锁
SemaphoreHandle_t sensorMutex = NULL;   // 传感器数据互斥锁
SemaphoreHandle_t k230Mutex = NULL;     // K230状态互斥锁

// 典型用法：
if (xSemaphoreTake(fanMutex, portMAX_DELAY) == pdTRUE) {
    // 访问共享资源
    fanControl.state = FAN_ON;
    xSemaphoreGive(fanMutex);  // 释放锁
}
```

### 4.4 自动/手动双模式

所有执行器支持**自动模式**和**手动模式**切换：

```cpp
typedef enum {
    FAN_MODE_AUTO = 0,    // 自动模式：根据传感器数据自动控制
    FAN_MODE_MANUAL = 1   // 手动模式：仅响应APP远程命令
} FanMode;
```

**模式切换逻辑：**
- 手动模式下，APP发送的控制命令直接执行
- 自动模式下，APP发送的控制命令被忽略，由传感器数据驱动

### 4.5 发布-订阅模式

MQTT通信采用**发布-订阅（Pub/Sub）**模式，实现设备与APP的解耦：

```
ESP32 ──publish──► [fire_alarm/sensor_data] ──subscribe──► 手机APP
ESP32 ◄─subscribe─ [fire_alarm/fan/control] ◄──publish─── 手机APP
```

---

## 5. WiFi连接详解

### 5.1 WiFi连接原理

ESP32-S3 内置 WiFi 模块，支持 802.11 b/g/n 协议，工作在 2.4GHz 频段。

**WiFi 连接流程：**

```
┌─────────────────────────────────────────────────────────────────┐
│                    WiFi 连接状态机                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌───────────┐    ┌───────────┐    ┌───────────┐               │
│  │  IDLE     │───►│ SCANNING  │───►│ CONNECTING│               │
│  │  (空闲)    │    │  (扫描)    │    │  (连接中) │               │
│  └───────────┘    └───────────┘    └─────┬─────┘               │
│                                          │                      │
│                   ┌──────────────────────┴──────────────────┐   │
│                   │                                         │   │
│                   ▼                                         ▼   │
│           ┌───────────┐                           ┌───────────┐ │
│           │ CONNECTED │                           │  FAILED   │ │
│           │  (已连接)  │                           │  (失败)   │ │
│           └───────────┘                           └───────────┘ │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 5.2 WiFi连接代码实现

```cpp
// MY_MQTT.cpp

// WiFi配置
const char* WIFI_SSID = "1234";
const char* WIFI_PASSWORD = "18636074500";

void setupWiFi() {
    Serial.println();
    Serial.print("Connecting to WiFi: ");
    Serial.println(WIFI_SSID);

    // 1. 断开之前的连接，清除状态
    WiFi.disconnect(true);
    delay(100);
    
    // 2. 设置为STA模式（Station，客户端模式）
    WiFi.mode(WIFI_STA);
    delay(100);
    
    // 3. 开始连接指定的WiFi热点
    WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

    // 4. 等待连接，最多重试40次（20秒）
    int retryCount = 0;
    while (WiFi.status() != WL_CONNECTED && retryCount < 40) {
        delay(500);
        Serial.print(".");
        retryCount++;
    }

    // 5. 检查连接结果
    if (WiFi.status() == WL_CONNECTED) {
        Serial.println("\nWiFi connected!");
        Serial.print("IP: ");
        Serial.println(WiFi.localIP());  // 打印获取到的IP地址
    } else {
        Serial.println("\nWiFi connection failed!");
    }
}
```

### 5.3 WiFi连接的关键步骤解析

| 步骤 | 函数调用 | 说明 |
|------|----------|------|
| 1 | `WiFi.disconnect(true)` | 断开现有连接，参数`true`表示清除保存的凭据 |
| 2 | `WiFi.mode(WIFI_STA)` | 设置为Station模式，作为客户端连接路由器 |
| 3 | `WiFi.begin(ssid, pwd)` | 发起连接请求，开始WPA/WPA2认证 |
| 4 | `WiFi.status()` | 轮询连接状态，返回`WL_CONNECTED`表示成功 |
| 5 | `WiFi.localIP()` | 获取DHCP分配的IP地址 |

### 5.4 WiFi断线重连机制

在MQTT任务中实现了自动重连：

```cpp
void reconnectMQTT() {
    // 先检查WiFi连接状态
    if (WiFi.status() != WL_CONNECTED) {
        WiFi.reconnect();  // 尝试重新连接
        int retry = 0;
        while (WiFi.status() != WL_CONNECTED && retry < 10) {
            vTaskDelay(pdMS_TO_TICKS(500));
            retry++;
        }
        if (WiFi.status() != WL_CONNECTED) return;
    }
    // ... MQTT重连逻辑
}
```

---

## 6. MQTT通信详解

### 6.1 MQTT协议原理

**MQTT（Message Queuing Telemetry Transport）** 是一种轻量级的发布/订阅消息传输协议，专为物联网设计。

**MQTT 核心概念：**

```
┌─────────────────────────────────────────────────────────────────┐
│                       MQTT 通信模型                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│    ┌──────────┐                           ┌──────────┐         │
│    │ ESP32    │                           │ 手机APP  │         │
│    │(Publisher│          MQTT             │(Subscriber)        │
│    │Subscriber)│         Broker           │ Publisher)│        │
│    └────┬─────┘         ┌─────┐          └────┬─────┘         │
│         │               │     │               │                │
│         │──PUBLISH────►│     │               │                │
│         │(sensor_data) │     │──DELIVER────►│                │
│         │               │     │(sensor_data) │                │
│         │               │     │               │                │
│         │◄──DELIVER────│     │◄──PUBLISH────│                │
│         │(fan/control) │     │(fan/control)  │                │
│         │               └─────┘               │                │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

**关键术语：**

| 术语 | 说明 |
|------|------|
| Broker | MQTT服务器，负责消息路由和分发 |
| Client | MQTT客户端（ESP32或手机APP） |
| Topic | 消息主题，用于消息分类和路由 |
| Publish | 发布消息到指定Topic |
| Subscribe | 订阅指定Topic以接收消息 |
| QoS | 服务质量等级（0/1/2） |

一般来讲，网络通信交互中间需要通过服务器进行数据的中转，常用的服务器可以购买华为云服务器、腾讯云服务器、阿里云服务器，而这里我们采用了免费的公共MQTT测试服务器 `broker.emqx.io` 进行数据的中转。这个是官方主动提供的，不需要我们掏一分钱，并且可以进行稳定的连接。

### 6.2 MQTT连接配置

```cpp
// MQTT Broker配置（使用公共测试服务器）
const char* MQTT_BROKER = "broker.emqx.io";
const int MQTT_PORT = 1883;
const char* MQTT_CLIENT_ID = "esp32_fire_alarm_001";
```

### 6.3 Topic 设计

本系统定义了以下MQTT Topic：

| Topic | 方向 | 数据格式 | 说明 |
|-------|------|----------|------|
| `fire_alarm/sensor_data` | ESP32 → APP | JSON | 传感器数据上报 |
| `fire_alarm/fan/control` | APP → ESP32 | JSON | 风扇开关控制 |
| `fire_alarm/fan/mode` | APP → ESP32 | JSON | 风扇模式切换 |
| `fire_alarm/pump/control` | APP → ESP32 | JSON | 水泵开关控制 |
| `fire_alarm/pump/mode` | APP → ESP32 | JSON | 水泵模式切换 |
| `fire_alarm/buzzer/control` | APP → ESP32 | JSON | 蜂鸣器开关控制 |
| `fire_alarm/buzzer/mode` | APP → ESP32 | JSON | 蜂鸣器模式切换 |

### 6.4 MQTT连接流程

```cpp
void setupMQTT() {
    // 1. 设置MQTT Broker地址和端口
    mqttClient.setServer(MQTT_BROKER, MQTT_PORT);
    
    // 2. 设置消息回调函数
    mqttClient.setCallback(mqttCallback);
    
    // 3. 设置缓冲区大小（JSON数据较大）
    mqttClient.setBufferSize(1024);
    
    Serial.println("[MQTT] Configured: " + String(MQTT_BROKER) + ":" + String(MQTT_PORT));
}

void reconnectMQTT() {
    // ... WiFi检查略 ...
    
    while (!mqttClient.connected()) {
        Serial.print("[MQTT] Connecting...");
        
        // 使用Client ID连接Broker
        if (mqttClient.connect(MQTT_CLIENT_ID)) {
            Serial.println("connected!");
            
            // 连接成功后订阅控制Topic
            subscribeControlTopics();
        } else {
            Serial.println("failed, retrying in 5s");
            vTaskDelay(pdMS_TO_TICKS(5000));
        }
    }
}

void subscribeControlTopics() {
    // 订阅所有控制命令Topic
    mqttClient.subscribe(MQTT_TOPIC_FAN_CONTROL);
    mqttClient.subscribe(MQTT_TOPIC_FAN_MODE);
    mqttClient.subscribe(MQTT_TOPIC_PUMP_CONTROL);
    mqttClient.subscribe(MQTT_TOPIC_PUMP_MODE);
    mqttClient.subscribe(MQTT_TOPIC_BUZZER_CONTROL);
    mqttClient.subscribe(MQTT_TOPIC_BUZZER_MODE);
    Serial.println("[MQTT] Subscribed to all control topics");
}
```

### 6.5 MQTT消息发布（上报传感器数据）

```cpp
void publishSensorData(float temperature, float humidity, float smokeLevel, bool smokeAlarm) {
    if (!mqttClient.connected()) return;

    // 创建JSON格式的数据负载
    String payload = createJsonPayload(temperature, humidity, smokeLevel, smokeAlarm);
    
    // 发布到传感器数据Topic
    if (mqttClient.publish(MQTT_TOPIC_SENSOR, payload.c_str())) {
        Serial.println("[MQTT] Published sensor data");
    }
}

String createJsonPayload(float temperature, float humidity, float smokeLevel, bool smokeAlarm) {
    JsonDocument doc;
    
    // 设备标识
    doc["device_id"] = DEVICE_ID;
    
    // 传感器数据
    doc["temperature"] = round(temperature * 10.0) / 10.0;
    doc["humidity"] = round(humidity * 10.0) / 10.0;
    doc["smoke_level"] = round(smokeLevel * 10.0) / 10.0;
    doc["smoke_alarm"] = smokeAlarm;
    
    // 执行器状态
    doc["fan_state"] = getFanStateString();
    doc["fan_mode"] = getFanModeString();
    doc["pump_state"] = getPumpStateString();
    doc["pump_mode"] = getPumpModeString();
    doc["k230_fire"] = getK230FireStateString();
    doc["k230_fire_detected"] = isK230FireDetected();
    doc["buzzer_state"] = getBuzzerStateString();
    doc["buzzer_mode"] = getBuzzerModeString();
    
    // 时间戳
    doc["timestamp"] = millis();
    
    // 单位信息
    JsonObject unit = doc["unit"].to<JsonObject>();
    unit["temperature"] = "celsius";
    unit["humidity"] = "percent";
    unit["smoke_level"] = "percent";

    String payload;
    serializeJson(doc, payload);
    
    return payload;
}
```

**上报数据JSON示例：**

```json
{
    "device_id": "esp32_fire_alarm_001",
    "temperature": 25.5,
    "humidity": 60.0,
    "smoke_level": 5.2,
    "smoke_alarm": false,
    "fan_state": "off",
    "fan_mode": "auto",
    "pump_state": "off",
    "pump_mode": "auto",
    "k230_fire": "none",
    "k230_fire_detected": false,
    "buzzer_state": "off",
    "buzzer_mode": "auto",
    "timestamp": 123456789,
    "unit": {
        "temperature": "celsius",
        "humidity": "percent",
        "smoke_level": "percent"
    }
}
```

### 6.6 MQTT消息接收（处理控制命令）

```cpp
void mqttCallback(char* topic, byte* payload, unsigned int length) {
    // 将payload转换为字符串
    char message[length + 1];
    memcpy(message, payload, length);
    message[length] = '\0';
    
    Serial.println("[MQTT] Received: " + String(topic) + " -> " + String(message));
    
    // 根据Topic路由到对应的处理函数
    if (strcmp(topic, MQTT_TOPIC_FAN_CONTROL) == 0) {
        handleFanControlCommand(message);
    } else if (strcmp(topic, MQTT_TOPIC_FAN_MODE) == 0) {
        handleFanModeCommand(message);
    } else if (strcmp(topic, MQTT_TOPIC_PUMP_CONTROL) == 0) {
        handlePumpControlCommand(message);
    } else if (strcmp(topic, MQTT_TOPIC_PUMP_MODE) == 0) {
        handlePumpModeCommand(message);
    } else if (strcmp(topic, MQTT_TOPIC_BUZZER_CONTROL) == 0) {
        handleBuzzerControlCommand(message);
    } else if (strcmp(topic, MQTT_TOPIC_BUZZER_MODE) == 0) {
        handleBuzzerModeCommand(message);
    }
}

// 风扇控制命令处理示例
void handleFanControlCommand(const char* payload) {
    JsonDocument doc;
    if (deserializeJson(doc, payload)) return;  // JSON解析失败
    
    const char* action = doc["action"];
    if (!action) return;
    
    // 自动模式下忽略控制命令
    if (isFanAutoMode()) {
        Serial.println("[MQTT] Fan control ignored - AUTO mode");
        return;
    }
    
    // 执行控制动作
    if (strcmp(action, "on") == 0) fanOn();
    else if (strcmp(action, "off") == 0) fanOff();
}
```

**控制命令JSON格式：**

```json
// 开启风扇
{"action": "on"}

// 关闭风扇
{"action": "off"}

// 切换到手动模式
{"action": "manual"}

// 切换到自动模式
{"action": "auto"}
```

### 6.7 MQTT任务（FreeRTOS）

```cpp
void mqttTask(void *pvParameters) {
    Serial.println("[MQTT] Task started on Core " + String(xPortGetCoreID()));

    for (;;) {
        // 1. 检查MQTT连接，必要时重连
        if (!mqttClient.connected()) {
            reconnectMQTT();
        }
        
        // 2. 处理MQTT消息（接收回调）
        mqttClient.loop();

        // 3. 获取传感器数据（线程安全）
        float temperature, humidity, smokeLevel;
        bool smokeAlarm;
        if(xSemaphoreTake(sensorMutex, portMAX_DELAY) == pdTRUE) {
            temperature = sensorData.temperature;
            humidity = sensorData.humidity;
            smokeLevel = sensorData.smokeLevel;
            smokeAlarm = sensorData.smokeAlarm;
            xSemaphoreGive(sensorMutex);
        }

        // 4. 发布传感器数据
        if (!isnan(humidity) && !isnan(temperature)) {
            publishSensorData(temperature, humidity, smokeLevel, smokeAlarm);
        }

        // 5. 任务周期：1秒
        vTaskDelay(pdMS_TO_TICKS(1000));
    }
}
```

### 6.8 MQTT通信时序图

```
┌────────┐          ┌────────────┐          ┌────────┐
│ ESP32  │          │MQTT Broker │          │手机APP │
└───┬────┘          └─────┬──────┘          └───┬────┘
    │                     │                     │
    │ ──CONNECT─────────► │                     │
    │ ◄──CONNACK───────── │                     │
    │                     │                     │
    │ ──SUBSCRIBE───────► │                     │
    │   (fan/control)     │                     │
    │ ◄──SUBACK────────── │                     │
    │                     │                     │
    │ ──PUBLISH─────────► │                     │
    │   (sensor_data)     │ ──PUBLISH─────────► │
    │                     │   (sensor_data)     │
    │                     │                     │
    │                     │ ◄──PUBLISH───────── │
    │ ◄──PUBLISH───────── │   (fan/control)     │
    │   (fan/control)     │                     │
    │                     │                     │
    │   [执行风扇控制]     │                     │
    │                     │                     │
```

---

## 7. 硬件引脚配置

| 模块 | 引脚 | GPIO | 说明 |
|------|------|------|------|
| DHT11 | DATA | GPIO 9 | 温湿度数据线 |
| MQ-2 | AO | GPIO 15 | 烟雾模拟输出 |
| MQ-2 | DO | GPIO 16 | 烟雾数字报警 |
| K230 | RX | GPIO 18 | 串口接收 |
| K230 | TX | GPIO 17 | 串口发送 |
| 风扇继电器 | IN | GPIO 13 | 低电平触发 |
| 水泵继电器 | IN | GPIO 14 | 高电平触发 |
| 蜂鸣器 | + | GPIO 8 | 低电平触发 |
| RGB LED | DATA | GPIO 48 | ESP32-S3内置 |

---

## 8. 模块说明

### 8.1 传感器模块

#### DHT11 温湿度传感器

- **采样周期**: 2秒
- **温度范围**: 0~50°C，精度±2°C
- **湿度范围**: 20%~90%RH，精度±5%RH

#### MQ-2 烟雾传感器

- **检测气体**: 可燃气体、烟雾
- **输出方式**: 模拟输出(AO) + 数字报警(DO)
- **报警阈值**: 浓度 > 30% 或 DO低电平

#### K230 视觉模块

- **通信方式**: UART串口 (115200bps)
- **检测协议**: 接收字符串"fire"表示检测到火焰
- **确认机制**: 连续1次检测即确认（可调整防抖次数）

### 8.2 执行器模块

#### 风扇控制

- **控制方式**: 继电器NO口
- **触发电平**: GPIO输出高电平 → 继电器闭合 → 风扇转动
- **保护机制**: 无

#### 水泵控制

- **控制方式**: 继电器NO口
- **触发电平**: GPIO输出高电平 → 继电器闭合 → 水泵工作
- **保护机制**:
  - 单次最大喷水时间: 5秒
  - 喷水后冷却时间: 10秒

#### 蜂鸣器控制

- **控制方式**: GPIO直驱
- **触发电平**: 低电平响
- **警报模式**: 间歇鸣叫（500ms响 / 300ms停）

---

## 总结

本ESP32消防灭火系统采用了现代嵌入式系统的最佳实践：

1. **模块化架构** - 每个硬件模块独立封装，便于维护和扩展
2. **FreeRTOS多任务** - 充分利用双核性能，任务间通过互斥锁安全通信
3. **状态机设计** - 设备状态清晰可控，支持自动/手动双模式
4. **MQTT物联网通信** - 轻量级协议，支持远程监控和控制
5. **多传感器融合** - 温度+烟雾+视觉三重检测，提高火灾识别准确率

---

*文档版本: 1.0*
*更新日期: 2026年1月21日*
