import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/clean_provider.dart';
import 'screens/scan_screen.dart';
import 'screens/select_screen.dart';
import 'screens/clean_screen.dart';
import 'screens/duplicate_files_screen.dart';
import 'screens/large_files_screen.dart';
import 'screens/image_cleanup_screen.dart';
import 'screens/social_cleanup_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/app_manager_screen.dart';
import 'screens/video_compression_screen.dart';
import 'screens/privacy_cleanup_screen.dart';
import 'screens/notification_cleanup_screen.dart';
import 'screens/toolbox_screen.dart';
import 'screens/phone_boost_screen.dart';
import 'screens/cpu_cooler_screen.dart';
import 'screens/antivirus_screen.dart';
import 'screens/database_optimize_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CleanProvider(),
      child: MaterialApp(
        title: '猫子手机清理',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2196F3)),
          useMaterial3: true,
          fontFamily: 'PingFang SC',
        ),
        home: const MainPage(),
      ),
    );
  }
}

/// 主页面 - 底部 Tab 导航
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  final List<_TabItem> _tabs = [
    _TabItem(
      icon: Icons.home_rounded,
      label: '首页',
      builder: (ctx) => const HomeTab(),
    ),
    _TabItem(
      icon: Icons.build_circle_rounded,
      label: '工具箱',
      builder: (ctx) => const ToolboxScreen(),
    ),
    _TabItem(
      icon: Icons.chat_rounded,
      label: '社交',
      builder: (ctx) => const SocialCleanupScreen(),
    ),
    _TabItem(
      icon: Icons.content_copy_rounded,
      label: '重复',
      builder: (ctx) => const DuplicateFilesScreen(),
    ),
    _TabItem(
      icon: Icons.grid_view_rounded,
      label: '全部',
      builder: (ctx) => const AllFeaturesTab(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_currentIndex].builder(context),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFF2196F3).withOpacity(0.1),
        destinations: _tabs
            .map((tab) => NavigationDestination(
                  icon: Icon(tab.icon, color: Colors.grey),
                  selectedIcon: Icon(tab.icon, color: const Color(0xFF2196F3)),
                  label: tab.label,
                ))
            .toList(),
      ),
    );
  }
}

class _TabItem {
  final IconData icon;
  final String label;
  final WidgetBuilder builder;

  _TabItem({required this.icon, required this.label, required this.builder});
}

/// 首页 Tab - 垃圾清理主流程
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          '猫子手机清理',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF2196F3),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<CleanProvider>(
        builder: (context, provider, _) {
          switch (provider.state) {
            case AppState.idle:
              return _buildIdleView(context, provider);
            case AppState.scanning:
              return const ScanScreen();
            case AppState.selecting:
              return SelectScreen(
                onStartClean: () => provider.startClean(),
              );
            case AppState.cleaning:
            case AppState.done:
              return const CleanScreen();
          }
        },
      ),
    );
  }

  Widget _buildIdleView(BuildContext context, CleanProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF2196F3),
                  const Color(0xFF2196F3).withOpacity(0.7),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2196F3).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.phone_android_rounded,
              size: 70,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '猫子手机清理',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '一键扫描手机垃圾，释放存储空间',
            style: TextStyle(fontSize: 15, color: Colors.grey[600]),
          ),
          const SizedBox(height: 48),
          FilledButton(
            onPressed: () => provider.startScan(),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
              padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 4,
            ),
            child: const Text(
              '开始扫描',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildFeatureIcon(Icons.search, '智能扫描'),
                _buildFeatureIcon(Icons.checklist, '安全勾选'),
                _buildFeatureIcon(Icons.delete_sweep, '深度清理'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureIcon(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, size: 24, color: const Color(0xFF2196F3)),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }
}

/// 全部功能 Tab
class AllFeaturesTab extends StatelessWidget {
  const AllFeaturesTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          '全部功能',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF2196F3),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 文件管理
          _buildSectionHeader('📁 文件管理'),
          _buildFeatureCard(
            context,
            icon: Icons.insert_drive_file_rounded,
            title: '大文件管理',
            subtitle: '查找并清理占用空间的大文件',
            color: const Color(0xFFFF9800),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LargeFilesScreen()),
            ),
          ),
          _buildFeatureCard(
            context,
            icon: Icons.image_rounded,
            title: '图片清理',
            subtitle: '清理截图、连拍、相似图片',
            color: const Color(0xFF4CAF50),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ImageCleanupScreen()),
            ),
          ),
          _buildFeatureCard(
            context,
            icon: Icons.video_library_rounded,
            title: '视频压缩',
            subtitle: '压缩视频文件，节省存储空间',
            color: const Color(0xFFFF5722),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const VideoCompressionScreen()),
            ),
          ),

          const SizedBox(height: 16),

          // 应用管理
          _buildSectionHeader('📱 应用管理'),
          _buildFeatureCard(
            context,
            icon: Icons.apps_rounded,
            title: '应用管理',
            subtitle: '批量卸载、清理缓存、应用冻结',
            color: const Color(0xFF2196F3),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AppManagerScreen()),
            ),
          ),

          const SizedBox(height: 16),

          // 隐私与安全
          _buildSectionHeader('🔒 隐私与安全'),
          _buildFeatureCard(
            context,
            icon: Icons.privacy_tip_rounded,
            title: '隐私清理',
            subtitle: '清理剪贴板、浏览历史、搜索记录',
            color: const Color(0xFF9C27B0),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrivacyCleanupScreen()),
            ),
          ),
          _buildFeatureCard(
            context,
            icon: Icons.notifications_off_rounded,
            title: '通知清理',
            subtitle: '批量清除无用通知',
            color: const Color(0xFF607D8B),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationCleanupScreen()),
            ),
          ),

          const SizedBox(height: 16),

          // 设置
          _buildSectionHeader('🚀 系统工具'),
          _buildFeatureCard(
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
          _buildFeatureCard(
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
          _buildFeatureCard(
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
          _buildFeatureCard(
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

          const SizedBox(height: 16),

          // 设置
          _buildSectionHeader('⚙️ 设置'),
          _buildFeatureCard(
            context,
            icon: Icons.settings_rounded,
            title: '设置',
            subtitle: '定时清理、回收站、清理统计',
            color: const Color(0xFF795548),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
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

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color),
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
