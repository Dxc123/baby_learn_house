import 'dart:io';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import '../tool/validate_stories.dart';

void main() {
  test('story revision detects structurally valid tampered text', () async {
    final root = await Directory.systemTemp.createTemp('story-audit-');
    try {
      await Directory('${root.path}/assets/data').create(recursive: true);
      await File(
        'assets/data/content.json',
      ).copy('${root.path}/assets/data/content.json');
      final body = jsonDecode(
        File('assets/data/stories.json').readAsStringSync(),
      );
      body['stories'][0]['intro'] = '这是一段已被修改但结构有效的介绍。';
      await File(
        '${root.path}/assets/data/stories.json',
      ).writeAsString(jsonEncode(body));
      await File(
        'assets/STORY_SOURCES.md',
      ).copy('${root.path}/assets/STORY_SOURCES.md');
      expect(await validateStoryResources(root), isNotEmpty);
    } finally {
      await root.delete(recursive: true);
    }
  });
  test('joint story audit covers all9 documents and18 scenes', () async {
    expect(await validateStoryResources(Directory.current), isEmpty);
  });
}
