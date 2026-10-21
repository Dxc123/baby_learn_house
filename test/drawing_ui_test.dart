import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:baby_learn_house/app/services/learning_audio.dart';
import 'widget_test.dart' show launch;
import 'package:baby_learn_house/app/modules/drawing/drawing_view.dart';
import 'package:baby_learn_house/app/modules/drawing/drawing_draft_store.dart';
import 'package:baby_learn_house/app/modules/drawing/drawing_document.dart';
import 'learning_store_test.dart' show MemoryPreferences;

void main() {
  testWidgets(
    'legacy drawing routes stop audio and preserve learned progress',
    (t) async {
      Get.testMode = true;
      addTearDown(Get.reset);
      final learning = await launch(t);
      final before = learning.learned.toSet();
      final audio = Get.find<LearningAudio>();
      await audio.play('audio/test.wav');
      Get.toNamed('/learn/drawing');
      await t.pumpAndSettle();
      expect(find.text('小小画板'), findsOneWidget);
      expect(audio.playingId.value, isNull);
      expect(learning.learned.toSet(), before);
      await t.tap(find.byType(BackButton));
      await t.pumpAndSettle();
      Get.toNamed('/math/drawing');
      await t.pumpAndSettle();
      expect(find.text('小小画板'), findsOneWidget);
      expect(learning.learned.toSet(), before);
    },
  );
  testWidgets('draw, clear confirmation, undo and draft survive reentry', (
    t,
  ) async {
    final prefs = MemoryPreferences();
    Future<void> open() async {
      await t.pumpWidget(
        MaterialApp(home: DrawingView(draftStore: DrawingDraftStore(prefs))),
      );
      await t.pumpAndSettle();
    }

    await open();
    final canvas = find.byKey(const ValueKey('drawing-canvas'));
    await t.drag(canvas, const Offset(50, 20));
    await t.pumpAndSettle();
    expect(
      DrawingDocument.decode(prefs.values['drawing_draft_v1']!).strokes.length,
      1,
    );
    await t.ensureVisible(find.text('清空'));
    await t.pumpAndSettle();
    await t.tap(find.text('清空'));
    await t.pumpAndSettle();
    expect(find.text('清空当前画面？可以在本次打开期间撤销。'), findsOneWidget);
    await t.tap(find.text('确认清空'));
    await t.pumpAndSettle();
    expect(
      DrawingDocument.decode(prefs.values['drawing_draft_v1']!).strokes,
      isEmpty,
    );
    await t.tap(find.text('撤销'));
    await t.pumpAndSettle();
    expect(
      DrawingDocument.decode(prefs.values['drawing_draft_v1']!).strokes.length,
      1,
    );
    await t.pumpWidget(const SizedBox());
    await open();
    expect(find.text('已保存到本机'), findsOneWidget);
    expect(
      t
          .widget<OutlinedButton>(find.widgetWithText(OutlinedButton, '撤销'))
          .onPressed,
      isNull,
    );
  });
  testWidgets('320 wide 200 percent tools wrap and outside scroll works', (
    t,
  ) async {
    t.view.physicalSize = const Size(320, 640);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: DrawingView(draftStore: DrawingDraftStore(MemoryPreferences())),
      ),
    );
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
    final position = t.state<ScrollableState>(find.byType(Scrollable)).position;
    final before = position.pixels;
    await t.drag(find.text('选一种颜色，画出你的发现。'), const Offset(0, -200));
    await t.pumpAndSettle();
    expect(position.pixels, greaterThan(before));
    expect(t.takeException(), isNull);
  });
  testWidgets('corrupt load does not overwrite until an actual edit', (
    t,
  ) async {
    final prefs = MemoryPreferences()..values['drawing_draft_v1'] = 'bad';
    await t.pumpWidget(
      MaterialApp(home: DrawingView(draftStore: DrawingDraftStore(prefs))),
    );
    await t.pumpAndSettle();
    expect(find.text('草稿暂时无法读取，可以重试或重新绘画。'), findsOneWidget);
    expect(prefs.values['drawing_draft_v1'], 'bad');
    await t.tap(find.text('红'));
    await t.tap(find.text('粗'));
    await t.pumpAndSettle();
    expect(prefs.values['drawing_draft_v1'], 'bad');
    expect(find.text('重试读取'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('drawing-canvas')));
    await t.pumpAndSettle();
    expect(
      DrawingDocument.decode(prefs.values['drawing_draft_v1']!).strokes.length,
      1,
    );
  });
}
