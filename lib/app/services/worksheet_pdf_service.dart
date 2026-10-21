import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../data/learning_content.dart';
import '../data/hanzi_strokes.dart';

class WorksheetConfig {
  WorksheetConfig({required List<String> itemIds, this.rowsPerCharacter = 2})
    : itemIds = List.unmodifiable(itemIds);
  final List<String> itemIds;
  final int rowsPerCharacter;
}

class WorksheetLayout {
  static const margin = 36.0, header = 32.0, footer = 18.0, cell = 48.0;
  static List<List<String>> paginate(WorksheetConfig config) {
    if (config.itemIds.isEmpty ||
        config.itemIds.length > 60 ||
        config.itemIds.toSet().length != config.itemIds.length ||
        config.rowsPerCharacter < 1 ||
        config.rowsPerCharacter > 4) {
      throw ArgumentError('请选择 1 至 60 个不重复的汉字，每字 1 至 4 行。');
    }
    final available = PdfPageFormat.a4.height - margin * 2 - header - footer;
    final block = 26 + 56 * config.rowsPerCharacter;
    final perPage = (available / block).floor();
    return [
      for (var i = 0; i < config.itemIds.length; i += perPage)
        config.itemIds.sublist(
          i,
          (i + perPage).clamp(0, config.itemIds.length),
        ),
    ];
  }
}

class WorksheetPdfService {
  WorksheetPdfService(this.content, this.strokes, this.bundle);
  final ContentRepository content;
  final HanziStrokeRepository strokes;
  final AssetBundle bundle;
  Future<Uint8List> build(WorksheetConfig config) async {
    final pages = WorksheetLayout.paginate(config);
    final items = <String, LearningItem>{};
    final glyphs = <String, HanziStrokeData>{};
    for (final id in config.itemIds) {
      final matches = content.items.where(
        (i) => i.id == id && i.kind == ContentKind.hanzi,
      );
      if (matches.isEmpty || matches.first.strokeAsset == null) {
        throw ArgumentError('汉字或笔顺不可用：$id');
      }
      final item = matches.first;
      final glyph = await strokes.load(item.strokeAsset!);
      if (glyph.character != item.text ||
          glyph.strokes.length != item.strokes) {
        throw const FormatException('字形与课程不一致');
      }
      items[id] = item;
      glyphs[id] = glyph;
    }
    final font = pw.Font.ttf(
      await bundle.load('assets/fonts/LXGWWenKai-Regular.ttf'),
    );
    final doc = pw.Document(
      title: '宝宝学识屋 · 汉字练习',
      author: '宝宝学识屋',
      creator: 'Offline worksheet',
    );
    pw.Widget cell(HanziStrokeData data, int index) => pw.Container(
      width: 48,
      height: 48,
      child: pw.Stack(
        children: [
          pw.Positioned.fill(
            child: pw.CustomPaint(
              painter: (canvas, size) {
                canvas.setLineDashPattern();
                canvas
                  ..setStrokeColor(PdfColors.grey500)
                  ..setLineWidth(.5)
                  ..drawRect(0, 0, 48, 48)
                  ..strokePath();
                canvas.setLineDashPattern([2, 2]);
                canvas
                  ..drawLine(24, 0, 24, 48)
                  ..drawLine(0, 24, 48, 24)
                  ..strokePath();
                canvas.setLineDashPattern();
              },
            ),
          ),
          if (index < 4)
            pw.Positioned(
              left: 48 / 18,
              top: 48 / 18,
              child: pw.SvgImage(
                svg: data.svg(color: index == 0 ? '#253B2A' : '#C8CDC5'),
                width: 48 - 96 / 18,
                height: 48 - 96 / 18,
              ),
            ),
        ],
      ),
    );
    for (var pageIndex = 0; pageIndex < pages.length; pageIndex++) {
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(36),
          theme: pw.ThemeData.withFont(base: font, bold: font),
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(
                height: 32,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      '宝宝学识屋 · 汉字练习',
                      style: const pw.TextStyle(fontSize: 14),
                    ),
                    pw.Text(
                      '姓名：________  日期：________',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
              for (final id in pages[pageIndex]) ...[
                pw.SizedBox(
                  height: 22,
                  child: pw.Text(
                    '${items[id]!.text}   ${items[id]!.pinyin.join(' ')}   · ${items[id]!.strokes} 画',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ),
                for (var row = 0; row < config.rowsPerCharacter; row++) ...[
                  pw.Row(
                    children: [
                      for (var col = 0; col < 9; col++) cell(glyphs[id]!, col),
                    ],
                  ),
                  if (row < config.rowsPerCharacter - 1) pw.SizedBox(height: 8),
                ],
                pw.SizedBox(height: 12),
              ],
              pw.Spacer(),
              pw.SizedBox(
                height: 18,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      '笔顺：Hanzi Writer Data / Arphic · 字体：LXGW WenKai / OFL',
                      style: const pw.TextStyle(fontSize: 7),
                    ),
                    pw.Text(
                      '${pageIndex + 1} / ${pages.length}',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    return doc.save();
  }
}
