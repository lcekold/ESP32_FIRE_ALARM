import 'dart:async';
import 'dart:convert';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import '../models/sensor_data.dart';
import '../utils/constants.dart';

/// MQTT服务结果类型
class MqttResult<T> {
  final T? data;
  final String? error;
  final bool isSuccess;

  MqttResult.success(this.data)
      : error = null,
        isSuccess = true;

  MqttResult.failure(this.error)
      : data = null,
        isSuccess = false;
}

/// MQTT服务接口
abstract class MqttServiceInterface {
  Future<void> connect();
  void disconnect();
  Stream<SensorData> get sensorDataStream;
  bool get isConnected;
  
  // 风扇控制方法
  Future<bool> sendFanControl(bool turnOn);
  Future<bool> sendFanModeChange(bool autoMode);
  
  // 水泵控制方法
  Future<bool> sendPumpControl(bool turnOn);
  Future<bool> sendPumpModeChange(bool autoMode);
  
  // 蜂鸣器控制方法
  Future<bool> sendBuzzerControl(bool turnOn);
  Future<bool> sendBuzzerModeChange(bool autoMode);
}

/// MQTT服务实现
/// 
/// 支持双向通信：
/// - 订阅传感器数据
/// - 发布风扇控制命令
class MqttService implements MqttServiceInterface {
  MqttServerClient? _client;
  final StreamController<SensorData> _sensorDataController =
      StreamController<SensorData>.broadcast();
  
  bool _isConnected = false;
  
  @override
  Stream<SensorData> get sensorDataStream => _sensorDataController.stream;
  
  @override
  bool get isConnected => _isConnected;

  /// 连接到MQTT Broker
  @override
  Future<void> connect() async {
    if (_isConnected) return;
    
    final clientId = '${MqttConfig.clientIdPrefix}${DateTime.now().millisecondsSinceEpoch}';
    
    _client = MqttServerClient.withPort(
      'ws://${MqttConfig.broker}/mqtt',
      clientId,
      MqttConfig.wsPort,
    );
    
    _client!.useWebSocket = true;
    _client!.port = MqttConfig.wsPort;
    _client!.logging(on: false);
    _client!.keepAlivePeriod = MqttConfig.keepAlivePeriod;
    _client!.connectTimeoutPeriod = MqttConfig.connectionTimeout * 1000;
    _client!.onConnected = _onConnected;
    _client!.onDisconnected = _onDisconnected;
    _client!.onSubscribed = _onSubscribed;
    
    final connMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .withWillTopic('fire_alarm/status')
        .withWillMessage('offline')
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    
    _client!.connectionMessage = connMessage;
    
    try {
      await _client!.connect();
    } catch (e) {
      _client!.disconnect();
      throw Exception('MQTT连接失败: $e');
    }
    
    if (_client!.connectionStatus?.state == MqttConnectionState.connected) {
      _isConnected = true;
      _subscribeToSensorData();
    } else {
      throw Exception('MQTT连接失败: ${_client!.connectionStatus}');
    }
  }

  @override
  void disconnect() {
    if (_client != null) {
      _client!.disconnect();
      _isConnected = false;
    }
  }
  
