import 'package:flutter/material.dart';
import '../services/social_scanner.dart';

/// 社交应用专清页面
class SocialCleanupScreen extends StatefulWidget {
  const SocialCleanupScreen({super.key});

  @override
  State<SocialCleanupScreen> createState() => _SocialCleanupScreenState();
}

class _SocialCleanupScreenState extends State<SocialCleanupScreen> {
  final SocialScanner _scanner = SocialScanner();
  Map<SocialApp, Map<SocialCacheType, List<SocialCacheItem>>> _data = {};
  bool _isScanning = false;
  bool _isCleaning = false;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _data = {};
    });

    final result = await _scanner.scanSocialApps();

    setState(() {
      _data = result;
      _isScanning = false;
    });
  }

  Future<void> _cleanSelected() async {
    final selected = _data.values
        .expand((types) => types.values)
        .expand((items) => items)
        .where((item) => item.isSelected)
        .toList();

    if (selected.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认清理'),
        content: Text(
          '将清理 ${selected.length} 个文件\n'
          '释放空间: ${_formatBytes(selected.fold<int>(0, (sum, i) => sum + i.sizeBytes))}\n\n'
          '注意：清理后聊天中的图片/视频可能无法再次查看',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE91E63)),
            child: const Text('确认清理', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isCleaning = true;
    });

    final freed = await _scanner.deleteSocialCache(selected);
    for (int i = 0; i < selected.length; i++) {
      await Future.delayed(const Duration(milliseconds: 20));
    }

    // 重新扫描
    await _startScan();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已清理 ${_formatBytes(freed)}'),
          backgroundColor: const Color(0xFF4CAF50),
        ),
      );
    }

    setState(() {
      _isCleaning = false;
    });
  }

  int get _totalCleanableBytes {
    return _data.values
        .expand((types) => types.values)
        .expand((items) => items)
        .where((item) => item.isSelected)
        .fold<int>(0, (sum, item) => sum + item.sizeBytes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          '社交应用专清',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF2196F3),
        elevation: 0,
        actions: [
          if (!_isScanning && !_isCleaning)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _startScan,
            ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomBar(),
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
              '正在扫描社交应用缓存...',
              style: TextStyle(fontSize: 16, color: Color(0xFF333333)),
            ),
            const SizedBox(height: 8),
            Text(
              '微信 / QQ / 抖音',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    if (_data.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, size: 80, color: Color(0xFF4CAF50)),
            const SizedBox(height: 16),
            const Text(
              '社交应用很干净',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              '没有发现可清理的缓存',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 汇总卡片
        _buildSummaryCard(),
        const SizedBox(height: 16),

        // 各社交应用卡片
        ..._data.entries.map((entry) => _buildAppCard(entry.key, entry.value)),
      ],
    );
  }

  Widget _buildSummaryCard() {
    final totalFiles = _data.values
        .expand((types) => types.values)
        .expand((items) => items)
        .length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFFE91E63), const Color(0xFFE91E63).withOpacity(0.8)],
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
                  '社交应用缓存',
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
                  '$totalFiles 个文件可清理',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          const Icon(Icons.chat, size: 60, color: Colors.white24),
        ],
      ),
    );
  }

  Widget _buildAppCard(
    SocialApp app,
    Map<SocialCacheType, List<SocialCacheItem>> types,
  ) {
    final allItems = types.values.expand((items) => items).toList();
    final totalSize = allItems.fold<int>(0, (sum, i) => sum + i.sizeBytes);
    final selectedSize = allItems
        .where((i) => i.isSelected)
        .fold<int>(0, (sum, i) => sum + i.sizeBytes);

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
          leading: Text(app.icon, style: const TextStyle(fontSize: 28)),
          title: Text(
            app.displayName,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            '${allItems.length} 项 • 选中 ${_formatBytes(selectedSize)}',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
          trailing: SizedBox(
            width: 60,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatBytes(totalSize),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFE91E63),
                  ),
                ),
                const SizedBox(height: 2),
                GestureDetector(
                  onTap: () {
                    final allSelected = allItems.every((i) => i.isSelected);
                    setState(() {
                      for (final item in allItems) {
                        item.isSelected = !allSelected;
                      }
                    });
                  },
                  child: Icon(
                    allItems.every((i) => i.isSelected)
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: const Color(0xFF2196F3),
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          children: types.entries.map((typeEntry) {
            return _buildTypeSection(typeEntry.key, typeEntry.value);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTypeSection(SocialCacheType type, List<SocialCacheItem> items) {
    final totalSize = items.fold<int>(0, (sum, i) => sum + i.sizeBytes);
    final selectedCount = items.where((i) => i.isSelected).length;

    return Column(
      children: [
        // 类型头部
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: Colors.grey[50],
          child: Row(
            children: [
              Text(type.icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                type.displayName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$selectedCount/${items.length}',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
              const Spacer(),
              Text(
                _formatBytes(totalSize),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFE91E63),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  final allSelected = items.every((i) => i.isSelected);
                  setState(() {
                    for (final item in items) {
                      item.isSelected = !allSelected;
                    }
                  });
                },
                child: Icon(
                  items.every((i) => i.isSelected)
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: const Color(0xFF2196F3),
                  size: 20,
                ),
              ),
            ],
          ),
        ),

        // 文件列表（最多显示5个）
        ...items.take(5).map((item) => ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          leading: GestureDetector(
            onTap: () => setState(() => item.isSelected = !item.isSelected),
            child: Icon(
              item.isSelected
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              color: item.isSelected ? const Color(0xFF2196F3) : Colors.grey[400],
              size: 20,
            ),
          ),
          title: Text(
            item.name,
            style: const TextStyle(fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Text(
            item.formattedSize,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        )),

        if (items.length > 5)
          Padding(
            padding: const EdgeInsets.only(left: 24, bottom: 8),
            child: Text(
              '...还有 ${items.length - 5} 个文件',
              style: TextStyle(fontSize: 11, color: Colors.grey[400]),
            ),
          ),
      ],
    );
  }

  Widget? _buildBottomBar() {
    if (_isScanning || _data.isEmpty) return null;

    final selectedCount = _data.values
        .expand((types) => types.values)
        .expand((items) => items)
        .where((i) => i.isSelected)
        .length;

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            '已选 $selectedCount 个文件',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const Spacer(),
          Text(
            _formatBytes(_totalCleanableBytes),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFFE91E63),
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: selectedCount > 0 && !_isCleaning ? _cleanSelected : null,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE91E63),
              disabledBackgroundColor: Colors.grey[300],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: _isCleaning
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('一键清理', style: TextStyle(color: Colors.white)),
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
