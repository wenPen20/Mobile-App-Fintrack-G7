import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fintrack_mobile/core/constants/app_colors.dart';
import 'package:fintrack_mobile/core/constants/app_text_styles.dart';
import '../providers/onboarding_provider.dart';

class OnboardingStepBudgets extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const OnboardingStepBudgets({
    super.key,
    required this.onNext,
    required this.onBack,
  });

  @override
  ConsumerState<OnboardingStepBudgets> createState() =>
      _OnboardingStepBudgetsState();
}

class _OnboardingStepBudgetsState extends ConsumerState<OnboardingStepBudgets> {
  final Map<String, double> _categoryLimits = {
    'Food & Drinks': 600.0,
    'Transport': 300.0,
    'Shopping': 250.0,
    'Bills': 600.0,
    'Entertainment': 200.0,
    'Health': 100.0,
    'Education': 100.0,
    'Travel': 100.0,
  };

  @override
  Widget build(BuildContext context) {
    final onboarding = ref.watch(onboardingProvider);
    final incomeTarget = onboarding.monthlyIncomeTarget > 0
        ? onboarding.monthlyIncomeTarget
        : 3000.0;
    final totalAllocated = _categoryLimits.values.fold(
      0.0,
      (sum, val) => sum + val,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Set Category Budgets', style: AppTextStyles.headingLarge),
          const SizedBox(height: 8),
          Text(
            'Allocate your target monthly income across your core spending categories.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // Total Allocation Summary Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Budgeted',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'RM ${totalAllocated.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Income Target',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'RM ${incomeTarget.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Sliders for each category
          Column(
            children: _categoryLimits.entries.map((entry) {
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.key,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          'RM ${entry.value.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: entry.value,
                      min: 0,
                      max: 2000,
                      divisions: 40,
                      activeColor: AppColors.primary,
                      inactiveColor: AppColors.primary.withValues(alpha: 0.15),
                      onChanged: (val) {
                        setState(() => _categoryLimits[entry.key] = val);
                      },
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Navigation buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onBack,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Back',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // Save limits to provider
                    _categoryLimits.forEach((cat, limit) {
                      ref
                          .read(onboardingProvider.notifier)
                          .updateCategoryBudget(cat, limit);
                    });
                    widget.onNext();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Review Setup',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
