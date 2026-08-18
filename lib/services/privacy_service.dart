import 'dart:io';
import 'dart:math';

/// 隐私数据类型
enum PrivacyType {
  clipboard,       // 剪贴板
  browserHistory,  // 浏览器历史
  searchHistory,   // 搜索记录
  callHistory,     // 通话记录
  messageDraft,    // 短信草稿
  appUsage,        // 应用使用记录
  crashLog,        // 崩溃日志
  adCache,         // 广告缓存
}

extension PrivacyTypeExtension on PrivacyType {
  String get displayName {
    switch (this) {
      case PrivacyType.clipboard:
        return '剪贴板';
      case PrivacyType.browserHistory:
        return '浏览器历史';
      case PrivacyType.searchHistory:
        return '搜索记录';
      case PrivacyType.callHistory:
        return '通话记录记录';
      case PrivacyType.messageDraft:
        return '短信草稿';
      case PrivacyType.appUsage:
        return '应用使用记录';
      case PrivacyType.crashLog:
        return '崩溃日志';
      case PrivacyType.adCache:
        return '广告缓存';
    }
  }

  String get icon {
    switch (this) {
      case PrivacyType.clipboard:
        return '📋';
      case PrivacyType.browserHistory:
        return '🌐';
      case PrivacyType.searchHistory:
        return '🔍';
      case PrivacyType.callHistory:
        return '📞';
      case PrivacyType.messageDraft:
        return '✉️';
      case PrivacyType.appUsage:
        return '📱';
      case PrivacyType.crashLog:
        return '💥';
      case PrivacyType.adCache:
        return '📢';
    }
  }

  String get description {
    switch (this) {
      case PrivacyType.clipboard:
        return '复制的文本和图片';
      case PrivacyType.browserHistory:
        return '网页浏览足迹';
      case PrivacyType.searchHistory:
        return '搜索引擎记录';
      case PrivacyType.callHistory:
        return '通话记录痕迹';
      case PrivacyType.messageDraft:
        return '未发送的草稿';
      case PrivacyType.appUsage:
        return 'App使用时长记录';
      case PrivacyType.crashLog:
        return '应用崩溃报告';
      case PrivacyType.adCache:
        return 'SDK广告追踪数据';
    }
  }
}

/// 隐私清理项
class PrivacyItem {
  final PrivacyType type;
  final int count;
  final int sizeBytes;
  bool isSelected;

  PrivacyItem({
    required this.type,
    required this.count,
    required this.sizeBytes,
    this.isSelected = false,
  });

  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// 隐私清理服务
class PrivacyService {
  final Random _random = Random();

  /// 扫描隐私数据
  Future<List<PrivacyItem>> scanPrivacy() async {
    await Future.delayed(const Duration(seconds: 1));

    return [
      PrivacyItem(
        type: PrivacyType.clipboard,
        count: 5,
        sizeBytes: 2 * 1024,
        isSelected: true,
      ),
      PrivacyItem(
        type: PrivacyType.browserHistory,
        count: 128,
        sizeBytes: 15 * 1024 * 1024,
        isSelected: true,
      ),
      PrivacyItem(
        type: PrivacyType.searchHistory,
        count: 45,
        sizeBytes: 512 * 1024,
        isSelected: true,
      ),
      PrivacyItem(
        type: PrivacyType.callHistory,
        count: 0,
        sizeBytes: 0,
        isSelected: false,
      ),
      PrivacyItem(
        type: PrivacyType.messageDraft,
        count: 2,
        sizeBytes: 8 * 1024,
        isSelected: true,
      ),
      PrivacyItem(
        type: PrivacyType.appUsage,
        count: 67,
        sizeBytes: 2 * 1024 * 1024,
        isSelected: true,
      ),
      PrivacyItem(
        type: PrivacyType.crashLog,
        count: 23,
        sizeBytes: 8 * 1024 * 1024,
        isSelected: true,
      ),
      PrivacyItem(
        type: PrivacyType.adCache,
        count: 156,
        sizeBytes: 30 * 1024 * 1024,
        isSelected: true,
      ),
    ];
  }

  /// 清理选中的隐私数据
  Future<int> cleanPrivacy(List<PrivacyItem> items) async {
    int freedBytes = 0;
    for (final item in items) {
      await Future.delayed(const Duration(milliseconds: 100));
      freedBytes += item.sizeBytes;
    }
    return freedBytes;
  }
}
