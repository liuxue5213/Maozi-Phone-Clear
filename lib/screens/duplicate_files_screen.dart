import '../widgets/file_preview_dialog.dart';
import 'package:flutter/material.dart';
import '../models/duplicate_file.dart';
import '../services/duplicate_scanner.dart';

/// 重复文件页面
class DuplicateFilesScreen extends StatefulWidget {
  const DuplicateFilesScreen({super.key});

  @override
  State<DuplicateFilesScreen> createState() => _DuplicateFilesScreenState();
}

class _DuplicateFilesScreenState extends State<DuplicateFilesScreen> {
  final DuplicateScanner _scanner = DuplicateScanner();
  List<DuplicateGroup> _groups = [];
  bool _isScanning = false;
  bool _isCleaning = false;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _groups = [];
    });

    final groups = await _scanner.scanDuplicates();

    setState(() {
      _groups = groups;
      _isScanning = false;
    });
  }

  Future<void> _cleanSelected() async {
    final allCleanable = _groups
        .expand((g) => g.files.where((f) => f.isSelected))
        .toList();

    if (allCleanable.isEmpty) return;

    setState(() => _isCleaning = true);

    int freed = 0; await _scanner.deleteDuplicates(allCleanable); freed = allCleanable.fold(0, (s, f) => s + f.sizeBytes);
    for (int i = 0; i < allCleanable.length; i++) {
      await Future.delayed(const Duration(milliseconds: 50));
      setState(() => _progress = (i + 1) / allCleanable.length);
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
      _progress = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          '重复文件',
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
      return _buildScanningView();
    }

    if (_groups.isEmpty) {
      return _buildEmptyView();
    }

    return _buildGroupList();
  }

  Widget _buildScanningView() {
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
            '正在扫描重复文件...',
            style: TextStyle(fontSize: 16, color: Color(0xFF333333)),
          ),
          const SizedBox(height: 8),
          Text(
            '按文件大小分组后计算哈希',
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
          ),
        ],
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
            '没有发现重复文件',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            '你的手机很干净！',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupList() {
    final totalWasted = _groups.fold<int>(0, (sum, g) => sum + g.wastedBytes);

    return Column(
      children: [
        // 汇总栏
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              const Icon(Icons.content_copy, color: Color(0xFF2196F3)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '发现 ${_groups.length} 组重复文件',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '可释放 ${_formatBytes(totalWasted)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    for (final group in _groups) {
                      for (final file in group.files) {
                        file.isSelected = file != group.files.first;
                      }
                    }
                  });
                },
                child: const Text('智能选择'),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // 分组列表
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _groups.length,
            itemBuilder: (context, index) {
              return _buildGroupCard(_groups[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGroupCard(DuplicateGroup group) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
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
            // 组信息
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9800).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${group.files.length} 个重复',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFFF9800),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '浪费 ${group.formattedWastedSize}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFE91E63),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 文件列表
            ...group.files.map((file) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() => file.isSelected = !file.isSelected);
                    },
                    child: Icon(
                      file.isSelected
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: file.isSelected
                          ? const Color(0xFF2196F3)
                          : Colors.grey[400],
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          file.name,
                          style: const TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          file.path,
                          style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    file.formattedSize,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  if (file == group.files.first)
                    Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: const Text(
                        '保留',
                        style: TextStyle(fontSize: 10, color: Color(0xFF4CAF50)),
                      ),
                    ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget? _buildBottomBar() {
    if (_isScanning || _groups.isEmpty) return null;

    final selectedCount = _groups
        .expand((g) => g.files)
        .where((f) => f.isSelected)
        .length;
    final selectedBytes = _groups
        .expand((g) => g.files)
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
          Text(
            '已选 $selectedCount 个文件',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const Spacer(),
          Text(
            _formatBytes(selectedBytes),
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
              backgroundColor: const Color(0xFF4CAF50),
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
                : const Text('清理选中', style: TextStyle(color: Colors.white)),
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
