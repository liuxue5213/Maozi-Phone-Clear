import 'package:flutter/material.dart';
import '../services/cpu_cooler_service.dart';
import '../services/permission_service.dart';
import '../widgets/permission_request_widget.dart';

/// CPU降温页面
class CpuCoolerScreen extends StatefulWidget {
  const CpuCoolerScreen({super.key});

  @override
  State<CpuCoolerScreen> createState() => _CpuCoolerScreenState();
}

class _CpuCoolerScreenState extends State<CpuCoolerScreen> {
  final CpuCoolerService _service = CpuCoolerService();
  int _cpuTemp = 0;
  List<HotApp> _hotApps = [];
  bool _isLoading = true;
  bool _isCooling = false;
  bool _hasPermission = true;
  CoolResult? _coolResult;

  @override
  void initState() {
    super.initState();
    _checkPermissionAndLoad();
  }

  Future<void> _checkPermissionAndLoad() async {
    final hasPermission = await PermissionService.hasStoragePermission();
    if (!mounted) return;
    setState(() => _hasPermission = hasPermission);
    
    if (hasPermission) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _coolResult = null;
    });

    final temp = await _service.getCpuTemperature();
    final apps = await _service.getHotApps();

    if (!mounted) return;
    setState(() {
      _cpuTemp = temp;
      _hotApps = apps;
      _isLoading = false;
    });
  }

  Future<void> _coolDown() async {
    final selected = _hotApps.where((a) => a.isSelected).toList();
    if (selected.isEmpty) return;

    setState(() => _isCooling = true);
    final result = await _service.coolDown(selected);

    if (!mounted) return;
    setState(() {
      _cpuTemp = result.temperatureAfter;
      _coolResult = result;
      _isCooling = false;
      _hotApps.removeWhere((a) => a.isSelected);
    });
  }

  @override
  Widget build(BuildContext context) {
    final status = _service.getTemperatureStatus(_cpuTemp);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'CPU降温',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFFF5722),
        elevation: 0,
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _loadData,
            ),
        ],
      ),
      body: !_hasPermission
          ? PermissionRequestWidget(
              customMessage: '为了检测CPU温度和发热应用，需要授予存储访问权限',
              onPermissionGranted: () {
                setState(() => _hasPermission = true);
                _loadData();
              },
            )
          : _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
              children: [
                // 温度显示
                _buildTemperatureCard(status),

                // 降温结果
                if (_coolResult != null) _buildResultCard(),

                // 发热应用标题
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Text(
                        '发热应用',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      Text(
                        '${_hotApps.length} 个应用',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),

                // 应用列表
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _hotApps.length,
                    itemBuilder: (context, index) {
                      return _buildAppCard(_hotApps[index]);
                    },
                  ),
                ),
              ],
            ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildTemperatureCard(TemperatureStatus status) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [status.color, status.color.withOpacity(0.7)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            '🌡️',
            style: const TextStyle(fontSize: 40),
          ),
          const SizedBox(height: 8),
          Text(
            '$_cpuTemp°C',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status.displayName,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
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
          const Icon(Icons.ac_unit, color: Color(0xFF4CAF50), size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '降温完成！',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4CAF50),
                  ),
                ),
                Text(
                  '温度降低 ${_coolResult!.temperatureReduction}°C，关闭 ${_coolResult!.killedApps} 个高耗电应用',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppCard(HotApp app) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: ListTile(
        leading: GestureDetector(
          onTap: () => setState(() => app.isSelected = !app.isSelected),
          child: Icon(
            app.isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
            color: app.isSelected ? const Color(0xFFFF5722) : Colors.grey[400],
            size: 22,
          ),
        ),
        title: Text(app.name, style: const TextStyle(fontSize: 14)),
        subtitle: Text('CPU ${app.cpuPercent}%', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: app.temperature > 10 ? Colors.red[50] : Colors.orange[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '+${app.temperature}°C',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: app.temperature > 10 ? Colors.red : Colors.orange,
            ),
          ),
        ),
      ),
    );
  }

  Widget? _buildBottomBar() {
    if (_isLoading || _hotApps.isEmpty) return null;

    final selectedCount = _hotApps.where((a) => a.isSelected).length;

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
            '已选 $selectedCount 个应用',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const Spacer(),
          FilledButton(
            onPressed: selectedCount > 0 && !_isCooling ? _coolDown : null,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF5722),
              disabledBackgroundColor: Colors.grey[300],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: const Text('一键降温', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
