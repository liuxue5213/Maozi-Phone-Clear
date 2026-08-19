import 'package:flutter/material.dart';
import '../services/notification_service.dart';

/// 通知清理页面
class NotificationCleanupScreen extends StatefulWidget {
  const NotificationCleanupScreen({super.key});

  @override
  State<NotificationCleanupScreen> createState() =>
      _NotificationCleanupScreenState();
}

class _NotificationCleanupScreenState extends State<NotificationCleanupScreen> {
  final NotificationService _service = NotificationService();
  List<NotificationItem> _notifications = [];
  bool _isLoading = true;
  bool _isClearing = false;
  NotificationType? _filterType;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _notifications = [];
    });

    final notifications = await _service.getNotifications();

    if (!mounted) return;
    setState(() {
      _notifications = notifications;
      _isLoading = false;
    });
  }

  Future<void> _clearSelected() async {
    final selected = _notifications.where((n) => n.isSelected).toList();
    if (selected.isEmpty) return;

    setState(() => _isClearing = true);
    await _service.clearNotifications(selected);

    if (!mounted) return;
    setState(() {
      _notifications.removeWhere((n) => n.isSelected);
      _isClearing = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已清除 ${selected.length} 条通知'),
          backgroundColor: const Color(0xFF607D8B),
        ),
      );
    }
  }

  List<NotificationItem> get _filteredNotifications {
    if (_filterType == null) return _notifications;
    return _notifications.where((n) => n.type == _filterType).toList();
  }

  int get _selectedCount => _notifications.where((n) => n.isSelected).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          '通知清理',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF607D8B),
        elevation: 0,
        actions: [
          if (!_isLoading && !_isClearing)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _loadNotifications,
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
    if (_notifications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.notifications_off_outlined, size: 80, color: Color(0xFF4CAF50)),
              const SizedBox(height: 16),
              const Text('通知栏很干净', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(
                '没有需要清理的通知\n\n提示：如需清理通知栏消息，请在系统设置中开启通知访问权限',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500]),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('请在系统设置 > 应用管理 > 特殊权限 > 通知访问权限中开启')),
                  );
                },
                icon: const Icon(Icons.settings),
                label: const Text('去设置'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // 类型筛选
        _buildTypeFilter(),

        // 通知列表
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _filteredNotifications.length,
            itemBuilder: (context, index) {
              return _buildNotificationCard(_filteredNotifications[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTypeFilter() {
    return Container(
      height: 50,
      color: Colors.white,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _buildFilterChip('全部', null),
          const SizedBox(width: 8),
          ...NotificationType.values.map((type) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _buildFilterChip(type.displayName, type),
          )),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, NotificationType? type) {
    final isSelected = type == _filterType;
    return GestureDetector(
      onTap: () => setState(() => _filterType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF607D8B) : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? Colors.white : Colors.grey[600],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem notification) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: notification.isSelected
              ? const Color(0xFF607D8B).withOpacity(0.5)
              : Colors.grey[100]!,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() => notification.isSelected = !notification.isSelected);
        },
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // 复选框
              Icon(
                notification.isSelected
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                color: notification.isSelected
                    ? const Color(0xFF607D8B)
                    : Colors.grey[400],
                size: 22,
              ),

              const SizedBox(width: 12),

              // 通知图标
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _getTypeColor(notification.type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    notification.type.icon,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // 通知内容
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          notification.appName,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF607D8B),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          notification.formattedTime,
                          style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      notification.title,
                      style: const TextStyle(fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      notification.content,
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      overflow: TextOverflow.ellipsis,
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

  Color _getTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.promotion:
        return const Color(0xFFE91E63);
      case NotificationType.social:
        return const Color(0xFF2196F3);
      case NotificationType.news:
        return const Color(0xFFFF9800);
      case NotificationType.system:
        return const Color(0xFF4CAF50);
      case NotificationType.other:
        return const Color(0xFF9E9E9E);
    }
  }

  Widget? _buildBottomBar() {
    if (_isLoading || _notifications.isEmpty) return null;

    if (_selectedCount == 0) return null;

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
            '已选 $_selectedCount 条通知',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              setState(() {
                for (final n in _notifications) {
                  n.isSelected = n.type == NotificationType.promotion;
                }
              });
            },
            child: const Text(
              '仅推广',
              style: TextStyle(fontSize: 13, color: Color(0xFF607D8B)),
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: _selectedCount > 0 && !_isClearing ? _clearSelected : null,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF607D8B),
              disabledBackgroundColor: Colors.grey[300],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: const Text('清除通知', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
