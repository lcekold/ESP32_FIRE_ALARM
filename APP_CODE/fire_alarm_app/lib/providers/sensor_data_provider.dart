import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/sensor_data.dart';
import '../services/mqtt_service.dart';

/// 传感器数据状态管理Provider
/// 
/// 管理MQTT连接、传感器数据流、风扇控制和水泵控制
class SensorDataProvider extends ChangeNotifier {
  final MqttService _mqttService = MqttService();
  StreamSubscription<SensorData>? _subscription;
  
  SensorData? _latestData;
  bool _isConnecting = false;
  bool _isConnected = false;
  bool _isWaitingForData = false;
  String? _errorMessage;
  
  // 命令发送状态
  bool _isSendingCommand = false;

  // ==================== 基础状态属性 ====================
  
  SensorData? get latestData => _latestData;
  bool get isConnecting => _isConnecting;
  bool get isConnected => _isConnected;
  bool get isWaitingForData => _isWaitingForData;
  String? get errorMessage => _errorMessage;
  bool get hasData => _latestData != null;
  bool get isSendingCommand => _isSendingCommand;
  
  // ==================== 风扇状态属性 ====================
  
  bool get isFanOn => _latestData?.isFanOn ?? false;
  bool get isFanAutoMode => _latestData?.isFanAutoMode ?? true;
  
  // ==================== 水泵状态属性 ====================
  
  bool get isPumpOn => _latestData?.isPumpOn ?? false;
  bool get isPumpCooldown => _latestData?.isPumpCooldown ?? false;
  bool get isPumpAvailable => _latestData?.isPumpAvailable ?? true;
  bool get isPumpAutoMode => _latestData?.isPumpAutoMode ?? true;

  // ==================== 蜂鸣器状态属性 ====================
  
  bool get isBuzzerOn => _latestData?.isBuzzerOn ?? false;
  bool get isBuzzerAutoMode => _latestData?.isBuzzerAutoMode ?? true;

  // ==================== 连接管理 ====================

  Future<void> connect() async {
    if (_isConnecting || _isConnected) return;
    
    _isConnecting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _mqttService.connect();
      
      _subscription = _mqttService.sensorDataStream.listen(
        _onDataReceived,
        onError: _onError,
      );

      _isConnecting = false;
      _isConnected = true;
      _isWaitingForData = true;
      notifyListeners();
    } catch (e) {
      _isConnecting = false;
      _isConnected = false;
      _errorMessage = '连接失败: $e';
      notifyListeners();
    }
  }

  void disconnect() {
    _subscription?.cancel();
    _subscription = null;
    _mqttService.disconnect();
    _isConnected = false;
    _isWaitingForData = false;
    notifyListeners();
  }

  Future<void> reconnect() async {
    disconnect();
    _latestData = null;
    _errorMessage = null;
    await connect();
  }

  void _onDataReceived(SensorData data) {
    _latestData = data;
    _isWaitingForData = false;
    _errorMessage = null;
    notifyListeners();
  }

  void _onError(dynamic error) {
    _errorMessage = '数据接收错误: $error';
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  // ==================== 风扇控制方法 ====================
  
  /// 控制风扇开关（仅手动模式下有效）
  Future<bool> controlFan(bool turnOn) async {
    if (_isSendingCommand || !_isConnected) return false;
    
    if (isFanAutoMode) {
      _errorMessage = '请先切换到手动模式';
      notifyListeners();
      return false;
    }
    
    _isSendingCommand = true;
    notifyListeners();
    
    try {
      final success = await _mqttService.sendFanControl(turnOn);
      if (!success) _errorMessage = '发送命令失败';
      return success;
    } finally {
      _isSendingCommand = false;
      notifyListeners();
    }
  }
  
  /// 切换风扇模式
  Future<bool> setFanMode(bool autoMode) async {
    if (_isSendingCommand || !_isConnected) return false;
    
    _isSendingCommand = true;
    notifyListeners();
    
    try {
      final success = await _mqttService.sendFanModeChange(autoMode);
      if (!success) _errorMessage = '发送命令失败';
      return success;
    } finally {
      _isSendingCommand = false;
      notifyListeners();
    }
  }
  
  Future<bool> turnOnFan() => controlFan(true);
  Future<bool> turnOffFan() => controlFan(false);
  Future<bool> setFanAutoMode() => setFanMode(true);
  Future<bool> setFanManualMode() => setFanMode(false);
  
  // ==================== 水泵控制方法 ====================
  
  /// 控制水泵开关（仅手动模式下有效）
  Future<bool> controlPump(bool turnOn) async {
    if (_isSendingCommand || !_isConnected) return false;
    
    if (isPumpAutoMode) {
      _errorMessage = '请先切换到手动模式';
      notifyListeners();
      return false;
    }
    
    if (!isPumpAvailable && turnOn) {
      _errorMessage = '水泵冷却中，请稍后再试';
      notifyListeners();
      return false;
    }
    
    _isSendingCommand = true;
    notifyListeners();
    
    try {
      final success = await _mqttService.sendPumpControl(turnOn);
      if (!success) _errorMessage = '发送命令失败';
      return success;
    } finally {
      _isSendingCommand = false;
      notifyListeners();
    }
  }
  
  /// 切换水泵模式
  Future<bool> setPumpMode(bool autoMode) async {
    if (_isSendingCommand || !_isConnected) return false;
    
    _isSendingCommand = true;
    notifyListeners();
    
    try {
      final success = await _mqttService.sendPumpModeChange(autoMode);
      if (!success) _errorMessage = '发送命令失败';
      return success;
    } finally {
      _isSendingCommand = false;
      notifyListeners();
    }
  }
  
  Future<bool> turnOnPump() => controlPump(true);
  Future<bool> turnOffPump() => controlPump(false);
  Future<bool> setPumpAutoMode() => setPumpMode(true);
  Future<bool> setPumpManualMode() => setPumpMode(false);
  
  // ==================== 蜂鸣器控制方法 ====================
  
  /// 控制蜂鸣器开关（仅手动模式下有效）
  Future<bool> controlBuzzer(bool turnOn) async {
    if (_isSendingCommand || !_isConnected) return false;
    
    if (isBuzzerAutoMode) {
      _errorMessage = '请先切换到手动模式';
      notifyListeners();
      return false;
    }
    
    _isSendingCommand = true;
    notifyListeners();
    
    try {
      final success = await _mqttService.sendBuzzerControl(turnOn);
      if (!success) _errorMessage = '发送命令失败';
      return success;
    } finally {
      _isSendingCommand = false;
      notifyListeners();
    }
  }
  
  /// 切换蜂鸣器模式
  Future<bool> setBuzzerMode(bool autoMode) async {
    if (_isSendingCommand || !_isConnected) return false;
    
    _isSendingCommand = true;
    notifyListeners();
    
    try {
      final success = await _mqttService.sendBuzzerModeChange(autoMode);
      if (!success) _errorMessage = '发送命令失败';
      return success;
    } finally {
      _isSendingCommand = false;
      notifyListeners();
    }
  }
  
  Future<bool> turnOnBuzzer() => controlBuzzer(true);
  Future<bool> turnOffBuzzer() => controlBuzzer(false);
  Future<bool> setBuzzerAutoMode() => setBuzzerMode(true);
  Future<bool> setBuzzerManualMode() => setBuzzerMode(false);

  @override
  void dispose() {
    _subscription?.cancel();
    _mqttService.dispose();
    super.dispose();
  }
}
