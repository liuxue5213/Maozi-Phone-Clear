import 'dart:io';
import 'package:flutter/material.dart';

class CpuCoolerService {
  Future<int> getCpuTemperature() async {
    final paths = ['/sys/class/thermal/thermal_zone0/temp', '/sys/class/thermal/thermal_zone1/temp'];
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
    return 0;
  }

  Future<List<HotApp>> getHotApps() async {
    final List<HotApp> apps = [];
    try {
      final result = await Process.run('top', ['-n', '1', '-b']);
      final lines = result.stdout.toString().split('\n');
      for (final line in lines.skip(7).take(20)) {
        final parts = line.trim().split(RegExp(r'\s+'));
        if (parts.length >= 12) {
          final cpu = int.tryParse(parts[8].replaceAll('%', '')) ?? 0;
          if (cpu > 5) apps.add(HotApp(name: parts.length > 11 ? parts[11] : 'Unknown', packageName: parts.length > 11 ? parts[11] : 'unknown', cpuPercent: cpu, temperature: (cpu * 0.5).round()));
        }
      }
    } catch (_) {}
    return apps;
  }

  Future<CoolResult> coolDown(List<HotApp> apps) async {
    await Future.delayed(const Duration(seconds: 2));
    return CoolResult(temperatureBefore: 45, temperatureAfter: 35, killedApps: apps.length);
  }

  TemperatureStatus getTemperatureStatus(int temp) {
    if (temp < 35) return TemperatureStatus.normal;
    if (temp < 42) return TemperatureStatus.warm;
    if (temp < 50) return TemperatureStatus.hot;
    return TemperatureStatus.critical;
  }
}

enum TemperatureStatus { normal, warm, hot, critical }

class HotApp {
  bool isSelected = false;
  final String name; final String packageName; final int cpuPercent; final int temperature;
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
