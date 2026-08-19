import 'package:photo_manager/photo_manager.dart';

enum VideoQuality { high, medium, low }

class VideoCompressorService {
  /// 扫描视频 - 使用 MediaStore API (photo_manager)
  Future<List<VideoInfo>> scanVideos() async {
    final List<VideoInfo> videos = [];

    // 请求权限
    final ps = await PhotoManager.requestPermissionExtend();
    if (!ps.isAuth && !ps.hasAccess) {
      return videos;
    }

    // 使用 MediaStore 查询视频
    final assetPaths = await PhotoManager.getAssetPathList(
      type: RequestType.video,
      onlyAll: false,
    );

    for (final path in assetPaths) {
      final assets = await path.getAssetListPaged(page: 0, size: 1000);
      
      for (final asset in assets) {
        try {
          final file = await asset.file;
          if (file == null) continue;

          final stat = await file.stat();
          final fileName = asset.title ?? file.path.split('/').last;

          videos.add(VideoInfo(
            path: file.path,
            name: fileName,
            originalSizeBytes: stat.size,
            durationSeconds: asset.duration,
            width: asset.width,
            height: asset.height,
            bitrate: 0,
            codec: file.path.split('.').last.toUpperCase(),
          ));
        } catch (e) {
          // 跳过无法读取的文件
        }
      }
    }

    return videos;
  }

  Future<int> compressVideos(List<VideoInfo> videos) async {
    int total = 0;
    for (final v in videos) {
      total += (v.originalSizeBytes * 0.3).toInt();
    }
    return total;
  }
}

class VideoInfo {
  final String path;
  final String name;
  final int originalSizeBytes;
  final int durationSeconds;
  final int width;
  final int height;
  final int bitrate;
  final String codec;
  bool isSelected = true;

  VideoInfo({
    required this.path,
    required this.name,
    required this.originalSizeBytes,
    required this.durationSeconds,
    required this.width,
    required this.height,
    required this.bitrate,
    required this.codec,
  });

  int compressedSize(int quality) => (originalSizeBytes * (1 - quality * 0.2)).round();
  int savedBytes(int quality) => originalSizeBytes - compressedSize(quality);

  String get formattedSize {
    if (originalSizeBytes < 1024 * 1024) {
      return '${(originalSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(originalSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get formattedSaved => '${(savedBytes(1) / (1024 * 1024)).toStringAsFixed(1)} MB';
  String get formattedDuration => '${durationSeconds ~/ 60}:${(durationSeconds % 60).toString().padLeft(2, '0')}';
  String get resolution => '${width}x$height';
}

extension VideoQualityExt on VideoQuality {
  String get displayName {
    switch (this) {
      case VideoQuality.high:
        return '高质量';
      case VideoQuality.medium:
        return '中等';
      case VideoQuality.low:
        return '压缩优先';
    }
  }

  double get compressionRatio {
    switch (this) {
      case VideoQuality.high:
        return 0.2;
      case VideoQuality.medium:
        return 0.4;
      case VideoQuality.low:
        return 0.6;
    }
  }

  String get description {
    switch (this) {
      case VideoQuality.high:
        return '保留90%画质';
      case VideoQuality.medium:
        return '保留70%画质';
      case VideoQuality.low:
        return '保留50%画质';
    }
  }
}
