import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

/// 文件预览对话框
class FilePreviewDialog extends StatelessWidget {
  final String filePath;
  final String fileName;
  final int sizeBytes;
  final DateTime lastModified;
  final VoidCallback? onDelete;

  const FilePreviewDialog({
    super.key,
    required this.filePath,
    required this.fileName,
    required this.sizeBytes,
    required this.lastModified,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isImage = _isImageFile(filePath);
    final isVideo = _isVideoFile(filePath);
    final isAudio = _isAudioFile(filePath);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题栏
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      fileName,
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            // 预览区域
            Flexible(
              child: Container(
                width: double.infinity,
                color: Colors.black,
                child: _buildPreview(isImage, isVideo, isAudio),
              ),
            ),
            // 文件信息
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoRow('路径', filePath),
                  const SizedBox(height: 6),
                  _infoRow('大小', _formatBytes(sizeBytes)),
                  const SizedBox(height: 6),
                  _infoRow('修改时间', _formatDate(lastModified)),
                  const SizedBox(height: 6),
                  _infoRow('类型', p.extension(filePath).toUpperCase()),
                ],
              ),
            ),
            // 操作按钮
            if (onDelete != null)
              Container(
                padding: EdgeInsets.only(left: 16, right: 16, bottom: 16, top: MediaQuery.of(context).padding.bottom),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _openWithExternal(context),
                        icon: const Icon(Icons.open_in_new, size: 18),
                        label: const Text('用其他应用打开'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          onDelete?.call();
                        },
                        icon: const Icon(Icons.delete, size: 18),
                        label: const Text('删除'),
                        style: FilledButton.styleFrom(backgroundColor: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview(bool isImage, bool isVideo, bool isAudio) {
    if (isImage) {
      return _buildImagePreview();
    } else if (isVideo) {
      return _buildVideoPreview();
    } else if (isAudio) {
      return _buildAudioPreview();
    } else {
      return _buildGenericPreview();
    }
  }

  Widget _buildImagePreview() {
    final file = File(filePath);
    if (!file.existsSync()) {
      return const Center(child: Icon(Icons.broken_image, size: 80, color: Colors.white54));
    }
    return InteractiveViewer(
      child: Image.file(
        file,
        fit: BoxFit.contain,
        errorBuilder: (c, e, s) => const Center(child: Icon(Icons.broken_image, size: 80, color: Colors.white54)),
      ),
    );
  }

  Widget _buildVideoPreview() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.videocam, size: 80, color: Colors.white54),
          const SizedBox(height: 12),
          Text(p.extension(filePath).toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildAudioPreview() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.audiotrack, size: 80, color: Colors.white54),
          SizedBox(height: 12),
          Text('音频文件', style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildGenericPreview() {
    final ext = p.extension(filePath).toLowerCase();
    IconData icon = Icons.insert_drive_file;
    if (['.pdf'].contains(ext)) icon = Icons.picture_as_pdf;
    else if (['.doc', '.docx'].contains(ext)) icon = Icons.description;
    else if (['.xls', '.xlsx'].contains(ext)) icon = Icons.table_chart;
    else if (['.ppt', '.pptx'].contains(ext)) icon = Icons.slideshow;
    else if (['.zip', '.rar', '.7z'].contains(ext)) icon = Icons.archive;
    else if (['.apk'].contains(ext)) icon = Icons.android;
    else if (['.txt'].contains(ext)) icon = Icons.text_snippet;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.white54),
          const SizedBox(height: 12),
          Text(ext.toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 70, child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600]))),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis, maxLines: 2)),
      ],
    );
  }

  bool _isImageFile(String path) {
    final ext = path.toLowerCase();
    return ext.endsWith('.jpg') || ext.endsWith('.jpeg') || ext.endsWith('.png') ||
           ext.endsWith('.gif') || ext.endsWith('.webp') || ext.endsWith('.bmp') ||
           ext.endsWith('.heic') || ext.endsWith('.heif');
  }

  bool _isVideoFile(String path) {
    final ext = path.toLowerCase();
    return ext.endsWith('.mp4') || ext.endsWith('.avi') || ext.endsWith('.mkv') ||
           ext.endsWith('.mov') || ext.endsWith('.wmv') || ext.endsWith('.flv') ||
           ext.endsWith('.webm') || ext.endsWith('.3gp');
  }

  bool _isAudioFile(String path) {
    final ext = path.toLowerCase();
    return ext.endsWith('.mp3') || ext.endsWith('.wav') || ext.endsWith('.flac') ||
           ext.endsWith('.aac') || ext.endsWith('.ogg') || ext.endsWith('.m4a') ||
           ext.endsWith('.amr') || ext.endsWith('.wma');
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _openWithExternal(BuildContext context) {
    // 实际实现需要 platform channel 调用系统文件管理器
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('打开文件: $filePath')),
    );
  }

  /// 显示文件预览对话框
  static Future<void> show(
    BuildContext context, {
    required String filePath,
    required String fileName,
    required int sizeBytes,
    required DateTime lastModified,
    VoidCallback? onDelete,
  }) {
    return showDialog(
      context: context,
      builder: (context) => FilePreviewDialog(
        filePath: filePath,
        fileName: fileName,
        sizeBytes: sizeBytes,
        lastModified: lastModified,
        onDelete: onDelete,
      ),
    );
  }
}

/// 文件预览卡片（用于列表中）
class FilePreviewCard extends StatelessWidget {
  final String filePath;
  final String fileName;
  final int sizeBytes;
  final DateTime lastModified;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onSelectedChanged;

  const FilePreviewCard({
    super.key,
    required this.filePath,
    required this.fileName,
    required this.sizeBytes,
    required this.lastModified,
    required this.isSelected,
    required this.onTap,
    this.onSelectedChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isImage = _isImageFile(filePath);
    final isVideo = _isVideoFile(filePath);

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: () => FilePreviewDialog.show(
          context,
          filePath: filePath,
          fileName: fileName,
          sizeBytes: sizeBytes,
          lastModified: lastModified,
        ),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              // 缩略图
              _buildThumbnail(isImage, isVideo),
              const SizedBox(width: 12),
              // 文件信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fileName, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(_formatBytes(sizeBytes), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFFE91E63))),
                        const SizedBox(width: 8),
                        Text(_formatDate(lastModified), style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                      ],
                    ),
                  ],
                ),
              ),
              // 复选框
              Checkbox(value: isSelected, onChanged: (_) => onSelectedChanged?.call()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(bool isImage, bool isVideo) {
    if (isImage) {
      final file = File(filePath);
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.file(file, width: 48, height: 48, fit: BoxFit.cover, errorBuilder: (c, e, s) => _thumbIcon(Icons.image)),
        );
      }
    }
    if (isVideo) return _thumbIcon(Icons.videocam);
    return _thumbIcon(Icons.insert_drive_file);
  }

  Widget _thumbIcon(IconData icon) {
    return Container(width: 48, height: 48, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(6)), child: Icon(icon, size: 24, color: Colors.grey[400]));
  }

  bool _isImageFile(String path) {
    final ext = path.toLowerCase();
    return ext.endsWith('.jpg') || ext.endsWith('.jpeg') || ext.endsWith('.png') || ext.endsWith('.gif') || ext.endsWith('.webp');
  }

  bool _isVideoFile(String path) {
    final ext = path.toLowerCase();
    return ext.endsWith('.mp4') || ext.endsWith('.avi') || ext.endsWith('.mkv') || ext.endsWith('.mov');
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}';
  }
}
