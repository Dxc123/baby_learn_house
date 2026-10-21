import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:baby_learn_house/app/core/annotated_reading_text.dart';
import 'widget_test.dart' show launch;

void main() {
  setUp(() => Get.testMode = true);
  tearDown(() => Get.reset());
  testWidgets('reader fits narrow large text and respects pinyin toggle', (
    tester,
  ) async {
    final store = await launch(tester, width: 320, scale: 2);
    Get.toNamed('/read/poetry-jingyesi');
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AnnotatedReadingText), findsWidgets);
    expect(tester.takeException(), isNull);
    await store.setShowPinyin(false);
    await tester.pumpAndSettle();
    expect(find.text('chuáng'), findsNothing);
    expect(store.learned, isEmpty);
  });
  testWidgets('classic deep link opens exact line, marks only that item', (
    tester,
  ) async {
    final store = await launch(tester);
    Get.toNamed('/learn/classics/classic-opening-12');
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
    expect(Get.currentRoute, contains('/read/classics-opening'));
    expect(
      find.text('母亲用中断织布作比喻，劝他坚持学习。').hitTestable(),
      findsOneWidget,
      reason: 'Opening line 12 must reveal it without manual scrolling',
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('reader-learned')),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('reader-learned')));
    await tester.pumpAndSettle();
    expect(store.learned, {'classic-opening-12'});
    expect(tester.takeException(), isNull);
  });
}
