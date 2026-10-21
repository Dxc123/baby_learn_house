import 'package:flutter/material.dart';

/// Original geometric illustration. No remote images or copied artwork.
class CategoryArt extends StatelessWidget {
  const CategoryArt({
    super.key,
    required this.symbol,
    required this.variant,
    this.aspectRatio,
  });
  final String symbol;
  final int variant;
  final double? aspectRatio;
  @override
  Widget build(BuildContext context) {
    const palettes = [
      Color(0xFFFFF0D5),
      Color(0xFFE7F2E3),
      Color(0xFFFCE7DE),
      Color(0xFFE5EEF9),
    ];
    final art = ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: SizedBox(
        height: aspectRatio == null ? 148 : null,
        width: double.infinity,
        child: CustomPaint(
          painter: _Landscape(palettes[variant % 4]),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 8,
                ),
                child: Text(
                  symbol,
                  style: TextStyle(
                    fontSize: symbol.length > 2 ? 60 : 82,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF68855B),
                    letterSpacing: 6,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return aspectRatio == null
        ? art
        : AspectRatio(aspectRatio: aspectRatio!, child: art);
  }
}

class _Landscape extends CustomPainter {
  _Landscape(this.background);
  final Color background;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = background);
    canvas.drawCircle(
      Offset(size.width - 44, 33),
      21,
      Paint()..color = const Color(0xFFF6D579),
    );
    final cloud = Paint()..color = Colors.white.withValues(alpha: .8);
    for (final position in [Offset(45, 36), Offset(size.width - 90, 82)]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: position, width: 54, height: 16),
          const Radius.circular(12),
        ),
        cloud,
      );
      canvas.drawCircle(position.translate(-8, -7), 12, cloud);
      canvas.drawCircle(position.translate(8, -5), 10, cloud);
    }
    final ground = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height - 18)
      ..quadraticBezierTo(
        size.width * .25,
        size.height - 65,
        size.width * .55,
        size.height - 18,
      )
      ..quadraticBezierTo(
        size.width * .8,
        size.height - 45,
        size.width,
        size.height - 23,
      )
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(
      ground,
      Paint()..color = const Color(0xFFB4CFA2).withValues(alpha: .5),
    );
    final dots = Paint()..color = const Color(0xFFE2A06B);
    for (var i = 0; i < 5; i++) {
      canvas.drawCircle(
        Offset(16 + i * 28, size.height - 12 - (i % 2) * 9),
        2.5,
        dots,
      );
    }
  }

  @override
  bool shouldRepaint(_Landscape oldDelegate) =>
      oldDelegate.background != background;
}
