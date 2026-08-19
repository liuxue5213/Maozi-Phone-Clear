import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'dart:math';

/// CPU温度状态
enum TemperatureStatus {
  normal,     // 正常 (< 35°C)
  warm,       // 温热 (35-42°C)
  hot,        // 发热 (42-50°C)
  critical,   // 过热 (> 50°C)
}

extension TemperatureStatusExtension on TemperatureStatus {
  String get displayName {
    switch (this) {
      case TemperatureStatus.normal:
        return '正常';
      case TemperatureStatus.warm:
        return '温热';
      case TemperatureStatus.hot:
        return '发热';
      case TemperatureStatus.critical:
        return '过热';
    }
  }

  Color get color {
    switch (this) {
      case TemperatureStatus.normal:
        return const Color(0xFF4CAF50);
      case TemperatureStatus.warm:
        return const Color(0xFFFF9800);
      case TemperatureStatus.hot:
        return const Color(0xFFFF5722);
      case TemperatureStatus.critical:
        return const Color(0xFFF44336);
    }
  }
}

/// 发热应用
class HotApp {
  final String name;
  final String packageName;
  final int cpuPercent;
  final int temperature;  // 模拟温度贡献
  bool isSelected;

  HotApp({
    required this.name,
    required this.packageName,
    required this.cpuPercent,
    required this.temperature,
    this.isSelected = false,
  });
}

/// CPU降温服务
class CpuCoolerService {
  final Random _random = Random();

  /// 获取CPU温度
  Future<int> getCpuTemperature() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return 38 + _random.nextInt(15); // 38-53°C
  }

  /// 获取发热应用
  Future<List<HotApp>> getHotApps() async {
    await Future.delayed(const Duration(seconds: 1));

    return [
      HotApp(name: '抖音', packageName: 'com.ss.android.ugc.aweme', cpuPercent: 25, temperature: 8),
      HotApp(name: '王者荣耀', packageName: 'com.tencent.tmgp.sgame', cpuPercent: 45, temperature: 12),
      HotApp(name: '腾讯视频', packageName: 'com.tencent.qqlive', cpuPercent: 18, temperature: 6),
      HotApp(name: '哔哩哔哩', packageName: 'tv.danmaku.bili', cpuPercent: 15, temperature: 5),
      HotApp(name: '相机', packageName: 'com.android.camera', cpuPercent: 30, temperature: 9),
      HotApp(name: '百度地图', packageName: 'com.baidu.BaiduMap', cpuPercent: 12, temperature: 4),
      HotApp(name: 'Chrome', packageName: 'com.android.chrome', cpuPercent: 20, temperature: 7),
      HotApp(name: '原神', packageName: 'com.miHoYo.Yuanshen', cpuPercent: 50, temperature: 15),
    ]..sort((a, b) => b.temperature.compareTo(a.temperature));
  }

  /// 执行降温
  Future<CoolResult> coolDown(List<HotApp> apps) async {
    final selected = apps.where((a) => a.isSelected).toList();
    int totalTempReduction = 0;

    for (final app in selected) {
      await Future.delayed(const Duration(milliseconds: 200));
      totalTempReduction += app.temperature;
    }

    return CoolResult(
      temperatureBefore: await getCpuTemperature(),
      temperatureAfter: 32 + _random.nextInt(5),
      killedApps: selected.length,
    );
  }

  TemperatureStatus getTemperatureStatus(int temp) {
    if (temp < 35) return TemperatureStatus.normal;
    if (temp < 42) return TemperatureStatus.warm;
    if (temp < 50) return TemperatureStatus.hot;
    return TemperatureStatus.critical;
  }
}

/// 降温结果
class CoolResult {
  final int temperatureBefore;
  final int temperatureAfter;
  final int killedApps;

  CoolResult({
    required this.temperatureBefore,
    required this.temperatureAfter,
    required this.killedApps,
  });

  int get temperatureReduction => temperatureBefore - temperatureAfter;
}
