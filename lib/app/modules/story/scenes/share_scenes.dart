part of '../story_scene_painter.dart';

void _paintShare(_SceneArt a, int page) {
  a.child(
    150,
    300,
    talk: page == 3 || page == 5,
    rightHand: page == 6 ? const Offset(133, 20) : null,
  );
  a.child(
    475,
    300,
    friend: true,
    raised: page == 2,
    talk: page == 4 || page == 5,
    leftHand: page == 6 ? const Offset(-115, 30) : null,
  );
  switch (page) {
    case 1:
      a.track();
      a.train(340, 345);
      a.block(420, 355, _SceneArt.yellow);
    case 2:
      a.track();
      a.line(
        const Offset(270, 350),
        const Offset(340, 305),
        _SceneArt.blue,
        width: 16,
      );
      a.line(
        const Offset(340, 305),
        const Offset(410, 350),
        _SceneArt.blue,
        width: 16,
      );
      a.rect(385, 195, 65, 16, _SceneArt.yellow);
    case 3:
      a.track();
      a.train(340, 345);
      a.bubble(200, 100);
    case 4:
      a.track();
      a.rect(300, 320, 90, 22, _SceneArt.blue);
      a.bubble(345, 100);
      a.circle(245, 255, 30, _SceneArt.yellow);
      a.line(
        const Offset(245, 255),
        const Offset(245, 235),
        _SceneArt.ink,
        width: 3,
      );
      a.line(
        const Offset(245, 255),
        const Offset(259, 263),
        _SceneArt.ink,
        width: 3,
      );
    case 5:
      a.track(joined: true);
      a.train(290, 335);
      a.bubble(210, 70, heart: true);
    case 6:
      a.box(265, 330);
      a.train(283, 306);
      a.rect(275, 390, 80, 10, const Color(0xFF927559));
  }
}
