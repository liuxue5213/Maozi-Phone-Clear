import 'package:flutter/foundation.dart';
import '../models/junk_item.dart';
import '../services/scanner_service.dart';
import '../utils/format_utils.dart';

/// 应用状态枚举
enum AppState {
  idle,       // 空闲/首页
  scanning,   // 扫描中
  selecting,  // 勾选中
  cleaning,   // 清理中
  done,       // 清理完成
}

/// 全局状态管理
class CleanProvider extends ChangeNotifier {
  final ScannerService _scanner = ScannerService();

  AppState _state = AppState.idle;
  List<CategorySummary> _categories = [];
  int _totalScannedBytes = 0;
  int _totalCleanedBytes = 0;
  double _progress = 0.0;
  String _statusMessage = '';

  // Getters
  AppState get state => _state;
  List<CategorySummary> get categories => _categories;
  int get totalScannedBytes => _totalScannedBytes;
  int get totalCleanedBytes => _totalCleanedBytes;
  double get progress => _progress;
  String get statusMessage => _statusMessage;

  /// 获取所有待勾选项
  List<JunkItem> get allItems {
    return _categories.expand((c) => c.items).toList();
  }

  /// 获取已勾选的文件列表
  List<JunkItem> get selectedItems {
    return allItems.where((item) => item.isSelected).toList();
  }

  /// 获取已勾选总大小
  int get selectedBytes =>
      selectedItems.fold(0, (sum, item) => sum + item.sizeBytes);

  /// 格式化已勾选大小
  String get formattedSelectedSize => FormatUtils.formatBytes(selectedBytes);

  /// 格式化扫描到的总大小
  String get formattedScannedSize => FormatUtils.formatBytes(_totalScannedBytes);

  /// 格式化已清理大小
  String get formattedCleanedSize => FormatUtils.formatBytes(_totalCleanedBytes);

  /// 开始扫描
  Future<void> startScan() async {
    _state = AppState.scanning;
    _progress = 0.0;
    _statusMessage = '正在扫描垃圾文件...';
    _categories = [];
    _totalScannedBytes = 0;
    notifyListeners();

    // 模拟扫描进度
    for (int i = 1; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      _progress = i / 10.0;
      _statusMessage = '扫描中... ${(i * 10)}%';
      notifyListeners();
    }

    // 执行扫描
    _categories = await _scanner.scanAll();
    _totalScannedBytes =
        _categories.fold(0, (sum, cat) => sum + cat.totalSizeBytes);

    _state = AppState.selecting;
    _statusMessage = '扫描完成，发现 ${FormatUtils.formatBytes(_totalScannedBytes)} 垃圾';
    notifyListeners();
  }

  /// 勾选/取消单个项目
  void toggleItem(JunkItem item) {
    item.isSelected = !item.isSelected;
    notifyListeners();
  }

  /// 全选/取消全选某分类
  void toggleCategory(CategorySummary category) {
    final bool target = !category.allSelected;
    for (final item in category.items) {
      item.isSelected = target;
    }
    notifyListeners();
  }

  /// 全选所有
  void selectAll() {
    for (final item in allItems) {
      item.isSelected = true;
    }
    notifyListeners();
  }

  /// 取消全选
  void deselectAll() {
    for (final item in allItems) {
      item.isSelected = false;
    }
    notifyListeners();
  }

  /// 开始清理
  Future<void> startClean() async {
    if (selectedItems.isEmpty) return;

    _state = AppState.cleaning;
    _progress = 0.0;
    _statusMessage = '正在清理...';
    notifyListeners();

    final items = List<JunkItem>.from(selectedItems);

    for (int i = 0; i < items.length; i++) {
      // 模拟每个文件的清理
      await Future.delayed(const Duration(milliseconds: 30));
      _progress = (i + 1) / items.length;
      _statusMessage = '清理中... ${((i + 1) / items.length * 100).toInt()}%';
      notifyListeners();
    }

    // 实际执行清理
    _totalCleanedBytes = await _scanner.cleanSelected(items);

    _state = AppState.done;
    _statusMessage = '清理完成！';
    notifyListeners();
  }

  /// 重置到首页
  void reset() {
    _state = AppState.idle;
    _categories = [];
    _totalScannedBytes = 0;
    _totalCleanedBytes = 0;
    _progress = 0.0;
    _statusMessage = '';
    notifyListeners();
  }

  /// 测试用：添加分类数据（仅用于测试）
  void addTestCategory(CategorySummary category) {
    _categories.add(category);
    _totalScannedBytes += category.totalSizeBytes;
    notifyListeners();
  }
}
