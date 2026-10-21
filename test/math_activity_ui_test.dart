import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'widget_test.dart' show launch;

Future<void> press(WidgetTester t, String key) async {
  final f = find.byKey(ValueKey(key));
  await t.ensureVisible(f);
  await t.tap(f);
  await t.pumpAndSettle();
}

void main() {
  setUp(() => Get.testMode = true);
  tearDown(() => Get.reset());
  testWidgets('count objects expose an accessibility tap action', (t) async {
    final handle = t.ensureSemantics();
    await launch(t);
    Get.toNamed('/math/count');
    await t.pumpAndSettle();
    final node = t.getSemantics(find.bySemanticsLabel('第 1 个，未数'));
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    handle.dispose();
  });
  testWidgets('count repeat tap reset and no progress writes', (t) async {
    final store = await launch(t);
    Get.toNamed('/math/count');
    await t.pumpAndSettle();
    await press(t, 'object-0');
    await press(t, 'object-0');
    await store.setTheme(1);
    await t.pumpAndSettle();
    expect(find.text('已经数了 1 个'), findsOneWidget);
    for (var i = 1; i < 5; i++) {
      await press(t, 'object-$i');
    }
    expect(find.text('一共有 5 个'), findsOneWidget);
    await press(t, 'reset');
    expect(find.text('已经数了 0 个'), findsOneWidget);
    expect(store.learned, isEmpty);
    expect(store.cursors, isEmpty);
    await press(t, 'left-plus');
    expect(find.text('已经数了 0 个'), findsOneWidget);
  });
  testWidgets('addition reveal boundary and parameter resets', (t) async {
    await launch(t);
    Get.toNamed('/math/plus-block');
    await t.pumpAndSettle();
    expect(find.text('2 + 3 = ？'), findsOneWidget);
    await press(t, 'reveal');
    expect(find.text('2 + 3 = 5'), findsOneWidget);
    expect(find.byKey(const ValueKey('combined-quantity')), findsOneWidget);
    await press(t, 'left-plus');
    expect(find.text('3 + 3 = ？'), findsOneWidget);
    for (var i = 0; i < 4; i++) {
      await press(t, 'left-plus');
    }
    expect(
      t.widget<IconButton>(find.byKey(const ValueKey('left-plus'))).onPressed,
      isNull,
    );
    await press(t, 'reset');
    expect(find.text('7 + 3 = ？'), findsOneWidget);
  });
  testWidgets('subtraction clamps and resets', (t) async {
    await launch(t);
    Get.toNamed('/math/minus-block');
    await t.pumpAndSettle();
    await press(t, 'reveal');
    expect(find.text('5 − 2 = 3'), findsOneWidget);
    for (var i = 0; i < 5; i++) {
      await press(t, 'left-minus');
    }
    expect(find.text('0 − 0 = ？'), findsOneWidget);
    await press(t, 'reveal');
    expect(find.text('0 − 0 = 0'), findsOneWidget);
  });
  testWidgets('all math pages fit narrow large type', (t) async {
    await launch(t, width: 320, scale: 2);
    for (final id in ['count', 'plus-block', 'minus-block']) {
      Get.toNamed('/math/$id');
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      await press(t, 'left-plus');
      expect(t.takeException(), isNull);
      Get.back();
      await t.pumpAndSettle();
    }
  });
  testWidgets('all four math pages fit tablet layouts', (t) async {
    await launch(t, width: 1024);
    for (final route in [
      '/learn/numbers/number-10',
      '/math/count',
      '/math/plus-block',
      '/math/minus-block',
    ]) {
      Get.toNamed(route);
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      await t.tap(find.byTooltip('返回'));
      await t.pumpAndSettle();
    }
  });
}
