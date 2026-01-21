#include <Arduino.h>
#include "MY_Buzzer.h"
#include "MY_Fan.h"  // 引入火灾检测阈值定义
#include "MY_DHT11.h"
#include "MY_MQ2.h"
#include "MY_Sensor.h"
#include "MY_K230.h"

// ==================== 全局变量定义 ====================
BuzzerControl buzzerControl = {
    .state = BUZZER_OFF,
    .mode = BUZZER_MODE_AUTO,
    .lastChange = 0,
    .alarmStart = 0,
    .fireDetected = false,
    .timeoutActive = false
};

TaskHandle_t buzzerTaskHandle = NULL;
SemaphoreHandle_t buzzerMutex = NULL;

// 内部变量：蜂鸣器当前输出状态（用于产生间歇警报）
static bool buzzerOutput = false;
static unsigned long lastBeepToggle = 0;

// ==================== 初始化函数 ====================

void setupBuzzer() {
    // 创建互斥锁
    buzzerMutex = xSemaphoreCreateMutex();
    
    // 配置GPIO
    pinMode(BUZZER_PIN, OUTPUT);
    digitalWrite(BUZZER_PIN, HIGH);  // 初始关闭
    
    buzzerControl.state = BUZZER_OFF;
    buzzerControl.mode = BUZZER_MODE_AUTO;
    buzzerControl.lastChange = millis();
    
    Serial.println("[BUZZER] ========== Buzzer Module Init ==========");
    Serial.println("[BUZZER] GPIO: " + String(BUZZER_PIN));
    Serial.println("[BUZZER] Mode: AUTO (default)");
    Serial.println("[BUZZER] Beep Pattern: " + String(BUZZER_BEEP_ON_MS) + "ms ON / " + String(BUZZER_BEEP_OFF_MS) + "ms OFF");
    Serial.println("[BUZZER] ==========================================");
}

// ==================== 蜂鸣器控制函数 ====================

/**
 * @brief 开启蜂鸣器警报
 */
void buzzerOn() {
    if (xSemaphoreTake(buzzerMutex, portMAX_DELAY) == pdTRUE) {
        if (buzzerControl.state != BUZZER_ON) {
            buzzerControl.state = BUZZER_ON;
            buzzerControl.lastChange = millis();
            buzzerControl.alarmStart = millis();
            buzzerOutput = true;
            lastBeepToggle = millis();
            digitalWrite(BUZZER_PIN, LOW);
            Serial.println("[BUZZER] >>> ALARM ACTIVATED <<<");
        }
        xSemaphoreGive(buzzerMutex);
    }
}

/**
 * @brief 关闭蜂鸣器
 */
void buzzerOff() {
    if (xSemaphoreTake(buzzerMutex, portMAX_DELAY) == pdTRUE) {
        if (buzzerControl.state != BUZZER_OFF) {
            digitalWrite(BUZZER_PIN, HIGH);
            buzzerControl.state = BUZZER_OFF;
            buzzerControl.lastChange = millis();
            buzzerOutput = false;
            Serial.println("[BUZZER] Alarm deactivated");
        }
        xSemaphoreGive(buzzerMutex);
    }
}

/**
 * @brief 切换蜂鸣器状态
 */
void buzzerToggle() {
    if (getBuzzerState() == BUZZER_ON) {
        buzzerOff();
    } else {
        buzzerOn();
    }
}

// ==================== 状态获取函数 ====================

BuzzerState getBuzzerState() {
    BuzzerState state = BUZZER_OFF;
    if (xSemaphoreTake(buzzerMutex, portMAX_DELAY) == pdTRUE) {
        state = buzzerControl.state;
        xSemaphoreGive(buzzerMutex);
    }
    return state;
}

BuzzerMode getBuzzerMode() {
    BuzzerMode mode = BUZZER_MODE_AUTO;
    if (xSemaphoreTake(buzzerMutex, portMAX_DELAY) == pdTRUE) {
        mode = buzzerControl.mode;
        xSemaphoreGive(buzzerMutex);
    }
    return mode;
}

