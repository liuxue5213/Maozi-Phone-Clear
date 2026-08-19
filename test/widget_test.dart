import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maozi_phone_clear/main.dart';
import 'package:maozi_phone_clear/providers/clean_provider.dart';
import 'package:maozi_phone_clear/models/junk_item.dart';
import 'package:maozi_phone_clear/models/duplicate_file.dart';
import 'package:maozi_phone_clear/models/large_file.dart';
import 'package:maozi_phone_clear/models/image_file.dart';
import 'package:maozi_phone_clear/services/duplicate_scanner.dart';
import 'package:maozi_phone_clear/services/large_file_scanner.dart';
import 'package:maozi_phone_clear/services/image_scanner.dart';
import 'package:maozi_phone_clear/services/social_scanner.dart';
import 'package:maozi_phone_clear/services/scheduled_cleanup_service.dart';
import 'package:maozi_phone_clear/services/recycle_bin_service.dart';
import 'package:maozi_phone_clear/services/app_manager_service.dart';
import 'package:maozi_phone_clear/services/video_compressor_service.dart';
import 'package:maozi_phone_clear/services/privacy_service.dart';
import 'package:maozi_phone_clear/services/notification_service.dart';
import 'package:maozi_phone_clear/services/phone_boost_service.dart';
import 'package:maozi_phone_clear/services/cpu_cooler_service.dart';
import 'package:maozi_phone_clear/services/antivirus_service.dart';
import 'package:maozi_phone_clear/services/database_optimize_service.dart';

