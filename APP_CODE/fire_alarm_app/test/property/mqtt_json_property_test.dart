import 'dart:convert';
import 'dart:math';
import 'package:glados/glados.dart';
import 'package:fire_alarm_app/services/mqtt_service.dart';
import 'package:fire_alarm_app/models/sensor_data.dart';

/// **Feature: mqtt-mobile-app, Property 10: Malformed JSON Handling**
/// **Validates: Requirements 5.2, 5.4**
/// 
/// 对于任何不是有效JSON或缺少必需字段的字符串，
/// JSON解析器应返回错误结果而不抛出未处理的异常。

/// 生成有效的传感器数据JSON Map
extension ValidSensorJsonGenerator on Any {
  /// 生成有效的timestamp（毫秒级）
  int _generateTimestamp(Random random) {
    // 使用较小的范围避免int32溢出
    // 生成2020-2025年之间的时间戳
    return 1577836800000 + random.nextInt(157680000) * 1000;
  }
  
  Generator<Map<String, dynamic>> get validSensorJson {
    final random = Random();
    return any.nonEmptyLetters.map((deviceId) {
      return {
        'temperature': -40.0 + random.nextDouble() * 120.0,
        'humidity': random.nextDouble() * 100.0,
        'timestamp': _generateTimestamp(random),
        'device_id': deviceId,
      };
    });
  }
  
  /// 生成缺少device_id的JSON
  Generator<Map<String, dynamic>> get jsonMissingDeviceId {
    final random = Random();
    return any.nonEmptyLetters.map((_) {
      return {
        'temperature': -40.0 + random.nextDouble() * 120.0,
        'humidity': random.nextDouble() * 100.0,
        'timestamp': _generateTimestamp(random),
      };
    });
  }
  
  /// 生成缺少temperature的JSON
  Generator<Map<String, dynamic>> get jsonMissingTemperature {
    final random = Random();
    return any.nonEmptyLetters.map((deviceId) {
      return {
        'humidity': random.nextDouble() * 100.0,
        'timestamp': _generateTimestamp(random),
        'device_id': deviceId,
      };
    });
  }

  /// 生成缺少humidity的JSON
  Generator<Map<String, dynamic>> get jsonMissingHumidity {
    final random = Random();
    return any.nonEmptyLetters.map((deviceId) {
      return {
        'temperature': -40.0 + random.nextDouble() * 120.0,
        'timestamp': _generateTimestamp(random),
        'device_id': deviceId,
      };
    });
  }
  
  /// 生成缺少timestamp的JSON
  Generator<Map<String, dynamic>> get jsonMissingTimestamp {
    final random = Random();
    return any.nonEmptyLetters.map((deviceId) {
      return {
        'temperature': -40.0 + random.nextDouble() * 120.0,
        'humidity': random.nextDouble() * 100.0,
        'device_id': deviceId,
      };
    });
  }
  
  /// 生成temperature类型错误的JSON
  Generator<Map<String, dynamic>> get jsonWrongTemperatureType {
    final random = Random();
    return any.nonEmptyLetters.map((deviceId) {
      return {
        'temperature': 'not_a_number', // 错误类型
        'humidity': random.nextDouble() * 100.0,
        'timestamp': _generateTimestamp(random),
        'device_id': deviceId,
      };
    });
  }
}

