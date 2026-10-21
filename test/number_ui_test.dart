import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'widget_test.dart' show launch;
import 'learning_store_test.dart' show MemoryPreferences;
import 'package:baby_learn_house/app/services/learning_store.dart';
import 'package:baby_learn_house/app/data/learning_content.dart';
import 'package:baby_learn_house/app/services/learning_audio.dart';
import 'math_activity_ui_test.dart' show press;

class DelayedPreferences extends MemoryPreferences {
  Completer<void>? gate;
  @override
  Future<void> write(String key, String value) async {
    await gate?.future;
    await super.write(key, value);
  }
}

void main() {
  setUp(() => Get.testMode = true);
  tearDown(() => Get.reset());
  testWidgets(
    'activity legacy paths and invalid number links fall back safely',
    (t) async {
      final store = await launch(t);
      for (final id in ['plus-block', 'minus-block']) {
        Get.toNamed('/learn/$id');
        await t.pumpAndSettle();
        expect(Get.currentRoute, '/math/$id');
        await t.tap(find.byTooltip('返回'));
        await t.pumpAndSettle();
      }
      Get.toNamed('/learn/numbers/no-such-number');
      await t.pumpAndSettle();
      expect(Get.currentRoute, '/learn/numbers');
      expect(t.takeException(), isNull);
      expect(
        Get.find<ContentRepository>().resumeItem('numbers', cursor: 'gone')!.id,
        'number-0',
      );
      expect(store.learned, isEmpty);
    },
  );
  testWidgets('late cursor save cannot replace another current route', (
    t,
  ) async {
    final prefs = DelayedPreferences();
    await launch(t, preferences: prefs);
    Get.toNamed('/learn/numbers/number-0');
    await t.pumpAndSettle();
    prefs.gate = Completer<void>();
    await press(t, 'number-next');
    Get.toNamed('/settings');
    await t.pumpAndSettle();
    prefs.gate!.complete();
    await t.pumpAndSettle();
    expect(Get.currentRoute, '/settings');
  });
  testWidgets('failed cursor save does not navigate to next number', (t) async {
    final prefs = MemoryPreferences();
    final store = await launch(t, preferences: prefs);
    Get.toNamed('/learn/numbers/number-0');
    await t.pumpAndSettle();
    prefs.failNext = true;
    await press(t, 'number-next');
    expect(Get.currentRoute, '/learn/numbers/number-0');
    expect(store.cursors['numbers'], isNull);
    await t.pump(const Duration(seconds: 4));
    await t.pumpAndSettle();
  });
  testWidgets('failed number save stays unmarked and retry works', (t) async {
    final prefs = MemoryPreferences();
    final store = await launch(t, preferences: prefs);
    Get.toNamed('/learn/numbers/number-0');
    await t.pumpAndSettle();
    prefs.failNext = true;
    await press(t, 'number-learned');
    expect(store.learned, isEmpty);
    await t.pump(const Duration(seconds: 4));
    await t.pumpAndSettle();
    await press(t, 'number-learned');
    expect(store.learned, contains('number-0'));
    await press(t, 'number-learned');
    expect(store.learned, isEmpty);
  });
  testWidgets('math route cancels existing audio and reentry resets state', (
    t,
  ) async {
    final store = await launch(t);
    final audio = Get.find<LearningAudio>();
    await audio.playSequence([
      const AudioCue('old', 'audio/old.wav'),
      const AudioCue('next', 'audio/next.wav'),
    ]);
    Get.toNamed('/math/count');
    await t.pumpAndSettle();
    expect(audio.sequencePlaying.value, isFalse);
    await press(t, 'object-0');
    await t.tap(find.byTooltip('返回'));
    await t.pumpAndSettle();
    Get.toNamed('/math/count');
    await t.pumpAndSettle();
    expect(find.text('已经数了 0 个'), findsOneWidget);
    expect(store.cursors, isEmpty);
  });
  testWidgets('number zero mark and restart preserve previous progress', (
    t,
  ) async {
    final prefs = MemoryPreferences();
    final store = await launch(t, preferences: prefs);
    await store.setLearned('pinyin-a', true);
    await store.setCursor('reader:poetry-jingyesi', 'poetry-jingyesi-line-02');
    Get.toNamed('/learn/numbers/number-0');
    await t.pumpAndSettle();
    expect(find.text('一个也没有'), findsOneWidget);
    await press(t, 'number-learned');
    expect(store.learned, containsAll(['pinyin-a', 'number-0']));
    await press(t, 'number-next');
    expect(store.cursors['numbers'], 'number-1');
    final reopened = await LearningStore.open(prefs);
    expect(reopened.learned, containsAll(['pinyin-a', 'number-0']));
    expect(
      reopened.cursors['reader:poetry-jingyesi'],
      'poetry-jingyesi-line-02',
    );
  });
  testWidgets('number ten and pinyin fit large text', (t) async {
    final store = await launch(t, width: 320, scale: 2);
    Get.toNamed('/learn/numbers/number-10');
    await t.pumpAndSettle();
    expect(find.text('10'), findsWidgets);
    expect(find.text('shí'), findsOneWidget);
    expect(t.takeException(), isNull);
    await store.setShowPinyin(false);
    await t.pumpAndSettle();
    expect(find.text('shí'), findsNothing);
  });
  testWidgets('old activity path redirects and bad path returns home', (
    t,
  ) async {
    await launch(t);
    Get.toNamed('/learn/count');
    await t.pumpAndSettle();
    expect(find.text('已经数了 0 个'), findsOneWidget);
    Get.toNamed('/math/numbers');
    await t.pumpAndSettle();
    expect(find.bySemanticsLabel('宝宝学识屋'), findsOneWidget);
  });
}
