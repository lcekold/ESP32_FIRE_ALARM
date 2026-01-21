import 'dart:math';
import 'package:glados/glados.dart';
import 'package:fire_alarm_app/models/sensor_data.dart';

/// Custom generator for SensorData
/// Generates valid sensor data with realistic temperature and humidity values
extension SensorDataGenerator on Any {
  /// Generates a valid SensorData instance
  Generator<SensorData> get sensorData {
    final random = Random();
    return any.nonEmptyLetters.map((deviceId) {
      return SensorData(
        temperature: -40.0 + random.nextDouble() * 120.0,  // -40 to 80
        humidity: random.nextDouble() * 100.0,              // 0 to 100
        timestamp: DateTime.fromMillisecondsSinceEpoch(
          random.nextInt(2000000000) * 1000,

        ),
        deviceId: deviceId,
      );
    });
  }
}

void main() {
  // **Feature: mqtt-mobile-app, Property 9: Sensor Data JSON Round-Trip**
  // **Validates: Requirements 5.1, 5.3**
  // 
  // *For any* valid SensorData object containing temperature, humidity, 
  // timestamp, and device_id, serializing to JSON and then deserializing 
  // SHALL produce an equivalent SensorData object.
  Glados(any.sensorData).test(
    'Property 9: Sensor Data JSON Round-Trip - toJson then fromJson produces equivalent object',
    (sensorData) {
      // Serialize to JSON
      final json = sensorData.toJson();
      
      // Deserialize back to SensorData
      final restored = SensorData.fromJson(json);
      
      // Verify round-trip produces equivalent object
      if (restored.temperature != sensorData.temperature) {
        throw Exception('Temperature mismatch: ${restored.temperature} != ${sensorData.temperature}');
      }
      if (restored.humidity != sensorData.humidity) {
        throw Exception('Humidity mismatch: ${restored.humidity} != ${sensorData.humidity}');
      }
      if (restored.timestamp != sensorData.timestamp) {
        throw Exception('Timestamp mismatch: ${restored.timestamp} != ${sensorData.timestamp}');
      }
      if (restored.deviceId != sensorData.deviceId) {
        throw Exception('DeviceId mismatch: ${restored.deviceId} != ${sensorData.deviceId}');
      }
      if (restored != sensorData) {
        throw Exception('Objects not equal: $restored != $sensorData');
      }
    },
  );
}
