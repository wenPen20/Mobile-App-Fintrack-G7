// lib/features/transactions/data/mock_categories.dart
//
// TEMP (Sprint 1): hardcoded copy of the default `category` rows from Supabase.
// Replaced by an API call after Sprint 1. Order here = display order.

import 'package:fintrack_mobile/features/budget/models/category.dart';

const List<Category> mockCategories = [
  // ---- Expense categories --------------------------------------------------
  Category(
    id: '7a8c19db-4452-4cd8-918e-f80061803e3c',
    name: 'Food & Drinks',
    icon: 'utensils',
    colorHex: '#D85A30',
    type: 'expense',
    isDefault: true,
  ),
  Category(
    id: 'e6cfb9fb-694b-4264-b412-8be30d1ad0ce',
    name: 'Transport',
    icon: 'car',
    colorHex: '#378ADD',
    type: 'expense',
    isDefault: true,
  ),
  Category(
    id: '41af5aff-d0a6-4669-a2bc-789e09c17c29',
    name: 'Shopping',
    icon: 'shopping-bag',
    colorHex: '#7F77DD',
    type: 'expense',
    isDefault: true,
  ),
  Category(
    id: '443e60ac-eef5-454f-953d-a937984fc1cb',
    name: 'Bills',
    icon: 'file-text',
    colorHex: '#E24B4A',
    type: 'expense',
    isDefault: true,
  ),
  Category(
    id: 'b23b862f-cb04-47fa-a021-149294a0bdc8',
    name: 'Entertainment',
    icon: 'film',
    colorHex: '#EF9F27',
    type: 'expense',
    isDefault: true,
  ),
  Category(
    id: 'd79f57be-0e2c-4588-839d-462d96702ffe',
    name: 'Health',
    icon: 'heart',
    colorHex: '#D4537E',
    type: 'expense',
    isDefault: true,
  ),
  Category(
    id: 'a962001f-f5b0-48f0-b7d6-d8c88b85610d',
    name: 'Travel',
    icon: 'map-pin',
    colorHex: '#185FA5',
    type: 'expense',
    isDefault: true,
  ),
  Category(
    id: '0f593876-2d04-432a-a420-8ec18cfe73ff',
    name: 'Education',
    icon: 'book',
    colorHex: '#639922',
    type: 'expense',
    isDefault: true,
  ),
  Category(
    id: '68425671-49ff-44c9-a0d4-fdc5f3b8c191',
    name: 'Other Expense',
    icon: 'more-horizontal',
    colorHex: '#888780',
    type: 'expense',
    isDefault: true,
  ),

  // ---- Income categories ---------------------------------------------------
  Category(
    id: '1f38d98e-ea8e-4d14-8ee6-699a7d919d2e',
    name: 'Salary',
    icon: 'briefcase',
    colorHex: '#1D9E75',
    type: 'income',
    isDefault: true,
  ),
  Category(
    id: '27611bd8-8cea-4ecb-807a-0f07c7eac9fa',
    name: 'Freelance',
    icon: 'laptop',
    colorHex: '#0F6E56',
    type: 'income',
    isDefault: true,
  ),
  Category(
    id: '380e43f6-4835-4dd7-9d5c-c2621915f222',
    name: 'Investment',
    icon: 'trending-up',
    colorHex: '#5DCAA5',
    type: 'income',
    isDefault: true,
  ),
  Category(
    id: '3cdc3cb1-5cdb-4fd8-8330-9d07c8599f15',
    name: 'Business',
    icon: 'store',
    colorHex: '#085041',
    type: 'income',
    isDefault: true,
  ),
  Category(
    id: 'ef6f04d2-508c-4ab9-a5e9-b2335f5f1048',
    name: 'Other Income',
    icon: 'plus-circle',
    colorHex: '#9FE1CB',
    type: 'income',
    isDefault: true,
  ),
];
