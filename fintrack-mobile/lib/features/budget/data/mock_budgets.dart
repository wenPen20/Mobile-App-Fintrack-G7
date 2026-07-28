// lib/features/budget/data/mock_budgets.dart
//
// TEMP (Sprint 1): sample monthly budget limits, one per category that has
// activity in mock_transactions.dart. Replaced by real data from P4's API
// after Sprint 1.

import '../models/category.dart';
import '../models/category_budget.dart';
import 'mock_categories.dart';

Category _cat(String name) => mockCategories.firstWhere((c) => c.name == name);

final List<CategoryBudget> mockBudgets = [
  CategoryBudget(category: _cat('Food & Drinks'), limit: 600),
  CategoryBudget(category: _cat('Transport'), limit: 200),
  CategoryBudget(category: _cat('Shopping'), limit: 250),
  CategoryBudget(category: _cat('Entertainment'), limit: 150),
  CategoryBudget(category: _cat('Health'), limit: 200),
  CategoryBudget(category: _cat('Bills'), limit: 300),
];
