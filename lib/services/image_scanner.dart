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
    ];
    final imgExts = ['.jpg', '.jpeg', '.png', '.webp', '.heic'];
    
    for (final dirPath in dirs) {
      final dir = Directory(dirPath);
      if (!await dir.exists()) continue;
      await for (final entity in dir.list(followLinks: false)) {
        if (entity is File) {
          try {
            final ext = entity.path.toLowerCase().split('.').last;
            if (imgExts.contains('.$ext')) {
              final stat = await entity.stat();
              final cat = dirPath.contains('Screenshot') ? ImageCategory.screenshot : ImageCategory.similar;
              result.putIfAbsent(cat, () => []).add(ImageFileItem(
                path: entity.path, name: entity.path.split('/').last, sizeBytes: stat.size,
                createdDate: stat.modified, width: 0, height: 0, category: cat, // 注意：真实实现需要 image_size_getter 包读取尺寸
              ));
            }
          } catch (e) {}
        }
      }
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
}
