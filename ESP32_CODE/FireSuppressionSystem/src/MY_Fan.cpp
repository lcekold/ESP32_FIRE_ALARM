#include "MY_Fan.h"
#include "MY_DHT11.h"
#include "MY_MQ2.h"
#include "MY_Sensor.h"
#include "MY_K230.h"

// ==================== 全局变量定义 ====================
FanControl fanControl = {
    .state = FAN_OFF,
    .mode = FAN_MODE_AUTO,      // 默认自动模式
    .alarmReason = ALARM_NONE,
    .lastChange = 0,
    .lastTemp = 0.0f,
    .lastHumidity = 0.0f,
    .lastSmokeLevel = 0.0f,
    .lastSmokeAlarm = false
};

TaskHandle_t fanTaskHandle = NULL;
SemaphoreHandle_t fanMutex = NULL;

// ==================== 初始化函数 ====================

/**
 * @brief 初始化风扇控制模块
 */
void setupFan() {
    // 创建互斥锁
    fanMutex = xSemaphoreCreateMutex();
    
    // 配置GPIO
    pinMode(FAN_RELAY_PIN, OUTPUT);
    digitalWrite(FAN_RELAY_PIN, LOW);  // 初始关闭 (高电平断开继电器)
    
    fanControl.state = FAN_OFF;
    fanControl.mode = FAN_MODE_AUTO;
    fanControl.alarmReason = ALARM_NONE;
    fanControl.lastChange = millis();
    
    Serial.println("[FAN] ========== Fan Module Init ==========");
    Serial.println("[FAN] GPIO: " + String(FAN_RELAY_PIN));
    Serial.println("[FAN] Mode: AUTO (default)");
    Serial.println("[FAN] Temp Alarm Threshold: " + String(TEMP_ALARM_THRESHOLD) + "°C");
    Serial.println("[FAN] Smoke Alarm Threshold: " + String(SMOKE_ALARM_THRESHOLD) + "%");
    Serial.println("[FAN] ======================================");
}

// ==================== 风扇控制函数 ====================

/**
 * @brief 开启风扇
 * 低电平触发继电器，NO口闭合，风扇转动
 */
void fanOn() {
    if (xSemaphoreTake(fanMutex, portMAX_DELAY) == pdTRUE) {
        if (fanControl.state != FAN_ON) {
            digitalWrite(FAN_RELAY_PIN, HIGH);
            fanControl.state = FAN_ON;
            fanControl.lastChange = millis();
            Serial.println("[FAN] >>> FAN TURNED ON <<<");
        }
        xSemaphoreGive(fanMutex);
    }
}

/**
 * @brief 关闭风扇
 * 高电平断开继电器，NO口断开，风扇停止
 */
void fanOff() {
    if (xSemaphoreTake(fanMutex, portMAX_DELAY) == pdTRUE) {
        if (fanControl.state != FAN_OFF) {
            digitalWrite(FAN_RELAY_PIN, LOW);
            fanControl.state = FAN_OFF;
            fanControl.alarmReason = ALARM_NONE;
            fanControl.lastChange = millis();
            Serial.println("[FAN] Fan turned OFF");
        }
        xSemaphoreGive(fanMutex);
    }
}

/**
 * @brief 切换风扇状态
 */
void fanToggle() {
    if (getFanState() == FAN_ON) {
        fanOff();
    } else {
        fanOn();
    }
}

// ==================== 状态获取函数 ====================

FanState getFanState() {
    FanState state = FAN_OFF;
    if (xSemaphoreTake(fanMutex, portMAX_DELAY) == pdTRUE) {
        state = fanControl.state;
        xSemaphoreGive(fanMutex);
    }
    return state;
}

FanMode getFanMode() {
    FanMode mode = FAN_MODE_AUTO;
    if (xSemaphoreTake(fanMutex, portMAX_DELAY) == pdTRUE) {
        mode = fanControl.mode;
        xSemaphoreGive(fanMutex);
    }
    return mode;
}

AlarmReason getAlarmReason() {
    AlarmReason reason = ALARM_NONE;
    if (xSemaphoreTake(fanMutex, portMAX_DELAY) == pdTRUE) {
        reason = fanControl.alarmReason;
        xSemaphoreGive(fanMutex);
    }
    return reason;
}

// ==================== 模式设置函数 ====================

/**
 * @brief 设置风扇控制模式
 * @param mode FAN_MODE_AUTO 或 FAN_MODE_MANUAL
 */
void setFanMode(FanMode mode) {
    if (xSemaphoreTake(fanMutex, portMAX_DELAY) == pdTRUE) {
        if (fanControl.mode != mode) {
            fanControl.mode = mode;
            Serial.println("[FAN] Mode changed to: " + String(mode == FAN_MODE_AUTO ? "AUTO" : "MANUAL"));
            
            // 切换到自动模式时，立即根据当前传感器数据判断
            if (mode == FAN_MODE_AUTO) {
                xSemaphoreGive(fanMutex);
                // 触发一次自动控制判断
                updateFanAutoControl(
                    fanControl.lastTemp,
                    fanControl.lastHumidity,
                    fanControl.lastSmokeLevel,
                    fanControl.lastSmokeAlarm
                );
                return;
            }
        }
        xSemaphoreGive(fanMutex);
    }
}

bool isFanAutoMode() {
    return getFanMode() == FAN_MODE_AUTO;
}

// ==================== 状态字符串转换 ====================

