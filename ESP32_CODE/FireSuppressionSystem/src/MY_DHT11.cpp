#include <Arduino.h>
#include "MY_DHT11.h"

// 定义 DHT 对象的实际实例
DHT dht(DHTPIN, DHTTYPE);

// FreeRTOS 任务句柄的定义
TaskHandle_t dhtTaskHandle = NULL;

void dhtTask(void *pvParameters) {
    dht.begin();
    Serial.println("DHT Task Started on Core " + String(xPortGetCoreID()));

    for (;;) {
        float h = dht.readHumidity();
        float t = dht.readTemperature();

        if (isnan(h) || isnan(t)) {
            Serial.println(F("Failed to read from DHT sensor!"));
        } else {
            Serial.print(F("Humidity: "));
            Serial.print(h);
            Serial.print(F("%  Temperature: "));
            Serial.print(t);
            Serial.println(F("°C"));
        }

        vTaskDelay(pdMS_TO_TICKS(2000));
    }
}
