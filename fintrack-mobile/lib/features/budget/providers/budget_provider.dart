import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_service.dart';
import '../models/category_budget.dart';
import '../models/category.dart';

// family provider to load budgets for a selected month/year
final budgetsProvider = FutureProvider.family<List<CategoryBudget>, DateTime>((ref, monthDate) async {
  final api = ref.watch(apiServiceProvider);
  final raw = await api.getBudgets(month: monthDate.month, year: monthDate.year);
  return raw.map((json) {
    return CategoryBudget(
      category: Category(
        id: json['category_id'] as String,
        name: json['category_name'] ?? 'Unknown',
        icon: json['category_icon'] ?? 'category',
        colorHex: json['category_color_hex'] ?? '#888888',
        type: 'expense',
        isDefault: true,
      ),
      limit: (json['amount_limit'] as num).toDouble(),
    );
  }).toList();
});

// Fetches dynamic financial calculations (total income, expenses, net) for a specific month
final budgetSummaryProvider = FutureProvider.family<Map<String, dynamic>, DateTime>((ref, date) async {
  final api = ref.watch(apiServiceProvider);
  return api.getSummary(date.month, date.year);
});

// provider/function to configure a budget and invalidate relevant caches
final setBudgetProvider = Provider((ref) {
  return ({
    required String categoryId,
    required double limit,
    required DateTime monthDate,
  }) async {
    final api = ref.read(apiServiceProvider);
    
    final payload = {
      'category_id': categoryId,
      'amount_limit': limit,
      'month': monthDate.month,
      'year': monthDate.year,
    };
    
    await api.createBudget(payload);
    
    // Refresh budgets list and summary for that month
    ref.invalidate(budgetsProvider(monthDate));
    ref.invalidate(budgetSummaryProvider(monthDate));
  };
});

// Fetches all real categories for the user (triggers seeding on first call)
final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final raw = await api.getCategories();
  return raw.map((json) => Category.fromJson(json as Map<String, dynamic>)).toList();
});


