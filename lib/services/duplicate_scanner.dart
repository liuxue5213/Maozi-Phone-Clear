import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import '../models/duplicate_file.dart';

/// 重复文件扫描服务
class DuplicateScanner {
  final Random _random = Random();

  /// 扫描重复文件
  /// 实际项目中会遍历文件系统，先按大小分组，再对同大小文件计算哈希
  Future<List<DuplicateGroup>> scanDuplicates() async {
    await Future.delayed(const Duration(seconds: 2));

    // 模拟扫描到的重复文件组
    return _generateMockDuplicates();
  }

  List<DuplicateGroup> _generateMockDuplicates() {
    final List<DuplicateGroup> groups = [];

    // 模拟组1：重复的照片
    groups.add(DuplicateGroup(
      hash: 'md5_photo_001',
      fileSize: 3 * 1024 * 1024,
      files: [
        DuplicateFile(
          path: '/storage/emulated/0/DCIM/Camera/IMG_20240101_001.jpg',
          name: 'IMG_20240101_001.jpg',
          sizeBytes: 3 * 1024 * 1024,
          lastModified: DateTime(2024, 1, 1),
          isSelected: false,
        ),
        DuplicateFile(
          path: '/storage/emulated/0/Download/IMG_20240101_001_copy.jpg',
          name: 'IMG_20240101_001_copy.jpg',
          sizeBytes: 3 * 1024 * 1024,
          lastModified: DateTime(2024, 1, 5),
          isSelected: true,
        ),
        DuplicateFile(
          path: '/storage/emulated/0/Pictures/Saved/IMG_20240101_001.png',
          name: 'IMG_20240101_001.png',
          sizeBytes: 3 * 1024 * 1024,
          lastModified: DateTime(2024, 2, 1),
          isSelected: true,
        ),
      ],
    ));

    // 模拟组2：重复的视频
    groups.add(DuplicateGroup(
      hash: 'md5_video_002',
      fileSize: 50 * 1024 * 1024,
      files: [
        DuplicateFile(
          path: '/storage/emulated/0/DCIM/Camera/VID_20240315.mp4',
          name: 'VID_20240315.mp4',
          sizeBytes: 50 * 1024 * 1024,
          lastModified: DateTime(2024, 3, 15),
          isSelected: false,
        ),
        DuplicateFile(
          path: '/storage/emulated/0/Movies/backup/VID_20240315.mp4',
          name: 'VID_20240315.mp4',
          sizeBytes: 50 * 1024 * 1024,
          lastModified: DateTime(2024, 3, 16),
          isSelected: true,
        ),
      ],
    ));

    // 模拟组3：重复的文档
    groups.add(DuplicateGroup(
      hash: 'md5_doc_003',
      fileSize: 2 * 1024 * 1024,
      files: [
        DuplicateFile(
          path: '/storage/emulated/0/Documents/work/report_2024.pdf',
          name: 'report_2024.pdf',
          sizeBytes: 2 * 1024 * 1024,
          lastModified: DateTime(2024, 6, 1),
          isSelected: false,
        ),
        DuplicateFile(
          path: '/storage/emulated/0/Download/report_2024.pdf',
          name: 'report_2024.pdf',
          sizeBytes: 2 * 1024 * 1024,
          lastModified: DateTime(2024, 6, 10),
          isSelected: true,
        ),
        DuplicateFile(
          path: '/storage/emulated/0/Documents/backup/report_2024_old.pdf',
          name: 'report_2024_old.pdf',
          sizeBytes: 2 * 1024 * 1024,
          lastModified: DateTime(2024, 5, 20),
          isSelected: true,
        ),
        DuplicateFile(
          path: '/storage/emulated/0/Downloads/report_final.pdf',
          name: 'report_final.pdf',
          sizeBytes: 2 * 1024 * 1024,
          lastModified: DateTime(2024, 7, 1),
          isSelected: true,
        ),
      ],
    ));

    // 模拟组4：重复的音乐
    groups.add(DuplicateGroup(
      hash: 'md5_audio_004',
      fileSize: 5 * 1024 * 1024,
      files: [
        DuplicateFile(
          path: '/storage/emulated/0/Music/artist/song.mp3',
          name: 'song.mp3',
          sizeBytes: 5 * 1024 * 1024,
          lastModified: DateTime(2024, 4, 1),
          isSelected: false,
        ),
        DuplicateFile(
          path: '/storage/emulated/0/Music/download/song.mp3',
          name: 'song.mp3',
          sizeBytes: 5 * 1024 * 1024,
          lastModified: DateTime(2024, 4, 5),
          isSelected: true,
        ),
      ],
    ));

    // 模拟组5：重复的压缩包
    groups.add(DuplicateGroup(
      hash: 'md5_archive_005',
      fileSize: 100 * 1024 * 1024,
      files: [
        DuplicateFile(
          path: '/storage/emulated/0/Download/project.zip',
          name: 'project.zip',
          sizeBytes: 100 * 1024 * 1024,
          lastModified: DateTime(2024, 8, 1),
          isSelected: false,
        ),
        DuplicateFile(
          path: '/storage/emulated/0/Download/project (1).zip',
          name: 'project (1).zip',
          sizeBytes: 100 * 1024 * 1024,
          lastModified: DateTime(2024, 8, 2),
          isSelected: true,
        ),
      ],
    ));

    return groups;
  }

  /// 实际文件哈希计算（生产环境使用）
  Future<String> calculateFileHash(String filePath) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    return md5.convert(bytes).toString();
  }

  /// 删除选中的重复文件
  Future<int> deleteDuplicates(List<DuplicateFile> files) async {
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
