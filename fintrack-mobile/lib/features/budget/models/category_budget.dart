// lib/features/budget/models/category_budget.dart
//
// Pairs a Category with its monthly spending limit (the `budgets` table row).
// Pure Dart — no Flutter imports.

import 'category.dart';

class CategoryBudget {
  final Category category;
  final double limit; // the monthly spending cap for this category

  const CategoryBudget({required this.category, required this.limit});
}
