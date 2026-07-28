// lib/features/transactions/data/mock_transactions.dart
//
// TEMP (Sprint 1): sample transactions so we can build & preview the UI before
// the API exists. Spans April–June 2026, with June populated like our reference
// screenshots. Replaced by real data from P4's API after Sprint 1.

import '../models/category.dart';
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
    account: 'TnG',
    amount: -81.25,
    dateTime: DateTime(2026, 6, 24, 1, 20),
  ),
  TransactionUi(
    name: 'Dinner',
    category: _cat('Food & Drinks'),
    account: 'TnG',
    amount: -25.70,
    dateTime: DateTime(2026, 6, 13, 13, 37),
    note: 'DuitNow QR payment, eWallet Balance',
  ),
  TransactionUi(
    name: 'Parking payment',
    category: _cat('Transport'),
    account: 'TnG',
    amount: -1.06,
    dateTime: DateTime(2026, 6, 12, 8, 14),
    note: 'parking fee, eWallet balance',
  ),
  TransactionUi(
    name: 'Grocery shopping',
    category: _cat('Shopping'),
    account: 'Bank',
    amount: -85.30,
    dateTime: DateTime(2026, 6, 8, 19, 30),
  ),
  TransactionUi(
    name: 'Monthly salary',
    category: _cat('Salary'),
    account: 'Bank',
    amount: 5000.00,
    dateTime: DateTime(2026, 6, 5, 9, 0),
    note: 'June payroll',
  ),
  TransactionUi(
    name: 'Netflix',
    category: _cat('Entertainment'),
    account: 'Bank',
    amount: -55.90,
    dateTime: DateTime(2026, 6, 3, 21, 0),
  ),

  // ---- May 2026 ------------------------------------------------------------
  TransactionUi(
    name: 'Electric bill',
    category: _cat('Bills'),
    account: 'Bank',
    amount: -120.00,
    dateTime: DateTime(2026, 5, 28, 10, 15),
  ),
  TransactionUi(
    name: 'Pharmacy',
    category: _cat('Health'),
    account: 'TnG',
    amount: -34.80,
    dateTime: DateTime(2026, 5, 20, 16, 45),
  ),
  TransactionUi(
    name: 'Train ticket',
    category: _cat('Transport'),
    account: 'TnG',
    amount: -3.40,
    dateTime: DateTime(2026, 5, 12, 7, 50),
  ),
  TransactionUi(
    name: 'Monthly salary',
    category: _cat('Salary'),
    account: 'Bank',
    amount: 5000.00,
    dateTime: DateTime(2026, 5, 5, 9, 0),
  ),

  // ---- April 2026 ----------------------------------------------------------
  TransactionUi(
    name: 'Dividend payout',
    category: _cat('Investment'),
    account: 'Bank',
    amount: 220.50,
    dateTime: DateTime(2026, 4, 27, 11, 0),
  ),
  TransactionUi(
    name: 'Textbooks',
    category: _cat('Education'),
    account: 'Bank',
    amount: -89.90,
    dateTime: DateTime(2026, 4, 22, 15, 30),
  ),
  TransactionUi(
    name: 'Dinner with friends',
    category: _cat('Food & Drinks'),
    account: 'TnG',
    amount: -42.00,
    dateTime: DateTime(2026, 4, 18, 20, 10),
    note: 'Split bill',
  ),
];
