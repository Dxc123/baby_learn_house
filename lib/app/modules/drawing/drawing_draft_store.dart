import 'package:flutter/foundation.dart';
import '../../services/learning_store.dart';
import 'drawing_document.dart';

enum DrawingSavePhase { saved, saving, failed }

class DrawingSaveStatus {
  const DrawingSaveStatus(this.phase, this.revision);
  final DrawingSavePhase phase;
  final int revision;
}

class DrawingDraftStore {
  DrawingDraftStore(this.preferences);
  final PreferenceStore preferences;
  final status = ValueNotifier(
    const DrawingSaveStatus(DrawingSavePhase.saved, 0),
  );
  ({String raw, int revision})? _pending, _latest;
  Future<void>? _worker;
  Object? _error;
  bool _disposed = false;
  Future<DrawingDocument?> load() async {
    final raw = await preferences.read('drawing_draft_v1');
    return raw == null ? null : DrawingDocument.decode(raw);
  }

  void _publish(DrawingSavePhase phase, int revision) {
    if (!_disposed) status.value = DrawingSaveStatus(phase, revision);
  }

  void submit(DrawingDocument document, int revision) {
    _latest = _pending = (raw: document.encode(), revision: revision);
    _error = null;
    _publish(DrawingSavePhase.saving, revision);
    _start();
  }

  void _start() {
    _worker ??= _drain();
  }

  Future<void> _drain() async {
    // Yield so _worker is assigned before a synchronous storage failure.
    await Future<void>.value();
    while (_pending != null) {
      final next = _pending!;
      _pending = null;
      try {
        await preferences.write('drawing_draft_v1', next.raw);
      } catch (e) {
        if (_pending != null) continue;
        _error = e;
        _publish(DrawingSavePhase.failed, _latest!.revision);
        break;
      }
      if (_pending == null && next.revision == _latest?.revision) {
        _error = null;
        _publish(DrawingSavePhase.saved, next.revision);
      }
    }
    _worker = null;
  }

  Future<void> flush() async {
    while (_worker != null) {
      await _worker;
    }
    if (_error != null) throw _error!;
  }

  Future<void> retry() async {
    if (_worker == null && _latest != null && _error != null) {
      _pending = _latest;
      _error = null;
      _publish(DrawingSavePhase.saving, _latest!.revision);
      _start();
    }
    await flush();
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    status.dispose();
  }
}
