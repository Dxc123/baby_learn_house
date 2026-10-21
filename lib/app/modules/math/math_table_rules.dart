enum MathTableKind { addition, subtraction, multiplication, division }

class MathFact {
  const MathFact({
    required this.row,
    required this.column,
    required this.left,
    required this.right,
    required this.result,
    required this.equation,
    this.groups,
    this.perGroup,
  });
  final int row, column, left, right, result;
  final String equation;
  final int? groups, perGroup;
}

class MathTableRules {
  const MathTableRules(this.kind);
  final MathTableKind kind;
  List<int> get rows => List.unmodifiable(List.generate(9, (i) => i + 1));
  List<int> get columns => List.unmodifiable(
    List.generate(
      kind == MathTableKind.subtraction ? 10 : 9,
      (i) => kind == MathTableKind.subtraction ? i : i + 1,
    ),
  );
  bool isValid(int row, int column) =>
      rows.contains(row) &&
      columns.contains(column) &&
      (kind != MathTableKind.subtraction || column <= row);
  MathFact fact(int row, int column) {
    if (!isValid(row, column)) throw ArgumentError('Invalid table cell');
    final left = kind == MathTableKind.division ? row * column : row;
    final right = kind == MathTableKind.division ? row : column;
    final (symbol, result) = switch (kind) {
      MathTableKind.addition => ('+', row + column),
      MathTableKind.subtraction => ('−', row - column),
      MathTableKind.multiplication => ('×', row * column),
      MathTableKind.division => ('÷', column),
    };
    final grouped =
        kind == MathTableKind.multiplication || kind == MathTableKind.division;
    return MathFact(
      row: row,
      column: column,
      left: left,
      right: right,
      result: result,
      equation: '$left $symbol $right = $result',
      groups: grouped ? row : null,
      perGroup: grouped ? column : null,
    );
  }
}

class MathTableSelection {
  MathTableSelection(MathTableKind kind)
    : rules = MathTableRules(kind),
      _column = kind == MathTableKind.subtraction ? 0 : 1;
  final MathTableRules rules;
  int _row = 1, _column;
  int get row => _row;
  int get column => _column;
  MathFact get fact => rules.fact(row, column);
  void select(int row, int column) {
    if (!rules.isValid(row, column)) throw ArgumentError('Invalid selection');
    _row = row;
    _column = column;
  }

  void setRow(int value) {
    final col = rules.kind == MathTableKind.subtraction && column > value
        ? value
        : column;
    select(value, col);
  }

  void setColumn(int value) => select(row, value);
}
