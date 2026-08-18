import 'dart:io';
import 'dart:math';

/// 应用类型
enum AppType {
  system,      // 系统应用
  user,        // 用户应用
  preinstalled, // 预装应用
}

extension AppTypeExtension on AppType {
  String get displayName {
    switch (this) {
      case AppType.system:
        return '系统应用';
      case AppType.user:
        return '用户应用';
      case AppType.preinstalled:
        return '预装应用';
    }
  }

  String get icon {
    switch (this) {
      case AppType.system:
        return '⚙️';
      case AppType.user:
        return '📱';
      case AppType.preinstalled:
        return '📦';
    }
  }
}

/// 应用信息
class AppInfo {
  final String packageName;
  final String name;
  final String version;
  final int sizeBytes;        // APK大小
  final int cacheBytes;       // 缓存大小
  final int dataBytes;        // 数据大小
  final DateTime installTime;
  final DateTime lastUsed;
  final AppType type;
  final String? iconPath;
  bool isSelected;

  AppInfo({
    required this.packageName,
    required this.name,
    required this.version,
    required this.sizeBytes,
    required this.cacheBytes,
    required this.dataBytes,
    required this.installTime,
    required this.lastUsed,
    required this.type,
    this.iconPath,
    this.isSelected = false,
  });

  int get totalSizeBytes => sizeBytes + cacheBytes + dataBytes;

  String get formattedApkSize => _formatBytes(sizeBytes);
  String get formattedCacheSize => _formatBytes(cacheBytes);
  String get formattedTotalSize => _formatBytes(totalSizeBytes);

  /// 使用频率描述
  String get usageFrequency {
    final daysSinceUsed = DateTime.now().difference(lastUsed).inDays;
    if (daysSinceUsed == 0) return '今天使用';
    if (daysSinceUsed == 1) return '昨天使用';
    if (daysSinceUsed < 7) return '${daysSinceUsed}天前使用';
    if (daysSinceUsed < 30) return '${(daysSinceUsed / 7).floor()}周前使用';
    if (daysSinceUsed < 365) return '${(daysSinceUsed / 30).floor()}月前使用';
    return '${(daysSinceUsed / 365).floor()}年前使用';
  }

  /// 是否可以卸载
  bool get canUninstall => type != AppType.system;

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

/// 应用管理服务
class AppManagerService {
  final Random _random = Random();

  /// 扫描已安装应用
  Future<List<AppInfo>> scanApps() async {
    await Future.delayed(const Duration(seconds: 1));
    return _generateMockApps();
  }

