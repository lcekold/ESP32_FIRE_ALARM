import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// 传感器数据卡片组件
/// 
/// 用于展示温度或湿度数据，支持警告状态显示
/// _Requirements: 1.3, 1.4, 4.1, 4.2_
class SensorCard extends StatelessWidget {
  final String title;
  final double value;
  final String unit;
  final IconData icon;
  final bool isWarning;
  final Color? normalColor;
  final Color? warningColor;

  const SensorCard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    this.isWarning = false,
    this.normalColor,
    this.warningColor,
  });

  /// 创建温度卡片
  /// 
  /// 当温度超过40°C时自动显示警告样式
  /// **Property 8: Temperature Warning Threshold**
  /// **Validates: Requirements 4.2**
  factory SensorCard.temperature({
    Key? key,
    required double temperature,
  }) {
    final isWarning = isTemperatureWarning(temperature);
    return SensorCard(
      key: key,
      title: '温度',
      value: temperature,
      unit: SensorConfig.temperatureUnit,
      icon: Icons.thermostat,
      isWarning: isWarning,
      normalColor: Colors.orange,
      warningColor: Colors.red,
    );
  }

  /// 创建湿度卡片
  factory SensorCard.humidity({
    Key? key,
    required double humidity,
  }) {
    return SensorCard(
      key: key,
      title: '湿度',
      value: humidity,
      unit: SensorConfig.humidityUnit,
      icon: Icons.water_drop,
      normalColor: Colors.blue,
    );
  }

  /// 创建烟雾传感器卡片
  /// 
  /// 当检测到烟雾报警时显示警告样式
  factory SensorCard.smoke({
    Key? key,
    required double smokeLevel,
    required bool smokeAlarm,
  }) {
    return SensorCard(
      key: key,
      title: '烟雾浓度',
      value: smokeLevel,
      unit: '%',
      icon: Icons.cloud,
      isWarning: smokeAlarm,
      normalColor: Colors.grey,
      warningColor: Colors.red,
    );
  }

  /// 创建K230视觉火焰检测卡片
  /// 
  /// 当检测到火焰时显示警告样式
  static Widget k230Fire({
    Key? key,
    required String fireState,
    required bool fireDetected,
  }) {
    return _K230FireCard(
      key: key,
      fireState: fireState,
      fireDetected: fireDetected,
    );
  }

  /// 检查温度是否超过警告阈值
  /// 
  /// **Property 8: Temperature Warning Threshold**
  /// **Validates: Requirements 4.2**
  static bool isTemperatureWarning(double temperature) {
    return temperature > SensorConfig.temperatureWarningThreshold;
  }

  /// 格式化传感器数值
  /// 
  /// 保留一位小数并添加单位
  /// **Property 1: Sensor Data Formatting Consistency**
  /// **Validates: Requirements 1.3, 1.4**
  static String formatSensorValue(double value, String unit) {
    return '${value.toStringAsFixed(SensorConfig.decimalPlaces)}$unit';
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = isWarning 
        ? (warningColor ?? Colors.red) 
        : (normalColor ?? Theme.of(context).colorScheme.primary);
    
    final backgroundColor = isWarning
        ? Colors.red[50]
        : cardColor.withOpacity(0.1);

    return Card(
      elevation: isWarning ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isWarning 
            ? BorderSide(color: Colors.red[300]!, width: 2)
            : BorderSide.none,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: backgroundColor,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题行
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cardColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: cardColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (isWarning) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.warning,
                          color: Colors.white,
                          size: 14,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '警告',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            // 数值显示
            Text(
              formatSensorValue(value, unit),
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: cardColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


/// K230视觉火焰检测卡片组件
/// 
/// 显示K230视觉模块的火焰检测状态
class _K230FireCard extends StatelessWidget {
  final String fireState;
  final bool fireDetected;

  const _K230FireCard({
    super.key,
    required this.fireState,
    required this.fireDetected,
  });

  @override
  Widget build(BuildContext context) {
    final isWarning = fireDetected;
    final cardColor = isWarning ? Colors.red : Colors.green;
    final backgroundColor = isWarning ? Colors.red[50] : Colors.green[50];
    
    String statusText;
    IconData statusIcon;
    
    switch (fireState) {
      case 'confirmed':
        statusText = '火焰确认 - 灭火中';
        statusIcon = Icons.local_fire_department;
        break;
      case 'detected':
        statusText = '检测到火焰';
        statusIcon = Icons.local_fire_department;
        break;
      default:
        statusText = '正常';
        statusIcon = Icons.check_circle;
    }

    return Card(
      elevation: isWarning ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isWarning 
            ? BorderSide(color: Colors.red[300]!, width: 2)
            : BorderSide.none,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: backgroundColor,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题行
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cardColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    color: cardColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'K230视觉检测',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (isWarning) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.warning,
                          color: Colors.white,
                          size: 14,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '火警',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            // 状态显示
            Row(
              children: [
                Icon(
                  statusIcon,
                  color: cardColor,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Text(
                  statusText,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: cardColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
