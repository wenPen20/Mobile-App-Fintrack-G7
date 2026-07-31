import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../budget/providers/budget_provider.dart' as budget;
import 'package:flutter/foundation.dart';

class OnboardingTransactionItem {
  final String title;
  final String categoryId;
  final String categoryName;
  final double amount;
  final String type; // 'expense' or 'income'
  final DateTime date;

  OnboardingTransactionItem({
    required this.title,
    required this.categoryId,
    required this.categoryName,
    required this.amount,
    required this.type,
    required this.date,
  });
}

class OnboardingState {
  final int currentStep;
  final String name;
  final String financialGoal;
  final double monthlyIncomeTarget;
  final String riskAppetite;
  final Map<String, double> categoryBudgets; // categoryId -> limit amount
  final List<OnboardingTransactionItem> initialTransactions;
  final bool isSubmitting;
  final String? error;

  OnboardingState({
    this.currentStep = 0,
    this.name = '',
    this.financialGoal = 'Track Expenses & Save',
    this.monthlyIncomeTarget = 3000.0,
    this.riskAppetite = 'moderate',
    this.categoryBudgets = const {},
    this.initialTransactions = const [],
    this.isSubmitting = false,
    this.error,
  });

  OnboardingState copyWith({
    int? currentStep,
    String? name,
    String? financialGoal,
    double? monthlyIncomeTarget,
    String? riskAppetite,
    Map<String, double>? categoryBudgets,
    List<OnboardingTransactionItem>? initialTransactions,
    bool? isSubmitting,
    String? error,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      name: name ?? this.name,
      financialGoal: financialGoal ?? this.financialGoal,
      monthlyIncomeTarget: monthlyIncomeTarget ?? this.monthlyIncomeTarget,
      riskAppetite: riskAppetite ?? this.riskAppetite,
      categoryBudgets: categoryBudgets ?? this.categoryBudgets,
      initialTransactions: initialTransactions ?? this.initialTransactions,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
    );
  }
}

class OnboardingNotifier extends Notifier<OnboardingState> {
  @override
  OnboardingState build() {
    return OnboardingState();
  }

  void resetStep() {
    state = state.copyWith(currentStep: 0);
  }

  void setStep(int step) {
    state = state.copyWith(currentStep: step);
  }

  void nextStep() {
    if (state.currentStep < 2) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  void updateProfileInfo({
    String? name,
    String? financialGoal,
    double? monthlyIncomeTarget,
    String? riskAppetite,
  }) {
    state = state.copyWith(
      name: name ?? state.name,
      financialGoal: financialGoal ?? state.financialGoal,
      monthlyIncomeTarget: monthlyIncomeTarget ?? state.monthlyIncomeTarget,
      riskAppetite: riskAppetite ?? state.riskAppetite,
    );
  }

  void updateCategoryBudget(String categoryId, double limit) {
    final updated = Map<String, double>.from(state.categoryBudgets);
    if (limit > 0) {
      updated[categoryId] = limit;
    } else {
      updated.remove(categoryId);
    }
    state = state.copyWith(categoryBudgets: updated);
  }

  void addInitialTransaction(OnboardingTransactionItem item) {
    final updated = List<OnboardingTransactionItem>.from(
      state.initialTransactions,
    )..add(item);
    state = state.copyWith(initialTransactions: updated);
  }

  void removeInitialTransaction(int index) {
    if (index >= 0 && index < state.initialTransactions.length) {
      final updated = List<OnboardingTransactionItem>.from(
        state.initialTransactions,
      )..removeAt(index);
      state = state.copyWith(initialTransactions: updated);
    }
  }

  Future<bool> completeOnboarding() async {
    state = state.copyWith(isSubmitting: true, error: null);

    try {
      final api = ref.read(apiServiceProvider);
      final now = DateTime.now();

      // Get or seed the user's categories.
      final rawCategories = await api.getCategories();

      final expenseCategories = <String, String>{};

      for (final item in rawCategories) {
        final category = Map<String, dynamic>.from(item as Map);

        final id = category['id']?.toString();
        final name = category['name']?.toString().trim();
        final type = category['type']?.toString().toLowerCase().trim();

        if (id != null && name != null && type == 'expense') {
          expenseCategories[name.toLowerCase()] = id;
        }
      }

      // Create each onboarding budget.
      for (final entry in state.categoryBudgets.entries) {
        final categoryName = entry.key.trim();
        final amount = entry.value;

        final categoryId = expenseCategories[categoryName.toLowerCase()];

        if (categoryId == null) {
          throw Exception(
            'The category "$categoryName" was not found in your expense categories.',
          );
        }

        await api.createBudget({
          'category_id': categoryId,
          'amount_limit': amount,
          'month': now.month,
          'year': now.year,
        });
      }

      // Complete onboarding only after budgets are saved.
      await api.updateOnboarding({
        if (state.name.trim().isNotEmpty) 'name': state.name.trim(),
        'onboarding_completed': true,
        'financial_goal': state.financialGoal,
        'monthly_income_target': state.monthlyIncomeTarget,
        'income_frequency': 'monthly',
        'risk_appetite': state.riskAppetite,
      });

      ref.read(authProvider.notifier).setOnboardingCompleted(true);

      ref.invalidate(profileProvider);
      ref.invalidate(budgetSummaryProvider(now));

      state = state.copyWith(isSubmitting: false, error: null);

      return true;
    } catch (e, stackTrace) {
      debugPrint('Complete onboarding error: $e');
      debugPrintStack(stackTrace: stackTrace);

      state = state.copyWith(
        isSubmitting: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );

      return false;
    }
  }
}

final onboardingProvider =
    NotifierProvider<OnboardingNotifier, OnboardingState>(
      OnboardingNotifier.new,
    );
