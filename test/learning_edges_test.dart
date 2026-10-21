import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:baby_learn_house/app/data/learning_content.dart';
import 'package:baby_learn_house/app/services/learning_audio.dart';
import 'learning_audio_test.dart' show TestAudioBackend;
import 'widget_test.dart' show launch;
import 'learning_store_test.dart' show MemoryPreferences;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    Get.testMode = true;
  });
  tearDown(() {
    Get.reset();
  });

  test(
    'order changes use strokes or normalized pinyin without changing IDs',
    () async {
      final content = ContentRepository.fromJson(
        jsonDecode(
              await File('test/fixtures/phase1_content.json').readAsString(),
            )
            as Map<String, dynamic>,
      );
      expect(content.sortedItems('chinese', 'grade').map((e) => e.text), [
        '一',
        '二',
        '三',
        '人',
        '口',
        '山',
      ]);
      expect(content.sortedItems('chinese', 'strokes').map((e) => e.text), [
        '一',
        '二',
        '人',
        '口',
        '三',
        '山',
      ]);
      expect(content.sortedItems('chinese', 'pinyin').map((e) => e.text), [
        '二',
        '口',
        '人',
        '三',
        '山',
        '一',
      ]);
      expect(content.itemsFor('chinese').first.id, 'hanzi-yi');
    },
  );
  test('moving app to background stops current playback', () async {
    final audio = LearningAudio(TestAudioBackend());
    await audio.play('audio/a.wav');
    audio.didChangeAppLifecycleState(AppLifecycleState.paused);
    expect(audio.playingId.value, isNull);
    await audio.shutdown();
  });
  testWidgets(
    'large text learning detail remains scrollable on a narrow phone',
    (tester) async {
      await launch(tester, width: 320, scale: 2);
      Get.toNamed('/learn/chinese');
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('item-hanzi-yi')).hitTestable(),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const ValueKey('item-hanzi-yi')));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('mark-learned')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        find.byKey(const ValueKey('mark-learned')).hitTestable(),
        findsOneWidget,
      );
    },
  );
  testWidgets('last sample returns to list and learned marker can be undone', (
    tester,
  ) async {
    final store = await launch(tester);
    Get.toNamed('/learn/chinese');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('group-starter')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('item-hanzi-shan')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('item-hanzi-shan')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('mark-learned')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('mark-learned')));
    await tester.pumpAndSettle();
    expect(store.learned, contains('hanzi-shan'));
    await tester.tap(find.byKey(const ValueKey('mark-learned')));
    await tester.pumpAndSettle();
    expect(store.learned, isNot(contains('hanzi-shan')));
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('next-item')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('next-item')));
    await tester.pumpAndSettle();
    expect(Get.currentRoute, '/learn/chinese');
    expect(find.byKey(const ValueKey('item-hanzi-shan')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'cursor write failure warns but still opens and advances offline lessons',
    (tester) async {
      final preferences = MemoryPreferences();
      final store = await launch(tester, preferences: preferences);
      Get.toNamed('/learn/chinese');
      await tester.pumpAndSettle();
      preferences.failNext = true;
      await tester.tap(find.byKey(const ValueKey('item-hanzi-yi')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('play-audio')), findsOneWidget);
      expect(store.cursors['chinese'], isNull);
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      preferences.failNext = true;
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('next-item')),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const ValueKey('next-item')));
      await tester.pumpAndSettle();
      expect(Get.currentRoute, '/learn/chinese/hanzi-er');
      expect(store.cursors['chinese'], isNull);
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    },
  );
}
