import 'package:flutter/material.dart';
import '../models/image_file.dart';
import '../services/image_scanner.dart';

/// 图片清理页面
class ImageCleanupScreen extends StatefulWidget {
  const ImageCleanupScreen({super.key});

  @override
  State<ImageCleanupScreen> createState() => _ImageCleanupScreenState();
}

class _ImageCleanupScreenState extends State<ImageCleanupScreen> {
  final ImageScanner _scanner = ImageScanner();
  Map<ImageCategory, List<ImageFileItem>> _images = {};
  List<SimilarImageGroup> _similarGroups = [];
  bool _isScanning = false;
  int _selectedTab = 0; // 0=分类视图, 1=相似图片

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _images = {};
      _similarGroups = [];
    });

    final images = await _scanner.scanImages();
    final groups = await _scanner.scanSimilarImages();

    setState(() {
      _images = images;
      _similarGroups = groups;
      _isScanning = false;
    });
  }

  int get _totalCleanableBytes {
    int total = 0;
    _images.forEach((category, items) {
      if (category == ImageCategory.burst) {
        // 连拍：保留最佳一张，其余可清理
        final burstGroups = <String, List<ImageFileItem>>{};
        for (final img in items) {
          final key = img.name.replaceAll(RegExp(r'_\d+\.jpg.*'), '');
          burstGroups.putIfAbsent(key, () => []).add(img);
        }
        for (final group in burstGroups.values) {
          group.sort((a, b) => (b.width * b.height).compareTo(a.width * a.height));
          for (int i = 1; i < group.length; i++) {
            total += group[i].sizeBytes;
          }
        }
      } else {
        total += items.fold<int>(0, (sum, img) => sum + img.sizeBytes);
      }
    });
    total += _similarGroups.fold<int>(0, (sum, g) => sum + g.cleanableImages.fold<int>(0, (s, img) => s + img.sizeBytes));
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          '图片清理',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF2196F3),
        elevation: 0,
        actions: [
          if (!_isScanning)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _startScan,
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: const Color(0xFF2196F3),
            child: Row(
              children: [
                _buildTabButton(0, '📸 分类清理'),
                _buildTabButton(1, '🖼️ 相似图片'),
              ],
            ),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildTabButton(int index, String label) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white60,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isScanning) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Color(0xFF2196F3),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '正在扫描图片...',
              style: TextStyle(fontSize: 16, color: Color(0xFF333333)),
            ),
            const SizedBox(height: 8),
            Text(
              '检测截图、连拍、相似图片',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return _selectedTab == 0 ? _buildCategoryView() : _buildSimilarView();
  }

  /// 分类视图
  Widget _buildCategoryView() {
    if (_images.isEmpty) {
      return _buildEmptyView();
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 汇总卡片
        _buildSummaryCard(),
        const SizedBox(height: 16),

        // 分类卡片
        ..._images.entries.map((entry) => _buildCategoryCard(entry.key, entry.value)),
      ],
    );
  }

  Widget _buildSummaryCard() {
    int totalFiles = _images.values.fold(0, (sum, list) => sum + list.length);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF4CAF50), const Color(0xFF4CAF50).withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '可清理图片',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatBytes(_totalCleanableBytes),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$totalFiles 张图片可优化',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          const Icon(Icons.image, size: 60, color: Colors.white24),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(ImageCategory category, List<ImageFileItem> items) {
    final totalSize = items.fold<int>(0, (sum, img) => sum + img.sizeBytes);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Text(category.icon, style: const TextStyle(fontSize: 24)),
          title: Text(
            category.displayName,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            '${items.length} 张 • ${_formatBytes(totalSize)}',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
          children: [
            ...items.map((img) => ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              title: Text(
                img.name,
                style: const TextStyle(fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '${img.resolution} • ${img.formattedDate}',
                style: TextStyle(fontSize: 11, color: Colors.grey[400]),
              ),
              trailing: Text(
                img.formattedSize,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFE91E63),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  /// 相似图片视图
  Widget _buildSimilarView() {
    if (_similarGroups.isEmpty) {
      return _buildEmptyView();
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 说明文字
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Color(0xFF2196F3)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '发现 ${_similarGroups.length} 组相似图片，系统将自动保留最高清版本',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 相似图片组
        ..._similarGroups.map((group) => _buildSimilarGroupCard(group)),
      ],
    );
  }

  Widget _buildSimilarGroupCard(SimilarImageGroup group) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.photo_library, size: 18, color: Color(0xFF2196F3)),
                const SizedBox(width: 8),
                Text(
                  '${group.images.length} 张相似图片',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  '可释放 ${group.formattedTotalSize}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFE91E63),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...group.images.map((img) {
              final isBest = img.path == group.bestImage.path;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isBest
                            ? const Color(0xFF4CAF50).withOpacity(0.1)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Icon(
                          isBest ? Icons.star : Icons.image,
                          size: 20,
                          color: isBest ? const Color(0xFF4CAF50) : Colors.grey[400],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            img.name,
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${img.resolution} • ${img.formattedSize}',
                            style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                          ),
                        ],
                      ),
                    ),
                    if (isBest)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '最佳',
                          style: TextStyle(fontSize: 10, color: Colors.white),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline, size: 80, color: Color(0xFF4CAF50)),
          const SizedBox(height: 16),
          const Text(
            '图片库很干净',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            '没有发现可清理的图片',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
