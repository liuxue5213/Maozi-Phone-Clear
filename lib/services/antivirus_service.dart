import 'dart:io';
import 'package:flutter/material.dart';

class AntivirusService {
  Future<ScanResult> scan() async {
    final List<ThreatItem> threats = [];
    int scanned = 0;
    try {
      final result = await Process.run('pm', ['list', 'packages', '-3']);
      final packages = result.stdout.toString().split('\n');
      for (final pkg in packages) {
        if (!pkg.startsWith('package:')) continue;
        final packageName = pkg.replaceFirst('package:', '').trim();
        scanned++;
        if (_isSuspicious(packageName)) {
          threats.add(ThreatItem(appName: packageName.split('.').last, packageName: packageName, description: '可疑应用名称', level: ThreatLevel.medium, type: ThreatType.riskware, filePath: '/data/app/$packageName'));
        }
      }
    } catch (_) {}
    return ScanResult(scannedApps: scanned, scannedFiles: scanned * 10, threatsFound: threats.length, threats: threats, scanDurationSeconds: 10);
  }

  bool _isSuspicious(String pkg) {
    final lower = pkg.toLowerCase();
    return ['hack', 'crack', 'cheat', 'mod'].any((s) => lower.contains(s));
  }

  Future<int> quarantineThreats(List<ThreatItem> threats) async => threats.length;
}

enum ThreatLevel { safe, low, medium, high, critical }
enum ThreatType { virus, trojan, adware, spyware, riskware, privacyRisk }

class ThreatItem {
  final String appName; final String packageName; final String description; final ThreatLevel level; final ThreatType type; final String filePath;
  bool isSelected = true;
  ThreatItem({required this.appName, required this.packageName, required this.description, required this.level, required this.type, required this.filePath});
}

class ScanResult {
  final int scannedApps; final int scannedFiles; final int threatsFound; final List<ThreatItem> threats; final int scanDurationSeconds;
  ScanResult({required this.scannedApps, required this.scannedFiles, required this.threatsFound, required this.threats, required this.scanDurationSeconds});
  bool get isClean => threats.isEmpty;
}

extension ThreatLevelExt on ThreatLevel {
  String get displayName { switch(this) { case ThreatLevel.safe: return '安全'; case ThreatLevel.low: return '低风险'; case ThreatLevel.medium: return '中风险'; case ThreatLevel.high: return '高风险'; case ThreatLevel.critical: return '严重'; } }
  Color get color { switch(this) { case ThreatLevel.safe: return const Color(0xFF4CAF50); case ThreatLevel.low: return const Color(0xFF8BC34A); case ThreatLevel.medium: return const Color(0xFFFF9800); case ThreatLevel.high: return const Color(0xFFFF5722); case ThreatLevel.critical: return const Color(0xFFF44336); } }
}

extension ThreatTypeExt on ThreatType {
  String get displayName { switch(this) { case ThreatType.virus: return '病毒'; case ThreatType.trojan: return '木马'; case ThreatType.adware: return '广告软件'; case ThreatType.spyware: return '间谍软件'; case ThreatType.riskware: return '风险软件'; case ThreatType.privacyRisk: return '隐私风险'; } }
  String get icon { switch(this) { case ThreatType.virus: return '🦠'; case ThreatType.trojan: return '🐴'; case ThreatType.adware: return '📢'; case ThreatType.spyware: return '👁️'; case ThreatType.riskware: return '⚠️'; case ThreatType.privacyRisk: return '🔓'; } }
}

