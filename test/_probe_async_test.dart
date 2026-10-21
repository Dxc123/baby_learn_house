import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:baby_learn_house/main.dart';
import 'package:baby_learn_house/app/data/learning_content.dart';
import 'package:baby_learn_house/app/data/reading_repository.dart';
import 'package:baby_learn_house/app/data/story_repository.dart';
import 'package:baby_learn_house/app/services/learning_audio.dart';
import 'package:baby_learn_house/app/services/learning_store.dart';
import 'learning_store_test.dart' show MemoryPreferences;
import 'learning_audio_test.dart' show TestAudioBackend;
import 'route_probe_support.dart';

const asyncRoutes = <String>[
  '/read/poetry-yong-e',
  '/read/poetry-jingyesi?line=poetry-jingyesi-line-02',
  '/story/book-share-toys',
  '/story/dialog-greeting',
  '/practice/hanzi-yi',
  '/resource-licenses',
  '/drawing',
];

void main() {
  setUp(resetRouteProbe);
  tearDown(() => Get.reset());

  for (final config in [
    (844.0, 390.0, 1.0),
    (844.0, 390.0, 2.0),
    (1194.0, 834.0, 2.0),
    (320.0, 568.0, 2.0),
  ]) {
    testWidgets('${config.$1}x${config.$2} scale${config.$3}', (tester) async {
      tester.view.physicalSize = Size(config.$1, config.$2);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = config.$3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final backing = MemoryPreferences();
      final store = await LearningStore.open(backing);
      final content = (await tester.runAsync(
        () => ContentRepository.load(rootBundle),
      ))!;
      final audio = LearningAudio(TestAudioBackend());
      Get.put(store, permanent: true);
      Get.put(content, permanent: true);
      Get.put(ReadingRepository(rootBundle, content), permanent: true);
      Get.put(StoryRepository(rootBundle, content), permanent: true);
      Get.put(audio, permanent: true);
      Get.lazyPut<PreferenceStore>(() => backing, fenix: true);
      await tester.pumpWidget(
        BabyLearnApp(
          store: store,
          content: content,
          audio: audio,
          drawingPreferences: backing,
        ),
      );
      await pumpProbeReady(
        tester,
        find.bySemanticsLabel('宝宝学识屋'),
        reason: 'home',
      );

      for (final route in asyncRoutes) {
        Get.toNamed(route);
        await pumpProbeReady(
          tester,
          routeReady(route),
          reason: '${config.$1}x${config.$2} scale${config.$3} $route',
        );
        expect(Uri.parse(Get.currentRoute).path, Uri.parse(route).path);
        Get.back();
        await pumpProbeReady(
          tester,
          find.bySemanticsLabel('宝宝学识屋'),
          reason: 'return from $route',
        );
        expect(Get.currentRoute, '/home');
      }
      expect(store.learned, isEmpty);
    });
  }
}
