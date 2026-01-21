#ifndef MY_MQ2_H
#define MY_MQ2_H

#include <Arduino.h>

// MQ-2 传感器引脚定义
#define MQ2_AO_PIN 15  // 模拟输出引脚
#define MQ2_DO_PIN 16  // 数字输出引脚（报警输出）

// 烟雾报警阈值
#define SMOKE_ALARM_THRESHOLD 30.0f // 超过此浓度判定为火灾
#define SMOKE_SAFE_THRESHOLD 15.0f  // 低于此浓度可解除火灾状态

// MQ-2 数据结构
struct MQ2Data {
    int analogValue;      // 模拟值 (0-4095)
    bool digitalAlarm;    // 数字报警状态 (true=检测到烟雾)
    float smokeLevel;     // 烟雾浓度百分比 (0-100%)
};

// 函数声明
void setupMQ2();
MQ2Data readMQ2();

// 全局变量声明
extern MQ2Data currentMQ2Data;

#endif
