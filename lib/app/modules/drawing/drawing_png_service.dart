import 'dart:ui' as ui;
import 'dart:typed_data';
import 'drawing_document.dart';
import 'drawing_painter.dart';

class DrawingPngService {
  Future<Uint8List> encode(DrawingDocument snapshot) async {
    snapshot.validate();
    final recorder = ui.PictureRecorder();
    paintDrawing(ui.Canvas(recorder), const ui.Size(1024, 1024), snapshot);
    final picture = recorder.endRecording();
    try {
      final image = await picture.toImage(1024, 1024);
      try {
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        if (data == null || data.lengthInBytes == 0) {
          throw StateError('PNG编码失败');
        }
        return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      } finally {
        image.dispose();
      }
    } finally {
      picture.dispose();
    }
  }
}