// ==================== 模式设置函数 ====================

void setBuzzerMode(BuzzerMode mode) {
    if (xSemaphoreTake(buzzerMutex, portMAX_DELAY) == pdTRUE) {
        if (buzzerControl.mode != mode) {
            buzzerControl.mode = mode;
            Serial.println("[BUZZER] Mode changed to: " + String(mode == BUZZER_MODE_AUTO ? "AUTO" : "MANUAL"));
            
            // 切换到手动模式时，关闭蜂鸣器
            if (mode == BUZZER_MODE_MANUAL && buzzerControl.state == BUZZER_ON) {
                xSemaphoreGive(buzzerMutex);
                buzzerOff();
                return;
            }
        }
        xSemaphoreGive(buzzerMutex);
    }
}

bool isBuzzerAutoMode() {
    return getBuzzerMode() == BUZZER_MODE_AUTO;
}

// ==================== 状态字符串转换 ====================

const char* getBuzzerStateString() {
    return getBuzzerState() == BUZZER_ON ? "on" : "off";
}

const char* getBuzzerModeString() {
    return getBuzzerMode() == BUZZER_MODE_AUTO ? "auto" : "manual";
}

// ==================== 自动控制函数 ====================

/**
 * @brief 根据火灾检测状态自动控制蜂鸣器（K230触发）
 * @param fireDetected 是否检测到火灾
 */
void updateBuzzerAutoControl(bool fireDetected) {
    // 仅在自动模式下执行
    if (!isBuzzerAutoMode()) {
        return;
    }
    
    // 更新火灾检测状态
    if (xSemaphoreTake(buzzerMutex, portMAX_DELAY) == pdTRUE) {
        buzzerControl.fireDetected = fireDetected;
        xSemaphoreGive(buzzerMutex);
    }
    
    // 火灾检测：开启警报
    if (fireDetected) {
        if (getBuzzerState() != BUZZER_ON) {
            Serial.println("[BUZZER] !!! FIRE DETECTED (K230) - ALARM ON !!!");
            buzzerOn();
        }
    } else {
        // 火灾解除：关闭警报
        if (getBuzzerState() == BUZZER_ON) {
            Serial.println("[BUZZER] Fire cleared (K230), alarm off");
            buzzerOff();
        }
    }
}

/**
 * @brief 根据传感器数据自动控制蜂鸣器（温度/烟雾触发）
 * 
 * 火灾判定逻辑（与风扇相同）：
 * - 温度 > 50°C → 高温报警
 * - 烟雾浓度 > 30% 或 烟雾报警触发 → 烟雾报警
 * 
 * 安全恢复逻辑：
 * - 温度 < 40°C 且 烟雾浓度 < 15% 且 无烟雾报警 → 关闭警报
 * 
 * @param temperature 当前温度 (摄氏度)
 * @param smokeLevel 当前烟雾浓度 (百分比)
 * @param smokeAlarm 烟雾报警状态 (MQ2数字输出)
 */
