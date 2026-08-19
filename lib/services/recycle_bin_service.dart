import 'dart:convert';
import 'dart:io';
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

  /// 获取回收站存储目录
  static Future<Directory> _getRecycleBinDir() async {
    final recycleDir = Directory('/storage/emulated/0/.maozi_recycle_bin');
    if (!await recycleDir.exists()) {
      await recycleDir.create(recursive: true);
    }
    return recycleDir;
  }

  /// 添加文件到回收站（真实移动文件）
  Future<bool> addItemFromFile(String originalPath) async {
    try {
      final originalFile = File(originalPath);
      if (!await originalFile.exists()) return false;

      final recycleDir = await _getRecycleBinDir();
      final fileName = originalPath.split('/').last;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final recyclePath = '${recycleDir.path}/${timestamp}_$fileName';

      // 复制文件到回收站
      await originalFile.copy(recyclePath);
      // 删除原文件
      await originalFile.delete();

      // 记录到 SharedPreferences
      final stat = await File(recyclePath).stat();
      final item = RecycleBinItem(
        originalPath: originalPath,
        recyclePath: recyclePath,
        name: fileName,
        sizeBytes: stat.size,
        deletedAt: DateTime.now(),
        fileType: _getFileType(fileName),
      );

      final items = await getItems();
      items.insert(0, item);

      // 超过最大数量时删除最早的
      if (items.length > _maxItems) {
        final removed = items.sublist(_maxItems);
        for (final r in removed) {
          await _deleteFilePermanently(r.recyclePath);
        }
        items.removeRange(_maxItems, items.length);
      }

      await _saveItems(items);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 获取所有回收站文件
  Future<List<RecycleBinItem>> getItems() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_recycleBinKey);
    if (data == null) return [];
    final List<dynamic> list = jsonDecode(data);
    return list.map((e) => RecycleBinItem.fromJson(e)).toList();
  }

  /// 恢复文件（移出回收站，还原到原始位置）
  Future<bool> restoreItem(String recyclePath) async {
    try {
      final items = await getItems();
      final item = items.firstWhere((i) => i.recyclePath == recyclePath, orElse: () => throw Exception('文件未找到'));
      
      final recycleFile = File(recyclePath);
      if (!await recycleFile.exists()) {
        // 文件已不存在，只移除记录
        items.removeWhere((i) => i.recyclePath == recyclePath);
        await _saveItems(items);
        return false;
      }

      // 确保原始目录存在
      final originalDir = Directory(item.originalPath).parent;
      if (!await originalDir.exists()) {
        await originalDir.create(recursive: true);
      }

      // 复制文件回原始位置
      await recycleFile.copy(item.originalPath);
      // 删除回收站中的文件
      await recycleFile.delete();
      // 移除记录
      items.removeWhere((i) => i.recyclePath == recyclePath);
      await _saveItems(items);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 永久删除单个文件
  Future<bool> deletePermanently(String recyclePath) async {
    try {
      await _deleteFilePermanently(recyclePath);
      final items = await getItems();
      items.removeWhere((i) => i.recyclePath == recyclePath);
      await _saveItems(items);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 清空回收站
  Future<void> clearAll() async {
    final items = await getItems();
    for (final item in items) {
      await _deleteFilePermanently(item.recyclePath);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recycleBinKey);
  }

  /// 自动清理过期文件
  Future<int> cleanupExpired() async {
    final items = await getItems();
    final expired = items.where((item) => item.isExpired).toList();
    final valid = items.where((item) => !item.isExpired).toList();

    for (final item in expired) {
      await _deleteFilePermanently(item.recyclePath);
    }
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

  Future<void> _deleteFilePermanently(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // 忽略删除失败
    }
  }

  String _getFileType(String fileName) {
    final ext = fileName.toLowerCase().split('.').last;
    if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(ext)) return 'image';
    if (['mp4', 'avi', 'mkv', 'mov', 'wmv', 'flv', 'webm'].contains(ext)) return 'video';
    if (['mp3', 'wav', 'flac', 'aac', 'ogg', 'wma'].contains(ext)) return 'audio';
    if (['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt'].contains(ext)) return 'document';
    return 'other';
  }
}
