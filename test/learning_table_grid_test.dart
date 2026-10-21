import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baby_learn_house/app/modules/math/learning_table_grid.dart';

void main() {
  testWidgets('last cell is built visible after selection and accessible', (
    t,
  ) async {
    t.view.physicalSize = const Size(320, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    final semantics = t.ensureSemantics();
    Future<void> render(String? selected, int rev) async {
      await t.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 300),
                    LearningTableGrid(
                      columnLabels: List.generate(10, (i) => '${i + 1}'),
                      rowLabels: List.generate(10, (i) => '${i + 1}'),
                      cells: List.generate(
                        10,
                        (r) => List.generate(
                          10,
                          (c) => LearningTableCell(
                            id: 'n-${r * 10 + c + 1}',
                            label: '${r * 10 + c + 1}',
                            semanticsLabel: '数字 ${r * 10 + c + 1}',
                            enabled: true,
                            selected: selected == 'n-${r * 10 + c + 1}',
                            highlighted: false,
                            onTap: () {},
                          ),
                        ),
                      ),
                      selectedCellId: selected,
                      selectionRevision: rev,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
    }

    await render('n-100', 1);
    expect(
      find.byKey(const ValueKey('cell-n-100')).hitTestable(),
      findsOneWidget,
    );
    expect(
      t
          .getSemantics(find.byKey(const ValueKey('cell-n-100')))
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isTrue,
    );
    await render('n-1', 2);
    expect(
      find.byKey(const ValueKey('cell-n-1')).hitTestable(),
      findsOneWidget,
    );
    expect(t.takeException(), isNull);
    await t.drag(
      find.byType(SingleChildScrollView).last,
      const Offset(-180, 0),
    );
    await t.pumpAndSettle();
    final controller = t.widget<Scrollbar>(find.byType(Scrollbar)).controller!;
    final offset = controller.offset;
    expect(offset, greaterThan(0));
    await render('n-1', 2);
    expect(controller.offset, closeTo(offset, .1));
    // Rebuild synchronously without drawing a frame: both positioning
    // callbacks are genuinely queued together before the scheduler runs.
    final grid = t.widget<LearningTableGrid>(find.byType(LearningTableGrid));
    void queueSelection(String id, int revision) {
      final element = t.element(find.byType(LearningTableGrid));
      t.binding.buildOwner!.buildScope(
        element,
        () => element.update(
          LearningTableGrid(
            columnLabels: grid.columnLabels,
            rowLabels: grid.rowLabels,
            cells: grid.cells,
            selectedCellId: id,
            selectionRevision: revision,
          ),
        ),
      );
    }

    queueSelection('n-100', 3);
    queueSelection('n-1', 4);
    await t.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('cell-n-1')).hitTestable(),
      findsOneWidget,
    );
    queueSelection('n-100', 5);
    await t.pumpWidget(const SizedBox());
    await t.pump();
    expect(t.takeException(), isNull);
    semantics.dispose();
  });
}
