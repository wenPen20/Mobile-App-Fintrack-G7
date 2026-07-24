import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/auth_error_banner.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String? email;
  final String? code;

  const ResetPasswordScreen({
    super.key,
    this.email,
    this.code,
  });

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _formError;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    setState(() {
      _passwordError = null;
      _confirmPasswordError = null;
      _formError = null;
    });

    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (password.isEmpty) {
      setState(() => _passwordError = 'New password cannot be empty');
      return;
    }
    if (password.length < 8) {
      setState(() => _passwordError = 'Password must be at least 8 characters');
      return;
    }
    if (confirmPassword.isEmpty) {
      setState(() => _confirmPasswordError = 'Please confirm your new password');
      return;
    }
    
    // FIXED: validate that confirmPassword matches password before proceeding
    if (confirmPassword != password) {
      setState(() {
        _confirmPasswordError = 'Passwords do not match';
        _passwordError = 'Passwords do not match';
      });
      return;
    }

    final success = await ref.read(authProvider.notifier).confirmPasswordReset(
          widget.code ?? '',
          password,
        );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset successfully! Please sign in.'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back to Login
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      } else {
        final authState = ref.read(authProvider);
        setState(() {
          _formError = authState.error ?? 'Failed to reset password';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.key_outlined,
                      size: 48,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Center(
                  child: Text(
                    'Create New Password',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                const Center(
                  child: Text(
                    'Your new password must be different from previous passwords',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ),
                const SizedBox(height: 32),

                // Error Banner
                if (_formError != null) ...[
                  AuthErrorBanner(
                    message: _formError!,
                    onDismiss: () => setState(() => _formError = null),
                  ),
                  const SizedBox(height: 16),
                ],

                // New Password input
                AppTextField(
                  controller: _passwordController,
                  label: 'New Password',
                  hintText: 'Enter new password',
                  isPassword: true,
                  isObscure: _obscurePassword,
                  onToggleObscure: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                  errorText: _passwordError,
                ),
                const SizedBox(height: 16),

                // Confirm New Password input
                AppTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirm New Password',
                  hintText: 'Re-enter new password',
                  isPassword: true,
                  isObscure: _obscureConfirmPassword,
                  onToggleObscure: () {
                    setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                  },
                  errorText: _confirmPasswordError,
                ),
                const SizedBox(height: 28),

                // Submit Reset Button
                AppButton(
                  label: 'Reset Password',
                  isLoading: authState.isLoading,
                  onPressed: _handleResetPassword,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
