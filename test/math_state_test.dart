import 'package:flutter_test/flutter_test.dart';
import 'package:baby_learn_house/app/data/content_types.dart';
import 'package:baby_learn_house/app/modules/math/math_state.dart';

void main() {
  test('counting is idempotent and bounded', () {
    final state = CountingState();
    state.tap(0);
    state.tap(0);
    expect(state.count, 1);
    for (var i = 0; i < 5; i++) {
      state.tap(i);
    }
    expect(state.complete, isTrue);
    expect(() => state.tap(5), throwsArgumentError);
    expect(() => state.setTarget(0), throwsArgumentError);
    state.setTarget(2);
    expect(state.count, 0);
    state.tap(1);
    state.reset();
    expect(state.target, 2);
    expect(state.count, 0);
    expect(() => state.countedIndices.add(0), throwsUnsupportedError);
  });
  test('addition exhaustive and resets reveal', () {
    for (var a = 0; a <= 10; a++) {
      for (var b = 0; b <= 10 - a; b++) {
        final s = ArithmeticState(kind: ActivityKind.addition);
        s.setRight(0);
        s.setLeft(a);
        s.setRight(b);
        s.reveal();
        expect(s.result, a + b);
        expect(s.revealed, isTrue);
        s.reset();
        expect(s.revealed, isFalse);
        expect(s.result, a + b);
        s.reveal();
        s.setRight(b);
        expect(s.revealed, isFalse);
        expect(() => s.setRight(11 - a), throwsArgumentError);
        expect(s.right, b);
      }
    }
  });
  test('subtraction exhaustive and shrinking left clamps right', () {
    for (var a = 0; a <= 10; a++) {
      for (var b = 0; b <= a; b++) {
        final s = ArithmeticState(kind: ActivityKind.subtraction);
        s.setLeft(a);
        s.setRight(b);
        s.reveal();
        expect(s.result, a - b);
        expect(() => s.setRight(a + 1), throwsArgumentError);
        expect(s.right, b);
        s.setLeft(0);
        expect(s.right, 0);
        expect(s.revealed, isFalse);
      }
    }
    expect(
      () => ArithmeticState(kind: ActivityKind.count),
      throwsArgumentError,
    );
  });
}
