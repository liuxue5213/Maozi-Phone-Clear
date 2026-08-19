class NotificationService {
  Future<List<NotificationItem>> getNotifications() async {
    // 注意：读取通知需要 NotificationListenerService，普通应用无法直接获取
    // 这里返回空列表，提示用户需要特殊权限
    return [];
  }

  Future<int> clearNotifications(List<NotificationItem> items) async {
    return 0;
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
