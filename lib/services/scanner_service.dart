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
  final String message;

  ScanResult({
    required this.categories,
    required this.errors,
    required this.scannedDirs,
    required this.totalFilesScanned,
    this.message = '',
  });

  int get totalBytes => categories.fold(0, (sum, cat) => sum + cat.totalSizeBytes);
  int get totalFiles => categories.fold(0, (sum, cat) => sum + cat.items.length);
}

/// 垃圾文件扫描服务
class ScannerService {
  static const int _maxDepth = 8;

  Future<ScanResult> scanAll() async {
    final List<JunkItem> allItems = [];
    final List<String> errors = [];
    final List<String> scannedDirs = [];
    int totalFilesScanned = 0;

    // 1. 使用 MediaStore 扫描所有可访问的文件
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

    // 2. 扫描可访问的文件系统目录
    final dirsToScan = [
      '/storage/emulated/0/Download',
      '/storage/emulated/0/DCIM',
      '/storage/emulated/0/Pictures',
      '/storage/emulated/0/Movies',
      '/storage/emulated/0/Documents',
      '/storage/emulated/0/Music',
    ];

    for (final dirPath in dirsToScan) {
      final dir = Directory(dirPath);
      final exists = await dir.exists();
      if (!exists) continue;
      
      try {
        final counter = [0];
        await _scanDir(dir, allItems, 0, counter);
        final fileCount = counter[0];
        if (fileCount > 0) {
          scannedDirs.add('$dirPath ($fileCount 个文件)');
        }
        totalFilesScanned += fileCount;
      } catch (e) {
        errors.add('无权限: $dirPath');
      }
    }

    // 按分类分组
    final Map<JunkCategory, List<JunkItem>> grouped = {};
    for (final item in allItems) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }

    String message = '';
    if (grouped.isEmpty) {
      message = '未发现可清理的文件。已扫描 ${totalFilesScanned} 个文件。';
    }

    return ScanResult(
      categories: grouped.entries
          .map((e) => CategorySummary(category: e.key, items: e.value))
          .toList(),
      errors: errors,
      scannedDirs: scannedDirs,
      totalFilesScanned: totalFilesScanned,
      message: message,
    );
  }

  Future<_MediaScanResult> _scanMediaFiles() async {
    final List<JunkItem> items = [];
    int fileCount = 0;

    final ps = await PhotoManager.requestPermissionExtend();
    if (!ps.isAuth && !ps.hasAccess) {
      return _MediaScanResult(items: items, fileCount: 0);
    }

    // 扫描图片（所有图片）
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
          
          // 所有图片都计入（用户可以选择清理）
          items.add(JunkItem(
            path: file.path,
            name: asset.title ?? file.path.split('/').last,
            sizeBytes: stat.size,
            category: JunkCategory.largeFile,
            lastModified: asset.createDateTime,
          ));
          fileCount++;
        } catch (e) {}
      }
    }

    // 扫描视频
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
          
          items.add(JunkItem(
            path: file.path,
            name: asset.title ?? file.path.split('/').last,
            sizeBytes: stat.size,
            category: JunkCategory.largeFile,
            lastModified: asset.createDateTime,
          ));
          fileCount++;
        } catch (e) {}
      }
    }

    return _MediaScanResult(items: items, fileCount: fileCount);
  }

  Future<void> _scanDir(Directory dir, List<JunkItem> items, int depth, List<int> counter) async {
    if (depth >= _maxDepth) return;
    
    await for (final entity in dir.list(followLinks: false)) {
      if (entity is File) {
        try {
          final stat = await entity.stat();
          final path = entity.path.toLowerCase();
          final ext = p.extension(path);
          
          JunkCategory? category;
          
          if (path.contains('/cache/') || path.contains('/caches/')) {
            category = JunkCategory.cache;
          } else if (ext == '.log' || path.contains('/logs/')) {
            category = JunkCategory.log;
          } else if (ext == '.tmp' || ext == '.temp' || path.contains('/tmp/')) {
            category = JunkCategory.temp;
          } else if (ext == '.apk') {
            category = JunkCategory.apk;
          } else if (stat.size > 50 * 1024 * 1024) {
            // 大于50MB
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
            counter[0]++;
          }
        } catch (e) {}
      } else if (entity is Directory) {
        try {
          await _scanDir(entity, items, depth + 1, counter);
        } catch (e) {}
      }
    }
  }

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
