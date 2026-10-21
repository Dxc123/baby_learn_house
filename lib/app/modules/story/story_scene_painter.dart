import 'package:flutter/material.dart';
import 'story_scene_registry.dart';
part 'scenes/share_scenes.dart';
part 'scenes/tidy_scenes.dart';
part 'scenes/feelings_scenes.dart';

class StoryScenePainter extends CustomPainter {
  StoryScenePainter(this.sceneId);
  final String sceneId;
  @override
  void paint(Canvas canvas, Size size) =>
      paintStoryScene(canvas, size, sceneId);
  @override
  bool shouldRepaint(covariant StoryScenePainter old) => old.sceneId != sceneId;
}

void paintStoryScene(Canvas canvas, Size size, String sceneId) {
  if (!supportedStoryScenes.contains(sceneId)) {
    throw ArgumentError.value(sceneId);
  }
  canvas.save();
  canvas.scale(size.width / 640, size.height / 480);
  final a = _SceneArt(canvas);
  a.room();
  final page = int.parse(sceneId.split('-').last);
  if (sceneId.startsWith('share-')) {
    _paintShare(a, page);
  } else if (sceneId.startsWith('tidy-')) {
    _paintTidy(a, page);
  } else {
    _paintFeelings(a, page);
  }
  canvas.restore();
}

class _SceneArt {
  _SceneArt(this.c);
  final Canvas c;
  static const green = Color(0xFF499779),
      blue = Color(0xFF688CBB),
      yellow = Color(0xFFEAC365),
      ink = Color(0xFF394B47);
  void rect(
    double x,
    double y,
    double w,
    double h,
    Color color, {
    double radius = 10,
  }) => c.drawRRect(
    RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(radius)),
    Paint()..color = color,
  );
  void line(Offset a, Offset b, Color color, {double width = 5}) => c.drawLine(
    a,
    b,
    Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round,
  );
  void circle(double x, double y, double r, Color color) =>
      c.drawCircle(Offset(x, y), r, Paint()..color = color);
  void room() {
    rect(0, 0, 640, 480, const Color(0xFFFFF7DF), radius: 0);
    rect(0, 325, 640, 155, const Color(0xFFEAE5D0), radius: 0);
    rect(50, 40, 138, 138, const Color(0xFFD2E8E9));
    line(const Offset(119, 40), const Offset(119, 178), Colors.white, width: 6);
    line(const Offset(50, 109), const Offset(188, 109), Colors.white, width: 6);
    circle(88, 75, 17, yellow);
    rect(485, 120, 100, 145, const Color(0xFFB5CBB1));
    rect(500, 145, 70, 12, Colors.white);
    rect(500, 214, 70, 12, Colors.white);
    c.drawOval(
      const Rect.fromLTWH(75, 345, 490, 110),
      Paint()..color = const Color(0xFFF8F0D0),
    );
  }

  void child(
    double x,
    double y, {
    bool friend = false,
    bool sad = false,
    bool talk = false,
    bool raised = false,
    bool calm = false,
    double scale = 1,
    Offset? leftHand,
    Offset? rightHand,
  }) {
    c.save();
    c.translate(x, y);
    c.scale(scale);
    final shirt = friend ? blue : green;
    final left =
        leftHand ?? (raised ? const Offset(-64, -78) : const Offset(-56, -10));
    final right =
        rightHand ?? (talk ? const Offset(66, -40) : const Offset(55, -10));
    rect(-29, -55, 58, 66, shirt, radius: 18);
    line(const Offset(-14, 10), const Offset(-27, 36), ink, width: 10);
    line(const Offset(14, 10), const Offset(28, 36), ink, width: 10);
    line(const Offset(-26, -42), left, shirt, width: 15);
    line(const Offset(27, -42), right, shirt, width: 15);
    circle(left.dx, left.dy, 9, const Color(0xFFEBC5A4));
    circle(right.dx, right.dy, 9, const Color(0xFFEBC5A4));
    circle(0, -98, 39, const Color(0xFFF1CEAD));
    c.drawArc(
      const Rect.fromLTWH(-39, -138, 78, 55),
      3.15,
      3.15,
      false,
      Paint()
        ..color = ink
        ..strokeWidth = 11
        ..style = PaintingStyle.stroke,
    );
    if (calm) {
      line(const Offset(-20, -99), const Offset(-9, -99), ink, width: 3);
      line(const Offset(9, -99), const Offset(20, -99), ink, width: 3);
    } else {
      circle(-14, -99, 3, ink);
      circle(14, -99, 3, ink);
    }
    c.drawArc(
      Rect.fromLTWH(-12, sad ? -78 : -91, 24, 18),
      sad ? 3.3 : .1,
      2.9,
      false,
      Paint()
        ..color = ink
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke,
    );
    if (sad) {
      line(const Offset(-23, -116), const Offset(-8, -109), ink, width: 3);
      line(const Offset(8, -109), const Offset(23, -116), ink, width: 3);
    }
    c.restore();
  }

  void block(double x, double y, Color color, {double size = 36}) {
    rect(x, y, size, size, color, radius: 4);
    line(
      Offset(x + 5, y + 5),
      Offset(x + size - 5, y + 5),
      Colors.white,
      width: 2,
    );
  }

  void ball(double x, double y, {Color color = yellow}) {
    circle(x, y, 18, color);
    c.drawArc(
      Rect.fromCircle(center: Offset(x, y), radius: 11),
      .4,
      2,
      false,
      Paint()
        ..color = Colors.white
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke,
    );
  }

  void box(double x, double y, {double width = 110, double height = 65}) {
    rect(x, y, width, height, const Color(0xFFD7A673), radius: 6);
    rect(
      x + width * .35,
      y + height * .3,
      width * .3,
      10,
      const Color(0xFFAE7A51),
      radius: 4,
    );
  }

  void bubble(double x, double y, {bool heart = false}) {
    rect(x, y, 100, 58, Colors.white, radius: 22);
    line(
      Offset(x + 20, y + 55),
      Offset(x + 8, y + 70),
      Colors.white,
      width: 10,
    );
    if (heart) {
      circle(x + 40, y + 25, 9, green);
      circle(x + 57, y + 25, 9, green);
      final p = Path()
        ..moveTo(x + 31, y + 27)
        ..lineTo(x + 48, y + 47)
        ..lineTo(x + 66, y + 27)
        ..close();
      c.drawPath(p, Paint()..color = green);
    } else {
      for (var i = 0; i < 3; i++) {
        circle(x + 28 + i * 22, y + 29, 5, ink);
      }
    }
  }

  void train(double x, double y) {
    rect(x, y, 64, 32, green, radius: 5);
    rect(x + 40, y - 23, 24, 32, green, radius: 4);
    rect(x + 45, y - 18, 13, 15, Colors.white, radius: 2);
    circle(x + 14, y + 34, 9, ink);
    circle(x + 52, y + 34, 9, ink);
  }

  void track({bool joined = false}) {
    final p = Paint()
      ..color = const Color(0xFF927559)
      ..strokeWidth = 7
      ..style = PaintingStyle.stroke;
    if (joined) {
      c.drawOval(const Rect.fromLTWH(170, 320, 300, 100), p);
      c.drawOval(const Rect.fromLTWH(188, 333, 264, 74), p);
    } else {
      line(const Offset(230, 365), const Offset(345, 365), p.color, width: 7);
      line(const Offset(230, 382), const Offset(345, 382), p.color, width: 7);
    }
  }
}
