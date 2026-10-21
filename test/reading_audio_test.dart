import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baby_learn_house/app/services/learning_audio.dart';

class QueueBackend implements AudioBackend {
  final events = StreamController<AudioCompletion>.broadcast(sync: true);
  final requests = <(int, String)>[];
  bool fail = false;
  Completer<void>? gate;
  @override
  Stream<AudioCompletion> get completed => events.stream;
  @override
  Future<void> play(String path, {required int requestId}) async {
    requests.add((requestId, path));
    await gate?.future;
    if (fail) throw StateError('decoder');
  }

  @override
  Future<void> stop() async {}
  @override
  Future<void> dispose() async {
    await events.close();
  }

  void finish(int id) => events.add(AudioCompletion(id));
}

Future<void> flush() async {
  for (var i = 0; i < 12; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('an old pending decoder error cannot clear newer playback', () async {
    final b = QueueBackend();
    final a = LearningAudio(b);
    final gate = Completer<void>();
    b.gate = gate;
    final first = a.play('audio/old.wav');
    await flush();
    final next = a.playSequence([const AudioCue('new', 'audio/new.wav')]);
    b.gate = null;
    gate.completeError(StateError('old decoder failed'));
    await Future.wait([first, next]);
    expect(a.playingId.value, 'audio/new.wav');
    expect(a.error.value, isNull);
    expect(a.sequencePlaying.value, isTrue);
    await a.shutdown();
  });
  test(
    'completion IDs isolate sequences, single playback and cancellation',
    () async {
      final b = QueueBackend();
      final a = LearningAudio(b);
      await a.playSequence([
        const AudioCue('one', 'audio/one.wav'),
        const AudioCue('two', 'audio/two.wav'),
      ]);
      final first = b.requests.last.$1;
      b.finish(first);
      await flush();
      expect(a.activeCueId.value, 'two');
      b.finish(first);
      await flush();
      expect(b.requests.length, 2);
      await a.play('audio/other.wav');
      b.finish(b.requests[1].$1);
      await flush();
      expect(a.playingId.value, 'audio/other.wav');
      await a.playSequence([
        const AudioCue('one', 'audio/one.wav'),
        const AudioCue('two', 'audio/two.wav'),
      ]);
      final old = b.requests.last.$1;
      a.didChangeAppLifecycleState(AppLifecycleState.paused);
      b.finish(old);
      await flush();
      expect(a.playingId.value, isNull);
      expect(a.sequencePlaying.value, isFalse);
      await a.shutdown();
    },
  );
  test(
    'missing and failing audio stop at current cue without skipping',
    () async {
      final b = QueueBackend();
      final a = LearningAudio(b);
      await a.playSequence([
        const AudioCue('one', 'audio/one.wav'),
        const AudioCue('missing', null),
        const AudioCue('three', 'audio/three.wav'),
      ]);
      b.finish(b.requests.last.$1);
      await flush();
      expect(a.activeCueId.value, 'missing');
      expect(a.error.value, contains('暂缺'));
      expect(b.requests.length, 1);
      b.fail = true;
      await a.playSequence([const AudioCue('retry', 'audio/retry.wav')]);
      expect(a.error.value, isNotNull);
      b.fail = false;
      await a.playSequence([const AudioCue('retry', 'audio/retry.wav')]);
      b.finish(b.requests.last.$1);
      await flush();
      expect(a.sequencePlaying.value, isFalse);
      await expectLater(a.playSequence([]), throwsArgumentError);
      await a.shutdown();
    },
  );
}
