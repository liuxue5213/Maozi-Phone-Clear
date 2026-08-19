/// 通知服务
/// 
/// 注意：读取通知需要 NotificationListenerService 权限
/// 用户需要在系统设置中手动开启通知访问权限
class NotificationService {
  /// 获取通知列表
  /// 
  /// 由于 Android 权限限制，普通应用无法直接读取通知
  /// 需要 NotificationListenerService 或用户手动开启通知访问权限
  Future<List<NotificationItem>> getNotifications() async {
    // TODO: 实现 NotificationListenerService
    // 需要创建 NotificationListenerService 子类并在 AndroidManifest.xml 中注册
    return [];
  }

  /// 清除选中的通知
  Future<int> clearNotifications(List<NotificationItem> items) async {
    // TODO: 实现通知清除
    // 需要 NotificationListenerService 权限
    return 0;
  }

  /// 检查是否有通知访问权限
  Future<bool> hasPermission() async {
    // TODO: 检查 NotificationListenerService 是否已授权
    return false;
  }

  /// 请求通知访问权限（跳转到系统设置）
  Future<void> requestPermission() async {
    // TODO: 跳转到系统通知访问设置页面
    // 需要 platform channel 调用
  }
}

enum NotificationType { promotion, social, news, system, other }

class NotificationItem {
  final String id; final String appName; final String title; final String content; final DateTime time; final NotificationType type; final String packageName;
  bool isSelected;
  NotificationItem({required this.id, required this.appName, required this.title, required this.content, required this.time, required this.type, required this.packageName, this.isSelected = true});
  String get formattedTime { final d = DateTime.now().difference(time); if (d.inMinutes < 60) return '${d.inMinutes}分钟前'; if (d.inHours < 24) return '${d.inHours}小时前'; return '${d.inDays}天前'; }
}

extension NotificationTypeExt on NotificationType {
  String get displayName { switch(this) { case NotificationType.promotion: return '推广通知'; case NotificationType.social: return '社交通知'; case NotificationType.news: return '新闻资讯'; case NotificationType.system: return '系统通知'; case NotificationType.other: return '其他通知'; } }
  String get icon { switch(this) { case NotificationType.promotion: return '📢'; case NotificationType.social: return '💬'; case NotificationType.news: return '📰'; case NotificationType.system: return '🔔'; case NotificationType.other: return '📋'; } }
}
