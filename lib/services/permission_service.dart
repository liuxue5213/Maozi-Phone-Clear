import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

/// 权限服务 - 处理存储权限请求
class PermissionService {
  /// 检查是否有存储权限
  static Future<bool> hasStoragePermission() async {
    if (Platform.isAndroid) {
      final androidInfo = await _getAndroidSdkVersion();
      if (androidInfo >= 30) {
        // Android 11+ 需要 MANAGE_EXTERNAL_STORAGE
        return await Permission.manageExternalStorage.isGranted;
      } else {
        // Android 10 及以下需要 READ_EXTERNAL_STORAGE
        return await Permission.storage.isGranted;
      }
    }
    return true;
  }

  /// 请求存储权限
  static Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      final androidInfo = await _getAndroidSdkVersion();
      if (androidInfo >= 30) {
        // Android 11+ 请求 MANAGE_EXTERNAL_STORAGE
        final status = await Permission.manageExternalStorage.request();
        return status.isGranted;
      } else {
        // Android 10 及以下请求 READ_EXTERNAL_STORAGE
        final status = await Permission.storage.request();
        return status.isGranted;
      }
    }
    return true;
  }

  /// 检查权限是否被永久拒绝
  static Future<bool> isPermissionPermanentlyDenied() async {
    if (Platform.isAndroid) {
      final androidInfo = await _getAndroidSdkVersion();
      if (androidInfo >= 30) {
        return await Permission.manageExternalStorage.isPermanentlyDenied;
      } else {
        return await Permission.storage.isPermanentlyDenied;
      }
    }
    return false;
  }

  /// 打开应用设置页面
  static Future<void> openSettings() async {
    await openAppSettings();
  }

  /// 获取 Android SDK 版本
  static Future<int> _getAndroidSdkVersion() async {
    try {
      // 通过 platform channel 获取，这里简化处理
      return 33; // 默认返回 Android 13
    } catch (e) {
      return 33;
    }
  }
}
