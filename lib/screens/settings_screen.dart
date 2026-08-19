import 'package:flutter/material.dart';
import '../services/scheduled_cleanup_service.dart';
import '../services/recycle_bin_service.dart';

/// 设置页面
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ScheduledCleanupService _scheduledService = ScheduledCleanupService();
  final RecycleBinService _recycleBinService = RecycleBinService();

  ScheduledCleanupConfig _config = ScheduledCleanupConfig();
  List<RecycleBinItem> _recycleBinItems = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final config = await _scheduledService.getConfig();
    final items = await _recycleBinService.getItems();

    setState(() {
      _config = config;
      _recycleBinItems = items;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          '设置',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF2196F3),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 定时清理设置
          _buildSectionTitle('🧹 定时清理'),
          _buildScheduledCleanupCard(),
          const SizedBox(height: 20),

          // 清理历史
          _buildSectionTitle('📊 清理统计'),
          _buildCleanStatsCard(),
          const SizedBox(height: 20),

          // 回收站
          _buildSectionTitle('🗑️ 回收站'),
          _buildRecycleBinCard(),
          const SizedBox(height: 20),

          // 关于
          _buildSectionTitle('ℹ️ 关于'),
          _buildAboutCard(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF666666),
        ),
      ),
    );
  }

  Widget _buildScheduledCleanupCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 总开关
            SwitchListTile(
              title: const Text(
                '启用定时清理',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                _config.enabled
                    ? '频率: ${_config.frequency.displayName}'
                    : '已关闭定时清理',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
              value: _config.enabled,
              onChanged: (value) async {
                final newConfig = _config.copyWith(enabled: value);
                await _scheduledService.saveConfig(newConfig);
                setState(() => _config = newConfig);
              },
              activeColor: const Color(0xFF4CAF50),
              contentPadding: EdgeInsets.zero,
            ),

            if (_config.enabled) ...[
              const Divider(),

              // 频率选择
              ListTile(
                title: const Text('清理频率', style: TextStyle(fontSize: 14)),
                trailing: DropdownButton<CleanupFrequency>(
                  value: _config.frequency,
                  underline: const SizedBox(),
                  items: CleanupFrequency.values
                      .where((f) => f != CleanupFrequency.never)
                      .map((f) => DropdownMenuItem(
                            value: f,
                            child: Text(f.displayName),
                          ))
                      .toList(),
                  onChanged: (value) async {
                    if (value == null) return;
                    final newConfig = _config.copyWith(frequency: value);
                    await _scheduledService.saveConfig(newConfig);
                    setState(() => _config = newConfig);
                  },
                ),
                contentPadding: EdgeInsets.zero,
              ),

              // 仅WiFi
              CheckboxListTile(
                title: const Text('仅在WiFi下清理', style: TextStyle(fontSize: 14)),
                value: _config.wifiOnly,
                onChanged: (value) async {
                  final newConfig = _config.copyWith(wifiOnly: value ?? true);
                  await _scheduledService.saveConfig(newConfig);
                  setState(() => _config = newConfig);
                },
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),

              // 清理完成通知
              CheckboxListTile(
                title: const Text('清理完成后通知', style: TextStyle(fontSize: 14)),
                value: _config.notifyComplete,
                onChanged: (value) async {
                  final newConfig = _config.copyWith(notifyComplete: value ?? true);
                  await _scheduledService.saveConfig(newConfig);
                  setState(() => _config = newConfig);
                },
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),

              if (_config.lastCleanupTime != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '上次清理: ${_formatDate(_config.lastCleanupTime!)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCleanStatsCard() {
    return FutureBuilder<int>(
      future: _scheduledService.getTotalCleanedBytes(),
      builder: (context, snapshot) {
        final totalBytes = snapshot.data ?? 0;
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey[200]!),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      '累计清理',
                      _formatBytes(totalBytes),
                      Icons.delete_sweep,
                      const Color(0xFF4CAF50),
                    ),
                    _buildStatItem(
                      '回收站文件',
                      '${_recycleBinItems.length} 个',
                      Icons.delete_outline,
                      const Color(0xFFFF9800),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _scheduledService.getCleanupHistory(),
                  builder: (context, snapshot) {
                    final history = snapshot.data ?? [];
                    if (history.isEmpty) {
                      return Text(
                        '暂无清理记录',
                        style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '最近清理记录',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...history.take(3).map((record) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle, size: 16, color: Color(0xFF4CAF50)),
                                const SizedBox(width: 8),
                                Text(
                                  '${record['type']}',
                                  style: const TextStyle(fontSize: 13),
                                ),
                                const Spacer(),
                                Text(
                                  _formatBytes(record['bytesCleaned']),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF4CAF50),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '${record['filesCleaned']} 个文件',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 28, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
      ],
    );
  }

  Widget _buildRecycleBinCard() {
    return FutureBuilder<int>(
      future: _recycleBinService.getTotalSize(),
      builder: (context, snapshot) {
        final totalSize = snapshot.data ?? 0;
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey[200]!),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.delete_outline, color: Color(0xFFFF9800)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '回收站',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${_recycleBinItems.length} 个文件 • ${_formatBytes(totalSize)}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                    if (_recycleBinItems.isNotEmpty)
                      TextButton(
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('清空回收站'),
                              content: const Text('清空后文件将无法恢复，确定要继续吗？'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('取消'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  style: FilledButton.styleFrom(backgroundColor: Colors.red),
                                  child: const Text('清空', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await _recycleBinService.clearAll();
                            _loadData();
                          }
                        },
                        child: const Text(
                          '清空',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                  ],
                ),

                if (_recycleBinItems.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  ..._recycleBinItems.take(5).map((item) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      _getFileIcon(item.fileType),
                      size: 24,
                      color: Colors.grey[600],
                    ),
                    title: Text(
                      item.name,
                      style: const TextStyle(fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${item.formattedSize} • ${item.daysUntilExpiry} 天后过期',
                      style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.restore, size: 18, color: Color(0xFF4CAF50)),
                          onPressed: () async {
                            await _recycleBinService.restoreItem(item.recyclePath);
                            _loadData();
                          },
                          tooltip: '恢复',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_forever, size: 18, color: Colors.red),
                          onPressed: () async {
                            await _recycleBinService.deletePermanently(item.recyclePath);
                            _loadData();
                          },
                          tooltip: '永久删除',
                        ),
                      ],
                    ),
                  )),
                  if (_recycleBinItems.length > 5)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '...还有 ${_recycleBinItems.length - 5} 个文件',
                        style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                      ),
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAboutCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.phone_android, size: 48, color: Color(0xFF2196F3)),
            const SizedBox(height: 12),
            const Text(
              '猫子手机清理',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              '版本 1.0.0',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
            const SizedBox(height: 12),
            Text(
              '一款简洁、安全的手机垃圾清理工具\n'
              '支持垃圾清理、重复文件检测、大文件管理、图片优化',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFileIcon(String fileType) {
    switch (fileType) {
      case 'image':
        return Icons.image;
      case 'video':
        return Icons.video_file;
      case 'audio':
        return Icons.audio_file;
      case 'document':
        return Icons.description;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
