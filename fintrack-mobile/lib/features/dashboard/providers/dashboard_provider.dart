import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_service.dart';

/// Fetches the summary data for the last 6 months concurrently to generate historical trend chart
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

/// Fetches budget summary for a specific month and year.
final budgetSummaryProvider = FutureProvider.family<Map<String, dynamic>, DateTime>((ref, date) async {
  final api = ref.watch(apiServiceProvider);
  return api.getSummary(date.month, date.year);
});

/// Fetches profile details for the authenticated user.
final profileProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.getProfile();
});

/// Fetches recent transactions for the dashboard overview.
final recentTransactionsProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final txs = await api.getTransactions();
  txs.sort((a, b) {
    final dateA = DateTime.tryParse(a['transaction_date'] ?? '') ?? DateTime(1970);
    final dateB = DateTime.tryParse(b['transaction_date'] ?? '') ?? DateTime(1970);
    return dateB.compareTo(dateA); // Newest first
  });
  return txs.take(5).toList();
});

/// Simple data model representing category budget limit for dashboard displays.
class BudgetModel {
  final String categoryName;
  final double limit;

  BudgetModel({required this.categoryName, required this.limit});
}

/// Fetches list of budget models for a given month and year.
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
