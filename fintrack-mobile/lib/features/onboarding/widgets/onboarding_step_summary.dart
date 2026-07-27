import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fintrack_mobile/core/constants/app_colors.dart';
import 'package:fintrack_mobile/core/constants/app_text_styles.dart';
import '../providers/onboarding_provider.dart';

class OnboardingStepSummary extends ConsumerWidget {
  final VoidCallback onComplete;
  final VoidCallback onBack;

  const OnboardingStepSummary({
    super.key,
    required this.onComplete,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboarding = ref.watch(onboardingProvider);
    final totalBudgeted = onboarding.categoryBudgets.values.fold(0.0, (sum, val) => sum + val);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Review & Complete', style: AppTextStyles.headingLarge),
          const SizedBox(height: 8),
          Text(
            'Confirm your initial setup. You can adjust these anytime in your Profile & Settings.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),

          // Overview Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _summaryRow('Display Name', onboarding.name.isNotEmpty ? onboarding.name : 'User'),
                const Divider(height: 24),
                _summaryRow('Monthly Income Target', 'RM ${onboarding.monthlyIncomeTarget.toStringAsFixed(2)}'),
                const Divider(height: 24),
                _summaryRow('Total Budget Allocated', 'RM ${totalBudgeted.toStringAsFixed(2)}'),
                const Divider(height: 24),
                _summaryRow('Primary Goal', onboarding.financialGoal),
                const Divider(height: 24),
                _summaryRow('Risk Appetite', onboarding.riskAppetite.toUpperCase()),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onBack,
                  style: OutlinedButton.styleFrom(
                    height: 50,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Back', style: TextStyle(color: AppColors.textPrimary)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: onboarding.isSubmitting
                      ? null
                      : () async {
                          final success = await ref.read(onboardingProvider.notifier).completeOnboarding();
                          if (success && context.mounted) {
                            onComplete();
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    height: 50,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: onboarding.isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Get Started!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }
}
