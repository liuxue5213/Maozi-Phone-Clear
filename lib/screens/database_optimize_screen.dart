import 'package:flutter/material.dart';
import '../services/database_optimize_service.dart';

/// 数据库优化页面
class DatabaseOptimizeScreen extends StatefulWidget {
  const DatabaseOptimizeScreen({super.key});

  @override
  State<DatabaseOptimizeScreen> createState() => _DatabaseOptimizeScreenState();
}

class _DatabaseOptimizeScreenState extends State<DatabaseOptimizeScreen> {
  final DatabaseOptimizeService _service = DatabaseOptimizeService();
  List<DatabaseItem> _items = [];
  bool _isLoading = true;
  bool _isOptimizing = false;
  int? _optimizedBytes;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _optimizedBytes = null;
    });

    final items = await _service.scanDatabases();
    setState(() {
      _items = items;
      _isLoading = false;
    });
  }

  Future<void> _optimize() async {
    final selected = _items.where((i) => i.isSelected).toList();
    if (selected.isEmpty) return;

    setState(() => _isOptimizing = true);
    final freed = await _service.optimize(selected);

    setState(() {
      _optimizedBytes = freed;
      _isOptimizing = false;
      // 重置已优化的项
      for (final item in selected) {
        item.isSelected = false;
      }
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('优化完成！释放 ${_formatBytes(freed)}'),
          backgroundColor: const Color(0xFF9C27B0),
        ),
      );
    }
  }

  int get _totalWastedBytes {
    return _items
        .where((i) => i.isSelected)
        .fold<int>(0, (sum, i) => sum + i.wastedBytes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          '数据库优化',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF9C27B0),
        elevation: 0,
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _loadData,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 汇总卡片
                _buildSummaryCard(),

                // 优化结果
                if (_optimizedBytes != null) _buildResultCard(),

                // 列表标题
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Text(
                        '可优化的数据库',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          final allSelected = _items.every((i) => i.isSelected);
                          setState(() {
                            for (final i in _items) {
                              i.isSelected = !allSelected;
                            }
                          });
                        },
                        child: Row(
                          children: [
                            Icon(
                              _items.every((i) => i.isSelected)
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: const Color(0xFF9C27B0),
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            const Text('全选', style: TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // 数据库列表
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      return _buildDatabaseCard(_items[index]);
                    },
                  ),
                ),
              ],
            ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildSummaryCard() {
    final totalWasted = _items.fold<int>(0, (sum, i) => sum + i.wastedBytes);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF9C27B0), const Color(0xFF9C27B0).withOpacity(0.7)],
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
                  '数据库碎片',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatBytes(totalWasted),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_items.length} 个数据库可优化',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          const Icon(Icons.storage, size: 60, color: Colors.white24),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF50).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '优化完成！',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4CAF50),
                  ),
                ),
                Text(
                  '数据库已执行 VACUUM 优化，释放 ${_formatBytes(_optimizedBytes!)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatabaseCard(DatabaseItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: ListTile(
        leading: GestureDetector(
          onTap: () => setState(() => item.isSelected = !item.isSelected),
          child: Icon(
            item.isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
            color: item.isSelected ? const Color(0xFF9C27B0) : Colors.grey[400],
            size: 22,
          ),
        ),
        title: Text(item.appName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.issue, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            const SizedBox(height: 2),
            Row(
              children: [
                Text(
                  item.formattedOriginalSize,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const Icon(Icons.arrow_forward, size: 14, color: Color(0xFF4CAF50)),
                const SizedBox(width: 4),
                Text(
                  item.formattedOptimizedSize,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4CAF50)),
                ),
              ],
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF9C27B0).withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '-${item.formattedWastedSize}',
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF9C27B0),
              fontWeight: FontWeight.w600,
            ),
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
            '可释放 ${_formatBytes(_totalWastedBytes)}',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const Spacer(),
          FilledButton(
            onPressed: selectedCount > 0 && !_isOptimizing ? _optimize : null,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF9C27B0),
              disabledBackgroundColor: Colors.grey[300],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: const Text('一键优化', style: TextStyle(color: Colors.white)),
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
