import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baby_learn_house/app/modules/story/story_scene.dart';
import 'package:baby_learn_house/app/modules/story/story_scene_registry.dart';

void main() {
  testWidgets('18 implemented scenes have alt semantics and unknown fallback', (
    t,
  ) async {
    final body = jsonDecode(
      File('assets/data/stories.json').readAsStringSync(),
    );
    expect(
      supportedStoryScenes,
      (body['scenes'] as List).map((s) => s['id']).toSet(),
    );
    for (final s in body['scenes']) {
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StoryScene(sceneId: s['id'], alt: s['alt']),
          ),
        ),
      );
      expect(t.takeException(), isNull);
    }
    await t.pumpWidget(
      const MaterialApp(
        home: StoryScene(sceneId: 'bad', alt: '未知'),
      ),
    );
    expect(find.text('这页插图暂时无法显示'), findsOneWidget);
  });
}
