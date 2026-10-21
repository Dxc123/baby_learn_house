import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baby_learn_house/app/data/learning_content.dart';
import 'package:baby_learn_house/app/data/hanzi_strokes.dart';
import 'package:baby_learn_house/app/services/worksheet_pdf_service.dart';

class MissingFontBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) {
    if (key.contains('/fonts/')) throw StateError('Missing font');
    return rootBundle.load(key);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('export rejects unknown, non-Hanzi and missing font', () async {
    final content = await ContentRepository.load(rootBundle);
    final repo = HanziStrokeRepository(rootBundle);
    final service = WorksheetPdfService(content, repo, rootBundle);
    await expectLater(
      service.build(WorksheetConfig(itemIds: ['unknown'])),
      throwsArgumentError,
    );
    await expectLater(
      service.build(WorksheetConfig(itemIds: ['en-a'])),
      throwsArgumentError,
    );
    await expectLater(
      WorksheetPdfService(
        content,
        repo,
        MissingFontBundle(),
      ).build(WorksheetConfig(itemIds: ['hanzi-yi'])),
      throwsStateError,
    );
  });
  test(
    'real service builds six and maximum-batch printable artifacts',
    () async {
      final content = await ContentRepository.load(rootBundle);
      final service = WorksheetPdfService(
        content,
        HanziStrokeRepository(rootBundle),
        rootBundle,
      );
      final ids = content
          .sortedItems('chinese', 'grade')
          .map((i) => i.id)
          .toList();
      for (final entry in [
        ('six', ids.take(6).toList(), 2),
        ('sixty', ids, 4),
      ]) {
        final bytes = await service.build(
          WorksheetConfig(itemIds: entry.$2, rowsPerCharacter: entry.$3),
        );
        expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
        expect(bytes.length, greaterThan(10000));
        if (const bool.fromEnvironment('WRITE_WORKSHEETS')) {
          await Directory('docs/artifacts').create(recursive: true);
          await File(
            'docs/artifacts/worksheet-${entry.$1}.pdf',
          ).writeAsBytes(bytes);
        }
      }
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
