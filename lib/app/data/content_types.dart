enum ContentKind {
  pinyin,
  hanzi,
  alphabet,
  cognition,
  reading,
  number,
  pictureBook,
  dialogue,
}

enum ActivityKind {
  count,
  addition,
  subtraction,
  hundred,
  additionTable,
  subtractionTable,
  multiplicationTable,
  divisionTable,
  drawing,
}

ActivityKind? parseActivityKind(Map<String, dynamic> category) {
  final value = category['activityKind'];
  if (value == null) return null;
  for (final kind in ActivityKind.values) {
    if (kind.name == value) return kind;
  }
  throw const FormatException('Unknown activity kind');
}

enum AudioQuality { unavailable, demo, verified }

class LearningGroup {
  const LearningGroup(this.id, this.title, this.order);
  final String id, title;
  final int order;
}

ContentKind? contentKind(Map<String, dynamic> category) {
  final explicit = category['kind'];
  if (explicit != null) {
    return ContentKind.values.firstWhere(
      (e) => e.name == explicit,
      orElse: () => throw const FormatException('Unknown content kind'),
    );
  }
  return switch (category['id']) {
    'pinyin' => ContentKind.pinyin,
    'chinese' => ContentKind.hanzi,
    'animals' => ContentKind.cognition,
    _ => null,
  };
}

String normalizeSearch(String text) {
  const substitutions = {
    'ɑ': 'a',
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
    'ü': 'v',
    'ǖ': 'v',
    'ǘ': 'v',
    'ǚ': 'v',
    'ǜ': 'v',
  };
  return text
      .toLowerCase()
      .replaceAll('u:', 'v')
      .split('')
      .map((c) => substitutions[c] ?? c)
      .join()
      .trim();
}

bool safeAsset(String path, String directory) =>
    path.startsWith('$directory/') &&
    !path.contains('..') &&
    RegExp(r'^[a-zA-Z0-9_./-]+$').hasMatch(path) &&
    !path.contains('//');

