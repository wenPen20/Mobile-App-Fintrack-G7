// lib/features/budget/screens/widgets/monthly_budget_card.dart
//
// The top summary card on the budget screen: displays the monthly budget health,
// overall limit, spent amounts, and category alert status using a clean horizontal
// progress bar matching the category list and dashboard styles.

import 'package:flutter/material.dart';
import 'package:fintrack_mobile/core/constants/app_colors.dart';
import 'package:fintrack_mobile/core/constants/app_text_styles.dart';
import '../../utils/budget_helpers.dart';

class MonthlyBudgetCard extends StatelessWidget {
  final MonthlyBudgetSummary summary;

  const MonthlyBudgetCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final double healthProgress;
    if (summary.totalBudget <= 0) {
      healthProgress = summary.totalSpent > 0 ? 0.0 : 1.0;
    } else {
      final double remaining = (summary.totalBudget - summary.totalSpent).clamp(0.0, summary.totalBudget);
      healthProgress = remaining / summary.totalBudget;
    }
    final healthPercent = (healthProgress * 100).round();
    final isOverBudget = summary.categoriesOverBudget > 0;
    final ringColor = isOverBudget ? AppColors.error : AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Section label & health status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('MONTHLY BUDGET', style: AppTextStyles.labelSmall),
              Text(
                '$healthPercent% health',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: ringColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Horizontal progress bar (matching categories & dashboard budget health)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: healthProgress,
              minHeight: 10,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(ringColor),
            ),
          ),
          const SizedBox(height: 14),

          // Details Row: Spent vs Overall Limit
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${formatCurrency(summary.totalSpent)} spent',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isOverBudget) ...[
                      const TextSpan(
                        text: '  |  ',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      TextSpan(
                        text: '${summary.categoriesOverBudget} over limit',
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                'Limit: ${formatCurrency(summary.totalBudget)}',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
