import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:baby_learn_house/app/data/learning_content.dart';

Map<String, dynamic> catalog() =>
    jsonDecode(File('assets/data/content.json').readAsStringSync())
        as Map<String, dynamic>;
void main() {
  test('3A corpus preserves old IDs and adds eleven numbers', () {
    final repo = ContentRepository.fromJson(catalog());
    expect(repo.items.length, 261);
    expect(repo.categories.where((c) => c.available).length, 28);
    final old =
        (jsonDecode(File('test/fixtures/phase2c_ids.json').readAsStringSync())
                as List)
            .cast<String>();
    expect(repo.items.map((i) => i.id).toSet().containsAll(old), isTrue);
    for (final order in ['grade', 'strokes', 'pinyin']) {
      expect(
        repo.sortedItems('numbers', order).map((i) => i.numberValue),
        List.generate(11, (i) => i),
      );
    }
    for (final query in ['10', '十', 'shi']) {
      expect(
        repo.filteredItems('numbers', query: query).map((i) => i.id),
        contains('number-10'),
      );
    }
  });
  test('rejects ambiguous activities and invalid numbers', () {
    for (final mutate in <void Function(Map<String, dynamic>)>[
      (d) => (d['items'] as List).firstWhere(
        (i) => i['id'] == 'number-1',
      )['pinyin'] = [],
      (d) => (d['items'] as List).firstWhere(
        (i) => i['id'] == 'number-1',
      )['pinyin'] = [' '],
      (d) => (d['categories'] as List).firstWhere(
        (c) => c['id'] == 'count',
      )['kind'] = 'number',
      (d) => (d['categories'] as List).firstWhere(
        (c) => c['id'] == 'count',
      )['activityKind'] = 'other',
      (d) => (d['items'] as List).firstWhere(
        (i) => i['id'] == 'number-1',
      )['numberValue'] = true,
      (d) => (d['items'] as List).firstWhere(
        (i) => i['id'] == 'number-1',
      )['numberValue'] = 0,
      (d) => (d['items'] as List).firstWhere(
        (i) => i['id'] == 'number-1',
      )['categoryId'] = 'count',
    ]) {
      final d = catalog();
      mutate(d);
      expect(() => ContentRepository.fromJson(d), throwsFormatException);
    }
  });
}
