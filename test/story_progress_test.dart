import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:baby_learn_house/app/data/story_types.dart';
import 'package:baby_learn_house/app/services/learning_store.dart';
import 'package:baby_learn_house/app/modules/story/story_controller.dart';
import 'learning_store_test.dart' show MemoryPreferences;

class StoryDelayedPreferences extends MemoryPreferences {
  Completer<void>? gate;
  bool failBlocked = false;
  @override
  Future<void> write(String key, String value) async {
    final pending = gate;
    gate = null;
    if (pending != null) {
      await pending.future;
      if (failBlocked) throw StateError('late failure');
    }
    await super.write(key, value);
  }
}

StoryDocument storyFixture() {
  final b = jsonDecode(File('assets/data/stories.json').readAsStringSync());
  return StoryDocument.fromJson(
    Map<String, dynamic>.from(b['stories'][0]),
    scenes: (b['scenes'] as List)
        .map((s) => Map<String, dynamic>.from(s))
        .toList(),
  );
}

void main() {
  test(
    'late position failure cannot override new selection or closed UI',
    () async {
      final prefs = StoryDelayedPreferences();
      final store = await LearningStore.open(prefs);
      final d = storyFixture();
      final c = StoryController(d, store, itemId: d.id);
      await c.open();
      final gate = Completer<void>();
      prefs.gate = gate;
      prefs.failBlocked = true;
      final a = c.selectUnit(d.units[1].id);
      await Future<void>.delayed(Duration.zero);
      final b = c.selectUnit(d.units[4].id);
      expect(c.currentUnit.id, d.units[4].id);
      gate.complete();
      await Future.wait([a, b]);
      expect(c.warning.value, isNull);
      expect(store.cursors['story:${d.id}'], d.units[4].id);
      final closeGate = Completer<void>();
      prefs.gate = closeGate;
      prefs.failBlocked = false;
      final pending = c.selectUnit(d.units.last.id);
      c.onClose();
      closeGate.complete();
      await pending;
      expect(c.warning.value, isNull);
    },
  );
  test('story stable position whole marking and storage failure', () async {
    final prefs = MemoryPreferences();
    final store = await LearningStore.open(prefs);
    final d = storyFixture();
    await store.setLearned('pinyin-a', true);
    await store.setCursor('story:${d.id}', d.units[3].id);
    final c = StoryController(d, store, itemId: d.id);
    await c.open();
    expect(c.currentUnit.id, d.units[3].id);
    await c.open(requestedUnitId: 'other-page-04');
    expect(c.currentUnit.id, d.units.first.id);
    expect(c.warning.value, isNotNull);
    prefs.failNext = true;
    await c.selectUnit(d.units.last.id);
    expect(c.currentUnit.id, d.units.last.id);
    expect(c.warning.value, isNotNull);
    expect(store.learned, {'pinyin-a'});
    await c.selectUnit(d.units.last.id);
    expect(store.cursors['story:${d.id}'], d.units.last.id);
    await c.markLearned();
    expect(store.learned, containsAll(['pinyin-a', d.id]));
    await c.markLearned();
    expect(store.learned, {'pinyin-a'});
    final reopened = await LearningStore.open(prefs);
    expect(reopened.cursors[d.categoryId], d.id);
    c.onClose();
  });
}
