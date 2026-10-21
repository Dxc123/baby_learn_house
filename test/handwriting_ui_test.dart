import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:baby_learn_house/app/modules/handwriting/stroke_board.dart';
import 'widget_test.dart' show launch;

void main() {
  setUp(() => Get.testMode = true);
  tearDown(() => Get.reset());
  testWidgets('global pinyin toggle also hides annotated Hanzi words', (
    tester,
  ) async {
    final store = await launch(tester);
    await store.setShowPinyin(false);
    Get.toNamed('/learn/chinese/hanzi-yi');
    await tester.pumpAndSettle();
    expect(find.text('一个'), findsOneWidget);
    expect(find.text('yí  gè'), findsNothing);
  });
  testWidgets(
    'narrow practice tracing and worksheet selection leave progress unchanged',
    (tester) async {
      final store = await launch(tester, width: 320, scale: 2);
      Get.toNamed('/practice/hanzi-kou');
      await tester.pumpAndSettle();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(StrokeBoard), findsOneWidget);
      await tester.tap(find.text('自由描红'));
      await tester.pumpAndSettle();
      final rect = tester.getRect(find.byType(StrokeBoard));
      await tester.dragFrom(rect.center, const Offset(0, -80));
      await tester.pumpAndSettle();
      expect(
        tester.getRect(find.byType(StrokeBoard)).top,
        rect.top,
        reason:
            'Drawing must own vertical gestures instead of scrolling the page',
      );
      await tester.dragFrom(rect.center, const Offset(30, 30));
      await tester.scrollUntilVisible(
        find.text('撤销一笔'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('撤销一笔'));
      await tester.tap(find.text('清空'));
      expect(store.learned, isEmpty);
      expect(tester.takeException(), isNull);
      Get.back();
      await tester.pumpAndSettle();
      Get.toNamed('/worksheet');
      await tester.pumpAndSettle();
      await tester.tap(find.text('基础六字'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('生成并预览 · 6 字'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.takeException(), isNull);
      expect(store.learned, isEmpty);
    },
  );
  testWidgets('invalid practice ID has recoverable error', (tester) async {
    await launch(tester);
    Get.toNamed('/practice/en-a');
    await tester.pumpAndSettle();
    expect(find.text('笔顺暂时无法打开，请返回认读或重试。'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
