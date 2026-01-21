#ifndef MY_PUMP_H
#define MY_PUMP_H

#include <Arduino.h>
#include <freertos/FreeRTOS.h>
#include <freertos/task.h>
#include <freertos/semphr.h>

// ==================== 硬件配置 ====================
// 水泵控制引脚 (连接到继电器IN口，高电平触发)
#define PUMP_RELAY_PIN 14

// ==================== 水泵工作参数 ====================
// 单次喷水最大持续时间 (毫秒) - 防止水泵过热或水箱耗尽
#define PUMP_MAX_DURATION_MS     5000   // 5秒
// 喷水间隔冷却时间 (毫秒)
#define PUMP_COOLDOWN_MS         10000   // 10秒
// 自动模式下检测到火灾后的喷水时间 (毫秒)
#define PUMP_AUTO_SPRAY_MS       5000   // 5秒

// ==================== 枚举定义 ====================

// 水泵状态
typedef enum {
    PUMP_OFF = 0,       // 水泵关闭
    PUMP_ON = 1,        // 水泵开启（喷水中）
    PUMP_COOLDOWN = 2   // 冷却中（暂时不可用）
} PumpState;

// 控制模式
typedef enum {
    PUMP_MODE_AUTO = 0,     // 自动模式 (根据传感器数据控制)
    PUMP_MODE_MANUAL = 1    // 手动模式 (APP远程控制)
} PumpMode;

// ==================== 数据结构 ====================

// 水泵控制状态结构体
typedef struct {
    PumpState state;              // 当前水泵状态
    PumpMode mode;                // 当前控制模式
    unsigned long lastStartTime;  // 上次启动时间
    unsigned long lastStopTime;   // 上次停止时间
    unsigned long totalSprayTime; // 累计喷水时间 (用于统计)
    uint32_t sprayCount;          // 喷水次数统计
    bool fireDetected;            // 是否检测到火灾
} PumpControl;

// ==================== 全局变量声明 ====================
extern PumpControl pumpControl;
extern TaskHandle_t pumpTaskHandle;
extern SemaphoreHandle_t pumpMutex;

// ==================== 函数声明 ====================

// 初始化函数
void setupPump();

// 水泵控制函数
void pumpOn();                              // 开启水泵
void pumpOff();                             // 关闭水泵
void pumpSpray(unsigned long durationMs);   // 喷水指定时间后自动关闭

// 状态获取函数
PumpState getPumpState();
PumpMode getPumpMode();
bool isPumpAvailable();                     // 检查水泵是否可用（非冷却状态）
unsigned long getPumpRemainingCooldown();   // 获取剩余冷却时间

// 模式设置函数
void setPumpMode(PumpMode mode);
bool isPumpAutoMode();

// 自动控制函数
void updatePumpAutoControl(float temperature, float smokeLevel, bool smokeAlarm);

// 状态字符串转换 (用于MQTT发布)
const char* getPumpStateString();
const char* getPumpModeString();

// RTOS任务函数
void pumpTask(void *pvParameters);

#endif
