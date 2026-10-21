import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baby_learn_house/app/modules/math/grouped_quantity.dart';

void main() {
  testWidgets('nine groups contain81 compact objects without overflow', (
    t,
  ) async {
    final semantics = t.ensureSemantics();
    t.view.physicalSize = const Size(320, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: SingleChildScrollView(
              child: GroupedQuantity(groups: 9, perGroup: 9),
            ),
          ),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('group-object-8-8')), findsOneWidget);
    expect(find.byType(Semantics), findsWidgets);
    expect(
      find.bySemanticsLabel(RegExp(r'第 [1-9] 组，每组 9 个')),
      findsNWidgets(9),
    );
    expect(t.takeException(), isNull);
    semantics.dispose();
  });
}
