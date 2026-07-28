import 'package:flutter/material.dart';
import 'package:fintrack_mobile/core/constants/app_colors.dart';
import '../../utils/date_format.dart';

class DaySectionHeader extends StatelessWidget {
  final DateTime day;
  const DaySectionHeader({super.key, required this.day});

  @override
  Widget build(BuildContext context) {
    return Padding(
      // a little breathing room above/below the header
      padding: const EdgeInsets.only(top: 16, bottom: 4),
      child: Text(
        formatDayHeader(day), // "Wednesday, 24 June"
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
