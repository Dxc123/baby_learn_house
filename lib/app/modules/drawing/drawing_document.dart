import 'dart:convert';

const drawingColors = [
  0xff263238,
  0xffe85d5d,
  0xffe9a23b,
  0xff30946d,
  0xff477bc0,
  0xff9365b8,
];
const drawingWidths = [4.0, 10.0, 20.0];
const drawingMaxPoints = 12000;
const drawingMaxBytes = 1024 * 1024;

class DrawingPoint {
  const DrawingPoint(this.x, this.y);
  final double x, y;
}

class DrawingStroke {
  DrawingStroke({
    required this.color,
    required this.width,
    required List<DrawingPoint> points,
  }) : points = List.unmodifiable(points);
  final int color;
  final double width;
  final List<DrawingPoint> points;
  Map<String, Object> toJson() => {
    'color': color,
    'width': width,
    'points': [
      for (final p in points)
        [
          double.parse(p.x.toStringAsFixed(4)),
          double.parse(p.y.toStringAsFixed(4)),
        ],
    ],
  };
}

class DrawingDocument {
  DrawingDocument({
    this.color = 0xff263238,
    this.width = 10,
    List<DrawingStroke> strokes = const [],
  }) : strokes = List.unmodifiable(strokes);
  final int color;
  final double width;
  final List<DrawingStroke> strokes;
  int get pointCount => strokes.fold(0, (n, s) => n + s.points.length);
  void validate() {
    if (!drawingColors.contains(color) ||
        !drawingWidths.contains(width) ||
        strokes.length > 256 ||
        pointCount > drawingMaxPoints) {
      throw const FormatException('Invalid drawing limits or brush');
    }
    for (final s in strokes) {
      if (!drawingColors.contains(s.color) ||
          !drawingWidths.contains(s.width) ||
          s.points.isEmpty) {
        throw const FormatException('Invalid stroke');
      }
      for (final p in s.points) {
        if (!p.x.isFinite ||
            !p.y.isFinite ||
            p.x < 0 ||
            p.x > 1 ||
            p.y < 0 ||
            p.y > 1) {
          throw const FormatException('Invalid drawing point');
        }
      }
    }
  }

  String encode() {
    validate();
    final raw = jsonEncode({
      'version': 1,
      'reference': 1024,
      'color': color,
      'width': width,
      'strokes': strokes.map((s) => s.toJson()).toList(),
    });
    if (utf8.encode(raw).length > drawingMaxBytes) {
      throw const FormatException('Drawing too large');
    }
    return raw;
  }

  factory DrawingDocument.decode(String raw) {
    if (raw.length > drawingMaxBytes ||
        utf8.encode(raw).length > drawingMaxBytes) {
      throw const FormatException('Drawing too large');
    }
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      if (m['version'] != 1 || m['reference'] != 1024) {
        throw const FormatException('Unknown drawing version');
      }
      final list = m['strokes'] as List;
      if (list.length > 256) throw const FormatException('Too many strokes');
      var count = 0;
      final strokes = <DrawingStroke>[];
      for (final s in list) {
        final points = s['points'] as List;
        count += points.length;
        if (count > drawingMaxPoints) {
          throw const FormatException('Too many points');
        }
        strokes.add(
          DrawingStroke(
            color: s['color'] as int,
            width: (s['width'] as num).toDouble(),
            points: [
              for (final p in points)
                if (p is List && p.length == 2)
                  DrawingPoint(
                    (p[0] as num).toDouble(),
                    (p[1] as num).toDouble(),
                  )
                else
                  throw const FormatException('Invalid point shape'),
            ],
          ),
        );
      }
      final doc = DrawingDocument(
        color: m['color'] as int,
        width: (m['width'] as num).toDouble(),
        strokes: strokes,
      );
      doc.validate();
      return doc;
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('Invalid drawing draft');
    }
  }
}
