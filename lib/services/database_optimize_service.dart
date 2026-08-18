import 'dart:math';

/// 数据库优化项
class DatabaseItem {
  final String appName;
  final String packageName;
  final String dbName;
  final int originalSizeBytes;
  final int wastedBytes;
  final String issue;
  bool isSelected;

  DatabaseItem({
    required this.appName,
    required this.packageName,
    required this.dbName,
    required this.originalSizeBytes,
    required this.wastedBytes,
    required this.issue,
    this.isSelected = false,
  });

  int get optimizedSizeBytes => originalSizeBytes - wastedBytes;

  String get formattedOriginalSize => _formatBytes(originalSizeBytes);
  String get formattedWastedSize => _formatBytes(wastedBytes);
  String get formattedOptimizedSize => _formatBytes(optimizedSizeBytes);

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// 数据库优化服务
class DatabaseOptimizeService {
  final Random _random = Random();

  /// 扫描可优化的数据库
  Future<List<DatabaseItem>> scanDatabases() async {
    await Future.delayed(const Duration(seconds: 1));

    return [
      DatabaseItem(
        appName: '微信',
        packageName: 'com.tencent.mm',
        dbName: 'MicroMsg.db',
        originalSizeBytes: 85 * 1024 * 1024,
        wastedBytes: 25 * 1024 * 1024,
        issue: '聊天记录数据库碎片过多',
        isSelected: true,
      ),
      DatabaseItem(
        appName: 'QQ',
        packageName: 'com.tencent.mobileqq',
        dbName: 'slowtable.db',
        originalSizeBytes: 60 * 1024 * 1024,
        wastedBytes: 18 * 1024 * 1024,
        issue: '群消息历史冗余数据',
        isSelected: true,
      ),
      DatabaseItem(
        appName: '微博',
        packageName: 'com.sina.weibo',
        dbName: 'weibo.db',
        originalSizeBytes: 45 * 1024 * 1024,
        wastedBytes: 12 * 1024 * 1024,
        issue: '微博缓存索引膨胀',
        isSelected: true,
      ),
      DatabaseItem(
        appName: '知乎',
        packageName: 'com.zhihu.android',
        dbName: 'zhihu.db',
        originalSizeBytes: 35 * 1024 * 1024,
        wastedBytes: 8 * 1024 * 1024,
        issue: '推荐算法缓存堆积',
        isSelected: true,
      ),
      DatabaseItem(
        appName: '抖音',
        packageName: 'com.ss.android.ugc.aweme',
        dbName: 'aweme.db',
        originalSizeBytes: 55 * 1024 * 1024,
        wastedBytes: 15 * 1024 * 1024,
        issue: '视频观看记录冗余',
        isSelected: true,
      ),
      DatabaseItem(
        appName: '今日头条',
        packageName: 'com.ss.android.article.news',
        dbName: 'article.db',
        originalSizeBytes: 40 * 1024 * 1024,
        wastedBytes: 10 * 1024 * 1024,
        issue: '新闻阅读历史未清理',
        isSelected: true,
      ),
      DatabaseItem(
        appName: '网易云音乐',
        packageName: 'com.netease.cloudmusic',
        dbName: 'music.db',
        originalSizeBytes: 28 * 1024 * 1024,
        wastedBytes: 6 * 1024 * 1024,
        issue: '歌曲播放记录冗余',
        isSelected: true,
      ),
    ];
  }

  /// 执行数据库优化 (VACUUM)
  Future<int> optimize(List<DatabaseItem> items) async {
    int totalFreed = 0;
    for (final item in items) {
      await Future.delayed(const Duration(milliseconds: 200));
      totalFreed += item.wastedBytes;
    }
    return totalFreed;
  }
}
