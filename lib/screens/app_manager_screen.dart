import 'package:flutter/material.dart';
import '../services/app_manager_service.dart';

/// 应用管理页面
class AppManagerScreen extends StatefulWidget {
  const AppManagerScreen({super.key});

  @override
  State<AppManagerScreen> createState() => _AppManagerScreenState();
}

class _AppManagerScreenState extends State<AppManagerScreen> {
  final AppManagerService _service = AppManagerService();
  List<AppInfo> _apps = [];
  bool _isLoading = true;
  int _sortBy = 0; // 0=大小, 1=使用时间, 2=名称
  int _filterType = 0; // 0=全部, 1=用户, 2=预装

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    setState(() => _isLoading = true);
    final apps = await _service.scanApps();
    setState(() {
      _apps = apps;
      _isLoading = false;
      _sortApps();
    });
  }

  void _sortApps() {
    switch (_sortBy) {
      case 0:
        _apps.sort((a, b) => b.totalSizeBytes.compareTo(a.totalSizeBytes));
        break;
      case 1:
        _apps.sort((a, b) => a.lastUsed.compareTo(b.lastUsed));
        break;
      case 2:
        _apps.sort((a, b) => a.name.compareTo(b.name));
        break;
    }
  }

  List<AppInfo> get _filteredApps {
    switch (_filterType) {
      case 1:
        return _apps.where((a) => a.type == AppType.user).toList();
      case 2:
        return _apps.where((a) => a.type == AppType.preinstalled).toList();
      default:
        return _apps;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          '应用管理',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF2196F3),
        elevation: 0,
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.sort, color: Colors.white),
            onSelected: (value) {
              setState(() {
                _sortBy = value;
                _sortApps();
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 0, child: Text('按大小排序')),
              const PopupMenuItem(value: 1, child: Text('按使用时间')),
              const PopupMenuItem(value: 2, child: Text('按名称排序')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 筛选标签
                _buildFilterTabs(),

                // 汇总信息
                _buildSummaryBar(),

                // 应用列表
                Expanded(
                  child: _filteredApps.isEmpty
                      ? const Center(child: Text('没有符合条件的应用'))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredApps.length,
                          itemBuilder: (context, index) {
                            return _buildAppCard(_filteredApps[index]);
                          },
                        ),
                ),
              ],
            ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildFilterChip('全部', 0),
          const SizedBox(width: 8),
          _buildFilterChip('用户应用', 1),
          const SizedBox(width: 8),
          _buildFilterChip('预装应用', 2),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int type) {
    final isSelected = _filterType == type;
    return GestureDetector(
      onTap: () => setState(() => _filterType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2196F3) : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isSelected ? Colors.white : Colors.grey[600],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryBar() {
    final userApps = _apps.where((a) => a.type == AppType.user).length;
    final preApps = _apps.where((a) => a.type == AppType.preinstalled).length;
    final totalCache = _apps.fold<int>(0, (sum, a) => sum + a.cacheBytes);

    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('${_apps.length}', '个应用'),
          _buildSummaryItem('${_formatBytes(totalCache)}', '缓存'),
          _buildSummaryItem('${userApps}', '用户'),
          _buildSummaryItem('${preApps}', '预装'),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2196F3),
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
        ),
      ],
    );
  }

  Widget _buildAppCard(AppInfo app) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: app.isSelected
              ? const Color(0xFF2196F3).withOpacity(0.5)
              : Colors.grey[200]!,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() => app.isSelected = !app.isSelected);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // 复选框
              Icon(
                app.isSelected
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                color: app.isSelected
                    ? const Color(0xFF2196F3)
                    : Colors.grey[400],
                size: 24,
              ),

              const SizedBox(width: 12),

              // 应用图标占位
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _getAppColor(app.name).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    app.name.isNotEmpty ? app.name[0] : '?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _getAppColor(app.name),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // 应用信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            app.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (app.type != AppType.user)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              app.type == AppType.system ? '系统' : '预装',
                              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '版本 ${app.version} • ${app.formattedApkSize}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          app.formattedTotalSize,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFE91E63),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '• ${app.usageFrequency}',
                          style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getAppColor(String name) {
    final colors = [
      const Color(0xFF2196F3),
      const Color(0xFF4CAF50),
      const Color(0xFFFF9800),
      const Color(0xFFE91E63),
      const Color(0xFF9C27B0),
      const Color(0xFF607D8B),
      const Color(0xFF795548),
      const Color(0xFF009688),
    ];
    return colors[name.hashCode.abs() % colors.length];
  }

  Widget? _buildBottomBar() {
    if (_isLoading) return null;

    final selectedApps = _apps.where((a) => a.isSelected).toList();
    if (selectedApps.isEmpty) return null;

    final selectedBytes = selectedApps.fold<int>(0, (sum, a) => sum + a.totalSizeBytes);
    final hasCache = selectedApps.any((a) => a.cacheBytes > 0);

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
            '已选 ${selectedApps.length} 个',
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
          const SizedBox(width: 8),
          if (hasCache)
            OutlinedButton(
              onPressed: () async {
                final freed = await _service.clearAppCache(selectedApps);
                setState(() {
                  for (final app in selectedApps) {
                    app.isSelected = false;
                  }
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('已清理缓存 ${_formatBytes(freed)}')),
                  );
                }
              },
              child: const Text('清缓存'),
            ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('确认卸载'),
                  content: Text('确定要卸载选中的 ${selectedApps.length} 个应用吗？'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('取消'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: FilledButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('卸载', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                final freed = await _service.batchUninstall(selectedApps);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('已卸载 ${selectedApps.length} 个应用，释放 ${_formatBytes(freed)}')),
                  );
                }
                _loadApps();
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('卸载', style: TextStyle(color: Colors.white)),
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