  List<AppInfo> _generateMockApps() {
    final List<AppInfo> apps = [];

    // 用户应用 - 常用
    apps.addAll([
      _createApp('com.tencent.mm', '微信', '8.0.40', 350 * 1024 * 1024, 2 * 1024 * 1024 * 1024, 500 * 1024 * 1024, AppType.user, daysAgo: 0),
      _createApp('com.tencent.mobileqq', 'QQ', '8.9.80', 280 * 1024 * 1024, 1.5 * 1024 * 1024 * 1024 as int, 300 * 1024 * 1024, AppType.user, daysAgo: 0),
      _createApp('com.ss.android.ugc.aweme', '抖音', '28.0.0', 420 * 1024 * 1024, 3 * 1024 * 1024 * 1024 as int, 200 * 1024 * 1024, AppType.user, daysAgo: 0),
      _createApp('com.sina.weibo', '微博', '13.8.0', 220 * 1024 * 1024, 800 * 1024 * 1024, 150 * 1024 * 1024, AppType.user, daysAgo: 1),
      _createApp('com.netease.cloudmusic', '网易云音乐', '8.10.0', 180 * 1024 * 1024, 1 * 1024 * 1024 * 1024 as int, 200 * 1024 * 1024, AppType.user, daysAgo: 0),
    ]);

    // 用户应用 - 不常用
    apps.addAll([
      _createApp('com.meituan.meituan', '美团', '12.20.0', 200 * 1024 * 1024, 400 * 1024 * 1024, 100 * 1024 * 1024, AppType.user, daysAgo: 15),
      _createApp('com.taobao.taobao', '淘宝', '10.30.0', 350 * 1024 * 1024, 600 * 1024 * 1024, 200 * 1024 * 1024, AppType.user, daysAgo: 30),
      _createApp('com.jingdong.app.mall', '京东', '12.0.0', 280 * 1024 * 1024, 500 * 1024 * 1024, 180 * 1024 * 1024, AppType.user, daysAgo: 45),
      _createApp('com.dianping.v1', '大众点评', '11.40.0', 150 * 1024 * 1024, 300 * 1024 * 1024, 80 * 1024 * 1024, AppType.user, daysAgo: 60),
      _createApp('com.Qunar', '去哪儿旅行', '10.2.0', 180 * 1024 * 1024, 200 * 1024 * 1024, 120 * 1024 * 1024, AppType.user, daysAgo: 90),
      _createApp('com.sdu.didi.psnger', '滴滴出行', '7.0.0', 250 * 1024 * 1024, 350 * 1024 * 1024, 150 * 1024 * 1024, AppType.user, daysAgo: 20),
      _createApp('ctrip.android.view', '携程旅行', '8.60.0', 200 * 1024 * 1024, 250 * 1024 * 1024, 100 * 1024 * 1024, AppType.user, daysAgo: 120),
    ]);

    // 预装应用
    apps.addAll([
      _createApp('com.android.chrome', 'Chrome浏览器', '120.0', 150 * 1024 * 1024, 800 * 1024 * 1024, 50 * 1024 * 1024, AppType.preinstalled, daysAgo: 3),
      _createApp('com.android.vending', 'Google Play', '35.0', 80 * 1024 * 1024, 200 * 1024 * 1024, 100 * 1024 * 1024, AppType.preinstalled, daysAgo: 7),
      _createApp('com.google.android.youtube', 'YouTube', '19.0', 120 * 1024 * 1024, 500 * 1024 * 1024, 200 * 1024 * 1024, AppType.preinstalled, daysAgo: 10),
      _createApp('com.android.email', '邮件', '1.0', 30 * 1024 * 1024, 50 * 1024 * 1024, 20 * 1024 * 1024, AppType.preinstalled, daysAgo: 100),
      _createApp('com.android.calculator2', '计算器', '1.0', 5 * 1024 * 1024, 1 * 1024 * 1024, 0, AppType.preinstalled, daysAgo: 200),
    ]);

    // 按总大小降序
    apps.sort((a, b) => b.totalSizeBytes.compareTo(a.totalSizeBytes));
    return apps;
  }

  AppInfo _createApp(
    String packageName,
    String name,
    String version,
    int apkSize,
    int cacheSize,
    int dataSize,
    AppType type, {
    int daysAgo = 0,
  }) {
    return AppInfo(
      packageName: packageName,
      name: name,
      version: version,
      sizeBytes: apkSize,
      cacheBytes: cacheSize,
      dataBytes: dataSize,
      installTime: DateTime.now().subtract(Duration(days: 30 + _random.nextInt(365))),
      lastUsed: DateTime.now().subtract(Duration(days: daysAgo)),
      type: type,
    );
  }

  /// 卸载应用（模拟）
  Future<bool> uninstallApp(AppInfo app) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // 实际项目调用平台API卸载
    return true;
  }

  /// 批量卸载
  Future<int> batchUninstall(List<AppInfo> apps) async {
    int freedBytes = 0;
    for (final app in apps) {
      if (app.canUninstall) {
        final success = await uninstallApp(app);
        if (success) {
          freedBytes += app.totalSizeBytes;
        }
      }
    }
    return freedBytes;
  }

  /// 清理应用缓存
  Future<int> clearAppCache(List<AppInfo> apps) async {
    int freedBytes = 0;
    for (final app in apps) {
      await Future.delayed(const Duration(milliseconds: 100));
      freedBytes += app.cacheBytes;
    }
    return freedBytes;
  }
}
