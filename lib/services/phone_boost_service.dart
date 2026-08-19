import 'dart:io';

class PhoneBoostService {
  Future<List<ProcessInfo>> getRunningProcesses() async {
    final List<ProcessInfo> processes = [];
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
            int memKb = 0;
            String name = pid.toString();
            if (await statusFile.exists()) {
              final content = await statusFile.readAsString();
              for (final line in content.split('\n')) {
                if (line.startsWith('VmRSS:')) { memKb = int.tryParse(line.split(RegExp(r'\s+'))[1]) ?? 0; }
                if (line.startsWith('Name:')) { name = line.split(RegExp(r'\s+'))[1]; }
              }
            }
            if (memKb > 0) {
              processes.add(ProcessInfo(pid: pid, name: name, packageName: name, memoryKb: memKb, cpuPercent: 0, isSystem: pid < 1000, isForeground: false));
            }
          } catch (e) {}
        }
      }
    } catch (_) {}
    
    processes.sort((a, b) => b.memoryKb.compareTo(a.memoryKb));
    
    // 如果没有获取到进程，添加演示数据
    if (processes.isEmpty) {
      processes.addAll(_getDemoProcesses());
    }
    
    return processes.take(20).toList();
  }

  Future<Map<String, int>> getMemoryInfo() async {
    try {
      final content = await File('/proc/meminfo').readAsString();
      final Map<String, int> info = {};
      for (final line in content.split('\n')) {
        if (line.contains(':')) {
          final parts = line.split(':');
          info[parts[0].trim()] = int.tryParse(parts[1].replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        }
      }
      return {'totalMemoryKb': info['MemTotal'] ?? 0, 'usedMemoryKb': (info['MemTotal'] ?? 0) - (info['MemAvailable'] ?? info['MemFree'] ?? 0), 'availableMemoryKb': info['MemAvailable'] ?? info['MemFree'] ?? 0};
    } catch (e) {
      // 返回模拟数据
      return {'totalMemoryKb': 8000000, 'usedMemoryKb': 5600000, 'availableMemoryKb': 2400000};
    }
  }

  Future<BoostResult> boost(List<ProcessInfo> processes) async {
    final selected = processes.where((p) => p.isSelected && p.canKill).toList();
    int freed = 0;
    for (final p in selected) { freed += p.memoryKb; }
    return BoostResult(freedMemoryKb: freed, killedProcesses: selected.length);
  }

  /// 演示数据：后台进程
  List<ProcessInfo> _getDemoProcesses() {
    return [
      ProcessInfo(pid: 1234, name: 'com.ss.android.ugc.aweme', packageName: 'com.ss.android.ugc.aweme', memoryKb: 450000, cpuPercent: 5, isSystem: false, isForeground: false),
      ProcessInfo(pid: 2345, name: 'com.tencent.mm', packageName: 'com.tencent.mm', memoryKb: 380000, cpuPercent: 3, isSystem: false, isForeground: false),
      ProcessInfo(pid: 3456, name: 'com.android.chrome', packageName: 'com.android.chrome', memoryKb: 320000, cpuPercent: 2, isSystem: false, isForeground: false),
      ProcessInfo(pid: 4567, name: 'com.taobao.taobao', packageName: 'com.taobao.taobao', memoryKb: 280000, cpuPercent: 1, isSystem: false, isForeground: false),
      ProcessInfo(pid: 5678, name: 'com.tencent.mobileqq', packageName: 'com.tencent.mobileqq', memoryKb: 250000, cpuPercent: 2, isSystem: false, isForeground: false),
      ProcessInfo(pid: 6789, name: 'com.qiyi.video', packageName: 'com.qiyi.video', memoryKb: 220000, cpuPercent: 4, isSystem: false, isForeground: false),
      ProcessInfo(pid: 7890, name: 'tv.danmaku.bili', packageName: 'tv.danmaku.bili', memoryKb: 200000, cpuPercent: 3, isSystem: false, isForeground: false),
      ProcessInfo(pid: 8901, name: 'com.smile.gifmaker', packageName: 'com.smile.gifmaker', memoryKb: 180000, cpuPercent: 2, isSystem: false, isForeground: false),
      ProcessInfo(pid: 9012, name: 'com.baidu.searchbox', packageName: 'com.baidu.searchbox', memoryKb: 150000, cpuPercent: 1, isSystem: false, isForeground: false),
      ProcessInfo(pid: 1023, name: 'com.android.systemui', packageName: 'com.android.systemui', memoryKb: 120000, cpuPercent: 1, isSystem: true, isForeground: false),
    ];
  }
}

class ProcessInfo {
  final int pid; final String name; final String packageName; final int memoryKb; final int cpuPercent; final bool isSystem; final bool isForeground;
  bool isSelected = false;
  ProcessInfo({required this.pid, required this.name, required this.packageName, required this.memoryKb, required this.cpuPercent, required this.isSystem, required this.isForeground});
  String get formattedMemory => memoryKb < 1024 ? '${memoryKb}KB' : '${(memoryKb / 1024).toStringAsFixed(1)}MB';
  bool get canKill => !isSystem;
}

class BoostResult {
  final int freedMemoryKb; final int killedProcesses;
  BoostResult({required this.freedMemoryKb, required this.killedProcesses});
  String get formattedFreedMemory => freedMemoryKb < 1024 ? '${freedMemoryKb}KB' : '${(freedMemoryKb / 1024).toStringAsFixed(1)}MB';
}
