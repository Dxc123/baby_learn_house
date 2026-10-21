import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:baby_learn_house/app/data/reading_types.dart';
import 'validate_content.dart' show hasPcmAudio;

Future<List<String>> validateReadingResources(Directory root) async {
  final errors = <String>[];
  try {
    final catalog =
        jsonDecode(
              await File(
                '${root.path}/assets/data/content.json',
              ).readAsString(),
            )
            as Map<String, dynamic>;
    if (!(catalog['items'] as List).any((i) => i['readingId'] != null)) {
      return errors;
    }
    final body =
        jsonDecode(
              await File(
                '${root.path}/assets/data/readings.json',
              ).readAsString(),
            )
            as Map<String, dynamic>;
    validateReadingData(body, catalog);
    final manifestFile = File(
      '${root.path}/assets/audio/reading/manifest.json',
    );
    final manifest = manifestFile.existsSync()
        ? jsonDecode(await manifestFile.readAsString()) as List
        : [];
    final byId = {for (final e in manifest) e['lineId']: e};
    if (byId.length != manifest.length) {
      errors.add('Duplicate reading audio manifest');
    }
    final referenced = <String>{};
    for (final p in body['passages']) {
      for (final line in p['lines']) {
        if (line['audio'] == null) continue;
        referenced.add(line['id']);
        final entry = byId[line['id']];
        final file = File('${root.path}/assets/${line['audio']}');
        if (!await file.exists()) {
          errors.add('${line['id']}: missing reading audio');
          continue;
        }
        final bytes = await file.readAsBytes();
        if (!hasPcmAudio(bytes)) {
          errors.add('${line['id']}: invalid reading PCM');
        }
        final transcript = {
          'pinyin': line['pinyin'],
          'speechText': line['speechText'],
          'text': line['text'],
        };
        final textHash = sha256
            .convert(utf8.encode(jsonEncode(transcript)))
            .toString();
        if (entry == null ||
            entry['asset'] != line['audio'] ||
            entry['quality'] != line['audioQuality'] ||
            entry['speechText'] != line['speechText'] ||
            entry['textSha256'] != textHash ||
            entry['audioSha256'] != sha256.convert(bytes).toString() ||
            entry['source'] is! String ||
            (entry['source'] as String).isEmpty ||
            entry['voice'] is! String) {
          errors.add('${line['id']}: reading audio provenance mismatch');
        }
        if (line['audioQuality'] == 'verified' &&
            (entry?['reviewedBy'] is! String ||
                (entry['reviewedBy'] as String).trim().isEmpty)) {
          errors.add('${line['id']}: verified reading needs reviewer');
        }
      }
    }
    if (referenced.length != byId.length ||
        !referenced.containsAll(byId.keys.cast<String>())) {
      errors.add('Orphan reading audio provenance');
    }
  } catch (e) {
    errors.add('Reading audit failed: $e');
  }
  return errors;
}
