// lib/features/transactions/screens/widgets/category_avatar.dart
//
// The little coloured circle with a category icon inside (e.g. an orange circle
// with a fork-and-knife for "Food & Drinks"). It takes a Category and uses our
// category_visuals helpers to turn the stored strings into a real Icon + Color.

import 'package:flutter/material.dart';
import 'package:fintrack_mobile/features/budget/models/category.dart';
import 'package:fintrack_mobile/core/constants/category_visuals.dart';

class CategoryAvatar extends StatelessWidget {
  final Category category;
  final double size;
  const CategoryAvatar({super.key, required this.category, this.size = 44});

  @override
  Widget build(BuildContext context) {
    // Convert the category's stored "#hex" string into a real Color once.
    final color = colorFromHex(category.colorHex);

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center, // centre the icon inside the circle
      decoration: BoxDecoration(
        // A faded version of the category colour as the background. `withValues`
        // is Flutter's current way to tweak a colour — here alpha 0.15 = 15%
        // opacity, giving a soft tint behind the solid-colour icon.
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle, // make the Container a circle, not a square
      ),
      child: Icon(
        iconForName(category.icon), // "car" -> Icons.directions_car
        color: color, // full-strength category colour for the icon itself
        size: size * 0.5, // icon takes up half the circle
      ),
    );
  }
}
