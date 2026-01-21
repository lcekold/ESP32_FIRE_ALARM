#ifndef MY_FAN_H
#define MY_FAN_H

#include <Arduino.h>
#include <freertos/FreeRTOS.h>
#include <freertos/task.h>
#include <freertos/semphr.h>

// ==================== 硬件配置 ====================
// 风扇控制引脚 (连接到继电器IN口，低电平触发)
#define FAN_RELAY_PIN 13

// ==================== 枚举定义 ====================

// 风扇状态
typedef enum {
    FAN_OFF = 0,    // 风扇关闭
    FAN_ON = 1      // 风扇开启
} FanState;

// 控制模式
typedef enum {
    FAN_MODE_AUTO = 0,    // 自动模式 (根据传感器数据控制)
    FAN_MODE_MANUAL = 1   // 手动模式 (APP远程控制)
} FanMode;

// 报警原因
typedef enum {
    ALARM_NONE = 0,           // 无报警
    ALARM_HIGH_TEMP = 1,      // 高温报警
    ALARM_SMOKE_DETECTED = 2, // 烟雾报警
    ALARM_BOTH = 3            // 高温+烟雾
} AlarmReason;

// ==================== 数据结构 ====================

// 风扇控制状态结构体
typedef struct {
    FanState state;           // 当前风扇状态
    FanMode mode;             // 当前控制模式
    AlarmReason alarmReason;  // 报警原因
    unsigned long lastChange; // 上次状态改变时间(ms)
    float lastTemp;           // 上次检测的温度
    float lastHumidity;       // 上次检测的湿度
    float lastSmokeLevel;     // 上次检测的烟雾浓度
    bool lastSmokeAlarm;      // 上次的烟雾报警状态
} FanControl;

// ==================== 全局变量声明 ====================
extern FanControl fanControl;
extern TaskHandle_t fanTaskHandle;
extern SemaphoreHandle_t fanMutex;

// ==================== 函数声明 ====================

// 初始化函数
void setupFan();

// 风扇控制函数
void fanOn();
void fanOff();
void fanToggle();

// 状态获取函数
FanState getFanState();
FanMode getFanMode();
AlarmReason getAlarmReason();

// 模式设置函数
void setFanMode(FanMode mode);
bool isFanAutoMode();

// 自动控制核心函数
void updateFanAutoControl(float temperature, float humidity, float smokeLevel, bool smokeAlarm);

// 状态字符串转换 (用于MQTT发布)
const char* getFanStateString();
const char* getFanModeString();

// RTOS任务函数
void fanTask(void *pvParameters);

#endif
