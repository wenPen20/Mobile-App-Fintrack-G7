// lib/features/transactions/data/mock_transactions.dart
//
// TEMP (Sprint 1): sample transactions so we can build & preview the UI before
// the API exists. Spans April–June 2026, with June populated like our reference
// screenshots. Replaced by real data from P4's API after Sprint 1.

import 'package:flutter/foundation.dart' show ValueNotifier;

import 'package:fintrack_mobile/features/budget/models/category.dart';
import '../models/transaction_ui.dart';
import 'mock_categories.dart';

// Small helper: look up a Category by name from our mock list, so the rows below
// stay readable (e.g. `_cat('Food & Drinks')` instead of a long firstWhere).
Category _cat(String name) => mockCategories.firstWhere((c) => c.name == name);

final List<TransactionUi> mockTransactions = [
  // ---- June 2026 -----------------------------------------------------------
  TransactionUi(
    name: 'Online Shopping',
    category: _cat('Shopping'),
    amount: -81.25,
    dateTime: DateTime(2026, 6, 24, 1, 20),
  ),
  TransactionUi(
    name: 'Dinner',
    category: _cat('Food & Drinks'),
    amount: -25.70,
    dateTime: DateTime(2026, 6, 13, 13, 37),
    note: 'DuitNow QR payment, eWallet Balance',
  ),
  TransactionUi(
    name: 'Parking payment',
    category: _cat('Transport'),
    amount: -1.06,
    dateTime: DateTime(2026, 6, 12, 8, 14),
    note: 'parking fee, eWallet balance',
  ),
  TransactionUi(
    name: 'Grocery shopping',
    category: _cat('Shopping'),
    amount: -85.30,
    dateTime: DateTime(2026, 6, 8, 19, 30),
  ),
  TransactionUi(
    name: 'Monthly salary',
    category: _cat('Salary'),
    amount: 5000.00,
    dateTime: DateTime(2026, 6, 5, 9, 0),
    note: 'June payroll',
  ),
  TransactionUi(
    name: 'Netflix',
    category: _cat('Entertainment'),
    amount: -55.90,
    dateTime: DateTime(2026, 6, 3, 21, 0),
  ),

  // ---- May 2026 ------------------------------------------------------------
  TransactionUi(
    name: 'Electric bill',
    category: _cat('Bills'),
    amount: -120.00,
    dateTime: DateTime(2026, 5, 28, 10, 15),
  ),
  TransactionUi(
    name: 'Pharmacy',
    category: _cat('Health'),
    amount: -34.80,
    dateTime: DateTime(2026, 5, 20, 16, 45),
  ),
  TransactionUi(
    name: 'Train ticket',
    category: _cat('Transport'),
    amount: -3.40,
    dateTime: DateTime(2026, 5, 12, 7, 50),
  ),
  TransactionUi(
    name: 'Monthly salary',
    category: _cat('Salary'),
    amount: 5000.00,
    dateTime: DateTime(2026, 5, 5, 9, 0),
  ),

  // ---- April 2026 ----------------------------------------------------------
  TransactionUi(
    name: 'Dividend payout',
    category: _cat('Investment'),
    amount: 220.50,
    dateTime: DateTime(2026, 4, 27, 11, 0),
  ),
  TransactionUi(
    name: 'Textbooks',
    category: _cat('Education'),
    amount: -89.90,
    dateTime: DateTime(2026, 4, 22, 15, 30),
  ),
  TransactionUi(
    name: 'Dinner with friends',
    category: _cat('Food & Drinks'),
    amount: -42.00,
    dateTime: DateTime(2026, 4, 18, 20, 10),
    note: 'Split bill',
  ),
];

// ---------------------------------------------------------------------------
// Mutations + a change signal (still plain Flutter, no Riverpod).
//
// The Add/Edit screen is opened from the nav bar — decoupled from the list
// screen — so mutating the list can't rely on that screen's setState. These
// helpers bump `transactionsRevision`; any screen that listens rebuilds.
// ---------------------------------------------------------------------------

/// Increments every time the list changes; screens listen to this to refresh.
final ValueNotifier<int> transactionsRevision = ValueNotifier<int>(0);

/// Month of the most recent add/edit, so the list can jump there to show it.
DateTime? lastTouchedMonth;

void addTransaction(TransactionUi t) {
  mockTransactions.add(t);
  lastTouchedMonth = DateTime(t.dateTime.year, t.dateTime.month);
  transactionsRevision.value++;
}

void replaceTransaction(TransactionUi oldTx, TransactionUi newTx) {
  final i = mockTransactions.indexOf(oldTx);
  if (i != -1) mockTransactions[i] = newTx;
  lastTouchedMonth = DateTime(newTx.dateTime.year, newTx.dateTime.month);
  transactionsRevision.value++;
}

void removeTransaction(TransactionUi t) {
  mockTransactions.remove(t);
  transactionsRevision.value++;
}

void insertTransactionAt(int index, TransactionUi t) {
  final at = (index >= 0 && index <= mockTransactions.length)
      ? index
      : mockTransactions.length;
  mockTransactions.insert(at, t);
  transactionsRevision.value++;
}
