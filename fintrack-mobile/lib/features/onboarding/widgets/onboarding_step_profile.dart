import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fintrack_mobile/core/constants/app_colors.dart';
import 'package:fintrack_mobile/core/constants/app_text_styles.dart';
import '../providers/onboarding_provider.dart';

class OnboardingStepProfile extends ConsumerStatefulWidget {
  final VoidCallback onNext;

  const OnboardingStepProfile({super.key, required this.onNext});

  @override
  ConsumerState<OnboardingStepProfile> createState() => _OnboardingStepProfileState();
}

class _OnboardingStepProfileState extends ConsumerState<OnboardingStepProfile> {
  final _nameController = TextEditingController();
  final _incomeController = TextEditingController(text: '3000');
  String _selectedGoal = 'Track Expenses & Save';
  String _selectedRisk = 'moderate';

  final List<String> _goals = [
    'Track Expenses & Save',
    'Pay Off Debt',
    'Build Emergency Fund',
    'Invest & Grow Wealth',
  ];

  final List<Map<String, String>> _riskLevels = [
    {'value': 'conservative', 'label': 'Conservative', 'desc': 'Low risk, stable returns'},
    {'value': 'moderate', 'label': 'Moderate', 'desc': 'Balanced growth & risk'},
    {'value': 'aggressive', 'label': 'Aggressive', 'desc': 'Higher risk for maximum returns'},
  ];

  @override
  void initState() {
    super.initState();
    final onboarding = ref.read(onboardingProvider);
    _nameController.text = onboarding.name;
    if (onboarding.monthlyIncomeTarget > 0) {
      _incomeController.text = onboarding.monthlyIncomeTarget.toStringAsFixed(0);
    }
    _selectedGoal = onboarding.financialGoal;
    _selectedRisk = onboarding.riskAppetite;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _incomeController.dispose();
    super.dispose();
  }

  void _saveAndNext() {
    final name = _nameController.text.trim();
    final income = double.tryParse(_incomeController.text.trim()) ?? 3000.0;

    ref.read(onboardingProvider.notifier).updateProfileInfo(
          name: name,
          financialGoal: _selectedGoal,
          monthlyIncomeTarget: income,
          riskAppetite: _selectedRisk,
        );

    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Personalize Your Experience', style: AppTextStyles.headingLarge),
          const SizedBox(height: 8),
          Text(
            'Tell us a little about your financial preferences to tailor your experience.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),

          // Display Name
          const Text('Display Name', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'Enter your name',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 24),

          // Monthly Income Target
          const Text('Target Monthly Income (RM)', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _incomeController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'e.g. 3000',
              prefixText: 'RM ',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 24),

          // Financial Goal Dropdown
          const Text('Primary Financial Goal', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedGoal,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            items: _goals.map((g) {
              return DropdownMenuItem(value: g, child: Text(g));
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedGoal = val);
            },
          ),
          const SizedBox(height: 24),

          // Risk Appetite Selection
          const Text('Risk Appetite', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Column(
            children: _riskLevels.map((r) {
              final isSelected = _selectedRisk == r['value'];
              return GestureDetector(
                onTap: () => setState(() => _selectedRisk = r['value']!),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                        color: isSelected ? AppColors.primary : Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r['label']!, style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text(r['desc']!, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),

          // Next Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _saveAndNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Continue to Budgeting', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
