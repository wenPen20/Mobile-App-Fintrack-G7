import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fintrack_mobile/core/constants/app_colors.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_step_profile.dart';
import '../widgets/onboarding_step_budgets.dart';
import '../widgets/onboarding_step_summary.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboarding = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Account Setup', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Step Progress Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: List.generate(3, (index) {
                final isActive = index <= onboarding.currentStep;
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.primary : AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),

          Expanded(
            child: IndexedStack(
              index: onboarding.currentStep,
              children: [
                OnboardingStepProfile(
                  onNext: () => notifier.nextStep(),
                ),
                OnboardingStepBudgets(
                  onNext: () => notifier.nextStep(),
                  onBack: () => notifier.previousStep(),
                ),
                OnboardingStepSummary(
                  onBack: () => notifier.previousStep(),
                  onComplete: () {
                    context.go('/home');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
