import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'widget_test.dart' show launch;
import 'dart:io';
import 'dart:convert';
import 'package:baby_learn_house/app/data/learning_content.dart';
import 'package:baby_learn_house/app/data/story_repository.dart';
import 'package:baby_learn_house/app/modules/story/dialogue_body.dart';
import 'story_repository_test.dart' show StoryBundle;
import 'math_activity_ui_test.dart' show press;

void main() {
  setUp(() => Get.testMode = true);
  tearDown(() => Get.reset());
  testWidgets('unknown illustration keeps book text and navigation', (t) async {
    await launch(t);
    final body = jsonDecode(
      File('assets/data/stories.json').readAsStringSync(),
    );
    body['stories'][0]['pages'][0]['sceneId'] = 'unknown';
    Get.replace(
      StoryRepository(
        StoryBundle()..value = jsonEncode(body),
        Get.find<ContentRepository>(),
      ),
    );
    Get.toNamed('/story/book-share-toys');
    await t.pumpAndSettle();
    expect(find.text('这页插图暂时无法显示'), findsOneWidget);
    expect(find.text('1 / 6'), findsOneWidget);
    await press(t, 'story-next');
    expect(find.text('2 / 6'), findsOneWidget);
  });
  testWidgets('story failure retries and legacy story link opens', (t) async {
    await launch(t);
    final bundle = StoryBundle();
    Get.replace(StoryRepository(bundle, Get.find<ContentRepository>()));
    Get.toNamed('/learn/books/book-share-toys');
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('story-retry')), findsOneWidget);
    bundle.value = File('assets/data/stories.json').readAsStringSync();
    await press(t, 'story-retry');
    expect(find.text('1 / 6'), findsOneWidget);
  });
  testWidgets('dialogue queued choices target latest and exit is safe', (
    t,
  ) async {
    await launch(t);
    Get.toNamed('/story/dialog-help');
    await t.pump();
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await t.pumpAndSettle();
    final c = t.widget<DialogueBody>(find.byType(DialogueBody)).controller;
    final last = c.selectUnit(c.document.units.last.id);
    final first = c.selectUnit(c.document.units.first.id);
    await t.pumpAndSettle();
    await Future.wait([last, first]);
    expect(
      find.byKey(ValueKey('unit-${c.document.units.first.id}')).hitTestable(),
      findsOneWidget,
    );
    final pending = c.selectUnit(c.document.units.last.id);
    await t.pumpWidget(const SizedBox());
    await pending;
    await t.pump();
    expect(t.takeException(), isNull);
  });
  testWidgets('book6 pages stay aligned and manual learned only', (t) async {
    final store = await launch(t);
    Get.toNamed('/story/book-share-toys');
    await t.pump();
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await t.pumpAndSettle();
    for (var i = 1; i < 6; i++) {
      await press(t, 'story-next');
    }
    expect(find.text('6 / 6'), findsOneWidget);
    expect(find.text('这本读完啦'), findsOneWidget);
    expect(store.learned, isEmpty);
    await press(t, 'story-learned');
    expect(store.learned, {'book-share-toys'});
    await press(t, 'story-learned');
    expect(store.learned, isEmpty);
  });
  testWidgets('dialogue last turn deep link and large type', (t) async {
    final store = await launch(t, width: 320, scale: 2);
    Get.toNamed('/story/dialog-help?unit=dialog-help-turn-06');
    await t.pump();
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await t.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('unit-dialog-help-turn-06')).hitTestable(),
      findsOneWidget,
    );
    expect(t.takeException(), isNull);
    expect(store.cursors['story:dialog-help'], 'dialog-help-turn-06');
    await store.setShowPinyin(false);
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
  });
}
