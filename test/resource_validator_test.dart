import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import '../tool/validate_content.dart';

void main() {
  test('stroke audit rejects tampered files and missing license', () async {
    final root = await Directory.systemTemp.createTemp('hanzi-provenance-');
    addTearDown(() => root.delete(recursive: true));
    for (final directory in ['strokes', 'fonts', 'licenses']) {
      await Directory('${root.path}/assets/$directory').create(recursive: true);
      await for (final file in Directory('assets/$directory').list()) {
        if (file is File) {
          await file.copy(
            '${root.path}/assets/$directory/${file.uri.pathSegments.last}',
          );
        }
      }
    }
    await Directory('${root.path}/assets/data').create(recursive: true);
    await Directory('${root.path}/assets/audio').create(recursive: true);
    await File('${root.path}/assets/audio/manifest.json').writeAsString('[]');
    await File(
      '${root.path}/assets/RESOURCE_SOURCES.md',
    ).writeAsString('Fixture');
    final source = jsonDecode(
      await File('assets/data/content.json').readAsString(),
    );
    source['categories'] = (source['categories'] as List)
        .where((c) => c['id'] == 'chinese')
        .toList();
    source['items'] = (source['items'] as List)
        .where((i) => i['categoryId'] == 'chinese')
        .toList();
    for (final item in source['items']) {
      item['audio'] = null;
      item['audioQuality'] = 'unavailable';
    }
    await File(
      '${root.path}/assets/data/content.json',
    ).writeAsString(jsonEncode(source));
    expect(await validateContent(root), isEmpty);
    final glyph = File('${root.path}/assets/strokes/4e00.json');
    await glyph.writeAsString('${await glyph.readAsString()}\n');
    expect(
      await validateContent(root),
      contains(contains('stroke provenance mismatch')),
    );
    await File('${root.path}/assets/licenses/ARPHICPL.TXT').delete();
    expect(await validateContent(root), isNotEmpty);
  });
  test('audit rejects any Hanzi missing its stroke reference', () async {
    final root = await Directory.systemTemp.createTemp('hanzi-missing-');
    addTearDown(() => root.delete(recursive: true));
    await Directory('${root.path}/assets/data').create(recursive: true);
    await Directory('${root.path}/assets/audio').create(recursive: true);
    await File('${root.path}/assets/audio/manifest.json').writeAsString('[]');
    await File(
      '${root.path}/assets/RESOURCE_SOURCES.md',
    ).writeAsString('Fixture');
    final source = jsonDecode(
      await File('assets/data/content.json').readAsString(),
    );
    final chinese = (source['categories'] as List).singleWhere(
      (c) => c['id'] == 'chinese',
    );
    final items = (source['items'] as List)
        .where((i) => i['categoryId'] == 'chinese')
        .toList();
    for (final item in items) {
      item.remove('strokeAsset');
      item['audio'] = null;
      item['audioQuality'] = 'unavailable';
    }
    await File('${root.path}/assets/data/content.json').writeAsString(
      jsonEncode({
        'version': 1,
        'categories': [chinese],
        'items': items,
      }),
    );
    final errors = await validateContent(root);
    expect(
      errors.where((e) => e.contains('missing stroke reference')).length,
      60,
    );
  });
  Uint8List pcmFixture({int bits = 16, int channels = 1, bool silent = false}) {
    final bytes = Uint8List(44 + 2400);
    final data = ByteData.sublistView(bytes);
    bytes.setAll(0, 'RIFF'.codeUnits);
    data.setUint32(4, bytes.length - 8, Endian.little);
    bytes.setAll(8, 'WAVEfmt '.codeUnits);
    data.setUint32(16, 16, Endian.little);
    data.setUint16(20, 1, Endian.little);
    data.setUint16(22, channels, Endian.little);
    data.setUint32(24, 22050, Endian.little);
    final align = channels * bits ~/ 8;
    data.setUint32(28, 22050 * align, Endian.little);
    data.setUint16(32, align, Endian.little);
    data.setUint16(34, bits, Endian.little);
    bytes.setAll(36, 'data'.codeUnits);
    data.setUint32(40, 2400, Endian.little);
    bytes.fillRange(44, bytes.length, silent ? (bits == 8 ? 128 : 0) : 32);
    return bytes;
  }

  test('PCM audit rejects corrupt format fields and partial frames', () {
    expect(hasPcmAudio(pcmFixture()), isTrue);
    for (final offset in [22, 24, 28, 32, 34]) {
      final bytes = pcmFixture();
      final view = ByteData.sublistView(bytes);
      if (offset == 24 || offset == 28) {
        view.setUint32(offset, 0, Endian.little);
      } else {
        view.setUint16(offset, 0, Endian.little);
      }
      expect(
        hasPcmAudio(bytes),
        isFalse,
        reason: 'corrupt format field at $offset',
      );
    }
    final partial = pcmFixture(channels: 2);
    ByteData.sublistView(partial).setUint32(40, 2399, Endian.little);
    expect(hasPcmAudio(partial), isFalse);
  });
  test(
    'PCM audit recognizes unsigned 8bit silence and signed 16bit silence',
    () {
      expect(hasPcmAudio(pcmFixture(bits: 8)), isTrue);
      expect(hasPcmAudio(pcmFixture(bits: 8, silent: true)), isFalse);
      expect(hasPcmAudio(pcmFixture(silent: true)), isFalse);
    },
  );
  test('verified audio requires an actual clip and a named reviewer', () async {
    final root = await Directory.systemTemp.createTemp('learning-audit-');
    addTearDown(() => root.delete(recursive: true));
    await Directory('${root.path}/assets/data').create(recursive: true);
    await Directory('${root.path}/assets/audio').create(recursive: true);
    final old =
        jsonDecode(
              await File('test/fixtures/phase1_content.json').readAsString(),
            )
            as Map;
    final item = (old['items'] as List).first as Map<String, dynamic>;
    item['audioQuality'] = 'verified';
    await File('${root.path}/assets/data/content.json').writeAsString(
      jsonEncode({
        'version': 1,
        'categories': [(old['categories'] as List).first],
        'items': [item],
      }),
    );
    final manifest = [
      {
        'asset': 'audio/pinyin-a.wav',
        'source': 'test fixture',
        'quality': 'verified',
        'reviewedBy': null,
      },
    ];
    final manifestFile = File('${root.path}/assets/audio/manifest.json');
    await manifestFile.writeAsString(jsonEncode(manifest));
    await File(
      '${root.path}/assets/RESOURCE_SOURCES.md',
    ).writeAsString('Fixture provenance');
    expect(
      await validateContent(root),
      contains(contains('missing audio/pinyin-a.wav')),
    );
    await File(
      'assets/audio/pinyin-a.wav',
    ).copy('${root.path}/assets/audio/pinyin-a.wav');
    expect(await validateContent(root), contains(contains('needs reviewer')));
    manifest.first['reviewedBy'] = 'Test reviewer';
    await manifestFile.writeAsString(jsonEncode(manifest));
    expect(await validateContent(root), isEmpty);
    await File(
      '${root.path}/assets/audio/pinyin-a.wav',
    ).writeAsBytes(List.filled(4096, 0));
    expect(
      await validateContent(root),
      contains(contains('invalid or silent WAV')),
    );
  });
}
