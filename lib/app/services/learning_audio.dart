import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class AudioCompletion {
  const AudioCompletion(this.requestId, {this.error});
  final int requestId;
  final Object? error;
}

class AudioCue {
  const AudioCue(this.id, this.path);
  final String id;
  final String? path;
}

abstract interface class AudioBackend {
  Stream<AudioCompletion> get completed;
  Future<void> play(String path, {required int requestId});
  Future<void> stop();
  Future<void> dispose();
}

class AssetAudioBackend implements AudioBackend {
  final _events = StreamController<AudioCompletion>.broadcast();
  AudioPlayer? _player;
  StreamSubscription<void>? _subscription;
  bool _disposed = false;
  @override
  Stream<AudioCompletion> get completed => _events.stream;
  @override
  Future<void> play(String path, {required int requestId}) async {
    await stop();
    if (_disposed) return;
    final player = AudioPlayer();
    _player = player;
    _subscription = player.onPlayerComplete.listen(
      (_) {
        if (identical(_player, player) && !_disposed) {
          _events.add(AudioCompletion(requestId));
        }
      },
      onError: (Object error) {
        if (identical(_player, player) && !_disposed) {
          _events.add(AudioCompletion(requestId, error: error));
        }
      },
    );
    await player.play(AssetSource(path));
  }

  @override
  Future<void> stop() async {
    final player = _player;
    final subscription = _subscription;
    _player = null;
    _subscription = null;
    await subscription?.cancel();
    if (player != null) {
      try {
        await player.stop();
      } finally {
        await player.dispose();
      }
    }
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await stop();
    await _events.close();
  }
}

class LearningAudio extends GetxController with WidgetsBindingObserver {
  LearningAudio(this._backend) {
    _completion = _backend.completed.listen(_complete);
  }
  final AudioBackend _backend;
  late final StreamSubscription<AudioCompletion> _completion;
  final playingId = RxnString(), error = RxnString(), activeCueId = RxnString();
  final sequencePlaying = false.obs;
  Future<void> _tail = Future.value();
  int _session = 0, _serial = 0;
  int get requestGeneration => _session;
  int? _activeRequest;
  bool _disposed = false;
  List<AudioCue> _cues = const [];
  int _index = 0;
  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
  }

  bool _current(int session) => !_disposed && session == _session;
  Future<void> _enqueue(int session, Future<void> Function() action) {
    final pending = _tail.then((_) async {
      try {
        await action();
      } catch (_) {
        if (_current(session)) {
          _activeRequest = null;
          playingId.value = null;
          sequencePlaying.value = false;
          error.value = '声音暂时无法播放，请再试一次。';
          try {
            await _backend.stop();
          } catch (_) {}
        }
      }
    });
    _tail = pending;
    return pending;
  }

  int _reset() {
    _activeRequest = null;
    playingId.value = null;
    activeCueId.value = null;
    error.value = null;
    sequencePlaying.value = false;
    _cues = const [];
    _index = 0;
    return ++_session;
  }

  Future<void> play(String path) {
    if (_disposed) return Future.value();
    final session = _reset();
    return _enqueue(session, () async {
      await _backend.stop();
      if (!_current(session)) return;
      await _start(session, path);
    });
  }

  Future<void> playSequence(List<AudioCue> cues) {
    if (cues.isEmpty || cues.map((c) => c.id).toSet().length != cues.length) {
      return Future.error(ArgumentError('Empty or duplicate audio cues'));
    }
    if (_disposed) return Future.value();
    final session = _reset();
    _cues = List.unmodifiable(cues);
    activeCueId.value = _cues.first.id;
    sequencePlaying.value = true;
    return _enqueue(session, () async {
      await _backend.stop();
      if (_current(session)) await _startCue(session);
    });
  }

  Future<void> _start(int session, String path) async {
    final request = ++_serial;
    _activeRequest = request;
    await _backend.play(path, requestId: request);
    if (_current(session) && _activeRequest == request) playingId.value = path;
  }

  Future<void> _startCue(int session) async {
    if (!_current(session)) return;
    final cue = _cues[_index];
    activeCueId.value = cue.id;
    if (cue.path == null) {
      sequencePlaying.value = false;
      playingId.value = null;
      _activeRequest = null;
      error.value = '本句暂缺录音，可继续阅读。';
      return;
    }
    await _start(session, cue.path!);
  }

  void _complete(AudioCompletion event) {
    if (_disposed || event.requestId != _activeRequest) return;
    final session = _session;
    unawaited(
      _enqueue(session, () async {
        if (!_current(session) || event.requestId != _activeRequest) return;
        _activeRequest = null;
        playingId.value = null;
        if (event.error != null) throw StateError('Playback failed');
        if (!sequencePlaying.value) return;
        if (_index + 1 >= _cues.length) {
          sequencePlaying.value = false;
          return;
        }
        _index++;
        await _backend.stop();
        if (_current(session)) await _startCue(session);
      }),
    );
  }

  Future<void> stop() {
    final session = _reset();
    if (_disposed) return _tail;
    return _enqueue(session, _backend.stop);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) unawaited(stop());
  }

  Future<void> shutdown() async {
    if (_disposed) return;
    WidgetsBinding.instance.removeObserver(this);
    _reset();
    _disposed = true;
    await _tail;
    await _completion.cancel();
    try {
      await _backend.stop();
    } finally {
      await _backend.dispose();
    }
  }

  @override
  void onClose() {
    unawaited(shutdown());
    super.onClose();
  }
}

class AudioRouteObserver extends NavigatorObserver {
  AudioRouteObserver(this.audio);
  final LearningAudio audio;
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      unawaited(audio.stop());
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      unawaited(audio.stop());
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      unawaited(audio.stop());
}
