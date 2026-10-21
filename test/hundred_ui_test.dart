import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'widget_test.dart' show launch;
import 'math_activity_ui_test.dart' show press;

void main() {
  setUp(() => Get.testMode = true);
  tearDown(() => Get.reset());
  testWidgets('hundred theme rebuild preserves selection and reentry resets', (
    t,
  ) async {
    final store = await launch(t);
    Get.toNamed('/math/hundred');
    await t.pumpAndSettle();
    await press(t, 'hundred-zero');
    await store.setTheme(1);
    await t.pumpAndSettle();
    expect(find.text('当前数字：0'), findsOneWidget);
    await t.tap(find.byTooltip('返回'));
    await t.pumpAndSettle();
    Get.toNamed('/math/hundred');
    await t.pumpAndSettle();
    expect(find.text('当前数字：1'), findsOneWidget);
    expect(store.cursors, isEmpty);
  });
  testWidgets(
    'hundred input invalid preserves selected number and zero boundaries',
    (t) async {
      final store = await launch(t, width: 320, scale: 2);
      Get.toNamed('/math/hundred');
      await t.pumpAndSettle();
      await t.ensureVisible(find.byKey(const ValueKey('hundred-input')));
      await t.enterText(find.byKey(const ValueKey('hundred-input')), '100');
      await press(t, 'hundred-submit');
      expect(
        find.byKey(const ValueKey('cell-hundred-100')).hitTestable(),
        findsOneWidget,
      );
      await t.ensureVisible(find.byKey(const ValueKey('hundred-input')));
      await t.enterText(find.byKey(const ValueKey('hundred-input')), '101');
      await press(t, 'hundred-submit');
      expect(find.text('请输入 0～100 的整数。'), findsOneWidget);
      await press(t, 'hundred-zero');
      expect(find.text('当前数字：0'), findsOneWidget);
      expect(
        t
            .widget<OutlinedButton>(
              find.byKey(const ValueKey('hundred-previous')),
            )
            .onPressed,
        isNull,
      );
      expect(store.learned, isEmpty);
      expect(store.cursors, isEmpty);
      expect(t.takeException(), isNull);
    },
  );
}
