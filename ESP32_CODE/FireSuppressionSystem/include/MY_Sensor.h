#ifndef MY_SENSOR_H
#define MY_SENSOR_H

#include <Arduino.h>


typedef struct {
    float temperature;
    float humidity;
    float smokeLevel;
    bool smokeAlarm;
}SensorData;

extern SensorData sensorData;
extern TaskHandle_t sensorTaskHandle;
extern SemaphoreHandle_t sensorMutex;


void setupSensor();
void sensorTask(void *pvParameters);

#endif