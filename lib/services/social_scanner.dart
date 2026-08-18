import 'dart:io';
import 'dart:math';

/// 社交应用类型
enum SocialApp {
  wechat,
  qq,
  douyin,
  weibo,
}

extension SocialAppExtension on SocialApp {
  String get displayName {
    switch (this) {
      case SocialApp.wechat:
        return '微信';
      case SocialApp.qq:
        return 'QQ';
      case SocialApp.douyin:
        return '抖音';
      case SocialApp.weibo:
        return '微博';
    }
  }

  String get icon {
    switch (this) {
      case SocialApp.wechat:
        return '💬';
      case SocialApp.qq:
        return '🐧';
      case SocialApp.douyin:
        return '🎵';
      case SocialApp.weibo:
        return '📢';
    }
  }
}

/// 社交应用缓存分类
enum SocialCacheType {
  image,       // 聊天图片
  video,       // 聊天视频
  file,        // 接收文件
  voice,       // 语音消息
  emoji,       // 自定义表情
  sticker,     // 贴纸
  cache,       // 通用缓存
}

extension SocialCacheTypeExtension on SocialCacheType {
  String get displayName {
    switch (this) {
      case SocialCacheType.image:
        return '聊天图片';
      case SocialCacheType.video:
        return '聊天视频';
      case SocialCacheType.file:
        return '接收文件';
      case SocialCacheType.voice:
        return '语音消息';
      case SocialCacheType.emoji:
        return '自定义表情';
      case SocialCacheType.sticker:
        return '贴纸';
      case SocialCacheType.cache:
        return '通用缓存';
    }
  }

  String get icon {
    switch (this) {
      case SocialCacheType.image:
        return '🖼️';
      case SocialCacheType.video:
        return '🎬';
      case SocialCacheType.file:
        return '📎';
      case SocialCacheType.voice:
        return '🎤';
      case SocialCacheType.emoji:
        return '😀';
      case SocialCacheType.sticker:
        return '🏷️';
      case SocialCacheType.cache:
        return '📦';
    }
  }
}

/// 社交应用缓存项
class SocialCacheItem {
  final String path;
  final String name;
  final int sizeBytes;
  final SocialApp app;
  final SocialCacheType type;
  final DateTime lastAccessed;
  bool isSelected;

