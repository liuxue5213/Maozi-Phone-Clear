import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/junk_item.dart';

/// 垃圾文件扫描服务 - 真实文件扫描
class ScannerService {
  /// 执行完整扫描，返回按分类汇总的结果
  Future<List<CategorySummary>> scanAll() async {
    final List<JunkItem> allItems = [];

    // 要扫描的目录
    final dirsToScan = [
      '/storage/emulated/0/Android/data',
      '/storage/emulated/0/Android/cache',
      '/storage/emulated/0/cache',
      '/storage/emulated/0/tmp',
      '/storage/emulated/0/Download',
    ];

    for (final dirPath in dirsToScan) {
      final dir = Directory(dirPath);
      if (!await dir.exists()) continue;
      try {
        await _scanDir(dir, allItems);
      } catch (e) {
        // 跳过无权限目录
      }
    }

    // 按分类分组
    final Map<JunkCategory, List<JunkItem>> grouped = {};
    for (final item in allItems) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }

    return grouped.entries
        .map((e) => CategorySummary(category: e.key, items: e.value))
        .toList();
  }

  Future<void> _scanDir(Directory dir, List<JunkItem> items) async {
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
          }
        } catch (e) {
          // 跳过无权限文件
        }
      } else if (entity is Directory) {
        // 限制递归深度，避免栈溢出
        try {
          await _scanDir(entity, items);
        } catch (e) {
          // 跳过
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
