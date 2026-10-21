import 'package:flutter/material.dart';
import '../../core/learning_widgets.dart';
import 'hundred_state.dart';
import 'learning_table_grid.dart';

class HundredView extends StatefulWidget {
  const HundredView({super.key});
  @override
  State<HundredView> createState() => _HundredViewState();
}

class _HundredViewState extends State<HundredView> {
  final _state = HundredState();
  final _input = TextEditingController(text: '1');
  String? _error;
  int _revision = 0;
  void _select(int value) {
    setState(() {
      _state.select(value);
      _input.text = '$value';
      _error = null;
      _revision++;
    });
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    setState(() {
      _error = _state.submit(_input.text);
      if (_error == null) {
        _input.text = '${_state.value}';
        _revision++;
      }
    });
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LearningScaffold(
    title: '百数表',
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '当前数字：${_state.value}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('hundred-input'),
            controller: _input,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: '输入 0～100 的整数'),
            onSubmitted: (_) => _submit(),
          ),
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              FilledButton(
                key: const ValueKey('hundred-submit'),
                onPressed: _submit,
                child: const Text('查看'),
              ),
              OutlinedButton(
                key: const ValueKey('hundred-previous'),
                onPressed: _state.canPrevious
                    ? () => _select(_state.value - 1)
                    : null,
                child: const Text('前一个'),
              ),
              OutlinedButton(
                key: const ValueKey('hundred-next'),
                onPressed: _state.canNext
                    ? () => _select(_state.value + 1)
                    : null,
                child: const Text('后一个'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            key: const ValueKey('hundred-zero'),
            onPressed: () => _select(0),
            child: const Text('0 · 一个也没有'),
          ),
          const Text('主体是 1～100，每行10个。同一列向下一格增加10。0单独认识，不占第一行位置。'),
          const SizedBox(height: 16),
          LearningTableGrid(
            columnLabels: List.generate(10, (c) => '${c + 1}'),
            rowLabels: List.generate(10, (r) => '${r + 1}'),
            selectedCellId: _state.value == 0
                ? null
                : 'hundred-${_state.value}',
            selectionRevision: _revision,
            cells: List.generate(
              10,
              (r) => List.generate(10, (c) {
                final n = r * 10 + c + 1;
                return LearningTableCell(
                  id: 'hundred-$n',
                  label: '$n',
                  semanticsLabel: '数字 $n，第 ${r + 1} 行，第 ${c + 1} 列',
                  enabled: true,
                  selected: n == _state.value,
                  highlighted:
                      _state.value != 0 &&
                      (_state.row == r || _state.column == c),
                  onTap: () => _select(n),
                );
              }),
            ),
          ),
          const SizedBox(height: 16),
          const Text('点选探索，不计分，也不会改变已学记录。', textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}
