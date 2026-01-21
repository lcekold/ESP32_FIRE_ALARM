#ifndef __MY_MQTT_H__
#define __MY_MQTT_H__

#include <WiFi.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>
#include "MY_K230.h"

// ==================== WiFi配置 ====================
extern const char* WIFI_SSID;
extern const char* WIFI_PASSWORD;

// ==================== MQTT配置 ====================
extern const char* MQTT_BROKER;
extern const int MQTT_PORT;
extern const char* MQTT_CLIENT_ID;
extern const char* DEVICE_ID;

// MQTT Topics
extern const char* MQTT_TOPIC_SENSOR;         // 传感器数据发布Topic
extern const char* MQTT_TOPIC_FAN_CONTROL;    // 风扇控制订阅Topic
extern const char* MQTT_TOPIC_FAN_MODE;       // 风扇模式订阅Topic
extern const char* MQTT_TOPIC_PUMP_CONTROL;   // 水泵控制订阅Topic
extern const char* MQTT_TOPIC_PUMP_MODE;      // 水泵模式订阅Topic
extern const char* MQTT_TOPIC_BUZZER_CONTROL; // 蜂鸣器控制订阅Topic
extern const char* MQTT_TOPIC_BUZZER_MODE;    // 蜂鸣器模式订阅Topic

// ==================== 全局对象 ====================
extern WiFiClient espClient;
extern PubSubClient mqttClient;

// ==================== FreeRTOS任务句柄 ====================
extern TaskHandle_t mqttTaskHandle;

// ==================== 函数声明 ====================

void setupWiFi();
void setupMQTT();
void reconnectMQTT();
void subscribeControlTopics();

// MQTT回调
void mqttCallback(char* topic, byte* payload, unsigned int length);

// 命令处理
void handleFanControlCommand(const char* payload);
void handleFanModeCommand(const char* payload);
void handlePumpControlCommand(const char* payload);
void handlePumpModeCommand(const char* payload);
void handleBuzzerControlCommand(const char* payload);
void handleBuzzerModeCommand(const char* payload);

// 数据发布
void publishSensorData(float temperature, float humidity, float smokeLevel, bool smokeAlarm);
String createJsonPayload(float temperature, float humidity, float smokeLevel, bool smokeAlarm);

// RTOS任务
void mqttTask(void *pvParameters);

#endif
