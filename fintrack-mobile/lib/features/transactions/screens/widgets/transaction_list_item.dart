// lib/features/transactions/screens/widgets/transaction_list_item.dart
//
// ONE transaction row, like in the screenshots:
//
//   ( icon )  Name                              01:20
//             note text                       ↘ RM 25.70
//
// It composes CategoryAvatar plus some text, arranged with Row / Expanded / Column.

import 'package:flutter/material.dart';
import 'package:fintrack_mobile/core/constants/app_colors.dart';
import '../../models/transaction_ui.dart';
import '../../utils/date_format.dart';
import 'category_avatar.dart';

class TransactionListItem extends StatelessWidget {
  final TransactionUi transaction;
  const TransactionListItem({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final t = transaction; // short alias to keep the code below readable

    // Income = green, expense = red. We decide the colour once and reuse it for
    // both the little arrow and the amount text.
    final amountColor = t.isExpense ? Colors.red.shade400 : Colors.green.shade600;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      // A Row lays its children out LEFT-TO-RIGHT.
      child: Row(
        // Vertically centre the three columns relative to each other.
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1) The category circle (your widget).
          CategoryAvatar(category: t.category),
          const SizedBox(width: 12), // gap

          // 2) The MIDDLE block. `Expanded` tells this child to grab all the
          //    leftover horizontal space, pushing the time/amount to the far
          //    right. Without Expanded, a long name could overflow the screen.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // left-align text
              children: [
                Text(
                  t.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis, // "Very long na…" if too wide
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                // Show the note line ONLY if there is a note. This `if` inside a
                // children list is a "collection if" — a handy Dart/Flutter trick.
                if (t.note != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    t.note!, // `!` = "I promise this isn't null" (the if guarantees it)
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 12),

          // 3) The RIGHT block: time on top, amount below, both right-aligned.
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatTime(t.dateTime), // "01:20"
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min, // only as wide as its content
                children: [
                  Icon(
                    // a subtle arrow: down-right for money out, up-right for money in
                    t.isExpense ? Icons.arrow_drop_down : Icons.arrow_drop_up,
                    size: 14,
                    color: amountColor,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    t.displayAmount, // "RM 25.70"
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: amountColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
