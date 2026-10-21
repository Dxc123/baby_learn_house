import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:baby_learn_house/app/modules/drawing/drawing_document.dart';
import 'package:baby_learn_house/app/modules/drawing/drawing_controller.dart';
import 'package:baby_learn_house/app/modules/drawing/drawing_png_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'PNG is white 1024 paper with captured colors and no undone stroke',
    () async {
      final c = DrawingController();
      c.begin(1, .25, .25);
      c.end(1);
      c.setBrush(color: drawingColors[1], width: 20);
      c.begin(1, .5, .5);
      c.move(1, .75, .5);
      c.end(1);
      c.setBrush(color: drawingColors[4]);
      c.begin(1, .8, .8);
      c.end(1);
      c.undo();
      final future = DrawingPngService().encode(c.document);
      c.clear();
      final bytes = await future;
      final image = img.decodePng(bytes)!;
      expect(image.width, 1024);
      expect(image.height, 1024);
      expect(image.getPixel(0, 0).r, 255);
      expect(image.getPixel(256, 256).r, 0x26);
      expect(image.getPixel(600, 512).r, 0xe8);
      expect(image.getPixel(600, 519).r, 0xe8);
      expect(image.getPixel(600, 526).g, 255);
      expect(image.getPixel(819, 819).b, 255);
      final file = File('docs/artifacts/phase-3d/sample.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes);
    },
  );
}
