// lib/features/profile/screens/category_management_screen.dart
//
// Full-screen category manager accessible from the Profile page.
// Two tabs: Expense | Income. Each shows the user's categories with
// edit and delete actions. FAB opens the AddEditCategorySheet to create new ones.
// Supports drag-and-drop reordering of categories, saved locally via SharedPreferences.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fintrack_mobile/core/constants/app_colors.dart';
import 'package:fintrack_mobile/core/constants/app_text_styles.dart';
import 'package:fintrack_mobile/core/constants/category_visuals.dart';
import 'package:fintrack_mobile/features/budget/models/category.dart';
import 'package:fintrack_mobile/features/profile/providers/category_provider.dart';
import 'widgets/add_edit_category_sheet.dart';

class CategoryManagementScreen extends ConsumerStatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  ConsumerState<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState
    extends ConsumerState<CategoryManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openSheet({Category? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AddEditCategorySheet(existing: existing),
    );
  }

  Future<void> _confirmDelete(Category category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text(
          'Delete "${category.name}"? This cannot be undone.\n\n'
          'If this category is used by any budgets or transactions it cannot be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref.read(deleteCategoryProvider)(category.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${category.name}" deleted'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _reorder(List<Category> subList, int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;

    final reordered = List<Category>.from(subList);
    final item = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, item);

    // Get the full sorted list and replace the subList section with reordered
    final all = ref.read(sortedCategoriesProvider).value ?? [];
    final otherType = item.type == 'expense' ? 'income' : 'expense';
    final others = all.where((c) => c.type == otherType).toList();

    final allOrderedIds = [
      ...reordered.map((c) => c.id),
      ...others.map((c) => c.id),
    ];

    // Must be applied synchronously. ReorderableListView keys every row with a
    // GlobalKey derived from the row's ValueKey and assumes the list it rebuilds
    // right after onReorder returns is already in the new order. Deferring this
    // (e.g. to a post-frame callback) reparents those GlobalKeys a frame late,
    // which drops the reorder or crashes the list if another drag is in flight.
    ref.read(categoryOrderProvider.notifier).updateOrder(allOrderedIds);
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(sortedCategoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Categories', style: AppTextStyles.headingSmall),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Expense'),
            Tab(text: 'Income'),
          ],
        ),
      ),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: AppColors.error,
                  size: 40,
                ),
                const SizedBox(height: 12),
                Text(
                  e.toString().replaceAll('Exception: ', ''),
                  style: AppTextStyles.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        data: (categories) {
          final expenses = categories
              .where((c) => c.type == 'expense')
              .toList();
          final incomes = categories.where((c) => c.type == 'income').toList();

          return TabBarView(
            controller: _tabController,
            children: [_buildList(expenses), _buildList(incomes)],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openSheet(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Category'),
      ),
    );
  }

  Widget _buildList(List<Category> categories) {
    if (categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.category_outlined,
              size: 56,
              color: AppColors.textSecondary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No categories yet.\nTap + to add one.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: categories.length,
      onReorder: (oldIndex, newIndex) =>
          _reorder(categories, oldIndex, newIndex),
      itemBuilder: (context, index) {
        final cat = categories[index];
        final color = colorFromHex(cat.colorHex);

        return Container(
          key: ValueKey(cat.id),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 4,
            ),
            leading: CircleAvatar(
              radius: 20,
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(iconForName(cat.icon), color: color, size: 18),
            ),
            title: Text(
              cat.name,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  onPressed: () => _openSheet(existing: cat),
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.error,
                    size: 20,
                  ),
                  onPressed: () => _confirmDelete(cat),
                  tooltip: 'Delete',
                ),
                ReorderableDragStartListener(
                  index: index,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      Icons.drag_indicator,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
