import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fintrack_mobile/core/constants/app_colors.dart';
import 'package:fintrack_mobile/core/constants/app_text_styles.dart';
import 'package:fintrack_mobile/features/dashboard/providers/dashboard_provider.dart';

class NetBalanceCard extends ConsumerWidget {
  const NetBalanceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final monthDate = DateTime(now.year, now.month);
    final summaryAsync = ref.watch(budgetSummaryProvider(monthDate));

    return summaryAsync.when(
      data: (summary) {
        final double income = (summary['total_income'] as num).toDouble();
        final double expenses = (summary['total_expenses'] as num).toDouble();
        final double net = (summary['net'] as num).toDouble();

        return _buildCard(income, expenses, net);
      },
      loading: () => Container(
        height: 172,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(child: CircularProgressIndicator(color: Colors.white)),
      ),
      error: (err, stack) => _buildCard(0.00, 0.00, 0.00),
    );
  }

  Widget _buildCard(double income, double expenses, double net) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Net Balance', style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70)),
          const SizedBox(height: 8),
          Text(
            'RM ${net.toStringAsFixed(2)}',
            style: AppTextStyles.headingLarge.copyWith(color: Colors.white, fontSize: 36),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _balanceItem(Icons.arrow_downward_rounded, 'Income', income, Colors.greenAccent),
              _balanceItem(Icons.arrow_upward_rounded, 'Expenses', expenses, Colors.redAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _balanceItem(IconData icon, String label, double amount, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            Text(
              'RM ${amount.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }
}
