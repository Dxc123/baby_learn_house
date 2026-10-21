import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baby_learn_house/app/data/hanzi_strokes.dart';
import 'package:baby_learn_house/app/modules/handwriting/stroke_playback_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('playback pauses, steps, replays, changes speed and closes', (
    tester,
  ) async {
    final data = await tester.runAsync(
      () => HanziStrokeRepository(rootBundle).load('assets/strokes/53e3.json'),
    );
    final c = StrokePlaybackController()..load(data!);
    c.play();
    c.play();
    await tester.pump(const Duration(milliseconds: 600));
    expect(c.visible.value, 1);
    c.pause();
    await tester.pump(const Duration(seconds: 2));
    expect(c.visible.value, 1);
    c.stepForward();
    expect(c.visible.value, 2);
    expect(c.playing.value, isFalse);
    c.replay();
    expect(c.visible.value, 0);
    c.setSpeed(2);
    await tester.pump(const Duration(milliseconds: 900));
    expect(c.visible.value, 3);
    expect(c.playing.value, isFalse);
    c.replay();
    c.onClose();
    await tester.pump(const Duration(seconds: 5));
    expect(c.visible.value, 0);
  });
}
