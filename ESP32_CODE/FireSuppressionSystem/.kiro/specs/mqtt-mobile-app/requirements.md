# Requirements Document

## Introduction

本文档定义了小区火灾报警系统的MQTT通信与手机APP交互功能的需求。该功能使ESP32-S3设备能够通过MQTT协议将温湿度传感器数据实时传输到手机APP，同时APP提供用户认证（登录/注册）功能和美观的用户界面来展示数据。

## Glossary

- **Fire_Suppression_System**: 基于ESP32-S3的小区火灾报警系统，负责采集传感器数据并通过MQTT发布
- **Mobile_App**: 用于显示传感器数据和用户交互的手机应用程序
- **MQTT_Broker**: MQTT消息代理服务器，负责消息的路由和分发
- **User**: 使用手机APP查看火灾报警系统数据的终端用户
- **Temperature_Data**: DHT11传感器采集的温度数据，单位为摄氏度(°C)
- **Humidity_Data**: DHT11传感器采集的湿度数据，单位为百分比(%)
- **Authentication_Service**: 负责用户登录和注册验证的服务模块

## Requirements

### Requirement 1

**User Story:** As a User, I want to view real-time temperature and humidity data on my mobile phone, so that I can monitor the fire safety status of my residential area.

#### Acceptance Criteria

1. WHEN the Fire_Suppression_System collects Temperature_Data and Humidity_Data from the DHT11 sensor, THEN the Fire_Suppression_System SHALL publish the data to the MQTT_Broker within 3 seconds
2. WHEN the Mobile_App subscribes to the sensor data topic, THEN the Mobile_App SHALL receive and display Temperature_Data and Humidity_Data within 2 seconds of publication
3. WHEN the Mobile_App displays sensor data, THEN the Mobile_App SHALL show Temperature_Data with one decimal place precision and the unit "°C"
4. WHEN the Mobile_App displays sensor data, THEN the Mobile_App SHALL show Humidity_Data with one decimal place precision and the unit "%"
5. WHEN the MQTT connection is lost, THEN the Fire_Suppression_System SHALL attempt to reconnect automatically every 5 seconds

### Requirement 2

**User Story:** As a User, I want to register a new account in the Mobile_App, so that I can securely access the fire alarm system data.

#### Acceptance Criteria

1. WHEN a User opens the Mobile_App for the first time, THEN the Mobile_App SHALL display a login page with an option to navigate to the registration page
2. WHEN a User submits registration information with a valid username (4-20 characters) and password (6-20 characters), THEN the Authentication_Service SHALL create a new user account
3. WHEN a User submits registration information with an invalid username or password format, THEN the Mobile_App SHALL display a specific error message indicating the validation failure
4. WHEN a User attempts to register with an existing username, THEN the Authentication_Service SHALL reject the registration and the Mobile_App SHALL display an error message
5. WHEN registration is successful, THEN the Mobile_App SHALL navigate the User to the login page with a success notification

### Requirement 3

**User Story:** As a User, I want to log in to the Mobile_App with my credentials, so that I can access the fire alarm monitoring features.

#### Acceptance Criteria

1. WHEN a User enters valid credentials and submits the login form, THEN the Authentication_Service SHALL verify the credentials and grant access to the main dashboard
2. WHEN a User enters invalid credentials, THEN the Mobile_App SHALL display an error message without revealing which credential is incorrect
3. WHEN a User successfully logs in, THEN the Mobile_App SHALL store the session token securely and navigate to the main dashboard
4. WHEN a User is logged in and reopens the Mobile_App, THEN the Mobile_App SHALL restore the session and skip the login page
5. WHEN a User clicks the logout button, THEN the Mobile_App SHALL clear the session and navigate to the login page

### Requirement 4

**User Story:** As a User, I want the Mobile_App to have a beautiful and easy-to-use interface, so that I can quickly understand the fire safety status.

#### Acceptance Criteria

1. WHEN the Mobile_App displays the main dashboard, THEN the Mobile_App SHALL show Temperature_Data and Humidity_Data using visually distinct card components with appropriate icons
2. WHEN Temperature_Data exceeds 40°C, THEN the Mobile_App SHALL highlight the temperature display with a warning color (red or orange)
3. WHEN the Mobile_App loads data, THEN the Mobile_App SHALL display a loading indicator to provide visual feedback
4. WHEN the Mobile_App encounters a data loading error, THEN the Mobile_App SHALL display a user-friendly error message with a retry option
5. WHEN the User interacts with the Mobile_App, THEN the Mobile_App SHALL provide responsive touch feedback within 100 milliseconds

### Requirement 5

**User Story:** As a system developer, I want the MQTT communication to use a structured data format, so that the data can be easily parsed and extended.

#### Acceptance Criteria

1. WHEN the Fire_Suppression_System publishes sensor data, THEN the Fire_Suppression_System SHALL format the data as a JSON object containing temperature, humidity, timestamp, and device_id fields
2. WHEN the Mobile_App receives MQTT messages, THEN the Mobile_App SHALL parse the JSON data and validate the required fields before displaying
3. WHEN the Fire_Suppression_System serializes sensor data to JSON, THEN the Fire_Suppression_System SHALL produce valid JSON that can be deserialized back to the original data structure (round-trip consistency)
4. WHEN the Mobile_App receives malformed JSON data, THEN the Mobile_App SHALL handle the parsing error gracefully without crashing
