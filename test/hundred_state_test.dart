import 'package:flutter_test/flutter_test.dart';
import 'package:baby_learn_house/app/modules/math/hundred_state.dart';

void main() {
  test('hundred coordinates boundaries and invalid input', () {
    final s = HundredState();
    expect(s.value, 1);
    for (final entry in {
      1: [0, 0],
      10: [0, 9],
      11: [1, 0],
      100: [9, 9],
    }.entries) {
      s.select(entry.key);
      expect([s.row, s.column], entry.value);
    }
    s.next();
    expect(s.value, 100);
    s.select(0);
    s.previous();
    expect(s.value, 0);
    expect(s.row, isNull);
    expect(s.column, isNull);
    expect(s.submit(' 100 '), isNull);
    expect(s.value, 100);
    for (final input in ['', '-1', '1.5', '1e2', '101', '+1', '9' * 400]) {
      expect(s.submit(input), '请输入 0～100 的整数。');
      expect(s.value, 100);
    }
    expect(() => s.select(-1), throwsArgumentError);
  });
}
