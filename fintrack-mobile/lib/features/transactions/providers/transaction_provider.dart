import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_service.dart';
import '../../budget/providers/budget_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart'
    as dashboard;
import '../models/transaction_model.dart';

// family provider to load transactions on demand for a selected month
final transactionsProvider =
    FutureProvider.family<List<TransactionModel>, DateTime>((
      ref,
      monthDate,
    ) async {
      final api = ref.watch(apiServiceProvider);
      final raw = await api.getTransactions(
        month: monthDate.month,
        year: monthDate.year,
      );
      return raw.map((json) => TransactionModel.fromJson(json)).toList();
    });

// provider to fetch the most recent transactions across all months for the dashboard
final recentTransactionsProvider = FutureProvider<List<TransactionModel>>((
  ref,
) async {
  final api = ref.watch(apiServiceProvider);
  final list = await api.getTransactions();
  final txs = list.map((json) => TransactionModel.fromJson(json)).toList();
  // Sort descending by date (newest first)
  txs.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
  return txs.take(5).toList();
});

/// Invalidates all providers that depend on transaction data so the UI
/// (transaction list, dashboard cards, chart) stays in sync after a mutation.
/// After invalidation, eagerly reads the dashboard providers to trigger a
/// background refetch so fresh data is already cached when the user navigates
/// back to the dashboard (instead of showing a loading spinner).
void _invalidateAll(Ref ref) {
  final now = DateTime.now();
  final monthDate = DateTime(now.year, now.month);

  // Transaction page
  ref.invalidate(transactionsProvider);
  ref.invalidate(recentTransactionsProvider);

  // Budget page
  ref.invalidate(budgetSummaryProvider(monthDate));
  ref.invalidate(budgetsProvider(monthDate));

  // Dashboard page
  ref.invalidate(dashboard.budgetSummaryProvider(monthDate));
  ref.invalidate(dashboard.budgetsProvider(monthDate));
  ref.invalidate(dashboard.recentTransactionsProvider);
  ref.invalidate(dashboard.dashboardTrendProvider);
}

// provider/function to add a transaction and invalidate relevant caches
final addTransactionProvider = Provider((ref) {
  return ({
    required String categoryId,
    required String type,
    required double amount,
    String? title,
    String? note,
    required DateTime transactionDate,
  }) async {
    final api = ref.read(apiServiceProvider);

    final payload = {
      'category_id': categoryId,
      'type': type,
      'amount': amount,
      'title': title,
      'note': note,
      'transaction_date': transactionDate.toUtc().toIso8601String(),
    };

    await api.createTransaction(payload);
    _invalidateAll(ref);
  };
});

// provider/function to update a transaction and invalidate relevant caches
final updateTransactionProvider = Provider((ref) {
  return ({
    required String transactionId,
    required Map<String, dynamic> data,
  }) async {
    final api = ref.read(apiServiceProvider);
    await api.updateTransaction(transactionId, data);
    _invalidateAll(ref);
  };
});

// provider/function to delete a transaction and invalidate relevant caches
final deleteTransactionProvider = Provider((ref) {
  return ({required String transactionId}) async {
    final api = ref.read(apiServiceProvider);
    await api.deleteTransaction(transactionId);
    _invalidateAll(ref);
  };
});
