/// 格式化工具类
/// 提供文件大小格式化等通用功能
class FormatUtils {
  /// 格式化字节大小为人类可读格式
  /// 
  /// 示例：
  /// - 512 -> "512 B"
  /// - 1536 -> "1.5 KB"
  /// - 1572864 -> "1.5 MB"
  /// - 1073741824 -> "1.00 GB"
  static String formatBytes(int bytes) {
    if (bytes < 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// 格式化日期为 yyyy-MM-dd 格式
  static String formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// 格式化日期时间为 yyyy-MM-dd HH:mm 格式
  static String formatDateTime(DateTime date) {
    return '${formatDate(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
