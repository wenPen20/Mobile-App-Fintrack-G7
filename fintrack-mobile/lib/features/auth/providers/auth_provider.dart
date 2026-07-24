import 'package:flutter_riverpod/flutter_riverpod.dart';

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

    // Stub: simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    state = AuthState(token: 'stub_mock_jwt_token_12345');
    return true;
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

    // Stub: simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    state = AuthState();
    return true;
  }

  Future<bool> requestPasswordReset(String email) async {
    state = AuthState(isLoading: true);

    if (email.trim().isEmpty || !email.contains('@')) {
      state = AuthState(error: 'Please enter a valid email address');
      return false;
    }

    await Future.delayed(const Duration(milliseconds: 800));
    state = AuthState();
    return true;
  }

  Future<bool> confirmPasswordReset(String code, String newPassword) async {
    state = AuthState(isLoading: true);

    if (code.trim().isEmpty) {
      state = AuthState(error: 'Reset code is required');
      return false;
    }
    if (newPassword.length < 8) {
      state = AuthState(error: 'Password must be at least 8 characters');
      return false;
    }

    await Future.delayed(const Duration(milliseconds: 800));
    state = AuthState();
    return true;
  }

  void logout() {
    state = AuthState();
  }

  void clearError() {
    state = AuthState(token: state.token, isLoading: state.isLoading);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
