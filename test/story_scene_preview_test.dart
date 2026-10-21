import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';
import 'package:baby_learn_house/app/modules/story/story_scene_painter.dart';

void main() {
  test('render all18 scenes using production painter', () async {
    for (final prefix in ['share', 'tidy', 'feelings']) {
      final sheet = ui.PictureRecorder();
      final canvas = ui.Canvas(sheet);
      for (var i = 1; i <= 6; i++) {
        final id = '$prefix-${i.toString().padLeft(2, '0')}';
        final recorder = ui.PictureRecorder();
        paintStoryScene(ui.Canvas(recorder), const ui.Size(640, 480), id);
        final pic = recorder.endRecording();
        final image = await pic.toImage(640, 480);
        if (const bool.fromEnvironment('WRITE_STORY_PREVIEWS')) {
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File('docs/artifacts/phase-3c-scenes/$id.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes!.buffer.asUint8List());
        }
        canvas.save();
        canvas.translate(((i - 1) % 3) * 320.0, ((i - 1) ~/ 3) * 240.0);
        canvas.scale(.5);
        canvas.drawImage(image, ui.Offset.zero, ui.Paint());
        canvas.restore();
        image.dispose();
        pic.dispose();
      }
      final picture = sheet.endRecording();
      final image = await picture.toImage(960, 480);
      if (const bool.fromEnvironment('WRITE_STORY_PREVIEWS')) {
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          'docs/artifacts/phase-3c-scenes/$prefix-contact.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
      }
      image.dispose();
      picture.dispose();
    }
  });
}