void updateBuzzerAutoControlBySensor(float temperature, float smokeLevel, bool smokeAlarm) {
    // 仅在自动模式下执行
    if (!isBuzzerAutoMode()) {
        return;
    }
    
    // 判断是否处于火灾环境（使用与风扇相同的阈值）
    bool highTemp = (temperature > TEMP_ALARM_THRESHOLD);
    bool smokeDetected = (smokeLevel > SMOKE_ALARM_THRESHOLD) || smokeAlarm;
    bool fireDetected = highTemp || smokeDetected;

    // 更新火灾检测状态
    if (xSemaphoreTake(buzzerMutex, portMAX_DELAY) == pdTRUE) {
        buzzerControl.fireDetected = fireDetected;
        xSemaphoreGive(buzzerMutex);
    }

    // k230火焰确认
    // K230火焰确认
    int K230FireConfirmed = 0;
    if(xSemaphoreTake(k230Mutex, portMAX_DELAY) == pdTRUE){
        K230FireConfirmed = k230Control.fireState;
        xSemaphoreGive(k230Mutex);
    }
    
    if(K230FireConfirmed == K230_FIRE_CONFIRMED){
        buzzerControl.fireDetected = true; // K230确认火焰检测时强制触发警报
    }
    
    // 火灾检测：开启警报
    if (fireDetected) {
        if (getBuzzerState() != BUZZER_ON) {
            Serial.println("[BUZZER] !!! FIRE DETECTED (Sensor) - ALARM ON !!!");
            Serial.println("[BUZZER] Temp: " + String(temperature) + "°C, Smoke: " + String(smokeLevel) + "%");

            // 报警的时候响一会儿然后关闭一会儿，然后重复这个状态
            unsigned long interval = buzzerOutput ? BUZZER_BEEP_ON_MS : BUZZER_BEEP_OFF_MS;
            
            if (millis() - lastBeepToggle >= interval) {
                buzzerOutput = !buzzerOutput;
                if(buzzerOutput==BUZZER_BEEP_ON_MS){
                    buzzerOn();
                }else if(buzzerOutput==BUZZER_BEEP_OFF_MS){
                    buzzerOff();
                }

                lastBeepToggle = millis();
            }

        }
        return;
    }
    
    // 安全恢复：关闭警报
    bool tempSafe = (temperature < TEMP_SAFE_THRESHOLD);
    bool smokeSafe = (smokeLevel < SMOKE_SAFE_THRESHOLD) && !smokeAlarm;
    
    if (tempSafe && smokeSafe && K230FireConfirmed != K230_FIRE_CONFIRMED) {
        buzzerControl.fireDetected = false;
        if (getBuzzerState() == BUZZER_ON) {
            Serial.println("[BUZZER] Environment safe (Sensor), alarm off");
            buzzerOff();
        }
    }
}

// ==================== RTOS任务函数 ====================

/**
 * @brief 蜂鸣器控制RTOS任务
 * 
 * 职责：
 * 1. 产生间歇性警报声（ON/OFF交替）
 * 2. 检查自动关闭超时
 * 3. 与其他模块协同工作
 */
void buzzerTask(void *pvParameters) {
    Serial.println("[BUZZER] Buzzer task started on Core " + String(xPortGetCoreID()));
    
    // 等待系统初始化
    vTaskDelay(pdMS_TO_TICKS(2000));
    
    for (;;) {
        
        float temperature;
        float humidity;
        float smokeLevel;
        bool  smokeAlarm;
        // 更新传感器数据缓存
        if(xSemaphoreTake(sensorMutex,portMAX_DELAY)==pdTRUE){
            temperature = sensorData.temperature;
            humidity = sensorData.humidity;
            smokeLevel = sensorData.smokeLevel;
            smokeAlarm = sensorData.smokeAlarm;
            xSemaphoreGive(sensorMutex);
        }


        // 检查DHT读取是否有效
        if(!isnan(humidity) && !isnan(temperature)){
            updateBuzzerAutoControlBySensor(temperature, smokeLevel, smokeAlarm);
        }

        // 处理超时
        unsigned long now = millis();
        if(isBuzzerAutoMode()){
            if(xSemaphoreTake(buzzerMutex,pdMS_TO_TICKS(10))==pdTRUE){
                if(now - buzzerControl.alarmStart >= BUZZER_AUTO_OFF_MS){
                    buzzerControl.timeoutActive = true; // 标记已经超时
                    xSemaphoreGive(buzzerMutex);

                    buzzerOff();
                } else{
                    xSemaphoreGive(buzzerMutex);
                }
            }
        }
        
        // 任务周期：50ms（确保警报节奏准确）
        vTaskDelay(pdMS_TO_TICKS(50));
    }
}
