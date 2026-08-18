import 'dart:io';
import 'dart:math';

/// 后台进程信息
class ProcessInfo {
  final int pid;
  final String name;
  final String packageName;
  final int memoryKb;        // 内存占用 KB
  final int cpuPercent;      // CPU占用率
  final bool isSystem;       // 是否系统进程
  final bool isForeground;   // 是否前台
  bool isSelected;

  ProcessInfo({
    required this.pid,
    required this.name,
    required this.packageName,
    required this.memoryKb,
    required this.cpuPercent,
    required this.isSystem,
    required this.isForeground,
    this.isSelected = false,
  });

  String get formattedMemory {
    if (memoryKb < 1024) return '${memoryKb}KB';
    return '${(memoryKb / 1024).toStringAsFixed(1)}MB';
  }

  /// 是否可以清理
  bool get canKill => !isSystem && !isForeground;
}

/// 手机加速服务
class PhoneBoostService {
  final Random _random = Random();

  /// 获取后台进程列表
  Future<List<ProcessInfo>> getRunningProcesses() async {
    await Future.delayed(const Duration(seconds: 1));

    final List<ProcessInfo> processes = [];

    // 用户应用进程
    final userApps = [
      ('抖音', 'com.ss.android.ugc.aweme', 450, 12),
      ('微博', 'com.sina.weibo', 280, 5),
      ('淘宝', 'com.taobao.taobao', 350, 8),
      ('京东', 'com.jingdong.app.mall', 300, 6),
      ('大众点评', 'com.dianping.v1', 200, 4),
      ('知乎', 'com.zhihu.android', 250, 7),
      ('哔哩哔哩', 'tv.danmaku.bili', 380, 15),
      ('小红书', 'com.xingin.xhs', 220, 5),
      ('美团外卖', 'com.sankuai.meituan.takeoutnew', 180, 3),
      ('网易云音乐', 'com.netease.cloudmusic', 260, 8),
      ('腾讯视频', 'com.tencent.qqlive', 400, 18),
      ('百度地图', 'com.baidu.BaiduMap', 320, 10),
      ('今日头条', 'com.ss.android.article.news', 240, 6),
      ('滴滴出行', 'com.sdu.didi.psnger', 210, 4),
      ('爱奇艺', 'com.qiyi.video', 360, 12),
    ];

    for (int i = 0; i < userApps.length; i++) {
      final (name, pkg, mem, cpu) = userApps[i];
      processes.add(ProcessInfo(
        pid: 1000 + i,
        name: name,
        packageName: pkg,
        memoryKb: mem * 1024 + _random.nextInt(50 * 1024),
        cpuPercent: cpu + _random.nextInt(5),
        isSystem: false,
        isForeground: i == 0, // 第一个是前台
        isSelected: i != 0, // 非前台默认选中
      ));
    }

    // 系统进程
    final systemApps = [
      ('系统UI', 'com.android.systemui', 150, 2),
      ('启动器', 'com.android.launcher3', 120, 1),
      ('Google服务', 'com.google.android.gms', 200, 3),
      ('系统服务', 'android', 180, 2),
      ('输入法', 'com.android.inputmethod.latin', 80, 1),
    ];

    for (int i = 0; i < systemApps.length; i++) {
      final (name, pkg, mem, cpu) = systemApps[i];
      processes.add(ProcessInfo(
        pid: 500 + i,
        name: name,
        packageName: pkg,
        memoryKb: mem * 1024,
        cpuPercent: cpu,
        isSystem: true,
        isForeground: false,
        isSelected: false,
      ));
    }

    // 按内存占用降序
    processes.sort((a, b) => b.memoryKb.compareTo(a.memoryKb));
    return processes;
  }

  /// 一键加速（清理选中进程）
  Future<BoostResult> boost(List<ProcessInfo> processes) async {
    final selected = processes.where((p) => p.isSelected && p.canKill).toList();

    if (selected.isEmpty) {
      return BoostResult(freedMemoryKb: 0, killedProcesses: 0);
    }

    int freedMemoryKb = 0;
    for (final process in selected) {
      // 模拟杀进程
      await Future.delayed(const Duration(milliseconds: 50));
      freedMemoryKb += process.memoryKb;
    }

    return BoostResult(
      freedMemoryKb: freedMemoryKb,
      killedProcesses: selected.length,
    );
  }

  /// 总内存信息
  Future<Map<String, int>> getMemoryInfo() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return {
      'totalMemoryKb': 8 * 1024 * 1024,  // 8GB
      'usedMemoryKb': 5 * 1024 * 1024,    // 5GB
      'availableMemoryKb': 3 * 1024 * 1024, // 3GB
    };
  }

  /// 白名单（不应被清理的应用）
  static const List<String> whitelistPackages = [
    'com.tencent.mm',  // 微信
    'com.android.systemui',
    'com.android.launcher3',
  ];
}

/// 加速结果
class BoostResult {
  final int freedMemoryKb;
  final int killedProcesses;

  BoostResult({
    required this.freedMemoryKb,
    required this.killedProcesses,
  });

  String get formattedFreedMemory {
    if (freedMemoryKb < 1024) return '${freedMemoryKb}KB';
    return '${(freedMemoryKb / 1024).toStringAsFixed(1)}MB';
  }
}
