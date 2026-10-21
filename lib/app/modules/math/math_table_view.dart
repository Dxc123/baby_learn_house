import 'package:flutter/material.dart';
import '../../core/learning_widgets.dart';
import 'math_table_rules.dart';
import 'learning_table_grid.dart';
import 'grouped_quantity.dart';

class MathTableView extends StatefulWidget {
  const MathTableView({super.key, required this.kind});
  final MathTableKind kind;
  @override
  State<MathTableView> createState() => _MathTableViewState();
}

class _MathTableViewState extends State<MathTableView> {
  late MathTableSelection _selection;
  int _revision = 0;
  @override
  void initState() {
    super.initState();
    _selection = MathTableSelection(widget.kind);
  }

  @override
  void didUpdateWidget(covariant MathTableView old) {
    super.didUpdateWidget(old);
    if (old.kind != widget.kind) {
      _selection = MathTableSelection(widget.kind);
      _revision++;
    }
  }

  void _select(int row, int column) => setState(() {
    _selection.select(row, column);
    _revision++;
  });
  Widget _stepper(
    String label,
    int value,
    String key,
    int min,
    int max,
    ValueChanged<int> update,
  ) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        '$label：$value',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 20),
      ),
      Wrap(
        alignment: WrapAlignment.center,
        children: [
          IconButton(
            key: ValueKey('$key-minus'),
            tooltip: '$label减少一个',
            onPressed: value > min
                ? () => setState(() {
                    update(value - 1);
                    _revision++;
                  })
                : null,
            icon: const Icon(Icons.remove_circle_outline),
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          ),
          IconButton(
            key: ValueKey('$key-plus'),
            tooltip: '$label增加一个',
            onPressed: value < max
                ? () => setState(() {
                    update(value + 1);
                    _revision++;
                  })
                : null,
            icon: const Icon(Icons.add_circle_outline),
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          ),
        ],
      ),
    ],
  );
  @override
  Widget build(BuildContext context) {
    final rules = _selection.rules;
    final fact = _selection.fact;
    final sub = widget.kind == MathTableKind.subtraction;
    final (title, rowLabel, columnLabel, description) = switch (widget.kind) {
      MathTableKind.addition => (
        '九九加法',
        '第一个加数',
        '第二个加数',
        '行是第一个加数，列是第二个加数，各为1～9。本表允许和大于10。',
      ),
      MathTableKind.subtraction => (
        '九九减法',
        '被减数',
        '减数',
        '行是被减数1～9，列是减数0～9。“—”超出本页范围，不计算负数。',
      ),
      MathTableKind.multiplication => (
        '九九乘法',
        '组数',
        '每组数量',
        '行是组数，列是每组数量，格中是一共几个。',
      ),
      MathTableKind.division => (
        '九九除法',
        '分成几组',
        '每组几个',
        '格中为总数，行是分成几组（除数），列是每组几个（商）。本表只探索整除。',
      ),
    };
    return LearningScaffold(
      title: title,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              fact.equation,
              key: const ValueKey('table-equation'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(description),
            const SizedBox(height: 12),
            SoftPanel(
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 24,
                runSpacing: 12,
                children: [
                  _stepper(
                    rowLabel,
                    _selection.row,
                    'table-row',
                    1,
                    9,
                    _selection.setRow,
                  ),
                  _stepper(
                    columnLabel,
                    _selection.column,
                    'table-column',
                    sub ? 0 : 1,
                    sub ? _selection.row : 9,
                    _selection.setColumn,
                  ),
                ],
              ),
            ),
            if (fact.groups != null) ...[
              const SizedBox(height: 16),
              Text(
                widget.kind == MathTableKind.division
                    ? '把 ${fact.left} 个平均分成 ${fact.groups} 组，每组 ${fact.perGroup} 个。'
                    : '${fact.groups} 组，每组 ${fact.perGroup} 个，一共 ${fact.result} 个。',
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 12),
              GroupedQuantity(groups: fact.groups!, perGroup: fact.perGroup!),
            ],
            const SizedBox(height: 20),
            LearningTableGrid(
              columnLabels: rules.columns.map((c) => '$c').toList(),
              rowLabels: rules.rows.map((r) => '$r').toList(),
              selectedCellId:
                  '${widget.kind.name}-${_selection.row}-${_selection.column}',
              selectionRevision: _revision,
              cells: [
                for (final r in rules.rows)
                  [for (final c in rules.columns) _cell(r, c)],
              ],
            ),
            const SizedBox(height: 16),
            const Text('点选探索，不计分；退出后重新开始。', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  LearningTableCell _cell(int r, int c) {
    final rules = _selection.rules;
    final valid = rules.isValid(r, c);
    final fact = valid ? rules.fact(r, c) : null;
    return LearningTableCell(
      id: '${widget.kind.name}-$r-$c',
      label: fact == null
          ? '—'
          : '${widget.kind == MathTableKind.division ? fact.left : fact.result}',
      semanticsLabel: fact?.equation ?? '$r 减 $c，超出本页范围',
      enabled: valid,
      selected: r == _selection.row && c == _selection.column,
      highlighted: r == _selection.row || c == _selection.column,
      onTap: valid ? () => _select(r, c) : null,
    );
  }
}
