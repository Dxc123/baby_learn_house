import 'dart:convert';
import 'package:flutter/services.dart';

Map<String, dynamic> sampleCatalog() => {
  'version': 1,
  'readingRevision': 'fixture',
  'categories': [
    {
      'id': 'poetry',
      'name': '古诗',
      'pinyin': ['gǔ', 'shī'],
      'symbol': '诗',
      'description': '读诗',
      'tab': 0,
      'available': true,
      'kind': 'reading',
    },
  ],
  'items': [
    {
      'id': 'poetry-test',
      'categoryId': 'poetry',
      'text': '静夜思',
      'pinyin': ['jìng', 'yè', 'sī'],
      'symbol': '诗',
      'note': '古诗',
      'example': '一起读诗',
      'audio': null,
      'audioQuality': 'unavailable',
      'readingId': 'poetry-test',
    },
  ],
};
Map<String, dynamic> sampleBody() => {
  'version': 1,
  'readingRevision': 'fixture',
  'passages': [
    {
      'id': 'poetry-test',
      'categoryId': 'poetry',
      'title': '静夜思',
      'titlePinyin': ['jìng', 'yè', 'sī'],
      'author': '李白',
      'sourceLabel': '古诗',
      'intro': '一起看月亮',
      'provenance': {
        'url': 'https://zh.wikisource.org/wiki/靜夜思',
        'edition': '示例',
        'reviewStatus': 'structural',
      },
      'lines': [
        {
          'id': 'poetry-test-line-01',
          'text': '床前明月光，',
          'pinyin': ['chuáng', 'qián', 'míng', 'yuè', 'guāng', ''],
          'explanation': '月光照在床前。',
          'audio': null,
          'audioQuality': 'unavailable',
        },
        {
          'id': 'poetry-test-line-02',
          'text': '疑是地上霜。',
          'pinyin': ['yí', 'shì', 'dì', 'shàng', 'shuāng', ''],
          'explanation': '像地上的霜。',
          'audio': null,
          'audioQuality': 'unavailable',
        },
      ],
    },
  ],
};

class ReadingBundle extends CachingAssetBundle {
  ReadingBundle(this.body);
  Map<String, dynamic> body;
  bool fail = false;
  @override
  Future<ByteData> load(String key) async {
    if (fail) throw StateError('load failed');
    return ByteData.sublistView(
      Uint8List.fromList(utf8.encode(jsonEncode(body))),
    );
  }
}
