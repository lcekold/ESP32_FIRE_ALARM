#include <Arduino.h>
#include "MY_K230.h"
#include "MY_Fan.h"
#include "MY_Pump.h"
#include "MY_Buzzer.h"

// ==================== 全局变量定义 ====================
K230Control k230Control = {
    .fireState = K230_FIRE_NONE,
    .lastFireTime = 0,
    .fireStartTime = 0,
    .fireCount = 0,
    .totalFireEvents = 0,
    .suppressionActive = false
};

TaskHandle_t k230TaskHandle = NULL;
SemaphoreHandle_t k230Mutex = NULL;

// 内部缓冲区
static char rxBuffer[K230_BUFFER_SIZE];
static uint8_t rxIndex = 0;

// ==================== 初始化函数 ====================

/**
 * @brief 初始化K230串口通信模块
 */
void setupK230() {
    // 创建互斥锁
    k230Mutex = xSemaphoreCreateMutex();
    
    // 初始化串口1用于K230通信
    K230_SERIAL.begin(K230_BAUD_RATE, SERIAL_8N1, K230_RX_PIN, K230_TX_PIN);
    
    // 清空接收缓冲区
    while (K230_SERIAL.available()) {
        K230_SERIAL.read();
    }
    
    Serial.println("[K230] ========== K230 Module Init ==========");
    Serial.println("[K230] Serial: Serial1");
    Serial.println("[K230] Baud Rate: " + String(K230_BAUD_RATE));
    Serial.println("[K230] RX Pin: " + String(K230_RX_PIN));
    Serial.println("[K230] TX Pin: " + String(K230_TX_PIN));
    Serial.println("[K230] Fire Command: \"" + String(K230_FIRE_CMD) + "\"");
    Serial.println("[K230] ========================================");
}

// ==================== 状态获取函数 ====================

K230FireState getK230FireState() {
    K230FireState state = K230_FIRE_NONE;
    if (xSemaphoreTake(k230Mutex, portMAX_DELAY) == pdTRUE) {
        state = k230Control.fireState;
        xSemaphoreGive(k230Mutex);
    }
    return state;
}

bool isK230FireDetected() {
    return getK230FireState() != K230_FIRE_NONE;
}

unsigned long getK230LastFireTime() {
    unsigned long time = 0;
    if (xSemaphoreTake(k230Mutex, portMAX_DELAY) == pdTRUE) {
        time = k230Control.lastFireTime;
        xSemaphoreGive(k230Mutex);
    }
    return time;
}

// ==================== 状态字符串转换 ====================

const char* getK230FireStateString() {
    K230FireState state = getK230FireState();
    switch (state) {
        case K230_FIRE_DETECTED:  return "detected";
        case K230_FIRE_CONFIRMED: return "confirmed";
        default:                  return "none";
    }
}

// ==================== 火焰处理函数 ====================

/**
 * @brief 处理K230检测到火焰事件
 * 
 * 触发灭火响应：
 * 1. 立即开启蜂鸣器警报
 * 2. 立即开启风扇（排烟）
 * 3. 立即启动水泵喷水（灭火）
 * 4. 更新状态供MQTT上报
 */
void handleK230FireDetected() {
    if (xSemaphoreTake(k230Mutex, portMAX_DELAY) == pdTRUE) {
        unsigned long now = millis();
        
        // 更新火焰检测时间
        k230Control.lastFireTime = now;
        k230Control.fireCount++;
        
        // 首次检测到火焰
        if (k230Control.fireState == K230_FIRE_NONE) {
            k230Control.fireState = K230_FIRE_DETECTED;
            k230Control.fireStartTime = now;
            k230Control.totalFireEvents++;
            
            Serial.println("[K230] !!! FIRE DETECTED BY VISION !!!");
            Serial.println("[K230] Event #" + String(k230Control.totalFireEvents));
        }
        
        // 检查是否需要确认（防抖）
        if (k230Control.fireCount >= K230_FIRE_CONFIRM_COUNT && 
            k230Control.fireState == K230_FIRE_DETECTED) {
            k230Control.fireState = K230_FIRE_CONFIRMED;
            k230Control.suppressionActive = true;
            
            Serial.println("[K230] >>> FIRE CONFIRMED - ACTIVATING SUPPRESSION <<<");
        }
        
        xSemaphoreGive(k230Mutex);
    }
    
    // 触发灭火系统（在互斥锁外执行，避免死锁）
    if (getK230FireState() == K230_FIRE_CONFIRMED) {
        // 开启蜂鸣器警报
        updateBuzzerAutoControl(true);
        
        // 开启风扇排烟（仅自动模式）
        if (isFanAutoMode() && getFanState() != FAN_ON) {
            Serial.println("[K230] Activating fan for smoke extraction");
            fanOn();
        }
        
        // 启动水泵喷水（仅自动模式）
        if (isPumpAutoMode()) {
            PumpState pumpState = getPumpState();
            if (pumpState == PUMP_OFF) {
                Serial.println("[K230] Activating pump for fire suppression");
                pumpSpray(K230_PUMP_SPRAY_MS);
            } else if (pumpState == PUMP_COOLDOWN && isPumpAvailable()) {
                Serial.println("[K230] Pump ready, continuing suppression");
                pumpSpray(K230_PUMP_SPRAY_MS);
            }
        }
    }
}

