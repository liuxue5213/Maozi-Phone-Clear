import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/clean_provider.dart';

/// 清理页面 - 清理中显示进度，完成后显示结果
class CleanScreen extends StatelessWidget {
  const CleanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CleanProvider>();

    // 清理中
    if (provider.state == AppState.cleaning) {
      return _buildCleaningView(provider);
    }

    // 清理完成
    return _buildResultView(context, provider);
  }

  /// 清理中视图
  Widget _buildCleaningView(CleanProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 清理动画
          SizedBox(
            width: 160,
            height: 160,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(seconds: 3),
              builder: (context, value, child) {
                return Transform.rotate(
                  angle: value * 6.28 * 2,
                  child: child,
                );
              },
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  border: Border.all(
                    color: const Color(0xFF4CAF50),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.auto_delete_rounded,
                  size: 50,
                  color: Color(0xFF4CAF50),
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),

          Text(
            provider.statusMessage,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),

          const SizedBox(height: 24),

          // 进度条
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 60),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: provider.progress,
                minHeight: 8,
                backgroundColor: const Color(0xFFE0E0E0),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
              ),
            ),
          ),

          const SizedBox(height: 12),

          Text(
            '${(provider.progress * 100).toInt()}%',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  /// 清理完成视图
  Widget _buildResultView(BuildContext context, CleanProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 成功图标
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF4CAF50).withOpacity(0.1),
              border: Border.all(
                color: const Color(0xFF4CAF50),
                width: 3,
              ),
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 60,
              color: Color(0xFF4CAF50),
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            '清理完成！',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),

          const SizedBox(height: 16),

          // 清理大小展示
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text(
                  '已清理',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  provider.formattedCleanedSize,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4CAF50),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 48),

          // 返回首页按钮
          FilledButton(
            onPressed: provider.reset,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: const Text(
              '返回首页',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
