import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:photo_manager/photo_manager.dart';
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

    // 1. 使用 MediaStore 扫描媒体文件
    try {
      final mediaResult = await _scanMediaFiles();
      allItems.addAll(mediaResult.items);
      totalFilesScanned += mediaResult.fileCount;
      if (mediaResult.fileCount > 0) {
        scannedDirs.add('媒体文件 (${mediaResult.fileCount} 个)');
      }
    } catch (e) {
      errors.add('媒体文件扫描失败: $e');
    }

    // 2. 扫描文件系统目录
    final dirsToScan = [
      '/storage/emulated/0/Download',
      '/storage/emulated/0/DCIM',
      '/storage/emulated/0/Pictures',
      '/storage/emulated/0/Movies',
      '/storage/emulated/0/Documents',
      '/storage/emulated/0/Music',
      '/storage/emulated/0/Android/data',
      '/storage/emulated/0/Android/cache',
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
        if (filesInDir > 0) {
          scannedDirs.add('$dirPath ($filesInDir 个文件)');
        }
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

  /// 使用 MediaStore 扫描媒体文件
  Future<_MediaScanResult> _scanMediaFiles() async {
    final List<JunkItem> items = [];
    int fileCount = 0;

    // 请求权限
    final ps = await PhotoManager.requestPermissionExtend();
    if (!ps.isAuth && !ps.hasAccess) {
      return _MediaScanResult(items: items, fileCount: 0);
    }

    // 扫描图片
    final imagePaths = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: false,
    );
    for (final path in imagePaths) {
      final assets = await path.getAssetListPaged(page: 0, size: 1000);
      for (final asset in assets) {
        try {
          final file = await asset.file;
          if (file == null) continue;
          final stat = await file.stat();
          
          // 大图片可能是垃圾（超过5MB）
          if (stat.size > 5 * 1024 * 1024) {
            items.add(JunkItem(
              path: file.path,
              name: asset.title ?? file.path.split('/').last,
              sizeBytes: stat.size,
              category: JunkCategory.largeFile,
              lastModified: asset.createDateTime,
            ));
            fileCount++;
          }
        } catch (e) {}
      }
    }

    // 扫描视频（所有视频都算，因为占用空间大）
    final videoPaths = await PhotoManager.getAssetPathList(
      type: RequestType.video,
      onlyAll: false,
    );
    for (final path in videoPaths) {
      final assets = await path.getAssetListPaged(page: 0, size: 1000);
      for (final asset in assets) {
        try {
          final file = await asset.file;
          if (file == null) continue;
          final stat = await file.stat();
          
          // 视频文件（超过50MB算大文件）
          if (stat.size > 50 * 1024 * 1024) {
            items.add(JunkItem(
              path: file.path,
              name: asset.title ?? file.path.split('/').last,
              sizeBytes: stat.size,
              category: JunkCategory.largeFile,
              lastModified: asset.createDateTime,
            ));
            fileCount++;
          }
        } catch (e) {}
      }
    }

    return _MediaScanResult(items: items, fileCount: fileCount);
  }

  Future<void> _scanDir(Directory dir, List<JunkItem> items, int depth, int fileCount) async {
    if (depth >= _maxDepth) return;
    
    await for (final entity in dir.list(followLinks: false)) {
      if (entity is File) {
        try {
          final stat = await entity.stat();
          final path = entity.path.toLowerCase();
          final ext = p.extension(path);
          
          JunkCategory? category;
          
          // 分类判断 - 扩展更多类型
          if (path.contains('/cache/') || path.contains('/caches/')) {
            category = JunkCategory.cache;
          } else if (ext == '.log' || path.contains('/logs/')) {
            category = JunkCategory.log;
          } else if (ext == '.tmp' || ext == '.temp' || path.contains('/tmp/')) {
            category = JunkCategory.temp;
          } else if (path.contains('/android/data/')) {
            category = JunkCategory.residual;
          } else if (ext == '.apk') {
            category = JunkCategory.apk;
          } else if (stat.size > 100 * 1024 * 1024) {
            // 大于100MB的文件算大文件
            category = JunkCategory.largeFile;
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

class _MediaScanResult {
  final List<JunkItem> items;
  final int fileCount;
  _MediaScanResult({required this.items, required this.fileCount});
}
