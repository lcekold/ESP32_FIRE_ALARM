/// MQTT和应用配置常量
/// 
/// 定义了MQTT连接参数和应用相关的配置常量
/// _Requirements: 1.2_

/// MQTT Broker配置
class MqttConfig {
  /// MQTT Broker地址
  static const String broker = 'broker.emqx.io';
  
  /// MQTT Broker端口
  static const int port = 1883;
  
  /// WebSocket端口（用于移动端连接）
  static const int wsPort = 8083;
  
  /// 传感器数据Topic (订阅)
  static const String sensorDataTopic = 'fire_alarm/sensor_data';
  
  /// 风扇控制Topic (发布)
  static const String fanControlTopic = 'fire_alarm/fan/control';
  
  /// 风扇模式Topic (发布)
  static const String fanModeTopic = 'fire_alarm/fan/mode';
  
  /// 水泵控制Topic (发布)
  static const String pumpControlTopic = 'fire_alarm/pump/control';
  
  /// 水泵模式Topic (发布)
  static const String pumpModeTopic = 'fire_alarm/pump/mode';
  
  /// 蜂鸣器控制Topic (发布)
  static const String buzzerControlTopic = 'fire_alarm/buzzer/control';
  
  /// 蜂鸣器模式Topic (发布)
  static const String buzzerModeTopic = 'fire_alarm/buzzer/mode';
  
  /// 客户端ID前缀
  static const String clientIdPrefix = 'fire_alarm_app_';
  
  /// 连接超时时间（秒）
  static const int connectionTimeout = 30;
  
  /// Keep Alive间隔（秒）
  static const int keepAlivePeriod = 60;
}

/// 用户认证配置
class AuthConfig {
  /// 用户名最小长度
  static const int usernameMinLength = 4;
  
  /// 用户名最大长度
  static const int usernameMaxLength = 20;
  
  /// 密码最小长度
  static const int passwordMinLength = 6;
  
  /// 密码最大长度
  static const int passwordMaxLength = 20;
}

/// 传感器数据配置
class SensorConfig {
  /// 温度警告阈值（摄氏度）
  static const double temperatureWarningThreshold = 40.0;
  
  /// 温度单位
  static const String temperatureUnit = '°C';
  
  /// 湿度单位
  static const String humidityUnit = '%';
  
  /// 数据显示小数位数
  static const int decimalPlaces = 1;
}

/// 本地存储Key
class StorageKeys {
  /// 用户列表
  static const String users = 'users';
  
  /// 当前登录用户
  static const String currentUser = 'current_user';
  
  /// 会话Token
  static const String sessionToken = 'session_token';
}
