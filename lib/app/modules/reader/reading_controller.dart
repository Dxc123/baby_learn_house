import 'dart:async';
import 'package:get/get.dart';
import '../../data/reading_types.dart';
import '../../services/learning_store.dart';
import '../../services/learning_audio.dart';

class ReadingController extends GetxController {
  ReadingController(this.passage, this.store, this.audio, {this.wholeItemId}) {
    currentLineId.value = passage.lines.first.id;
    _worker = ever(audio.activeCueId, (id) {
      if (!_closed && passage.lines.any((l) => l.id == id)) {
        currentLineId.value = id!;
      }
    });
  }
  final ReadingPassage passage;
  final LearningStore store;
  final LearningAudio audio;
  final String? wholeItemId;
  final currentLineId = ''.obs;
  final warning = RxnString();
  final saving = false.obs;
  late final Worker _worker;
  bool _closed = false;
  int _operation = 0;
  ReadingLine get currentLine =>
      passage.lines.firstWhere((l) => l.id == currentLineId.value);
  String get learnedId =>
      currentLine.learningItemId ?? wholeItemId ?? passage.id;
  Future<void> open({String? requestedLineId}) async {
    final requested = requestedLineId ?? store.cursors['reader:${passage.id}'];
    final id = passage.lines.any((l) => l.id == requested)
        ? requested!
        : passage.lines.first.id;
    if (requested != null && requested != id) {
      warning.value = '阅读位置已变化，已从第一句开始。';
    }
    await selectLine(id);
  }

  Future<void> selectLine(String id) async {
    if (_closed) return;
    if (!passage.lines.any((l) => l.id == id)) {
      throw ArgumentError('Unknown reading line');
    }
    final operation = ++_operation;
    unawaited(audio.stop());
    currentLineId.value = id;
    try {
      await store.setCursors({
        passage.categoryId: learnedId,
        'reader:${passage.id}': id,
      });
    } catch (_) {
      if (!_closed && operation == _operation) {
        warning.value = '这次阅读位置尚未保存，可继续阅读，稍后重试。';
      }
    }
  }

  Future<void> playLine(String id) async {
    final pending = selectLine(id);
    final operation = _operation;
    final audioGeneration = audio.requestGeneration;
    await pending;
    if (_closed ||
        operation != _operation ||
        audioGeneration != audio.requestGeneration ||
        currentLineId.value != id) {
      return;
    }
    final l = currentLine;
    await audio.playSequence([AudioCue(l.id, l.audio)]);
  }

  Future<void> playFromCurrent() async {
    if (_closed) return;
    ++_operation;
    final start = passage.lines.indexWhere((l) => l.id == currentLineId.value);
    await audio.playSequence([
      for (final l in passage.lines.skip(start)) AudioCue(l.id, l.audio),
    ]);
  }

  Future<void> stop() {
    ++_operation;
    return audio.stop();
  }

  Future<void> toggleLearned() async {
    if (_closed || saving.value) return;
    final id = learnedId;
    saving.value = true;
    try {
      await store.setLearned(id, !store.learned.contains(id));
    } catch (_) {
      if (!_closed) warning.value = '已学标记保存失败，请重试。';
    } finally {
      if (!_closed) saving.value = false;
    }
  }

  @override
  void onClose() {
    if (_closed) return;
    _closed = true;
    ++_operation;
    _worker.dispose();
    if (passage.lines.any((l) => l.id == audio.activeCueId.value)) {
      unawaited(audio.stop());
    }
    super.onClose();
  }
}
