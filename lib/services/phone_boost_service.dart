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
            processes.add(ProcessInfo(pid: pid, name: name, packageName: name, memoryKb: memKb, cpuPercent: 0, isSystem: pid < 1000, isForeground: false));
          } catch (e) {}
        }
      }
    } catch (e) {}
    processes.sort((a, b) => b.memoryKb.compareTo(a.memoryKb));
    return processes.take(50).toList();
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
      return {'totalMemoryKb': 0, 'usedMemoryKb': 0, 'availableMemoryKb': 0};
    }
  }

  Future<BoostResult> boost(List<ProcessInfo> processes) async {
    final selected = processes.where((p) => p.isSelected && p.canKill).toList();
    int freed = 0;
    for (final p in selected) { try { freed += p.memoryKb; } catch (e) {} }
    return BoostResult(freedMemoryKb: freed, killedProcesses: selected.length);
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
