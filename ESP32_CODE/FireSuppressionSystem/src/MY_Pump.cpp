#include "MY_Pump.h"
#include "MY_DHT11.h"
#include "MY_MQ2.h"
#include "MY_Fan.h"
#include "MY_Sensor.h"
#include "MY_K230.h"
// ==================== 全局变量定义 ====================
PumpControl pumpControl = {
    .state = PUMP_OFF,
    .mode = PUMP_MODE_AUTO,
    .lastStartTime = 0,
    .lastStopTime = 0,
    .totalSprayTime = 0,
    .sprayCount = 0,
    .fireDetected = false
};

TaskHandle_t pumpTaskHandle = NULL;
SemaphoreHandle_t pumpMutex = NULL;

// 内部变量：自动关闭定时器
static unsigned long autoStopTime = 0;
static bool autoStopEnabled = false;

// ==================== 初始化函数 ====================

void setupPump() {
    // 创建互斥锁
    pumpMutex = xSemaphoreCreateMutex();
    
    // 配置GPIO
    pinMode(PUMP_RELAY_PIN, OUTPUT);
    digitalWrite(PUMP_RELAY_PIN, LOW);  // 初始关闭
    
    pumpControl.state = PUMP_OFF;
    pumpControl.mode = PUMP_MODE_AUTO;
    pumpControl.lastStopTime = millis();
    
    Serial.println("[PUMP] ========== Pump Module Init ==========");
    Serial.println("[PUMP] GPIO: " + String(PUMP_RELAY_PIN));
    Serial.println("[PUMP] Mode: AUTO (default)");
    Serial.println("[PUMP] Max spray duration: " + String(PUMP_MAX_DURATION_MS / 1000) + "s");
    Serial.println("[PUMP] Cooldown time: " + String(PUMP_COOLDOWN_MS / 1000) + "s");
    Serial.println("[PUMP] ========================================");
}

// ==================== 水泵控制函数 ====================

/**
 * @brief 开启水泵
 * 高电平触发继电器，NO口闭合，水泵启动
 */
void pumpOn() {
    if (xSemaphoreTake(pumpMutex, portMAX_DELAY) == pdTRUE) {
        // 检查是否在冷却中
        if (pumpControl.state == PUMP_COOLDOWN) {
            unsigned long remaining = getPumpRemainingCooldown();
            Serial.println("[PUMP] Pump in cooldown, " + String(remaining / 1000) + "s remaining");
            xSemaphoreGive(pumpMutex);
            return;
        }
        
        if (pumpControl.state != PUMP_ON) {
            digitalWrite(PUMP_RELAY_PIN, HIGH);  // 高电平触发
            pumpControl.state = PUMP_ON;
            pumpControl.lastStartTime = millis();
            pumpControl.sprayCount++;
            
            // 设置最大运行时间保护
            autoStopTime = millis() + PUMP_MAX_DURATION_MS;
            autoStopEnabled = true;
            
            Serial.println("[PUMP] >>> PUMP TURNED ON - SPRAYING <<<");
        }
        xSemaphoreGive(pumpMutex);
    }
}

/**
 * @brief 关闭水泵
 * 低电平断开继电器，NO口断开，水泵停止
 */
void pumpOff() {
    if (xSemaphoreTake(pumpMutex, portMAX_DELAY) == pdTRUE) {
        if (pumpControl.state == PUMP_ON) {
            digitalWrite(PUMP_RELAY_PIN, LOW);  // 低电平断开
            
            // 计算本次喷水时间
            unsigned long sprayDuration = millis() - pumpControl.lastStartTime;
            pumpControl.totalSprayTime += sprayDuration;
            
            // 进入冷却状态
            pumpControl.state = PUMP_COOLDOWN;
            pumpControl.lastStopTime = millis();
            autoStopEnabled = false;
            
            Serial.println("[PUMP] Pump turned OFF");
            Serial.println("[PUMP] Spray duration: " + String(sprayDuration / 1000.0, 1) + "s");
            Serial.println("[PUMP] Entering cooldown for " + String(PUMP_COOLDOWN_MS / 1000) + "s");
        }
        xSemaphoreGive(pumpMutex);
    }
}

