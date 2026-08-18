# 猫子手机清理 (Maozi Phone Clean)

📱 一款基于 Flutter 开发的跨平台手机垃圾清理软件，支持 Android 和 iOS。

## 功能特性

### 🗑️ 垃圾清理（首页）
- 🔍 **智能扫描** — 扫描应用缓存、日志文件、临时文件、残留文件、安装包、大文件
- ✅ **安全勾选** — 按分类展示，支持全选/单选，清理前二次确认
- 🧹 **深度清理** — 一键清理勾选的垃圾文件，释放存储空间
- 📊 **统计展示** — 实时显示扫描/清理的文件大小

### 📊 存储分析
- 交互式饼图展示存储分布
- 各类文件大小占比一目了然
- 总存储/已用/可用空间展示

### 📋 重复文件检测
- 按文件大小分组 + 哈希比对
- 智能保留建议（保留最早/最大版本）
- 显示每组浪费空间
- 一键清理重复项

### 📁 大文件管理
- 扫描 >50MB 的大文件
- 按类型筛选（视频/音频/图片/文档/压缩包/安装包）
- 按大小/时间排序
- 删除前二次确认

### 📸 图片清理
- 📸 截图专项清理
- 🔍 连拍照片智能筛选（保留最佳）
- 🖼️ 相似图片检测（保留最高清）
- 📁 缩略图缓存清理

## 项目结构

```
maozi-phone-clear/
├── .github/workflows/           # GitHub Actions CI/CD
│   ├── build-android.yml        # Android APK/AAB 构建
│   └── build-ios.yml            # iOS IPA 构建
├── android/                     # Android 原生配置
├── ios/                         # iOS 原生配置
├── lib/
│   ├── main.dart                # 应用入口 + 底部导航
│   ├── models/
│   │   ├── junk_item.dart       # 垃圾文件数据模型
│   │   ├── duplicate_file.dart  # 重复文件模型
│   │   ├── large_file.dart      # 大文件模型
│   │   └── image_file.dart      # 图片清理模型
│   ├── providers/
│   │   └── clean_provider.dart  # 状态管理 (Provider)
│   ├── screens/
│   │   ├── scan_screen.dart     # 扫描页
│   │   ├── select_screen.dart   # 勾选页
│   │   ├── clean_screen.dart    # 清理结果页
│   │   ├── storage_analysis_screen.dart  # 存储分析饼图
│   │   ├── duplicate_files_screen.dart   # 重复文件页
│   │   ├── large_files_screen.dart       # 大文件管理页
│   │   └── image_cleanup_screen.dart     # 图片清理页
│   └── services/
│       ├── scanner_service.dart      # 垃圾扫描服务
│       ├── duplicate_scanner.dart    # 重复文件扫描
│       ├── large_file_scanner.dart   # 大文件扫描
│       ├── image_scanner.dart        # 图片清理扫描
│       └── whitelist_service.dart    # 白名单/安全机制
├── test/                        # 单元测试
└── pubspec.yaml                 # Flutter 项目配置
```

## 工作流程

```
┌─────────────────────────────────────────────────────┐
│                    底部 Tab 导航                      │
├─────────┬─────────┬─────────┬─────────┬─────────────┤
│  首页    │ 存储分析 │ 重复文件 │  大文件  │  图片清理   │
│         │         │         │         │             │
│ 开始扫描 │  饼图    │ 哈希比对 │ 大小筛选 │ 截图/连拍   │
│    ↓    │  占比    │ 智能选择 │ 类型筛选 │ 相似图片    │
│ 勾选清理 │         │ 一键清理 │ 删除确认 │ 缩略图      │
│    ↓    │         │         │         │             │
│ 统计结果 │         │         │         │             │
└─────────┴─────────┴─────────┴─────────┴─────────────┘
```

## 本地开发

### 环境要求
- Flutter SDK >= 3.0.0
- Dart SDK >= 3.0.0
- Android Studio (Android 开发)
- Xcode (iOS 开发，仅 macOS)

### 启动项目

```bash
# 1. 安装依赖
flutter pub get

# 2. 运行调试
flutter run

# 3. 运行测试
flutter test

# 4. 代码检查
flutter analyze
```

## 构建发布

### Android
```bash
flutter build apk --release        # APK
flutter build appbundle --release  # AAB (Google Play)
```

### iOS
```bash
flutter build ios --release --no-codesign
```

## GitHub Actions 自动构建

推送代码到 `main` 分支自动触发：
- **Android**: 生成 APK + AAB
- **iOS**: 生成 unsigned IPA

## 技术栈

| 组件 | 选型 |
|------|------|
| 框架 | Flutter 3.24.x |
| 状态管理 | Provider |
| 图表 | fl_chart |
| 加密哈希 | crypto |
| 本地存储 | shared_preferences |
| 最低支持 | Android 5.0 (API 21) / iOS 12.0 |

## 注意事项

- 当前数据为模拟数据，生产环境需替换为真实文件系统遍历
- iOS 沙箱限制，部分功能需引导用户手动操作
- Android 11+ 需要 MANAGE_EXTERNAL_STORAGE 权限
