import 'dart:io';
import 'package:crypto/crypto.dart';
import '../models/duplicate_file.dart';

/// 重复文件扫描服务 - 基于 MD5 全文哈希的真实重复检测
class DuplicateScanner {
  /// 扫描重复文件（基于内容哈希）
  Future<List<DuplicateGroup>> scanDuplicates() async {
    final Map<String, List<DuplicateFile>> sizeGroups = {};
    final dirs = [
      '/storage/emulated/0/DCIM',
      '/storage/emulated/0/Pictures',
      '/storage/emulated/0/Download',
      '/storage/emulated/0/Documents',
      '/storage/emulated/0/Movies',
    ];

    // 第一步：按大小分组
    for (final dirPath in dirs) {
      final dir = Directory(dirPath);
      if (!await dir.exists()) continue;
      try {
        await _scanForSize(dirPath, sizeGroups);
      } catch (e) { /* skip */ }
    }

    // 第二步：对相同大小的文件计算 MD5 哈希，按哈希分组
    final Map<String, List<DuplicateFile>> hashGroups = {};
    for (final entry in sizeGroups.entries) {
      if (entry.value.length < 2) continue; // 只有1个文件不算重复
      
      for (final file in entry.value) {
        try {
          final hash = await _calculateHash(file.path);
          hashGroups.putIfAbsent(hash, () => []).add(file);
        } catch (e) {
          // 跳过无法读取的文件
        }
      }
    }

    // 第三步：构建结果（只保留真正重复的组）
    final List<DuplicateGroup> result = [];
    for (final entry in hashGroups.entries) {
      if (entry.value.length >= 2) {
        result.add(DuplicateGroup(
          hash: entry.key,
          fileSize: entry.value.first.sizeBytes,
          files: entry.value,
        ));
      }
    }

    result.sort((a, b) => b.wastedBytes.compareTo(a.wastedBytes));
    return result;
  }

  Future<void> _scanForSize(String dirPath, Map<String, List<DuplicateFile>> groups) async {
    final dir = Directory(dirPath);
    await for (final entity in dir.list(followLinks: false)) {
      if (entity is File) {
        try {
          final stat = await entity.stat();
          if (stat.size < 10240) continue; // 跳过 <10KB 小文件
          final key = stat.size.toString();
          groups.putIfAbsent(key, () => []).add(
            DuplicateFile(path: entity.path, name: entity.path.split('/').last, sizeBytes: stat.size, lastModified: stat.modified),
          );
        } catch (e) { /* skip */ }
      } else if (entity is Directory) {
        try { await _scanForSize(entity.path, groups); } catch (e) {}
      }
    }
  }

  Future<String> _calculateHash(String path) async {
    final stream = File(path).openRead();
    final hash = await md5.bind(stream).first;
    return hash.toString();
  }

  Future<String> calculateFileHash(String filePath) async => _calculateHash(filePath);

  Future<int> deleteDuplicates(List<DuplicateFile> files) async {
    int freed = 0;
    for (final file in files) {
      try { await File(file.path).delete(); freed += file.sizeBytes; } catch (e) {}
    }
    return freed;
  }
}
