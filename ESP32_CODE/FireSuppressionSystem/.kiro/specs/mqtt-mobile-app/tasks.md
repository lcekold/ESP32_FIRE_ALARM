# Implementation Plan

## Part 1: ESP32-S3 MQTT功能实现

- [x] 1. 实现ESP32-S3 MQTT通信模块






  - [x] 1.1 创建MY_MQTT头文件和基础结构






    - 创建 `include/MY_MQTT.h` 定义WiFi和MQTT配置常量
    - 声明WiFi连接、MQTT连接、数据发布函数
    - 定义MQTT任务句柄
    - _Requirements: 1.1, 5.1_





  - [x] 1.2 实现WiFi连接功能






    - 创建 `src/MY_MQTT.cpp` 实现 `setupWiFi()` 函数
    - 实现WiFi连接状态检查和自动重连逻辑
    - _Requirements: 1.5_


  - [x] 1.3 实现MQTT连接和发布功能






    - 实现 `setupMQTT()` 和 `reconnectMQTT()` 函数
    - 实现 `publishSensorData()` 函数发布温湿度数据
    - 配置MQTT Broker地址为 `broker.emqx.io`
    - _Requirements: 1.1, 1.5_


  - [x] 1.4 实现JSON数据序列化


    - 实现 `createJsonPayload()` 函数生成JSON格式数据
    - JSON包含 temperature, humidity, timestamp, device_id 字段
    - _Requirements: 5.1, 5.3_

  - [x] 1.5 创建MQTT FreeRTOS任务






    - 实现 `mqttTask()` 函数作为独立任务运行
    - 集成DHT11数据读取和MQTT发布
    - _Requirements: 1.1_


  - [x] 1.6 更新main.cpp集成MQTT功能







    - 添加MQTT任务创建
    - 更新platformio.ini添加PubSubClient和ArduinoJson库依赖
    - _Requirements: 1.1, 5.1_




- [x] 2. Checkpoint - 确保ESP32-S3代码编译通过

  - Ensure all tests pass, ask the user if questions arise.

## Part 2: Flutter手机APP实现



- [x] 3. 创建Flutter项目基础结构




  - [x] 3.1 初始化Flutter项目






    - 在BISHE目录下创建 `fire_alarm_app` Flutter项目
    - 配置 `pubspec.yaml` 添加依赖：mqtt_client, shared_preferences, provider
    - _Requirements: 1.2, 2.1, 3.1_


  - [x] 3.2 创建项目目录结构





    - 创建 models/, services/, screens/, widgets/, utils/ 目录
    - 创建 `utils/constants.dart` 定义MQTT配置常量
    - _Requirements: 1.2_

- [x] 4. 实现数据模型层






  - [-] 4.1 实现SensorData模型




    - 创建 `models/sensor_data.dart`
    - 实现 fromJson() 和 toJson() 方法
    - 包含 temperature, humidity, timestamp, deviceId 字段
    - _Requirements: 5.1, 5.2_


  - [x] 4.2 编写SensorData JSON往返属性测试




    - **Property 9: Sensor Data JSON Round-Trip**
    - **Validates: Requirements 5.1, 5.3**




  - [x] 4.3 实现User模型


    - 创建 `models/user.dart`
    - 实现用户数据序列化和反序列化
    - _Requirements: 2.2, 3.1_

