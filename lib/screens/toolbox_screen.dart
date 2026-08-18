import 'package:flutter/material.dart';
import 'phone_boost_screen.dart';
import 'cpu_cooler_screen.dart';
import 'antivirus_screen.dart';
import 'database_optimize_screen.dart';

/// 工具箱页面 - 整合所有系统工具
class ToolboxScreen extends StatelessWidget {
  const ToolboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          '工具箱',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF2196F3),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 系统加速
          _buildSectionTitle('🚀 系统加速'),
          _buildToolCard(
            context,
            icon: Icons.speed_rounded,
            title: '手机加速',
            subtitle: '清理后台进程，释放运行内存',
            color: const Color(0xFF2196F3),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PhoneBoostScreen()),
            ),
          ),
          _buildToolCard(
            context,
            icon: Icons.thermostat_rounded,
            title: 'CPU降温',
            subtitle: '检测发热应用，降低手机温度',
            color: const Color(0xFFFF5722),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CpuCoolerScreen()),
            ),
          ),

          const SizedBox(height: 16),

          // 安全防护
          _buildSectionTitle('🛡️ 安全防护'),
          _buildToolCard(
            context,
            icon: Icons.security_rounded,
            title: '病毒查杀',
            subtitle: '全盘扫描，检测恶意软件和病毒',
            color: const Color(0xFFF44336),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AntivirusScreen()),
            ),
          ),

          const SizedBox(height: 16),

          // 高级优化
          _buildSectionTitle('⚡ 高级优化'),
          _buildToolCard(
            context,
            icon: Icons.storage_rounded,
            title: '数据库优化',
            subtitle: '优化应用数据库，减少碎片空间',
            color: const Color(0xFF9C27B0),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DatabaseOptimizeScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF666666),
        ),
      ),
    );
  }

  Widget _buildToolCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 26),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
        onTap: onTap,
      ),
    );
  }
}
