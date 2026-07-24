import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/auth_error_banner.dart';
import '../../../core/widgets/app_text_field.dart';
import 'register_screen.dart';
import 'forget_password_screen.dart';


class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  String? _emailError;
  String? _passwordError;
  String? _formError;

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    setState(() {
      _emailError = null;
      _passwordError = null;
      _formError = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty) {
      setState(() => _emailError = 'Email cannot be empty');
      return;
    }
    if (!_isValidEmail(email)) {
      setState(() => _emailError = 'Please enter a valid email address');
      return;
    }
    if (password.isEmpty) {
      setState(() => _passwordError = 'Password cannot be empty');
      return;
    }

    final success = await ref.read(authProvider.notifier).login(email, password);

    if (mounted) {
      if (success) {
        // Once GoRouter is configured, it will auto-redirect based on authState.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login successful!')),
        );
      } else {
        final authState = ref.read(authProvider);
        setState(() {
          _formError = authState.error ?? 'Invalid email or password';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header / Logo
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withAlpha((0.1 * 255).round()),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_outline_rounded,
                      size: 48,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Center(
                  child: Text(
                    'Welcome Back',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Center(
                  child: Text(
                    'Sign in to your account to continue',
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

                // Email field
                AppTextField(
                  controller: _emailController,
                  label: 'Email Address',
                  hintText: 'name@example.com',
                  keyboardType: TextInputType.emailAddress,
                  errorText: _emailError,
                ),
                const SizedBox(height: 16),

                // Password field header row
                Row(
                  children: [
                    const Text(
                      'Password',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ForgetPasswordScreen(),
                          ),
                        );
                      },
                      child: const Text('Forgot Password?'),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                AppTextField(
                  controller: _passwordController,
                  label: '',
                  hintText: 'Enter your password',
                  isPassword: true,
                  isObscure: _obscurePassword,
                  onToggleObscure: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                  errorText: _passwordError,
                ),
                const SizedBox(height: 24),

                // Sign In Button
                AppButton(
                  label: 'Sign In',
                  isLoading: authState.isLoading,
                  onPressed: _handleSignIn,
                ),
                const SizedBox(height: 20),

                // Sign Up link footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account?",
                      style: TextStyle(color: Colors.grey),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
