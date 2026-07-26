import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/forget_password_screen.dart';
import '../../features/auth/screens/reset_password_screen.dart';
import '../../shared/navigation/app_shell.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

// Helper class to make GoRouter react to Riverpod AuthState changes
class AuthListenable extends ChangeNotifier {
  AuthListenable(Ref ref) {
    ref.listen<AuthState>(
      authProvider,
      (previous, next) {
        notifyListeners();
      },
    );
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final authListenable = AuthListenable(ref);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    refreshListenable: authListenable,
    redirect: (BuildContext context, GoRouterState state) {
      final isAuth = ref.read(authProvider).isAuthenticated;
      final isAuthRoute = state.matchedLocation.startsWith('/login') ||
          state.matchedLocation.startsWith('/register') ||
          state.matchedLocation.startsWith('/forget-password') ||
          state.matchedLocation.startsWith('/reset-password');

      if (!isAuth && !isAuthRoute) {
        return '/login';
      }

      if (isAuth && isAuthRoute) {
        return '/home'; // Navigate to main dashboard shell when logged in
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forget-password',
        builder: (context, state) => const ForgetPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => const ResetPasswordScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return AppShell(
            currentLocation: state.uri.toString(),
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const Scaffold(
              body: Center(
                child: Text('Dashboard Screen (Home Tab)'),
              ),
            ),
          ),
          GoRoute(
            path: '/transactions',
            builder: (context, state) => const Scaffold(
              body: Center(
                child: Text('Transactions Screen (Tab)'),
              ),
            ),
          ),
          GoRoute(
            path: '/budget',
            builder: (context, state) => const Scaffold(
              body: Center(
                child: Text('Budget Screen (Tab)'),
              ),
            ),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const Scaffold(
              body: Center(
                child: Text('Profile Screen (Tab)'),
              ),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/add_transaction',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const Scaffold(
          body: Center(
            child: Text('Add Transaction Screen Modal'),
          ),
        ),
      ),
    ],
  );
});
