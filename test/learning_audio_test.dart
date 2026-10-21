import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:baby_learn_house/app/services/learning_audio.dart';

class TestAudioBackend implements AudioBackend {
  final events = <String>[];
  Completer<void>? nextStop;
  bool failPlay = false;
  @override
  Stream<AudioCompletion> get completed => const Stream.empty();
  @override
  Future<void> play(String path, {required int requestId}) async {
    events.add('play:$path');
    if (failPlay) throw StateError('decoder');
  }

  @override
  Future<void> stop() async {
    events.add('stop');
    final gate = nextStop;
    nextStop = null;
    await gate?.future;
  }

  @override
  Future<void> dispose() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'only newest pending request plays and stop invalidates queued requests',
    () async {
      final backend = TestAudioBackend();
      final audio = LearningAudio(backend);
      final gate = Completer<void>();
      backend.nextStop = gate;
      final first = audio.play('audio/first.wav');
      await Future<void>.delayed(Duration.zero);
      final second = audio.play('audio/second.wav');
      gate.complete();
      await Future.wait([first, second]);
      expect(backend.events.where((e) => e.startsWith('play:')), [
        'play:audio/second.wav',
      ]);
      expect(audio.playingId.value, 'audio/second.wav');
      final third = audio.play('audio/third.wav');
      final stop = audio.stop();
      await Future.wait([third, stop]);
      expect(backend.events, isNot(contains('play:audio/third.wav')));
      expect(audio.playingId.value, isNull);
      await audio.shutdown();
    },
  );
  test('failed playback is visible and does not prevent retry', () async {
    final backend = TestAudioBackend()..failPlay = true;
    final audio = LearningAudio(backend);
    await audio.play('audio/a.wav');
    expect(audio.error.value, isNotNull);
    expect(audio.playingId.value, isNull);
    backend.failPlay = false;
    await audio.play('audio/a.wav');
    expect(audio.error.value, isNull);
    expect(audio.playingId.value, 'audio/a.wav');
    await audio.shutdown();
  });
}
