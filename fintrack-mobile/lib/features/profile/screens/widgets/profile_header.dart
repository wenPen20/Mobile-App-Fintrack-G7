// lib/features/profile/screens/widgets/profile_header.dart
import 'package:flutter/material.dart';
import 'package:fintrack_mobile/core/constants/app_colors.dart';
import 'package:fintrack_mobile/core/constants/app_text_styles.dart';

class ProfileHeader extends StatelessWidget {
  final String name;
  final String email;
  final VoidCallback onEditPressed;

  const ProfileHeader({
    super.key,
    required this.name,
    required this.email,
    required this.onEditPressed,
  });

  String _getInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'U';

    final parts = trimmed.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';

    if (parts.length == 1) {
      return parts[0][0];
    }

    return parts.first[0] + parts.last[0];
  }

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(name);

    return Column(
      children: [
        // Avatar circle with border
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary, width: 2),
          ),
          child: CircleAvatar(
            radius: 48,
            backgroundColor: AppColors.primary,
            child: Text(
              initials,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Name & Email
        Text(name, style: AppTextStyles.headingLarge),
        const SizedBox(height: 4),
        Text(email, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 16),
        // Edit Profile Button
        OutlinedButton.icon(
          onPressed: onEditPressed,
          icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.primary),
          label: const Text(
            'Edit Profile',
            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.border),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          ),
        ),
      ],
    );
  }
}
