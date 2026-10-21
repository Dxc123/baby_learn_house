import 'reading_types.dart' show validateAnnotations;

enum StoryKind { pictureBook, dialogue }

const storyBooks = {
  'book-share-toys': 'share',
  'book-tidy-up': 'tidy',
  'book-feelings': 'feelings',
};
const storyDialogs = {
  'dialog-greeting',
  'dialog-thanks',
  'dialog-borrowing',
  'dialog-help',
  'dialog-taking-turns',
  'dialog-feelings',
};
final storySceneIds = Set<String>.unmodifiable([
  for (final p in storyBooks.values)
    for (var i = 1; i <= 6; i++) '$p-${i.toString().padLeft(2, '0')}',
]);

class StoryUnit {
  StoryUnit.fromJson(Map<String, dynamic> j)
    : id = j['id'] as String,
      text = j['text'] as String,
      pinyin = List<String>.unmodifiable(j['pinyin'] as List),
      sceneId = j['sceneId'] as String?,
      roleId = j['roleId'] as String?;
  final String id, text;
  final List<String> pinyin;
  final String? sceneId, roleId;
}

class StoryRole {
  StoryRole.fromJson(Map<String, dynamic> j)
    : id = j['id'] as String,
      name = j['name'] as String,
      avatarId = j['avatarId'] as String;
  final String id, name, avatarId;
}

class StoryDocument {
  StoryDocument.fromJson(
    Map<String, dynamic> j, {
    required List<Map<String, dynamic>> scenes,
  }) : id = j['id'] as String,
       categoryId = j['categoryId'] as String,
       title = j['title'] as String,
       titlePinyin = List<String>.unmodifiable(j['titlePinyin'] as List),
       intro = j['intro'] as String,
       prompt = j['prompt'] as String,
       kind = StoryKind.values.byName(j['type'] as String),
       provenance = Map<String, dynamic>.unmodifiable(j['provenance'] as Map),
       units = List.unmodifiable(
         (j[j['type'] == 'pictureBook' ? 'pages' : 'turns'] as List).map(
           (u) => StoryUnit.fromJson(Map<String, dynamic>.from(u as Map)),
         ),
       ),
       roles = List.unmodifiable(
         (j['roles'] as List? ?? []).map(
           (r) => StoryRole.fromJson(Map<String, dynamic>.from(r as Map)),
         ),
       ),
       parentTips = List<String>.unmodifiable(j['parentTips'] as List? ?? []),
       sceneMetadata = Map.unmodifiable({
         for (final s in scenes)
           if (s['bookId'] == j['id'])
             s['id'] as String: Map<String, dynamic>.unmodifiable(s),
       });
  final String id, categoryId, title, intro, prompt;
  final List<String> titlePinyin, parentTips;
  final StoryKind kind;
  final List<StoryUnit> units;
  final List<StoryRole> roles;
  final Map<String, dynamic> provenance;
  final Map<String, Map<String, dynamic>> sceneMetadata;
}

void _require(bool condition, String why) {
  if (!condition) throw FormatException(why);
}

bool _text(Object? v) => v is String && v.trim().isNotEmpty;
void validateStoryDocument(
  Map raw,
  Map catalog,
  List<Map<String, dynamic>> scenes, {
  bool allowMissingScenes = false,
}) {
  final id = raw['id'];
  final book = storyBooks.containsKey(id);
  _require(book || storyDialogs.contains(id), 'Unknown story');
  _require(
    raw['type'] == (book ? 'pictureBook' : 'dialogue') &&
        raw['categoryId'] == (book ? 'books' : 'dialog'),
    'Story type',
  );
  validateAnnotations(
    raw['title'] as String,
    List<String>.from(raw['titlePinyin'] as List),
  );
  _require(
    _text(raw['intro']) &&
        _text(raw['prompt']) &&
        raw['provenance'] is Map &&
        raw['provenance']['source'] == 'project-authored' &&
        raw['provenance']['reviewStatus'] == 'text-reviewed',
    'Story metadata',
  );
  final units = raw[book ? 'pages' : 'turns'] as List;
  _require(units.length == 6, 'Unit count');
  final roles = raw['roles'] as List? ?? [];
  if (!book) {
    _require(
      roles.length == 2 &&
          roles.map((r) => r['id']).toSet().length == 2 &&
          roles.every(
            (r) =>
                _text(r['id']) &&
                _text(r['name']) &&
                ['child', 'friend', 'adult'].contains(r['avatarId']),
          ),
      'Invalid roles',
    );
    _require(
      raw['parentTips'] is List &&
          (raw['parentTips'] as List).length == 2 &&
          (raw['parentTips'] as List).every(_text),
      'Parent tips',
    );
  }
  for (var i = 0; i < units.length; i++) {
    final u = units[i] as Map;
    final uid =
        '$id-${book ? 'page' : 'turn'}-${(i + 1).toString().padLeft(2, '0')}';
    _require(u['id'] == uid, 'Unit identity');
    validateAnnotations(
      u['text'] as String,
      List<String>.from(u['pinyin'] as List),
    );
    final count = RegExp(
      r'[\u3400-\u9fff]',
    ).allMatches(u['text'] as String).length;
    _require(
      book ? (count >= 12 && count <= 32) : (count >= 8 && count <= 28),
      'Unit length',
    );
    if (book) {
      final scene = '${storyBooks[id]}-${(i + 1).toString().padLeft(2, '0')}';
      _require(u['roleId'] == null, 'Unexpected page role');
      if (allowMissingScenes) continue;
      final matches = scenes.where((s) => s['id'] == scene).toList();
      _require(
        u['sceneId'] == scene &&
            u['roleId'] == null &&
            storySceneIds.contains(scene) &&
            matches.length == 1,
        'Scene identity',
      );
      final s = matches.single;
      _require(
        s['bookId'] == id &&
            s['pageId'] == uid &&
            _text(s['alt']) &&
            s['version'] == 1 &&
            s['source'] == 'project-authored vector scene' &&
            s['quality'] == 'illustration',
        'Scene metadata',
      );
    } else {
      _require(
        roles.any((r) => r['id'] == u['roleId']) && u['sceneId'] == null,
        'Unknown role',
      );
    }
  }
  final items = (catalog['items'] as List)
      .where((i) => i['storyId'] == id)
      .toList();
  _require(
    items.length == 1 &&
        items.single['id'] == id &&
        items.single['categoryId'] == raw['categoryId'],
    'Story reference',
  );
  _require(
    items.single['coverSceneId'] == (book ? '${storyBooks[id]}-01' : null),
    'Cover reference',
  );
}

void validateStoryData(Map body, Map catalog) {
  _require(
    body['version'] == 1 &&
        body['storyRevision'] is String &&
        body['storyRevision'] == catalog['storyRevision'],
    'Story revision',
  );
  final stories = body['stories'] as List;
  final scenes = (body['scenes'] as List)
      .map((s) => Map<String, dynamic>.from(s as Map))
      .toList();
  _require(
    stories.length == 9 &&
        stories.map((s) => s['id']).toSet().containsAll({
          ...storyBooks.keys,
          ...storyDialogs,
        }) &&
        scenes.length == 18 &&
        scenes.map((s) => s['id']).toSet().length == 18 &&
        scenes.every((s) => storySceneIds.contains(s['id'])),
    'Story corpus',
  );
  for (final story in stories) {
    validateStoryDocument(story as Map, catalog, scenes);
  }
  _require(
    (catalog['items'] as List).where((i) => i['storyId'] != null).length == 9,
    'Story catalog coverage',
  );
}
