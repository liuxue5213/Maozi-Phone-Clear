import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/junk_item.dart';

/// 扫描结果
class ScanResult {
  final List<CategorySummary> categories;
  final List<String> errors;
  final List<String> scannedDirs;
  final int totalFilesScanned;

  ScanResult({
    required this.categories,
    required this.errors,
    required this.scannedDirs,
    required this.totalFilesScanned,
  });

  int get totalBytes => categories.fold(0, (sum, cat) => sum + cat.totalSizeBytes);
  int get totalFiles => categories.fold(0, (sum, cat) => sum + cat.items.length);
}

/// 垃圾文件扫描服务 - 真实文件扫描
class ScannerService {
  /// 最大递归深度，防止栈溢出
  static const int _maxDepth = 8;

  /// 执行完整扫描，返回详细结果
  Future<ScanResult> scanAll() async {
    final List<JunkItem> allItems = [];
    final List<String> errors = [];
    final List<String> scannedDirs = [];
    int totalFilesScanned = 0;

    // 要扫描的目录
    final dirsToScan = [
      '/storage/emulated/0/Android/data',
      '/storage/emulated/0/Android/cache',
      '/storage/emulated/0/cache',
      '/storage/emulated/0/tmp',
      '/storage/emulated/0/Download',
      '/storage/emulated/0/DCIM',
      '/storage/emulated/0/Pictures',
      '/storage/emulated/0/Movies',
      '/storage/emulated/0/Documents',
    ];

    for (final dirPath in dirsToScan) {
      final dir = Directory(dirPath);
      final exists = await dir.exists();
      if (!exists) {
        errors.add('目录不存在: $dirPath');
        continue;
      }
      
      try {
        int filesInDir = 0;
        await _scanDir(dir, allItems, 0, filesInDir);
        scannedDirs.add('$dirPath ($filesInDir 个文件)');
        totalFilesScanned += filesInDir;
      } catch (e) {
        errors.add('无权限访问: $dirPath');
      }
    }

    // 按分类分组
    final Map<JunkCategory, List<JunkItem>> grouped = {};
    for (final item in allItems) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }

    return ScanResult(
      categories: grouped.entries
          .map((e) => CategorySummary(category: e.key, items: e.value))
          .toList(),
      errors: errors,
      scannedDirs: scannedDirs,
      totalFilesScanned: totalFilesScanned,
    );
  }

  Future<void> _scanDir(Directory dir, List<JunkItem> items, int depth, int fileCount) async {
    // 限制递归深度，避免栈溢出
    if (depth >= _maxDepth) return;
    
    await for (final entity in dir.list(followLinks: false)) {
      if (entity is File) {
        try {
          final stat = await entity.stat();
          final path = entity.path.toLowerCase();
          final ext = p.extension(path);
          
          JunkCategory? category;
          
          // 分类判断
          if (path.contains('/cache/') || path.contains('/caches/')) {
            category = JunkCategory.cache;
          } else if (ext == '.log' || path.contains('/logs/')) {
            category = JunkCategory.log;
          } else if (ext == '.tmp' || ext == '.temp' || path.contains('/tmp/')) {
            category = JunkCategory.temp;
          } else if (path.contains('/android/data/')) {
            category = JunkCategory.residual;
          } else if ((ext == '.apk') && path.contains('/download')) {
            category = JunkCategory.apk;
          }
          
          if (category != null) {
            items.add(JunkItem(
              path: entity.path,
              name: p.basename(entity.path),
              sizeBytes: stat.size,
              category: category,
              lastModified: stat.modified,
            ));
            fileCount++;
          }
        } catch (e) {
          // 跳过无权限文件
        }
      } else if (entity is Directory) {
        try {
          await _scanDir(entity, items, depth + 1, fileCount);
        } catch (e) {
          // 跳过无权限目录
        }
      }
    }
  }

  /// 执行清理：删除选中的文件
  Future<int> cleanSelected(List<JunkItem> selectedItems) async {
    int cleanedBytes = 0;
    for (final item in selectedItems) {
      try {
        final file = File(item.path);
        if (await file.exists()) {
          await file.delete();
          cleanedBytes += item.sizeBytes;
        }
      } catch (e) {
        print('删除失败: ${item.path} - $e');
      }
    }
    return cleanedBytes;
  }
}
