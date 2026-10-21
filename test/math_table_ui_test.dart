import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:baby_learn_house/app/services/learning_audio.dart';
import 'widget_test.dart' show launch;
import 'math_activity_ui_test.dart' show press;

void main() {
  setUp(() => Get.testMode = true);
  tearDown(() => Get.reset());
  testWidgets('invalid subtraction cell has no accessibility activation', (
    t,
  ) async {
    final semantics = t.ensureSemantics();
    await launch(t);
    Get.toNamed('/math/minus');
    await t.pumpAndSettle();
    await t.ensureVisible(find.byKey(const ValueKey('cell-subtraction-1-9')));
    expect(
      t
          .getSemantics(find.byKey(const ValueKey('cell-subtraction-1-9')))
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isFalse,
    );
    expect(find.text('1 − 0 = 1'), findsOneWidget);
    semantics.dispose();
  });
  testWidgets(
    'all table routes work old routes redirect and progress unchanged',
    (t) async {
      final store = await launch(t);
      for (final id in ['hundred', 'plus', 'minus', 'times', 'divide']) {
        Get.toNamed('/learn/$id');
        await t.pumpAndSettle();
        expect(Get.currentRoute, '/math/$id');
        if (id != 'hundred') {
          expect(
            find.byKey(const ValueKey('table-equation')).hitTestable(),
            findsOneWidget,
          );
        }
        expect(t.takeException(), isNull);
        await t.tap(find.byTooltip('返回'));
        await t.pumpAndSettle();
      }
      expect(store.cursors, isEmpty);
      expect(store.learned, isEmpty);
    },
  );
  testWidgets('arithmetic last cells and same dividend identities', (t) async {
    await launch(t);
    for (final entry in {
      'plus': '9 + 9 = 18',
      'minus': '9 − 9 = 0',
      'times': '9 × 9 = 81',
      'divide': '81 ÷ 9 = 9',
    }.entries) {
      Get.toNamed('/math/${entry.key}');
      await t.pumpAndSettle();
      final id = {
        'plus': 'addition',
        'minus': 'subtraction',
        'times': 'multiplication',
        'divide': 'division',
      }[entry.key];
      await press(t, 'cell-$id-9-9');
      expect(find.text(entry.value), findsOneWidget);
      expect(t.takeException(), isNull);
      if (entry.key == 'divide') {
        await press(t, 'cell-division-2-6');
        expect(find.text('12 ÷ 2 = 6'), findsOneWidget);
        await press(t, 'cell-division-3-4');
        expect(find.text('12 ÷ 3 = 4'), findsOneWidget);
      }
      await t.tap(find.byTooltip('返回'));
      await t.pumpAndSettle();
    }
  });
  testWidgets(
    'large text tablet theme rebuild reentry and audio cancellation',
    (t) async {
      final store = await launch(t, width: 320, scale: 2);
      final audio = Get.find<LearningAudio>();
      await audio.playSequence([const AudioCue('old', 'audio/old.wav')]);
      Get.toNamed('/math/divide');
      await t.pumpAndSettle();
      expect(audio.sequencePlaying.value, isFalse);
      await press(t, 'table-row-plus');
      await store.setTheme(1);
      await t.pumpAndSettle();
      expect(find.text('2 ÷ 2 = 1'), findsOneWidget);
      expect(t.takeException(), isNull);
      await t.tap(find.byTooltip('返回'));
      await t.pumpAndSettle();
      Get.toNamed('/math/divide');
      await t.pumpAndSettle();
      expect(find.text('1 ÷ 1 = 1'), findsOneWidget);
      t.view.physicalSize = const Size(1024, 844);
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    },
  );
}
