import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 回收站文件项
class RecycleBinItem {
  final String originalPath;
  final String recyclePath;    // 回收站中的存储路径
  final String name;
  final int sizeBytes;
  final DateTime deletedAt;
  final String fileType;       // 文件类型标识

  RecycleBinItem({
    required this.originalPath,
    required this.recyclePath,
    required this.name,
    required this.sizeBytes,
    required this.deletedAt,
    required this.fileType,
  });

  Map<String, dynamic> toJson() => {
        'originalPath': originalPath,
        'recyclePath': recyclePath,
        'name': name,
        'sizeBytes': sizeBytes,
        'deletedAt': deletedAt.toIso8601String(),
        'fileType': fileType,
      };

  factory RecycleBinItem.fromJson(Map<String, dynamic> json) {
    return RecycleBinItem(
      originalPath: json['originalPath'],
      recyclePath: json['recyclePath'],
      name: json['name'],
      sizeBytes: json['sizeBytes'],
      deletedAt: DateTime.parse(json['deletedAt']),
      fileType: json['fileType'],
    );
  }

  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    if (sizeBytes < 1024 * 1024 * 1024) {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(sizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// 获取过期天数（默认7天后自动清理）
  int get daysUntilExpiry {
    final expiryDate = deletedAt.add(const Duration(days: 7));
    return expiryDate.difference(DateTime.now()).inDays;
  }

  bool get isExpired =>
      DateTime.now().difference(deletedAt).inDays >= 7;
}

/// 回收站服务
class RecycleBinService {
  static const String _recycleBinKey = 'recycle_bin_v2';
  static const int _maxItems = 100;  // 最大保留数量

  /// 获取所有回收站文件
  Future<List<RecycleBinItem>> getItems() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_recycleBinKey);
    if (data == null) return [];
    final List<dynamic> list = jsonDecode(data);
    return list.map((e) => RecycleBinItem.fromJson(e)).toList();
  }

  /// 添加文件到回收站
  Future<void> addItem(RecycleBinItem item) async {
    final items = await getItems();
    items.insert(0, item);

    // 超过最大数量时删除最早的
    if (items.length > _maxItems) {
      items.removeRange(_maxItems, items.length);
    }

    await _saveItems(items);
  }

  /// 恢复文件（移出回收站）
  Future<void> restoreItem(String recyclePath) async {
    final items = await getItems();
    items.removeWhere((item) => item.recyclePath == recyclePath);
    await _saveItems(items);
  }

  /// 永久删除单个文件
  Future<void> deletePermanently(String recyclePath) async {
    final items = await getItems();
    items.removeWhere((item) => item.recyclePath == recyclePath);
    await _saveItems(items);
  }

  /// 清空回收站
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recycleBinKey);
  }

  /// 自动清理过期文件
  Future<int> cleanupExpired() async {
    final items = await getItems();
    final expired = items.where((item) => item.isExpired).toList();
    final valid = items.where((item) => !item.isExpired).toList();

    await _saveItems(valid);

    // 返回释放的字节数
    return expired.fold<int>(0, (sum, item) => sum + item.sizeBytes);
  }

  /// 获取回收站总大小
  Future<int> getTotalSize() async {
    final items = await getItems();
    return items.fold<int>(0, (sum, item) => sum + item.sizeBytes);
  }

  Future<void> _saveItems(List<RecycleBinItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(items.map((e) => e.toJson()).toList());
    await prefs.setString(_recycleBinKey, data);
  }
}
