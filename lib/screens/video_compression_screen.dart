import 'package:flutter/material.dart';
import '../utils/format_utils.dart';import '../services/video_compressor_service.dart';

/// 视频压缩页面
class VideoCompressionScreen extends StatefulWidget {
  const VideoCompressionScreen({super.key});

  @override
  State<VideoCompressionScreen> createState() => _VideoCompressionScreenState();
}

class _VideoCompressionScreenState extends State<VideoCompressionScreen> {
  final VideoCompressorService _service = VideoCompressorService();
  List<VideoInfo> _videos = [];
  bool _isLoading = true;
  bool _isCompressing = false;
  double _progress = 0.0;
  VideoQuality _quality = VideoQuality.medium;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    setState(() => _isLoading = true);
    final videos = await _service.scanVideos();

    if (!mounted) return;
    setState(() {
      _videos = videos;
      _isLoading = false;
    });
  }

  Future<void> _compressSelected() async {
    final selected = _videos.where((v) => v.isSelected).toList();
    if (selected.isEmpty) return;

    final totalSaved = selected.fold<int>(0, (sum, v) => sum + v.savedBytes(_quality.index + 1));

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认压缩'),
        content: Text(
          '将对 ${selected.length} 个视频进行压缩\n'
          '压缩质量: ${_quality.displayName}\n'
          '预计节省: ${FormatUtils.formatBytes(totalSaved)}\n\n'
          '注意: 压缩后原视频将被覆盖',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('开始压缩'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isCompressing = true;
      _progress = 0.0;
    });

    int saved = 0;
    for (int i = 0; i < selected.length; i++) {
      await Future.delayed(const Duration(milliseconds: 300));
      saved += selected[i].savedBytes(_quality.index + 1);
      setState(() => _progress = (i + 1) / selected.length);
    }
    await _service.compressVideos(selected);

    setState(() {
      _isCompressing = false;
      _progress = 0;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('压缩完成！节省 ${FormatUtils.formatBytes(saved)}'),
          backgroundColor: const Color(0xFF4CAF50),
        ),
      );
    }
    _loadVideos();
  }

  int get _totalSavedBytes {
    return _videos
        .where((v) => v.isSelected)
        .fold<int>(0, (sum, v) => sum + v.savedBytes(_quality.index + 1));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          '视频压缩',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF2196F3),
        elevation: 0,
        actions: [
          if (!_isLoading && !_isCompressing)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _loadVideos,
            ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_videos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.video_library_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('没有找到视频文件', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('下载或录制一些视频后再来吧', style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      );
    }

    return Column(
      children: [
        // 压缩质量选择
        _buildQualitySelector(),

        // 汇总
        _buildSummary(),

        // 视频列表
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _videos.length,
            itemBuilder: (context, index) {
              return _buildVideoCard(_videos[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQualitySelector() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '压缩质量',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: VideoQuality.values.map((q) {
              final isSelected = q == _quality;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _quality = q),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF2196F3)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF2196F3)
                            : Colors.grey[300]!,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          q.displayName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${(q.compressionRatio * 100).toInt()}%压缩',
                          style: TextStyle(
                            fontSize: 11,
                            color: isSelected ? Colors.white70 : Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 4),
          Text(
            _quality.description,
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    final selectedCount = _videos.where((v) => v.isSelected).length;
    final totalSize = _videos.fold<int>(0, (sum, v) => sum + v.originalSizeBytes);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFF9800),
            const Color(0xFFFF9800).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Text(
                '$selectedCount',
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text('${_videos.length} 个视频', style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
          Container(width: 1, height: 40, color: Colors.white24),
          Column(
            children: [
              Text(
                FormatUtils.formatBytes(totalSize),
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Text('总大小', style: TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVideoCard(VideoInfo video) {
    final savedBytes = video.savedBytes(_quality.index + 1);
    final compressedSize = video.compressedSize(_quality.index + 1);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: video.isSelected
              ? const Color(0xFF2196F3).withOpacity(0.5)
              : Colors.grey[200]!,
        ),
      ),
      child: InkWell(
        onTap: () => setState(() => video.isSelected = !video.isSelected),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(
                video.isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: video.isSelected ? const Color(0xFF2196F3) : Colors.grey[400],
                size: 24,
              ),
              const SizedBox(width: 12),

              // 视频缩略图占位
              Container(
                width: 70,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(Icons.play_circle_outline, color: Colors.white, size: 24),
                    Positioned(
                      bottom: 2,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          video.formattedDuration,
                          style: const TextStyle(color: Colors.white, fontSize: 9),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // 视频信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.name,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          video.resolution,
                          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '• ${video.codec}',
                          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '• ${video.formattedDuration}',
                          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          video.formattedSize,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        const Icon(Icons.arrow_forward, size: 14, color: Color(0xFF4CAF50)),
                        const SizedBox(width: 4),
                        Text(
                          FormatUtils.formatBytes(compressedSize),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '-${FormatUtils.formatBytes(savedBytes)}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF4CAF50),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget? _buildBottomBar() {
    if (_isLoading || _videos.isEmpty) return null;

    final selectedCount = _videos.where((v) => v.isSelected).length;
    if (selectedCount == 0) return null;

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            '已选 $selectedCount 个视频',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const Spacer(),
          Text(
            '可节省 ${FormatUtils.formatBytes(_totalSavedBytes)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFFFF9800),
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: selectedCount > 0 && !_isCompressing ? _compressSelected : null,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF9800),
              disabledBackgroundColor: Colors.grey[300],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: _isCompressing
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${(_progress * 100).toInt()}%'),
                    ],
                  )
                : const Text('开始压缩', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

}
