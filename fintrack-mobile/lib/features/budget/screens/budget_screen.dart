// lib/features/budget/screens/budget_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fintrack_mobile/core/constants/app_colors.dart';
import 'package:fintrack_mobile/core/constants/app_text_styles.dart';
import '../models/category.dart';
import '../models/category_budget.dart';
import 'package:fintrack_mobile/features/transactions/providers/transaction_provider.dart';
import '../providers/budget_provider.dart';
import '../utils/budget_helpers.dart';
import 'package:fintrack_mobile/core/widgets/month_selector.dart';
import 'widgets/category_budget_tile.dart';
import 'widgets/monthly_budget_card.dart';
import '../../profile/providers/category_provider.dart';

class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    // Default to the current month.
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
  }

  /// Returns 12 calendar months starting from the current month going forward in time.
  List<DateTime> _last12Months() {
    final now = DateTime.now();
    return List.generate(12, (i) => DateTime(now.year, now.month + i));
  }

  Widget _buildHeader() {
    return Row(children: [Text('Budget', style: AppTextStyles.headingLarge)]);
  }

  Widget _buildLoadingState() {
    return const Expanded(child: Center(child: CircularProgressIndicator()));
  }

  Widget _buildErrorState(Object error) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 40),
            const SizedBox(height: 12),
            Text(
              'Failed to load budget data',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              error.toString().replaceAll('Exception: ', ''),
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showSetBudgetDialog(Category category, double currentLimit) {
    final controller = TextEditingController(
      text: currentLimit > 0 ? currentLimit.toStringAsFixed(2) : '',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Set Budget for ${category.name}'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Budget Limit (RM)',
            prefixText: 'RM ',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final val = double.tryParse(controller.text) ?? 0.0;
              Navigator.pop(ctx);
              try {
                await ref.read(setBudgetProvider)(
                  categoryId: category.id,
                  limit: val.toInt().toDouble(),
                  monthDate: _selectedMonth,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Budget limit updated for ${category.name}',
                      ),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to update budget: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final months = _last12Months();

    // Watch all three providers.
    final budgetsAsync = ref.watch(budgetsProvider(_selectedMonth));
    final transactionsAsync = ref.watch(transactionsProvider(_selectedMonth));
    final categoriesAsync = ref.watch(sortedCategoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              _buildHeader(),
              const SizedBox(height: 8),
              MonthSelector(
                months: months,
                selectedMonth: _selectedMonth,
                onSelected: (month) => setState(() => _selectedMonth = month),
              ),
              const SizedBox(height: 16),

              // Render the main content based on async states.
              budgetsAsync.when(
                loading: _buildLoadingState,
                error: (e, _) => _buildErrorState(e),
                data: (budgets) => transactionsAsync.when(
                  loading: _buildLoadingState,
                  error: (e, _) => _buildErrorState(e),
                  data: (transactions) => categoriesAsync.when(
                    loading: _buildLoadingState,
                    error: (e, _) => _buildErrorState(e),
                    data: (categories) {
                      // Filter for user's expense categories
                      final expenseCategories = categories
                          .where((c) => c.type == 'expense')
                          .toList();

                      // Merge expense categories with configured budgets.
                      // If no budget is configured, set limit to 0.0.
                      final mergedBudgets = expenseCategories.map((cat) {
                        final existingBudget = budgets.firstWhere(
                          (b) => b.category.id == cat.id,
                          orElse: () => CategoryBudget(category: cat, limit: 0),
                        );
                        return CategoryBudget(
                          category: cat,
                          limit: existingBudget.limit,
                        );
                      }).toList();

                      // Map real API transactions to the UI model the helpers expect.
                      final uiTransactions = transactions
                          .map(transactionModelToUi)
                          .toList();

                      // Reuse the unchanged pure helper functions.
                      final progressList = budgetProgressForMonth(
                        mergedBudgets,
                        uiTransactions,
                        _selectedMonth,
                      );
                      final summary = summarizeMonth(progressList);

                      if (expenseCategories.isEmpty) {
                        return Expanded(
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.pie_chart_outline,
                                  size: 56,
                                  color: AppColors.textSecondary.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No expense categories set. Create one under Profile.',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return Expanded(
                        child: ListView(
                          padding: EdgeInsets.zero,
                          children: [
                            MonthlyBudgetCard(summary: summary),
                            const SizedBox(height: 20),
                            Text(
                              'Categories',
                              style: AppTextStyles.headingSmall,
                            ),
                            const SizedBox(height: 12),
                            for (final progress in progressList)
                              GestureDetector(
                                onTap: () => _showSetBudgetDialog(
                                  progress.budget.category,
                                  progress.budget.limit,
                                ),
                                child: CategoryBudgetTile(progress: progress),
                              ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
