import 'package:flutter/material.dart';
import '../services/privacy_service.dart';

/// 隐私清理页面
class PrivacyCleanupScreen extends StatefulWidget {
  const PrivacyCleanupScreen({super.key});

  @override
  State<PrivacyCleanupScreen> createState() => _PrivacyCleanupScreenState();
}

class _PrivacyCleanupScreenState extends State<PrivacyCleanupScreen> {
  final PrivacyService _service = PrivacyService();
  List<PrivacyItem> _items = [];
  bool _isLoading = true;
  bool _isCleaning = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final items = await _service.scanPrivacy();
    setState(() {
      _items = items;
      _isLoading = false;
    });
  }

  Future<void> _cleanSelected() async {
    final selected = _items.where((i) => i.isSelected).toList();
    if (selected.isEmpty) return;

    final totalBytes = selected.fold<int>(0, (sum, i) => sum + i.sizeBytes);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.privacy_tip, color: Color(0xFF9C27B0)),
            SizedBox(width: 8),
            Text('隐私清理'),
          ],
        ),
        content: Text(
          '将清理以下 ${selected.length} 项隐私数据:\n'
          '• 释放空间: ${_formatBytes(totalBytes)}\n'
          '• 清理后无法恢复\n\n'
          '确定要继续吗？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF9C27B0)),
            child: const Text('清理', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isCleaning = true);
    final freed = await _service.cleanPrivacy(selected);
    setState(() => _isCleaning = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已清理隐私数据 ${_formatBytes(freed)}'),
          backgroundColor: const Color(0xFF9C27B0),
        ),
      );
    }
    _loadData();
  }

  int get _totalCleanableBytes {
    return _items
        .where((i) => i.isSelected)
        .fold<int>(0, (sum, i) => sum + i.sizeBytes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          '隐私清理',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF9C27B0),
        elevation: 0,
        actions: [
          if (!_isLoading && !_isCleaning)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _loadData,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBody() {
    final availableItems = _items.where((i) => i.count > 0).toList();

    if (availableItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shield_outlined, size: 80, color: Color(0xFF4CAF50)),
            const SizedBox(height: 16),
            const Text('隐私很安全', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('没有发现需要清理的隐私数据', style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 安全提示
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF9C27B0).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Color(0xFF9C27B0)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '清理隐私数据可以保护您的个人隐私，防止敏感信息泄露',
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 隐私项列表
        ...availableItems.map((item) => _buildPrivacyCard(item)),
      ],
    );
  }

  Widget _buildPrivacyCard(PrivacyItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: item.isSelected
              ? const Color(0xFF9C27B0).withOpacity(0.5)
              : Colors.grey[200]!,
        ),
      ),
      child: InkWell(
        onTap: () => setState(() => item.isSelected = !item.isSelected),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 图标
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF9C27B0).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    item.type.icon,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // 信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.type.displayName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.type.description,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${item.count} 条记录',
                          style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          item.formattedSize,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF9C27B0),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // 复选框
              Icon(
                item.isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: item.isSelected
                    ? const Color(0xFF9C27B0)
                    : Colors.grey[400],
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget? _buildBottomBar() {
    if (_isLoading || _items.isEmpty) return null;

    final selectedCount = _items.where((i) => i.isSelected).length;
    if (selectedCount == 0) return null;

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
            '已选 $selectedCount 项',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const Spacer(),
          Text(
            _formatBytes(_totalCleanableBytes),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF9C27B0),
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: selectedCount > 0 && !_isCleaning ? _cleanSelected : null,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF9C27B0),
              disabledBackgroundColor: Colors.grey[300],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: const Text('清理隐私', style: TextStyle(color: Colors.white)),
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
