import 'dart:math';
import 'package:glados/glados.dart';
import 'package:fire_alarm_app/widgets/sensor_card.dart';
import 'package:fire_alarm_app/utils/constants.dart';

/// Custom generator for temperature values
/// Generates temperature values across a wide range including edge cases
extension TemperatureGenerator on Any {
  /// Generates temperature values from -50 to 100
  Generator<double> get temperature {
    final random = Random();
    return any.int.map((_) {
      // Generate temperatures in range -50 to 100
      return -50.0 + random.nextDouble() * 150.0;
    });
  }
  
  /// Generates humidity values from 0 to 100
  Generator<double> get humidity {
    final random = Random();
    return any.int.map((_) {
      return random.nextDouble() * 100.0;
    });
  }
}

void main() {
  // **Feature: mqtt-mobile-app, Property 8: Temperature Warning Threshold**
  // **Validates: Requirements 4.2**
  //
  // *For any* temperature value T, if T > 40.0, the UI state SHALL indicate 
  // warning mode; if T ≤ 40.0, the UI state SHALL indicate normal mode.
  Glados(any.temperature).test(
    'Property 8: Temperature Warning Threshold - warning state matches threshold',
    (temperature) {
      final isWarning = SensorCard.isTemperatureWarning(temperature);
      final expectedWarning = temperature > SensorConfig.temperatureWarningThreshold;
      
      if (isWarning != expectedWarning) {
        throw Exception(
          'Temperature $temperature: isWarning=$isWarning but expected=$expectedWarning '
          '(threshold=${SensorConfig.temperatureWarningThreshold})'
        );
      }
    },
  );

  // **Feature: mqtt-mobile-app, Property 1: Sensor Data Formatting Consistency**
  // **Validates: Requirements 1.3, 1.4**
  //
  // *For any* temperature value and humidity value, the formatted display string 
  // SHALL contain exactly one decimal place and the appropriate unit.
  Glados(any.temperature).test(
    'Property 1: Temperature Formatting - contains one decimal place and °C unit',
    (temperature) {
      final formatted = SensorCard.formatSensorValue(
        temperature, 
        SensorConfig.temperatureUnit,
      );
      
      // Check that the formatted string contains the unit
      if (!formatted.contains(SensorConfig.temperatureUnit)) {
        throw Exception(
          'Formatted temperature "$formatted" does not contain unit "${SensorConfig.temperatureUnit}"'
        );
      }
      
      // Check that it has exactly one decimal place
      final valueStr = formatted.replaceAll(SensorConfig.temperatureUnit, '');
      final parts = valueStr.split('.');
      if (parts.length != 2) {
        throw Exception(
          'Formatted temperature "$formatted" does not have decimal point'
        );
      }
      if (parts[1].length != SensorConfig.decimalPlaces) {
        throw Exception(
          'Formatted temperature "$formatted" does not have exactly ${SensorConfig.decimalPlaces} decimal place(s)'
        );
      }
    },
  );

  Glados(any.humidity).test(
    'Property 1: Humidity Formatting - contains one decimal place and % unit',
    (humidity) {
      final formatted = SensorCard.formatSensorValue(
        humidity, 
        SensorConfig.humidityUnit,
      );
      
      // Check that the formatted string contains the unit
      if (!formatted.contains(SensorConfig.humidityUnit)) {
        throw Exception(
          'Formatted humidity "$formatted" does not contain unit "${SensorConfig.humidityUnit}"'
        );
      }
      
      // Check that it has exactly one decimal place
      final valueStr = formatted.replaceAll(SensorConfig.humidityUnit, '');
      final parts = valueStr.split('.');
      if (parts.length != 2) {
        throw Exception(
          'Formatted humidity "$formatted" does not have decimal point'
        );
      }
      if (parts[1].length != SensorConfig.decimalPlaces) {
        throw Exception(
          'Formatted humidity "$formatted" does not have exactly ${SensorConfig.decimalPlaces} decimal place(s)'
        );
      }
    },
  );
}
