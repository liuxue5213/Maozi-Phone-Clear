import 'dart:io';
import '../utils/format_utils.dart';

/// 垃圾文件分类
enum JunkCategory {
  cache,
  log,
  temp,
  residual,
  apk,
  largeFile,
}

extension JunkCategoryExtension on JunkCategory {
  String get displayName {
    switch (this) {
      case JunkCategory.cache:
        return '应用缓存';
      case JunkCategory.log:
        return '日志文件';
      case JunkCategory.temp:
        return '临时文件';
      case JunkCategory.residual:
        return '残留文件';
      case JunkCategory.apk:
        return '安装包';
      case JunkCategory.largeFile:
        return '大文件';
    }
  }

  String get icon {
    switch (this) {
      case JunkCategory.cache:
        return '🗂️';
      case JunkCategory.log:
        return '📋';
      case JunkCategory.temp:
        return '🕐';
      case JunkCategory.residual:
        return '📁';
      case JunkCategory.apk:
        return '📦';
      case JunkCategory.largeFile:
        return '📄';
    }
  }
}

/// 单条垃圾文件数据模型
class JunkItem {
  final String path;
  final String name;
  final int sizeBytes;
  final JunkCategory category;
  final DateTime lastModified;
  bool isSelected;

  JunkItem({
    required this.path,
    required this.name,
    required this.sizeBytes,
    required this.category,
    required this.lastModified,
    this.isSelected = false,
  });

  /// 格式化文件大小显示
  String get formattedSize => FormatUtils.formatBytes(sizeBytes);

  /// 获取文件对象
  File get file => File(path);
}

/// 分类汇总
class CategorySummary {
  final JunkCategory category;
  final List<JunkItem> items;

  CategorySummary({required this.category, required this.items});

  int get totalSizeBytes => items.fold(0, (sum, item) => sum + item.sizeBytes);

  String get formattedTotalSize => FormatUtils.formatBytes(totalSizeBytes);

  int get selectedCount => items.where((item) => item.isSelected).length;

  int get selectedSizeBytes =>
      items.where((item) => item.isSelected).fold(0, (sum, item) => sum + item.sizeBytes);

  bool get allSelected => items.every((item) => item.isSelected);

  bool get partiallySelected =>
      items.any((item) => item.isSelected) && !allSelected;
}
