import 'package:flutter_test/flutter_test.dart';
import 'package:baby_learn_house/app/data/learning_content.dart';
import 'package:baby_learn_house/app/data/reading_repository.dart';
import 'package:baby_learn_house/app/data/reading_types.dart';
import 'reading_fixtures.dart';

void main() {
  test(
    'lazy repository retries failures and rejects mismatched revisions',
    () async {
      final bundle = ReadingBundle(sampleBody())..fail = true;
      final repo = ReadingRepository(
        bundle,
        ContentRepository.fromJson(sampleCatalog()),
      );
      await expectLater(repo.load('poetry-test'), throwsStateError);
      bundle.fail = false;
      expect((await repo.load('poetry-test')).lines.length, 2);
      await expectLater(repo.load('unknown'), throwsFormatException);
      final body = sampleBody()..['readingRevision'] = 'wrong';
      await expectLater(
        ReadingRepository(
          ReadingBundle(body),
          ContentRepository.fromJson(sampleCatalog()),
        ).load('poetry-test'),
        throwsFormatException,
      );
    },
  );
  test('full audit rejects duplicate lines and invalid resources', () {
    final body = sampleBody();
    validateReadingData(body, sampleCatalog());
    final lines = body['passages'][0]['lines'] as List;
    lines.add(lines.first);
    expect(
      () => validateReadingData(body, sampleCatalog()),
      throwsFormatException,
    );
    lines.removeLast();
    lines.first['audio'] = 'audio/../x.wav';
    lines.first['audioQuality'] = 'demo';
    expect(
      () => validateReadingData(body, sampleCatalog()),
      throwsFormatException,
    );
  });
}