void main() {
  // 测试有效JSON应成功解析
  Glados(any.validSensorJson).test(
    'Property 10: 有效JSON应成功解析',
    (jsonMap) {
      final jsonString = json.encode(jsonMap);
      final result = parseSensorData(jsonString);
      
      if (!result.isSuccess) {
        throw Exception('有效JSON解析失败: ${result.error}');
      }
      if (result.data == null) {
        throw Exception('解析结果数据为null');
      }
      if (result.data!.temperature != jsonMap['temperature']) {
        throw Exception('温度不匹配');
      }
      if (result.data!.humidity != jsonMap['humidity']) {
        throw Exception('湿度不匹配');
      }
      if (result.data!.deviceId != jsonMap['device_id']) {
        throw Exception('设备ID不匹配');
      }
    },
  );


  // 测试缺少device_id字段的JSON
  Glados(any.jsonMissingDeviceId).test(
    'Property 10: 缺少device_id字段应返回错误',
    (jsonMap) {
      final jsonString = json.encode(jsonMap);
      final result = parseSensorData(jsonString);
      
      if (result.isSuccess) {
        throw Exception('缺少device_id的JSON不应解析成功');
      }
      if (result.error == null || !result.error!.contains('device_id')) {
        throw Exception('错误消息应包含device_id');
      }
    },
  );

  // 测试缺少temperature字段的JSON
  Glados(any.jsonMissingTemperature).test(
    'Property 10: 缺少temperature字段应返回错误',
    (jsonMap) {
      final jsonString = json.encode(jsonMap);
      final result = parseSensorData(jsonString);
      
      if (result.isSuccess) {
        throw Exception('缺少temperature的JSON不应解析成功');
      }
      if (result.error == null || !result.error!.contains('temperature')) {
        throw Exception('错误消息应包含temperature');
      }
    },
  );

  // 测试缺少humidity字段的JSON
  Glados(any.jsonMissingHumidity).test(
    'Property 10: 缺少humidity字段应返回错误',
    (jsonMap) {
      final jsonString = json.encode(jsonMap);
      final result = parseSensorData(jsonString);
      
      if (result.isSuccess) {
        throw Exception('缺少humidity的JSON不应解析成功');
      }
      if (result.error == null || !result.error!.contains('humidity')) {
        throw Exception('错误消息应包含humidity');
      }
    },
  );

  // 测试缺少timestamp字段的JSON
  Glados(any.jsonMissingTimestamp).test(
    'Property 10: 缺少timestamp字段应返回错误',
    (jsonMap) {
      final jsonString = json.encode(jsonMap);
      final result = parseSensorData(jsonString);
      
      if (result.isSuccess) {
        throw Exception('缺少timestamp的JSON不应解析成功');
      }
      if (result.error == null || !result.error!.contains('timestamp')) {
        throw Exception('错误消息应包含timestamp');
      }
    },
  );


  // 测试temperature类型错误的JSON
  Glados(any.jsonWrongTemperatureType).test(
    'Property 10: temperature类型错误应返回错误',
    (jsonMap) {
      final jsonString = json.encode(jsonMap);
      final result = parseSensorData(jsonString);
      
      if (result.isSuccess) {
        throw Exception('temperature类型错误的JSON不应解析成功');
      }
      if (result.error == null || !result.error!.contains('temperature')) {
        throw Exception('错误消息应包含temperature');
      }
    },
  );

  // 测试随机字符串不会导致异常
  Glados(any.letters).test(
    'Property 10: 任意字符串不应导致未处理异常',
    (randomString) {
      // 对于任意随机字符串，parseSensorData不应抛出异常
      final result = parseSensorData(randomString);
      
      // 结果应该是MqttResult类型
      if (result is! MqttResult<SensorData>) {
        throw Exception('返回类型错误');
      }
      
      // 随机字母字符串不是有效JSON，应该返回失败
      if (result.isSuccess) {
        throw Exception('无效JSON不应解析成功');
      }
      if (result.error == null) {
        throw Exception('失败结果应包含错误消息');
      }
    },
  );

  // 边界测试：空字符串
  Glados(any.always('')).test(
    'Property 10: 空字符串应返回错误',
    (emptyString) {
      final result = parseSensorData(emptyString);
      if (result.isSuccess) {
        throw Exception('空字符串不应解析成功');
      }
      if (result.error == null) {
        throw Exception('失败结果应包含错误消息');
      }
    },
  );

  // 边界测试：null JSON
  Glados(any.always('null')).test(
    'Property 10: null JSON应返回错误',
    (nullJson) {
      final result = parseSensorData(nullJson);
      if (result.isSuccess) {
        throw Exception('null JSON不应解析成功');
      }
      if (result.error == null) {
        throw Exception('失败结果应包含错误消息');
      }
    },
  );

  // 边界测试：数组JSON
  Glados(any.always('[1, 2, 3]')).test(
    'Property 10: 数组JSON应返回错误',
    (arrayJson) {
      final result = parseSensorData(arrayJson);
      if (result.isSuccess) {
        throw Exception('数组JSON不应解析成功');
      }
      if (result.error == null || !result.error!.contains('对象类型')) {
        throw Exception('错误消息应说明期望对象类型');
      }
    },
  );
}
