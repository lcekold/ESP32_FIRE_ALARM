#ifndef MY_BUZZER_H
#define MY_BUZZER_H

#include <Arduino.h>
#include <freertos/FreeRTOS.h>
#include <freertos/task.h>
#include <freertos/semphr.h>

// ==================== 硬件配置 ====================
// 蜂鸣器控制引脚 (高电平触发)
#define BUZZER_PIN 8

// ==================== 蜂鸣器工作参数 ====================
// 蜂鸣器响动间隔 (毫秒) - 用于产生警报效果
#define BUZZER_BEEP_ON_MS       500     // 响500ms
#define BUZZER_BEEP_OFF_MS      300     // 停300ms
// 火灾警报持续时间 (毫秒) - 超过此时间自动关闭
#define BUZZER_AUTO_OFF_MS      60000   // 60秒

// ==================== 枚举定义 ====================

// 蜂鸣器状态
typedef enum {
    BUZZER_OFF = 0,     // 蜂鸣器关闭
    BUZZER_ON = 1       // 蜂鸣器开启（警报中）
} BuzzerState;

// 控制模式
typedef enum {
    BUZZER_MODE_AUTO = 0,    // 自动模式 (根据火灾检测控制)
    BUZZER_MODE_MANUAL = 1   // 手动模式 (APP远程控制)
} BuzzerMode;

// ==================== 数据结构 ====================

// 蜂鸣器控制状态结构体
typedef struct {
    BuzzerState state;          // 当前蜂鸣器状态
    BuzzerMode mode;            // 当前控制模式
    unsigned long lastChange;   // 上次状态改变时间(ms)
    unsigned long alarmStart;   // 警报开始时间
    bool fireDetected;          // 是否检测到火灾
    bool timeoutActive;         // 是否超时
} BuzzerControl;

// ==================== 全局变量声明 ====================
extern BuzzerControl buzzerControl;
extern TaskHandle_t buzzerTaskHandle;
extern SemaphoreHandle_t buzzerMutex;

// ==================== 函数声明 ====================

// 初始化函数
void setupBuzzer();

// 蜂鸣器控制函数
void buzzerOn();
void buzzerOff();
void buzzerToggle();

// 状态获取函数
BuzzerState getBuzzerState();
BuzzerMode getBuzzerMode();

// 模式设置函数
void setBuzzerMode(BuzzerMode mode);
bool isBuzzerAutoMode();

// 自动控制函数
void updateBuzzerAutoControl(bool fireDetected);
void updateBuzzerAutoControlBySensor(float temperature, float smokeLevel, bool smokeAlarm);

// 状态字符串转换 (用于MQTT发布)
const char* getBuzzerStateString();
const char* getBuzzerModeString();

// RTOS任务函数
void buzzerTask(void *pvParameters);

#endif
