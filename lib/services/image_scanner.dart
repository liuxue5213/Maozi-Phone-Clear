import 'dart:io';
import 'package:photo_manager/photo_manager.dart';
import '../models/image_file.dart';

class ImageScanner {
  /// 扫描图片 - 使用 MediaStore API (photo_manager)
  Future<Map<ImageCategory, List<ImageFileItem>>> scanImages() async {
    final Map<ImageCategory, List<ImageFileItem>> result = {};

    // 请求权限
    final ps = await PhotoManager.requestPermissionExtend();
    if (!ps.isAuth && !ps.hasAccess) {
      return result;
    }

    // 使用 MediaStore 查询图片
    final assetPaths = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: false,
    );

    for (final path in assetPaths) {
      final assets = await path.getAssetListPaged(page: 0, size: 1000);
      
      for (final asset in assets) {
        try {
          final file = await asset.file;
          if (file == null) continue;

          final stat = await file.stat();
          final fileName = asset.title ?? file.path.split('/').last;
          
          // 判断分类
          ImageCategory category;
          final pathLower = file.path.toLowerCase();
          if (pathLower.contains('screenshot')) {
            category = ImageCategory.screenshot;
          } else {
            category = ImageCategory.similar;
          }

          result.putIfAbsent(category, () => []).add(ImageFileItem(
            path: file.path,
            name: fileName,
            sizeBytes: stat.size,
            createdDate: asset.createDateTime,
            width: asset.width,
            height: asset.height,
            category: category,
          ));
        } catch (e) {
          // 跳过无法读取的文件
        }
      }
    }

    return result;
  }

  Future<int> deleteImages(List<ImageFileItem> images) async {
    int freed = 0;
    for (final img in images) {
      try {
        await PhotoManager.editor.deleteWithIds([img.path]);
        freed += img.sizeBytes;
      } catch (e) {
        // 尝试直接删除文件
        try {
          final file = File(img.path);
          if (await file.exists()) {
            await file.delete();
            freed += img.sizeBytes;
          }
        } catch (_) {}
      }
    }
    return freed;
  }

  Future<List<SimilarImageGroup>> scanSimilarImages() async {
    final images = await scanImages();
    final allImages = images.values.expand((l) => l).toList();
    final Map<int, List<ImageFileItem>> groups = {};
    for (final img in allImages) {
      final key = (img.sizeBytes ~/ 102400) * 102400;
      groups.putIfAbsent(key, () => []).add(img);
    }
    return groups.entries.where((e) => e.value.length >= 2).map((e) => SimilarImageGroup(images: e.value)).toList();
  }
}
