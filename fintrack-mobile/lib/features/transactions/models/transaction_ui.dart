// lib/features/transactions/models/transaction_ui.dart
//
// A "presentation model" — a plain Dart class that holds the data ONE transaction
// row needs in order to be drawn on screen during this UI-design phase.
//
// Why a separate class instead of the real TransactionModel?
//  - The real model (models/transaction_model.dart) mirrors P4's backend and has
//    NO category icon/colour.
//  - Our Cashew-inspired design needs those, so we keep a UI-only model here and
//    feed it with mock data. The real model stays untouched until we wire the API.

// We import the Category data class (which YOU will write in category.dart).
// An import gives this file access to the `Category` type defined over there.
//
// Why a class and not an enum? Categories are USER-OWNED, EDITABLE data that
// lives in Supabase (users add/remove/rename their own). That's open-ended
// runtime data -> a data class + a List, not a fixed compile-time enum.
import 'package:fintrack_mobile/features/budget/models/category.dart';

class TransactionUi {
  final String name; // e.g. "Claude Pro Subscription"
  final Category category; // the full category -> gives us name, icon, colour

  // We store the amount as a SIGNED number:
  //   negative  = money out  (expense)  e.g. -25.70
  //   positive  = money in   (income)   e.g.  5000.00
  // The sign is our single source of truth for income vs expense in the UI.
  final double amount;

  final DateTime dateTime; // full date AND time (we show both: day header + HH:mm)
  final String? note; // optional ("?" = nullable). e.g. "DuitNow QR payment"

  // ---- Constructor --------------------------------------------------------
  // `const` lets callers build instances at compile time (cheaper, and lets us
  // use `const` lists of mock data). Named parameters `{...}` make call sites
  // readable: TransactionUi(name: '...', category: ..., amount: -12.5, ...).
  // `required` = the caller MUST provide it; `note` is optional so it's not required.
  const TransactionUi({
    required this.name,
    required this.category,
    required this.amount,
    required this.dateTime,
    this.note,
  });

  // ---- Convenience getters -------------------------------------------------
  // A "getter" is a computed read-only property. These keep the widgets clean: instead of
  // checking `t.amount < 0` everywhere, a widget can ask `t.isExpense`.

  bool get isExpense {
    return amount < 0;
  }

  bool get isIncome {
    return amount >= 0;
  }

  // The amount WITHOUT its sign, formatted for display, e.g. "RM 25.70".
  // We use the absolute value because the widget shows the +/- via colour and an
  // arrow icon, not a minus sign. `.abs()` strips the sign; `toStringAsFixed(2)`
  // forces exactly 2 decimal places ("RM 5.00", not "RM 5.0").
  String get displayAmount => 'RM ${amount.abs().toStringAsFixed(2)}';
}
