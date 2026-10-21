import 'dart:convert';
import 'dart:io';
import 'package:baby_learn_house/app/data/learning_content.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baby_learn_house/app/data/story_types.dart';

void main() {
  test('story corpus rejects role scene unit and pronunciation tampering', () {
    final catalog =
        jsonDecode(File('assets/data/content.json').readAsStringSync())
            as Map<String, dynamic>;
    for (final change in [
      'role',
      'scene',
      'duplicate',
      'pinyin',
      'tips',
      'cover',
    ]) {
      final body =
          jsonDecode(File('assets/data/stories.json').readAsStringSync())
              as Map<String, dynamic>;
      final c = jsonDecode(jsonEncode(catalog)) as Map<String, dynamic>;
      if (change == 'role') {
        body['stories'][3]['turns'][0]['roleId'] = 'unknown';
      }
      if (change == 'scene') body['scenes'][0]['id'] = 'unknown';
      if (change == 'duplicate') {
        body['stories'][0]['pages'][1]['id'] =
            body['stories'][0]['pages'][0]['id'];
      }
      if (change == 'pinyin') body['stories'][0]['pages'][0]['pinyin'] = [];
      if (change == 'tips') body['stories'][3]['parentTips'] = [];
      if (change == 'cover') {
        c['items'].firstWhere(
          (i) => i['id'] == 'book-share-toys',
        )['coverSceneId'] = 'tidy-01';
      }
      expect(
        () => validateStoryData(body, c),
        throwsFormatException,
        reason: change,
      );
    }
    catalog['items'].firstWhere((i) => i['id'] == 'book-share-toys')['pinyin'] =
        [];
    expect(() => ContentRepository.fromJson(catalog), throwsFormatException);
  });
  test('story validation rejects missing structure', () {
    expect(
      () => validateStoryData(
        {'version': 1, 'stories': [], 'scenes': []},
        {'items': []},
      ),
      throwsFormatException,
    );
  });
}
