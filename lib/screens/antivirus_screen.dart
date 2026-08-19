import 'package:flutter/material.dart';
import '../services/antivirus_service.dart';

/// 病毒查杀页面
class AntivirusScreen extends StatefulWidget {
  const AntivirusScreen({super.key});

  @override
  State<AntivirusScreen> createState() => _AntivirusScreenState();
}

class _AntivirusScreenState extends State<AntivirusScreen> {
  final AntivirusService _service = AntivirusService();
  bool _isScanning = false;
  double _scanProgress = 0.0;
  ScanResult? _scanResult;
  bool _isQuarantining = false;

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _scanProgress = 0.0;
      _scanResult = null;
    });

    // 模拟扫描进度
    for (int i = 1; i <= 20; i++) {
      await Future.delayed(const Duration(milliseconds: 150));
      if (!mounted) return;
      setState(() => _scanProgress = i / 20);
    }

    final result = await _service.scan();

    if (!mounted) return;
    setState(() {
      _scanResult = result;
      _isScanning = false;
    });
  }

  Future<void> _quarantineSelected() async {
    if (_scanResult == null) return;

    final selected = _scanResult!.threats.where((t) => t.isSelected).toList();
    if (selected.isEmpty) return;

    setState(() => _isQuarantining = true);
    await _service.quarantineThreats(selected);

    setState(() {
      _scanResult!.threats.removeWhere((t) => t.isSelected);
      _isQuarantining = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已处理 ${selected.length} 个威胁'),
          backgroundColor: const Color(0xFF4CAF50),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          '病毒查杀',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFF44336),
        elevation: 0,
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBody() {
    if (_isScanning) {
      return _buildScanningView();
    }

    if (_scanResult == null) {
      return _buildIdleView();
    }

    return _buildResultView();
  }

  Widget _buildIdleView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.security, size: 100, color: Color(0xFFF44336)),
          const SizedBox(height: 24),
          const Text(
            '病毒查杀',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '全面扫描手机中的病毒、木马和恶意软件',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: _startScan,
            icon: const Icon(Icons.search, color: Colors.white),
            label: const Text('开始扫描', style: TextStyle(color: Colors.white, fontSize: 16)),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFF44336),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanningView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: CircularProgressIndicator(
              value: _scanProgress,
              strokeWidth: 6,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF44336)),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '${(_scanProgress * 100).toInt()}%',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            '正在扫描...',
            style: TextStyle(fontSize: 16, color: Color(0xFF666666)),
          ),
          const SizedBox(height: 4),
          Text(
            '已扫描 ${(_scanProgress * 156).toInt()} 个应用',
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildResultView() {
    if (_scanResult!.isClean) {
      return _buildCleanView();
    }
    return _buildThreatsView();
  }

  Widget _buildCleanView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF4CAF50).withOpacity(0.1),
            ),
            child: const Icon(Icons.check_circle, size: 60, color: Color(0xFF4CAF50)),
          ),
          const SizedBox(height: 24),
          const Text(
            '手机很安全！',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '扫描了 ${_scanResult!.scannedApps} 个应用\n${_scanResult!.scannedFiles} 个文件\n未发现任何威胁',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildThreatsView() {
    return Column(
      children: [
        // 威胁汇总
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red[400]!, Colors.red[600]!],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning, color: Colors.white, size: 40),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '发现威胁',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${_scanResult!.threatsFound} 个安全威胁需要处理',
                      style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 威胁列表
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _scanResult!.threats.length,
            itemBuilder: (context, index) {
              return _buildThreatCard(_scanResult!.threats[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildThreatCard(ThreatItem threat) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: threat.level.color.withOpacity(0.3)),
      ),
      child: ExpansionTile(
        leading: Text(threat.type.icon, style: const TextStyle(fontSize: 24)),
        title: Text(threat.appName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: threat.level.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                threat.level.displayName,
                style: TextStyle(fontSize: 11, color: threat.level.color, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              threat.type.displayName,
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ),
        trailing: Checkbox(
          value: threat.isSelected,
          onChanged: (v) => setState(() => threat.isSelected = v ?? false),
          activeColor: const Color(0xFFF44336),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(threat.description, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                const SizedBox(height: 4),
                Text(threat.filePath, style: TextStyle(fontSize: 11, color: Colors.grey[400])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildBottomBar() {
    if (_isScanning || _scanResult == null || _scanResult!.isClean) return null;

    final selectedCount = _scanResult!.threats.where((t) => t.isSelected).length;

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
            '已选 $selectedCount 个威胁',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const Spacer(),
          FilledButton(
            onPressed: selectedCount > 0 && !_isQuarantining ? _quarantineSelected : null,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFF44336),
              disabledBackgroundColor: Colors.grey[300],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: const Text('立即处理', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
