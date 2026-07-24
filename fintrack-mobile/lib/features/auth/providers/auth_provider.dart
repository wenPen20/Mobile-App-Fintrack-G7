import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/auth_api_service.dart';

class AuthState {
  final String? token;
  final String? error;
  final bool isLoading;

  AuthState({
    this.token,
    this.error,
    this.isLoading = false,
  });

  bool get isAuthenticated => token != null;
}

class AuthNotifier extends Notifier<AuthState> {
  // Using localhost for emulator/testing
  final String baseUrl = 'http://localhost:8000';

  @override
  AuthState build() {
    return AuthState();
  }

  Future<bool> login(String email, String password) async {
    state = AuthState(isLoading: true);

    // Client-side validation checks
    if (email.trim().isEmpty) {
      state = AuthState(error: 'Email is required');
      return false;
    }
    if (!email.contains('@') || !email.contains('.')) {
      state = AuthState(error: 'Please enter a valid email address');
      return false;
    }
    if (password.isEmpty) {
      state = AuthState(error: 'Password is required');
      return false;
    }

    try {
      final api = AuthApiService(baseUrl: baseUrl);
      final res = await api.login(email, password);
      final token = res['access_token'] as String?;
      state = AuthState(token: token);
      return true;
    } catch (e) {
      state = AuthState(error: _formatError(e));
      return false;
    }
  }

  Future<bool> register(String email, String password, String confirmPassword) async {
    state = AuthState(isLoading: true);

    if (email.trim().isEmpty) {
      state = AuthState(error: 'Email is required');
      return false;
    }
    if (!email.contains('@') || !email.contains('.')) {
      state = AuthState(error: 'Please enter a valid email address');
      return false;
    }
    if (password.length < 8) {
      state = AuthState(error: 'Password must be at least 8 characters');
      return false;
    }
    if (password != confirmPassword) {
      state = AuthState(error: 'Passwords do not match');
      return false;
    }

    try {
      final api = AuthApiService(baseUrl: baseUrl);
      await api.register(email, password);
      state = AuthState();
      return true;
    } catch (e) {
      state = AuthState(error: _formatError(e));
      return false;
    }
  }

  Future<bool> requestPasswordReset(String email) async {
    state = AuthState(isLoading: true);

    if (email.trim().isEmpty || !email.contains('@')) {
      state = AuthState(error: 'Please enter a valid email address');
      return false;
    }

    try {
      final api = AuthApiService(baseUrl: baseUrl);
      await api.requestPasswordReset(email);
      state = AuthState();
      return true;
    } catch (e) {
      state = AuthState(error: _formatError(e));
      return false;
    }
  }

  Future<bool> confirmPasswordReset({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    state = AuthState(isLoading: true);

    if (code.trim().isEmpty) {
      state = AuthState(error: 'Reset code is required');
      return false;
    }
    if (newPassword.length < 8) {
      state = AuthState(error: 'Password must be at least 8 characters');
      return false;
    }

    try {
      final api = AuthApiService(baseUrl: baseUrl);
      await api.confirmPasswordReset(email, code, newPassword);
      state = AuthState();
      return true;
    } catch (e) {
      state = AuthState(error: _formatError(e));
      return false;
    }
  }

  void logout() {
    state = AuthState();
  }

  void clearError() {
    state = AuthState(token: state.token, isLoading: state.isLoading);
  }

  String _formatError(dynamic e) {
    final str = e.toString();
    if (str.startsWith('Exception: ')) {
      return str.substring('Exception: '.length);
    }
    return str;
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
