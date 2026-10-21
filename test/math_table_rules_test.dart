import 'package:flutter_test/flutter_test.dart';
import 'package:baby_learn_house/app/modules/math/math_table_rules.dart';

void main() {
  test('exhaustive table facts have correct operands and grouping', () {
    for (final kind in MathTableKind.values) {
      final rules = MathTableRules(kind);
      var valid = 0;
      for (final row in rules.rows) {
        for (final col in rules.columns) {
          if (kind == MathTableKind.subtraction && col > row) {
            expect(rules.isValid(row, col), isFalse);
            expect(() => rules.fact(row, col), throwsArgumentError);
            continue;
          }
          valid++;
          final f = rules.fact(row, col);
          expect(f.row, row);
          expect(f.column, col);
          switch (kind) {
            case MathTableKind.addition:
              expect(f.result, row + col);
              expect(f.equation, '$row + $col = ${row + col}');
            case MathTableKind.subtraction:
              expect(f.result, row - col);
            case MathTableKind.multiplication:
              expect(f.result, row * col);
              expect(f.groups, row);
              expect(f.perGroup, col);
            case MathTableKind.division:
              expect(f.left, row * col);
              expect(f.right, row);
              expect(f.result, col);
              expect(f.groups, row);
              expect(f.perGroup, col);
              expect(f.equation, '${row * col} ÷ $row = $col');
          }
        }
      }
      expect(valid, kind == MathTableKind.subtraction ? 54 : 81);
      for (final pair in [
        [0, 1],
        [10, 1],
        [1, 10],
      ]) {
        expect(() => rules.fact(pair[0], pair[1]), throwsArgumentError);
      }
    }
  });
  test('division identities and subtraction clamp are stable', () {
    final s = MathTableSelection(MathTableKind.division);
    s.select(2, 6);
    expect(s.fact.equation, '12 ÷ 2 = 6');
    s.select(3, 4);
    expect(s.row, 3);
    expect(s.column, 4);
    expect(s.fact.equation, '12 ÷ 3 = 4');
    expect(() => s.select(0, 0), throwsArgumentError);
    expect(s.row, 3);
    final sub = MathTableSelection(MathTableKind.subtraction);
    expect(sub.column, 0);
    sub.select(9, 9);
    sub.setRow(1);
    expect(sub.column, 1);
    expect(sub.fact.result, 0);
  });
}