  void _subscribeToSensorData() {
    _client!.subscribe(MqttConfig.sensorDataTopic, MqttQos.atLeastOnce);
    
    _client!.updates?.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
      for (final message in messages) {
        final recMessage = message.payload as MqttPublishMessage;
        final payload = MqttPublishPayload.bytesToStringAsString(
          recMessage.payload.message,
        );
        
        _handleMessage(payload);
      }
    });
  }
  
  void _handleMessage(String payload) {
    final result = parseSensorData(payload);
    if (result.isSuccess && result.data != null) {
      _sensorDataController.add(result.data!);
    }
  }
  
  void _onConnected() {
    _isConnected = true;
  }
  
  void _onDisconnected() {
    _isConnected = false;
  }
  
  void _onSubscribed(String topic) {
    // 订阅成功
  }
  
  // ==================== 风扇控制方法 ====================
  
  /// 发送风扇控制命令
  /// 
  /// [turnOn] true=开启风扇, false=关闭风扇
  /// 返回是否发送成功
  @override
  Future<bool> sendFanControl(bool turnOn) async {
    if (!_isConnected || _client == null) {
      return false;
    }
    
    final command = {
      'command': 'fan',
      'action': turnOn ? 'on' : 'off',
    };
    
    return _publishMessage(MqttConfig.fanControlTopic, json.encode(command));
  }
  
  /// 发送风扇模式切换命令
  /// 
  /// [autoMode] true=自动模式, false=手动模式
  /// 返回是否发送成功
  @override
  Future<bool> sendFanModeChange(bool autoMode) async {
    if (!_isConnected || _client == null) {
      return false;
    }
    
    final command = {
      'command': 'mode',
      'action': autoMode ? 'auto' : 'manual',
    };
    
    return _publishMessage(MqttConfig.fanModeTopic, json.encode(command));
  }
  
  /// 发布MQTT消息
  bool _publishMessage(String topic, String message) {
    try {
      final builder = MqttClientPayloadBuilder();
      builder.addString(message);
      
      _client!.publishMessage(
        topic,
        MqttQos.atLeastOnce,
        builder.payload!,
      );
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // ==================== 水泵控制方法 ====================
  
  /// 发送水泵控制命令
  /// 
  /// [turnOn] true=开启水泵（喷水）, false=关闭水泵
  /// 返回是否发送成功
  @override
  Future<bool> sendPumpControl(bool turnOn) async {
    if (!_isConnected || _client == null) {
      return false;
    }
    
    final command = {
      'command': 'pump',
      'action': turnOn ? 'on' : 'off',
    };
    
    return _publishMessage(MqttConfig.pumpControlTopic, json.encode(command));
  }
  
  /// 发送水泵模式切换命令
  /// 
  /// [autoMode] true=自动模式, false=手动模式
  /// 返回是否发送成功
  @override
  Future<bool> sendPumpModeChange(bool autoMode) async {
    if (!_isConnected || _client == null) {
      return false;
    }
    
    final command = {
      'command': 'mode',
      'action': autoMode ? 'auto' : 'manual',
    };
    
    return _publishMessage(MqttConfig.pumpModeTopic, json.encode(command));
  }
  
  // ==================== 蜂鸣器控制方法 ====================
  
  /// 发送蜂鸣器控制命令
  /// 
  /// [turnOn] true=开启蜂鸣器, false=关闭蜂鸣器
  /// 返回是否发送成功
  @override
  Future<bool> sendBuzzerControl(bool turnOn) async {
    if (!_isConnected || _client == null) {
      return false;
    }
    
    final command = {
      'command': 'buzzer',
      'action': turnOn ? 'on' : 'off',
    };
    
    return _publishMessage(MqttConfig.buzzerControlTopic, json.encode(command));
  }
  
  /// 发送蜂鸣器模式切换命令
  /// 
  /// [autoMode] true=自动模式, false=手动模式
  /// 返回是否发送成功
  @override
  Future<bool> sendBuzzerModeChange(bool autoMode) async {
    if (!_isConnected || _client == null) {
      return false;
    }
    
    final command = {
      'command': 'mode',
      'action': autoMode ? 'auto' : 'manual',
    };
    
    return _publishMessage(MqttConfig.buzzerModeTopic, json.encode(command));
  }
  
  void dispose() {
    disconnect();
    _sensorDataController.close();
  }
}

/// 解析传感器数据JSON
MqttResult<SensorData> parseSensorData(String jsonString) {
  try {
    final dynamic decoded = json.decode(jsonString);
    
    if (decoded is! Map<String, dynamic>) {
      return MqttResult.failure('JSON数据格式错误：期望对象类型');
    }
    
    final Map<String, dynamic> jsonMap = decoded;
    
    // 验证必需字段
    if (!jsonMap.containsKey('temperature')) {
      return MqttResult.failure('缺少必需字段: temperature');
    }
    if (!jsonMap.containsKey('humidity')) {
      return MqttResult.failure('缺少必需字段: humidity');
    }
    if (!jsonMap.containsKey('timestamp')) {
      return MqttResult.failure('缺少必需字段: timestamp');
    }
    if (!jsonMap.containsKey('device_id')) {
      return MqttResult.failure('缺少必需字段: device_id');
    }
    
    // 验证字段类型
    if (jsonMap['temperature'] is! num) {
      return MqttResult.failure('字段类型错误: temperature 应为数字');
    }
    if (jsonMap['humidity'] is! num) {
      return MqttResult.failure('字段类型错误: humidity 应为数字');
    }
    if (jsonMap['timestamp'] is! int) {
      return MqttResult.failure('字段类型错误: timestamp 应为整数');
    }
    if (jsonMap['device_id'] is! String) {
      return MqttResult.failure('字段类型错误: device_id 应为字符串');
    }
    
    final sensorData = SensorData.fromJson(jsonMap);
    return MqttResult.success(sensorData);
  } on FormatException catch (e) {
    return MqttResult.failure('JSON解析错误: ${e.message}');
  } catch (e) {
    return MqttResult.failure('未知错误: $e');
  }
}
