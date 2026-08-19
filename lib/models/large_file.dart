import 'dart:io';

/// 大文件类型
enum LargeFileType {
  video,
  audio,
  image,
  document,
  archive,
  apk,
  other,
}

/// 根据扩展名获取文件类型
LargeFileType getFileTypeFromExtension(String ext) {
  const videoExts = ['.mp4', '.avi', '.mkv', '.mov', '.wmv', '.flv', '.webm', '.m4v', '.3gp'];
  const audioExts = ['.mp3', '.wav', '.flac', '.aac', '.ogg', '.wma', '.m4a'];
  const imageExts = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp', '.heic', '.heif'];
  const docExts = ['.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx', '.txt', '.epub'];
  const archiveExts = ['.zip', '.rar', '.7z', '.tar', '.gz', '.bz2'];

  final lower = ext.toLowerCase();
  if (videoExts.contains(lower)) return LargeFileType.video;
  if (audioExts.contains(lower)) return LargeFileType.audio;
  if (imageExts.contains(lower)) return LargeFileType.image;
  if (docExts.contains(lower)) return LargeFileType.document;
  if (archiveExts.contains(lower)) return LargeFileType.archive;
  if (lower == '.apk') return LargeFileType.apk;
  return LargeFileType.other;
}

extension LargeFileTypeExtension on LargeFileType {
  String get displayName {
    switch (this) {
      case LargeFileType.video:
        return '视频';
      case LargeFileType.audio:
        return '音频';
      case LargeFileType.image:
        return '图片';
      case LargeFileType.document:
        return '文档';
      case LargeFileType.archive:
        return '压缩包';
      case LargeFileType.apk:
        return '安装包';
      case LargeFileType.other:
        return '其他';
    }
  }

  String get icon {
    switch (this) {
      case LargeFileType.video:
        return '🎬';
      case LargeFileType.audio:
        return '🎵';
      case LargeFileType.image:
        return '🖼️';
      case LargeFileType.document:
        return '📄';
      case LargeFileType.archive:
        return '🗜️';
      case LargeFileType.apk:
        return '📦';
      case LargeFileType.other:
        return '📁';
    }
  }

}

/// 大文件项
class LargeFileItem {
  final String path;
  final String name;
  final int sizeBytes;
  final LargeFileType type;
  final DateTime lastModified;
  final String extension;
  bool isSelected;

  LargeFileItem({
    required this.path,
    required this.name,
    required this.sizeBytes,
    required this.type,
    required this.lastModified,
    required this.extension,
    this.isSelected = false,
  });

  File get file => File(path);

  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    if (sizeBytes < 1024 * 1024 * 1024) {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(sizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// 格式化日期
  String get formattedDate {
    final now = DateTime.now();
    final diff = now.difference(lastModified);
    if (diff.inDays == 0) return '今天';
    if (diff.inDays == 1) return '昨天';
    if (diff.inDays < 7) return '${diff.inDays} 天前';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} 周前';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()} 月前';
    return '${(diff.inDays / 365).floor()} 年前';
  }
}
