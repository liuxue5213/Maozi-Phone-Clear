import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/format_utils.dart';

/// 存储分析页面 - 饼图可视化展示存储占用
class StorageAnalysisScreen extends StatefulWidget {
  const StorageAnalysisScreen({super.key});

  @override
  State<StorageAnalysisScreen> createState() => _StorageAnalysisScreenState();
}

class _StorageAnalysisScreenState extends State<StorageAnalysisScreen> {
  int _touchedIndex = -1;

  // 真实存储数据
  List<_StorageCategory> _categories = [];
  bool _isLoading = true;
  int _totalBytes = 0;
  int _usedBytes = 0;

  @override
  void initState() {
    super.initState();
    _loadStorageData();
  }

  Future<void> _loadStorageData() async {
    setState(() => _isLoading = true);

    try {
      // 获取设备存储信息
      final stat = await Directory('/storage/emulated/0').stat();
      final totalBytes = await _getTotalStorage();
      final freeBytes = await _getFreeStorage();
      final usedBytes = totalBytes - freeBytes;

      // 扫描各类型文件占用
      final categories = await _scanStorageCategories();

      if (!mounted) return;
      setState(() {
        _categories = categories;
        _totalBytes = totalBytes;
        _usedBytes = usedBytes;
        _isLoading = false;
      });
    } catch (e) {
      // 使用估算值
      if (!mounted) return;
      setState(() {
        _categories = _getDefaultCategories();
        _totalBytes = 64 * 1024 * 1024 * 1024; // 64GB
        _usedBytes = 32 * 1024 * 1024 * 1024; // 32GB
        _isLoading = false;
      });
    }
  }

  Future<int> _getTotalStorage() async {
    try {
      final result = await Process.run('stat', ['-f', '-c', '%b', '/storage/emulated/0']);
      final blocks = int.tryParse(result.stdout.toString().trim()) ?? 0;
      return blocks * 4096; // 每块4KB
    } catch (e) {
      return 64 * 1024 * 1024 * 1024; // 默认64GB
    }
  }

  Future<int> _getFreeStorage() async {
    try {
      final result = await Process.run('stat', ['-f', '-c', '%f', '/storage/emulated/0']);
      final freeBlocks = int.tryParse(result.stdout.toString().trim()) ?? 0;
      return freeBlocks * 4096;
    } catch (e) {
      return 32 * 1024 * 1024 * 1024; // 默认32GB
    }
  }

  Future<List<_StorageCategory>> _scanStorageCategories() async {
    final Map<String, int> categorySizes = {
      '应用': 0,
      '图片': 0,
      '视频': 0,
      '音频': 0,
      '文档': 0,
      '缓存': 0,
      '系统': 0,
      '其他': 0,
    };

    final dirs = {
      '图片': ['/storage/emulated/0/DCIM', '/storage/emulated/0/Pictures'],
      '视频': ['/storage/emulated/0/Movies', '/storage/emulated/0/DCIM'],
      '音频': ['/storage/emulated/0/Music'],
      '文档': ['/storage/emulated/0/Documents', '/storage/emulated/0/Download'],
    };

    for (final entry in dirs.entries) {
      for (final dirPath in entry.value) {
        final dir = Directory(dirPath);
        if (await dir.exists()) {
          await for (final entity in dir.list(recursive: true, followLinks: false)) {
            if (entity is File) {
              try {
                final stat = await entity.stat();
                categorySizes[entry.key] = (categorySizes[entry.key] ?? 0) + stat.size;
              } catch (e) {}
            }
          }
        }
      }
    }

    return [
      _StorageCategory('应用', categorySizes['应用']!.toDouble() / (1024 * 1024), const Color(0xFF2196F3)),
      _StorageCategory('图片', categorySizes['图片']!.toDouble() / (1024 * 1024), const Color(0xFF4CAF50)),
      _StorageCategory('视频', categorySizes['视频']!.toDouble() / (1024 * 1024), const Color(0xFFFF9800)),
      _StorageCategory('音频', categorySizes['音频']!.toDouble() / (1024 * 1024), const Color(0xFF9C27B0)),
      _StorageCategory('文档', categorySizes['文档']!.toDouble() / (1024 * 1024), const Color(0xFF607D8B)),
      _StorageCategory('缓存', categorySizes['缓存']!.toDouble() / (1024 * 1024), const Color(0xFFE91E63)),
      _StorageCategory('系统', categorySizes['系统']!.toDouble() / (1024 * 1024), const Color(0xFF795548)),
      _StorageCategory('其他', categorySizes['其他']!.toDouble() / (1024 * 1024), const Color(0xFF9E9E9E)),
    ];
  }

  List<_StorageCategory> _getDefaultCategories() {
    return [
      _StorageCategory('应用', 12.5 * 1024, const Color(0xFF2196F3)),
      _StorageCategory('图片', 8.3 * 1024, const Color(0xFF4CAF50)),
      _StorageCategory('视频', 15.7 * 1024, const Color(0xFFFF9800)),
      _StorageCategory('音频', 2.1 * 1024, const Color(0xFF9C27B0)),
      _StorageCategory('文档', 3.4 * 1024, const Color(0xFF607D8B)),
      _StorageCategory('缓存', 5.8 * 1024, const Color(0xFFE91E63)),
      _StorageCategory('系统', 10.0 * 1024, const Color(0xFF795548)),
      _StorageCategory('其他', 4.2 * 1024, const Color(0xFF9E9E9E)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F7FA),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final total = _categories.fold<double>(0, (sum, c) => sum + c.sizeMB);
    final used = _usedBytes / (1024 * 1024); // 转换为 MB

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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadStorageData,
          ),
        ],
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

  Widget _buildTotalCard(double usedMB, double totalMB) {
    final usedPercent = totalMB > 0 ? (usedMB / totalMB * 100).toStringAsFixed(1) : '0.0';
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
            '${FormatUtils.formatBytes((usedMB * 1024 * 1024).toInt())} / ${FormatUtils.formatBytes((totalMB * 1024 * 1024).toInt())}',
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
              value: totalMB > 0 ? usedMB / totalMB : 0,
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
    final total = _categories.fold<double>(0, (sum, c) => sum + c.sizeMB);
    if (total == 0) return [];

    return List.generate(_categories.length, (i) {
      final isTouched = i == _touchedIndex;
      final fontSize = isTouched ? 16.0 : 12.0;
      final radius = isTouched ? 65.0 : 55.0;
      final category = _categories[i];
      final percent = category.sizeMB / total * 100;

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
          ...List.generate(_categories.length, (i) {
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
                    FormatUtils.formatBytes((category.sizeMB * 1024 * 1024).toInt()),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                if (i < _categories.length - 1)
                  Divider(height: 1, indent: 44, endIndent: 16, color: Colors.grey[100]),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _StorageCategory {
  final String name;
  final double sizeMB;
  final Color color;

  _StorageCategory(this.name, this.sizeMB, this.color);
}
