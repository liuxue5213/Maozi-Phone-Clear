import 'dart:io';
import 'dart:math';
import '../models/image_file.dart';

/// 图片清理扫描服务
class ImageScanner {
  final Random _random = Random();

  /// 扫描可清理的图片
  Future<Map<ImageCategory, List<ImageFileItem>>> scanImages() async {
    await Future.delayed(const Duration(seconds: 2));
    return _generateMockImages();
  }

  /// 扫描相似图片组
  Future<List<SimilarImageGroup>> scanSimilarImages() async {
    await Future.delayed(const Duration(seconds: 1));
    return _generateMockSimilarGroups();
  }

  Map<ImageCategory, List<ImageFileItem>> _generateMockImages() {
    final Map<ImageCategory, List<ImageFileItem>> result = {};

    // 截图
    result[ImageCategory.screenshot] = [
      ImageFileItem(
        path: '/storage/emulated/0/Pictures/Screenshots/Screenshot_20240801.png',
        name: 'Screenshot_20240801.png',
        sizeBytes: 512 * 1024,
        createdDate: DateTime(2024, 8, 1),
        width: 1080,
        height: 2400,
        category: ImageCategory.screenshot,
      ),
      ImageFileItem(
        path: '/storage/emulated/0/Pictures/Screenshots/Screenshot_20240805.png',
        name: 'Screenshot_20240805.png',
        sizeBytes: 480 * 1024,
        createdDate: DateTime(2024, 8, 5),
        width: 1080,
        height: 2400,
        category: ImageCategory.screenshot,
      ),
      ImageFileItem(
        path: '/storage/emulated/0/Pictures/Screenshots/Screenshot_20240810.png',
        name: 'Screenshot_20240810.png',
        sizeBytes: 620 * 1024,
        createdDate: DateTime(2024, 8, 10),
        width: 1080,
        height: 2400,
        category: ImageCategory.screenshot,
      ),
      ImageFileItem(
        path: '/storage/emulated/0/Pictures/Screenshots/Screenshot_20240812.png',
        name: 'Screenshot_20240812.png',
        sizeBytes: 390 * 1024,
        createdDate: DateTime(2024, 8, 12),
        width: 1080,
        height: 2400,
        category: ImageCategory.screenshot,
      ),
      ImageFileItem(
        path: '/storage/emulated/0/Pictures/Screenshots/Screenshot_20240815.png',
        name: 'Screenshot_20240815.png',
        sizeBytes: 550 * 1024,
        createdDate: DateTime(2024, 8, 15),
        width: 1080,
        height: 2400,
        category: ImageCategory.screenshot,
      ),
    ];

    // 缩略图
    result[ImageCategory.thumbnail] = [
      ImageFileItem(
        path: '/storage/emulated/0/DCIM/.thumbnails/thumb_001.jpg',
        name: 'thumb_001.jpg',
        sizeBytes: 25 * 1024,
        createdDate: DateTime(2024, 7, 1),
        width: 150,
        height: 150,
        category: ImageCategory.thumbnail,
      ),
      ImageFileItem(
        path: '/storage/emulated/0/DCIM/.thumbnails/thumb_002.jpg',
        name: 'thumb_002.jpg',
        sizeBytes: 30 * 1024,
        createdDate: DateTime(2024, 7, 5),
        width: 150,
        height: 150,
        category: ImageCategory.thumbnail,
      ),
      ImageFileItem(
        path: '/storage/emulated/0/Android/data/com.android.gallery3d/cache/thumb_003.jpg',
        name: 'thumb_003.jpg',
        sizeBytes: 20 * 1024,
        createdDate: DateTime(2024, 7, 10),
        width: 120,
        height: 120,
        category: ImageCategory.thumbnail,
      ),
    ];

    // 连拍照片（保留最佳一张，其余可清理）
    result[ImageCategory.burst] = [
      ImageFileItem(
        path: '/storage/emulated/0/DCIM/Camera/burst_001_001.jpg',
        name: 'burst_001_001.jpg (最佳)',
        sizeBytes: 4 * 1024 * 1024,
        createdDate: DateTime(2024, 8, 8, 14, 30, 1),
        width: 4000,
        height: 3000,
        category: ImageCategory.burst,
      ),
      ImageFileItem(
        path: '/storage/emulated/0/DCIM/Camera/burst_001_002.jpg',
        name: 'burst_001_002.jpg',
        sizeBytes: 3 * 1024 * 1024,
        createdDate: DateTime(2024, 8, 8, 14, 30, 2),
        width: 4000,
        height: 3000,
        category: ImageCategory.burst,
      ),
      ImageFileItem(
        path: '/storage/emulated/0/DCIM/Camera/burst_001_003.jpg',
        name: 'burst_001_003.jpg',
        sizeBytes: 3 * 1024 * 1024,
        createdDate: DateTime(2024, 8, 8, 14, 30, 3),
        width: 4000,
        height: 3000,
        category: ImageCategory.burst,
      ),
      ImageFileItem(
        path: '/storage/emulated/0/DCIM/Camera/burst_002_001.jpg',
        name: 'burst_002_001.jpg (最佳)',
        sizeBytes: 5 * 1024 * 1024,
        createdDate: DateTime(2024, 8, 12, 10, 15, 1),
        width: 4000,
        height: 3000,
        category: ImageCategory.burst,
      ),
      ImageFileItem(
        path: '/storage/emulated/0/DCIM/Camera/burst_002_002.jpg',
        name: 'burst_002_002.jpg',
        sizeBytes: 3 * 1024 * 1024,
        createdDate: DateTime(2024, 8, 12, 10, 15, 2),
        width: 4000,
        height: 3000,
        category: ImageCategory.burst,
      ),
    ];

    return result;
  }

