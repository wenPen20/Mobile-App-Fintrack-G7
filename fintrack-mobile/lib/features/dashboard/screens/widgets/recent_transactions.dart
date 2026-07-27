import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fintrack_mobile/core/constants/app_colors.dart';
import 'package:fintrack_mobile/core/constants/app_text_styles.dart';
import 'package:fintrack_mobile/features/dashboard/providers/dashboard_provider.dart';

class RecentTransactionsCard extends ConsumerWidget {
  const RecentTransactionsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentAsync = ref.watch(recentTransactionsProvider);

    return recentAsync.when(
      data: (transactions) {
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
                  Text('Recent Transactions', style: AppTextStyles.headingSmall),
                  GestureDetector(
                    onTap: () => context.go('/transactions'),
                    child: const Text('See all', style: TextStyle(color: AppColors.primary, fontSize: 13)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              transactions.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text('No transactions yet', style: AppTextStyles.bodyMedium),
                      ),
                    )
                  : Column(
                      children: [
                        for (final tx in transactions.take(5))
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                              child: Icon(
                                tx['type'] == 'income' ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                color: tx['type'] == 'income' ? Colors.green : Colors.red,
                              ),
                            ),
                            title: Text(tx['title'] ?? tx['category_name'] ?? 'Transaction'),
                            subtitle: Text(tx['transaction_date']?.toString().substring(0, 10) ?? ''),
                            trailing: Text(
                              '${tx['type'] == 'income' ? '+' : '-'}RM ${(tx['amount'] as num).toDouble().toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: tx['type'] == 'income' ? Colors.green : Colors.red,
                              ),
                            ),
                          ),
                      ],
                    ),
            ],
          ),
        );
      },
      loading: () => Container(
        height: 200,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Container(
        height: 200,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(child: Text('Error loading transactions', style: AppTextStyles.bodyMedium)),
      ),
    );
  }
}
