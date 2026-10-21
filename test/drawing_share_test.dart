import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baby_learn_house/app/modules/drawing/drawing_share_service.dart';
import 'package:baby_learn_house/app/modules/drawing/drawing_png_service.dart';
import 'package:baby_learn_house/app/modules/drawing/drawing_document.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('baby_learn_house/drawing_share');
  test('share validates PNG and forwards immutable bytes and anchor', () async {
    final service = DrawingShareService();
    var calls = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls++;
          expect(call.method, 'sharePng');
          expect(call.arguments['anchor']['width'], 48.0);
          expect((call.arguments['bytes'] as Uint8List).length, greaterThan(8));
          return {'status': 'presented'};
        });
    for (final bytes in [
      Uint8List(0),
      Uint8List(12 * 1024 * 1024 + 1),
      Uint8List.fromList([1, 2, 3]),
    ]) {
      await expectLater(
        service.openPng(bytes, anchor: const Rect.fromLTWH(0, 0, 48, 48)),
        throwsArgumentError,
      );
    }
    final png = await DrawingPngService().encode(DrawingDocument());
    await service.openPng(png, anchor: const Rect.fromLTWH(0, 0, 48, 48));
    expect(calls, 1);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          channel,
          (_) async => throw PlatformException(code: 'presenter'),
        );
    await expectLater(
      service.openPng(png, anchor: const Rect.fromLTWH(0, 0, 48, 48)),
      throwsA(isA<PlatformException>()),
    );
  });
}
