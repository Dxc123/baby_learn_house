import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baby_learn_house/app/data/learning_content.dart';
import 'package:baby_learn_house/app/services/learning_store.dart';
import 'learning_store_test.dart' show MemoryPreferences;

Map<String, dynamic> original() =>
    jsonDecode(File('test/fixtures/phase1_content.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('declared order survives JSON entry reordering', () async {
    final json =
        jsonDecode(await File('assets/data/content.json').readAsString())
            as Map<String, dynamic>;
    json['items'] = (json['items'] as List).reversed.toList();
    final content = ContentRepository.fromJson(json);
    expect(content.filteredItems('alphabet').first.id, 'en-a');
    expect(
      content.filteredItems('pinyin', groupId: 'initials').first.text,
      'b',
    );
    expect(
      content.filteredItems('pinyin', groupId: 'syllables').first.text,
      'zhi',
    );
  });
  test(
    'resume falls back within selected group without losing valid cursor',
    () async {
      final content = await ContentRepository.load(rootBundle);
      expect(
        content
            .resumeItem('pinyin', groupId: 'syllables', cursor: 'pinyin-a')!
            .id,
        'pinyin-zhi',
      );
      expect(
        content
            .resumeItem(
              'pinyin',
              groupId: 'syllables',
              cursor: 'deleted',
              learned: {'pinyin-zhi'},
            )!
            .id,
        'pinyin-chi',
      );
      expect(
        content
            .resumeItem('pinyin', groupId: 'syllables', cursor: 'pinyin-shi')!
            .id,
        'pinyin-shi',
      );
      final all = content
          .filteredItems('pinyin', groupId: 'syllables')
          .map((e) => e.id)
          .toSet();
      expect(
        content.resumeItem('pinyin', groupId: 'syllables', learned: all)!.id,
        'pinyin-zhi',
      );
    },
  );
  test(
    'legacy fixture and upgraded catalog preserve saved stable IDs',
    () async {
      final old = ContentRepository.fromJson(original());
      expect(old.items.length, 16);
      final prefs = MemoryPreferences();
      final store = await LearningStore.open(prefs);
      await store.setLearned('hanzi-yi', true);
      await store.setLearned('pinyin-a', true);
      await store.setCursor('animals', 'animal-cat');
      final upgraded = await ContentRepository.load(rootBundle);
      expect(upgraded.items.length, 261);
      expect(
        upgraded.items.map((e) => e.id),
        containsAll(old.items.map((e) => e.id)),
      );
      expect(
        (await LearningStore.open(prefs)).learned,
        containsAll(['hanzi-yi', 'pinyin-a']),
      );
      expect(
        (await LearningStore.open(prefs)).cursors['animals'],
        'animal-cat',
      );
    },
  );
  test(
    'unknown groups, duplicate IDs, unsafe paths and invalid annotation reject content',
    () {
      final group = original();
      (group['items'] as List).first['groupId'] = 'missing';
      expect(() => ContentRepository.fromJson(group), throwsFormatException);
      final duplicate = original();
      (duplicate['items'] as List).add((duplicate['items'] as List).first);
      expect(
        () => ContentRepository.fromJson(duplicate),
        throwsFormatException,
      );
      final unsafe = original();
      (unsafe['items'] as List).first['audio'] = 'audio/../private.wav';
      expect(() => ContentRepository.fromJson(unsafe), throwsFormatException);
      final pinyin = original();
      (pinyin['items'] as List)[6]['pinyin'] = [];
      expect(() => ContentRepository.fromJson(pinyin), throwsFormatException);
    },
  );
  test(
    'unavailable audio remains readable and quality cannot contradict asset',
    () {
      final data = original();
      final item = (data['items'] as List).first;
      item['audio'] = null;
      item['audioQuality'] = 'unavailable';
      expect(
        ContentRepository.fromJson(data).items.first.audioQuality,
        AudioQuality.unavailable,
      );
      item['audioQuality'] = 'verified';
      expect(() => ContentRepository.fromJson(data), throwsFormatException);
    },
  );
  test(
    'pinyin groups have 23,24,16 complete units and normalized lookup',
    () async {
      final content = await ContentRepository.load(rootBundle);
      expect(content.groupsFor('pinyin').map((e) => e.id), [
        'initials',
        'finals',
        'syllables',
      ]);
      expect(content.filteredItems('pinyin', groupId: 'initials').length, 23);
      expect(content.filteredItems('pinyin', groupId: 'finals').length, 24);
      expect(content.filteredItems('pinyin', groupId: 'syllables').length, 16);
      expect(content.filteredItems('pinyin', query: 'zhi').map((e) => e.text), [
        'zhi',
      ]);
      expect(content.filteredItems('pinyin', query: 'ang').map((e) => e.text), [
        'ɑng',
      ]);
      expect(
        content.filteredItems('pinyin', query: 'u:').map((e) => e.text),
        contains('ü'),
      );
      expect(
        content.filteredItems('pinyin', query: 'ǚ').map((e) => e.text),
        contains('ü'),
      );
      expect(
        content.filteredItems('pinyin', groupId: 'finals', query: 'zhi'),
        isEmpty,
      );
      expect(content.filteredItems('pinyin', groupId: 'bogus').length, 63);
    },
  );
  test(
    'alphabet and cognition batches have deterministic counts and annotations',
    () async {
      final content = await ContentRepository.load(rootBundle);
      expect(content.itemsFor('alphabet').length, 26);
      expect(content.itemsFor('alphabet').first.text, 'Aa');
      expect(content.itemsFor('alphabet').last.id, 'en-z');
      expect(content.filteredItems('alphabet', query: 'a').single.id, 'en-a');
      expect(content.categories.where((e) => e.available).length, 28);
      for (final category in content.categories.where(
        (e) => e.kind == ContentKind.cognition && e.available,
      )) {
        expect(content.itemsFor(category.id).length, 6);
        for (final item in content.itemsFor(category.id)) {
          expect(item.pinyin.length, item.text.runes.length);
        }
      }
    },
  );
}
