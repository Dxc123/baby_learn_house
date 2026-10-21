import 'dart:convert';
import 'package:flutter/services.dart';
import 'learning_content.dart';
import 'reading_types.dart';

class ReadingRepository {
  ReadingRepository(this.bundle, this.content);
  final AssetBundle bundle;
  final ContentRepository content;
  final _cache = <String, ReadingPassage>{};
  Future<ReadingPassage> load(String readingId) async {
    if (!content.items.any((i) => i.readingId == readingId)) {
      throw const FormatException('Unknown reading');
    }
    if (_cache.containsKey(readingId)) return _cache[readingId]!;
    final body =
        jsonDecode(
              await bundle.loadString(
                'assets/data/readings.json',
                cache: false,
              ),
            )
            as Map<String, dynamic>;
    if (body['version'] != 1 ||
        content.readingRevision == null ||
        body['readingRevision'] != content.readingRevision) {
      throw const FormatException('Reading version mismatch');
    }
    final matches = (body['passages'] as List)
        .where((p) => p['id'] == readingId)
        .toList();
    if (matches.length != 1) {
      throw const FormatException('Unknown/duplicate reading');
    }
    final raw = Map<String, dynamic>.from(matches.single);
    validateReadingPassage(raw, content.raw);
    final result = ReadingPassage.fromJson(raw);
    _cache[readingId] = result;
    return result;
  }
}
