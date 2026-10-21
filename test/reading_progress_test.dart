import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baby_learn_house/app/data/reading_types.dart';
import 'package:baby_learn_house/app/modules/reader/reading_controller.dart';
import 'package:baby_learn_house/app/services/learning_audio.dart';
import 'package:baby_learn_house/app/services/learning_store.dart';
import 'reading_fixtures.dart';
import 'reading_audio_test.dart' show QueueBackend, flush;
import 'learning_store_test.dart' show MemoryPreferences;

class GatedPreferences extends MemoryPreferences {
  Completer<void>? gate;
  @override
  Future<void> write(String key, String value) async {
    final pending = gate;
    gate = null;
    await pending?.future;
    await super.write(key, value);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'external route/background cancellation also invalidates a pending line request',
    () async {
      for (final background in [false, true]) {
        final prefs = GatedPreferences();
        final store = await LearningStore.open(prefs);
        final backend = QueueBackend();
        final audio = LearningAudio(backend);
        final raw = sampleBody()['passages'][0];
        raw['lines'][0]['audio'] = 'audio/reading/poetry-test-line-01.wav';
        final p = ReadingPassage.fromJson(raw);
        final c = ReadingController(
          p,
          store,
          audio,
          wholeItemId: 'poetry-test',
        );
        final gate = Completer<void>();
        prefs.gate = gate;
        final pending = c.playLine(p.lines.first.id);
        await flush();
        if (background) {
          audio.didChangeAppLifecycleState(AppLifecycleState.paused);
        } else {
          await audio.stop();
        }
        gate.complete();
        await pending;
        expect(
          backend.requests,
          isEmpty,
          reason: 'cancelled by ${background ? 'background' : 'route'}',
        );
        c.onClose();
        await audio.shutdown();
      }
    },
  );
  test(
    'stop cancels a line play still waiting for cursor persistence',
    () async {
      final prefs = GatedPreferences();
      final store = await LearningStore.open(prefs);
      final backend = QueueBackend();
      final audio = LearningAudio(backend);
      final raw = sampleBody()['passages'][0];
      raw['lines'][0]['audio'] = 'audio/reading/poetry-test-line-01.wav';
      final p = ReadingPassage.fromJson(raw);
      final c = ReadingController(p, store, audio, wholeItemId: 'poetry-test');
      final gate = Completer<void>();
      prefs.gate = gate;
      final pending = c.playLine(p.lines.first.id);
      await flush();
      await c.stop();
      gate.complete();
      await pending;
      expect(backend.requests, isEmpty);
      c.onClose();
      await audio.shutdown();
    },
  );
  test('manual position saves, automatic playback never learns', () async {
    final prefs = MemoryPreferences();
    final store = await LearningStore.open(prefs);
    final audio = LearningAudio(QueueBackend());
    final p = ReadingPassage.fromJson(sampleBody()['passages'][0]);
    final c = ReadingController(p, store, audio, wholeItemId: 'poetry-test');
    await c.open(requestedLineId: p.lines.last.id);
    expect(c.currentLineId.value, p.lines.last.id);
    expect(store.cursors['reader:${p.id}'], p.lines.last.id);
    expect(store.learned, isEmpty);
    await c.toggleLearned();
    expect(store.learned, contains('poetry-test'));
    c.onClose();
    await audio.shutdown();
    expect(
      (await LearningStore.open(prefs)).cursors['reader:${p.id}'],
      p.lines.last.id,
    );
  });
  test(
    'invalid line falls back and storage failure does not block reading',
    () async {
      final prefs = MemoryPreferences();
      final store = await LearningStore.open(prefs);
      final audio = LearningAudio(QueueBackend());
      final p = ReadingPassage.fromJson(sampleBody()['passages'][0]);
      final c = ReadingController(p, store, audio, wholeItemId: 'poetry-test');
      await c.open(requestedLineId: 'deleted');
      expect(c.currentLineId.value, p.lines.first.id);
      expect(c.warning.value, isNotNull);
      prefs.failNext = true;
      await c.selectLine(p.lines.last.id);
      expect(c.currentLineId.value, p.lines.last.id);
      expect(store.cursors['reader:${p.id}'], p.lines.first.id);
      c.onClose();
      await audio.shutdown();
    },
  );
}
