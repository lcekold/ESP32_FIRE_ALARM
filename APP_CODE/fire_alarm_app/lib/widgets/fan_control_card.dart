import 'package:flutter/material.dart';

/// 风扇控制卡片组件
/// 
/// 显示风扇状态，提供模式切换和手动控制功能
class FanControlCard extends StatelessWidget {
  final bool isFanOn;
  final bool isAutoMode;
  final bool isLoading;
  final VoidCallback? onToggleFan;
  final VoidCallback? onToggleMode;

  const FanControlCard({
    super.key,
    required this.isFanOn,
    required this.isAutoMode,
    this.isLoading = false,
    this.onToggleFan,
    this.onToggleMode,
  });

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
                  Icons.air,
                  color: isFanOn ? Colors.blue : Colors.grey,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  '排烟风扇',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                // 风扇状态指示
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: isFanOn ? Colors.green.shade100 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isFanOn ? '运行中' : '已关闭',
                    style: TextStyle(
                      color: isFanOn ? Colors.green.shade700 : Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
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
                          ? '自动模式：根据温度和烟雾传感器自动控制风扇'
                          : '手动模式：可通过下方按钮手动控制风扇',
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
            
            // 手动控制按钮（仅在手动模式下可用）
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: (!isAutoMode && !isLoading && !isFanOn) 
                        ? onToggleFan 
                        : null,
                    icon: isLoading 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.power_settings_new),
                    label: const Text('开启风扇'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: (!isAutoMode && !isLoading && isFanOn) 
                        ? onToggleFan 
                        : null,
                    icon: isLoading 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.power_off),
                    label: const Text('关闭风扇'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                    ),
                  ),
                ),
              ],
            ),
            
            // 自动模式下的提示
            if (isAutoMode) ...[
              const SizedBox(height: 8),
              Text(
                '* 自动模式下无法手动控制风扇',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
