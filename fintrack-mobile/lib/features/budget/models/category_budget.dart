// lib/features/budget/models/category_budget.dart
//
// TEMP (Sprint 1): mirrors what a `budget` row would look like once P4's API
// exists (a monthly spending limit set per category). Hardcoded for now via
// mock_budgets.dart.
//
// Pure Dart — no Flutter imports.

import 'category.dart';

class CategoryBudget {
  final Category category;
  final double limit; // the monthly spending cap for this category

  const CategoryBudget({required this.category, required this.limit});
}
