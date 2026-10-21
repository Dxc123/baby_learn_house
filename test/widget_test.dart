import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:baby_learn_house/main.dart';
import 'package:baby_learn_house/app/data/learning_content.dart';
import 'package:baby_learn_house/app/services/learning_audio.dart';
import 'package:baby_learn_house/app/services/learning_store.dart';
import 'learning_store_test.dart' show MemoryPreferences;
import 'learning_audio_test.dart' show TestAudioBackend;

Future<LearningStore> launch(
  WidgetTester tester, {
  double width = 390,
  double scale = 1,
  MemoryPreferences? preferences,
}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final backing = preferences ?? MemoryPreferences();
  final store = await LearningStore.open(backing);
  final content = (await tester.runAsync(
    () => ContentRepository.load(rootBundle),
  ))!;
  await tester.pumpWidget(
    BabyLearnApp(
      store: store,
      content: content,
      audio: LearningAudio(TestAudioBackend()),
      drawingPreferences: backing,
    ),
  );
  await tester.pumpAndSettle();
  return store;
}

void main() {
  setUp(() {
    Get.testMode = true;
  });
  tearDown(() {
    Get.reset();
  });
  testWidgets('four tabs expose categories and drawing destination opens', (
    tester,
  ) async {
    await launch(tester);
    expect(find.bySemanticsLabel('宝宝学识屋'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('tab-2')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('category-numbers')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('tab-3')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('category-drawing')));
    await tester.tap(find.byKey(const ValueKey('category-drawing')));
    await tester.pumpAndSettle();
    expect(find.text('小小画板'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('tab-3')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('category-books')), findsOneWidget);
  });
  testWidgets('settings change global pinyin visibility and theme', (
    tester,
  ) async {
    final store = await launch(tester);
    await tester.tap(find.byTooltip('设置'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('pinyin-switch')));
    await tester.pumpAndSettle();
    expect(store.showPinyin.value, false);
    await tester.tap(find.byKey(const ValueKey('theme-1')));
    await tester.pumpAndSettle();
    expect(store.themeIndex.value, 1);
    await tester.tap(find.byTooltip('返回'));
    await tester.pumpAndSettle();
    expect(find.text('xué'), findsNothing);
  });
  testWidgets(
    'small screen at large text and tablet have no layout exceptions',
    (tester) async {
      await launch(tester, width: 320, scale: 2);
      expect(tester.takeException(), isNull);
      for (var tab = 1; tab < 4; tab++) {
        await tester.tap(find.byKey(ValueKey('tab-$tab')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      tester.view.physicalSize = const Size(1024, 1200);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'learned state follows next item, filters and navigation stops audio',
    (tester) async {
      final store = await launch(tester);
      await tester.tap(find.byKey(const ValueKey('category-chinese')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('item-hanzi-yi')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('play-audio')));
      await tester.pumpAndSettle();
      expect(Get.find<LearningAudio>().playingId.value, 'audio/hanzi-yi.wav');
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('mark-learned')),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const ValueKey('mark-learned')));
      await tester.pumpAndSettle();
      expect(store.learned, contains('hanzi-yi'));
      await tester.tap(find.byKey(const ValueKey('next-item')));
      await tester.pumpAndSettle();
      expect(store.cursors['chinese'], 'hanzi-er');
      expect(Get.find<LearningAudio>().playingId.value, isNull);
      await tester.tap(find.byTooltip('返回'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('filter-learned')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('item-hanzi-yi')), findsOneWidget);
      expect(find.byKey(const ValueKey('item-hanzi-er')), findsNothing);
      await tester.enterText(find.byType(TextField), '不存在');
      await tester.pumpAndSettle();
      expect(find.text('还没有匹配的内容'), findsOneWidget);
    },
  );
}