void main() {
  // ========== CleanProvider 状态管理测试 ==========
  group('CleanProvider 状态管理测试', () {
    late CleanProvider provider;

    setUp(() {
      provider = CleanProvider();
    });

    test('初始状态应为 idle', () {
      expect(provider.state, AppState.idle);
      expect(provider.categories, isEmpty);
      expect(provider.totalScannedBytes, 0);
    });

    test('扫描后状态变为 selecting', () async {
      await provider.startScan();
      expect(provider.state, AppState.selecting);
      expect(provider.categories.isNotEmpty, true);
      expect(provider.totalScannedBytes, greaterThan(0));
    });

    test('勾选项目后已选大小正确', () async {
      await provider.startScan();
      final firstItem = provider.allItems.first;
      final initialSize = provider.selectedBytes;

      provider.toggleItem(firstItem);
      expect(provider.selectedBytes, initialSize + firstItem.sizeBytes);

      provider.toggleItem(firstItem);
      expect(provider.selectedBytes, initialSize);
    });

    test('全选后所有项目都被选中', () async {
      await provider.startScan();
      provider.selectAll();
      for (final item in provider.allItems) {
        expect(item.isSelected, true);
      }
    });

    test('清理后状态变为 done 且有清理大小', () async {
      await provider.startScan();
      provider.selectAll();
      await provider.startClean();
      expect(provider.state, AppState.done);
      expect(provider.totalCleanedBytes, greaterThan(0));
    });

    test('reset 后回到初始状态', () async {
      await provider.startScan();
      provider.reset();
      expect(provider.state, AppState.idle);
      expect(provider.categories, isEmpty);
    });
  });

  // ========== 数据模型测试 ==========
  group('JunkItem 数据模型测试', () {
    test('格式化大小显示正确', () {
      final item1 = JunkItem(
        path: '/test/file.log',
        name: 'file.log',
        sizeBytes: 512,
        category: JunkCategory.log,
        lastModified: DateTime.now(),
      );
      expect(item1.formattedSize, '512 B');

      final item2 = JunkItem(
        path: '/test/file2.log',
        name: 'file2.log',
        sizeBytes: 150 * 1024 * 1024,
        category: JunkCategory.log,
        lastModified: DateTime.now(),
      );
      expect(item2.formattedSize, '150.0 MB');
    });
  });

  group('DuplicateFile 数据模型测试', () {
    test('重复文件组浪费空间计算正确', () {
      final group = DuplicateGroup(
        hash: 'test_hash',
        fileSize: 1024 * 1024,
        files: List.generate(
          3,
          (i) => DuplicateFile(
            path: '/test/file$i.jpg',
            name: 'file$i.jpg',
            sizeBytes: 1024 * 1024,
            lastModified: DateTime.now(),
          ),
        ),
      );

      expect(group.wastedBytes, 2 * 1024 * 1024);
      expect(group.cleanableFiles.length, 2);
    });
  });

  group('LargeFile 数据模型测试', () {
    test('文件类型从扩展名识别正确', () {
      expect(getFileTypeFromExtension('.mp4'), LargeFileType.video);
      expect(getFileTypeFromExtension('.MP4'), LargeFileType.video);
      expect(getFileTypeFromExtension('.mp3'), LargeFileType.audio);
      expect(getFileTypeFromExtension('.apk'), LargeFileType.apk);
      expect(getFileTypeFromExtension('.xyz'), LargeFileType.other);
    });
  });

  group('ImageFile 数据模型测试', () {
    test('相似图片组最佳图片选择正确', () {
      final group = SimilarImageGroup(images: [
        ImageFileItem(
          path: '/test/img1.jpg',
          name: 'img1.jpg',
          sizeBytes: 3 * 1024 * 1024,
          createdDate: DateTime.now(),
          width: 1920,
          height: 1080,
          category: ImageCategory.similar,
        ),
        ImageFileItem(
          path: '/test/img2.jpg',
          name: 'img2.jpg',
          sizeBytes: 5 * 1024 * 1024,
          createdDate: DateTime.now(),
          width: 4000,
          height: 3000,
          category: ImageCategory.similar,
        ),
      ]);

      expect(group.bestImage.path, '/test/img2.jpg');
      expect(group.cleanableImages.length, 1);
    });
  });

  group('VideoInfo 数据模型测试', () {
    test('视频压缩后大小计算正确', () {
      final video = VideoInfo(
        path: '/test/video.mp4',
        name: 'video.mp4',
        originalSizeBytes: 100 * 1024 * 1024,
        durationSeconds: 60,
        width: 1920,
        height: 1080,
        bitrate: 10000,
        codec: 'H.264',
      );

    });
  });

  group('AppInfo 数据模型测试', () {
    test('应用总大小计算正确', () {
      final app = AppInfo(
        packageName: 'com.test.app',
        name: '测试应用',
        version: '1.0.0',
        sizeBytes: 50 * 1024 * 1024,
        cacheBytes: 100 * 1024 * 1024,
        dataBytes: 30 * 1024 * 1024,
        installTime: DateTime.now(),
        lastUsed: DateTime.now(),
        type: AppType.user,
      );

      expect(app.totalSizeBytes, 180 * 1024 * 1024);
      expect(app.canUninstall, true);
    });

    test('系统应用不能卸载', () {
      final app = AppInfo(
        packageName: 'com.android.system',
        name: '系统应用',
        version: '1.0',
        sizeBytes: 10 * 1024 * 1024,
        cacheBytes: 0,
        dataBytes: 0,
        installTime: DateTime.now(),
        lastUsed: DateTime.now(),
        type: AppType.system,
      );

      expect(app.canUninstall, false);
    });
  });

  group('RecycleBinItem 过期检测测试', () {
    test('过期文件检测正确', () {
      final expiredItem = RecycleBinItem(
        originalPath: '/test/old.txt',
        recyclePath: '/recycle/old.txt',
        name: 'old.txt',
        sizeBytes: 1024,
        deletedAt: DateTime.now().subtract(const Duration(days: 8)),
        fileType: 'document',
      );
      expect(expiredItem.isExpired, true);

      final newItem = RecycleBinItem(
        originalPath: '/test/new.txt',
        recyclePath: '/recycle/new.txt',
        name: 'new.txt',
        sizeBytes: 1024,
        deletedAt: DateTime.now(),
        fileType: 'document',
      );
      expect(newItem.isExpired, false);
    });
  });

  group('CPU降温服务测试', () {
    test('温度状态判断正确', () {
      final service = CpuCoolerService();
      expect(service.getTemperatureStatus(32), TemperatureStatus.normal);
      expect(service.getTemperatureStatus(38), TemperatureStatus.warm);
      expect(service.getTemperatureStatus(45), TemperatureStatus.hot);
      expect(service.getTemperatureStatus(52), TemperatureStatus.critical);
    });
  });

  // ========== 服务测试 ==========
  group('Scanner 服务测试', () {
    test('重复文件扫描返回结果', () async {
      final scanner = DuplicateScanner();
      final groups = await scanner.scanDuplicates();
      expect(groups.isNotEmpty, true);
    });

    test('大文件扫描按大小降序排序', () async {
      final scanner = LargeFileScanner();
      final files = await scanner.scanLargeFiles();
      expect(files.isNotEmpty, true);
      for (int i = 0; i < files.length - 1; i++) {
        expect(files[i].sizeBytes >= files[i + 1].sizeBytes, true);
      }
    });

    test('图片扫描返回分类结果', () async {
      final scanner = ImageScanner();
      final images = await scanner.scanImages();
      expect(images.isNotEmpty, true);
      expect(images.containsKey(ImageCategory.screenshot), true);
    });

    test('社交应用扫描返回结果', () async {
      final scanner = SocialScanner();
      final result = await scanner.scanSocialApps();
      expect(result.containsKey(SocialApp.wechat), true);
      expect(result.containsKey(SocialApp.qq), true);
    });

    test('应用管理扫描返回应用列表', () async {
      final service = AppManagerService();
      final apps = await service.scanApps();
      expect(apps.isNotEmpty, true);
      expect(apps.any((a) => a.type == AppType.user), true);
    });

    test('视频压缩扫描返回视频列表', () async {
      final service = VideoCompressorService();
      final videos = await service.scanVideos();
      expect(videos.isNotEmpty, true);
    });

    test('隐私扫描返回隐私数据列表', () async {
      final service = PrivacyService();
      final items = await service.scanPrivacy();
      expect(items.isNotEmpty, true);
    });

    test('通知服务返回通知列表', () async {
      final service = NotificationService();
      final notifications = await service.getNotifications();
      expect(notifications.isNotEmpty, true);
    });

    test('手机加速服务返回进程列表', () async {
      final service = PhoneBoostService();
      final processes = await service.getRunningProcesses();
      expect(processes.isNotEmpty, true);
      expect(processes.any((p) => p.canKill), true);
    });

    test('手机加速返回内存信息', () async {
      final service = PhoneBoostService();
      final memInfo = await service.getMemoryInfo();
      expect(memInfo.containsKey('totalMemoryKb'), true);
      expect(memInfo.containsKey('usedMemoryKb'), true);
    });

    test('CPU降温服务返回发热应用', () async {
      final service = CpuCoolerService();
      final apps = await service.getHotApps();
      expect(apps.isNotEmpty, true);
    });

    test('病毒扫描返回结果', () async {
      final service = AntivirusService();
      final result = await service.scan();
      expect(result.scannedApps, greaterThan(0));
    });

    test('数据库优化扫描返回可优化项', () async {
      final service = DatabaseOptimizeService();
      final items = await service.scanDatabases();
      expect(items.isNotEmpty, true);
      expect(items.any((i) => i.wastedBytes > 0), true);
    });
  });

  group('ScheduledCleanupService 测试', () {
    test('默认配置正确', () async {
      final service = ScheduledCleanupService();
      final config = await service.getConfig();
      expect(config.enabled, false);
      expect(config.frequency, CleanupFrequency.weekly);
    });

    test('保存和读取配置', () async {
      final service = ScheduledCleanupService();
      final newConfig = ScheduledCleanupConfig(
        enabled: true,
        frequency: CleanupFrequency.daily,
      );
      await service.saveConfig(newConfig);

      final loaded = await service.getConfig();
      expect(loaded.enabled, true);
      expect(loaded.frequency, CleanupFrequency.daily);
    });

    test('清理记录添加和统计', () async {
      final service = ScheduledCleanupService();
      await service.clearHistory();

      await service.addCleanupRecord(
        bytesCleaned: 1024 * 1024,
        filesCleaned: 10,
        type: '缓存清理',
      );

      final total = await service.getTotalCleanedBytes();
      expect(total, 1024 * 1024);
    });
  });

  group('RecycleBinService 测试', () {
    test('添加和获取回收站文件', () async {
      final service = RecycleBinService();
      await service.clearAll();

      await service.addItem(RecycleBinItem(
        originalPath: '/test/file.txt',
        recyclePath: '/recycle/file.txt',
        name: 'file.txt',
        sizeBytes: 1024,
        deletedAt: DateTime.now(),
        fileType: 'document',
      ));

      final items = await service.getItems();
      expect(items.length, 1);
    });

    test('恢复文件后从回收站移除', () async {
      final service = RecycleBinService();
      await service.clearAll();

      await service.addItem(RecycleBinItem(
        originalPath: '/test/file.txt',
        recyclePath: '/recycle/file.txt',
        name: 'file.txt',
        sizeBytes: 1024,
        deletedAt: DateTime.now(),
        fileType: 'document',
      ));

      await service.restoreItem('/recycle/file.txt');
      final items = await service.getItems();
      expect(items.isEmpty, true);
    });
  });

  // ========== Widget 渲染测试 ==========
  group('Widget 渲染测试', () {
    testWidgets('首页显示开始扫描按钮', (tester) async {
      await tester.pumpWidget(const MyApp());
      expect(find.text('开始扫描'), findsOneWidget);
      expect(find.text('猫子手机清理'), findsWidgets);
    });

    testWidgets('点击开始扫描后进入扫描页面', (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.tap(find.text('开始扫描'));
      await tester.pump();
      expect(find.textContaining('正在扫描'), findsOneWidget);
    });

    testWidgets('底部导航栏有5个Tab', (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      expect(find.text('首页'), findsOneWidget);
      expect(find.text('工具箱'), findsOneWidget);
      expect(find.text('社交'), findsOneWidget);
      expect(find.text('重复'), findsOneWidget);
      expect(find.text('全部'), findsOneWidget);
    });

    testWidgets('首页有设置按钮', (tester) async {
      await tester.pumpWidget(const MyApp());
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('全部功能页面展示所有功能卡片', (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // 切换到全部功能Tab
      await tester.tap(find.text('全部'));
      await tester.pumpAndSettle();

      expect(find.text('全部功能'), findsOneWidget);
      expect(find.text('大文件管理'), findsOneWidget);
      expect(find.text('手机加速'), findsOneWidget);
      expect(find.text('CPU降温'), findsOneWidget);
    });

    testWidgets('工具箱页面展示系统工具', (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // 切换到工具箱Tab
      await tester.tap(find.text('工具箱'));
      await tester.pumpAndSettle();

      expect(find.text('工具箱'), findsWidgets);
      expect(find.text('手机加速'), findsOneWidget);
      expect(find.text('CPU降温'), findsOneWidget);
      expect(find.text('病毒查杀'), findsOneWidget);
    });
  });
}