/**
 * @brief 重置K230火焰状态
 * 
 * 当超过超时时间未收到火焰信号时调用
 * 同时关闭蜂鸣器，并检查是否需要关闭风扇和水泵
 */
void resetK230FireState() {
    bool wasActive = false;
    
    if (xSemaphoreTake(k230Mutex, portMAX_DELAY) == pdTRUE) {
        if (k230Control.fireState != K230_FIRE_NONE) {
            unsigned long duration = millis() - k230Control.fireStartTime;
            Serial.println("[K230] Fire event ended, duration: " + String(duration / 1000.0, 1) + "s");
            
            wasActive = k230Control.suppressionActive;
            k230Control.fireState = K230_FIRE_NONE;
            k230Control.fireCount = 0;
            k230Control.suppressionActive = false;
        }
        xSemaphoreGive(k230Mutex);
    }
    
    // 如果之前灭火系统是激活状态，现在需要关闭
    if (wasActive) {
        // 关闭蜂鸣器警报
        updateBuzzerAutoControl(false);
        
        // 关闭风扇（仅自动模式，且传感器数据正常时）
        if (isFanAutoMode() && getFanState() == FAN_ON) {
            Serial.println("[K230] Fire cleared, turning off fan");
            fanOff();
        }
        
        // 水泵会自动关闭（有定时器），这里不需要手动关闭
        Serial.println("[K230] Suppression system deactivated");
    }
}

// ==================== 串口数据解析 ====================

/**
 * @brief 解析接收到的串口数据
 * @param data 接收到的字符串
 * @return true=识别到有效命令, false=无效数据
 */
static bool parseK230Data(const char* data) {
    // 去除首尾空白字符进行比较
    String cmd = String(data);
    cmd.trim();
    
    if (cmd.equalsIgnoreCase(K230_FIRE_CMD)) {
        return true;
    }
    
    return false;
}

/**
 * @brief 处理串口接收的单个字符
 * @param c 接收到的字符
 */
static void processK230Char(char c) {
    // 遇到换行符，处理完整命令
    if (c == '\n' || c == '\r') {
        if (rxIndex > 0) {
            rxBuffer[rxIndex] = '\0';
            
            // 解析命令
            if (parseK230Data(rxBuffer)) {
                handleK230FireDetected();
            }
            
            // 重置缓冲区
            rxIndex = 0;
        }
        return;
    }
    
    // 存储字符到缓冲区
    if (rxIndex < K230_BUFFER_SIZE - 1) {
        rxBuffer[rxIndex++] = c;
    } else {
        // 缓冲区溢出，重置
        rxIndex = 0;
    }
}

// ==================== RTOS任务函数 ====================

/**
 * @brief K230串口通信RTOS任务
 * 
 * 高优先级任务，负责：
 * 1. 实时读取K230串口数据
 * 2. 解析火焰检测命令
 * 3. 触发灭火响应
 * 4. 管理火焰状态超时
 * 
 * 任务周期：10ms（高频轮询确保快速响应）
 */
void k230Task(void *pvParameters) {
    Serial.println("[K230] K230 task started on Core " + String(xPortGetCoreID()));
    Serial.println("[K230] Waiting for fire detection signals...");
    
    // 等待系统初始化
    vTaskDelay(pdMS_TO_TICKS(1000));
    
    for (;;) {
        // 1. 读取串口数据（非阻塞）
        while (K230_SERIAL.available()) {
            char c = K230_SERIAL.read();
            processK230Char(c);
        }
        
        // 2. 检查火焰状态超时
        if (isK230FireDetected()) {
            unsigned long lastFire = getK230LastFireTime();
            if (millis() - lastFire > K230_FIRE_TIMEOUT_MS) {
                Serial.println("[K230] Fire signal timeout, resetting state");
                resetK230FireState();
            }
        }
        
        // 3. 高频轮询，确保快速响应
        vTaskDelay(pdMS_TO_TICKS(10));
    }
}
