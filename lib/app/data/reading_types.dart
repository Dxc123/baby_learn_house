import 'content_types.dart';

const readingPunctuation = '，。！？；：、（）《》“”‘’—…·';
void validateAnnotations(String text, List<String> pinyin) {
  final chars = text.runes.map(String.fromCharCode).toList();
  if (chars.isEmpty || chars.length != pinyin.length) {
    throw const FormatException('Reading annotation length');
  }
  for (var i = 0; i < chars.length; i++) {
    if (readingPunctuation.contains(chars[i])
        ? pinyin[i].isNotEmpty
        : !RegExp(r'^[\u3400-\u9fff]$').hasMatch(chars[i]) ||
              pinyin[i].trim().isEmpty) {
      throw const FormatException('Reading annotation alignment');
    }
  }
}

class ReadingLine {
  ReadingLine.fromJson(Map<String, dynamic> j)
    : id = j['id'] as String,
      text = j['text'] as String,
      pinyin = List.unmodifiable(List<String>.from(j['pinyin'] as List)),
      explanation = j['explanation'] as String,
      audio = j['audio'] as String?,
      audioQuality = AudioQuality.values.byName(j['audioQuality'] as String),
      learningItemId = j['learningItemId'] as String?;
  final String id, text, explanation;
  final List<String> pinyin;
  final String? audio, learningItemId;
  final AudioQuality audioQuality;
}

class ReadingPassage {
  ReadingPassage.fromJson(Map<String, dynamic> j)
    : id = j['id'] as String,
      categoryId = j['categoryId'] as String,
      title = j['title'] as String,
      titlePinyin = List.unmodifiable(
        List<String>.from(j['titlePinyin'] as List),
      ),
      author = j['author'] as String,
      sourceLabel = j['sourceLabel'] as String,
      intro = j['intro'] as String,
      lines = List.unmodifiable(
        (j['lines'] as List).map(
          (l) => ReadingLine.fromJson(Map<String, dynamic>.from(l)),
        ),
      ),
      provenance = Map.unmodifiable(Map<String, dynamic>.from(j['provenance']));
  final String id, categoryId, title, author, sourceLabel, intro;
  final List<String> titlePinyin;
  final List<ReadingLine> lines;
  final Map<String, dynamic> provenance;
}

bool _id(Object? id) =>
    id is String && RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$').hasMatch(id);
Never _bad(String reason) => throw FormatException(reason);
void validateReadingPassage(
  Map<String, dynamic> p,
  Map<String, dynamic> catalog,
) {
  if (!_id(p['id']) ||
      !['poetry', 'idioms', 'classics'].contains(p['categoryId'])) {
    _bad('Invalid reading identity');
  }
  for (final key in ['title', 'sourceLabel', 'intro', 'author']) {
    if (p[key] is! String || (p[key] as String).trim().isEmpty) {
      _bad('Missing $key');
    }
  }
  validateAnnotations(
    p['title'] as String,
    List<String>.from(p['titlePinyin'] as List),
  );
  final provenance = p['provenance'];
  if (provenance is! Map ||
      provenance['url'] is! String ||
      !((Uri.tryParse(provenance['url'])?.scheme ?? '') == 'https') ||
      provenance['edition'] is! String ||
      (provenance['edition'] as String).isEmpty) {
    _bad('Missing reading provenance');
  }
  final items = (catalog['items'] as List)
      .where((i) => i['readingId'] == p['id'])
      .toList();
  if (items.isEmpty || items.any((i) => i['categoryId'] != p['categoryId'])) {
    _bad('Unknown reading reference');
  }
  final lines = p['lines'];
  if (lines is! List || lines.isEmpty) _bad('Empty reading');
  final ids = <String>{}, learningIds = <String>{};
  for (final raw in lines) {
    final l = raw as Map;
    if (!_id(l['id']) ||
        !(l['id'] as String).startsWith('${p['id']}-line-') ||
        !ids.add(l['id'])) {
      _bad('Duplicate or foreign reading line');
    }
    validateAnnotations(
      l['text'] as String,
      List<String>.from(l['pinyin'] as List),
    );
    if (l['explanation'] is! String ||
        (l['explanation'] as String).trim().isEmpty) {
      _bad('Missing explanation');
    }
    final audio = l['audio'];
    if (!AudioQuality.values.any((q) => q.name == l['audioQuality']) ||
        (l['audioQuality'] == 'unavailable') != (audio == null) ||
        (audio != null && audio != 'audio/reading/${l['id']}.wav')) {
      _bad('Invalid reading audio');
    }
    final learning = l['learningItemId'];
    if (p['categoryId'] == 'classics') {
      if (learning is! String ||
          !learningIds.add(learning) ||
          !items.any(
            (i) => i['id'] == learning && i['readingLineId'] == l['id'],
          )) {
        _bad('Invalid classic learning reference');
      }
    } else if (learning != null) {
      _bad('Whole passage learning only');
    }
  }
  if (p['categoryId'] == 'classics'
      ? learningIds.length != items.length
      : items.length != 1) {
    _bad('Reading item coverage');
  }
}

void validateReadingData(
  Map<String, dynamic> body,
  Map<String, dynamic> catalog,
) {
  if (body['version'] != 1 ||
      body['readingRevision'] != catalog['readingRevision'] ||
      body['readingRevision'] is! String ||
      body['passages'] is! List) {
    _bad('Reading version mismatch');
  }
  final ids = <String>{};
  for (final raw in body['passages'] as List) {
    final p = Map<String, dynamic>.from(raw);
    if (!ids.add(p['id'] as String)) _bad('Duplicate reading');
    validateReadingPassage(p, catalog);
  }
  final referenced = (catalog['items'] as List)
      .where((i) => i['readingId'] != null)
      .map((i) => i['readingId'])
      .toSet();
  if (ids.length != referenced.length || !ids.containsAll(referenced)) {
    _bad('Reading coverage mismatch');
  }
}
