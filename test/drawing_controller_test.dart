import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:baby_learn_house/app/modules/drawing/drawing_document.dart';
import 'package:baby_learn_house/app/modules/drawing/drawing_controller.dart';

void main() {
  test('tap, sampling, captured brush and clamped boundary', () {
    final c = DrawingController();
    expect(c.begin(1, .5, .5), true);
    c.setBrush(color: drawingColors[1], width: 20);
    c.move(1, .5001, .5);
    expect(c.activeStroke!.points.length, 1);
    c.move(1, 2, -.5);
    expect(c.activeStroke!.points.last.x, 1);
    expect(c.activeStroke!.points.last.y, 0);
    c.end(1);
    expect(c.document.strokes.single.color, drawingColors.first);
    expect(c.document.strokes.single.width, 10);
    c.begin(1, .2, .2);
    c.end(1);
    expect(c.document.strokes.last.points.length, 1);
    expect(c.document.strokes.last.width, 20);
  });
  test('invalid input, second pointer and cancellation do not commit', () {
    final c = DrawingController();
    expect(c.begin(1, -1, .5), false);
    expect(c.begin(1, double.nan, 0), false);
    c.begin(1, .2, .2);
    expect(c.begin(2, .8, .8), false);
    expect(c.move(1, double.infinity, .5), false);
    expect(c.end(2), false);
    c.cancel();
    expect(c.document.strokes, isEmpty);
  });
  test('redo survives cancelled stroke, clear is an undoable action', () {
    final c = DrawingController();
    c.begin(1, .2, .2);
    c.end(1);
    c.undo();
    c.begin(1, .3, .3);
    c.cancel();
    expect(c.canRedo, true);
    c.redo();
    c.clear();
    expect(c.document.strokes, isEmpty);
    c.undo();
    expect(c.document.strokes.length, 1);
    c.redo();
    expect(c.document.strokes, isEmpty);
    c.undo();
    c.undo();
    c.begin(1, .4, .4);
    c.end(1);
    expect(c.canRedo, false);
    final doc = DrawingDocument.decode(c.document.encode());
    c.restore(doc);
    expect(c.canUndo, false);
  });
  test('limits preserve valid strokes and undo releases capacity', () {
    final c = DrawingController();
    for (var i = 0; i < 256; i++) {
      c.begin(1, .2, .2);
      c.end(1);
    }
    expect(c.begin(1, .2, .2), false);
    expect(c.limitReached, true);
    expect(c.document.strokes.length, 256);
    c.undo();
    expect(c.begin(1, .2, .2), true);
    c.end(1);
    expect(c.document.encode().length, lessThan(1024 * 1024));
    final dense = DrawingController();
    dense.begin(1, 0, 0);
    for (var i = 0; i < 13000; i++) {
      dense.move(1, i.isEven ? 1 : 0, 0);
    }
    dense.end(1);
    expect(dense.document.strokes.single.points.length, 12000);
  });
  test(
    'document validates version, colors, widths, finite points and size',
    () {
      final good = DrawingDocument().encode();
      for (final edit in <void Function(Map<String, dynamic>)>[
        (m) => m['version'] = 2,
        (m) => m['color'] = 0,
        (m) => m['width'] = 3,
        (m) => m['strokes'] = [
          {'color': drawingColors.first, 'width': 10, 'points': []},
        ],
        (m) => m['strokes'] = [
          {
            'color': drawingColors.first,
            'width': 10,
            'points': [
              [2, 0],
            ],
          },
        ],
      ]) {
        final m = jsonDecode(good) as Map<String, dynamic>;
        edit(m);
        expect(
          () => DrawingDocument.decode(jsonEncode(m)),
          throwsFormatException,
        );
      }
      expect(
        () => DrawingDocument.decode(' ' * (1024 * 1024 + 1)),
        throwsFormatException,
      );
      final doc = DrawingDocument(
        strokes: [
          DrawingStroke(
            color: drawingColors.first,
            width: 10,
            points: [DrawingPoint(.123456, .5)],
          ),
        ],
      );
      expect(
        DrawingDocument.decode(doc.encode()).strokes.single.points.single.x,
        .1235,
      );
    },
  );
}
