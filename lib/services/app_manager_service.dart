import 'dart:io';

class AppManagerService {
  Future<List<AppInfo>> scanApps() async {
    final List<AppInfo> apps = [];
    // 扫描已安装应用的缓存目录
    final dataDir = Directory('/storage/emulated/0/Android/data');
    if (!await dataDir.exists()) return apps;
    
    await for (final entity in dataDir.list()) {
      if (entity is Directory) {
        final pkg = entity.path.split('/').last;
        int totalSize = 0;
        await for (final f in entity.list(recursive: true, followLinks: false)) {
          if (f is File) { try { totalSize += (await f.stat()).size; } catch (_) {} }
        }
        apps.add(AppInfo(packageName: pkg, name: pkg.split('.').last, version: '1.0.0', sizeBytes: totalSize, cacheBytes: totalSize, dataBytes: 0, installTime: DateTime.now(), lastUsed: DateTime.now(), type: AppType.user));
      }
    }
    return apps;
  }

  Future<bool> uninstallApp(AppInfo app) async {
    // 卸载需要系统权限，普通应用无法执行
    return false;
  }

  Future<int> batchUninstall(List<AppInfo> apps) async {
    // 卸载需要系统权限，普通应用无法执行
    return 0;
  }

  Future<int> clearAppCache(List<AppInfo> apps) async {
    int freed = 0;
    for (final app in apps) {
      try {
        final cacheDir = Directory('/storage/emulated/0/Android/data/${app.packageName}/cache');
        if (await cacheDir.exists()) {
          await for (final f in cacheDir.list(recursive: true, followLinks: false)) {
            if (f is File) { try { await f.delete(); } catch (_) {} }
          }
        }
        freed += app.cacheBytes;
      } catch (_) {}
    }
    return freed;
  }
}

enum AppType { system, user, preinstalled }

class AppInfo {
  final String packageName; final String name; final String version; final int sizeBytes; final int cacheBytes; final int dataBytes; final DateTime installTime; final DateTime lastUsed; final AppType type;
  bool isSelected = false;
  AppInfo({required this.packageName, required this.name, required this.version, required this.sizeBytes, required this.cacheBytes, required this.dataBytes, required this.installTime, required this.lastUsed, required this.type});
  int get totalSizeBytes => sizeBytes + cacheBytes + dataBytes;
  bool get canUninstall => type != AppType.system;
  String get usageFrequency { final d = DateTime.now().difference(lastUsed).inDays; if (d == 0) return '今天使用'; if (d < 7) return '${d}天前'; if (d < 30) return '${(d/7).floor()}周前'; return '${(d/30).floor()}月前'; }
  String get formattedApkSize => sizeBytes > 1024*1024 ? '${(sizeBytes/(1024*1024)).toStringAsFixed(1)}MB' : '${(sizeBytes/1024).toStringAsFixed(1)}KB';
  String get formattedTotalSize => totalSizeBytes > 1024*1024 ? '${(totalSizeBytes/(1024*1024)).toStringAsFixed(1)}MB' : '${(totalSizeBytes/1024).toStringAsFixed(1)}KB';
}
