import 'package:flutter/material.dart';
import 'drawing_document.dart';

void paintDrawing(
  Canvas canvas,
  Size size,
  DrawingDocument document, {
  DrawingStroke? activeStroke,
}) {
  canvas.save();
  canvas.clipRect(Offset.zero & size);
  canvas.drawColor(Colors.white, BlendMode.src);
  for (final stroke in [...document.strokes, ?activeStroke]) {
    final paint = Paint()
      ..color = Color(stroke.color)
      ..strokeWidth = stroke.width * size.width / 1024
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    Offset position(DrawingPoint p) =>
        Offset(p.x * size.width, p.y * size.height);
    if (stroke.points.length == 1) {
      canvas.drawCircle(
        position(stroke.points.first),
        paint.strokeWidth / 2,
        Paint()..color = paint.color,
      );
    } else {
      final first = position(stroke.points.first);
      final path = Path()..moveTo(first.dx, first.dy);
      for (final p in stroke.points.skip(1)) {
        final v = position(p);
        path.lineTo(v.dx, v.dy);
      }
      canvas.drawPath(path, paint);
    }
  }
  canvas.restore();
}

class DrawingPainter extends CustomPainter {
  DrawingPainter(this.document, {this.activeStroke});
  final DrawingDocument document;
  final DrawingStroke? activeStroke;
  @override
  void paint(Canvas canvas, Size size) =>
      paintDrawing(canvas, size, document, activeStroke: activeStroke);
  @override
  bool shouldRepaint(covariant DrawingPainter old) =>
      old.document != document || old.activeStroke != activeStroke;
}
