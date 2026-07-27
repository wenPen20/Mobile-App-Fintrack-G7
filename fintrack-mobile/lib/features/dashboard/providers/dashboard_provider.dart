import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_service.dart';

// Fetches the summary data for the last 6 months concurrently to generate charts
final dashboardTrendProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final now = DateTime.now();
  
  final List<Future<Map<String, dynamic>>> futures = [];
  
  // Query last 6 months (oldest to newest)
  for (int i = 5; i >= 0; i--) {
    final targetDate = DateTime(now.year, now.month - i);
    futures.add(api.getSummary(targetDate.month, targetDate.year));
  }
  
  return Future.wait(futures);
});

final budgetSummaryProvider = FutureProvider.family<Map<String, dynamic>, DateTime>((ref, date) async {
  final api = ref.watch(apiServiceProvider);
  return api.getSummary(date.month, date.year);
});

final profileProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.getProfile();
});

final recentTransactionsProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final now = DateTime.now();
  return api.getTransactions(month: now.month, year: now.year);
});

class BudgetModel {
  final String categoryName;
  final double limit;

  BudgetModel({required this.categoryName, required this.limit});
}

final budgetsProvider = FutureProvider.family<List<BudgetModel>, DateTime>((ref, date) async {
  final api = ref.watch(apiServiceProvider);
  final rawBudgets = await api.getBudgets(month: date.month, year: date.year);
  return rawBudgets.map((b) {
    return BudgetModel(
      categoryName: b['category_name'] ?? 'General',
      limit: (b['amount_limit'] ?? b['limit'] ?? 0.0 as num).toDouble(),
    );
  }).toList();
});
