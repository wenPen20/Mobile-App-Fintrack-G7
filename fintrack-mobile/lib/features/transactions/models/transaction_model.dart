import 'package:fintrack_mobile/features/transactions/models/transaction_ui.dart';
import 'package:fintrack_mobile/features/budget/models/category.dart';

/// Data model representing a transaction record fetched from the API.
class TransactionModel {
  final String id;
  final String userId;
  final String categoryId;
  final String categoryName; // joined from categories table via API
  final String? categoryIcon; // joined from categories table via API
  final String? categoryColorHex; // joined from categories table via API
  final String type; // 'income' or 'expense'
  final double amount;
  final String? title;
  final String? note;
  final DateTime transactionDate;
  final DateTime createdAt;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.categoryName,
    this.categoryIcon,
    this.categoryColorHex,
    required this.type,
    required this.amount,
    this.title,
    this.note,
    required this.transactionDate,
    required this.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'],
      userId: json['user_id'],
      categoryId: json['category_id'] ?? '',
      categoryName: json['category_name'] ?? 'Unknown',
      categoryIcon: json['category_icon'] as String?,
      categoryColorHex: json['category_color_hex'] as String?,
      type: json['type'],
      amount: (json['amount'] as num).toDouble(),
      title: json['title'],
      note: json['note'],
      transactionDate: DateTime.parse(json['transaction_date']).toLocal(),
      createdAt: DateTime.parse(json['created_at']).toLocal(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category_id': categoryId,
      'type': type,
      'amount': amount,
      'title': title,
      'note': note,
      'transaction_date': transactionDate.toIso8601String(),
    };
  }
}

extension TransactionModelX on TransactionModel {
  TransactionUi toUiModel() {
    final signedAmount = type == 'expense' ? -amount.abs() : amount.abs();

    return TransactionUi(
      name: (title != null && title!.isNotEmpty) ? title! : categoryName,
      category: Category(
        id: categoryId,
        name: categoryName,
        icon: categoryIcon ?? 'sports_esports',
        colorHex: categoryColorHex ?? '#30D158',
        type: type,
        isDefault: false,
      ),
      amount: signedAmount,
      dateTime: transactionDate,
      note: note,
    );
  }
}