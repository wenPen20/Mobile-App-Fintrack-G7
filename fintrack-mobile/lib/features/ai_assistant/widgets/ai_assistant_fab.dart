import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../screens/ai_chat_screen.dart';

/// Floating action button widget mounting the AI assistant modal launcher.
///
/// Displayed within the main app shell, allowing users to open the AI chat bottom sheet.
class AiAssistantFab extends StatelessWidget {
  /// Creates an [AiAssistantFab] instance.
  const AiAssistantFab({super.key});

  /// Displays the [AiChatScreen] interface within a modal bottom sheet.
  void _openChat(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const AiChatScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.8,
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
