import 'package:flutter_test/flutter_test.dart';
import 'package:baby_learn_house/app/data/reading_types.dart';

void main() {
  test('annotations align punctuation and reject missing readings', () {
    validateAnnotations('床前明月光，', [
      'chuáng',
      'qián',
      'míng',
      'yuè',
      'guāng',
      '',
    ]);
    expect(() => validateAnnotations('人，', ['', '']), throwsFormatException);
    expect(
      () => validateAnnotations('人，', ['rén', 'dòu']),
      throwsFormatException,
    );
    expect(() => validateAnnotations('人', ['rén', 'x']), throwsFormatException);
  });
}
