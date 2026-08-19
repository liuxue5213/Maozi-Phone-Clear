import 'package:flutter/material.dart';
import '../services/phone_boost_service.dart';

/// 手机加速页面
class PhoneBoostScreen extends StatefulWidget {
  const PhoneBoostScreen({super.key});

  @override
  State<PhoneBoostScreen> createState() => _PhoneBoostScreenState();
}

class _PhoneBoostScreenState extends State<PhoneBoostScreen>
    with SingleTickerProviderStateMixin {
  final PhoneBoostService _service = PhoneBoostService();
  List<ProcessInfo> _processes = [];
  bool _isLoading = true;
  bool _isBoosting = false;
  BoostResult? _boostResult;
  Map<String, int>? _memoryInfo;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _loadData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _boostResult = null;
    });

    final processes = await _service.getRunningProcesses();
    final memInfo = await _service.getMemoryInfo();

    setState(() {
      _processes = processes;
      _memoryInfo = memInfo;
      _isLoading = false;
    });
  }

  Future<void> _boost() async {
    final selected = _processes.where((p) => p.isSelected).toList();
    if (selected.isEmpty) return;

    setState(() => _isBoosting = true);
    _animController.repeat();

    final result = await _service.boost(_processes);

    await Future.delayed(const Duration(milliseconds: 500));
    _animController.stop();
    _animController.reset();

    if (!mounted) return;
    // 移除已清理的进程
    setState(() {
      _processes.removeWhere((p) => p.isSelected && p.canKill);
      _boostResult = result;
      _isBoosting = false;
    });

    // 刷新内存信息
    final memInfo = await _service.getMemoryInfo();
    if (!mounted) return;
    setState(() => _memoryInfo = memInfo);
  }

  int get _totalCleanableKb {
    return _processes
        .where((p) => p.isSelected && p.canKill)
        .fold<int>(0, (sum, p) => sum + p.memoryKb);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          '手机加速',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF2196F3),
        elevation: 0,
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _loadData,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        // 内存使用状态
        _buildMemoryCard(),

        // 加速结果
        if (_boostResult != null) _buildResultCard(),

        // 进程列表标题
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Text(
                '后台进程',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  final allSelected = _processes
                      .where((p) => p.canKill)
                      .every((p) => p.isSelected);
                  setState(() {
                    for (final p in _processes) {
                      if (p.canKill) p.isSelected = !allSelected;
                    }
                  });
                },
                child: Row(
                  children: [
                    Icon(
                      _processes.where((p) => p.canKill).every((p) => p.isSelected)
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: const Color(0xFF2196F3),
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    const Text('全选', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 进程列表
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _processes.length,
            itemBuilder: (context, index) {
              return _buildProcessCard(_processes[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMemoryCard() {
    final totalKb = _memoryInfo?['totalMemoryKb'] ?? 1;
    final usedKb = _memoryInfo?['usedMemoryKb'] ?? 0;
    final percent = totalKb > 0 ? (usedKb / totalKb).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: percent > 0.8
              ? [Colors.red[400]!, Colors.red[600]!]
              : percent > 0.6
                  ? [const Color(0xFFFF9800), const Color(0xFFF57C00)]
                  : [const Color(0xFF4CAF50), const Color(0xFF388E3C)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RotationTransition(
                turns: _isBoosting
                    ? Tween(begin: 0.0, end: 1.0).animate(_animController)
                    : const AlwaysStoppedAnimation(0),
                child: const Icon(Icons.speed, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 12),
              Column(
                children: [
                  Text(
                    '${(percent * 100).toInt()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '内存使用率',
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 10,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMemoryStat('总计', _formatKb(totalKb)),
              _buildMemoryStat('已用', _formatKb(usedKb)),
              _buildMemoryStat('可用', _formatKb(totalKb - usedKb)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMemoryStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildResultCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF50).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '加速完成！',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4CAF50),
                  ),
                ),
                Text(
                  '释放内存 ${_boostResult!.formattedFreedMemory}，关闭 ${_boostResult!.killedProcesses} 个进程',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessCard(ProcessInfo process) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: process.isForeground
              ? Colors.blue.withOpacity(0.3)
              : Colors.grey[200]!,
        ),
      ),
      child: ListTile(
        dense: true,
        leading: GestureDetector(
          onTap: process.canKill
              ? () => setState(() => process.isSelected = !process.isSelected)
              : null,
          child: Icon(
            process.isSelected
                ? Icons.check_circle
                : Icons.radio_button_unchecked,
            color: process.canKill
                ? (process.isSelected
                    ? const Color(0xFF2196F3)
                    : Colors.grey[400])
                : Colors.grey[300],
            size: 22,
          ),
        ),
        title: Text(
          process.name,
          style: TextStyle(
            fontSize: 14,
            fontWeight: process.isForeground
                ? FontWeight.w600
                : FontWeight.normal,
            color: process.canKill ? Colors.black87 : Colors.grey,
          ),
        ),
        subtitle: Row(
          children: [
            if (process.isSystem)
              Container(
                margin: const EdgeInsets.only(right: 4),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '系统',
                  style: TextStyle(fontSize: 9, color: Colors.orange),
                ),
              ),
            if (process.isForeground)
              Container(
                margin: const EdgeInsets.only(right: 4),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '前台',
                  style: TextStyle(fontSize: 9, color: Colors.blue),
                ),
              ),
            Text(
              'CPU ${process.cpuPercent}%',
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ),
        trailing: Text(
          process.formattedMemory,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: process.memoryKb > 300 * 1024
                ? Colors.red
                : const Color(0xFFE91E63),
          ),
        ),
      ),
    );
  }

  Widget? _buildBottomBar() {
    if (_isLoading || _processes.isEmpty) return null;

    final selectedCount = _processes.where((p) => p.isSelected).length;

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            '可释放 ${_formatKb(_totalCleanableKb)}',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const Spacer(),
          FilledButton(
            onPressed: selectedCount > 0 && !_isBoosting ? _boost : null,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: _isBoosting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    '一键加速',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
          ),
        ],
      ),
    );
  }

  String _formatKb(int kb) {
    if (kb < 1024) return '${kb}KB';
    return '${(kb / 1024).toStringAsFixed(1)}GB';
  }
}
