import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 定时清理频率
enum CleanupFrequency {
  daily,
  weekly,
  biweekly,
  monthly,
  never,
}

extension CleanupFrequencyExtension on CleanupFrequency {
  String get displayName {
    switch (this) {
      case CleanupFrequency.daily:
        return '每天';
      case CleanupFrequency.weekly:
        return '每周';
      case CleanupFrequency.biweekly:
        return '每两周';
      case CleanupFrequency.monthly:
        return '每月';
      case CleanupFrequency.never:
        return '从不';
    }
  }

  /// 获取间隔天数
  int get intervalDays {
    switch (this) {
      case CleanupFrequency.daily:
        return 1;
      case CleanupFrequency.weekly:
        return 7;
      case CleanupFrequency.biweekly:
        return 14;
      case CleanupFrequency.monthly:
        return 30;
      case CleanupFrequency.never:
        return -1;
    }
  }
}

/// 定时清理配置
class ScheduledCleanupConfig {
  final bool enabled;
  final CleanupFrequency frequency;
  final bool wifiOnly;        // 仅在WiFi下清理
  final bool notifyComplete;  // 清理完成后通知
  final DateTime? lastCleanupTime;

  ScheduledCleanupConfig({
    this.enabled = false,
    this.frequency = CleanupFrequency.weekly,
    this.wifiOnly = true,
    this.notifyComplete = true,
    this.lastCleanupTime,
  });

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'frequency': frequency.name,
        'wifiOnly': wifiOnly,
        'notifyComplete': notifyComplete,
        'lastCleanupTime': lastCleanupTime?.toIso8601String(),
      };

  factory ScheduledCleanupConfig.fromJson(Map<String, dynamic> json) {
    return ScheduledCleanupConfig(
      enabled: json['enabled'] ?? false,
      frequency: CleanupFrequency.values.firstWhere(
        (f) => f.name == json['frequency'],
        orElse: () => CleanupFrequency.weekly,
      ),
      wifiOnly: json['wifiOnly'] ?? true,
      notifyComplete: json['notifyComplete'] ?? true,
      lastCleanupTime: json['lastCleanupTime'] != null
          ? DateTime.parse(json['lastCleanupTime'])
          : null,
    );
  }

  ScheduledCleanupConfig copyWith({
    bool? enabled,
    CleanupFrequency? frequency,
    bool? wifiOnly,
    bool? notifyComplete,
    DateTime? lastCleanupTime,
  }) {
    return ScheduledCleanupConfig(
      enabled: enabled ?? this.enabled,
      frequency: frequency ?? this.frequency,
      wifiOnly: wifiOnly ?? this.wifiOnly,
      notifyComplete: notifyComplete ?? this.notifyComplete,
      lastCleanupTime: lastCleanupTime ?? this.lastCleanupTime,
    );
  }
}

/// 定时清理服务
class ScheduledCleanupService {
  static const String _configKey = 'scheduled_cleanup_config';

  /// 获取配置
  Future<ScheduledCleanupConfig> getConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_configKey);
    if (data == null) return ScheduledCleanupConfig();
    return ScheduledCleanupConfig.fromJson(jsonDecode(data));
  }

  /// 保存配置
  Future<void> saveConfig(ScheduledCleanupConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_configKey, jsonEncode(config.toJson()));
  }

  /// 检查是否需要执行定时清理
  Future<bool> shouldRunCleanup() async {
    final config = await getConfig();
    if (!config.enabled || config.frequency == CleanupFrequency.never) {
      return false;
    }

    if (config.lastCleanupTime == null) return true;

    final daysSinceLastCleanup =
        DateTime.now().difference(config.lastCleanupTime!).inDays;
    return daysSinceLastCleanup >= config.frequency.intervalDays;
  }

  /// 更新最后清理时间
  Future<void> updateLastCleanupTime() async {
    final config = await getConfig();
    await saveConfig(config.copyWith(lastCleanupTime: DateTime.now()));
  }

  /// 清理历史记录
  static const String _historyKey = 'cleanup_history';

  /// 获取清理历史
  Future<List<Map<String, dynamic>>> getCleanupHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_historyKey);
    if (data == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(data));
  }

  /// 添加清理记录
  Future<void> addCleanupRecord({
    required int bytesCleaned,
    required int filesCleaned,
    required String type,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getCleanupHistory();
    history.insert(0, {
      'bytesCleaned': bytesCleaned,
      'filesCleaned': filesCleaned,
      'type': type,
      'timestamp': DateTime.now().toIso8601String(),
    });
    // 只保留最近 50 条记录
    if (history.length > 50) {
      history.removeRange(50, history.length);
    }
    await prefs.setString(_historyKey, jsonEncode(history));
  }

  /// 获取累计清理大小
  Future<int> getTotalCleanedBytes() async {
    final history = await getCleanupHistory();
    return history.fold<int>(
      0,
      (sum, record) => sum + (record['bytesCleaned'] as int),
    );
  }

  /// 清空历史记录
  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }
}
