import 'dart:io';

class NotificationService {
  Future<List<NotificationItem>> getNotifications() async {
    final List<NotificationItem> items = [];
    try {
      final result = await Process.run('dumpsys', ['notification', '--noredact']);
      final output = result.stdout.toString();
      String currentPkg = '';
      for (final line in output.split('\n')) {
        if (line.contains('NotificationRecord')) {
          final match = RegExp(r'pkg=(\S+)').firstMatch(line);
          if (match != null) currentPkg = match.group(1) ?? '';
        }
        if (line.contains('android.title=') && currentPkg.isNotEmpty) {
          final titleMatch = RegExp(r'android.title=(.+)').firstMatch(line);
          final title = titleMatch?.group(1) ?? '通知';
          items.add(NotificationItem(id: currentPkg + items.length.toString(), appName: _getAppName(currentPkg), title: title, content: '', time: DateTime.now(), type: NotificationType.other, packageName: currentPkg, isSelected: true));
        }
      }
    } catch (_) {}
    return items.take(50).toList();
  }

  String _getAppName(String pkg) {
    if (pkg.contains('tencent.mm')) return '微信';
    if (pkg.contains('mobileqq')) return 'QQ';
    if (pkg.contains('whatsapp')) return 'WhatsApp';
    return pkg.split('.').last;
  }

  Future<int> clearNotifications(List<NotificationItem> items) async {
    return items.length;
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

