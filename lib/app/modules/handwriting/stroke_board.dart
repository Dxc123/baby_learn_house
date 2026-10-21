import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:path_drawing/path_drawing.dart';
import '../../core/glyph_geometry.dart';
import '../../data/hanzi_strokes.dart';
import 'trace_controller.dart';

class StrokeBoard extends StatelessWidget {
  const StrokeBoard(
    this.data, {
    super.key,
    required this.visibleStrokeCount,
    this.trace,
  });
  final HanziStrokeData data;
  final int visibleStrokeCount;
  final TraceController? trace;
  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 1,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.maxWidth;
        Point<double> point(Offset p) => Point(p.dx / side, p.dy / side);
        Widget board() => Semantics(
          label:
              '${data.character}，田字格，显示 $visibleStrokeCount / ${data.strokes.length} 笔${trace == null ? '' : '，自由描红区域'}',
          child: CustomPaint(
            painter: _BoardPainter(data, visibleStrokeCount, trace),
          ),
        );
        return ClipRect(
          child: RawGestureDetector(
            gestures: trace == null
                ? const {}
                : {
                    EagerGestureRecognizer:
                        GestureRecognizerFactoryWithHandlers<
                          EagerGestureRecognizer
                        >(() => EagerGestureRecognizer(), (_) {}),
                  },
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: trace == null
                  ? null
                  : (e) => trace!.begin(e.pointer, point(e.localPosition)),
              onPointerMove: trace == null
                  ? null
                  : (e) => trace!.update(e.pointer, point(e.localPosition)),
              onPointerUp: trace == null ? null : (e) => trace!.end(e.pointer),
              onPointerCancel: trace == null
                  ? null
                  : (e) => trace!.cancel(e.pointer),
              child: trace == null
                  ? board()
                  : AnimatedBuilder(
                      animation: trace!,
                      builder: (_, child) => board(),
                    ),
            ),
          ),
        );
      },
    ),
  );
}

class _BoardPainter extends CustomPainter {
  _BoardPainter(this.data, this.count, this.trace) : super(repaint: trace);
  final HanziStrokeData data;
  final int count;
  final TraceController? trace;
  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    final grid = Paint()
      ..color = const Color(0xFFB7C3AD)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFFFFDF6),
    );
    canvas.drawRect(Rect.fromLTWH(.5, .5, side - 1, side - 1), grid);
    for (double p = 0; p < side; p += 10) {
      canvas.drawLine(
        Offset(side / 2, p),
        Offset(side / 2, min(p + 5, side)),
        grid,
      );
      canvas.drawLine(
        Offset(p, side / 2),
        Offset(min(p + 5, side), side / 2),
        grid,
      );
    }
    final transform = GlyphTransform(side, inset: side / 18);
    canvas.save();
    canvas.translate(transform.inset, transform.inset + 900 * transform.scale);
    canvas.scale(transform.scale, -transform.scale);
    for (var i = 0; i < data.strokes.length; i++) {
      canvas.drawPath(
        parseSvgPathData(data.strokes[i]),
        Paint()
          ..color = (trace == null && i < count
              ? const Color(0xFF344D38)
              : const Color(0xFFDEE2D7)),
      );
    }
    canvas.restore();
    if (trace != null) {
      final pen = Paint()
        ..color = const Color(0xFFCB6C4C)
        ..strokeWidth = side / 48
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      for (final line in [...trace!.completed, trace!.active]) {
        if (line.isEmpty) continue;
        if (line.length == 1) {
          canvas.drawCircle(
            Offset(line.first.x * side, line.first.y * side),
            pen.strokeWidth / 2,
            Paint()..color = pen.color,
          );
          continue;
        }
        final path = Path()..moveTo(line.first.x * side, line.first.y * side);
        for (final p in line.skip(1)) {
          path.lineTo(p.x * side, p.y * side);
        }
        canvas.drawPath(path, pen);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BoardPainter old) =>
      old.data != data || old.count != count || old.trace != trace;
}
