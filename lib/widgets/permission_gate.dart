import 'package:flutter/material.dart';
import '../services/permission_service.dart';
import 'permission_request_widget.dart';

/// 权限门控 - 在应用启动时检查并请求存储权限
/// 所有需要文件访问的功能都必须先通过此门控
class PermissionGate extends StatefulWidget {
  final Widget child;

  const PermissionGate({super.key, required this.child});

  @override
  State<PermissionGate> createState() => _PermissionGateState();
}

class _PermissionGateState extends State<PermissionGate> {
  bool _hasPermission = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final hasPermission = await PermissionService.hasStoragePermission();
    if (!mounted) return;
    setState(() {
      _hasPermission = hasPermission;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 加载中
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F7FA),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF2196F3)),
              SizedBox(height: 16),
              Text('正在检查权限...', style: TextStyle(color: Color(0xFF666666))),
            ],
          ),
        ),
      );
    }

    // 无权限 - 显示全屏权限请求
    if (!_hasPermission) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: SafeArea(
          child: PermissionRequestWidget(
            customMessage: '帽子垃圾清理需要存储权限来扫描和清理手机中的垃圾文件',
            onPermissionGranted: _checkPermission,
          ),
        ),
      );
    }

    // 有权限 - 显示主应用
    return widget.child;
  }
}
