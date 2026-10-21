import 'dart:convert';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class PreferenceStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> remove(String key);
}

class DevicePreferences implements PreferenceStore {
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();
  @override
  Future<String?> read(String key) => _preferences.getString(key);
  @override
  Future<void> write(String key, String value) =>
      _preferences.setString(key, value);
  @override
  Future<void> remove(String key) => _preferences.remove(key);
}

/// Updates are committed in order and published only after a successful write.
class LearningStore extends GetxController {
  LearningStore._(this._preferences);
  final PreferenceStore _preferences;
  static const _key = 'learning_state_v1';
  final showPinyin = true.obs;
  final themeIndex = 0.obs;
  final order = 'grade'.obs;
  final learned = <String>{}.obs;
  final cursors = <String, String>{}.obs;
  String? loadWarning;
  Future<void> _tail = Future.value();

  static Future<LearningStore> open(PreferenceStore preferences) async {
    final store = LearningStore._(preferences);
    try {
      final raw = await preferences.read(_key);
      if (raw == null) return store;
      final data = jsonDecode(raw) as Map<String, dynamic>;
      if (data['version'] != 1) throw const FormatException('state version');
      final theme = data['theme'] as int;
      final sort = data['order'] as String;
      if (theme < 0 ||
          theme > 2 ||
          !['grade', 'strokes', 'pinyin'].contains(sort)) {
        throw const FormatException('settings');
      }
      final ids = (data['learned'] as List).cast<String>().toSet();
      final cursors = Map<String, String>.from(data['cursors'] as Map);
      final pinyin = data['showPinyin'] as bool;
      store.showPinyin.value = pinyin;
      store.themeIndex.value = theme;
      store.order.value = sort;
      store.learned.addAll(ids);
      store.cursors.addAll(cursors);
    } catch (_) {
      store.loadWarning = '本地记录无法读取，已使用默认设置。';
    }
    return store;
  }

  Map<String, dynamic> _snapshot() => {
    'version': 1,
    'showPinyin': showPinyin.value,
    'theme': themeIndex.value,
    'order': order.value,
    'learned': learned.toList(),
    'cursors': Map.of(cursors),
  };

  Future<void> _update(void Function(Map<String, dynamic>) change) {
    final operation = _tail.then((_) async {
      final state = _snapshot();
      change(state);
      await _preferences.write(_key, jsonEncode(state));
      showPinyin.value = state['showPinyin'] as bool;
      themeIndex.value = state['theme'] as int;
      order.value = state['order'] as String;
      learned.assignAll((state['learned'] as List).cast<String>());
      cursors.assignAll(Map<String, String>.from(state['cursors'] as Map));
    });
    _tail = operation.then<void>(
      (_) {},
      onError: (Object error, StackTrace stack) {},
    );
    return operation;
  }

  Future<void> setLearned(String id, bool value) => _update((state) {
    final ids = (state['learned'] as List).cast<String>().toSet();
    value ? ids.add(id) : ids.remove(id);
    state['learned'] = ids.toList();
  });
  Future<void> setCursor(String category, String id) =>
      setCursors({category: id});
  Future<void> setCursors(Map<String, String> updates) {
    final snapshot = Map<String, String>.of(updates);
    return _update((state) {
      (state['cursors'] as Map).addAll(snapshot);
    });
  }

  Future<void> setShowPinyin(bool value) =>
      _update((state) => state['showPinyin'] = value);
  Future<void> setTheme(int value) {
    if (value < 0 || value > 2) return Future.error(ArgumentError.value(value));
    return _update((state) => state['theme'] = value);
  }

  Future<void> setOrder(String value) {
    if (!['grade', 'strokes', 'pinyin'].contains(value)) {
      return Future.error(ArgumentError.value(value));
    }
    return _update((state) => state['order'] = value);
  }

  Future<void> clearCache() => _preferences.remove('download_cache');
}
