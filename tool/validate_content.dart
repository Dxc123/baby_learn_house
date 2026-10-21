import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'validate_readings.dart';
import 'validate_stories.dart';
export 'validate_readings.dart' show validateReadingResources;
import 'package:baby_learn_house/app/data/content_types.dart';

Future<List<String>> validateContent(Directory root) async {
  final errors = <String>[];
  try {
    final data =
        jsonDecode(
              await File(
                '${root.path}/assets/data/content.json',
              ).readAsString(),
            )
            as Map<String, dynamic>;
    validateContentData(data);
    final manifest =
        (jsonDecode(
                  await File(
                    '${root.path}/assets/audio/manifest.json',
                  ).readAsString(),
                )
                as List)
            .cast<Map<String, dynamic>>();
    if (manifest.map((m) => m['asset']).toSet().length != manifest.length) {
      errors.add('Duplicate manifest asset');
    }
    final manifestByAsset = {for (final m in manifest) m['asset']: m};
    final categories = {for (final c in data['categories']) c['id']: c};
    final hanziItems = (data['items'] as List)
        .where(
          (i) =>
              contentKind(
                Map<String, dynamic>.from(categories[i['categoryId']]),
              ) ==
              ContentKind.hanzi,
        )
        .toList();
    for (final item in hanziItems) {
      if (item['strokeAsset'] == null) {
        errors.add('${item['id']}: missing stroke reference');
      }
    }
    final strokeItems = hanziItems
        .where((i) => i['strokeAsset'] != null)
        .toList();
    if (strokeItems.isNotEmpty) {
      final source = jsonDecode(
        await File('${root.path}/assets/strokes/manifest.json').readAsString(),
      );
      final entries = {for (final e in source['entries']) e['asset']: e};
      if (entries.length != (source['entries'] as List).length ||
          entries.length != hanziItems.length) {
        errors.add('Stroke manifest coverage mismatch');
      }
      final seen = <String>{};
      if (!RegExp(r'^[0-9a-f]{40}$').hasMatch(source['revision'] as String)) {
        errors.add('Unpinned stroke source');
      }
      final license = File('${root.path}/${source['license']}');
      if (sha256.convert(await license.readAsBytes()).toString() !=
          source['licenseSha256']) {
        errors.add('Stroke license mismatch');
      }
      for (final item in strokeItems) {
        final path = item['strokeAsset'] as String;
        if (!seen.add(path)) errors.add('Duplicate stroke reference');
        final bytes = await File('${root.path}/$path').readAsBytes();
        final entry = entries[path];
        if (entry == null ||
            entry['character'] != item['text'] ||
            sha256.convert(bytes).toString() != entry['sha256'] ||
            !(entry['source'] as String).contains(source['revision'])) {
          errors.add('$path: stroke provenance mismatch');
        }
        final glyph = jsonDecode(utf8.decode(bytes));
        final paths = glyph['strokes'] as List;
        final medians = glyph['medians'] as List;
        if (paths.length != item['strokes'] ||
            medians.length != paths.length ||
            paths.any(
              (p) =>
                  p is! String ||
                  !RegExp(r'^[MmLlHhVvCcSsQqTtAaZz0-9., +\-]+$').hasMatch(p),
            )) {
          errors.add('$path: invalid stroke structure');
        }
        for (final line in medians) {
          if ((line as List).length < 2 ||
              line.any(
                (p) =>
                    p is! List ||
                    p.length != 2 ||
                    p.any((n) => n is! num || !n.isFinite),
              )) {
            errors.add('$path: invalid median');
          }
        }
      }
      final fontSource = jsonDecode(
        await File('${root.path}/assets/fonts/manifest.json').readAsString(),
      );
      for (final key in ['asset', 'license']) {
        if (sha256
                .convert(
                  await File('${root.path}/${fontSource[key]}').readAsBytes(),
                )
                .toString() !=
            fontSource['${key}Sha256']) {
          errors.add('Font $key hash mismatch');
        }
      }
    }
    for (final raw in data['items'] as List) {
      final item = raw as Map<String, dynamic>;
      final audio = item['audio'] as String?;
      if (audio != null) {
        final file = File('${root.path}/assets/$audio');
        if (!await file.exists()) {
          errors.add('${item['id']}: missing $audio');
          continue;
        }
        final bytes = await file.readAsBytes();
        if (!hasPcmAudio(bytes)) {
          errors.add('${item['id']}: invalid or silent WAV');
        }
        final provenance = manifestByAsset[audio];
        if (provenance == null ||
            provenance['source'] is! String ||
            (provenance['source'] as String).trim().isEmpty ||
            provenance['quality'] != (item['audioQuality'] ?? 'demo')) {
          errors.add('${item['id']}: missing or inconsistent audio provenance');
        } else if (provenance['quality'] == 'verified' &&
            (provenance['reviewedBy'] is! String ||
                (provenance['reviewedBy'] as String).trim().isEmpty)) {
          errors.add('${item['id']}: verified audio needs reviewer');
        }
      }
      final image = item['imageAsset'] as String?;
      if (image != null && !await File('${root.path}/assets/$image').exists()) {
        errors.add('${item['id']}: missing image');
      }
    }
    for (final category in data['categories'] as List) {
      if (category['available'] == true &&
          !(data['items'] as List).any(
            (i) => i['categoryId'] == category['id'],
          )) {
        if (category['activityKind'] == null) {
          errors.add('${category['id']}: available category has no content');
        }
      }
    }
    if (!await File('${root.path}/assets/RESOURCE_SOURCES.md').exists()) {
      errors.add('Missing resource source document');
    }
  } catch (error) {
    errors.add('Content audit failed: $error');
  }
  errors.addAll(await validateReadingResources(root));
  errors.addAll(await validateStoryResources(root));
  return errors;
}