  List<SimilarImageGroup> _generateMockSimilarGroups() {
    return [
      SimilarImageGroup(images: [
        ImageFileItem(
          path: '/storage/emulated/0/DCIM/Camera/IMG_001.jpg',
          name: 'IMG_001.jpg',
          sizeBytes: 4 * 1024 * 1024,
          createdDate: DateTime(2024, 8, 1),
          width: 4000,
          height: 3000,
          category: ImageCategory.similar,
        ),
        ImageFileItem(
          path: '/storage/emulated/0/Pictures/Edited/IMG_001_edited.jpg',
          name: 'IMG_001_edited.jpg',
          sizeBytes: 2 * 1024 * 1024,
          createdDate: DateTime(2024, 8, 2),
          width: 2000,
          height: 1500,
          category: ImageCategory.similar,
        ),
      ]),
      SimilarImageGroup(images: [
        ImageFileItem(
          path: '/storage/emulated/0/DCIM/Camera/IMG_002.jpg',
          name: 'IMG_002.jpg',
          sizeBytes: 5 * 1024 * 1024,
          createdDate: DateTime(2024, 8, 5),
          width: 4000,
          height: 3000,
          category: ImageCategory.similar,
        ),
        ImageFileItem(
          path: '/storage/emulated/0/SavedPictures/IMG_002_share.jpg',
          name: 'IMG_002_share.jpg',
          sizeBytes: 1 * 1024 * 1024,
          createdDate: DateTime(2024, 8, 6),
          width: 1080,
          height: 810,
          category: ImageCategory.similar,
        ),
        ImageFileItem(
          path: '/storage/emulated/0/Pictures/WeChat/IMG_002_compressed.jpg',
          name: 'IMG_002_compressed.jpg',
          sizeBytes: 500 * 1024,
          createdDate: DateTime(2024, 8, 6),
          width: 720,
          height: 540,
          category: ImageCategory.similar,
        ),
      ]),
    ];
  }

  /// 删除选中的图片文件
  Future<int> deleteImages(List<ImageFileItem> images) async {
    int freedBytes = 0;
    for (final img in images) {
      try {
        // 实际项目中执行真实删除
        // await img.file.delete();
        await Future.delayed(const Duration(milliseconds: 30));
        freedBytes += img.sizeBytes;
      } catch (e) {
        print('删除失败: ${img.path}');
      }
    }
    return freedBytes;
  }
}
