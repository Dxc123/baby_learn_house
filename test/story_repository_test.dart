import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baby_learn_house/app/data/learning_content.dart';
import 'package:baby_learn_house/app/data/story_repository.dart';

class StoryBundle extends CachingAssetBundle {
  String value = 'bad';
  int reads = 0;
  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    reads++;
    return value;
  }

  @override
  Future<ByteData> load(String key) => throw UnimplementedError();
}

void main() {
  test('non-map unrelated document and scene do not poison target', () async {
    final data =
        jsonDecode(File('assets/data/content.json').readAsStringSync())
            as Map<String, dynamic>;
    final body = jsonDecode(
      File('assets/data/stories.json').readAsStringSync(),
    );
    body['stories'][1] = null;
    body['scenes'][7] = null;
    final repo = StoryRepository(
      StoryBundle()..value = jsonEncode(body),
      ContentRepository.fromJson(data),
    );
    expect((await repo.load('book-share-toys')).units.length, 6);
  });
  test(
    'bad different document isolated and revision mismatch retriable',
    () async {
      final data =
          jsonDecode(File('assets/data/content.json').readAsStringSync())
              as Map<String, dynamic>;
      final body = jsonDecode(
        File('assets/data/stories.json').readAsStringSync(),
      );
      body['stories'][1]['pages'] = [];
      final bundle = StoryBundle()..value = jsonEncode(body);
      final repo = StoryRepository(bundle, ContentRepository.fromJson(data));
      expect((await repo.load('book-share-toys')).units.length, 6);
      await expectLater(repo.load('book-tidy-up'), throwsFormatException);
      body['storyRevision'] = 'old';
      bundle.value = jsonEncode(body);
      await expectLater(repo.load('dialog-help'), throwsFormatException);
      bundle.value = File('assets/data/stories.json').readAsStringSync();
      expect((await repo.load('dialog-help')).units.length, 6);
    },
  );
  test('failed body retries and successful body caches target', () async {
    final catalog = ContentRepository.fromJson(
      jsonDecode(File('assets/data/content.json').readAsStringSync())
          as Map<String, dynamic>,
    );
    final bundle = StoryBundle();
    final repo = StoryRepository(bundle, catalog);
    await expectLater(repo.load('book-share-toys'), throwsFormatException);
    bundle.value = File('assets/data/stories.json').readAsStringSync();
    final doc = await repo.load('book-share-toys');
    expect(doc.units.length, 6);
    await repo.load(doc.id);
    expect(bundle.reads, 2);
  });
}