  SocialCacheItem({
    required this.path,
    required this.name,
    required this.sizeBytes,
    required this.app,
    required this.type,
    required this.lastAccessed,
    this.isSelected = false,
  });

  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    if (sizeBytes < 1024 * 1024 * 1024) {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(sizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

/// 社交应用专清扫描服务
class SocialScanner {
  final Random _random = Random();

  /// 扫描社交应用缓存
  Future<Map<SocialApp, Map<SocialCacheType, List<SocialCacheItem>>>>
      scanSocialApps() async {
    await Future.delayed(const Duration(seconds: 2));

    return {
      SocialApp.wechat: _generateWeChatCache(),
      SocialApp.qq: _generateQQCache(),
      SocialApp.douyin: _generateDouyinCache(),
    };
  }

  Map<SocialCacheType, List<SocialCacheItem>> _generateWeChatCache() {
    return {
      SocialCacheType.image: List.generate(
        20,
        (i) => SocialCacheItem(
          path: '/storage/emulated/0/Android/data/com.tencent.mm/MicroMsg/image2/img_$i.jpg',
          name: '聊天图片_${i + 1}.jpg',
          sizeBytes: 200 * 1024 + _random.nextInt(3 * 1024 * 1024),
          app: SocialApp.wechat,
          type: SocialCacheType.image,
          lastAccessed: DateTime.now().subtract(Duration(days: _random.nextInt(60))),
          isSelected: true,
        ),
      ),
      SocialCacheType.video: List.generate(
        8,
        (i) => SocialCacheItem(
          path: '/storage/emulated/0/Android/data/com.tencent.mm/MicroMsg/video/vid_$i.mp4',
          name: '聊天视频_${i + 1}.mp4',
          sizeBytes: 5 * 1024 * 1024 + _random.nextInt(50 * 1024 * 1024),
          app: SocialApp.wechat,
          type: SocialCacheType.video,
          lastAccessed: DateTime.now().subtract(Duration(days: _random.nextInt(30))),
          isSelected: true,
        ),
      ),
      SocialCacheType.file: List.generate(
        10,
        (i) => SocialCacheItem(
          path: '/storage/emulated/0/Android/data/com.tencent.mm/MicroMsg/Download/file_$i',
          name: '接收文件_${i + 1}',
          sizeBytes: 1024 * 1024 + _random.nextInt(20 * 1024 * 1024),
          app: SocialApp.wechat,
          type: SocialCacheType.file,
          lastAccessed: DateTime.now().subtract(Duration(days: _random.nextInt(90))),
          isSelected: false,
        ),
      ),
      SocialCacheType.voice: List.generate(
        15,
        (i) => SocialCacheItem(
          path: '/storage/emulated/0/Android/data/com.tencent.mm/MicroMsg/voice/voice_$i.amr',
          name: '语音_${i + 1}.amr',
          sizeBytes: 50 * 1024 + _random.nextInt(500 * 1024),
          app: SocialApp.wechat,
          type: SocialCacheType.voice,
          lastAccessed: DateTime.now().subtract(Duration(days: _random.nextInt(30))),
          isSelected: true,
        ),
      ),
      SocialCacheType.emoji: List.generate(
        25,
        (i) => SocialCacheItem(
          path: '/storage/emulated/0/Android/data/com.tencent.mm/MicroMsg/emoji/emoji_$i.png',
          name: '表情_${i + 1}.png',
          sizeBytes: 10 * 1024 + _random.nextInt(200 * 1024),
          app: SocialApp.wechat,
          type: SocialCacheType.emoji,
          lastAccessed: DateTime.now().subtract(Duration(days: _random.nextInt(100))),
          isSelected: true,
        ),
      ),
      SocialCacheType.cache: List.generate(
        12,
        (i) => SocialCacheItem(
          path: '/storage/emulated/0/Android/data/com.tencent.mm/cache/cache_$i.dat',
          name: '缓存_${i + 1}.dat',
          sizeBytes: 500 * 1024 + _random.nextInt(10 * 1024 * 1024),
          app: SocialApp.wechat,
          type: SocialCacheType.cache,
          lastAccessed: DateTime.now().subtract(Duration(days: _random.nextInt(14))),
          isSelected: true,
        ),
      ),
    };
  }

  Map<SocialCacheType, List<SocialCacheItem>> _generateQQCache() {
    return {
      SocialCacheType.image: List.generate(
        18,
        (i) => SocialCacheItem(
          path: '/storage/emulated/0/Android/data/com.tencent.mobileqq/Tencent/QQ_Images/img_$i.jpg',
          name: '聊天图片_${i + 1}.jpg',
          sizeBytes: 150 * 1024 + _random.nextInt(2 * 1024 * 1024),
          app: SocialApp.qq,
          type: SocialCacheType.image,
          lastAccessed: DateTime.now().subtract(Duration(days: _random.nextInt(45))),
          isSelected: true,
        ),
      ),
      SocialCacheType.video: List.generate(
        5,
        (i) => SocialCacheItem(
          path: '/storage/emulated/0/Android/data/com.tencent.mobileqq/Tencent/QQ_Video/vid_$i.mp4',
          name: '聊天视频_${i + 1}.mp4',
          sizeBytes: 10 * 1024 * 1024 + _random.nextInt(80 * 1024 * 1024),
          app: SocialApp.qq,
          type: SocialCacheType.video,
          lastAccessed: DateTime.now().subtract(Duration(days: _random.nextInt(20))),
          isSelected: true,
        ),
      ),
      SocialCacheType.file: List.generate(
        12,
        (i) => SocialCacheItem(
          path: '/storage/emulated/0/Android/data/com.tencent.mobileqq/Tencent/QQfile_recv/file_$i',
          name: '接收文件_${i + 1}',
          sizeBytes: 512 * 1024 + _random.nextInt(50 * 1024 * 1024),
          app: SocialApp.qq,
          type: SocialCacheType.file,
          lastAccessed: DateTime.now().subtract(Duration(days: _random.nextInt(60))),
          isSelected: false,
        ),
      ),
      SocialCacheType.emoji: List.generate(
        30,
        (i) => SocialCacheItem(
          path: '/storage/emulated/0/Android/data/com.tencent.mobileqq/Tencent/QQ_Emoji/emoji_$i.png',
          name: 'QQ表情_${i + 1}.png',
          sizeBytes: 20 * 1024 + _random.nextInt(300 * 1024),
          app: SocialApp.qq,
          type: SocialCacheType.emoji,
          lastAccessed: DateTime.now().subtract(Duration(days: _random.nextInt(120))),
          isSelected: true,
        ),
      ),
      SocialCacheType.cache: List.generate(
        10,
        (i) => SocialCacheItem(
          path: '/storage/emulated/0/Android/data/com.tencent.mobileqq/cache/cache_$i.dat',
          name: '缓存_${i + 1}.dat',
          sizeBytes: 1024 * 1024 + _random.nextInt(15 * 1024 * 1024),
          app: SocialApp.qq,
          type: SocialCacheType.cache,
          lastAccessed: DateTime.now().subtract(Duration(days: _random.nextInt(10))),
          isSelected: true,
        ),
      ),
    };
  }

  Map<SocialCacheType, List<SocialCacheItem>> _generateDouyinCache() {
    return {
      SocialCacheType.video: List.generate(
        30,
        (i) => SocialCacheItem(
          path: '/storage/emulated/0/Android/data/com.ss.android.ugc.aweme/cache/video/vid_$i.mp4',
          name: '抖音缓存_${i + 1}.mp4',
          sizeBytes: 2 * 1024 * 1024 + _random.nextInt(10 * 1024 * 1024),
          app: SocialApp.douyin,
          type: SocialCacheType.video,
          lastAccessed: DateTime.now().subtract(Duration(days: _random.nextInt(7))),
          isSelected: true,
        ),
      ),
      SocialCacheType.cache: List.generate(
        20,
        (i) => SocialCacheItem(
          path: '/storage/emulated/0/Android/data/com.ss.android.ugc.aweme/cache/data_$i.dat',
          name: '应用缓存_${i + 1}.dat',
          sizeBytes: 500 * 1024 + _random.nextInt(5 * 1024 * 1024),
          app: SocialApp.douyin,
          type: SocialCacheType.cache,
          lastAccessed: DateTime.now().subtract(Duration(days: _random.nextInt(5))),
          isSelected: true,
        ),
      ),
    };
  }

  /// 删除选中的社交应用缓存
  Future<int> deleteSocialCache(List<SocialCacheItem> items) async {
    int freedBytes = 0;
    for (final item in items) {
      try {
        await Future.delayed(const Duration(milliseconds: 20));
        freedBytes += item.sizeBytes;
      } catch (e) {
        print('删除失败: ${item.path}');
      }
    }
    return freedBytes;
  }
}
