import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:baby_learn_house/app/modules/drawing/drawing_document.dart';
import 'package:baby_learn_house/app/modules/drawing/drawing_draft_store.dart';
import 'package:baby_learn_house/app/services/learning_store.dart';
import 'learning_store_test.dart' show MemoryPreferences;

class DelayedPreferences extends MemoryPreferences {
  final gate = Completer<void>();
  final writes = <String>[];
  @override
  Future<void> write(String key, String value) async {
    writes.add(value);
    if (writes.length == 1) await gate.future;
    return super.write(key, value);
  }
}

void main() {
  test('retry without further editing persists last failed snapshot', () async {
    final p = MemoryPreferences()..failNext = true;
    final s = DrawingDraftStore(p);
    s.submit(DrawingDocument(color: drawingColors[5]), 1);
    await expectLater(s.flush(), throwsStateError);
    await s.retry();
    expect(s.status.value.phase, DrawingSavePhase.saved);
    expect((await s.load())!.color, drawingColors[5]);
    s.dispose();
  });
  test(
    'load errors never overwrite stored draft; cache clear is isolated',
    () async {
      final p = MemoryPreferences();
      final s = DrawingDraftStore(p);
      expect(await s.load(), null);
      p.values['drawing_draft_v1'] = 'broken';
      await expectLater(s.load(), throwsFormatException);
      expect(p.values['drawing_draft_v1'], 'broken');
      final learning = await LearningStore.open(p);
      await learning.clearCache();
      expect(p.values['drawing_draft_v1'], 'broken');
      final old = p.values['learning_state_v1'];
      s.submit(DrawingDocument(), 1);
      await s.flush();
      expect(p.values['learning_state_v1'], old);
      expect((await s.load())!.strokes, isEmpty);
      s.dispose();
    },
  );
  test(
    'serial writes coalesce pending snapshots and only latest is saved',
    () async {
      final p = DelayedPreferences();
      final s = DrawingDraftStore(p);
      final savedRevisions = <int>[];
      s.status.addListener(() {
        if (s.status.value.phase == DrawingSavePhase.saved) {
          savedRevisions.add(s.status.value.revision);
        }
      });
      s.submit(DrawingDocument(), 1);
      await Future<void>.delayed(Duration.zero);
      expect(p.writes.length, 1);
      s.submit(DrawingDocument(color: drawingColors[1]), 2);
      s.submit(DrawingDocument(color: drawingColors[2]), 3);
      expect(s.status.value.revision, 3);
      expect(s.status.value.phase, DrawingSavePhase.saving);
      p.gate.complete();
      await s.flush();
      expect(p.writes.length, 2);
      expect(DrawingDocument.decode(p.writes.last).color, drawingColors[2]);
      expect(s.status.value.phase, DrawingSavePhase.saved);
      expect(s.status.value.revision, 3);
      expect(savedRevisions, [3]);
      s.dispose();
    },
  );
  test(
    'failure is explicit and retry writes latest; disposed store drains',
    () async {
      final p = MemoryPreferences()..failNext = true;
      final s = DrawingDraftStore(p);
      s.submit(DrawingDocument(), 1);
      await expectLater(s.flush(), throwsStateError);
      expect(s.status.value.phase, DrawingSavePhase.failed);
      s.submit(DrawingDocument(color: drawingColors[3]), 2);
      await s.retry();
      expect(s.status.value.revision, 2);
      s.submit(DrawingDocument(), 3);
      s.dispose();
      await s.flush();
      expect(
        DrawingDocument.decode(p.values['drawing_draft_v1']!).color,
        drawingColors.first,
      );
    },
  );
}
