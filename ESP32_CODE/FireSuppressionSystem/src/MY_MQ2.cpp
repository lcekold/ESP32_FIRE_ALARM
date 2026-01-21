#include <Arduino.h>
#include "MY_MQ2.h"

// 全局变量定义
MQ2Data currentMQ2Data = {0, false, 0.0};

/**
 * @brief 初始化MQ-2传感器
 */
void setupMQ2() {
    // 设置模拟输入引脚
    pinMode(MQ2_AO_PIN, INPUT);
    // 设置数字输入引脚
    pinMode(MQ2_DO_PIN, INPUT);
    
    Serial.println("MQ-2 Sensor initialized");
    Serial.print("  AO Pin: GPIO");
    Serial.println(MQ2_AO_PIN);
    Serial.print("  DO Pin: GPIO");
    Serial.println(MQ2_DO_PIN);
}
      
/**
 * @brief 读取MQ-2传感器数据
 * 
 * @return MQ2Data 包含模拟值、数字报警状态和烟雾浓度百分比
 */
MQ2Data readMQ2() {
    MQ2Data data;
    
    // 读取模拟值 (ESP32 ADC 12位，范围0-4095)
    data.analogValue = analogRead(MQ2_AO_PIN);
    
    // 读取数字报警状态 (LOW=检测到烟雾，HIGH=正常)
    // MQ-2的DO引脚在检测到烟雾时输出低电平
    data.digitalAlarm = (digitalRead(MQ2_DO_PIN) == LOW);
    
    // 将模拟值转换为百分比 (0-100%)
    // 4095对应100%，0对应0%
    data.smokeLevel = (data.analogValue / 4095.0) * 100.0;
    
    // 更新全局变量
    currentMQ2Data = data;
    
    return data;
}
