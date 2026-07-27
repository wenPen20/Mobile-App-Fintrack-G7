import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fintrack_mobile/core/constants/app_colors.dart';
import 'package:fintrack_mobile/core/constants/app_text_styles.dart';
import '../providers/dashboard_provider.dart';
import 'widgets/net_balance.dart';
import 'widgets/income_expense.dart';
import 'widgets/spending_donut.dart';
import 'widgets/budget_health.dart';
import 'widgets/recent_transactions.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final String displayName = profileAsync.maybeWhen(
      data: (profile) => profile['name'] ?? 'User',
      orElse: () => 'User',
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting header
              Text('Good morning, $displayName 👋', style: AppTextStyles.headingLarge),
              const SizedBox(height: 4),
              Text("Here's your financial summary", style: AppTextStyles.bodyMedium),
              const SizedBox(height: 24),

              const NetBalanceCard(),
              const SizedBox(height: 16),
              const IncomeExpenseCard(),
              const SizedBox(height: 16),
              const SpendingDonutCard(),
              const SizedBox(height: 16),
              const BudgetHealthCard(),
              const SizedBox(height: 16),
              const RecentTransactionsCard(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
