import 'dart:convert';
import 'package:flutter/services.dart';
import 'content_types.dart';
export 'content_types.dart';

class LearningCategory {
  LearningCategory.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      tab = json['tab'] as int,
      name = json['name'] as String,
      pinyin = List<String>.from(json['pinyin'] as List),
      symbol = json['symbol'] as String,
      description = json['description'] as String,
      available = json['available'] == true,
      kind = contentKind(json),
      activityKind = parseActivityKind(json),
      groups = List.unmodifiable(
        (json['groups'] as List? ?? []).map(
          (g) => LearningGroup(
            g['id'] as String,
            g['title'] as String,
            g['order'] as int,
          ),
        ),
      );
  final String id, name, symbol, description;
  final List<String> pinyin;
  final int tab;
  final bool available;
  final ContentKind? kind;
  final ActivityKind? activityKind;
  final List<LearningGroup> groups;
}

class AnnotatedWord {
  const AnnotatedWord(this.text, this.pinyin);
  final String text;
  final List<String> pinyin;
}

class LearningItem {
  LearningItem.fromJson(Map<String, dynamic> json, {required this.kind})
    : id = json['id'] as String,
      categoryId = json['categoryId'] as String,
      text = json['text'] as String,
      pinyin = List<String>.from(json['pinyin'] as List),
      symbol = json['symbol'] as String,
      audio = json['audio'] as String?,
      groupId = json['groupId'] as String?,
      sortKey = json['sortKey'] as String?,
      imageAsset = json['imageAsset'] as String?,
      strokeAsset = json['strokeAsset'] as String?,
      numberValue = json['numberValue'] as int?,
      storyId = json['storyId'] as String?,
      coverSceneId = json['coverSceneId'] as String?,
      readingId = json['readingId'] as String?,
      readingLineId = json['readingLineId'] as String?,
      words = List.unmodifiable(
        (json['words'] as List? ?? []).map(
          (w) => AnnotatedWord(
            w['text'] as String,
            List<String>.from(w['pinyin'] as List),
          ),
        ),
      ),
      audioQuality = AudioQuality.values.byName(
        json['audioQuality'] as String? ??
            (json['audio'] == null ? 'unavailable' : 'demo'),
      ),
      note = json['note'] as String,
      example = json['example'] as String,
      strokes = json['strokes'] as int? ?? 0;
  final String id, categoryId, text, symbol, note, example;
  final String? audio, groupId, sortKey, imageAsset;
  final String? strokeAsset;
  final String? readingId, readingLineId;
  final String? storyId, coverSceneId;
  final List<AnnotatedWord> words;
  final ContentKind kind;
  final int? numberValue;
  final AudioQuality audioQuality;
  final List<String> pinyin;
  final int strokes;
}

class ContentRepository {
  ContentRepository._(this.categories, this.items, this.raw);
  final Map<String, dynamic> raw;
  String? get readingRevision => raw['readingRevision'] as String?;
  String? get storyRevision => raw['storyRevision'] as String?;
  final List<LearningCategory> categories;
  final List<LearningItem> items;
  static Future<ContentRepository> load(AssetBundle bundle) async {
    final data =
        jsonDecode(await bundle.loadString('assets/data/content.json'))
            as Map<String, dynamic>;
    return ContentRepository.fromJson(data);
  }

  factory ContentRepository.fromJson(Map<String, dynamic> data) {
    validateContentData(data);
    final categories = (data['categories'] as List)
        .map((e) => LearningCategory.fromJson(e as Map<String, dynamic>))
        .toList();
    final items = (data['items'] as List)
        .map(
          (e) => LearningItem.fromJson(
            e as Map<String, dynamic>,
            kind: categories.firstWhere((c) => c.id == e['categoryId']).kind!,
          ),
        )
        .toList();
    return ContentRepository._(
      List.unmodifiable(categories),
      List.unmodifiable(items),
      data,
    );
  }

  LearningCategory category(String id) =>
      categories.firstWhere((e) => e.id == id);
  List<LearningItem> itemsFor(String categoryId) =>
      items.where((e) => e.categoryId == categoryId).toList();
  List<LearningGroup> groupsFor(String categoryId) =>
      [...category(categoryId).groups]
        ..sort((a, b) => a.order.compareTo(b.order));
  LearningItem? resumeItem(
    String categoryId, {
    String? groupId,
    String order = 'grade',
    String? cursor,
    Set<String> learned = const {},
  }) {
    final candidates = filteredItems(
      categoryId,
      groupId: groupId,
      order: order,
    );
    if (candidates.isEmpty) return null;
    for (final item in candidates) {
      if (item.id == cursor) return item;
    }
    for (final item in candidates) {
      if (!learned.contains(item.id)) return item;
    }
    return candidates.first;
  }

  List<LearningItem> filteredItems(
    String categoryId, {
    String? groupId,
    String query = '',
    String order = 'grade',
  }) {
    final validGroup = groupsFor(categoryId).any((g) => g.id == groupId)
        ? groupId
        : null;
    final needle = normalizeSearch(query);
    return sortedItems(categoryId, order)
        .where(
          (item) =>
              (validGroup == null || item.groupId == validGroup) &&
              (normalizeSearch(item.text).contains(needle) ||
                  (item.numberValue?.toString().contains(needle) ?? false) ||
                  normalizeSearch(item.pinyin.join(' ')).contains(needle)),
        )
        .toList();
  }

  List<LearningItem> sortedItems(String categoryId, String order) {
    final result = itemsFor(categoryId);
    if (category(categoryId).kind == ContentKind.number) {
      return result..sort((a, b) => a.numberValue!.compareTo(b.numberValue!));
    }
    if (category(categoryId).kind != ContentKind.hanzi || order == 'grade') {
      final positions = {
        for (var i = 0; i < result.length; i++) result[i].id: i,
      };
      final groupOrder = {
        for (final group in groupsFor(categoryId)) group.id: group.order,
      };
      result.sort((a, b) {
        final group = (groupOrder[a.groupId] ?? 0).compareTo(
          groupOrder[b.groupId] ?? 0,
        );
        if (group != 0) return group;
        final left = a.sortKey ?? positions[a.id]!.toString().padLeft(8, '0');
        final right = b.sortKey ?? positions[b.id]!.toString().padLeft(8, '0');
        final rank = left.compareTo(right);
        return rank == 0 ? a.id.compareTo(b.id) : rank;
      });
      return result;
    }
    if (categoryId == 'chinese' && order == 'strokes') {
      result.sort((a, b) {
        final strokes = a.strokes.compareTo(b.strokes);
        return strokes == 0 ? a.id.compareTo(b.id) : strokes;
      });
    } else if (categoryId == 'chinese' && order == 'pinyin') {
      const tones = {
        'ā': 'a',
        'á': 'a',
        'ǎ': 'a',
        'à': 'a',
        'ē': 'e',
        'é': 'e',
        'ě': 'e',
        'è': 'e',
        'ī': 'i',
        'í': 'i',
        'ǐ': 'i',
        'ì': 'i',
        'ō': 'o',
        'ó': 'o',
        'ǒ': 'o',
        'ò': 'o',
        'ū': 'u',
        'ú': 'u',
        'ǔ': 'u',
        'ù': 'u',
        'ǖ': 'v',
        'ǘ': 'v',
        'ǚ': 'v',
        'ǜ': 'v',
      };
      String plain(String text) =>
          text.split('').map((c) => tones[c] ?? c).join();
      result.sort(
        (a, b) => plain(a.pinyin.join()).compareTo(plain(b.pinyin.join())),
      );
    }
    return result;
  }
}
