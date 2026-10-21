import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crypto/crypto.dart';
import 'package:baby_learn_house/app/data/hanzi_strokes.dart';
import 'package:baby_learn_house/app/data/learning_content.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('all 60 glyphs agree with content and pinned provenance', () async {
    final content = await ContentRepository.load(rootBundle);
    final manifest = jsonDecode(
      await File('assets/strokes/manifest.json').readAsString(),
    );
    final entries = {for (final e in manifest['entries']) e['asset']: e};
    expect(entries.length, 60);
    expect(
      sha256.convert(await File(manifest['license']).readAsBytes()).toString(),
      manifest['licenseSha256'],
    );
    final repo = HanziStrokeRepository(rootBundle);
    for (final item in content.itemsFor('chinese')) {
      final glyph = await repo.load(item.strokeAsset!);
      expect(glyph.character, item.text);
      expect(glyph.strokes.length, item.strokes);
      expect(glyph.medians.length, item.strokes);
      expect(
        sha256.convert(await File(item.strokeAsset!).readAsBytes()).toString(),
        entries[item.strokeAsset]['sha256'],
      );
    }
  });
  test('malformed paths, coordinates and traversal fail', () async {
    final data =
        jsonDecode(await File('assets/strokes/4e00.json').readAsString())
            as Map<String, dynamic>;
    data['strokes'] = ['M NaN 0'];
    expect(
      () => HanziStrokeData.fromJson(data, character: '一'),
      throwsFormatException,
    );
    data['strokes'] = ['M 0 0 L 10 10 L 20 0 Z'];
    data['medians'] = [
      [
        [0, double.infinity],
        [1, 1],
      ],
    ];
    expect(
      () => HanziStrokeData.fromJson(data, character: '一'),
      throwsFormatException,
    );
    await expectLater(
      HanziStrokeRepository(rootBundle).load('assets/strokes/../4e00.json'),
      throwsFormatException,
    );
  });
}
