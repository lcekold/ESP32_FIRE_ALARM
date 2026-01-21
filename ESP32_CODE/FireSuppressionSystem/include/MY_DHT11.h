#ifndef __MY_DHT11_H__
#define __MY_DHT11_H__

#include <DHT.h>


// --- 定义引脚和类型 ---
#define DHTPIN 9     // 连接到 ESP32-S3 的 GPIO 35
#define DHTTYPE DHT11 // 传感器类型为 DHT11

// 温度警告阈值
#define TEMP_ALARM_THRESHOLD 50.0f // 超过此温度判定为火灾
#define TEMP_SAFE_THRESHOLD 40.0f  // 低于此温度可解除火灾状态

extern DHT dht;

extern TaskHandle_t dhtTaskHandle;

void dhtTask(void *pvParameters);

#endif