/// SensorData model representing all sensor and device data from ESP32-S3
/// 
/// This model is used to parse JSON data received via MQTT from the fire suppression system.
/// Includes temperature, humidity, smoke, fan, pump and K230 vision data.
class SensorData {
  final double temperature;
  final double humidity;
  final double smokeLevel;
  final bool smokeAlarm;
  final String fanState;      // "on" or "off"
  final String fanMode;       // "auto" or "manual"
  final String pumpState;     // "on", "off" or "cooldown"
  final String pumpMode;      // "auto" or "manual"
  final String k230Fire;      // "none", "detected" or "confirmed"
  final bool k230FireDetected; // K230视觉模块是否检测到火焰
  final String buzzerState;   // "on" or "off"
  final String buzzerMode;    // "auto" or "manual"
  final DateTime timestamp;
  final String deviceId;

  SensorData({
    required this.temperature,
    required this.humidity,
    required this.smokeLevel,
    required this.smokeAlarm,
    required this.fanState,
    required this.fanMode,
    required this.pumpState,
    required this.pumpMode,
    required this.k230Fire,
    required this.k230FireDetected,
    required this.buzzerState,
    required this.buzzerMode,
    required this.timestamp,
    required this.deviceId,
  });

  // ==================== 风扇状态便捷属性 ====================
  
  /// 风扇是否开启
  bool get isFanOn => fanState == 'on';
  
  /// 风扇是否为自动模式
  bool get isFanAutoMode => fanMode == 'auto';

  // ==================== 水泵状态便捷属性 ====================
  
  /// 水泵是否开启（喷水中）
  bool get isPumpOn => pumpState == 'on';
  
  /// 水泵是否在冷却中
  bool get isPumpCooldown => pumpState == 'cooldown';
  
  /// 水泵是否可用（非冷却状态）
  bool get isPumpAvailable => pumpState != 'cooldown';
  
  /// 水泵是否为自动模式
  bool get isPumpAutoMode => pumpMode == 'auto';

  // ==================== K230视觉检测状态便捷属性 ====================
  
  /// K230是否检测到火焰
  bool get isK230FireActive => k230FireDetected;
  
  /// K230火焰是否已确认（正在灭火）
  bool get isK230FireConfirmed => k230Fire == 'confirmed';

  // ==================== 蜂鸣器状态便捷属性 ====================
  
  /// 蜂鸣器是否开启
  bool get isBuzzerOn => buzzerState == 'on';
  
  /// 蜂鸣器是否为自动模式
  bool get isBuzzerAutoMode => buzzerMode == 'auto';

  /// Creates a SensorData instance from JSON map
  /// 
  /// Expected JSON format:
  /// {
  ///   "device_id": "esp32_fire_alarm_001",
  ///   "temperature": 25.5,
  ///   "humidity": 60.2,
  ///   "smoke_level": 15.3,
  ///   "smoke_alarm": false,
  ///   "fan_state": "off",
  ///   "fan_mode": "auto",
  ///   "pump_state": "off",
  ///   "pump_mode": "auto",
  ///   "k230_fire": "none",
  ///   "k230_fire_detected": false,
  ///   "buzzer_state": "off",
  ///   "buzzer_mode": "auto",
  ///   "timestamp": 1703232000000
  /// }
  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      temperature: (json['temperature'] as num).toDouble(),
      humidity: (json['humidity'] as num).toDouble(),
      smokeLevel: (json['smoke_level'] as num?)?.toDouble() ?? 0.0,
      smokeAlarm: json['smoke_alarm'] as bool? ?? false,
      fanState: json['fan_state'] as String? ?? 'off',
      fanMode: json['fan_mode'] as String? ?? 'auto',
      pumpState: json['pump_state'] as String? ?? 'off',
      pumpMode: json['pump_mode'] as String? ?? 'auto',
      k230Fire: json['k230_fire'] as String? ?? 'none',
      k230FireDetected: json['k230_fire_detected'] as bool? ?? false,
      buzzerState: json['buzzer_state'] as String? ?? 'off',
      buzzerMode: json['buzzer_mode'] as String? ?? 'auto',
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
      deviceId: json['device_id'] as String,
    );
  }

  /// Converts SensorData to JSON map for serialization
  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'humidity': humidity,
      'smoke_level': smokeLevel,
      'smoke_alarm': smokeAlarm,
      'fan_state': fanState,
      'fan_mode': fanMode,
      'pump_state': pumpState,
      'pump_mode': pumpMode,
      'k230_fire': k230Fire,
      'k230_fire_detected': k230FireDetected,
      'buzzer_state': buzzerState,
      'buzzer_mode': buzzerMode,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'device_id': deviceId,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SensorData &&
        other.temperature == temperature &&
        other.humidity == humidity &&
        other.smokeLevel == smokeLevel &&
        other.smokeAlarm == smokeAlarm &&
        other.fanState == fanState &&
        other.fanMode == fanMode &&
        other.pumpState == pumpState &&
        other.pumpMode == pumpMode &&
        other.k230Fire == k230Fire &&
        other.k230FireDetected == k230FireDetected &&
        other.buzzerState == buzzerState &&
        other.buzzerMode == buzzerMode &&
        other.timestamp == timestamp &&
        other.deviceId == deviceId;
  }

  @override
  int get hashCode {
    return Object.hash(
      temperature, humidity, smokeLevel, smokeAlarm,
      fanState, fanMode, pumpState, pumpMode,
      k230Fire, k230FireDetected, buzzerState, buzzerMode,
      timestamp, deviceId,
    );
  }

  @override
  String toString() {
    return 'SensorData(temp: $temperature, humidity: $humidity, '
        'smoke: $smokeLevel, alarm: $smokeAlarm, '
        'fan: $fanState/$fanMode, pump: $pumpState/$pumpMode, '
        'buzzer: $buzzerState/$buzzerMode, k230: $k230Fire)';
  }
}
