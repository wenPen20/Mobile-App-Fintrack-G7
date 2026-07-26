import 'package:flutter/material.dart';
import 'package:fintrack_mobile/core/constants/app_colors.dart';

/// Floating action button that opens the AI assistant context.
class AiAssistantFab extends StatelessWidget {
  const AiAssistantFab({super.key});

  void _openChat(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('FinTrack AI Assistant opening...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.9,
      child: FloatingActionButton(
        onPressed: () => _openChat(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        tooltip: 'FinTrack Assistant',
        child: const Icon(Icons.auto_awesome),
      ),
    );
  }
}
