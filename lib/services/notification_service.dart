import 'dart:math';

/// 通知类型
enum NotificationType {
  promotion,     // 推广
  social,        // 社交
  news,          // 新闻
  system,        // 系统
  other,         // 其他
}

extension NotificationTypeExtension on NotificationType {
  String get displayName {
    switch (this) {
      case NotificationType.promotion:
        return '推广通知';
      case NotificationType.social:
        return '社交通知';
      case NotificationType.news:
        return '新闻资讯';
      case NotificationType.system:
        return '系统通知';
      case NotificationType.other:
        return '其他通知';
    }
  }

  String get icon {
    switch (this) {
      case NotificationType.promotion:
        return '📢';
      case NotificationType.social:
        return '💬';
      case NotificationType.news:
        return '📰';
      case NotificationType.system:
        return '🔔';
      case NotificationType.other:
        return '📋';
    }
  }
}

/// 通知项
class NotificationItem {
  final String id;
  final String appName;
  final String title;
  final String content;
  final DateTime time;
  final NotificationType type;
  final String packageName;
  bool isSelected;

  NotificationItem({
    required this.id,
    required this.appName,
    required this.title,
    required this.content,
    required this.time,
    required this.type,
    required this.packageName,
    this.isSelected = false,
  });

  String get formattedTime {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return '${time.month}/${time.day}';
  }
}

/// 通知清理服务
class NotificationService {
  final Random _random = Random();

  /// 获取通知列表
  Future<List<NotificationItem>> getNotifications() async {
    await Future.delayed(const Duration(seconds: 1));

    final List<NotificationItem> notifications = [];
    final apps = [
      ('美团外卖', 'com.sankuai.meituan.takeoutnew', NotificationType.promotion),
      ('淘宝', 'com.taobao.taobao', NotificationType.promotion),
      ('京东', 'com.jingdong.app.mall', NotificationType.promotion),
      ('拼多多', 'com.xunmeng.pinduoduo', NotificationType.promotion),
      ('微信', 'com.tencent.mm', NotificationType.social),
      ('QQ', 'com.tencent.mobileqq', NotificationType.social),
      ('抖音', 'com.ss.android.ugc.aweme', NotificationType.social),
      ('今日头条', 'com.ss.android.article.news', NotificationType.news),
      ('网易新闻', 'com.netease.newsreader.activity', NotificationType.news),
      ('系统更新', 'com.android.systemui', NotificationType.system),
    ];

    for (final (name, pkg, type) in apps) {
      final count = 2 + _random.nextInt(8);
      for (int i = 0; i < count; i++) {
        notifications.add(NotificationItem(
          id: '${pkg}_$i',
          appName: name,
          title: _generateTitle(name, type),
          content: _generateContent(type),
          time: DateTime.now().subtract(Duration(minutes: _random.nextInt(1440))),
          type: type,
          packageName: pkg,
          isSelected: type == NotificationType.promotion,
        ));
      }
    }

    // 按时间降序
    notifications.sort((a, b) => b.time.compareTo(a.time));
    return notifications;
  }

  String _generateTitle(String appName, NotificationType type) {
    switch (type) {
      case NotificationType.promotion:
        return '$appName: 限时优惠！新人专享大礼包';
      case NotificationType.social:
        return '$appName: 您有新消息';
      case NotificationType.news:
        return '$appName: 今日热点新闻';
      case NotificationType.system:
        return '$appName: 系统通知';
      case NotificationType.other:
        return '$appName: 提醒';
    }
  }

  String _generateContent(NotificationType type) {
    switch (type) {
      case NotificationType.promotion:
        return '错过再等一年，立即点击查看专属优惠';
      case NotificationType.social:
        return '您收到一条新消息，点击查看';
      case NotificationType.news:
        return '今日热点事件汇总，不容错过';
      case NotificationType.system:
        return '系统检测到可用更新';
      case NotificationType.other:
        return '点击查看详细内容';
    }
  }

  /// 清理选中的通知
  Future<int> clearNotifications(List<NotificationItem> items) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return items.length;
  }
}