/**
 * @brief 喷水指定时间后自动关闭
 * @param durationMs 喷水持续时间（毫秒）
 */
void pumpSpray(unsigned long durationMs) {
    // 限制最大喷水时间
    if (durationMs > PUMP_MAX_DURATION_MS) {
        durationMs = PUMP_MAX_DURATION_MS;
    }
    
    if (xSemaphoreTake(pumpMutex, portMAX_DELAY) == pdTRUE) {
        if (pumpControl.state == PUMP_OFF || pumpControl.state == PUMP_ON) {
            // 设置自动关闭时间
            autoStopTime = millis() + durationMs;
            autoStopEnabled = true;
            xSemaphoreGive(pumpMutex);
            
            // 开启水泵
            pumpOn();
            
            Serial.println("[PUMP] Spray scheduled for " + String(durationMs / 1000.0, 1) + "s");
        } else {
            xSemaphoreGive(pumpMutex);
        }
    }
}

// ==================== 状态获取函数 ====================

PumpState getPumpState() {
    PumpState state = PUMP_OFF;
    if (xSemaphoreTake(pumpMutex, portMAX_DELAY) == pdTRUE) {
        state = pumpControl.state;
        xSemaphoreGive(pumpMutex);
    }
    return state;
}

PumpMode getPumpMode() {
    PumpMode mode = PUMP_MODE_AUTO;
    if (xSemaphoreTake(pumpMutex, portMAX_DELAY) == pdTRUE) {
        mode = pumpControl.mode;
        xSemaphoreGive(pumpMutex);
    }
    return mode;
}

/**
 * @brief 检查水泵是否可用
 * @return true=可用, false=冷却中
 */
bool isPumpAvailable() {
    bool available = false;
    if (xSemaphoreTake(pumpMutex, portMAX_DELAY) == pdTRUE) {
        available = (pumpControl.state != PUMP_COOLDOWN);
        xSemaphoreGive(pumpMutex);
    }
    return available;
}

/**
 * @brief 获取剩余冷却时间
 * @return 剩余冷却时间（毫秒），0表示已就绪
 */
unsigned long getPumpRemainingCooldown() {
    unsigned long remaining = 0;
    if (xSemaphoreTake(pumpMutex, portMAX_DELAY) == pdTRUE) {
        if (pumpControl.state == PUMP_COOLDOWN) {
            unsigned long elapsed = millis() - pumpControl.lastStopTime;
            if (elapsed < PUMP_COOLDOWN_MS) {
                remaining = PUMP_COOLDOWN_MS - elapsed;
            }
        }
        xSemaphoreGive(pumpMutex);
    }
    return remaining;
}

// ==================== 模式设置函数 ====================

void setPumpMode(PumpMode mode) {
    if (xSemaphoreTake(pumpMutex, portMAX_DELAY) == pdTRUE) {
        if (pumpControl.mode != mode) {
            pumpControl.mode = mode;
            Serial.println("[PUMP] Mode changed to: " + String(mode == PUMP_MODE_AUTO ? "AUTO" : "MANUAL"));
        }
        xSemaphoreGive(pumpMutex);
    }
}

bool isPumpAutoMode() {
    return getPumpMode() == PUMP_MODE_AUTO;
}

// ==================== 状态字符串转换 ====================

const char* getPumpStateString() {
    PumpState state = getPumpState();
    switch (state) {
        case PUMP_ON: return "on";
        case PUMP_COOLDOWN: return "cooldown";
        default: return "off";
    }
}

const char* getPumpModeString() {
    return getPumpMode() == PUMP_MODE_AUTO ? "auto" : "manual";
}


// ==================== 自动控制函数 ====================

/**
 * @brief 根据传感器数据自动控制水泵
 * 
 * 火灾判定逻辑（与风扇相同）：
 * - 温度 > 50°C 或 烟雾浓度 > 30% 或 烟雾报警 → 检测到火灾
 * 
 * 喷水策略：
 * - 检测到火灾时，自动喷水15秒
 * - 喷水后进入冷却期，防止水泵过热
 * - 冷却期结束后，如果仍检测到火灾，继续喷水
 */
