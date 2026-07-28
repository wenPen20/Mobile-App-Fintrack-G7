// lib/features/transactions/screens/widgets/transaction_summary_bar.dart
//
// The little summary pill under the months:
//
//   ▼ RM210.58   |   ▲ RM168.78   |   =  -RM41.80
//   (expenses)        (income)         (net = income - expenses)
//
// It's given the transactions for the selected month and adds them up itself.

import 'package:flutter/material.dart';
import 'package:fintrack_mobile/core/constants/app_colors.dart';
import '../../models/transaction_ui.dart';

class TransactionSummaryBar extends StatelessWidget {
  final List<TransactionUi> transactions; // already filtered to the chosen month
  const TransactionSummaryBar({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    // Add up expenses (as positive numbers) and income separately.
    double expense = 0;
    double income = 0;
    for (final t in transactions) {
      if (t.isExpense) {
        expense += t.amount.abs(); // .abs() so -25.70 counts as 25.70
      } else {
        income += t.amount;
      }
    }
    final net = income - expense; // can be negative (spent more than earned)

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _segment(
            icon: Icons.arrow_drop_up,
            color: Colors.green.shade600,
            amount: income,
          ),
          _divider(),
          _segment(
            icon: Icons.arrow_drop_down,
            color: Colors.red.shade400,
            amount: expense,
          ),
          _divider(),
          _segment(
            icon: net < 0 
                ? Icons.arrow_drop_down 
                : (net > 0 ? Icons.arrow_drop_up : Icons.drag_handle_rounded),
            color: net < 0 
                ? Colors.red.shade400 
                : (net > 0 ? Colors.green.shade600 : AppColors.textPrimary),
            amount: net,
          ),
        ],
      ),
    );
  }

  // One of the three segments. `Expanded` makes the three share the width evenly.
  Widget _segment({
    required IconData icon,
    required Color color,
    required double amount,
  }) {
    // Show amount formatted (use absolute value since the arrow icon indicates the sign).
    final text = 'RM${amount.abs().toStringAsFixed(2)}';
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // A thin vertical line between segments.
  Widget _divider() => Container(width: 1, height: 20, color: AppColors.border);
}
