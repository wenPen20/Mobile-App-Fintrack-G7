// lib/features/profile/providers/category_provider.dart
//
// Provides category CRUD actions. Each action calls the API then invalidates
// the shared categoriesProvider cache so any widget watching it refreshes.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/api_service.dart';
import '../../budget/providers/budget_provider.dart';
import '../../budget/models/category.dart';

/// Action: create a new custom category.
/// Payload keys: name, icon, color_hex, type
final createCategoryProvider = Provider((ref) {
  return (Map<String, dynamic> data) async {
    final api = ref.read(apiServiceProvider);
    await api.createCategory(data);
    ref.invalidate(categoriesProvider);
  };
});

/// Action: update an existing category (name / icon / color_hex).
/// Payload keys: any subset of name, icon, color_hex
final updateCategoryProvider = Provider((ref) {
  return (String id, Map<String, dynamic> data) async {
    final api = ref.read(apiServiceProvider);
    await api.updateCategory(id, data);
    ref.invalidate(categoriesProvider);
  };
});

/// Action: delete a category by id.
/// Throws if the category is still referenced by budgets or transactions (409).
final deleteCategoryProvider = Provider((ref) {
  return (String id) async {
    final api = ref.read(apiServiceProvider);
    await api.deleteCategory(id);
    ref.invalidate(categoriesProvider);
  };
});

// Notifier to manage the custom list order of category IDs (Riverpod 3.x).
class CategoryOrderNotifier extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('category_order') ?? [];
  }

  Future<void> updateOrder(List<String> newOrder) async {
    state = AsyncData(newOrder);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('category_order', newOrder);
  }
}

// Provider for custom category IDs sort order.
final categoryOrderProvider =
    AsyncNotifierProvider<CategoryOrderNotifier, List<String>>(
        CategoryOrderNotifier.new);

// Combines raw API categories with the locally saved custom drag-and-drop sort order.
final sortedCategoriesProvider = Provider<AsyncValue<List<Category>>>((ref) {
  final categoriesAsync = ref.watch(categoriesProvider);
  final orderAsync = ref.watch(categoryOrderProvider);

  // Combine both async states
  return categoriesAsync.whenData((categories) {
    final orderList = orderAsync.when(
      data: (d) => d,
      loading: () => <String>[],
      error: (err, st) => <String>[],
    );

    if (orderList.isEmpty) {
      return categories;
    }

    final sorted = List<Category>.from(categories);
    sorted.sort((a, b) {
      final indexA = orderList.indexOf(a.id);
      final indexB = orderList.indexOf(b.id);

      if (indexA == -1 && indexB == -1) return 0;
      if (indexA == -1) return 1; // new categories go to end
      if (indexB == -1) return -1;

      return indexA.compareTo(indexB);
    });
    return sorted;
  });
});
