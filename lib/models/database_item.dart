import '../utils/format_utils.dart';

/// 数据库优化项
class DatabaseItem {
  final String appName;
  final String packageName;
  final String dbName;
  final int originalSizeBytes;
  final int wastedBytes;
  final String issue;
  bool isSelected;

  DatabaseItem({
    required this.appName,
    required this.packageName,
    required this.dbName,
    required this.originalSizeBytes,
    required this.wastedBytes,
    required this.issue,
    this.isSelected = false,
  });

  int get optimizedSizeBytes => originalSizeBytes - wastedBytes;

  String get formattedOriginalSize => FormatUtils.formatBytes(originalSizeBytes);
  String get formattedWastedSize => FormatUtils.formatBytes(wastedBytes);
  String get formattedOptimizedSize => FormatUtils.formatBytes(optimizedSizeBytes);
}
