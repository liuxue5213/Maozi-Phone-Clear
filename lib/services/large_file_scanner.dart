import 'dart:io';
import 'dart:math';
import 'package:path/path.dart' as p;
import '../models/large_file.dart';

/// 大文件扫描服务
class LargeFileScanner {
  final Random _random = Random();

  /// 扫描大文件（默认阈值 50MB）
  Future<List<LargeFileItem>> scanLargeFiles({int minSizeBytes = 50 * 1024 * 1024}) async {
    await Future.delayed(const Duration(seconds: 2));
    return _generateMockLargeFiles();
  }

  List<LargeFileItem> _generateMockLargeFiles() {
    final List<LargeFileItem> files = [];

    // 视频文件
    files.addAll([
      LargeFileItem(
        path: '/storage/emulated/0/Movies/Recording/screen_record_2024.mp4',
        name: 'screen_record_2024.mp4',
        sizeBytes: 450 * 1024 * 1024,
        type: LargeFileType.video,
        lastModified: DateTime(2024, 7, 15),
        extension: '.mp4',
      ),
      LargeFileItem(
        path: '/storage/emulated/0/DCIM/Camera/vacation_2024.mov',
        name: 'vacation_2024.mov',
        sizeBytes: 1200 * 1024 * 1024,
        type: LargeFileType.video,
        lastModified: DateTime(2024, 6, 20),
        extension: '.mov',
      ),
      LargeFileItem(
        path: '/storage/emulated/0/Movies/Download/movie_backup.mp4',
        name: 'movie_backup.mp4',
        sizeBytes: 2100 * 1024 * 1024,
        type: LargeFileType.video,
        lastModified: DateTime(2024, 5, 1),
        extension: '.mp4',
      ),
      LargeFileItem(
        path: '/storage/emulated/0/Download/tutorial.mkv',
        name: 'tutorial.mkv',
        sizeBytes: 800 * 1024 * 1024,
        type: LargeFileType.video,
        lastModified: DateTime(2024, 4, 10),
        extension: '.mkv',
      ),
    ]);

    // 音频文件
    files.addAll([
      LargeFileItem(
        path: '/storage/emulated/0/Music/flac_collection/symphony.flac',
        name: 'symphony.flac',
        sizeBytes: 65 * 1024 * 1024,
        type: LargeFileType.audio,
        lastModified: DateTime(2024, 3, 1),
        extension: '.flac',
      ),
      LargeFileItem(
        path: '/storage/emulated/0/Music/download/concert_recording.wav',
        name: 'concert_recording.wav',
        sizeBytes: 120 * 1024 * 1024,
        type: LargeFileType.audio,
        lastModified: DateTime(2024, 2, 15),
        extension: '.wav',
      ),
    ]);

    // 压缩包
    files.addAll([
      LargeFileItem(
        path: '/storage/emulated/0/Download/project_files.zip',
        name: 'project_files.zip',
        sizeBytes: 350 * 1024 * 1024,
        type: LargeFileType.archive,
        lastModified: DateTime(2024, 8, 1),
        extension: '.zip',
      ),
      LargeFileItem(
        path: '/storage/emulated/0/Download/backup_2024.7z',
        name: 'backup_2024.7z',
        sizeBytes: 600 * 1024 * 1024,
        type: LargeFileType.archive,
        lastModified: DateTime(2024, 7, 1),
        extension: '.7z',
      ),
    ]);

    // 安装包
    files.addAll([
      LargeFileItem(
        path: '/storage/emulated/0/Download/game_mod.apk',
        name: 'game_mod.apk',
        sizeBytes: 180 * 1024 * 1024,
        type: LargeFileType.apk,
        lastModified: DateTime(2024, 8, 10),
        extension: '.apk',
      ),
      LargeFileItem(
        path: '/storage/emulated/0/Download/old_app.apk',
        name: 'old_app.apk',
        sizeBytes: 85 * 1024 * 1024,
        type: LargeFileType.apk,
        lastModified: DateTime(2024, 6, 1),
        extension: '.apk',
      ),
    ]);

    // 文档
    files.addAll([
      LargeFileItem(
        path: '/storage/emulated/0/Documents/work/presentation_final.pptx',
        name: 'presentation_final.pptx',
        sizeBytes: 75 * 1024 * 1024,
        type: LargeFileType.document,
        lastModified: DateTime(2024, 8, 5),
        extension: '.pptx',
      ),
      LargeFileItem(
        path: '/storage/emulated/0/Download/course_materials.pdf',
        name: 'course_materials.pdf',
        sizeBytes: 95 * 1024 * 1024,
        type: LargeFileType.document,
        lastModified: DateTime(2024, 7, 20),
        extension: '.pdf',
      ),
    ]);

    // 按大小降序排序
    files.sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));
    return files;
  }

  /// 实际文件系统扫描（生产环境使用）
  Future<List<LargeFileItem>> _scanDirectory(Directory dir, int minSizeBytes) async {
    final List<LargeFileItem> results = [];
    try {
      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          try {
            final stat = await entity.stat();
            if (stat.size >= minSizeBytes) {
              final ext = p.extension(entity.path);
              results.add(LargeFileItem(
                path: entity.path,
                name: p.basename(entity.path),
                sizeBytes: stat.size,
                type: getFileTypeFromExtension(ext),
                lastModified: stat.modified,
                extension: ext,
              ));
            }
          } catch (e) {
            // 跳过无权限文件
          }
        }
      }
    } catch (e) {
      // 跳过无权限目录
    }
    results.sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));
    return results;
  }

  /// 删除选中的大文件
  Future<int> deleteFiles(List<LargeFileItem> files) async {
    int freedBytes = 0;
    for (final file in files) {
      try {
        // 实际项目中执行真实删除
        // await file.file.delete();
        await Future.delayed(const Duration(milliseconds: 50));
        freedBytes += file.sizeBytes;
      } catch (e) {
        print('删除失败: ${file.path}');
      }
    }
    return freedBytes;
  }
}
