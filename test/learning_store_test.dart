import 'package:flutter_test/flutter_test.dart';
import 'package:baby_learn_house/app/services/learning_store.dart';

class MemoryPreferences implements PreferenceStore {
  final values = <String, String>{};
  bool failNext = false;
  bool failRead = false;
  @override
  Future<String?> read(String key) async {
    if (failRead) throw StateError('storage unavailable');
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    if (failNext) {
      failNext = false;
      throw StateError('disk unavailable');
    }
    values[key] = value;
  }

  @override
  Future<void> remove(String key) async => values.remove(key);
}

void main() {
  test(
    'storage read failure opens with usable defaults and a visible warning',
    () async {
      final prefs = MemoryPreferences()..failRead = true;
      final store = await LearningStore.open(prefs);
      expect(store.learned, isEmpty);
      expect(store.showPinyin.value, true);
      expect(store.loadWarning, isNotNull);
    },
  );
  test('reopening restores learned IDs, cursor, and settings', () async {
    final prefs = MemoryPreferences();
    final store = await LearningStore.open(prefs);
    await store.setLearned('hanzi-yi', true);
    await store.setCursor('chinese', 'hanzi-er');
    await store.setShowPinyin(false);
    await store.setTheme(1);
    await store.setOrder('strokes');
    final restored = await LearningStore.open(prefs);
    expect(restored.learned, contains('hanzi-yi'));
    expect(restored.cursors['chinese'], 'hanzi-er');
    expect(restored.showPinyin.value, false);
    expect(restored.themeIndex.value, 1);
    expect(restored.order.value, 'strokes');
  });

  test(
    'failed write does not report success or poison subsequent writes',
    () async {
      final prefs = MemoryPreferences();
      final store = await LearningStore.open(prefs);
      prefs.failNext = true;
      await expectLater(store.setLearned('hanzi-yi', true), throwsStateError);
      expect(store.learned, isNot(contains('hanzi-yi')));
      await store.setLearned('hanzi-er', true);
      expect((await LearningStore.open(prefs)).learned, ['hanzi-er']);
    },
  );

  test(
    'concurrent updates preserve both entries and clearing cache keeps progress',
    () async {
      final prefs = MemoryPreferences();
      final store = await LearningStore.open(prefs);
      await Future.wait([
        store.setLearned('hanzi-yi', true),
        store.setLearned('hanzi-er', true),
        store.setTheme(2),
      ]);
      prefs.values['download_cache'] = 'temporary';
      await store.clearCache();
      final restored = await LearningStore.open(prefs);
      expect(restored.learned, containsAll(['hanzi-yi', 'hanzi-er']));
      expect(restored.themeIndex.value, 2);
      expect(prefs.values, isNot(contains('download_cache')));
    },
  );

  test('corrupt persisted data gives a recoverable warning', () async {
    final prefs = MemoryPreferences()..values['learning_state_v1'] = '{broken';
    final store = await LearningStore.open(prefs);
    expect(store.learned, isEmpty);
    expect(store.loadWarning, isNotNull);
    await store.setLearned('hanzi-yi', true);
    expect((await LearningStore.open(prefs)).learned, ['hanzi-yi']);
  });
}
