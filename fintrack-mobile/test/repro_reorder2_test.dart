// Repro 2: what happens when the category order changes *while* a drag is in
// flight — i.e. when a previous reorder's deferred post-frame update lands
// during the next drag.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fintrack_mobile/features/budget/models/category.dart';
import 'package:fintrack_mobile/features/budget/providers/budget_provider.dart';
import 'package:fintrack_mobile/features/profile/providers/category_provider.dart';
import 'package:fintrack_mobile/features/profile/screens/category_management_screen.dart';

const ids = ['food', 'rent', 'fuel', 'fun', 'gym'];

List<Category> fakeCategories() => [
  for (final n in ids)
    Category(
      id: n,
      name: n,
      icon: 'category',
      colorHex: '#888888',
      type: 'expense',
      isDefault: false,
    ),
];

void main() {
  testWidgets('order changes mid-drag', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer(
      overrides: [categoriesProvider.overrideWith((ref) async => fakeCategories())],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: CategoryManagementScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final handles = find.byIcon(Icons.drag_indicator);
    final gesture = await tester.startGesture(tester.getCenter(handles.at(0)));
    await tester.pump(const Duration(milliseconds: 300));
    for (var i = 0; i < 4; i++) {
      await gesture.moveBy(const Offset(0, 16));
      await tester.pump(const Duration(milliseconds: 16));
    }

    // Mid-drag: a stale deferred update from an earlier reorder lands.
    container
        .read(categoryOrderProvider.notifier)
        .updateOrder(['gym', 'fun', 'fuel', 'rent', 'food']);
    await tester.pump(const Duration(milliseconds: 16));

    for (var i = 0; i < 4; i++) {
      await gesture.moveBy(const Offset(0, 16));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pumpAndSettle();

    debugPrint('SURVIVED');
  });
}
