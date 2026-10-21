import 'dart:math' as math;
import 'package:flutter/material.dart';

class LearningTableCell {
  const LearningTableCell({
    required this.id,
    required this.label,
    required this.semanticsLabel,
    required this.enabled,
    required this.selected,
    required this.highlighted,
    this.onTap,
  });
  final String id, label, semanticsLabel;
  final bool enabled, selected, highlighted;
  final VoidCallback? onTap;
}

/// A complete grid: only horizontal scrolling is owned here. The page owns y.
class LearningTableGrid extends StatefulWidget {
  const LearningTableGrid({
    super.key,
    required this.columnLabels,
    required this.rowLabels,
    required this.cells,
    required this.selectedCellId,
    required this.selectionRevision,
  });
  final List<String> columnLabels, rowLabels;
  final List<List<LearningTableCell>> cells;
  final String? selectedCellId;
  final int selectionRevision;
  @override
  State<LearningTableGrid> createState() => _LearningTableGridState();
}

class _LearningTableGridState extends State<LearningTableGrid> {
  final _scroll = ScrollController();
  final _keys = <String, GlobalKey>{};
  int _generation = 0;
  @override
  void initState() {
    super.initState();
    if (widget.cells.isNotEmpty &&
        widget.cells.first.isNotEmpty &&
        widget.selectedCellId != widget.cells.first.first.id) {
      _schedule();
    }
  }

  @override
  void didUpdateWidget(covariant LearningTableGrid old) {
    super.didUpdateWidget(old);
    if (old.selectedCellId != widget.selectedCellId ||
        old.selectionRevision != widget.selectionRevision) {
      _schedule();
    }
  }

  void _schedule() {
    final generation = ++_generation;
    final id = widget.selectedCellId;
    if (id == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || generation != _generation || !_scroll.hasClients) return;
      final target = _keys[id]?.currentContext;
      if (target != null) {
        Scrollable.ensureVisible(
          target,
          alignment: .5,
          duration: Duration.zero,
        );
      }
    });
  }

  @override
  void dispose() {
    _generation++;
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final text = TextPainter(
      text: const TextSpan(text: '100', style: TextStyle(fontSize: 18)),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout();
    final width = math.max(56.0, text.width + 28);
    final height = math.max(56.0, text.height + 24);
    final scheme = Theme.of(context).colorScheme;
    Widget header(String label) => SizedBox(
      width: width,
      height: height,
      child: Center(
        child: Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('左右滑动查看完整表格', textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Scrollbar(
          controller: _scroll,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _scroll,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              children: [
                Row(
                  children: [
                    header('行/列'),
                    for (final label in widget.columnLabels) header(label),
                  ],
                ),
                for (var r = 0; r < widget.cells.length; r++)
                  Row(
                    children: [
                      header(widget.rowLabels[r]),
                      for (final cell in widget.cells[r])
                        SizedBox(
                          key: _keys.putIfAbsent(cell.id, () => GlobalKey()),
                          width: width,
                          height: height,
                          child: Semantics(
                            key: ValueKey('cell-${cell.id}'),
                            label: cell.semanticsLabel,
                            selected: cell.selected,
                            button: cell.enabled,
                            enabled: cell.enabled,
                            onTap: cell.enabled ? cell.onTap : null,
                            child: ExcludeSemantics(
                              child: Material(
                                color: cell.selected
                                    ? scheme.primaryContainer
                                    : cell.highlighted
                                    ? scheme.secondaryContainer
                                    : Colors.white,
                                child: InkWell(
                                  onTap: cell.enabled ? cell.onTap : null,
                                  child: Container(
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: cell.selected
                                            ? scheme.primary
                                            : Colors.grey.shade300,
                                        width: cell.selected ? 3 : 1,
                                      ),
                                    ),
                                    child: Text(
                                      cell.label,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: cell.selected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: cell.enabled
                                            ? scheme.onSurface
                                            : Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
