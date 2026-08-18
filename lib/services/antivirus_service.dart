import 'dart:math';

/// 威胁等级
enum ThreatLevel {
  safe,       // 安全
  low,        // 低风险
  medium,     // 中风险
  high,       // 高风险
  critical,   // 严重
}

extension ThreatLevelExtension on ThreatLevel {
  String get displayName {
    switch (this) {
      case ThreatLevel.safe:
        return '安全';
      case ThreatLevel.low:
        return '低风险';
      case ThreatLevel.medium:
        return '中风险';
      case ThreatLevel.high:
        return '高风险';
      case ThreatLevel.critical:
        return '严重';
    }
  }

  Color get color {
    switch (this) {
      case ThreatLevel.safe:
        return const Color(0xFF4CAF50);
      case ThreatLevel.low:
        return const Color(0xFF8BC34A);
      case ThreatLevel.medium:
        return const Color(0xFFFF9800);
      case ThreatLevel.high:
        return const Color(0xFFFF5722);
      case ThreatLevel.critical:
        return const Color(0xFFF44336);
    }
  }
}

/// 威胁类型
enum ThreatType {
  virus,          // 病毒
  trojan,         // 木马
  adware,         // 广告软件
  spyware,        // 间谍软件
  riskware,       // 风险软件
  privacyRisk,    // 隐私风险
}

extension ThreatTypeExtension on ThreatType {
  String get displayName {
    switch (this) {
      case ThreatType.virus:
        return '病毒';
      case ThreatType.trojan:
        return '木马';
      case ThreatType.adware:
        return '广告软件';
      case ThreatType.spyware:
        return '间谍软件';
      case ThreatType.riskware:
        return '风险软件';
      case ThreatType.privacyRisk:
        return '隐私风险';
    }
  }

  String get icon {
    switch (this) {
      case ThreatType.virus:
        return '🦠';
      case ThreatType.trojan:
        return '🐴';
      case ThreatType.adware:
        return '📢';
      case ThreatType.spyware:
        return '👁️';
      case ThreatType.riskware:
        return '⚠️';
      case ThreatType.privacyRisk:
        return '🔓';
    }
  }
}

/// 检测到的威胁
class ThreatItem {
  final String appName;
  final String packageName;
  final String description;
  final ThreatLevel level;
  final ThreatType type;
  final String filePath;
  bool isSelected;

  ThreatItem({
    required this.appName,
    required this.packageName,
    required this.description,
    required this.level,
    required this.type,
    required this.filePath,
    this.isSelected = false,
  });
}

/// 病毒查杀服务
class AntivirusService {
  final Random _random = Random();

  /// 执行病毒扫描
  Future<ScanResult> scan() async {
    await Future.delayed(const Duration(seconds: 3));

    final threats = _generateThreats();
    return ScanResult(
      scannedApps: 156,
      scannedFiles: 2843,
      threatsFound: threats.length,
      threats: threats,
      scanDurationSeconds: 12,
    );
  }

  List<ThreatItem> _generateThreats() {
    return [
      ThreatItem(
        name: '清理大师Pro',
        packageName: 'com.cleaner.pro',
        description: '发现广告插件，可能在后台弹出恶意广告',
        level: ThreatLevel.medium,
        type: ThreatType.adware,
        filePath: '/data/app/com.cleaner.pro/base.apk',
        isSelected: true,
      ),
      ThreatItem(
        name: '免费WiFi',
        packageName: 'com.free.wifi',
        description: '过度请求位置权限，可能存在隐私泄露风险',
        level: ThreatLevel.low,
        type: ThreatType.privacyRisk,
        filePath: '/data/app/com.free.wifi/base.apk',
        isSelected: true,
      ),
      ThreatItem(
        name: 'GameHack',
        packageName: 'com.game.hack',
        description: '检测到可疑代码注入行为',
        level: ThreatLevel.high,
        type: ThreatType.riskware,
        filePath: '/data/app/com.game.hack/base.apk',
        isSelected: true,
      ),
    ];
  }

  /// 处理威胁
  Future<int> quarantineThreats(List<ThreatItem> threats) async {
    int count = 0;
    for (final threat in threats) {
      await Future.delayed(const Duration(milliseconds: 300));
      count++;
    }
    return count;
  }
}

/// 扫描结果
class ScanResult {
  final int scannedApps;
  final int scannedFiles;
  final int threatsFound;
  final List<ThreatItem> threats;
  final int scanDurationSeconds;

  ScanResult({
    required this.scannedApps,
    required this.scannedFiles,
    required this.threatsFound,
    required this.threats,
    required this.scanDurationSeconds,
  });

  bool get isClean => threats.isEmpty;
}
