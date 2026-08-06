// Mirrors the Supabase `categories` table schema.
// Pure Dart — no Flutter imports. icon/colorHex are reference strings only.

class Category {
  final String id;
  final String name;
  final String icon;
  final String colorHex;
  final String type; // "expense" or "income"
  final bool isDefault;

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.colorHex,
    required this.type,
    required this.isDefault,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: (json['icon'] as String?) ?? 'category',
      colorHex: (json['color_hex'] as String?) ?? '#888888',
      type: json['type'] as String,
      isDefault: (json['is_default'] as bool?) ?? false,
    );
  }

  // ---- Convenience getters -------------------------------------------------
  bool get isExpense {
    return type == 'expense';
  }

  bool get isIncome {
    return type == 'income';
  }
}