/// Pure Dart validation shared by the app loader and the build-time audit.
void validateContentData(Map<String, dynamic> data) {
  if (data['version'] != 1 ||
      data['categories'] is! List ||
      data['items'] is! List) {
    throw const FormatException('Unsupported content document');
  }
  final categories = <String, Map<String, dynamic>>{};
  for (final raw in data['categories'] as List) {
    final c = raw as Map<String, dynamic>;
    final id = c['id'] as String;
    if (categories.containsKey(id)) {
      throw const FormatException('Duplicate category');
    }
    categories[id] = c;
    final kind = contentKind(c);
    if ((kind == ContentKind.pictureBook && id != 'books') ||
        (kind == ContentKind.dialogue && id != 'dialog')) {
      throw const FormatException('Invalid story category');
    }
    final activity = parseActivityKind(c);
    if (kind != null && activity != null) {
      throw const FormatException('Ambiguous category capability');
    }
    const activityIds = {
      'count': 'count',
      'plus-block': 'addition',
      'minus-block': 'subtraction',
      'hundred': 'hundred',
      'plus': 'additionTable',
      'minus': 'subtractionTable',
      'times': 'multiplicationTable',
      'divide': 'divisionTable',
      'drawing': 'drawing',
    };
    if ((activity != null && activityIds[id] != activity.name) ||
        (kind == ContentKind.number && id != 'numbers')) {
      throw const FormatException('Invalid category capability');
    }
    if (c['available'] == true && kind == null && activity == null) {
      throw const FormatException('Available category needs kind');
    }
    if ((c['pinyin'] as List).length != (c['name'] as String).runes.length ||
        c['tab'] is! int ||
        (c['tab'] as int) < 0 ||
        (c['tab'] as int) > 3) {
      throw const FormatException('Invalid category');
    }
    final groups = (c['groups'] as List? ?? []).cast<Map<String, dynamic>>();
    if (groups.map((g) => g['id']).toSet().length != groups.length) {
      throw const FormatException('Duplicate group');
    }
  }
  final ids = <String>{};
  for (final raw in data['items'] as List) {
    final item = raw as Map<String, dynamic>;
    if (!ids.add(item['id'] as String)) {
      throw const FormatException('Duplicate item');
    }
    final category = categories[item['categoryId']];
    if (category == null || contentKind(category) == null) {
      throw const FormatException('Unknown category');
    }
    final kind = contentKind(category)!;
    final story = item['storyId'];
    final cover = item['coverSceneId'];
    final isStory =
        kind == ContentKind.pictureBook || kind == ContentKind.dialogue;
    if ((isStory && (story != item['id'] || story is! String)) ||
        (!isStory && (story != null || cover != null)) ||
        (kind == ContentKind.pictureBook &&
            (cover is! String ||
                !RegExp(r'^(share|tidy|feelings)-01$').hasMatch(cover))) ||
        (kind == ContentKind.dialogue && cover != null)) {
      throw const FormatException('Invalid story reference');
    }
    final number = item['numberValue'];
    if ((kind == ContentKind.number &&
            (number is! int ||
                number < 0 ||
                number > 10 ||
                item['id'] != 'number-$number')) ||
        (kind != ContentKind.number && number != null)) {
      throw const FormatException('Invalid number value');
    }
    final pinyin = item['pinyin'] as List;
    final text = item['text'] as String;
    if (text.isEmpty ||
        ((kind == ContentKind.hanzi ||
                kind == ContentKind.cognition ||
                kind == ContentKind.number ||
                isStory ||
                pinyin.isNotEmpty) &&
            pinyin.length != text.runes.length)) {
      throw const FormatException('Invalid annotations');
    }
    if ((kind == ContentKind.number || isStory) &&
        !pinyin.every((p) => p is String && p.trim().isNotEmpty)) {
      throw const FormatException('Missing number pronunciation');
    }
    final group = item['groupId'];
    final reading = item['readingId'];
    final readingLine = item['readingLineId'];
    if (kind == ContentKind.reading &&
        (reading is! String ||
            !RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$').hasMatch(reading))) {
      throw const FormatException('Invalid reading reference');
    }
    if ((kind != ContentKind.reading &&
            (reading != null || readingLine != null)) ||
        (readingLine != null &&
            (readingLine is! String ||
                !readingLine.startsWith('$reading-line-')))) {
      throw const FormatException('Invalid reading line reference');
    }
    final groups = category['groups'] as List? ?? [];
    if (group != null && !groups.any((g) => g['id'] == group)) {
      throw const FormatException('Unknown group');
    }
    if (groups.isNotEmpty && group == null) {
      throw const FormatException('Missing group');
    }
    final audio = item['audio'] as String?;
    final quality =
        item['audioQuality'] ?? (audio == null ? 'unavailable' : 'demo');
    if (!AudioQuality.values.any((q) => q.name == quality) ||
        ((quality == 'unavailable') != (audio == null)) ||
        (audio != null &&
            (!safeAsset(audio, 'audio') || !audio.endsWith('.wav')))) {
      throw const FormatException('Invalid audio resource');
    }
    final image = item['imageAsset'] as String?;
    final stroke = item['strokeAsset'] as String?;
    if (stroke != null &&
        (!safeAsset(stroke, 'assets/strokes') || !stroke.endsWith('.json'))) {
      throw const FormatException('Invalid stroke path');
    }
    for (final word in item['words'] as List? ?? []) {
      if (word['text'] is! String ||
          (word['text'] as String).isEmpty ||
          word['pinyin'] is! List ||
          (word['pinyin'] as List).length !=
              (word['text'] as String).runes.length ||
          !(word['pinyin'] as List).every(
            (p) => p is String && p.trim().isNotEmpty,
          )) {
        throw const FormatException('Invalid word annotations');
      }
    }
    if (image != null && !safeAsset(image, 'images')) {
      throw const FormatException('Invalid image path');
    }
  }
}
