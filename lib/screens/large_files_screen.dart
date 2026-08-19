import 'package:flutter/material.dart';
import '../utils/format_utils.dart';import '../models/large_file.dart';
import '../services/large_file_scanner.dart';

/// 大文件管理页面
class LargeFilesScreen extends StatefulWidget {
  const LargeFilesScreen({super.key});

  @override
  State<LargeFilesScreen> createState() => _LargeFilesScreenState();
}

class _LargeFilesScreenState extends State<LargeFilesScreen> {
  final LargeFileScanner _scanner = LargeFileScanner();
  List<LargeFileItem> _files = [];
  bool _isScanning = false;
  bool _isCleaning = false;
  int _minSize = 50; // MB
  LargeFileType? _filterType;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _files = [];
    });

    final files = await _scanner.scanLargeFiles(
      minSizeBytes: _minSize * 1024 * 1024,
    );

    if (!mounted) return;
    setState(() {
      _files = files;
      _isScanning = false;
    });
  }

  Future<void> _cleanSelected() async {
    final selected = _files.where((f) => f.isSelected).toList();
    if (selected.isEmpty) return;

    // 二次确认
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除选中的 ${selected.length} 个文件吗？\n'
            '释放空间: ${FormatUtils.formatBytes(selected.fold<int>(0, (sum, f) => sum + f.sizeBytes))}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isCleaning = true);

    final freed = await _scanner.deleteFiles(selected);

    // 从列表中移除
    setState(() {
      _files.removeWhere((f) => f.isSelected);
      _isCleaning = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已删除 ${selected.length} 个文件，释放 ${FormatUtils.formatBytes(freed)}'),
          backgroundColor: const Color(0xFF4CAF50),
        ),
      );
    }
  }

  List<LargeFileItem> get _filteredFiles {
    if (_filterType == null) return _files;
    return _files.where((f) => f.type == _filterType).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          '大文件管理',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF2196F3),
        elevation: 0,
        actions: [
          if (!_isScanning && !_isCleaning)
            PopupMenuButton<String>(
              icon: const Icon(Icons.filter_list, color: Colors.white),
              onSelected: (value) {
                setState(() {
                  if (value == 'all') {
                    _filterType = null;
                  } else {
                    _filterType = LargeFileType.values
                        .firstWhere((t) => t.name == value);
                  }
                });
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'all', child: Text('全部类型')),
                ...LargeFileType.values.map(
                  (t) => PopupMenuItem(
                    value: t.name,
                    child: Text('${t.icon} ${t.displayName}'),
                  ),
                ),
              ],
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
              '正在扫描大文件...',
              style: TextStyle(fontSize: 16, color: Color(0xFF333333)),
            ),
            const SizedBox(height: 8),
            Text(
              '扫描 > ${_minSize}MB 的文件',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    if (_filteredFiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.folder_open, size: 80, color: Color(0xFFBDBDBD)),
            const SizedBox(height: 16),
            const Text(
              '没有发现大文件',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              '所有文件都在 ${_minSize}MB 以下',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    final totalSize = _filteredFiles.fold<int>(0, (sum, f) => sum + f.sizeBytes);

    return Column(
      children: [
        // 汇总栏
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              Text(
                _filterType != null
                    ? '${_filterType!.icon} ${_filterType!.displayName}'
                    : '📁 全部类型',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${_filteredFiles.length} 个文件',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(width: 12),
              Text(
                FormatUtils.formatBytes(totalSize),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFE91E63),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // 文件列表
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _filteredFiles.length,
            itemBuilder: (context, index) {
              final file = _filteredFiles[index];
              return _buildFileCard(file);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFileCard(LargeFileItem file) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: file.isSelected
              ? const Color(0xFF2196F3).withOpacity(0.5)
              : Colors.grey[200]!,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() => file.isSelected = !file.isSelected);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // 文件类型图标
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _getTypeColor(file.type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    file.type.icon,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // 文件信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          file.formattedSize,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFE91E63),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '• ${file.formattedDate}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      file.path,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[400],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // 复选框
              Icon(
                file.isSelected
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                color: file.isSelected
                    ? const Color(0xFF2196F3)
                    : Colors.grey[400],
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(LargeFileType type) {
    switch (type) {
      case LargeFileType.video:
        return const Color(0xFFFF9800);
      case LargeFileType.audio:
        return const Color(0xFF9C27B0);
      case LargeFileType.image:
        return const Color(0xFF4CAF50);
      case LargeFileType.document:
        return const Color(0xFF607D8B);
      case LargeFileType.archive:
        return const Color(0xFF795548);
      case LargeFileType.apk:
        return const Color(0xFF2196F3);
      case LargeFileType.other:
        return const Color(0xFF9E9E9E);
    }
  }

  Widget? _buildBottomBar() {
    if (_isScanning || _filteredFiles.isEmpty) return null;

    final selectedCount = _filteredFiles.where((f) => f.isSelected).length;
    final selectedBytes = _filteredFiles
        .where((f) => f.isSelected)
        .fold<int>(0, (sum, f) => sum + f.sizeBytes);

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
          GestureDetector(
            onTap: () {
              final allSelected = _filteredFiles.every((f) => f.isSelected);
              setState(() {
                for (final f in _filteredFiles) {
                  f.isSelected = !allSelected;
                }
              });
            },
            child: Row(
              children: [
                Icon(
                  _filteredFiles.every((f) => f.isSelected)
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: const Color(0xFF2196F3),
                  size: 22,
                ),
                const SizedBox(width: 6),
                const Text('全选', style: TextStyle(fontSize: 15)),
              ],
            ),
          ),
          const Spacer(),
          Text(
            '已选 ${FormatUtils.formatBytes(selectedBytes)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2196F3),
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: selectedCount > 0 && !_isCleaning ? _cleanSelected : null,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red[400],
              disabledBackgroundColor: Colors.grey[300],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: const Text('删除选中', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

}
