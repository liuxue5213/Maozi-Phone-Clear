import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/clean_provider.dart';
import '../models/junk_item.dart';

/// 勾选页面 - 展示扫描结果，用户勾选要清理的文件
class SelectScreen extends StatelessWidget {
  final VoidCallback onStartClean;

  const SelectScreen({super.key, required this.onStartClean});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CleanProvider>();

    return Column(
      children: [
        // 顶部汇总信息栏
        _buildSummaryHeader(provider),

        // 分类列表
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: provider.categories.length,
            itemBuilder: (context, index) {
              return _CategoryCard(
                category: provider.categories[index],
                onToggleCategory: () =>
                    provider.toggleCategory(provider.categories[index]),
                onToggleItem: provider.toggleItem,
              );
            },
          ),
        ),

        // 底部操作栏
        _buildBottomBar(provider, context),
      ],
    );
  }

  Widget _buildSummaryHeader(CleanProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2196F3),
            const Color(0xFF2196F3).withOpacity(0.8),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const Text(
              '扫描完成',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              provider.formattedScannedSize,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '共发现 ${provider.allItems.length} 个垃圾文件',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(CleanProvider provider, BuildContext context) {
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
          // 全选按钮
          GestureDetector(
            onTap: provider.selectedItems.length == provider.allItems.length
                ? provider.deselectAll
                : provider.selectAll,
            child: Row(
              children: [
                Icon(
                  provider.selectedItems.length == provider.allItems.length
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: const Color(0xFF2196F3),
                  size: 22,
                ),
                const SizedBox(width: 6),
                const Text(
                  '全选',
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF333333),
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // 已选大小
          Text(
            '已选 ${provider.formattedSelectedSize}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),

          const SizedBox(width: 12),

          // 清理按钮
          FilledButton(
            onPressed: provider.selectedItems.isNotEmpty ? onStartClean : null,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
              disabledBackgroundColor: Colors.grey[300],
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: const Text(
              '立即清理',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 分类卡片
class _CategoryCard extends StatefulWidget {
  final CategorySummary category;
  final VoidCallback onToggleCategory;
  final Function(JunkItem) onToggleItem;

  const _CategoryCard({
    required this.category,
    required this.onToggleCategory,
    required this.onToggleItem,
  });

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          // 分类头部
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  // 分类图标
                  Text(
                    widget.category.category.icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 12),

                  // 分类名称 + 文件数
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.category.category.displayName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF333333),
                          ),
                        ),
                        Text(
                          '${widget.category.items.length} 个文件',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 分类总大小
                  Text(
                    widget.category.formattedTotalSize,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2196F3),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // 分类全选复选框
                  GestureDetector(
                    onTap: widget.onToggleCategory,
                    child: Icon(
                      widget.category.allSelected
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: const Color(0xFF2196F3),
                      size: 24,
                    ),
                  ),

                  const SizedBox(width: 4),

                  // 展开/收起箭头
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ),
          ),

          // 文件列表（展开时显示）
          if (_expanded)
            ...widget.category.items.map(
              (item) => _FileListItem(
                item: item,
                onToggle: () => widget.onToggleItem(item),
              ),
            ),
        ],
      ),
    );
  }
}

/// 单个文件行
class _FileListItem extends StatelessWidget {
  final JunkItem item;
  final VoidCallback onToggle;

  const _FileListItem({required this.item, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // 复选框
            Icon(
              item.isSelected
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              color: item.isSelected
                  ? const Color(0xFF2196F3)
                  : Colors.grey[400],
              size: 22,
            ),
            const SizedBox(width: 12),

            // 文件信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF333333),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.path,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[400],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // 文件大小
            Text(
              item.formattedSize,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
