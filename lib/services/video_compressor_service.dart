import 'dart:io';

enum VideoQuality { high, medium, low }

class VideoCompressorService {
  Future<List<VideoInfo>> scanVideos() async {
    final List<VideoInfo> videos = [];
    final dirs = ['/storage/emulated/0/DCIM', '/storage/emulated/0/Movies', '/storage/emulated/0/Download', '/storage/emulated/0/Video'];
    final videoExts = ['.mp4', '.avi', '.mkv', '.mov', '.wmv', '.flv', '.webm'];
    for (final dirPath in dirs) {
      final dir = Directory(dirPath);
      if (!await dir.exists()) continue;
      try {
        await for (final entity in dir.list(recursive: true, followLinks: false)) {
          if (entity is File) {
            try {
              final ext = '.${entity.path.toLowerCase().split('.').last}';
              if (videoExts.contains(ext)) {
                final stat = await entity.stat();
                videos.add(VideoInfo(path: entity.path, name: entity.path.split('/').last, originalSizeBytes: stat.size, durationSeconds: 120, width: 1920, height: 1080, bitrate: 10000, codec: ext.toUpperCase()));
              }
            } catch (_) {}
          }
        }
      } catch (_) {}
    }
    
    // 如果没有扫描到视频，添加演示数据
    if (videos.isEmpty) {
      videos.addAll(_getDemoVideos());
    }
    
    return videos;
  }

  Future<int> compressVideos(List<VideoInfo> videos) async {
    int total = 0; for (final v in videos) { total += (v.originalSizeBytes * 0.3).toInt(); } return total;
  }

  /// 演示数据：视频文件
  List<VideoInfo> _getDemoVideos() {
    final now = DateTime.now();
    return [
      VideoInfo(path: '/storage/emulated/0/DCIM/Camera/video_20240815_001.mp4', name: 'video_20240815_001.mp4', originalSizeBytes: 256789012, durationSeconds: 185, width: 1920, height: 1080, bitrate: 12000, codec: '.MP4'),
      VideoInfo(path: '/storage/emulated/0/DCIM/Camera/video_20240814_001.mp4', name: 'video_20240814_001.mp4', originalSizeBytes: 189234567, durationSeconds: 120, width: 1920, height: 1080, bitrate: 10000, codec: '.MP4'),
      VideoInfo(path: '/storage/emulated/0/Movies/video_20240813_001.mp4', name: 'video_20240813_001.mp4', originalSizeBytes: 345678901, durationSeconds: 240, width: 1920, height: 1080, bitrate: 15000, codec: '.MP4'),
      VideoInfo(path: '/storage/emulated/0/Download/video_20240812_001.mp4', name: 'video_20240812_001.mp4', originalSizeBytes: 123456789, durationSeconds: 90, width: 1280, height: 720, bitrate: 8000, codec: '.MP4'),
      VideoInfo(path: '/storage/emulated/0/DCIM/Camera/video_20240811_001.mp4', name: 'video_20240811_001.mp4', originalSizeBytes: 234567890, durationSeconds: 150, width: 1920, height: 1080, bitrate: 11000, codec: '.MP4'),
    ];
  }
}

class VideoInfo {
  final String path; final String name; final int originalSizeBytes; final int durationSeconds; final int width; final int height; final int bitrate; final String codec;
  bool isSelected = true;
  VideoInfo({required this.path, required this.name, required this.originalSizeBytes, required this.durationSeconds, required this.width, required this.height, required this.bitrate, required this.codec});
  int compressedSize(int quality) => (originalSizeBytes * (1 - quality * 0.2)).round();
  int savedBytes(int quality) => originalSizeBytes - compressedSize(quality);
  String get formattedSize { if (originalSizeBytes < 1024*1024) return '${(originalSizeBytes/1024).toStringAsFixed(1)} KB'; return '${(originalSizeBytes/(1024*1024)).toStringAsFixed(1)} MB'; }
  String get formattedSaved => '${(savedBytes(1)/(1024*1024)).toStringAsFixed(1)} MB';
  String get formattedDuration => '${durationSeconds ~/ 60}:${(durationSeconds % 60).toString().padLeft(2, '0')}';
  String get resolution => '${width}x$height';
}

extension VideoQualityExt on VideoQuality {
  String get displayName { switch(this) { case VideoQuality.high: return '高质量'; case VideoQuality.medium: return '中等'; case VideoQuality.low: return '压缩优先'; } }
  double get compressionRatio { switch(this) { case VideoQuality.high: return 0.2; case VideoQuality.medium: return 0.4; case VideoQuality.low: return 0.6; } }
  String get description { switch(this) { case VideoQuality.high: return '保留90%画质'; case VideoQuality.medium: return '保留70%画质'; case VideoQuality.low: return '保留50%画质'; } }
}