- [x] 5. 实现认证服务

  - [x] 5.1 创建AuthService基础实现
    - 创建 `services/auth_service.dart`
    - 使用SharedPreferences存储用户数据
    - 实现用户名验证（4-20字符）和密码验证（6-20字符）
    - _Requirements: 2.2, 2.3_

  - [x] 5.2 编写用户名验证属性测试

    - **Property 2: Username Validation**
    - **Validates: Requirements 2.2, 2.3**


  - [x] 5.3 编写密码验证属性测试
    - **Property 3: Password Validation**
    - **Validates: Requirements 2.2, 2.3**

  - [x] 5.4 实现注册功能


    - 实现 `register()` 方法
    - 检查重复用户名
    - 安全存储密码（使用hash）


    - _Requirements: 2.2, 2.4_
  - [x] 5.5 编写重复用户名防止属性测试



    - **Property 4: Duplicate Username Prevention**
    - **Validates: Requirements 2.4**



  - [x] 5.6 实现登录功能
    - 实现 `login()` 方法验证凭证
    - 实现会话token存储
    - _Requirements: 3.1, 3.2, 3.3_

  - [x] 5.7 编写登录凭证验证属性测试
    - **Property 5: Login Credential Verification**
    - **Validates: Requirements 3.1, 3.2**

  - [x] 5.8 实现会话管理
    - 实现 `isLoggedIn()` 检查会话状态
    - 实现 `logout()` 清除会话
    - 实现会话恢复功能
    - _Requirements: 3.4, 3.5_

  - [x] 5.9 编写会话管理属性测试

    - **Property 6: Session Persistence Round-Trip**
    - **Property 7: Logout Clears Session**
    - **Validates: Requirements 3.3, 3.4, 3.5**


- [x] 6. 实现MQTT服务




  - [x] 6.1 创建MqttService实现


    - 创建 `services/mqtt_service.dart`
    - 实现MQTT连接到 broker.emqx.io
    - 实现订阅传感器数据topic
    - _Requirements: 1.2_
  - [x] 6.2 实现数据流处理



    - 使用StreamController提供传感器数据流
    - 实现JSON解析和错误处理
    - _Requirements: 5.2, 5.4_

  - [x] 6.3 编写畸形JSON处理属性测试


    - **Property 10: Malformed JSON Handling**
    - **Validates: Requirements 5.2, 5.4**


- [x] 7. Checkpoint - 确保服务层测试通过



  - Ensure all tests pass, ask the user if questions arise.


- [x] 8. 实现UI界面



  - [x] 8.1 创建登录页面







    - 创建 `screens/login_screen.dart`
    - 实现用户名和密码输入框
    - 添加登录按钮和注册页面导航链接
    - 实现表单验证和错误提示
    - _Requirements: 2.1, 3.1, 3.2_

  - [x] 8.2 创建注册页面


    - 创建 `screens/register_screen.dart`
    - 实现注册表单（用户名、密码、确认密码）
    - 实现输入验证和错误提示
    - 注册成功后导航到登录页面
    - _Requirements: 2.2, 2.3, 2.4, 2.5_

  - [x] 8.3 创建传感器数据卡片组件


    - 创建 `widgets/sensor_card.dart`
    - 实现温度和湿度数据展示卡片
    - 添加图标和单位显示
    - 实现温度>40°C时的警告样式
    - _Requirements: 1.3, 1.4, 4.1, 4.2_

  - [x] 8.4 编写温度警告阈值属性测试


    - **Property 8: Temperature Warning Threshold**
    - **Validates: Requirements 4.2**


  - [x] 8.5 编写传感器数据格式化属性测试
    - **Property 1: Sensor Data Formatting Consistency**
    - **Validates: Requirements 1.3, 1.4**
  - [x] 8.6 创建主仪表盘页面


    - 创建 `screens/dashboard_screen.dart`
    - 集成MQTT服务显示实时数据
    - 添加加载指示器和错误处理
    - 添加登出按钮
    - _Requirements: 1.2, 4.1, 4.3, 4.4, 3.5_
  - [x] 8.7 创建加载指示器组件



    - 创建 `widgets/loading_indicator.dart`
    - 实现美观的加载动画
    - _Requirements: 4.3_

- [x] 9. 实现应用路由和状态管理






  - [x] 9.1 配置应用路由

    - 更新 `main.dart` 配置路由
    - 实现登录状态检查和自动导航
    - 配置应用主题和样式
    - _Requirements: 2.1, 3.4_


  - [x] 9.2 集成Provider状态管理






    - 创建AuthProvider管理认证状态
    - 创建SensorDataProvider管理传感器数据
    - _Requirements: 1.2, 3.3, 3.4_

- [x] 10. Final Checkpoint - 确保所有测试通过






  - Ensure all tests pass, ask the user if questions arise.
