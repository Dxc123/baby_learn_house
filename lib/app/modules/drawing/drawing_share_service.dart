import 'package:flutter/services.dart';

class DrawingShareService {
  static const channel = MethodChannel('baby_learn_house/drawing_share');
  Future<void> openPng(Uint8List png, {required Rect anchor}) async {
    const signature = [137, 80, 78, 71, 13, 10, 26, 10];
    if (png.length < 24 ||
        png.length > 12 * 1024 * 1024 ||
        !List.generate(8, (i) => png[i] == signature[i]).every((v) => v) ||
        ![
          anchor.left,
          anchor.top,
          anchor.width,
          anchor.height,
        ].every((v) => v.isFinite) ||
        anchor.width <= 0 ||
        anchor.height <= 0) {
      throw ArgumentError('无效PNG或分享位置');
    }
    final result = await channel.invokeMapMethod<String, dynamic>('sharePng', {
      'bytes': Uint8List.fromList(png),
      'anchor': {
        'x': anchor.left,
        'y': anchor.top,
        'width': anchor.width,
        'height': anchor.height,
      },
    });
    if (result?['status'] != 'presented') {
      throw PlatformException(code: 'not_presented', message: '分享面板未打开');
    }
  }
}
