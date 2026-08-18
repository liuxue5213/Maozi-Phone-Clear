import 'dart:io';
import 'dart:math';

/// 视频压缩质量
enum VideoQuality {
  high,    // 高质量 (压缩率 20%)
  medium,  // 中等 (压缩率 40%)
  low,    // 低质量 (压缩率 60%)
}

extension VideoQualityExtension on VideoQuality {
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

  String get description {
    switch (this) {
      case VideoQuality.high:
        return '保留90%画质，节省20%空间';
      case VideoQuality.medium:
        return '保留70%画质，节省40%空间';
      case VideoQuality.low:
        return '保留50%画质，节省60%空间';
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
}

/// 视频文件信息
class VideoInfo {
  final String path;
  final String name;
  final int originalSizeBytes;
  final int durationSeconds;
  final int width;
  final int height;
  final double bitrate; // kbps
  final String codec;
  bool isSelected;

  VideoInfo({
    required this.path,
    required this.name,
    required this.originalSizeBytes,
    required this.durationSeconds,
    required this.width,
    required this.height,
    required this.bitrate,
    required this.codec,
    this.isSelected = false,
  });

  String get formattedSize => _formatBytes(originalSizeBytes);
  String get resolution => '${width}x$height';
  String get formattedDuration {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  /// 计算压缩后大小
  int compressedSize(VideoQuality quality) {
    return (originalSizeBytes * (1 - quality.compressionRatio)).toInt();
  }

  /// 计算可节省的空间
  int savedBytes(VideoQuality quality) {
    return originalSizeBytes - compressedSize(quality);
  }

  String formattedSaved(VideoQuality quality) {
    return _formatBytes(savedBytes(quality));
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

/// 视频压缩服务
class VideoCompressorService {
  final Random _random = Random();

  /// 扫描视频文件
  Future<List<VideoInfo>> scanVideos() async {
    await Future.delayed(const Duration(seconds: 2));
    return _generateMockVideos();
  }

  List<VideoInfo> _generateMockVideos() {
    return [
      VideoInfo(
        path: '/storage/emulated/0/DCIM/Camera/VID_20240801_1920x1080.mp4',
        name: 'VID_20240801.mp4',
        originalSizeBytes: 450 * 1024 * 1024,
        durationSeconds: 180,
        width: 1920,
        height: 1080,
        bitrate: 18000,
        codec: 'H.264',
      ),
      VideoInfo(
        path: '/storage/emulated/0/DCIM/Camera/VID_20240805_4K.mp4',
        name: 'VID_20240805_4K.mp4',
        originalSizeBytes: 2100 * 1024 * 1024,
        durationSeconds: 300,
        width: 3840,
        height: 2160,
        bitrate: 50000,
        codec: 'H.265',
      ),
      VideoInfo(
        path: '/storage/emulated/0/Movies/Recording/screen_rec_001.mp4',
        name: 'screen_rec_001.mp4',
        originalSizeBytes: 800 * 1024 * 1024,
        durationSeconds: 600,
        width: 1920,
        height: 1080,
        bitrate: 10000,
        codec: 'H.264',
      ),
      VideoInfo(
        path: '/storage/emulated/0/Download/tutorial_video.mp4',
        name: 'tutorial_video.mp4',
        originalSizeBytes: 350 * 1024 * 1024,
        durationSeconds: 900,
        width: 1280,
        height: 720,
        bitrate: 3000,
        codec: 'H.264',
      ),
      VideoInfo(
        path: '/storage/emulated/0/Movies/Download/movie_clip.mp4',
        name: 'movie_clip.mp4',
        originalSizeBytes: 1200 * 1024 * 1024,
        durationSeconds: 1200,
        width: 2560,
        height: 1440,
        bitrate: 35000,
        codec: 'H.265',
      ),
      VideoInfo(
        path: '/storage/emulated/0/DCIM/Camera/VID_20240810_short.mp4',
        name: 'VID_20240810_short.mp4',
        originalSizeBytes: 120 * 1024 * 1024,
        durationSeconds: 30,
        width: 1920,
        height: 1080,
        bitrate: 30000,
        codec: 'H.264',
      ),
      VideoInfo(
        path: '/storage/emulated/0/Movies/WhatChat_Video/wechat_001.mp4',
        name: 'wechat_001.mp4',
        originalSizeBytes: 85 * 1024 * 1024,
        durationSeconds: 60,
        width: 720,
        height: 1280,
        bitrate: 10000,
        codec: 'H.264',
      ),
    ];
  }

  /// 压缩视频（模拟）
  Future<int> compressVideos(List<VideoInfo> videos, VideoQuality quality) async {
    int totalSaved = 0;
    for (final video in videos) {
      // 模拟压缩耗时（每10MB约1秒）
      final compressTime = video.originalSizeBytes ~/ (10 * 1024 * 1024);
      await Future.delayed(Duration(milliseconds: compressTime * 100));
      totalSaved += video.savedBytes(quality);
    }
    return totalSaved;
  }
}
