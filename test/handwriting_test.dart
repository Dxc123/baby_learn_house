import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:baby_learn_house/app/core/glyph_geometry.dart';
import 'package:baby_learn_house/app/modules/handwriting/trace_controller.dart';

void main() {
  test('source coordinates map upright and round trip', () {
    final t = GlyphTransform(288);
    expect(t.toView(const Point(0, 900)), const Point(16.0, 16.0));
    expect(t.toView(const Point(1024, -124)), const Point(272.0, 272.0));
    expect(
      t.toGlyph(t.toView(const Point(300, 400))),
      const Point(300.0, 400.0),
    );
  });
  test('first pointer owns normalized trace; cancel, undo, clear', () {
    final c = TraceController();
    c.begin(1, const Point(.1, .2));
    c.begin(2, const Point(.5, .5));
    c.update(2, const Point(.6, .6));
    c.update(1, const Point(2, 0));
    c.end(2);
    expect(c.active.length, 1);
    c.end(1);
    expect(c.completed.single.length, 1);
    c.begin(3, const Point(.2, .3));
    c.cancel(3);
    expect(c.completed.length, 1);
    c.begin(4, const Point(.4, .4));
    c.undo();
    expect(c.active, isEmpty);
    expect(c.completed, isEmpty);
    c.begin(5, const Point(.1, .1));
    c.clear();
    c.end(5);
    expect(c.completed, isEmpty);
  });
}
