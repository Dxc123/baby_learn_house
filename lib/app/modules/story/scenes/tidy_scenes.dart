part of '../story_scene_painter.dart';

void _paintTidy(_SceneArt a, int page) {
  if (page <= 3) {
    a.child(165, 292, talk: page == 2);
  } else if (page <= 5) {
    a.child(
      170,
      300,
      talk: true,
      rightHand: page == 5 ? const Offset(93, 4) : null,
    );
    a.child(
      470,
      300,
      friend: true,
      talk: true,
      leftHand: page == 5 ? const Offset(-72, 4) : null,
    );
  } else {
    a.child(165, 292);
    a.child(425, 292, friend: true);
  }
  switch (page) {
    case 1:
      for (var i = 0; i < 3; i++) {
        a.block(
          255 + i * 58,
          345 + (i % 2) * 30,
          i == 1 ? _SceneArt.blue : _SceneArt.green,
        );
      }
      a.ball(470, 388);
      a.ball(520, 350);
    case 2:
      a.block(315, 350, _SceneArt.green);
      a.block(355, 350, _SceneArt.blue);
      a.block(395, 350, _SceneArt.yellow);
      a.ball(505, 360);
      a.ball(545, 360);
      a.line(
        const Offset(200, 440),
        const Offset(200, 345),
        Colors.white,
        width: 18,
      );
    case 3:
      a.box(275, 340);
      for (var i = 0; i < 3; i++) {
        a.block(285 + i * 26, 321, _SceneArt.green, size: 24);
      }
      a.rect(430, 335, 120, 75, _SceneArt.blue, radius: 25);
      a.ball(465, 338);
      a.ball(510, 338);
    case 4:
      a.box(260, 325, width: 140, height: 85);
      a.bubble(200, 110);
    case 5:
      a.rect(245, 326, 170, 18, const Color(0xFFAE7A51));
      a.rect(255, 344, 12, 65, const Color(0xFFAE7A51));
      a.rect(392, 344, 12, 65, const Color(0xFFAE7A51));
      a.box(263, 260, width: 135, height: 65);
    case 6:
      a.rect(240, 340, 180, 17, const Color(0xFFAE7A51));
      a.box(260, 286);
      a.rect(470, 340, 90, 60, _SceneArt.blue, radius: 24);
      a.ball(492, 342);
      a.ball(532, 342);
  }
}
