import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/sensor_data_provider.dart';
import '../widgets/sensor_card.dart';
import '../widgets/fan_control_card.dart';
import '../widgets/pump_control_card.dart';
import '../widgets/buzzer_control_card.dart';
import 'login_screen.dart';

/// 主仪表盘页面
/// 
/// 显示实时传感器数据，集成MQTT服务
/// 无论连接状态如何，始终显示完整界面
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    _connectMqtt();
  }

  Future<void> _connectMqtt() async {
    final sensorProvider = context.read<SensorDataProvider>();
    await sensorProvider.connect();
  }

  Future<void> _retry() async {
    final sensorProvider = context.read<SensorDataProvider>();
    await sensorProvider.reconnect();
  }

  Future<void> _logout() async {
    final authProvider = context.read<AuthProvider>();
    final sensorProvider = context.read<SensorDataProvider>();
    
    sensorProvider.disconnect();
    await authProvider.logout();
    
    if (!mounted) return;
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认登出'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _logout();
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('火灾监控'),
        centerTitle: true,
        actions: [
          Consumer<SensorDataProvider>(
            builder: (context, sensorProvider, _) => IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: sensorProvider.isConnecting ? null : _retry,
              tooltip: '刷新连接',
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _showLogoutDialog,
            tooltip: '登出',
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _retry,
          child: Consumer<SensorDataProvider>(
            builder: (context, sensorProvider, _) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 连接状态卡片
                    _buildConnectionStatusCard(sensorProvider),
                    const SizedBox(height: 16),
                    
                    // 传感器数据卡片（始终显示）
                    _buildSensorCards(sensorProvider),
                    const SizedBox(height: 24),
                    
                    // 设备控制卡片（始终显示）
                    _buildControlCards(sensorProvider),
                    const SizedBox(height: 24),
                    
                    // 设备信息卡片
                    _buildDeviceInfoCard(sensorProvider),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// 构建连接状态卡片
  Widget _buildConnectionStatusCard(SensorDataProvider sensorProvider) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final currentUser = authProvider.currentUser ?? '用户';
        
        // 确定连接状态
        String statusText;
        Color statusColor;
        IconData statusIcon;
        
        if (sensorProvider.isConnecting) {
          statusText = '正在连接...';
          statusColor = Colors.orange;
          statusIcon = Icons.sync;
        } else if (sensorProvider.hasData) {
          statusText = '已连接 · 数据同步中';
          statusColor = Colors.green;
          statusIcon = Icons.cloud_done;
        } else if (sensorProvider.isConnected) {
          statusText = '已连接 · 等待数据';
          statusColor = Colors.blue;
          statusIcon = Icons.cloud_queue;
        } else if (sensorProvider.errorMessage != null) {
          statusText = '连接失败';
          statusColor = Colors.red;
          statusIcon = Icons.cloud_off;
        } else {
          statusText = '未连接';
          statusColor = Colors.grey;
          statusIcon = Icons.cloud_off;
        }
        
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Text(
                        currentUser[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '欢迎，$currentUser',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(statusIcon, size: 14, color: statusColor),
                              const SizedBox(width: 4),
                              Text(
                                statusText,
                                style: TextStyle(color: statusColor, fontSize: 12),
                              ),
                              if (sensorProvider.isConnecting) ...[
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: statusColor,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // 错误信息提示
                if (sensorProvider.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            sensorProvider.errorMessage!,
                            style: TextStyle(color: Colors.red[700], fontSize: 12),
                          ),
                        ),
                        TextButton(
                          onPressed: _retry,
                          child: const Text('重试'),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// 构建传感器数据卡片
  Widget _buildSensorCards(SensorDataProvider sensorProvider) {
    final hasData = sensorProvider.hasData;
    final data = sensorProvider.latestData;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 温度卡片
        _buildSensorCardWithOverlay(
          hasData: hasData,
          child: SensorCard.temperature(
            temperature: data?.temperature ?? 0.0,
          ),
        ),
        const SizedBox(height: 16),
        
        // 湿度卡片
        _buildSensorCardWithOverlay(
          hasData: hasData,
          child: SensorCard.humidity(
            humidity: data?.humidity ?? 0.0,
          ),
        ),
        const SizedBox(height: 16),
        
        // 烟雾卡片
        _buildSensorCardWithOverlay(
          hasData: hasData,
          child: SensorCard.smoke(
            smokeLevel: data?.smokeLevel ?? 0.0,
            smokeAlarm: data?.smokeAlarm ?? false,
          ),
        ),
        const SizedBox(height: 16),
        
        // K230火焰检测卡片
        _buildSensorCardWithOverlay(
          hasData: hasData,
          child: SensorCard.k230Fire(
            fireState: data?.k230Fire ?? 'none',
            fireDetected: data?.k230FireDetected ?? false,
          ),
        ),
      ],
    );
  }

  /// 为传感器卡片添加离线遮罩
  Widget _buildSensorCardWithOverlay({
    required bool hasData,
    required Widget child,
  }) {
    if (hasData) return child;
    
    return Stack(
      children: [
        // 原始卡片（降低透明度）
        Opacity(opacity: 0.5, child: child),
        // 等待数据提示
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      '等待数据',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 构建设备控制卡片
  Widget _buildControlCards(SensorDataProvider sensorProvider) {
    final isOnline = sensorProvider.hasData;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 风扇控制
        _buildControlCardWithStatus(
          isOnline: isOnline,
          child: FanControlCard(
            isFanOn: sensorProvider.isFanOn,
            isAutoMode: sensorProvider.isFanAutoMode,
            isLoading: sensorProvider.isSendingCommand,
            onToggleFan: isOnline ? () => _handleFanToggle(sensorProvider) : null,
            onToggleMode: isOnline ? () => _handleFanModeToggle(sensorProvider) : null,
          ),
        ),
        const SizedBox(height: 16),
        
        // 水泵控制
        _buildControlCardWithStatus(
          isOnline: isOnline,
          child: PumpControlCard(
            isPumpOn: sensorProvider.isPumpOn,
            isPumpCooldown: sensorProvider.isPumpCooldown,
            isAutoMode: sensorProvider.isPumpAutoMode,
            isLoading: sensorProvider.isSendingCommand,
            onTogglePump: isOnline ? () => _handlePumpToggle(sensorProvider) : null,
            onToggleMode: isOnline ? () => _handlePumpModeToggle(sensorProvider) : null,
          ),
        ),
        const SizedBox(height: 16),
        
        // 蜂鸣器控制
        _buildControlCardWithStatus(
          isOnline: isOnline,
          child: BuzzerControlCard(
            isBuzzerOn: sensorProvider.isBuzzerOn,
            isAutoMode: sensorProvider.isBuzzerAutoMode,
            isLoading: sensorProvider.isSendingCommand,
            onToggleBuzzer: isOnline ? () => _handleBuzzerToggle(sensorProvider) : null,
            onToggleMode: isOnline ? () => _handleBuzzerModeToggle(sensorProvider) : null,
          ),
        ),
      ],
    );
  }

  /// 为控制卡片添加离线状态
  Widget _buildControlCardWithStatus({
    required bool isOnline,
    required Widget child,
  }) {
    if (isOnline) return child;
    
    return Stack(
      children: [
        Opacity(opacity: 0.6, child: child),
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off, size: 12, color: Colors.white),
                SizedBox(width: 4),
                Text(
                  '离线',
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 构建设备信息卡片
  Widget _buildDeviceInfoCard(SensorDataProvider sensorProvider) {
    final data = sensorProvider.latestData;
    final hasData = sensorProvider.hasData;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  '设备信息',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            const Divider(),
            _buildInfoRow(
              '设备ID',
              hasData ? data!.deviceId : '--',
            ),
            _buildInfoRow(
              '更新时间',
              hasData ? _formatDateTime(data!.timestamp) : '--',
            ),
            _buildInfoRow(
              '连接状态',
              sensorProvider.isConnected ? '在线' : '离线',
              valueColor: sensorProvider.isConnected ? Colors.green : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
  
  // ==================== 控制处理方法 ====================
  
  Future<void> _handleFanToggle(SensorDataProvider provider) async {
    final success = await provider.controlFan(!provider.isFanOn);
    _showResultSnackBar(success, provider);
  }
  
  Future<void> _handleFanModeToggle(SensorDataProvider provider) async {
    final newMode = !provider.isFanAutoMode;
    final success = await provider.setFanMode(newMode);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('风扇已切换到${newMode ? "自动" : "手动"}模式'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      _showResultSnackBar(success, provider);
    }
  }
  
  Future<void> _handlePumpToggle(SensorDataProvider provider) async {
    final success = await provider.controlPump(!provider.isPumpOn);
    _showResultSnackBar(success, provider);
  }
  
  Future<void> _handlePumpModeToggle(SensorDataProvider provider) async {
    final newMode = !provider.isPumpAutoMode;
    final success = await provider.setPumpMode(newMode);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('喷水装置已切换到${newMode ? "自动" : "手动"}模式'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      _showResultSnackBar(success, provider);
    }
  }
  
  Future<void> _handleBuzzerToggle(SensorDataProvider provider) async {
    final success = await provider.controlBuzzer(!provider.isBuzzerOn);
    _showResultSnackBar(success, provider);
  }
  
  Future<void> _handleBuzzerModeToggle(SensorDataProvider provider) async {
    final newMode = !provider.isBuzzerAutoMode;
    final success = await provider.setBuzzerMode(newMode);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('警报器已切换到${newMode ? "自动" : "手动"}模式'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      _showResultSnackBar(success, provider);
    }
  }
  
  void _showResultSnackBar(bool success, SensorDataProvider provider) {
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? '操作失败'),
          backgroundColor: Colors.red,
        ),
      );
      provider.clearError();
    }
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${_pad(dateTime.month)}-${_pad(dateTime.day)} '
           '${_pad(dateTime.hour)}:${_pad(dateTime.minute)}:${_pad(dateTime.second)}';
  }

  String _pad(int value) => value.toString().padLeft(2, '0');
}
