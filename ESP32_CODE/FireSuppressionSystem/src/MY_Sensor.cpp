#include <Arduino.h>
#include "MY_Sensor.h"
#include "MY_DHT11.h"
#include "MY_MQ2.h"

SensorData sensorData = {
    .temperature = 0.0f,
    .humidity = 0.0f,
    .smokeLevel = 0.0f,
    .smokeAlarm = false
};

TaskHandle_t sensorTaskHandle = NULL;
SemaphoreHandle_t sensorMutex = NULL; //互斥锁

// ==================== 初始化函数 ====================

void setupSensor() {
    // 创建互斥锁
    sensorMutex = xSemaphoreCreateMutex();
    
    Serial.println("[SENSOR] Sensor module initialized");
}

void sensorTask(void *pvParameters) {
    Serial.println("Sensor Task Started on Core " + String(xPortGetCoreID()));
    
    for (;;) {
        // 读取DHT11传感器数据
        if(xSemaphoreTake(sensorMutex,portMAX_DELAY)==pdTRUE){
            sensorData.humidity = dht.readHumidity();
            sensorData.temperature = dht.readTemperature();

            MQ2Data mq2Data = readMQ2();

            sensorData.smokeLevel = mq2Data.smokeLevel;
            sensorData.smokeAlarm = mq2Data.digitalAlarm;

            xSemaphoreGive(sensorMutex);
        }

        // 输出传感器数据到串口
        Serial.print(F("Sensor Data - Temp: "));
        Serial.print(sensorData.temperature);
        Serial.print(F("°C, Humidity: "));
        Serial.print(sensorData.humidity);
        Serial.print(F("%, Smoke Level: "));
        Serial.print(sensorData.smokeLevel);
        Serial.print(F("%, Smoke Alarm: "));
        Serial.println(sensorData.smokeAlarm ? "YES" : "NO");
        
        // 延时2秒后再次读取
        vTaskDelay(pdMS_TO_TICKS(2000));
    }
}