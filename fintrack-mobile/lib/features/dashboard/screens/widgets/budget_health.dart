import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fintrack_mobile/core/constants/app_colors.dart';
import 'package:fintrack_mobile/core/constants/app_text_styles.dart';
import 'package:fintrack_mobile/features/dashboard/providers/dashboard_provider.dart';

class BudgetHealthCard extends ConsumerWidget {
  const BudgetHealthCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final monthDate = DateTime(now.year, now.month);
    final budgetsAsync = ref.watch(budgetsProvider(monthDate));
    final summaryAsync = ref.watch(budgetSummaryProvider(monthDate));

    return budgetsAsync.when(
      data: (budgets) {
        return summaryAsync.when(
          data: (summary) {
            final double totalExpenses = (summary['total_expenses'] as num).toDouble();
            final double totalLimit = budgets.fold(0.0, (sum, b) => sum + b.limit);
            
            double budgetRemainingPercent;
            double remaining = 0.0;

            if (totalLimit <= 0) {
              budgetRemainingPercent = totalExpenses > 0 ? 0.0 : 1.0;
              remaining = 0.0;
            } else {
              remaining = (totalLimit - totalExpenses).clamp(0.0, totalLimit);
              budgetRemainingPercent = remaining / totalLimit;
            }

            return _buildContent(context, budgetRemainingPercent, totalLimit, remaining, totalExpenses);
          },
          loading: () => _buildLoadingState(),
          error: (err, stack) => _buildContent(context, 1.0, 0.0, 0.0, 0.0),
        );
      },
      loading: () => _buildLoadingState(),
      error: (err, stack) => _buildContent(context, 1.0, 0.0, 0.0, 0.0),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 180,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildContent(
    BuildContext context,
    double budgetRemainingPercent,
    double limit,
    double remaining,
    double spent,
  ) {
    final bool isLow = budgetRemainingPercent < 0.15;
    final alertColor = isLow ? Colors.redAccent : AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Budget Health', style: AppTextStyles.headingSmall),
              GestureDetector(
                onTap: () => context.go('/budget'),
                child: const Text('See all', style: TextStyle(color: AppColors.primary, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('This month', style: AppTextStyles.bodyMedium),
          const SizedBox(height: 20),
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${(budgetRemainingPercent * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: alertColor,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'budget left',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: budgetRemainingPercent,
              minHeight: 10,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(alertColor),
            ),
          ),
          const SizedBox(height: 10),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'RM ${remaining.toStringAsFixed(2)} left',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: alertColor,
                      ),
                    ),
                    const TextSpan(
                      text: '  |  ',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    TextSpan(
                      text: 'RM ${spent.toStringAsFixed(2)} spent',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Limit: RM ${limit.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