void updatePumpAutoControl(float temperature, float smokeLevel, bool smokeAlarm) {
    // 仅在自动模式下执行
    if (!isPumpAutoMode()) {
        return;
    }
    
    // 判断是否处于火灾环境（使用与风扇相同的阈值）
    bool highTemp = (temperature > TEMP_ALARM_THRESHOLD);
    bool smokeDetected = (smokeLevel > SMOKE_ALARM_THRESHOLD) || smokeAlarm;
    bool fireDetected = highTemp || smokeDetected;

    // 更新火灾检测状态
    if (xSemaphoreTake(pumpMutex, portMAX_DELAY) == pdTRUE) {
        pumpControl.fireDetected = fireDetected;
        xSemaphoreGive(pumpMutex);
    }

    // k230火焰确认
    int K230FireConfirmed = 0;
    if(xSemaphoreTake(k230Mutex, portMAX_DELAY) == pdTRUE){
        K230FireConfirmed = k230Control.fireState;
        xSemaphoreGive(k230Mutex);
    }

    if(K230FireConfirmed == K230_FIRE_CONFIRMED){
        fireDetected = true; // K230确认火焰检测时强制触发喷水
    }
    
    // 火灾检测：启动喷水
    if (fireDetected) {
        PumpState currentState = getPumpState();
        
        if (currentState == PUMP_OFF) {
            Serial.println("[PUMP] !!! FIRE DETECTED - STARTING SPRAY !!!");
            Serial.println("[PUMP] Temp: " + String(temperature) + "°C, Smoke: " + String(smokeLevel) + "%");
            pumpSpray(PUMP_AUTO_SPRAY_MS);
        } else if (currentState == PUMP_COOLDOWN) {
            // 冷却中，检查是否可以重新启动
            if (isPumpAvailable()) {
                Serial.println("[PUMP] Cooldown complete, fire still detected, restarting spray");
                pumpSpray(PUMP_AUTO_SPRAY_MS);
            }
        }
        // 如果正在喷水中，不做任何操作
    }
    // 注意：不在这里关闭水泵，让定时器自动关闭
}

// ==================== RTOS任务函数 ====================

/**
 * @brief 水泵控制RTOS任务
 * 
 * 职责：
 * 1. 检查自动关闭定时器
 * 2. 管理冷却状态转换
 * 3. 在自动模式下根据传感器数据控制喷水
 */
void pumpTask(void *pvParameters) {
    Serial.println("[PUMP] Pump control task started on Core " + String(xPortGetCoreID()));
    
    // 等待系统初始化
    vTaskDelay(pdMS_TO_TICKS(3000));
    
    for (;;) {
        // 1. 检查自动关闭定时器
        if (autoStopEnabled && millis() >= autoStopTime) {
            Serial.println("[PUMP] Auto-stop timer triggered");
            pumpOff();
        }
        
        // 2. 检查冷却状态是否结束
        if (xSemaphoreTake(pumpMutex, portMAX_DELAY) == pdTRUE) {
            if (pumpControl.state == PUMP_COOLDOWN) {
                unsigned long elapsed = millis() - pumpControl.lastStopTime;
                if (elapsed >= PUMP_COOLDOWN_MS) {
                    pumpControl.state = PUMP_OFF;
                    Serial.println("[PUMP] Cooldown complete, pump ready");
                }
            }
            xSemaphoreGive(pumpMutex);
        }
        
        // 获取传感器数据
        float temperature;
        float humidity;
        float smokeLevel;
        bool smokeAlarm;
        if(xSemaphoreTake(sensorMutex, portMAX_DELAY) == pdTRUE){
            temperature = sensorData.temperature;
            humidity = sensorData.humidity;
            smokeLevel = sensorData.smokeLevel;
            smokeAlarm = sensorData.smokeAlarm;
            xSemaphoreGive(sensorMutex);
        }
        // 3. 自动模式下的传感器检测
        if (isPumpAutoMode()) {
            if (!isnan(sensorData.temperature)) {
                updatePumpAutoControl(temperature, smokeLevel, smokeAlarm); 
            }
        }
        
        // 任务周期：500ms（比风扇更频繁，确保及时响应）
        vTaskDelay(pdMS_TO_TICKS(500));
    }
}
