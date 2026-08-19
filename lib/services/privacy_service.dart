import 'dart:io';

class PrivacyService {
  Future<List<PrivacyItem>> scanPrivacy() async {
    final List<PrivacyItem> items = [];
    final browserDirs = [
      '/storage/emulated/0/Android/data/com.android.chrome/app_chrome/Default/Cache',
      '/storage/emulated/0/Android/data/com.android.browser/app_cache',
      '/storage/emulated/0/Android/data/com.UCMobile.intl/cache',
    ];
    for (final dirPath in browserDirs) {
      try {
        final dir = Directory(dirPath);
        if (!await dir.exists()) continue;
        int size = 0;
        await for (final e in dir.list(recursive: true, followLinks: false)) {
          if (e is File) { try { size += (await e.stat()).size; } catch (_) {} }
        }
        if (size > 0) items.add(PrivacyItem(type: '浏览器历史', description: '网页浏览缓存和记录', sizeBytes: size, count: 1, isSelected: true));
      } catch (_) {}
    }
    return items;
  }

  Future<int> cleanPrivacy(List<PrivacyItem> items) async {
    int freed = 0;
    final dirs = [
      '/storage/emulated/0/Android/data/com.android.chrome/app_chrome/Default/Cache',
      '/storage/emulated/0/Android/data/com.android.browser/app_cache',
    ];
    for (final dirPath in dirs) {
      try {
        final dir = Directory(dirPath);
        if (!await dir.exists()) continue;
        await for (final e in dir.list(recursive: true, followLinks: false)) {
          if (e is File) { try { await e.delete(); } catch (_) {} }
        }
        freed += 1024 * 1024; // 估算
      } catch (_) {}
    }
    return freed;
  }
}

class PrivacyItem {
  final String type; final String description; final int sizeBytes; final int count;
  bool isSelected;
  PrivacyItem({required this.type, required this.description, required this.sizeBytes, required this.count, this.isSelected = true});
  String get formattedSize { if (sizeBytes < 1024) return '$sizeBytes B'; if (sizeBytes < 1024*1024) return '${(sizeBytes/1024).toStringAsFixed(1)} KB'; return '${(sizeBytes/(1024*1024)).toStringAsFixed(1)} MB'; }
}
