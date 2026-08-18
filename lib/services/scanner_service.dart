import 'dart:io';
import 'dart:math';
import '../models/junk_item.dart';

/// 垃圾文件扫描服务
class ScannerService {
  final Random _random = Random();

  /// 执行完整扫描，返回按分类汇总的结果
  /// 实际项目中这里会遍历真实文件系统
  /// 当前为演示数据，展示完整扫描流程
  Future<List<CategorySummary>> scanAll() async {
    // 模拟扫描耗时
    await Future.delayed(const Duration(seconds: 2));

    final List<JunkItem> allItems = [];

    // 模拟各类垃圾文件
    allItems.addAll(_generateMockItems(JunkCategory.cache, 15, 512 * 1024, 50 * 1024 * 1024));
    allItems.addAll(_generateMockItems(JunkCategory.log, 8, 10 * 1024, 5 * 1024 * 1024));
    allItems.addAll(_generateMockItems(JunkCategory.temp, 12, 1024, 20 * 1024 * 1024));
    allItems.addAll(_generateMockItems(JunkCategory.residual, 5, 100 * 1024, 10 * 1024 * 1024));
    allItems.addAll(_generateMockItems(JunkCategory.apk, 3, 20 * 1024 * 1024, 200 * 1024 * 1024));
    allItems.addAll(_generateMockItems(JunkCategory.largeFile, 4, 100 * 1024 * 1024, 500 * 1024 * 1024));

    // 按分类分组
    final Map<JunkCategory, List<JunkItem>> grouped = {};
    for (final item in allItems) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }

    return grouped.entries
        .map((e) => CategorySummary(category: e.key, items: e.value))
        .toList();
  }

  /// 生成模拟垃圾文件数据
  List<JunkItem> _generateMockItems(
    JunkCategory category,
    int count,
    int minSize,
    int maxSize,
  ) {
    final List<String> names = _getMockFileNames(category);
    return List.generate(count, (i) {
      final size = minSize + _random.nextInt(maxSize - minSize);
      return JunkItem(
        path: '/storage/emulated/0/${_getCategoryPath(category)}/${names[i % names.length]}_$i',
        name: '${names[i % names.length]}_$i${_getCategoryExt(category)}',
        sizeBytes: size,
        category: category,
        lastModified: DateTime.now().subtract(Duration(days: _random.nextInt(30))),
      );
    });
  }

  List<String> _getMockFileNames(JunkCategory category) {
    switch (category) {
      case JunkCategory.cache:
        return ['cache_data', 'image_cache', 'web_cache', 'thumb', 'preload'];
      case JunkCategory.log:
        return ['crash_log', 'debug_log', 'error_log', 'analytics_log'];
      case JunkCategory.temp:
        return ['tmp_file', 'download_temp', 'extract_temp', 'backup_temp'];
      case JunkCategory.residual:
        return ['com.app.removed', 'old_data', 'obsolete_config'];
      case JunkCategory.apk:
        return ['app_install', 'update_package', 'downloaded_apk'];
      case JunkCategory.largeFile:
        return ['video_clip', 'screen_recording', 'large_download'];
    }
  }

  String _getCategoryPath(JunkCategory category) {
    switch (category) {
      case JunkCategory.cache:
        return 'Android/data/cache';
      case JunkCategory.log:
        return 'Android/data/logs';
      case JunkCategory.temp:
        return 'tmp';
      case JunkCategory.residual:
        return 'Android/data';
      case JunkCategory.apk:
        return 'Download';
      case JunkCategory.largeFile:
        return 'Movies';
    }
  }

  String _getCategoryExt(JunkCategory category) {
    switch (category) {
      case JunkCategory.cache:
        return '.cache';
      case JunkCategory.log:
        return '.log';
      case JunkCategory.temp:
        return '.tmp';
      case JunkCategory.residual:
        return '';
      case JunkCategory.apk:
        return '.apk';
      case JunkCategory.largeFile:
        return '.mp4';
    }
  }

  /// 执行清理：删除选中的文件
  /// 返回成功删除的总字节数
  Future<int> cleanSelected(List<JunkItem> selectedItems) async {
    int cleanedBytes = 0;
    for (final item in selectedItems) {
      try {
        // 实际项目中执行真实文件删除
        // final file = File(item.path);
        // if (await file.exists()) {
        //   await file.delete();
        //   cleanedBytes += item.sizeBytes;
        // }
        
        // 模拟删除耗时
        await Future.delayed(const Duration(milliseconds: 50));
        cleanedBytes += item.sizeBytes;
      } catch (e) {
        // 记录删除失败的文件
        print('删除失败: ${item.path} - $e');
      }
    }
    return cleanedBytes;
  }
}
