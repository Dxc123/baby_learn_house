part of '../story_scene_painter.dart';

void _paintFeelings(_SceneArt a, int page) {
  if (page == 2) {
    a.child(300, 335, sad: true, scale: 1.5);
    a.circle(250, 180, 10, const Color(0xFFE8A99C));
    a.circle(350, 180, 10, const Color(0xFFE8A99C));
    return;
  }
  a.child(
    165,
    300,
    sad: page <= 3,
    talk: page == 3 || page == 5,
    calm: page == 4,
  );
  if (page >= 3) {
    a.child(475, 300, friend: true, talk: page == 6, calm: page == 4);
  }
  switch (page) {
    case 1:
      a.block(280, 360, _SceneArt.green);
      a.block(330, 375, _SceneArt.blue);
      a.block(380, 350, _SceneArt.yellow);
    case 3:
      a.block(290, 370, _SceneArt.green);
      a.block(340, 370, _SceneArt.blue);
      a.bubble(210, 110);
    case 4:
      for (var i = 0; i < 3; i++) {
        a.line(
          Offset(255, 210 + i * 22),
          Offset(365, 210 + i * 22),
          const Color(0xFF91B8AF),
          width: 4,
        );
      }
      a.bubble(270, 85, heart: true);
    case 5:
      a.block(270, 310, _SceneArt.green);
      a.block(330, 370, _SceneArt.blue);
      a.bubble(210, 105);
    case 6:
      a.block(270, 370, _SceneArt.green, size: 45);
      a.block(320, 370, _SceneArt.blue, size: 45);
      a.block(298, 325, _SceneArt.yellow, size: 42);
      a.bubble(270, 105, heart: true);
  }
}
