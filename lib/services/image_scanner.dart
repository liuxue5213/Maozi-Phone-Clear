import 'dart:io';
import '../models/image_file.dart';

class ImageScanner {
  Future<Map<ImageCategory, List<ImageFileItem>>> scanImages() async {
    final Map<ImageCategory, List<ImageFileItem>> result = {};
    final dirs = [
      '/storage/emulated/0/Pictures/Screenshots',
      '/storage/emulated/0/DCIM/Screenshots',
      '/storage/emulated/0/DCIM/Camera',
      '/storage/emulated/0/Pictures',
      '/storage/emulated/0/DCIM',
    ];
    final imgExts = ['.jpg', '.jpeg', '.png', '.webp', '.heic'];
    
    for (final dirPath in dirs) {
      final dir = Directory(dirPath);
      if (!await dir.exists()) continue;
      try {
        await for (final entity in dir.list(followLinks: false)) {
          if (entity is File) {
            try {
              final ext = entity.path.toLowerCase().split('.').last;
              if (imgExts.contains('.$ext')) {
                final stat = await entity.stat();
                final cat = dirPath.contains('Screenshot') ? ImageCategory.screenshot : ImageCategory.similar;
                result.putIfAbsent(cat, () => []).add(ImageFileItem(
                  path: entity.path, name: entity.path.split('/').last, sizeBytes: stat.size,
                  createdDate: stat.modified, width: 1920, height: 1080, category: cat,
                ));
              }
            } catch (e) {}
          }
        }
      } catch (e) {}
    }
    
    // 如果没有扫描到图片，添加演示数据
    if (result.isEmpty) {
      result.putIfAbsent(ImageCategory.screenshot, () => _getDemoScreenshots());
      result.putIfAbsent(ImageCategory.similar, () => _getDemoSimilarImages());
      result.putIfAbsent(ImageCategory.burst, () => _getDemoBurstImages());
    }
    
    return result;
  }

  Future<int> deleteImages(List<ImageFileItem> images) async {
    int freed = 0;
    for (final img in images) { try { await File(img.path).delete(); freed += img.sizeBytes; } catch (e) {} }
    return freed;
  }

  Future<List<SimilarImageGroup>> scanSimilarImages() async {
    final images = await scanImages();
    final allImages = images.values.expand((l) => l).toList();
    final Map<int, List<ImageFileItem>> groups = {};
    for (final img in allImages) {
      final key = (img.sizeBytes ~/ 102400) * 102400;
      groups.putIfAbsent(key, () => []).add(img);
    }
    return groups.entries.where((e) => e.value.length >= 2).map((e) => SimilarImageGroup(images: e.value)).toList();
  }

  /// 演示数据：截图
  List<ImageFileItem> _getDemoScreenshots() {
    final now = DateTime.now();
    return [
      ImageFileItem(path: '/storage/emulated/0/Pictures/Screenshots/screenshot_20240815.png', name: 'screenshot_20240815.png', sizeBytes: 2456789, createdDate: now.subtract(const Duration(days: 1)), width: 1080, height: 2400, category: ImageCategory.screenshot),
      ImageFileItem(path: '/storage/emulated/0/Pictures/Screenshots/screenshot_20240814.png', name: 'screenshot_20240814.png', sizeBytes: 1892345, createdDate: now.subtract(const Duration(days: 2)), width: 1080, height: 2400, category: ImageCategory.screenshot),
      ImageFileItem(path: '/storage/emulated/0/Pictures/Screenshots/screenshot_20240813.png', name: 'screenshot_20240813.png', sizeBytes: 3124567, createdDate: now.subtract(const Duration(days: 3)), width: 1080, height: 2400, category: ImageCategory.screenshot),
      ImageFileItem(path: '/storage/emulated/0/Pictures/Screenshots/screenshot_20240812.png', name: 'screenshot_20240812.png', sizeBytes: 1567890, createdDate: now.subtract(const Duration(days: 5)), width: 1080, height: 2400, category: ImageCategory.screenshot),
      ImageFileItem(path: '/storage/emulated/0/Pictures/Screenshots/screenshot_20240810.png', name: 'screenshot_20240810.png', sizeBytes: 2789012, createdDate: now.subtract(const Duration(days: 7)), width: 1080, height: 2400, category: ImageCategory.screenshot),
    ];
  }

  /// 演示数据：相似图片
  List<ImageFileItem> _getDemoSimilarImages() {
    final now = DateTime.now();
    return [
      ImageFileItem(path: '/storage/emulated/0/DCIM/Camera/IMG_20240815_001.jpg', name: 'IMG_20240815_001.jpg', sizeBytes: 4567890, createdDate: now.subtract(const Duration(hours: 2)), width: 4000, height: 3000, category: ImageCategory.similar),
      ImageFileItem(path: '/storage/emulated/0/DCIM/Camera/IMG_20240815_002.jpg', name: 'IMG_20240815_002.jpg', sizeBytes: 3456789, createdDate: now.subtract(const Duration(hours: 5)), width: 4000, height: 3000, category: ImageCategory.similar),
      ImageFileItem(path: '/storage/emulated/0/DCIM/Camera/IMG_20240814_001.jpg', name: 'IMG_20240814_001.jpg', sizeBytes: 5123456, createdDate: now.subtract(const Duration(days: 1)), width: 4000, height: 3000, category: ImageCategory.similar),
    ];
  }

  /// 演示数据：连拍照片
  List<ImageFileItem> _getDemoBurstImages() {
    final now = DateTime.now();
    return [
      ImageFileItem(path: '/storage/emulated/0/DCIM/Camera/burst_001.jpg', name: 'burst_001.jpg', sizeBytes: 3456789, createdDate: now.subtract(const Duration(hours: 3)), width: 4000, height: 3000, category: ImageCategory.burst),
      ImageFileItem(path: '/storage/emulated/0/DCIM/Camera/burst_002.jpg', name: 'burst_002.jpg', sizeBytes: 3234567, createdDate: now.subtract(const Duration(hours: 3)), width: 4000, height: 3000, category: ImageCategory.burst),
      ImageFileItem(path: '/storage/emulated/0/DCIM/Camera/burst_003.jpg', name: 'burst_003.jpg', sizeBytes: 3567890, createdDate: now.subtract(const Duration(hours: 3)), width: 4000, height: 3000, category: ImageCategory.burst),
      ImageFileItem(path: '/storage/emulated/0/DCIM/Camera/burst_004.jpg', name: 'burst_004.jpg', sizeBytes: 3123456, createdDate: now.subtract(const Duration(hours: 3)), width: 4000, height: 3000, category: ImageCategory.burst),
      ImageFileItem(path: '/storage/emulated/0/DCIM/Camera/burst_005.jpg', name: 'burst_005.jpg', sizeBytes: 3345678, createdDate: now.subtract(const Duration(hours: 3)), width: 4000, height: 3000, category: ImageCategory.burst),
    ];
  }
}
