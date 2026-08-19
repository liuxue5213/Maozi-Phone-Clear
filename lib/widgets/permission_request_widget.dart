import 'package:flutter/material.dart';
import '../services/permission_service.dart';

/// 权限请求组件
/// 当没有存储权限时显示引导 UI
class PermissionRequestWidget extends StatelessWidget {
  final VoidCallback? onPermissionGranted;
  final String? customMessage;

  const PermissionRequestWidget({
    super.key,
    this.onPermissionGranted,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.folder_off_outlined,
              size: 80,
              color: Color(0xFFBDBDBD),
            ),
            const SizedBox(height: 16),
            const Text(
              '需要存储权限',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              customMessage ?? '为了扫描和清理手机中的垃圾文件，需要授予存储访问权限',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _requestPermission(context),
              icon: const Icon(Icons.check),
              label: const Text('授予权限'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _requestPermission(BuildContext context) async {
    final granted = await PermissionService.requestStoragePermission();
    if (granted) {
      onPermissionGranted?.call();
    } else {
      // 检查是否被永久拒绝
      final permanentlyDenied = await PermissionService.isPermissionPermanentlyDenied();
      if (permanentlyDenied && context.mounted) {
        _showSettingsDialog(context);
      }
    }
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('需要手动授权'),
        content: const Text('存储权限被永久拒绝，请在系统设置中手动开启存储访问权限'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              PermissionService.openSettings();
            },
            child: const Text('去设置'),
          ),
        ],
      ),
    );
  }
}
