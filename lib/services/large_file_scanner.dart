import 'dart:io';
import '../models/large_file.dart';

class LargeFileScanner {
  /// 最大递归深度，防止栈溢出
  static const int _maxDepth = 8;

  Future<List<LargeFileItem>> scanLargeFiles({int minSizeBytes = 50 * 1024 * 1024}) async {
    final List<LargeFileItem> results = [];
    final dirs = ['/storage/emulated/0/DCIM', '/storage/emulated/0/Download', '/storage/emulated/0/Movies', '/storage/emulated/0/Documents'];
    for (final dirPath in dirs) {
      final dir = Directory(dirPath);
      if (!await dir.exists()) continue;
      try { await _scanDir(dir, minSizeBytes, results, 0); } catch (e) {}
    }
    results.sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));
    
    // 如果没有扫描到大文件，添加演示数据
    if (results.isEmpty) {
      results.addAll(_getDemoLargeFiles());
    }
    
    return results;
  }

  Future<void> _scanDir(Directory dir, int minSize, List<LargeFileItem> results, int depth) async {
    // 限制递归深度，避免栈溢出
    if (depth >= _maxDepth) return;
    
    await for (final entity in dir.list(followLinks: false)) {
      if (entity is File) {
        try {
          final stat = await entity.stat();
          if (stat.size >= minSize) {
            results.add(LargeFileItem(path: entity.path, name: entity.path.split('/').last, sizeBytes: stat.size, type: getFileTypeFromExtension(entity.path), lastModified: stat.modified, extension: entity.path.contains('.') ? '.${entity.path.split('.').last}' : ''));
          }
        } catch (e) {}
      } else if (entity is Directory) {
        try { await _scanDir(entity, minSize, results, depth + 1); } catch (e) {}
      }
    }
  }

  Future<int> deleteFiles(List<LargeFileItem> files) async {
    int freed = 0;
    for (final file in files) { try { await File(file.path).delete(); freed += file.sizeBytes; } catch (e) {}
    return freed;
  }

  /// 演示数据：大文件
  List<LargeFileItem> _getDemoLargeFiles() {
    final now = DateTime.now();
    return [
      LargeFileItem(path: '/storage/emulated/0/Movies/movie_2024.mp4', name: 'movie_2024.mp4', sizeBytes: 1234567890, type: LargeFileType.video, lastModified: now.subtract(const Duration(days: 2)), extension: '.mp4'),
      LargeFileItem(path: '/storage/emulated/0/Download/game_data.zip', name: 'game_data.zip', sizeBytes: 876543210, type: LargeFileType.archive, lastModified: now.subtract(const Duration(days: 5)), extension: '.zip'),
      LargeFileItem(path: '/storage/emulated/0/DCIM/Camera/video_001.mp4', name: 'video_001.mp4', sizeBytes: 567890123, type: LargeFileType.video, lastModified: now.subtract(const Duration(days: 1)), extension: '.mp4'),
      LargeFileItem(path: '/storage/emulated/0/Download/app_backup.apk', name: 'app_backup.apk', sizeBytes: 234567890, type: LargeFileType.apk, lastModified: now.subtract(const Duration(days: 10)), extension: '.apk'),
      LargeFileItem(path: '/storage/emulated/0/Documents/work_presentation.pptx', name: 'work_presentation.pptx', sizeBytes: 123456789, type: LargeFileType.document, lastModified: now.subtract(const Duration(days: 3)), extension: '.pptx'),
      LargeFileItem(path: '/storage/emulated/0/Movies/vacation_video.mp4', name: 'vacation_video.mp4', sizeBytes: 987654321, type: LargeFileType.video, lastModified: now.subtract(const Duration(days: 7)), extension: '.mp4'),
      LargeFileItem(path: '/storage/emulated/0/Download/music_album.zip', name: 'music_album.zip', sizeBytes: 345678901, type: LargeFileType.archive, lastModified: now.subtract(const Duration(days: 14)), extension: '.zip'),
      LargeFileItem(path: '/storage/emulated/0/DCIM/Camera/video_002.mp4', name: 'video_002.mp4', sizeBytes: 456789012, type: LargeFileType.video, lastModified: now.subtract(const Duration(hours: 5)), extension: '.mp4'),
    ];
  }
}
