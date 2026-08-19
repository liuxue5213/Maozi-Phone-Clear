import 'dart:io';
import 'package:flutter/material.dart';

class CpuCoolerService {
  Future<int> getCpuTemperature() async {
    final paths = ['/sys/class/thermal/thermal_zone0/temp', '/sys/class/thermal/thermal_zone1/temp', '/sys/devices/virtual/thermal/thermal_zone0/temp'];
    for (final path in paths) {
      try {
        final file = File(path);
        if (await file.exists()) {
          final content = await file.readAsString();
          final temp = int.tryParse(content.trim());
          if (temp != null) return temp > 1000 ? temp ~/ 1000 : temp;
        }
      } catch (_) {}
    }
    // 返回模拟温度
    return 42;
  }

  Future<List<HotApp>> getHotApps() async {
    final List<HotApp> apps = [];
    try {
      // 从 /proc 读取 CPU 使用率最高的进程
      final procDir = Directory('/proc');
      await for (final entity in procDir.list()) {
        if (entity is Directory) {
          final pid = int.tryParse(entity.path.split('/').last);
          if (pid == null) continue;
          try {
            final statFile = File('${entity.path}/stat');
            if (!await statFile.exists()) continue;
            final statusFile = File('${entity.path}/status');
            String name = pid.toString();
            if (await statusFile.exists()) {
              final content = await statusFile.readAsString();
              for (final line in content.split('\n')) {
                if (line.startsWith('Name:')) { name = line.split(RegExp(r'\s+'))[1]; break; }
              }
            }
            apps.add(HotApp(name: name, packageName: name, cpuPercent: 5, temperature: 3));
            if (apps.length >= 10) break; // 只取前10个
          } catch (_) {}
        }
      }
    } catch (_) {}
    
    // 如果没有获取到进程，添加演示数据
    if (apps.isEmpty) {
      apps.addAll(_getDemoHotApps());
    }
    
    return apps;
  }

  Future<CoolResult> coolDown(List<HotApp> apps) async {
    final before = await getCpuTemperature();
    await Future.delayed(const Duration(seconds: 2));
    final after = before - 5; // 模拟降温
    return CoolResult(temperatureBefore: before, temperatureAfter: after, killedApps: apps.length);
  }

  TemperatureStatus getTemperatureStatus(int temp) {
    if (temp < 35) return TemperatureStatus.normal;
    if (temp < 42) return TemperatureStatus.warm;
    if (temp < 50) return TemperatureStatus.hot;
    return TemperatureStatus.critical;
  }

  /// 演示数据：发热应用
  List<HotApp> _getDemoHotApps() {
    return [
      HotApp(name: '抖音', packageName: 'com.ss.android.ugc.aweme', cpuPercent: 25, temperature: 8),
      HotApp(name: '微信', packageName: 'com.tencent.mm', cpuPercent: 18, temperature: 6),
      HotApp(name: '王者荣耀', packageName: 'com.tencent.tmgp.sgame', cpuPercent: 35, temperature: 12),
      HotApp(name: 'Chrome浏览器', packageName: 'com.android.chrome', cpuPercent: 15, temperature: 5),
      HotApp(name: '淘宝', packageName: 'com.taobao.taobao', cpuPercent: 12, temperature: 4),
      HotApp(name: 'QQ', packageName: 'com.tencent.mobileqq', cpuPercent: 10, temperature: 3),
      HotApp(name: '爱奇艺', packageName: 'com.qiyi.video', cpuPercent: 20, temperature: 7),
      HotApp(name: '哔哩哔哩', packageName: 'tv.danmaku.bili', cpuPercent: 22, temperature: 8),
    ];
  }
}

enum TemperatureStatus { normal, warm, hot, critical }

class HotApp {
  final String name; final String packageName; final int cpuPercent; final int temperature;
  bool isSelected = false;
  HotApp({required this.name, required this.packageName, required this.cpuPercent, required this.temperature});
}

class CoolResult {
  final int temperatureBefore; final int temperatureAfter; final int killedApps;
  CoolResult({required this.temperatureBefore, required this.temperatureAfter, required this.killedApps});
  int get temperatureReduction => temperatureBefore - temperatureAfter;
}

extension TemperatureStatusExt on TemperatureStatus {
  String get displayName { switch(this) { case TemperatureStatus.normal: return '正常'; case TemperatureStatus.warm: return '温热'; case TemperatureStatus.hot: return '发热'; case TemperatureStatus.critical: return '过热'; } }
  Color get color { switch(this) { case TemperatureStatus.normal: return const Color(0xFF4CAF50); case TemperatureStatus.warm: return const Color(0xFFFF9800); case TemperatureStatus.hot: return const Color(0xFFFF5722); case TemperatureStatus.critical: return const Color(0xFFF44336); } }
}
