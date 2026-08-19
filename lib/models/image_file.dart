import 'dart:io';
import '../utils/format_utils.dart';

/// 图片分类
enum ImageCategory {
  screenshot,    // 截图
  similar,       // 相似图片
  burst,         // 连拍/实况照片
  thumbnail,     // 缩略图
}

extension ImageCategoryExtension on ImageCategory {
  String get displayName {
    switch (this) {
      case ImageCategory.screenshot:
        return '截图';
      case ImageCategory.similar:
        return '相似图片';
      case ImageCategory.burst:
        return '连拍照片';
      case ImageCategory.thumbnail:
        return '缩略图';
    }
  }

  String get icon {
    switch (this) {
      case ImageCategory.screenshot:
        return '📸';
      case ImageCategory.similar:
        return '🖼️';
      case ImageCategory.burst:
        return '📷';
      case ImageCategory.thumbnail:
        return '🔍';
    }
  }
}

/// 图片文件项
class ImageFileItem {
  final String path;
  final String name;
  final int sizeBytes;
  final DateTime createdDate;
  final int width;
  final int height;
  final ImageCategory category;
  bool isSelected;

  ImageFileItem({
    required this.path,
    required this.name,
    required this.sizeBytes,
    required this.createdDate,
    required this.width,
    required this.height,
    required this.category,
    this.isSelected = false,
  });

  File get file => File(path);

  String get formattedSize => FormatUtils.formatBytes(sizeBytes);

  String get resolution => '${width}x$height';

  /// 格式化日期
  String get formattedDate => FormatUtils.formatDate(createdDate);
}

/// 相似图片组
class SimilarImageGroup {
  final List<ImageFileItem> images;

  SimilarImageGroup({required this.images});

  int get totalSizeBytes => images.fold(0, (sum, img) => sum + img.sizeBytes);

  String get formattedTotalSize => FormatUtils.formatBytes(totalSizeBytes);

  /// 保留最高清的，其余可清理
  /// 如果所有图片宽高都为0，则保留第一个
  ImageFileItem get bestImage {
    if (images.isEmpty) throw StateError('图片列表为空');
    // 过滤出有效尺寸的图片
    final validImages = images.where((img) => img.width > 0 && img.height > 0).toList();
    if (validImages.isEmpty) return images.first; // 都没有尺寸信息，保留第一个
    return validImages.reduce((a, b) => (a.width * a.height) > (b.width * b.height) ? a : b);
  }

  List<ImageFileItem> get cleanableImages =>
      images.where((img) => img.path != bestImage.path).toList();
}
