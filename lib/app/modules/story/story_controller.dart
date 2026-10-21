import 'package:get/get.dart';
import '../../data/story_types.dart';
import '../../services/learning_store.dart';

class StoryController extends GetxController {
  StoryController(this.document, this.store, {required this.itemId}) {
    currentUnitId.value = document.units.first.id;
  }
  final StoryDocument document;
  final LearningStore store;
  final String itemId;
  final currentUnitId = ''.obs;
  final warning = RxnString();
  final saving = false.obs;
  bool _closed = false;
  int _operation = 0;
  StoryUnit get currentUnit =>
      document.units.firstWhere((u) => u.id == currentUnitId.value);
  Future<void> open({String? requestedUnitId}) async {
    final request = requestedUnitId ?? store.cursors['story:${document.id}'];
    final valid = document.units.any((u) => u.id == request);
    final invalid = request != null && !valid;
    await selectUnit(valid ? request! : document.units.first.id);
    if (!_closed && invalid) warning.value = '阅读位置已变化，已从开头开始。';
  }

  Future<void> selectUnit(String id) async {
    if (_closed) return;
    if (!document.units.any((u) => u.id == id)) throw ArgumentError.value(id);
    final operation = ++_operation;
    currentUnitId.value = id;
    warning.value = null;
    try {
      await store.setCursors({
        document.categoryId: itemId,
        'story:${document.id}': id,
      });
    } catch (_) {
      if (!_closed && operation == _operation) {
        warning.value = '这次阅读位置尚未保存，可继续阅读，稍后重试。';
      }
    }
  }

  Future<void> markLearned() async {
    if (_closed || saving.value) return;
    saving.value = true;
    try {
      await store.setLearned(itemId, !store.learned.contains(itemId));
    } catch (_) {
      if (!_closed) warning.value = '这次学会标记尚未保存，请稍后重试。';
    } finally {
      if (!_closed) saving.value = false;
    }
  }

  @override
  void onClose() {
    _closed = true;
    _operation++;
    super.onClose();
  }
}
