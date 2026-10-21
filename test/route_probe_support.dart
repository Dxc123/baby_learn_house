import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:baby_learn_house/app/core/annotated_reading_text.dart';
import 'package:baby_learn_house/app/modules/handwriting/stroke_board.dart';
import 'package:baby_learn_house/app/modules/story/picture_book_body.dart';
import 'package:baby_learn_house/app/modules/story/dialogue_body.dart';
import 'package:baby_learn_house/app/modules/math/math_activity_view.dart';
import 'package:baby_learn_house/app/modules/math/hundred_view.dart';
import 'package:baby_learn_house/app/modules/math/math_table_view.dart';
import 'package:baby_learn_house/app/modules/math/number_detail_view.dart';
import 'package:baby_learn_house/app/modules/worksheet/worksheet_view.dart';

void resetRouteProbe() {
  // Cached Futures created in another test's FakeAsync zone cannot be driven
  // by this test. Production has one normal event loop, not successive zones.
  rootBundle.clear();
  Get.testMode = true;
}

Finder routeReady(String route) {
  final path = Uri.parse(route).path;
  if (path.startsWith('/read/')) return find.byType(AnnotatedReadingText);
  if (path == '/story/book-share-toys') return find.byType(PictureBookBody);
  if (path == '/story/dialog-greeting') return find.byType(DialogueBody);
  if (path.startsWith('/practice/')) return find.byType(StrokeBoard);
  // The long introduction can fill the entire viewport at 200% text. The
  // following SelectableText is lazily built only after scrolling, so it is not
  // a valid loading indicator. This intro exists only in the loaded branch.
  if (path == '/resource-licenses') return find.textContaining('固定提交 68d10a4b');
  if (path == '/drawing') return find.byKey(const ValueKey('drawing-canvas'));
  return switch (path) {
    '/learn/pinyin' => find.byKey(const ValueKey('list-pinyin')),
    '/learn/chinese' => find.byKey(const ValueKey('list-chinese')),
    '/learn/chinese/hanzi-yi' ||
    '/learn/animals/animal-cat' => find.byKey(const ValueKey('play-audio')),
    '/learn/numbers/number-0' => find.byType(NumberDetailView),
    '/math/count' || '/math/plus-block' => find.byType(MathActivityView),
    '/math/hundred' => find.byType(HundredView),
    '/math/plus' => find.byType(MathTableView),
    '/worksheet' => find.byType(WorksheetView),
    '/settings' => find.byKey(const ValueKey('pinyin-switch')),
    _ => throw ArgumentError('Missing readiness contract for $route'),
  };
}

Future<void> pumpProbeCondition(
  WidgetTester tester,
  bool Function() ready, {
  required String reason,
}) async {
  // Build the route first, so initState can actually start I/O/isolate decoding.
  await tester.pump();
  final elapsed = Stopwatch()..start();
  while (!ready()) {
    if (elapsed.elapsed > const Duration(seconds: 3)) {
      fail(
        '$reason: content never became ready; '
        'loading=${find.byType(CircularProgressIndicator).evaluate().length}, '
        'licenseIntro=${find.textContaining('固定提交 68d10a4b').evaluate().length}',
      );
    }
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump(const Duration(milliseconds: 16));
    expect(tester.takeException(), isNull, reason: reason);
  }
}

Future<void> pumpProbeReady(
  WidgetTester tester,
  Finder ready, {
  required String reason,
}) async {
  await pumpProbeCondition(
    tester,
    () => ready.evaluate().isNotEmpty,
    reason: reason,
  );
  await tester.pumpAndSettle(
    const Duration(milliseconds: 16),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 2),
  );
  expect(tester.takeException(), isNull, reason: reason);
  expect(ready, findsWidgets, reason: reason);
  expect(find.byType(CircularProgressIndicator), findsNothing, reason: reason);
}
