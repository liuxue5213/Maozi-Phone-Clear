import 'package:flutter/services.dart';

/// 系统清理服务 - 提供跳转到系统设置的功能
class SystemCleanService {
  static const _channel = MethodChannel('com.maozi.phone_clean/system_clean');

  /// 跳转到系统存储设置
  static Future<void> openStorageSettings() async {
    try {
      await _channel.invokeMethod('openStorageSettings');
    } on PlatformException catch (e) {
      print('跳转存储设置失败: ${e.message}');
    } on MissingPluginException {
      // 如果没有原生实现，使用备用方案
      try {
        await _channel.invokeMethod('openAppSettings');
      } catch (_) {}
    }
  }

  /// 跳转到应用信息页面
  static Future<void> openAppInfo() async {
    try {
      await _channel.invokeMethod('openAppInfo');
    } on PlatformException catch (e) {
      print('跳转应用信息失败: ${e.message}');
    } on MissingPluginException {
      // 备用方案
    }
  }

  /// 清理应用缓存（需要辅助功能权限或 root）
  static Future<bool> clearAppCache() async {
    try {
      final result = await _channel.invokeMethod('clearAppCache');
      return result == true;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