const char* getFanStateString() {
    return getFanState() == FAN_ON ? "on" : "off";
}

const char* getFanModeString() {
    return getFanMode() == FAN_MODE_AUTO ? "auto" : "manual";
}


// ==================== 自动控制核心函数 ====================

/**
 * @brief 根据传感器数据自动控制风扇
 * 
 * 火灾判定逻辑：
 * - 温度 > 50°C  → 高温报警，开启风扇
 * - 烟雾浓度 > 30% 或 烟雾报警触发 → 烟雾报警，开启风扇
 * 
 * 安全恢复逻辑：
 * - 温度 < 40°C 且 烟雾浓度 < 15% 且 无烟雾报警 → 关闭风扇
 * 
 * @param temperature 当前温度 (摄氏度)
 * @param humidity 当前湿度 (百分比)
 * @param smokeLevel 当前烟雾浓度 (百分比)
 * @param smokeAlarm 烟雾报警状态 (MQ2数字输出)
 */
void updateFanAutoControl(float temperature, float humidity, float smokeLevel, bool smokeAlarm) {
    // 仅在自动模式下执行
    if (getFanMode() != FAN_MODE_AUTO) {
        return;
    }
    
    // 更新传感器数据缓存
    if (xSemaphoreTake(fanMutex, portMAX_DELAY) == pdTRUE) {
        fanControl.lastTemp = temperature;
        fanControl.lastHumidity = humidity;
        fanControl.lastSmokeLevel = smokeLevel;
        fanControl.lastSmokeAlarm = smokeAlarm;
        xSemaphoreGive(fanMutex);
    }
    
    // 判断是否处于火灾环境
    bool highTemp = (temperature > TEMP_ALARM_THRESHOLD);
    bool smokeDetected = (smokeLevel > SMOKE_ALARM_THRESHOLD) || smokeAlarm;
    
    // 确定报警原因
    AlarmReason reason = ALARM_NONE;
    if (highTemp && smokeDetected) {
        reason = ALARM_BOTH;
    } else if (highTemp) {
        reason = ALARM_HIGH_TEMP;
    } else if (smokeDetected) {
        reason = ALARM_SMOKE_DETECTED;
    }

    // K230火焰确认
    int K230FireConfirmed = 0;
    if(xSemaphoreTake(k230Mutex, portMAX_DELAY) == pdTRUE){
        K230FireConfirmed = k230Control.fireState;
        xSemaphoreGive(k230Mutex);
    }

    if(K230FireConfirmed == K230_FIRE_CONFIRMED){
        reason = ALARM_BOTH; // K230确认火焰检测时强制触发风扇开启
    }

    // 火灾检测：开启风扇
    if (reason != ALARM_NONE) {
        if (xSemaphoreTake(fanMutex, portMAX_DELAY) == pdTRUE) {
            fanControl.alarmReason = reason;
            xSemaphoreGive(fanMutex);
        }
        
        if (getFanState() != FAN_ON) {
            Serial.println("[FAN] !!! FIRE DETECTED !!!");
            Serial.println("[FAN] Reason: " + String(
                reason == ALARM_BOTH ? "High Temp + Smoke" :
                reason == ALARM_HIGH_TEMP ? "High Temperature" : "Smoke Detected"
            )); 
            Serial.println("[FAN] Temp: " + String(temperature) + "°C, Smoke: " + String(smokeLevel) + "%");
            fanOn();
        }
        return;
    }
    
    // 安全恢复：关闭风扇
    bool tempSafe = (temperature < TEMP_SAFE_THRESHOLD);
    bool smokeSafe = (smokeLevel < SMOKE_SAFE_THRESHOLD) && !smokeAlarm;
    
    if (tempSafe && smokeSafe && K230FireConfirmed != K230_FIRE_CONFIRMED) {
        if (getFanState() == FAN_ON) {
            Serial.println("[FAN] Environment safe, turning off fan");
            Serial.println("[FAN] Temp: " + String(temperature) + "°C, Smoke: " + String(smokeLevel) + "%");
            fanOff();
        }
    }
}

// ==================== RTOS任务函数 ====================

/**
 * @brief 风扇控制RTOS任务
 * 
 * 独立运行的任务，周期性读取传感器数据并执行自动控制
 * 任务周期：1秒
 */
void fanTask(void *pvParameters) {
    Serial.println("[FAN] Fan control task started on Core " + String(xPortGetCoreID()));
    
    // 等待传感器预热
    vTaskDelay(pdMS_TO_TICKS(2000)); 
    
    for (;;) {
        // 仅在自动模式下读取传感器并控制
        if (isFanAutoMode()) {
        
            // 获取传感器数据
            float temperature;
            float humidity;
            float smokeLevel;
            bool  smokeAlarm;
            if(xSemaphoreTake(sensorMutex,portMAX_DELAY)==pdTRUE){
                temperature = sensorData.temperature;
                humidity = sensorData.humidity;
                smokeLevel = sensorData.smokeLevel;
                smokeAlarm = sensorData.smokeAlarm;
                xSemaphoreGive(sensorMutex);
            }

            // 检查DHT读取是否有效
            if(!isnan(humidity) && !isnan(temperature)){
                // 执行自动控制逻辑
                updateFanAutoControl(temperature, humidity, smokeLevel, smokeAlarm);
            }
        }
        
        // 任务周期：1秒
        vTaskDelay(pdMS_TO_TICKS(1000));
    }
}
