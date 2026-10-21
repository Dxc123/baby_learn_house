import 'dart:io';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import '../tool/validate_content.dart';

void main() {
  test('reading audio tampering and orphan provenance are rejected', () async {
    final root = await Directory.systemTemp.createTemp('reading-audit-');
    addTearDown(() => root.delete(recursive: true));
    await Directory('${root.path}/assets/data').create(recursive: true);
    await Directory(
      '${root.path}/assets/audio/reading',
    ).create(recursive: true);
    final catalog = jsonDecode(
      await File('assets/data/content.json').readAsString(),
    );
    final body = jsonDecode(
      await File('assets/data/readings.json').readAsString(),
    );
    final manifest =
        jsonDecode(
              await File('assets/audio/reading/manifest.json').readAsString(),
            )
            as List;
    final chosen = body['passages'][0]['lines'][0];
    final chosenId = chosen['id'];
    for (final p in body['passages']) {
      for (final l in p['lines']) {
        if (l['id'] != chosenId) {
          l['audio'] = null;
          l['audioQuality'] = 'unavailable';
        }
      }
    }
    await File(
      '${root.path}/assets/data/content.json',
    ).writeAsString(jsonEncode(catalog));
    await File(
      '${root.path}/assets/data/readings.json',
    ).writeAsString(jsonEncode(body));
    final entry = manifest.firstWhere((e) => e['lineId'] == chosenId);
    final manifestFile = File(
      '${root.path}/assets/audio/reading/manifest.json',
    );
    await manifestFile.writeAsString(jsonEncode([entry]));
    final clip = await File(
      'assets/${chosen['audio']}',
    ).copy('${root.path}/assets/${chosen['audio']}');
    expect(await validateReadingResources(root), isEmpty);
    await clip.writeAsBytes([0, 1, 2]);
    expect(await validateReadingResources(root), isNotEmpty);
    await File('assets/${chosen['audio']}').copy(clip.path);
    entry['textSha256'] = 'tampered';
    await manifestFile.writeAsString(jsonEncode([entry]));
    expect(
      await validateReadingResources(root),
      contains(contains('provenance mismatch')),
    );
    await manifestFile.writeAsString(jsonEncode([...manifest.take(2)]));
    expect(await validateReadingResources(root), contains(contains('Orphan')));
  });
  test(
    'joint audit covers catalog, all reading lines and original resources',
    () async {
      expect(await validateContent(Directory.current), isEmpty);
      expect(await validateReadingResources(Directory.current), isEmpty);
    },
  );
}
