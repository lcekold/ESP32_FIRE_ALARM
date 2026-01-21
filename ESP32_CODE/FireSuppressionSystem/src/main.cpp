#include <Arduino.h>
#include "MY_DHT11.h"
#include "MY_MQ2.h"
#include "MY_MQTT.h"
#include "MY_Fan.h"
#include "MY_Pump.h"
#include "MY_K230.h"
#include "MY_Buzzer.h"
#include <esp_task_wdt.h>
#include "MY_Sensor.h"
void setup() {
    // ==================== 禁用看门狗 ====================
    esp_task_wdt_deinit();

    // 关闭ESP32-S3上的RGB灯
    neopixelWrite(48, 0, 0, 0);
    
    // 初始化串口
    Serial.begin(115200);
    delay(2000); 

    Serial.println("========================================");
    Serial.println("ESP32-S3 Fire Suppression System");
    Serial.println("========================================");

    // 初始化 DHT 传感器
    dht.begin();
    
    // 初始化 MQ-2 烟雾传感器
    setupMQ2();

    // 初始化传感器数据
    setupSensor();

    // 初始化风扇控制模块
    setupFan();
    
    // 初始化水泵控制模块
    setupPump();

    // 初始化K230视觉模块串口通信
    setupK230();

    // 初始化蜂鸣器模块
    setupBuzzer();

    // 初始化WiFi
    Serial.println("Initializing WiFi...");
    setupWiFi();
    
    // 初始化MQTT
    setupMQTT();

    // 创建风扇控制任务 (Core 0)
    xTaskCreatePinnedToCore(
        fanTask,
        "Fan_Task",
        4096,
        NULL,
        2,
        &fanTaskHandle,
        0
    );
    
    // 创建水泵控制任务 (Core 0)
    xTaskCreatePinnedToCore(
        pumpTask,
        "Pump_Task",
        4096,
        NULL,
        3,              // 优先级3，最高（灭火最重要）
        &pumpTaskHandle,
        0
    );

    // 创建K230视觉检测任务 (Core 0, 最高优先级)
    xTaskCreatePinnedToCore(
        k230Task,
        "K230_Task",
        4096,
        NULL,
        4,              // 优先级4，最高（火焰检测最重要）
        &k230TaskHandle,
        0
    );

    // 创建蜂鸣器控制任务 (Core 0)
    xTaskCreatePinnedToCore(
        buzzerTask,
        "Buzzer_Task",
        2048,
        NULL,
        1,              // 优先级1，较低
        &buzzerTaskHandle,
        0
    );

    // 创建 MQTT 任务 (Core 1)
    xTaskCreatePinnedToCore(
        mqttTask,
        "MQTT_Task",
        16384,
        NULL,
        1,
        &mqttTaskHandle,
        1
    );

    // 创建传感器读取数据任务
    xTaskCreatePinnedToCore(
        sensorTask,
        "Sensor_Task",
        4096,
        NULL,
        5,
        &sensorTaskHandle,
        1
    );

    Serial.println("========================================");
    Serial.println("All tasks created successfully!");
    Serial.println("Fan Mode: AUTO | Pump Mode: AUTO");
    Serial.println("Buzzer Mode: AUTO | K230 Vision: ACTIVE");
    Serial.println("========================================");
}

void loop() {
    // 每10秒打印一次系统状态
    Serial.println("\n========== System Status ==========");
    Serial.print("Free Heap: ");
    Serial.print(ESP.getFreeHeap());
    Serial.println(" bytes");
    Serial.println("-----------------------------------");
    Serial.print("Fan:  State=");
    Serial.print(getFanStateString());
    Serial.print(", Mode=");
    Serial.println(getFanModeString());
    Serial.print("Pump: State=");
    Serial.print(getPumpStateString());
    Serial.print(", Mode=");
    Serial.println(getPumpModeString());
    Serial.print("K230: Fire=");
    Serial.println(getK230FireStateString());
    Serial.print("Buzzer: State=");
    Serial.print(getBuzzerStateString());
    Serial.print(", Mode=");
    Serial.println(getBuzzerModeString());
    Serial.println("===================================");
    
    delay(10000);
}