bool hasPcmAudio(Uint8List bytes) {
  if (bytes.length < 44 ||
      String.fromCharCodes(bytes.take(4)) != 'RIFF' ||
      String.fromCharCodes(bytes.skip(8).take(4)) != 'WAVE') {
    return false;
  }
  final view = ByteData.sublistView(bytes);
  if (view.getUint32(4, Endian.little) + 8 != bytes.length) return false;
  var offset = 12;
  var pcm = false;
  var bits = 0;
  var blockAlign = 0;
  while (offset + 8 <= bytes.length) {
    final name = String.fromCharCodes(bytes.skip(offset).take(4));
    final length = view.getUint32(offset + 4, Endian.little);
    if (offset + 8 + length > bytes.length) return false;
    if (name == 'fmt ' && length >= 16) {
      final start = offset + 8;
      final format = view.getUint16(start, Endian.little);
      final channels = view.getUint16(start + 2, Endian.little);
      final sampleRate = view.getUint32(start + 4, Endian.little);
      final byteRate = view.getUint32(start + 8, Endian.little);
      blockAlign = view.getUint16(start + 12, Endian.little);
      bits = view.getUint16(start + 14, Endian.little);
      pcm =
          format == 1 &&
          channels >= 1 &&
          channels <= 2 &&
          sampleRate >= 8000 &&
          sampleRate <= 192000 &&
          [8, 16, 24, 32].contains(bits) &&
          blockAlign == channels * bits ~/ 8 &&
          byteRate == sampleRate * blockAlign;
    }
    if (name == 'data') {
      return pcm &&
          blockAlign > 0 &&
          length % blockAlign == 0 &&
          length > 2000 &&
          bytes
              .sublist(offset + 8, offset + 8 + length)
              .any((b) => b != (bits == 8 ? 128 : 0));
    }
    offset += 8 + length + (length % 2);
  }
  return false;
}

Future<void> main(List<String> arguments) async {
  final root = Directory(
    arguments.isEmpty ? Directory.current.path : arguments.single,
  );
  final errors = await validateContent(root);
  if (errors.isNotEmpty) {
    for (final error in errors) {
      stderr.writeln(error);
    }
    exitCode = 1;
  } else {
    final data =
        jsonDecode(
              await File(
                '${root.path}/assets/data/content.json',
              ).readAsString(),
            )
            as Map;
    final items = (data['items'] as List)
        .where((i) => i['readingId'] == null)
        .toList();
    final missing = items.where((i) => i['audio'] == null).length;
    stdout.writeln(
      'Content audit passed: ${items.length} items, ${items.length - missing} PCM clips, $missing explicitly unavailable recordings.',
    );
    if ((data['items'] as List).any((i) => i['readingId'] != null)) {
      final body = jsonDecode(
        await File('${root.path}/assets/data/readings.json').readAsString(),
      );
      final lines = [for (final p in body['passages']) ...p['lines']];
      stdout.writeln(
        'Reading audit passed: ${(data['items'] as List).length} total items; ${(body['passages'] as List).length} passages, ${lines.where((l) => l['audio'] != null).length} demo/verified clips, ${lines.where((l) => l['audio'] == null).length} unavailable reading lines.',
      );
    }
  }
}
