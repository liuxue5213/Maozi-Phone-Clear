import 'dart:io';

class VideoCompressorService {
  Future<List<VideoInfo>> scanVideos() async {
    final List<VideoInfo> videos = [];
    final dirs = ['/storage/emulated/0/DCIM', '/storage/emulated/0/Movies', '/storage/emulated/0/Download', '/storage/emulated/0/Video'];
    final videoExts = ['.mp4', '.avi', '.mkv', '.mov', '.wmv', '.flv', '.webm'];
    for (final dirPath in dirs) {
      final dir = Directory(dirPath);
      if (!await dir.exists()) continue;
      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          try {
            final ext = entity.path.toLowerCase().split('.').last;
            if (videoExts.contains('.$ext')) {
              final stat = await entity.stat();
              videos.add(VideoInfo(path: entity.path, name: entity.path.split('/').last, originalSizeBytes: stat.size, durationSeconds: 0, width: 0, height: 0, bitrate: 0, codec: ext.toUpperCase()));
            }
          } catch (_) {}
        }
      }
    }
    return videos;
  }

  Future<int> compressVideos(List<VideoInfo> videos) async {
    // 真实压缩需要 FFmpeg，这里返回估算值
    return videos.fold(0, (s, v) => s + (v.originalSizeBytes * 0.3).toInt());
  }
}

class VideoInfo {
  final String path; final String name; final int originalSizeBytes; final int durationSeconds; final int width; final int height; final int bitrate; final String codec;
  bool isSelected = true;
  VideoInfo({required this.path, required this.name, required this.originalSizeBytes, required this.durationSeconds, required this.width, required this.height, required this.bitrate, required this.codec});
  int compressedSize(int quality) => (originalSizeBytes * (1 - quality * 0.2)).toInt();
  int savedBytes(int quality) => originalSizeBytes - compressedSize(quality);
  String get formattedSize { if (originalSizeBytes < 1024*1024) return '${(originalSizeBytes/1024).toStringAsFixed(1)} KB'; return '${(originalSizeBytes/(1024*1024)).toStringAsFixed(1)} MB'; }
  String get formattedSaved { final s = (originalSizeBytes * 0.3).toInt(); if (s < 1024*1024) return '${(s/1024).toStringAsFixed(1)} KB'; return '${(s/(1024*1024)).toStringAsFixed(1)} MB'; }
}
