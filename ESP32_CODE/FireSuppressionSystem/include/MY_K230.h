#ifndef MY_K230_H
#define MY_K230_H

#include <Arduino.h>
#include <freertos/FreeRTOS.h>
#include <freertos/task.h>
#include <freertos/semphr.h>
#include <freertos/queue.h>

// ==================== 硬件配置 ====================
// K230串口配置 (使用Serial1)
#define K230_SERIAL         Serial1
#define K230_BAUD_RATE      115200
#define K230_RX_PIN         18      // ESP32-S3 RX 接 K230 TX
#define K230_TX_PIN         17      // ESP32-S3 TX 接 K230 RX

// ==================== 协议定义 ====================
// K230发送的火焰检测命令
#define K230_FIRE_CMD       "fire"
#define K230_BUFFER_SIZE    32

// ==================== 火焰检测参数 ====================
// 火焰检测后的风扇持续运行时间 (毫秒)
#define K230_FAN_DURATION_MS        60000   // 60秒
// 火焰检测后的水泵喷水时间 (毫秒)
#define K230_PUMP_SPRAY_MS          15000   // 15秒
// 连续检测到火焰的确认次数 (防抖)
#define K230_FIRE_CONFIRM_COUNT     1       // 立即响应，不做防抖
// 火焰状态超时时间 (毫秒) - 超过此时间未收到fire则认为火焰消失
#define K230_FIRE_TIMEOUT_MS        5000    // 5秒

// ==================== 枚举定义 ====================

// K230火焰检测状态
typedef enum {
    K230_FIRE_NONE = 0,         // 未检测到火焰
    K230_FIRE_DETECTED = 1,     // 检测到火焰
    K230_FIRE_CONFIRMED = 2     // 火焰已确认（触发灭火）
} K230FireState;

// ==================== 数据结构 ====================

// K230状态结构体
typedef struct {
    K230FireState fireState;        // 当前火焰状态
    unsigned long lastFireTime;     // 上次检测到火焰的时间
    unsigned long fireStartTime;    // 火焰开始时间
    uint32_t fireCount;             // 火焰检测计数
    uint32_t totalFireEvents;       // 累计火焰事件数
    bool suppressionActive;         // 灭火系统是否激活
} K230Control;

// ==================== 全局变量声明 ====================
extern K230Control k230Control;
extern TaskHandle_t k230TaskHandle;
extern SemaphoreHandle_t k230Mutex;

// ==================== 函数声明 ====================

// 初始化函数
void setupK230();

// 状态获取函数
K230FireState getK230FireState();
bool isK230FireDetected();
unsigned long getK230LastFireTime();

// 火焰处理函数
void handleK230FireDetected();
void resetK230FireState();

// 状态字符串转换 (用于MQTT发布)
const char* getK230FireStateString();

// RTOS任务函数
void k230Task(void *pvParameters);

#endif
