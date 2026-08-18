import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/clean_provider.dart';

/// 扫描页面 - 显示扫描动画和进度
class ScanScreen extends StatelessWidget {
  const ScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CleanProvider>();

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 扫描动画圆圈
          SizedBox(
            width: 200,
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 外圈旋转动画
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(seconds: 2),
                  builder: (context, value, child) {
                    return Transform.rotate(
                      angle: value * 6.28,
                      child: child,
                    );
                  },
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF2196F3).withOpacity(0.3),
                        width: 3,
                      ),
                      gradient: SweepGradient(
                        colors: [
                          const Color(0xFF2196F3).withOpacity(0.0),
                          const Color(0xFF2196F3).withOpacity(0.5),
                          const Color(0xFF2196F3),
                          const Color(0xFF2196F3).withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ),
                // 中心图标
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF2196F3).withOpacity(0.1),
                    border: Border.all(
                      color: const Color(0xFF2196F3),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.cleaning_services_rounded,
                    size: 50,
                    color: Color(0xFF2196F3),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // 扫描状态文字
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
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2196F3)),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // 百分比
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
}
