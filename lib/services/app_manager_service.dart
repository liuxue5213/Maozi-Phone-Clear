import 'dart:io';

class AppManagerService {
  Future<List<AppInfo>> scanApps() async {
    final List<AppInfo> apps = [];
    try {
      final result = await Process.run('pm', ['list', '-f', '-3']); // 第三方应用
      final lines = result.stdout.toString().split('\n');
      for (final line in lines) {
        if (!line.startsWith('package:')) continue;
        final parts = line.split('=');
        if (parts.length < 2) continue;
        final path = parts[0].replaceFirst('package:', '');
        final pkg = parts[1].trim();
        apps.add(AppInfo(packageName: pkg, name: pkg.split('.').last, version: '1.0.0', sizeBytes: 0, cacheBytes: 0, dataBytes: 0, installTime: DateTime.now(), lastUsed: DateTime.now(), type: AppType.user));
      }
    } catch (_) {}
    return apps;
  }

  Future<bool> uninstallApp(AppInfo app) async {
    try {
      final result = await Process.run('pm', ['uninstall', app.packageName]);
      return result.exitCode == 0;
    } catch (_) { return false; }
  }

  Future<int> batchUninstall(List<AppInfo> apps) async {
    int freed = 0;
    for (final app in apps) {
      if (await uninstallApp(app)) freed += app.totalSizeBytes;
    }
    return freed;
  }

  Future<int> clearAppCache(List<AppInfo> apps) async {
    int freed = 0;
    for (final app in apps) {
      freed += app.cacheBytes;
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
