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
    for (final file in files) { try { await File(file.path).delete(); freed += file.sizeBytes; } catch (e) {} }
    return freed;
  }
}
