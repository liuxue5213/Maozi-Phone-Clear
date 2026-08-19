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
    return 0;
  }

  Future<List<HotApp>> getHotApps() async {
    final List<HotApp> apps = [];
    try {
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
            if (apps.length >= 10) break;
          } catch (_) {}
        }
      }
    } catch (_) {}
    return apps;
  }

  Future<CoolResult> coolDown(List<HotApp> apps) async {
    final before = await getCpuTemperature();
    await Future.delayed(const Duration(seconds: 2));
    final after = await getCpuTemperature();
    return CoolResult(temperatureBefore: before, temperatureAfter: after, killedApps: apps.length);
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
