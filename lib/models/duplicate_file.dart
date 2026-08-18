import 'dart:io';

/// 重复文件组
class DuplicateGroup {
  final String hash;
  final List<DuplicateFile> files;
  final int fileSize;

  DuplicateGroup({
    required this.hash,
    required this.files,
    required this.fileSize,
  });

  /// 总浪费空间 = (文件数 - 1) * 单文件大小
  int get wastedBytes => (files.length - 1) * fileSize;

  String get formattedWastedSize => _formatBytes(wastedBytes);
  String get formattedFileSize => _formatBytes(fileSize);

  /// 保留第一个，其余可清理
  List<DuplicateFile> get cleanableFiles => files.skip(1).toList();

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

/// 单个重复文件
class DuplicateFile {
  final String path;
  final String name;
  final int sizeBytes;
  final DateTime lastModified;
  bool isSelected;

  DuplicateFile({
    required this.path,
    required this.name,
    required this.sizeBytes,
    required this.lastModified,
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
}
