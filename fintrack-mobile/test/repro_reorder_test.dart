// Repro: reorder the real CategoryManagementScreen.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fintrack_mobile/features/budget/models/category.dart';
import 'package:fintrack_mobile/features/budget/providers/budget_provider.dart';
import 'package:fintrack_mobile/features/profile/screens/category_management_screen.dart';

List<Category> fakeCategories() => [
  for (final n in ['Food', 'Rent', 'Fuel', 'Fun', 'Gym'])
    Category(
      id: n.toLowerCase(),
      name: n,
      icon: 'category',
      colorHex: '#888888',
      type: 'expense',
      isDefault: false,
    ),
  for (final n in ['Salary', 'Bonus'])
    Category(
      id: n.toLowerCase(),
      name: n,
      icon: 'category',
      colorHex: '#888888',
      type: 'income',
      isDefault: false,
    ),
];

Future<void> pumpScreen(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [categoriesProvider.overrideWith((ref) async => fakeCategories())],
      child: const MaterialApp(home: CategoryManagementScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

/// Drag the handle at [from] down/up by [rows] and release.
Future<void> drag(WidgetTester tester, int from, int rows, {bool settle = true}) async {
  final handles = find.byIcon(Icons.drag_indicator);
  final gesture = await tester.startGesture(tester.getCenter(handles.at(from)));
  await tester.pump(const Duration(milliseconds: 300));
  final step = rows > 0 ? 12.0 : -12.0;
  final steps = (rows.abs() * 74 / 12).round();
  for (var i = 0; i < steps; i++) {
    await gesture.moveBy(Offset(0, step));
    await tester.pump(const Duration(milliseconds: 16));
  }
  await gesture.up();
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

List<String?> visibleOrder(WidgetTester tester) => tester
    .widgetList<Text>(find.descendant(of: find.byType(ListTile), matching: find.byType(Text)))
    .map((t) => t.data)
    .toList();

void main() {
  testWidgets('A: single drag, settled', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await pumpScreen(tester);
    await drag(tester, 0, 2);
    debugPrint('A ORDER: ${visibleOrder(tester)}');
  });

  testWidgets('B: two drags back to back', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await pumpScreen(tester);
    await drag(tester, 0, 2);
    debugPrint('B AFTER 1: ${visibleOrder(tester)}');
    await drag(tester, 3, -2);
    debugPrint('B AFTER 2: ${visibleOrder(tester)}');
  });

  testWidgets('C: second drag starts before deferred update lands', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await pumpScreen(tester);
    await drag(tester, 0, 2, settle: false);
    await drag(tester, 1, 1);
    debugPrint('C ORDER: ${visibleOrder(tester)}');
  });

  testWidgets('D: drag then switch tab immediately', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await pumpScreen(tester);
    await drag(tester, 0, 2, settle: false);
    await tester.tap(find.text('Income'));
    await tester.pumpAndSettle();
    debugPrint('D ORDER: ${visibleOrder(tester)}');
  });

  testWidgets('E: pre-existing saved order', (tester) async {
    SharedPreferences.setMockInitialValues({
      'category_order': ['gym', 'fun', 'fuel', 'rent', 'food', 'bonus', 'salary'],
    });
    await pumpScreen(tester);
    debugPrint('E START: ${visibleOrder(tester)}');
    await drag(tester, 0, 3);
    debugPrint('E ORDER: ${visibleOrder(tester)}');
  });

  testWidgets('F: reorder on the income tab', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await pumpScreen(tester);
    await tester.tap(find.text('Income'));
    await tester.pumpAndSettle();
    await drag(tester, 0, 1);
    debugPrint('F ORDER: ${visibleOrder(tester)}');
    debugPrint('F SAVED: ${(await SharedPreferences.getInstance()).getStringList('category_order')}');
  });

  testWidgets('G: drag released mid-flight then list rebuilds', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await pumpScreen(tester);
    final handles = find.byIcon(Icons.drag_indicator);
    final gesture = await tester.startGesture(tester.getCenter(handles.at(0)));
    await tester.pump(const Duration(milliseconds: 300));
    for (var i = 0; i < 12; i++) {
      await gesture.moveBy(const Offset(0, 12));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    // Pump only a single frame: the drop animation is still running when the
    // post-frame callback mutates the provider.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();
    debugPrint('G ORDER: ${visibleOrder(tester)}');
  });
}
