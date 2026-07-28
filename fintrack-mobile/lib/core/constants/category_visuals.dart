// lib/features/transactions/utils/category_visuals.dart
//
// The "translation layer" between the DATA (plain strings stored in the DB,
// like "utensils" and "#D85A30") and the FLUTTER VISUALS (IconData, Color).
//
// We keep these here — NOT in category.dart — on purpose:
//   - category.dart stays pure data (mirrors the backend, no Flutter).
//   - This file is the only place that knows how a category "looks" in Flutter.
// If we ever changed icon packs or colour rules, we'd edit only this file.
//
// These are plain TOP-LEVEL functions (not inside a class). In Dart that's
// totally normal for small, stateless helpers — no need to wrap them in a class.

import 'package:flutter/material.dart';

/// Turns a hex colour string like "#D85A30" (or "D85A30") into a Flutter [Color].
///
/// Gotcha #1 — the leading "#": the DB stores "#D85A30", but Dart's number
/// parser doesn't understand "#". So we strip it first with replaceFirst.
///
/// Gotcha #2 — the ALPHA channel: Flutter's Color wants a 32-bit ARGB value:
///   0xAARRGGBB   (AA = alpha/opacity, RR = red, GG = green, BB = blue)
/// A hex like "D85A30" is only RRGGBB (24 bits) — it has no alpha. If we used it
/// as-is the alpha byte would be 0x00 = fully transparent (invisible!). So we
/// force full opacity by OR-ing in 0xFF000000 (alpha = FF = 255 = opaque).
Color colorFromHex(String hex) {
  // 1) Drop a leading '#'. ("#D85A30" -> "D85A30")
  final cleaned = hex.replaceFirst('#', '');

  // 2) Parse the remaining text as a base-16 (hexadecimal) integer.
  //    radix: 16 tells int.parse the digits are hex (0-9, A-F), not decimal.
  final rgb = int.parse(cleaned, radix: 16); // e.g. 0xD85A30

  // 3) Add the alpha byte so the colour is fully opaque, then build the Color.
  //    `0xFF000000 | rgb` sets AA=FF and keeps the RRGGBB bits.
  return Color(0xFF000000 | rgb);
}

/// Maps a category's icon NAME (the reference string from the DB, e.g. "car")
/// to a real Flutter [IconData].
///
/// Why a Map? The DB uses "Lucide"-style names ("utensils", "file-text", "car")
/// which DON'T match Flutter's own icon names ("restaurant", "description",
/// "directions_car"). So we keep a small lookup table translating one to the other.
/// (This covers the 14 default categories. If users later pick custom icons,
///  we'd either add entries here or bring in a dedicated icon package.)
const Map<String, IconData> _iconByName = {
  'book': Icons.menu_book, // Education
  'briefcase': Icons.work, // Salary
  'laptop': Icons.laptop_mac, // Freelance
  'trending-up': Icons.trending_up, // Investment
  'store': Icons.storefront, // Business
  'shopping-bag': Icons.shopping_bag, // Shopping
  'file-text': Icons.description, // Bills
  'more-horizontal': Icons.more_horiz, // Other Expense
  'utensils': Icons.restaurant, // Food & Drinks
  'map-pin': Icons.place, // Travel
  'car': Icons.directions_car, // Transport
  'film': Icons.movie, // Entertainment
  'heart': Icons.favorite, // Health
  'plus-circle': Icons.add_circle, // Other Income
};

IconData iconForName(String name) {
  // Looking up a missing key in a Map returns null. The `??` ("if null") operator
  // then falls back to a safe default, so an unknown icon name never crashes the UI.
  return _iconByName[name] ?? Icons.category_outlined;
}
