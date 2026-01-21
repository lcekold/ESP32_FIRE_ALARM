#include <Arduino.h>
#include "MY_MQTT.h"
#include "MY_DHT11.h"
#include "MY_MQ2.h"
#include "MY_Fan.h"
#include "MY_Pump.h"
#include "MY_Buzzer.h"
#include "MY_Sensor.h"

// ==================== WiFi配置 ====================
const char* WIFI_SSID = "1234";
const char* WIFI_PASSWORD = "18636074500";

// ==================== MQTT配置 ====================
const char* MQTT_BROKER = "broker.emqx.io";
const int MQTT_PORT = 1883;
const char* MQTT_CLIENT_ID = "esp32_fire_alarm_001";
const char* DEVICE_ID = "esp32_fire_alarm_001";

// MQTT Topics
const char* MQTT_TOPIC_SENSOR = "fire_alarm/sensor_data";
const char* MQTT_TOPIC_FAN_CONTROL = "fire_alarm/fan/control";
const char* MQTT_TOPIC_FAN_MODE = "fire_alarm/fan/mode";
const char* MQTT_TOPIC_PUMP_CONTROL = "fire_alarm/pump/control";
const char* MQTT_TOPIC_PUMP_MODE = "fire_alarm/pump/mode";
const char* MQTT_TOPIC_BUZZER_CONTROL = "fire_alarm/buzzer/control";
const char* MQTT_TOPIC_BUZZER_MODE = "fire_alarm/buzzer/mode";

// ==================== 全局对象实例 ====================
WiFiClient espClient;
PubSubClient mqttClient(espClient);
TaskHandle_t mqttTaskHandle = NULL;

// ==================== WiFi连接功能 ====================

void setupWiFi() {
    Serial.println();
    Serial.print("Connecting to WiFi: ");
    Serial.println(WIFI_SSID);

    WiFi.disconnect(true);
    delay(100);
    WiFi.mode(WIFI_STA);
    delay(100);
    WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

    int retryCount = 0;
    while (WiFi.status() != WL_CONNECTED && retryCount < 40) {
        delay(500);
        Serial.print(".");
        retryCount++;
    }

    if (WiFi.status() == WL_CONNECTED) {
        Serial.println("\nWiFi connected!");
        Serial.print("IP: ");
        Serial.println(WiFi.localIP());
    } else {
        Serial.println("\nWiFi connection failed!");
    }
}

// ==================== MQTT连接功能 ====================

void setupMQTT() {
    mqttClient.setServer(MQTT_BROKER, MQTT_PORT);
    mqttClient.setCallback(mqttCallback);
    mqttClient.setBufferSize(1024);
    Serial.println("[MQTT] Configured: " + String(MQTT_BROKER) + ":" + String(MQTT_PORT));
}

void reconnectMQTT() {
    if (WiFi.status() != WL_CONNECTED) {
        WiFi.reconnect();
        int retry = 0;
        while (WiFi.status() != WL_CONNECTED && retry < 10) {
            vTaskDelay(pdMS_TO_TICKS(500));
            retry++;
        }
        if (WiFi.status() != WL_CONNECTED) return;
    }

    while (!mqttClient.connected()) {
        Serial.print("[MQTT] Connecting...");
        if (mqttClient.connect(MQTT_CLIENT_ID)) {
            Serial.println("connected!");
            subscribeControlTopics();
        } else {
            Serial.println("failed, retrying in 5s");
            vTaskDelay(pdMS_TO_TICKS(5000));
        }
    }
}

void subscribeControlTopics() {
    mqttClient.subscribe(MQTT_TOPIC_FAN_CONTROL);
    mqttClient.subscribe(MQTT_TOPIC_FAN_MODE);
    mqttClient.subscribe(MQTT_TOPIC_PUMP_CONTROL);
    mqttClient.subscribe(MQTT_TOPIC_PUMP_MODE);
    mqttClient.subscribe(MQTT_TOPIC_BUZZER_CONTROL);
    mqttClient.subscribe(MQTT_TOPIC_BUZZER_MODE);
    Serial.println("[MQTT] Subscribed to all control topics");
}

// ==================== MQTT消息回调 ====================

void mqttCallback(char* topic, byte* payload, unsigned int length) {
    char message[length + 1];
    memcpy(message, payload, length);
    message[length] = '\0';
    
    Serial.println("[MQTT] Received: " + String(topic) + " -> " + String(message));
    
    if (strcmp(topic, MQTT_TOPIC_FAN_CONTROL) == 0) {
        handleFanControlCommand(message);
    } else if (strcmp(topic, MQTT_TOPIC_FAN_MODE) == 0) {
        handleFanModeCommand(message);
    } else if (strcmp(topic, MQTT_TOPIC_PUMP_CONTROL) == 0) {
        handlePumpControlCommand(message);
    } else if (strcmp(topic, MQTT_TOPIC_PUMP_MODE) == 0) {
        handlePumpModeCommand(message);
    } else if (strcmp(topic, MQTT_TOPIC_BUZZER_CONTROL) == 0) {
        handleBuzzerControlCommand(message);
    } else if (strcmp(topic, MQTT_TOPIC_BUZZER_MODE) == 0) {
        handleBuzzerModeCommand(message);
    }
}

// ==================== 风扇命令处理 ====================

