// lib/features/budget/utils/budget_helpers.dart
//
// Pure functions that turn (budgets + transactions + a selected month) into
// the numbers the budget UI needs: how much was spent per category, and the
// overall monthly totals. Same input -> same output, no stored state.

import '../models/category_budget.dart';
import '../models/category.dart';
import 'package:fintrack_mobile/features/transactions/models/transaction_model.dart';
import '../models/transaction_ui.dart';
import 'transaction_helpers.dart';

/// One category's budget progress for a given month: its limit, how much was
/// actually spent, and the derived over-budget state.
class CategoryBudgetProgress {
  final CategoryBudget budget;
  final double spent;

  const CategoryBudgetProgress({required this.budget, required this.spent});

  // 0.0-1.0, capped at 1.0 so the progress bar never overflows past full width.
  double get progress =>
      budget.limit <= 0 ? 0 : (spent / budget.limit).clamp(0, 1);

  bool get isOverBudget => spent > budget.limit;

  double get overAmount => isOverBudget ? spent - budget.limit : 0;
}

/// For each budget, sum that category's expense transactions in [month].
List<CategoryBudgetProgress> budgetProgressForMonth(
  List<CategoryBudget> budgets,
  List<TransactionUi> transactions,
  DateTime month,
) {
  final monthExpenses = inMonth(
    transactions,
    month,
  ).where((t) => t.isExpense).toList();

  return budgets.map((budget) {
    final spent = monthExpenses
        .where((t) => t.category.id == budget.category.id)
        .fold<double>(0, (sum, t) => sum + t.amount.abs());
    return CategoryBudgetProgress(budget: budget, spent: spent);
  }).toList();
}

/// The overall "Monthly Budget" card numbers: total limit across all
/// categories, total spent, and how many categories went over.
class MonthlyBudgetSummary {
  final double totalBudget;
  final double totalSpent;
  final int categoriesOverBudget;

  const MonthlyBudgetSummary({
    required this.totalBudget,
    required this.totalSpent,
    required this.categoriesOverBudget,
  });

  double get progress =>
      totalBudget <= 0 ? 0 : (totalSpent / totalBudget).clamp(0, 1);
}

MonthlyBudgetSummary summarizeMonth(List<CategoryBudgetProgress> items) {
  final totalBudget = items.fold<double>(0, (sum, i) => sum + i.budget.limit);
  final totalSpent = items.fold<double>(0, (sum, i) => sum + i.spent);
  final over = items.where((i) => i.isOverBudget).length;
  return MonthlyBudgetSummary(
    totalBudget: totalBudget,
    totalSpent: totalSpent,
    categoriesOverBudget: over,
  );
}

/// "RM 1234.56" — matches the format TransactionUi.displayAmount uses.
String formatCurrency(double value) => 'RM ${value.toStringAsFixed(2)}';

/// Converts a [TransactionModel] (the API/data layer type) into a
/// [TransactionUi] (the presentation layer type) that the budget helpers
/// and widgets already understand.
///
/// The API returns category_icon and category_color_hex directly from the
/// joined categories row, so we use those when present. Safe fallbacks are
/// provided for any rows that might be missing them.
TransactionUi transactionModelToUi(TransactionModel model) {
  return TransactionUi(
    name: model.note ?? model.categoryName,
    category: Category(
      id: model.categoryId,
      name: model.categoryName,
      icon: model.categoryIcon ?? 'pie_chart',
      colorHex: model.categoryColorHex ?? '#3498DB',
      type: model.type,
      isDefault: false,
    ),
    account: 'Bank',
    // TransactionUi uses signed amounts: negative = expense, positive = income.
    // TransactionModel stores amounts as positive — type is the signal.
    amount: model.type == 'expense' ? -model.amount : model.amount,
    dateTime: model.transactionDate,
    note: model.note,
  );
}
