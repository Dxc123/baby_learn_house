import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:baby_learn_house/app/data/learning_content.dart';
import 'package:baby_learn_house/app/modules/learning/cognition_visual.dart';
import 'package:baby_learn_house/app/services/learning_audio.dart';
import 'widget_test.dart' show launch;

Future<void> reveal(WidgetTester tester, String key) async {
  await tester.scrollUntilVisible(
    find.byKey(ValueKey(key)).hitTestable(),
    230,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    Get.testMode = true;
  });
  tearDown(() {
    Get.reset();
  });
  testWidgets(
    'whole syllable stays intact with pinyin off and group next stays inside group',
    (tester) async {
      final store = await launch(tester, width: 320, scale: 2);
      await store.setShowPinyin(false);
      Get.toNamed('/learn/pinyin');
      await tester.pumpAndSettle();
      await reveal(tester, 'group-syllables');
      await tester.tap(find.byKey(const ValueKey('group-syllables')));
      await tester.pumpAndSettle();
      await reveal(tester, 'item-pinyin-zhi');
      expect(find.byKey(const ValueKey('unit-pinyin-zhi')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('item-pinyin-zhi')));
      await tester.pumpAndSettle();
      expect(find.text('暂缺录音'), findsOneWidget);
      expect(find.byKey(const ValueKey('unit-pinyin-zhi')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await reveal(tester, 'next-item');
      await tester.tap(find.byKey(const ValueKey('next-item')));
      await tester.pumpAndSettle();
      expect(Get.parameters['itemId'], 'pinyin-chi');
      expect(Get.parameters['group'], 'syllables');
      expect(Get.find<LearningAudio>().playingId.value, isNull);
    },
  );
  testWidgets(
    'unavailable clip stops previous sound and last syllable returns to list',
    (tester) async {
      await launch(tester);
      Get.toNamed('/learn/pinyin');
      await tester.pumpAndSettle();
      final audio = Get.find<LearningAudio>();
      await audio.play('audio/pinyin-a.wav');
      Get.toNamed('/learn/pinyin/pinyin-ying?group=syllables');
      await tester.pumpAndSettle();
      expect(audio.playingId.value, isNull);
      expect(find.byKey(const ValueKey('play-audio')), findsNothing);
      await reveal(tester, 'next-item');
      await tester.tap(find.byKey(const ValueKey('next-item')));
      await tester.pumpAndSettle();
      expect(Get.currentRoute, '/learn/pinyin');
    },
  );
  testWidgets(
    'English Z learns and returns without changing its display on pinyin toggle',
    (tester) async {
      final store = await launch(tester);
      Get.toNamed('/learn/alphabet');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Z');
      await tester.pumpAndSettle();
      await reveal(tester, 'item-en-z');
      await tester.tap(find.byKey(const ValueKey('item-en-z')));
      await tester.pumpAndSettle();
      await store.setShowPinyin(false);
      await tester.pumpAndSettle();
      expect(find.text('Zz'), findsOneWidget);
      await reveal(tester, 'mark-learned');
      await tester.tap(find.byKey(const ValueKey('mark-learned')));
      await tester.pumpAndSettle();
      expect(store.learned, contains('en-z'));
      await reveal(tester, 'next-item');
      await tester.tap(find.byKey(const ValueKey('next-item')));
      await tester.pumpAndSettle();
      expect(Get.currentRoute, '/learn/alphabet');
    },
  );
  testWidgets('white color and native shapes expose understandable semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await launch(tester);
      Get.toNamed('/learn/colors/colors-white');
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('白色示意图'), findsOneWidget);
      expect(tester.takeException(), isNull);
      Get.offNamed('/learn/shapes/shapes-circle');
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('圆形示意图'), findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });
  testWidgets('missing illustration uses explicit readable fallback', (
    tester,
  ) async {
    final item = LearningItem.fromJson({
      'id': 'test-image',
      'categoryId': 'animals',
      'text': '猫',
      'pinyin': ['māo'],
      'symbol': '🐱',
      'audio': null,
      'audioQuality': 'unavailable',
      'note': '测试',
      'example': '猫',
      'imageAsset': 'images/missing.png',
    }, kind: ContentKind.cognition);
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: CognitionVisual(item))),
    );
    await tester.pumpAndSettle();
    expect(find.text('插图暂时无法显示'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
