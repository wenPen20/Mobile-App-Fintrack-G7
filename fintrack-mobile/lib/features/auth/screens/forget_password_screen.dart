import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/auth_error_banner.dart';
import 'reset_password_screen.dart';

class ForgetPasswordScreen extends ConsumerStatefulWidget {
  const ForgetPasswordScreen({super.key});

  @override
  ConsumerState<ForgetPasswordScreen> createState() => _ForgetPasswordScreenState();
}

class _ForgetPasswordScreenState extends ConsumerState<ForgetPasswordScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();

  bool _isCodeSent = false;
  String? _emailError;
  String? _codeError;
  String? _formError;

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _handleRequestCode() async {
    setState(() {
      _emailError = null;
      _formError = null;
    });
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() => _emailError = 'Email cannot be empty');
      return;
    }
    if (!_isValidEmail(email)) {
      setState(() => _emailError = 'Please enter a valid email address');
      return;
    }

    final success = await ref.read(authProvider.notifier).requestPasswordReset(email);
    
    if (mounted) {
      if (success) {
        setState(() {
          _isCodeSent = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification code sent to your email.'),
            backgroundColor: Colors.blue,
          ),
        );
      } else {
        final authState = ref.read(authProvider);
        setState(() {
          _formError = authState.error ?? 'Failed to send reset code';
        });
      }
    }
  }

  void _handleSubmitCode() {
    setState(() => _codeError = null);
    final code = _codeController.text.trim();

    if (code.isEmpty) {
      setState(() => _codeError = 'Verification code cannot be empty');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResetPasswordScreen(
          email: _emailController.text.trim(),
          code: code,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password'),
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
                      color: Colors.orange.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.mark_email_unread_outlined,
                      size: 48,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Center(
                  child: Text(
                    'Reset Your Password',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                const Center(
                  child: Text(
                    'Enter your registered email to receive a password reset code',
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

                // Step 1: Email Input
                AppTextField(
                  controller: _emailController,
                  label: 'Email Address',
                  hintText: 'Enter your email',
                  keyboardType: TextInputType.emailAddress,
                  errorText: _emailError,
                ),
                const SizedBox(height: 16),

                if (!_isCodeSent) ...[
                  AppButton(
                    label: 'Send Verification Code',
                    isLoading: authState.isLoading,
                    onPressed: _handleRequestCode,
                  ),
                ] else ...[
                  // Step 2: Verification Code Input
                  AppTextField(
                    controller: _codeController,
                    label: 'Verification Code',
                    hintText: 'Enter code',
                    keyboardType: TextInputType.number,
                    errorText: _codeError,
                  ),
                  const SizedBox(height: 20),

                  AppButton(
                    label: 'Verify Code',
                    onPressed: _handleSubmitCode,
                  ),
                  const SizedBox(height: 12),

                  Center(
                    child: TextButton(
                      onPressed: _handleRequestCode,
                      child: const Text('Resend Code'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
