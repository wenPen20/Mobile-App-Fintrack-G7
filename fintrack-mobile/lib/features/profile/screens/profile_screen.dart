// lib/features/profile/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fintrack_mobile/core/constants/app_colors.dart';
import 'package:fintrack_mobile/core/services/api_service.dart';

import 'package:fintrack_mobile/features/auth/providers/auth_provider.dart';
import 'package:fintrack_mobile/features/profile/providers/profile_provider.dart';
import 'package:fintrack_mobile/features/profile/screens/widgets/profile_header.dart';
import 'package:fintrack_mobile/features/profile/screens/widgets/settings_tile.dart';
import 'package:fintrack_mobile/features/profile/screens/widgets/settings_section.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _showEditNameDialog(
    BuildContext context,
    WidgetRef ref,
    String currentName,
  ) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Name'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Enter your full name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = controller.text.trim();
                if (newName.isNotEmpty) {
                  try {
                    await ref.read(updateProfileNameProvider)(currentName);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Name updated successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to update name: $e'),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showSecurityDialog(BuildContext context, WidgetRef ref) {
    final currentPasswordController = TextEditingController();

    // Step 1 Dialog: Confirm Current Password
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        bool isLoading = false;
        String? errorMessage;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Confirm Password'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Please re-enter your current password to continue.',
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: currentPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'Current Password',
                      errorText: errorMessage,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          final pass = currentPasswordController.text;
                          if (pass.isEmpty) {
                            setDialogState(
                              () => errorMessage = 'Password cannot be empty',
                            );
                            return;
                          }

                          setDialogState(() {
                            isLoading = true;
                            errorMessage = null;
                          });

                          try {
                            await ref.read(confirmPasswordProvider)(pass);

                            if (context.mounted) {
                              Navigator.pop(context); // Close Step 1
                              _showNewPasswordDialog(
                                context,
                                ref,
                              ); // Open Step 2
                            }
                          } catch (e) {
                            setDialogState(() {
                              isLoading = false;
                              errorMessage = e.toString().replaceAll(
                                'Exception: ',
                                '',
                              );
                            });
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Text('Confirm'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showNewPasswordDialog(BuildContext context, WidgetRef ref) {
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    // Step 2 Dialog: Enter New Password
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        bool isLoading = false;
        String? newPasswordError;
        String? confirmPasswordError;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Set New Password'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: newPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'New Password',
                      errorText: newPasswordError,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'Confirm New Password',
                      errorText: confirmPasswordError,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          final pass = newPasswordController.text;
                          final confirm = confirmPasswordController.text;

                          setDialogState(() {
                            newPasswordError = null;
                            confirmPasswordError = null;
                          });

                          if (pass.isEmpty) {
                            setDialogState(
                              () =>
                                  newPasswordError = 'Password cannot be empty',
                            );
                            return;
                          }
                          if (pass.length < 6) {
                            setDialogState(
                              () => newPasswordError =
                                  'Must be at least 6 characters',
                            );
                            return;
                          }
                          if (confirm != pass) {
                            setDialogState(
                              () => confirmPasswordError =
                                  'Passwords do not match',
                            );
                            return;
                          }

                          setDialogState(() => isLoading = true);

                          try {
                            await ref.read(updatePasswordProvider)(pass);

                            if (context.mounted) {
                              Navigator.pop(context); // Close Step 2
                              _showPasswordSuccessNotification(
                                context,
                              ); // Step 3
                            }
                          } catch (e) {
                            setDialogState(() {
                              isLoading = false;
                              newPasswordError = e.toString().replaceAll(
                                'Exception: ',
                                '',
                              );
                            });
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showPasswordSuccessNotification(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Success'),
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.green, size: 24),
              SizedBox(width: 10),
              Expanded(
                child: Text('Your password has been successfully updated!'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showPersonalDetailsDialog(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Personal Details'),
          content: profileAsync.when(
            data: (profile) {
              final name = profile['name'] ?? 'User';
              final email = profile['email'] ?? 'Not set';
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detailField('Full Name', name),
                  const SizedBox(height: 12),
                  _detailField('Email Address', email),
                  const SizedBox(height: 12),
                  _detailField('Account Status', 'Active'),
                ],
              );
            },
            loading: () => const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, stack) => const Text('Failed to load profile details'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showFinancialProfileDialog(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.read(profileProvider);
    final profile = profileAsync.value ?? {};

    final currentIncome =
        (profile['monthly_income'] ??
                profile['monthly_income_target'] ??
                3000.0)
            .toString();
    final incomeController = TextEditingController(text: currentIncome);
    final currentFixed = (profile['fixed_expenses'] ?? 0.0).toString();
    final fixedExpensesController = TextEditingController(text: currentFixed);
    String selectedFrequency =
        (profile['income_frequency']?.toString().toLowerCase() ?? 'monthly')
            .replaceAll('-', '')
            .replaceAll(' ', '');
    String selectedRisk =
        profile['risk_appetite']?.toString().toLowerCase() ?? 'moderate';
    final currentGoal = profile['financial_goal'] ?? 'Track Expenses & Save';
    final goalController = TextEditingController(text: currentGoal);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        bool isSaving = false;
        String? errorMsg;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Financial Profile & Target'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (errorMsg != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          errorMsg!,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 13,
                          ),
                        ),
                      ),

                    // 1. Monthly Income
                    const Text(
                      'Estimated Monthly Income (RM)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: incomeController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        prefixText: 'RM ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 2. Fixed Expenses
                    const Text(
                      'Estimated Fixed Expenses (RM)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: fixedExpensesController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        prefixText: 'RM ',
                        hintText: 'e.g. rent, bills, subscriptions',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 3. Income Frequency (Dropdown)
                    const Text(
                      'Income Frequency',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue:
                          [
                            'monthly',
                            'biweekly',
                            'weekly',
                          ].contains(selectedFrequency)
                          ? selectedFrequency
                          : 'monthly',
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'monthly',
                          child: Text('Monthly'),
                        ),
                        DropdownMenuItem(
                          value: 'biweekly',
                          child: Text('Bi-weekly'),
                        ),
                        DropdownMenuItem(
                          value: 'weekly',
                          child: Text('Weekly'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null)
                          setDialogState(() => selectedFrequency = val);
                      },
                    ),

                    const SizedBox(height: 16),

                    // 4. Risk Appetite (Dropdown)
                    const Text(
                      'Risk Appetite',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue:
                          [
                            'conservative',
                            'moderate',
                            'aggressive',
                          ].contains(selectedRisk)
                          ? selectedRisk
                          : 'moderate',
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'conservative',
                          child: Text('Conservative'),
                        ),
                        DropdownMenuItem(
                          value: 'moderate',
                          child: Text('Moderate'),
                        ),
                        DropdownMenuItem(
                          value: 'aggressive',
                          child: Text('Aggressive'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null)
                          setDialogState(() => selectedRisk = val);
                      },
                    ),

                    const SizedBox(height: 16),

                    // 5. Financial Goal
                    const Text(
                      'Primary Financial Goal',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: goalController,
                      decoration: InputDecoration(
                        hintText: 'e.g. Save for emergency fund',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          setDialogState(() {
                            isSaving = true;
                            errorMsg = null;
                          });

                          try {
                            final parsedIncome =
                                double.tryParse(incomeController.text.trim()) ??
                                0.0;
                            final parsedFixed =
                                double.tryParse(
                                  fixedExpensesController.text.trim(),
                                ) ??
                                0.0;
                            final api = ref.read(apiServiceProvider);
                            await api.updateOnboarding({
                              'monthly_income_target': parsedIncome,
                              'fixed_expenses': parsedFixed,
                              'income_frequency': selectedFrequency,
                              'risk_appetite': selectedRisk,
                              'financial_goal': goalController.text.trim(),
                              'onboarding_completed': true,
                            });

                            ref.invalidate(profileProvider);
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Financial profile updated successfully!',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() {
                              isSaving = false;
                              errorMsg = e.toString().replaceAll(
                                'Exception: ',
                                '',
                              );
                            });
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Text('Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _detailField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            children: [
              // 1. Profile Header Section (loads dynamically)
              profileAsync.when(
                data: (profile) => ProfileHeader(
                  name: profile['name'] ?? 'User',
                  email: profile['email'] ?? '',
                  onEditPressed: () => _showEditNameDialog(
                    context,
                    ref,
                    profile['name'] ?? 'User',
                  ),
                ),
                loading: () => Container(
                  height: 120,
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator(),
                ),
                error: (err, stack) => ProfileHeader(
                  name: 'User',
                  email: '',
                  onEditPressed: () =>
                      _showEditNameDialog(context, ref, 'User'),
                ),
              ),
              const SizedBox(height: 32),

              // 2. Account Settings Section
              SettingsSection(
                title: 'Account Settings',
                children: [
                  SettingsTile(
                    icon: Icons.person_outline_rounded,
                    title: 'Personal Details',
                    onTap: () => _showPersonalDetailsDialog(context, ref),
                  ),
                  SettingsTile(
                    icon: Icons.lock_outline_rounded,
                    title: 'Security & PIN',
                    onTap: () => _showSecurityDialog(context, ref),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // 3. App Preferences Section
              SettingsSection(
                title: 'Preferences',
                children: [
                  SettingsTile(
                    icon: Icons.category_outlined,
                    title: 'Manage Categories',
                    onTap: () => context.push('/categories'),
                  ),
                  SettingsTile(
                    icon: Icons.rocket_launch_outlined,
                    title: 'Onboarding & Quick Setup',
                    onTap: () => context.push('/onboarding'),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 4. Additional Settings Section
              SettingsSection(
                title: 'Additional Settings',
                children: [
                  SettingsTile(
                    icon: Icons.tune_rounded,
                    title: 'Financial Profile & Target',
                    onTap: () => _showFinancialProfileDialog(context, ref),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 5. Session Actions Section
              SettingsSection(
                title: 'Session',
                children: [
                  SettingsTile(
                    icon: Icons.logout_rounded,
                    iconColor: Colors.redAccent,
                    title: 'Log Out',
                    onTap: () {
                      ref.read(authProvider.notifier).logout();
                      context.go('/login');
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
