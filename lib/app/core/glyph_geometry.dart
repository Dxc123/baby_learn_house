import 'dart:math';

/// Make Me a Hanzi uses a 1024 unit square with Y increasing upwards.
class GlyphTransform {
  GlyphTransform(this.side, {this.inset = 16}) {
    if (!side.isFinite || !inset.isFinite || inset < 0 || side <= inset * 2) {
      throw ArgumentError('Invalid glyph viewport');
    }
  }
  final double side, inset;
  double get scale => (side - inset * 2) / 1024;
  Point<double> toView(Point<num> p) =>
      Point(inset + p.x * scale, inset + (900 - p.y) * scale);
  Point<double> toGlyph(Point<num> p) =>
      Point((p.x - inset) / scale, 900 - (p.y - inset) / scale);
}
