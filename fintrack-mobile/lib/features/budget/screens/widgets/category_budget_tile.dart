// lib/features/budget/screens/widgets/category_budget_tile.dart
//
// One row in the budget list: category icon + name, spent vs. limit, and a
// linear progress bar (turns red and shows an "over budget" line if exceeded).

import 'package:flutter/material.dart';
import 'package:fintrack_mobile/core/constants/app_colors.dart';
import 'package:fintrack_mobile/core/constants/app_text_styles.dart';
import 'package:fintrack_mobile/core/constants/category_visuals.dart';
import '../../utils/budget_helpers.dart';

class CategoryBudgetTile extends StatelessWidget {
  final CategoryBudgetProgress progress;

  const CategoryBudgetTile({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    final category = progress.budget.category;
    final categoryColor = colorFromHex(category.colorHex);

    // Calculate remaining health progress
    final double remaining = (progress.budget.limit - progress.spent).clamp(0.0, double.infinity);
    final double healthPercent;
    if (progress.budget.limit <= 0) {
      healthPercent = progress.spent > 0 ? 0.0 : 1.0;
    } else {
      healthPercent = (remaining / progress.budget.limit).clamp(0.0, 1.0);
    }

    final barColor = progress.isOverBudget ? AppColors.error : categoryColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: categoryColor.withValues(alpha: 0.15),
                child: Icon(
                  iconForName(category.icon),
                  color: categoryColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  category.name,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    progress.isOverBudget
                        ? '${formatCurrency(progress.overAmount)} over'
                        : '${formatCurrency(remaining)} left',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: progress.isOverBudget
                          ? AppColors.error
                          : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Limit: ${formatCurrency(progress.budget.limit)}',
                    style: AppTextStyles.labelSmall,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: healthPercent,
              minHeight: 6,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ],
      ),
    );
  }
}
