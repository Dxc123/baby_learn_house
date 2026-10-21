import 'dart:convert';
import 'package:flutter/services.dart';
import 'learning_content.dart';
import 'story_types.dart';

class StoryRepository {
  StoryRepository(this.bundle, this.content);
  final AssetBundle bundle;
  final ContentRepository content;
  final _cache = <String, StoryDocument>{};
  Future<StoryDocument> load(String id) async {
    if (_cache.containsKey(id)) return _cache[id]!;
    final body =
        jsonDecode(
              await bundle.loadString('assets/data/stories.json', cache: false),
            )
            as Map<String, dynamic>;
    if (body['version'] != 1 ||
        content.storyRevision == null ||
        body['storyRevision'] != content.storyRevision) {
      throw const FormatException('Story revision mismatch');
    }
    final matches = (body['stories'] as List)
        .whereType<Map>()
        .where((s) => s['id'] == id)
        .toList();
    if (matches.length != 1) {
      throw const FormatException('Unknown/duplicate story');
    }
    final raw = Map<String, dynamic>.from(matches.single);
    final scenes = (body['scenes'] is List ? body['scenes'] as List : [])
        .whereType<Map>()
        .where((s) => s['bookId'] == id && s['id'] is String)
        .map((s) => Map<String, dynamic>.from(s))
        .toList();
    validateStoryDocument(raw, content.raw, scenes, allowMissingScenes: true);
    if (raw['type'] == 'pictureBook') {
      raw['pages'] = [
        for (var i = 0; i < (raw['pages'] as List).length; i++)
          Map<String, dynamic>.from(raw['pages'][i] as Map),
      ];
      for (var i = 0; i < (raw['pages'] as List).length; i++) {
        final unit = raw['pages'][i] as Map;
        final expected =
            '${storyBooks[id]}-${(i + 1).toString().padLeft(2, '0')}';
        final metadata = scenes.where((s) => s['id'] == expected).toList();
        final valid =
            unit['sceneId'] == expected &&
            metadata.length == 1 &&
            metadata.single['pageId'] == unit['id'] &&
            metadata.single['version'] == 1 &&
            metadata.single['source'] == 'project-authored vector scene' &&
            metadata.single['quality'] == 'illustration' &&
            metadata.single['alt'] is String &&
            (metadata.single['alt'] as String).trim().isNotEmpty;
        if (!valid) unit['sceneId'] = 'unavailable-${unit['id']}';
      }
    }
    final doc = StoryDocument.fromJson(raw, scenes: scenes);
    _cache[id] = doc;
    return doc;
  }
}