void handleFanControlCommand(const char* payload) {
    JsonDocument doc;
    if (deserializeJson(doc, payload)) return;
    
    const char* action = doc["action"];
    if (!action) return;
    
    if (isFanAutoMode()) {
        Serial.println("[MQTT] Fan control ignored - AUTO mode");
        return;
    }
    
    if (strcmp(action, "on") == 0) fanOn();
    else if (strcmp(action, "off") == 0) fanOff();
}

void handleFanModeCommand(const char* payload) {
    JsonDocument doc;
    if (deserializeJson(doc, payload)) return;
    
    const char* action = doc["action"];
    if (!action) return;
    
    if (strcmp(action, "auto") == 0) setFanMode(FAN_MODE_AUTO);
    else if (strcmp(action, "manual") == 0) setFanMode(FAN_MODE_MANUAL);
}

// ==================== 水泵命令处理 ====================

void handlePumpControlCommand(const char* payload) {
    JsonDocument doc;
    if (deserializeJson(doc, payload)) return;
    
    const char* action = doc["action"];
    if (!action) return;
    
    if (isPumpAutoMode()) {
        Serial.println("[MQTT] Pump control ignored - AUTO mode");
        return;
    }
    
    if (strcmp(action, "on") == 0) {
        // 手动模式下喷水10秒
        pumpSpray(10000);
    } else if (strcmp(action, "off") == 0) {
        pumpOff();
    }
}

void handlePumpModeCommand(const char* payload) {
    JsonDocument doc;
    if (deserializeJson(doc, payload)) return;
    
    const char* action = doc["action"];
    if (!action) return;
    
    if (strcmp(action, "auto") == 0) setPumpMode(PUMP_MODE_AUTO);
    else if (strcmp(action, "manual") == 0) setPumpMode(PUMP_MODE_MANUAL);
}

// ==================== 蜂鸣器命令处理 ====================

void handleBuzzerControlCommand(const char* payload) {
    JsonDocument doc;
    if (deserializeJson(doc, payload)) return;
    
    const char* action = doc["action"];
    if (!action) return;
    
    if (isBuzzerAutoMode()) {
        Serial.println("[MQTT] Buzzer control ignored - AUTO mode");
        return;
    }
    
    if (strcmp(action, "on") == 0) buzzerOn();
    else if (strcmp(action, "off") == 0) buzzerOff();
}

void handleBuzzerModeCommand(const char* payload) {
    JsonDocument doc;
    if (deserializeJson(doc, payload)) return;
    
    const char* action = doc["action"];
    if (!action) return;
    
    if (strcmp(action, "auto") == 0) setBuzzerMode(BUZZER_MODE_AUTO);
    else if (strcmp(action, "manual") == 0) setBuzzerMode(BUZZER_MODE_MANUAL);
}


// ==================== 数据发布功能 ====================

void publishSensorData(float temperature, float humidity, float smokeLevel, bool smokeAlarm) {
    if (!mqttClient.connected()) return;

    String payload = createJsonPayload(temperature, humidity, smokeLevel, smokeAlarm);
    
    if (mqttClient.publish(MQTT_TOPIC_SENSOR, payload.c_str())) {
        Serial.println("[MQTT] Published sensor data");
    }
}

/**
 * @brief 创建JSON格式的传感器数据负载
 * 
 * 包含传感器数据、风扇状态和水泵状态
 */
String createJsonPayload(float temperature, float humidity, float smokeLevel, bool smokeAlarm) {
    JsonDocument doc;
    
    doc["device_id"] = DEVICE_ID;
    doc["temperature"] = round(temperature * 10.0) / 10.0;
    doc["humidity"] = round(humidity * 10.0) / 10.0;
    doc["smoke_level"] = round(smokeLevel * 10.0) / 10.0;
    doc["smoke_alarm"] = smokeAlarm;
    
    // 风扇状态
    doc["fan_state"] = getFanStateString();
    doc["fan_mode"] = getFanModeString();
    
    // 水泵状态
    doc["pump_state"] = getPumpStateString();
    doc["pump_mode"] = getPumpModeString();
    
    // K230视觉火焰检测状态
    doc["k230_fire"] = getK230FireStateString();
    doc["k230_fire_detected"] = isK230FireDetected();
    
    // 蜂鸣器状态
    doc["buzzer_state"] = getBuzzerStateString();
    doc["buzzer_mode"] = getBuzzerModeString();
    
    doc["timestamp"] = millis();
    
    JsonObject unit = doc["unit"].to<JsonObject>();
    unit["temperature"] = "celsius";
    unit["humidity"] = "percent";
    unit["smoke_level"] = "percent";

    String payload;
    serializeJson(doc, payload);
    
    return payload;
}

// ==================== MQTT FreeRTOS任务 ====================

void mqttTask(void *pvParameters) {
    Serial.println("[MQTT] Task started on Core " + String(xPortGetCoreID()));

    for (;;) {
        if (!mqttClient.connected()) {
            reconnectMQTT();
        }
        
        mqttClient.loop();

        //获取传感器数据
        float temperature;
        float humidity;
        float smokeLevel; 
        bool smokeAlarm;
        if(xSemaphoreTake(sensorMutex, portMAX_DELAY)==pdTRUE){
            temperature = sensorData.temperature;
            humidity = sensorData.humidity;
            smokeLevel = sensorData.smokeLevel;
            smokeAlarm = sensorData.smokeAlarm;
            xSemaphoreGive(sensorMutex);
        }

        if (!isnan(humidity) && !isnan(temperature)) {
            publishSensorData(temperature, humidity, smokeLevel, smokeAlarm);
        }

        vTaskDelay(pdMS_TO_TICKS(1000));
    }
}
