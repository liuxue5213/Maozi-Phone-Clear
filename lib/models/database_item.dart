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

  String get formattedOriginalSize => _formatBytes(originalSizeBytes);
  String get formattedWastedSize => _formatBytes(wastedBytes);
  String get formattedOptimizedSize => _formatBytes(optimizedSizeBytes);

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
