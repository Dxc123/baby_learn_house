import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baby_learn_house/app/modules/drawing/drawing_view.dart';
import 'package:baby_learn_house/app/modules/drawing/drawing_painter.dart';
import 'package:baby_learn_house/app/modules/drawing/drawing_document.dart';
import 'package:baby_learn_house/app/modules/drawing/drawing_draft_store.dart';
import 'package:baby_learn_house/app/modules/drawing/drawing_png_service.dart';
import 'package:baby_learn_house/app/modules/drawing/drawing_share_service.dart';
import 'learning_store_test.dart' show MemoryPreferences;

class PendingRead extends MemoryPreferences {
  final gate = Completer<String?>();
  @override
  Future<String?> read(String key) => gate.future;
}

class PendingPng extends DrawingPngService {
  final gate = Completer<Uint8List>();
  DrawingDocument? captured;
  @override
  Future<Uint8List> encode(DrawingDocument snapshot) {
    captured = snapshot;
    return gate.future;
  }
}

class RecordingShare extends DrawingShareService {
  int calls = 0;
  @override
  Future<void> openPng(Uint8List png, {required Rect anchor}) async {
    calls++;
  }
}

DrawingPainter painter(WidgetTester t) =>
    t
            .widget<CustomPaint>(
              find.descendant(
                of: find.byKey(const ValueKey('drawing-canvas')),
                matching: find.byType(CustomPaint),
              ),
            )
            .painter!
        as DrawingPainter;
Future<void> paperVisible(WidgetTester t) async {
  await t.ensureVisible(find.byKey(const ValueKey('drawing-canvas')));
  await t.pumpAndSettle();
}

void main() {
  testWidgets('cancelling ignored second pointer preserves first stroke', (
    t,
  ) async {
    await t.pumpWidget(
      MaterialApp(
        home: DrawingView(draftStore: DrawingDraftStore(MemoryPreferences())),
      ),
    );
    await t.pumpAndSettle();
    final pos = t.getCenter(find.byKey(const ValueKey('drawing-canvas')));
    final a = await t.startGesture(pos, pointer: 1);
    final b = await t.startGesture(pos + const Offset(20, 20), pointer: 2);
    await b.cancel();
    await a.moveBy(const Offset(50, 0));
    await a.up();
    await t.pump();
    expect(painter(t).document.strokes.length, 1);
  });
  testWidgets('late load blocks editing and completion after dispose is safe', (
    t,
  ) async {
    final p = PendingRead();
    await t.pumpWidget(
      MaterialApp(home: DrawingView(draftStore: DrawingDraftStore(p))),
    );
    await t.pump();
    expect(find.byKey(const ValueKey('drawing-canvas')), findsNothing);
    await t.pumpWidget(const SizedBox());
    p.gate.complete(DrawingDocument().encode());
    await t.pump();
    expect(t.takeException(), isNull);
  });
  testWidgets(
    'canvas consumes drag, ignores second pointer, cancels background and resize',
    (t) async {
      final p = MemoryPreferences();
      await t.pumpWidget(
        MaterialApp(home: DrawingView(draftStore: DrawingDraftStore(p))),
      );
      await t.pumpAndSettle();
      final paper = find.byKey(const ValueKey('drawing-canvas'));
      final scroll = t.state<ScrollableState>(find.byType(Scrollable)).position;
      final before = scroll.pixels;
      await t.drag(paper, const Offset(0, -60));
      await t.pump();
      expect(scroll.pixels, before);
      expect(painter(t).document.strokes.length, 1);
      final pos = t.getCenter(paper);
      final a = await t.startGesture(pos, pointer: 1);
      final b = await t.startGesture(pos + const Offset(20, 20), pointer: 2);
      await b.moveBy(const Offset(30, 0));
      await b.up();
      await a.cancel();
      await t.pump();
      expect(painter(t).document.strokes.length, 1);
      final active = await t.startGesture(pos);
      await active.moveBy(const Offset(30, 0));
      await t.pump();
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await t.pump();
      await active.up();
      await t.pump();
      expect(painter(t).document.strokes.length, 1);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      final resize = await t.startGesture(pos);
      await t.pump();
      t.view.physicalSize = const Size(700, 900);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      await t.pumpAndSettle();
      await resize.up();
      await t.pump();
      expect(painter(t).document.strokes.length, 1);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'export takes one snapshot, rejects reentry and stops after disposal',
    (t) async {
      final p = MemoryPreferences();
      final png = PendingPng();
      final share = RecordingShare();
      await t.pumpWidget(
        MaterialApp(
          home: DrawingView(
            draftStore: DrawingDraftStore(p),
            pngService: png,
            shareService: share,
          ),
        ),
      );
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('drawing-canvas')));
      await t.pump();
      await t.ensureVisible(find.text('导出PNG'));
      await t.pumpAndSettle();
      await t.tap(find.text('导出PNG'));
      await t.pump();
      expect(png.captured!.strokes.length, 1);
      expect(find.text('处理中…'), findsOneWidget);
      await paperVisible(t);
      await t.tap(find.byKey(const ValueKey('drawing-canvas')));
      await t.pump();
      expect(png.captured!.strokes.length, 1);
      expect(painter(t).document.strokes.length, 2);
      await t.pumpWidget(const SizedBox());
      png.gate.complete(Uint8List(10));
      await t.pumpAndSettle();
      expect(share.calls, 0);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets('back flush failure stays for retry or explicitly leaves', (
    t,
  ) async {
    final p = MemoryPreferences()..failNext = true;
    await t.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => DrawingView(draftStore: DrawingDraftStore(p)),
              ),
            ),
            child: const Text('打开'),
          ),
        ),
      ),
    );
    await t.tap(find.text('打开'));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('drawing-canvas')));
    await t.pumpAndSettle();
    await t.tap(find.byType(BackButton));
    await t.pumpAndSettle();
    expect(find.text('画面尚未保存'), findsOneWidget);
    await t.tap(find.text('留在画板'));
    await t.pumpAndSettle();
    expect(find.text('小小画板'), findsOneWidget);
    await t.tap(find.byType(BackButton));
    await t.pumpAndSettle();
    await t.tap(find.text('仍然离开'));
    await t.pumpAndSettle();
    expect(find.text('打开'), findsOneWidget);
    expect(p.values['drawing_draft_v1'], isNull);
  });
}
