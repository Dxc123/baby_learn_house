import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baby_learn_house/app/data/learning_content.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('catalog preserves 28 destinations and stable sample IDs', () async {
    final content = await ContentRepository.load(rootBundle);
    expect(content.categories.length, 28);
    expect(content.categories.map((e) => e.id).toSet().length, 28);
    expect(content.itemsFor('chinese').first.id, 'hanzi-yi');
    expect(content.itemsFor('animals').length, 6);
    expect(content.itemsFor('pinyin').length, 63);
    expect(
      content.categories.where((e) => e.available).map((e) => e.id),
      containsAll(['chinese', 'animals', 'pinyin']),
    );
    for (final item in content.items) {
      if (item.kind == ContentKind.hanzi ||
          item.kind == ContentKind.cognition) {
        expect(item.pinyin.length, item.text.runes.length);
      }
    }
  });
  test(
    'bundled sample audio is real PCM WAV, not a network dependency',
    () async {
      final content = await ContentRepository.load(rootBundle);
      for (final item in content.items) {
        if (item.audio == null) continue;
        final bytes = await File('assets/${item.audio}').readAsBytes();
        expect(String.fromCharCodes(bytes.take(4)), 'RIFF');
        expect(String.fromCharCodes(bytes.skip(8).take(4)), 'WAVE');
        expect(bytes.length, greaterThan(1000));
        var pcmSize = 0;
        var offset = 12;
        final data = ByteData.sublistView(bytes);
        while (offset + 8 <= bytes.length) {
          final name = String.fromCharCodes(bytes.skip(offset).take(4));
          final size = data.getUint32(offset + 4, Endian.little);
          if (name == 'data') {
            pcmSize = size;
            expect(
              bytes.skip(offset + 8).take(size).any((byte) => byte != 0),
              isTrue,
            );
            break;
          }
          offset += 8 + size + (size % 2);
        }
        expect(
          pcmSize,
          greaterThan(2000),
          reason: '${item.id} must contain real audio frames',
        );
      }
    },
  );
}
