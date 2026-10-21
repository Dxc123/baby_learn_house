import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../data/learning_content.dart';

/// Code-drawn diagrams and system pictograms, never fetched from a server.
class CognitionVisual extends StatelessWidget {
  const CognitionVisual(this.item, {super.key});
  final LearningItem item;
  @override
  Widget build(BuildContext context) {
    final image = item.imageAsset;
    return Semantics(
      container: true,
      label: '${item.text}示意图',
      image: true,
      child: SizedBox(
        height: 160,
        width: double.infinity,
        child: image != null
            ? Image.asset(
                'assets/$image',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stack) =>
                    const Center(child: Text('插图暂时无法显示')),
              )
            : item.categoryId == 'colors' ||
                  item.categoryId == 'shapes' ||
                  ['rope', 'grass', 'bamboo'].contains(item.symbol)
            ? CustomPaint(painter: _Diagram(item))
            : Center(
                child: Text(
                  item.symbol,
                  textScaler: TextScaler.noScaling,
                  style: const TextStyle(fontSize: 88),
                ),
              ),
      ),
    );
  }
}

class _Diagram extends CustomPainter {
  _Diagram(this.item);
  final LearningItem item;
  @override
  void paint(Canvas canvas, Size size) {
    final box = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: size.width.clamp(0, 170),
      height: 130,
    );
    final paint = Paint()..color = const Color(0xFF6A9E7A);
    if (item.categoryId == 'colors') {
      const colors = {
        'red': Color(0xFFE64B46),
        'yellow': Color(0xFFF9D64C),
        'blue': Color(0xFF458FD7),
        'green': Color(0xFF4EAA66),
        'black': Color(0xFF24272C),
        'white': Colors.white,
      };
      canvas.drawRRect(
        RRect.fromRectAndRadius(box, const Radius.circular(18)),
        paint..color = colors[item.symbol]!,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(box, const Radius.circular(18)),
        Paint()
          ..color = const Color(0xFF838B86)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    } else if (item.categoryId == 'shapes') {
      switch (item.symbol) {
        case 'circle':
          canvas.drawCircle(box.center, 60, paint);
        case 'square':
          canvas.drawRect(
            Rect.fromCenter(center: box.center, width: 120, height: 120),
            paint,
          );
        case 'rectangle':
          canvas.drawRect(box.deflate(8), paint);
        case 'oval':
          canvas.drawOval(box.deflate(8), paint);
        case 'triangle':
          canvas.drawPath(
            Path()
              ..moveTo(box.center.dx, box.top)
              ..lineTo(box.right, box.bottom)
              ..lineTo(box.left, box.bottom)
              ..close(),
            paint,
          );
        case 'star':
          final path = Path();
          for (var i = 0; i < 10; i++) {
            final angle = -math.pi / 2 + i * math.pi / 5;
            final radius = i.isEven ? 64.0 : 28.0;
            final point =
                box.center + Offset(math.cos(angle), math.sin(angle)) * radius;
            i == 0
                ? path.moveTo(point.dx, point.dy)
                : path.lineTo(point.dx, point.dy);
          }
          canvas.drawPath(path..close(), paint);
      }
    } else if (item.symbol == 'rope') {
      final center = box.center;
      final line = Paint()
        ..color = const Color(0xFF699A7D)
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawOval(
        box.deflate(3),
        Paint()
          ..color = const Color(0xFFE7AA58)
          ..strokeWidth = 4
          ..style = PaintingStyle.stroke,
      );
      canvas.drawCircle(
        center.translate(0, -40),
        13,
        Paint()..color = const Color(0xFFE8BB91),
      );
      for (final pair in [
        [center.translate(0, -24), center.translate(0, 18)],
        [center.translate(-42, -4), center.translate(0, -14)],
        [center.translate(0, -14), center.translate(42, -4)],
        [center.translate(0, 18), center.translate(-25, 48)],
        [center.translate(0, 18), center.translate(25, 48)],
      ]) {
        canvas.drawLine(pair[0], pair[1], line);
      }
    } else {
      final line = Paint()
        ..color = const Color(0xFF4C9162)
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 5; i++) {
        final x = box.left + 20 + i * 30;
        final bottom = Offset(x, box.bottom);
        final top = Offset(x + (i - 2) * 5, box.top + (i % 2) * 25);
        canvas.drawLine(bottom, top, line);
        if (item.symbol == 'bamboo') {
          for (var j = 1; j <= 3; j++) {
            final y = box.bottom - j * 28;
            canvas.drawLine(
              Offset(x - 4, y),
              Offset(x + 4, y),
              Paint()
                ..color = const Color(0xFFCAE5B0)
                ..strokeWidth = 2,
            );
            canvas.drawLine(
              Offset(x, y),
              Offset(x + 17, y - 15),
              line..strokeWidth = 3,
            );
          }
          line.strokeWidth = 7;
        }
      }
    }
  }

  @override
  bool shouldRepaint(_Diagram oldDelegate) => oldDelegate.item.id != item.id;
}
