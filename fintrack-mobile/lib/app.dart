import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Root application widget.
///
/// Uses [ConsumerWidget] so it can later consume the [routerProvider]
/// from core/router/app_router.dart once routing is configured (Commit 10).
class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'FinTrack',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A73E8)),
        useMaterial3: true,
      ),
      // TODO(router): replace with MaterialApp.router once GoRouter is
      // configured in core/router/app_router.dart (Commit 10).
      home: const Scaffold(
        body: Center(
          child: Text('FinTrack — Auth coming soon'),
        ),
      ),
    );
  }
}
