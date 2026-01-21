import 'package:flutter/material.dart';

/// 水泵控制卡片组件
/// 
/// 显示水泵状态，提供模式切换和手动控制功能
/// 包含冷却状态显示
class PumpControlCard extends StatelessWidget {
  final bool isPumpOn;
  final bool isPumpCooldown;
  final bool isAutoMode;
  final bool isLoading;
  final VoidCallback? onTogglePump;
  final VoidCallback? onToggleMode;

  const PumpControlCard({
    super.key,
    required this.isPumpOn,
    required this.isPumpCooldown,
    required this.isAutoMode,
    this.isLoading = false,
    this.onTogglePump,
    this.onToggleMode,
  });

  /// 获取水泵状态文本
  String get _statusText {
    if (isPumpOn) return '喷水中';
    if (isPumpCooldown) return '冷却中';
    return '待命';
  }

  /// 获取状态颜色
  Color get _statusColor {
    if (isPumpOn) return Colors.blue;
    if (isPumpCooldown) return Colors.orange;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题行
            Row(
              children: [
                Icon(
                  Icons.water_drop,
                  color: isPumpOn ? Colors.blue : Colors.grey,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  '喷水装置',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                // 状态指示
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isPumpOn || isPumpCooldown)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(_statusColor),
                            ),
                          ),
                        ),
                      Text(
                        _statusText,
                        style: TextStyle(
                          color: _statusColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const Divider(height: 24),
            
            // 模式切换
            Row(
              children: [
                const Text('控制模式：'),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('自动'),
                  selected: isAutoMode,
                  onSelected: isLoading ? null : (_) => onToggleMode?.call(),
                  selectedColor: Colors.blue.shade100,
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('手动'),
                  selected: !isAutoMode,
                  onSelected: isLoading ? null : (_) => onToggleMode?.call(),
                  selectedColor: Colors.orange.shade100,
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // 模式说明
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isAutoMode ? Colors.blue.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    isAutoMode ? Icons.auto_mode : Icons.touch_app,
                    size: 20,
                    color: isAutoMode ? Colors.blue.shade700 : Colors.orange.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isAutoMode 
                          ? '自动模式：检测到火灾时自动喷水灭火'
                          : '手动模式：可通过下方按钮手动控制喷水',
                      style: TextStyle(
                        fontSize: 12,
                        color: isAutoMode ? Colors.blue.shade700 : Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 手动控制按钮
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _canTurnOn ? onTogglePump : null,
                    icon: isLoading 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.water_drop),
                    label: const Text('开始喷水'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _canTurnOff ? onTogglePump : null,
                    icon: isLoading 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.stop),
                    label: const Text('停止喷水'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                    ),
                  ),
                ),
              ],
            ),
            
            // 提示信息
            const SizedBox(height: 8),
            if (isAutoMode)
              Text(
                '* 自动模式下无法手动控制喷水',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              )
            else if (isPumpCooldown)
              Text(
                '* 水泵冷却中，请等待冷却完成后再操作',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.orange.shade700,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 是否可以开启喷水
  bool get _canTurnOn => !isAutoMode && !isLoading && !isPumpOn && !isPumpCooldown;

  /// 是否可以关闭喷水
  bool get _canTurnOff => !isAutoMode && !isLoading && isPumpOn;
}
