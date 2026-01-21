import 'package:flutter/material.dart';

/// 蜂鸣器控制卡片组件
/// 
/// 显示蜂鸣器状态并提供控制功能
/// 支持自动/手动模式切换
class BuzzerControlCard extends StatelessWidget {
  final bool isBuzzerOn;
  final bool isAutoMode;
  final bool isLoading;
  final VoidCallback? onToggleBuzzer;
  final VoidCallback? onToggleMode;

  const BuzzerControlCard({
    super.key,
    required this.isBuzzerOn,
    required this.isAutoMode,
    this.isLoading = false,
    this.onToggleBuzzer,
    this.onToggleMode,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isBuzzerOn ? Colors.red : Colors.grey;
    final backgroundColor = isBuzzerOn ? Colors.red[50] : Colors.grey[100];

    return Card(
      elevation: isBuzzerOn ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isBuzzerOn
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
                    Icons.notifications_active,
                    color: cardColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '警报器',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                // 模式切换按钮
                _buildModeChip(context),
              ],
            ),
            const SizedBox(height: 16),
            // 状态显示
            Row(
              children: [
                Icon(
                  isBuzzerOn ? Icons.volume_up : Icons.volume_off,
                  color: cardColor,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Text(
                  isBuzzerOn ? '警报中' : '静音',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: cardColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 控制按钮
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isAutoMode || isLoading ? null : onToggleBuzzer,
                    icon: isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(isBuzzerOn ? Icons.volume_off : Icons.volume_up),
                    label: Text(isBuzzerOn ? '关闭警报' : '开启警报'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isBuzzerOn ? Colors.grey : Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            if (isAutoMode)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '自动模式下，警报器将在检测到火灾时自动响起',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeChip(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onToggleMode,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isAutoMode ? Colors.green[100] : Colors.orange[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isAutoMode ? Colors.green : Colors.orange,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isAutoMode ? Icons.auto_mode : Icons.touch_app,
              size: 16,
              color: isAutoMode ? Colors.green[700] : Colors.orange[700],
            ),
            const SizedBox(width: 4),
            Text(
              isAutoMode ? '自动' : '手动',
              style: TextStyle(
                color: isAutoMode ? Colors.green[700] : Colors.orange[700],
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
