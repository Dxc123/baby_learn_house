import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baby_learn_house/app/data/learning_content.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('legacy JSON defaults and malformed word annotations', () async {
    final legacy =
        jsonDecode(
              await File('test/fixtures/phase1_content.json').readAsString(),
            )
            as Map<String, dynamic>;
    final content = ContentRepository.fromJson(legacy);
    expect(content.itemsFor('chinese').first.words, isEmpty);
    expect(content.itemsFor('chinese').first.strokeAsset, isNull);
    (legacy['items'] as List).first['words'] = [
      {
        'text': '你好',
        'pinyin': ['nǐ'],
      },
    ];
    expect(() => ContentRepository.fromJson(legacy), throwsFormatException);
  });
  test(
    '60 characters in ten courses preserve original IDs and polyphones',
    () async {
      final content = await ContentRepository.load(rootBundle);
      final items = content.itemsFor('chinese');
      expect(items.length, 60);
      expect(content.items.length, 261);
      expect(content.groupsFor('chinese').length, 10);
      for (final group in content.groupsFor('chinese')) {
        expect(items.where((i) => i.groupId == group.id).length, 6);
      }
      expect(items.take(6).map((i) => i.id), [
        'hanzi-yi',
        'hanzi-er',
        'hanzi-san',
        'hanzi-ren',
        'hanzi-kou',
        'hanzi-shan',
      ]);
      final chang = items.firstWhere((i) => i.text == '长');
      expect(chang.words.map((w) => w.pinyin.first), ['cháng', 'zhǎng']);
      expect(items.skip(6).every((i) => i.audio == null), isTrue);
    },
  );
}
