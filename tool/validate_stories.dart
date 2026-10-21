import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:baby_learn_house/app/data/story_types.dart';

Future<List<String>> validateStoryResources(Directory root) async {
  final errors = <String>[];
  try {
    final catalog =
        jsonDecode(
              await File(
                '${root.path}/assets/data/content.json',
              ).readAsString(),
            )
            as Map;
    if (!(catalog['items'] as List).any((i) => i['storyId'] != null)) {
      return errors;
    }
    final body =
        jsonDecode(
              await File(
                '${root.path}/assets/data/stories.json',
              ).readAsString(),
            )
            as Map;
    validateStoryData(body, catalog);
    dynamic canonical(dynamic value) {
      if (value is Map) {
        final keys = value.keys.cast<String>().toList()..sort();
        return {for (final k in keys) k: canonical(value[k])};
      }
      if (value is List) return value.map(canonical).toList();
      return value;
    }

    final source = Map<String, dynamic>.from(body)..remove('storyRevision');
    if (sha256.convert(utf8.encode(jsonEncode(canonical(source)))).toString() !=
        body['storyRevision']) {
      errors.add('Story revision checksum mismatch');
    }
    if (!await File('${root.path}/assets/STORY_SOURCES.md').exists()) {
      errors.add('Missing story sources');
    }
  } catch (e) {
    errors.add('Story audit: $e');
  }
  return errors;
}
