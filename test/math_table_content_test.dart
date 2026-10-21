import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:baby_learn_house/app/data/learning_content.dart';
import 'package:baby_learn_house/app/modules/math/math_state.dart';

void main() {
  test('3B five table activities preserve252 IDs and protect3A model', () {
    final data =
        jsonDecode(File('assets/data/content.json').readAsStringSync())
            as Map<String, dynamic>;
    final repo = ContentRepository.fromJson(data);
    expect(repo.items.length, 261);
    expect(repo.categories.where((c) => c.available).length, 28);
    expect(
      repo.items
          .map((i) => i.id)
          .toSet()
          .containsAll(
            (jsonDecode(
                      File('test/fixtures/phase3a_ids.json').readAsStringSync(),
                    )
                    as List)
                .cast<String>(),
          ),
      isTrue,
    );
    final kinds = {
      'hundred': ActivityKind.hundred,
      'plus': ActivityKind.additionTable,
      'minus': ActivityKind.subtractionTable,
      'times': ActivityKind.multiplicationTable,
      'divide': ActivityKind.divisionTable,
    };
    for (final e in kinds.entries) {
      expect(repo.category(e.key).activityKind, e.value);
      expect(repo.itemsFor(e.key), isEmpty);
      expect(() => ArithmeticState(kind: e.value), throwsArgumentError);
    }
    final bad = jsonDecode(jsonEncode(data)) as Map<String, dynamic>;
    (bad['categories'] as List).firstWhere(
      (c) => c['id'] == 'hundred',
    )['activityKind'] = 'divisionTable';
    expect(() => ContentRepository.fromJson(bad), throwsFormatException);
  });
}
