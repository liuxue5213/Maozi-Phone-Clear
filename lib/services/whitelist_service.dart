import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 白名单/安全机制服务
/// 防止误删重要文件
class WhitelistService {
  static const String _whitelistKey = 'cleanup_whitelist';
  static const String _recycleBinKey = 'recycle_bin';

  /// 默认保护目录（系统关键路径）
  /// 注意：不包含 Android/data 等正常清理目录，避免与清理功能冲突
  static const List<String> protectedPaths = [
    '/storage/emulated/0/Android/obb',  // 游戏数据包，清理会导致游戏无法运行
    '/data',
    '/system',
  ];

  /// 受保护的文件扩展名（关键文件类型）
  static const List<String> protectedExtensions = [
    '.nomedia',
  ];

  /// 获取用户自定义白名单
  Future<List<String>> getWhitelist() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_whitelistKey);
    if (data == null) return [];
    return List<String>.from(jsonDecode(data));
  }

  /// 添加路径到白名单
  Future<void> addToWhitelist(String path) async {
    final whitelist = await getWhitelist();
    if (!whitelist.contains(path)) {
      whitelist.add(path);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_whitelistKey, jsonEncode(whitelist));
    }
  }

  /// 从白名单移除
  Future<void> removeFromWhitelist(String path) async {
    final whitelist = await getWhitelist();
    whitelist.remove(path);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_whitelistKey, jsonEncode(whitelist));
  }

  /// 检查路径是否被保护
  Future<bool> isProtected(String path) async {
    // 检查默认保护目录
    for (final protected in protectedPaths) {
      if (path.startsWith(protected)) return true;
    }

    // 检查用户自定义白名单
    final whitelist = await getWhitelist();
    for (final item in whitelist) {
      if (path.startsWith(item) || path == item) return true;
    }

    return false;
  }

  /// 回收站 - 记录被删除的文件（用于恢复）
  Future<void> addToRecycleBin(String originalPath, int sizeBytes) async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_recycleBinKey);
    List<Map<String, dynamic>> bin = [];
    if (data != null) {
      bin = List<Map<String, dynamic>>.from(jsonDecode(data));
    }
    bin.add({
      'path': originalPath,
      'sizeBytes': sizeBytes,
      'deletedAt': DateTime.now().toIso8601String(),
    });
    await prefs.setString(_recycleBinKey, jsonEncode(bin));
  }

  /// 获取回收站内容
  Future<List<Map<String, dynamic>>> getRecycleBin() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_recycleBinKey);
    if (data == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(data));
  }

  /// 清空回收站
  Future<void> clearRecycleBin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recycleBinKey);
  }

  /// 清理过期回收站（超过 7 天自动清除记录）
  Future<void> cleanupExpiredRecycleBin() async {
    final bin = await getRecycleBin();
    final now = DateTime.now();
    final valid = bin.where((item) {
      final deletedAt = DateTime.parse(item['deletedAt']);
      return now.difference(deletedAt).inDays < 7;
    }).toList();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_recycleBinKey, jsonEncode(valid));
  }
}
