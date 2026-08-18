import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// 存储分析页面 - 饼图可视化展示存储占用
class StorageAnalysisScreen extends StatefulWidget {
  const StorageAnalysisScreen({super.key});

  @override
  State<StorageAnalysisScreen> createState() => _StorageAnalysisScreenState();
}

class _StorageAnalysisScreenState extends State<StorageAnalysisScreen> {
  int _touchedIndex = -1;

  final List<_StorageCategory> _categories = [
    _StorageCategory('应用', 12.5 * 1024, const Color(0xFF2196F3)),
    _StorageCategory('图片', 8.3 * 1024, const Color(0xFF4CAF50)),
    _StorageCategory('视频', 15.7 * 1024, const Color(0xFFFF9800)),
    _StorageCategory('音频', 2.1 * 1024, const Color(0xFF9C27B0)),
    _StorageCategory('文档', 3.4 * 1024, const Color(0xFF607D8B)),
    _StorageCategory('缓存', 5.8 * 1024, const Color(0xFFE91E63)),
    _StorageCategory('系统', 10.0 * 1024, const Color(0xFF795548)),
    _StorageCategory('其他', 4.2 * 1024, const Color(0xFF9E9E9E)),
    _StorageCategory('可用', 25.0 * 1024, const Color(0xFFE0E0E0)),
  ];

  @override
  Widget build(BuildContext context) {
    final total = _categories.fold<double>(0, (sum, c) => sum + c.sizeMB * 1024);
    final used = total - _categories.last.sizeMB * 1024;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          '存储分析',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF2196F3),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 总存储信息卡片
            _buildTotalCard(used, total),
            const SizedBox(height: 20),

            // 饼图卡片
            _buildPieChartCard(),
            const SizedBox(height: 20),

            // 分类详情列表
            _buildCategoryList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalCard(double used, double total) {
    final usedPercent = (used / total * 100).toStringAsFixed(1);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF2196F3), const Color(0xFF2196F3).withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            '总存储空间',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            '${_formatSize(used)} / ${_formatSize(total)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // 存储进度条
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: used / total,
              minHeight: 12,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '已用 $usedPercent%',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChartCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            '存储分布',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        _touchedIndex = -1;
                        return;
                      }
                      _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                borderData: FlBorderData(show: false),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: _generateSections(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _generateSections() {
    final total = _categories.fold<double>(0, (sum, c) => sum + c.sizeMB * 1024);

    return List.generate(_categories.length, (i) {
      final isTouched = i == _touchedIndex;
      final fontSize = isTouched ? 16.0 : 12.0;
      final radius = isTouched ? 65.0 : 55.0;
      final category = _categories[i];
      final percent = category.sizeMB * 1024 / total * 100;

      return PieChartSectionData(
        color: category.color,
        value: category.sizeMB,
        title: percent > 5 ? '${percent.toStringAsFixed(1)}%' : '',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    });
  }

  Widget _buildCategoryList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '分类详情',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
            ),
          ),
          ...List.generate(_categories.length - 1, (i) {
            final category = _categories[i];
            return Column(
              children: [
                ListTile(
                  leading: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: category.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  title: Text(
                    category.name,
                    style: const TextStyle(fontSize: 14),
                  ),
                  trailing: Text(
                    _formatSize(category.sizeMB * 1024),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                if (i < _categories.length - 2)
                  Divider(height: 1, indent: 44, endIndent: 16, color: Colors.grey[100]),
              ],
            );
          }),
        ],
      ),
    );
  }

  String _formatSize(double bytes) {
    if (bytes < 1024) return '${bytes.toInt()} B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

class _StorageCategory {
  final String name;
  final double sizeMB;
  final Color color;

  _StorageCategory(this.name, this.sizeMB, this.color);
}
