import 'dart:io';

class SocialScanner {
  Future<Map<SocialApp, Map<SocialCacheType, List<SocialCacheItem>>>> scanSocialApps() async {
    final Map<SocialApp, Map<SocialCacheType, List<SocialCacheItem>>> result = {};
    final socialPaths = {
      SocialApp.wechat: '/storage/emulated/0/Android/data/com.tencent.mm',
      SocialApp.qq: '/storage/emulated/0/Android/data/com.tencent.mobileqq',
      SocialApp.douyin: '/storage/emulated/0/Android/data/com.ss.android.ugc.aweme',
    };

    for (final entry in socialPaths.entries) {
      final appDir = Directory(entry.value);
      if (!await appDir.exists()) continue;
      final Map<SocialCacheType, List<SocialCacheItem>> cache = {};
      
      await for (final entity in appDir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          try {
            final stat = await entity.stat();
            String type = 'cache';
            final path = entity.path.toLowerCase();
            if (path.contains('/video/')) type = 'video';
            else if (path.contains('/image/') || path.contains('/photo/')) type = 'image';
            else if (path.contains('/voice/')) type = 'voice';
            else if (path.contains('/emoji/')) type = 'emoji';
            
            final cacheType = SocialCacheType.values.firstWhere((t) => t.name == type, orElse: () => SocialCacheType.cache);
            cache.putIfAbsent(cacheType, () => []).add(SocialCacheItem(
              path: entity.path, name: entity.path.split('/').last, sizeBytes: stat.size,
              app: entry.key, type: cacheType, lastAccessed: stat.modified,
            ));
          } catch (e) {}
        }
      }
      
      if (cache.isNotEmpty) result[entry.key] = cache;
    }
    return result;
  }

  Future<int> deleteSocialCache(List<SocialCacheItem> items) async {
    int freed = 0;
    for (final item in items) { try { await File(item.path).delete(); freed += item.sizeBytes; } catch (e) {} }
    return freed;
  }
}

enum SocialApp { wechat, qq, douyin }
enum SocialCacheType { image, video, file, voice, emoji, sticker, cache }
class SocialCacheItem {
  final String path; final String name; final int sizeBytes; final SocialApp app; final SocialCacheType type; final DateTime lastAccessed;
  bool isSelected = true;
  SocialCacheItem({required this.path, required this.name, required this.sizeBytes, required this.app, required this.type, required this.lastAccessed});
  String get formattedSize { if (sizeBytes < 1024) return '$sizeBytes B'; if (sizeBytes < 1024*1024) return '${(sizeBytes/1024).toStringAsFixed(1)} KB'; if (sizeBytes < 1024*1024*1024) return '${(sizeBytes/(1024*1024)).toStringAsFixed(1)} MB'; return '${(sizeBytes/(1024*1024*1024)).toStringAsFixed(2)} GB'; }
}

extension SocialAppExt on SocialApp {
  String get displayName { switch(this) { case SocialApp.wechat: return '微信'; case SocialApp.qq: return 'QQ'; case SocialApp.douyin: return '抖音'; } }
  String get icon { switch(this) { case SocialApp.wechat: return '💬'; case SocialApp.qq: return '🐧'; case SocialApp.douyin: return '🎵'; } }
}
extension SocialCacheTypeExt on SocialCacheType {
  String get displayName { switch(this) { case SocialCacheType.image: return '图片'; case SocialCacheType.video: return '视频'; case SocialCacheType.file: return '文件'; case SocialCacheType.voice: return '语音'; case SocialCacheType.emoji: return '表情'; case SocialCacheType.sticker: return '贴纸'; case SocialCacheType.cache: return '缓存'; } }
  String get icon { switch(this) { case SocialCacheType.image: return '🖼️'; case SocialCacheType.video: return '🎬'; case SocialCacheType.file: return '📎'; case SocialCacheType.voice: return '🎤'; case SocialCacheType.emoji: return '😀'; case SocialCacheType.sticker: return '🏷️'; case SocialCacheType.cache: return '📦'; } }
}

