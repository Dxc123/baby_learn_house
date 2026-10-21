import 'package:flutter/material.dart';
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

const routes = <String>[
  '/learn/pinyin',
  '/learn/chinese',
  '/learn/chinese/hanzi-yi',
  '/learn/numbers/number-0',
  '/learn/animals/animal-cat',
  '/read/poetry-yong-e',
  '/story/book-share-toys',
  '/story/dialog-greeting',
  '/practice/hanzi-yi',
  '/math/count',
  '/math/plus-block',
  '/math/hundred',
  '/math/plus',
  '/worksheet',
  '/drawing',
  '/settings',
  '/resource-licenses',
];

Future<void> probe(
  WidgetTester tester,
  double w,
  double h,
  double scale,
) async {
  tester.view.physicalSize = Size(w, h);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final backing = MemoryPreferences();
  final store = await LearningStore.open(backing);
  final content = (await tester.runAsync(
    () => ContentRepository.load(rootBundle),
  ))!;
  Get.put(store, permanent: true);
  Get.put(content, permanent: true);
  Get.put(ReadingRepository(rootBundle, content), permanent: true);
  Get.put(StoryRepository(rootBundle, content), permanent: true);
  Get.put(LearningAudio(TestAudioBackend()), permanent: true);
  Get.lazyPut<PreferenceStore>(() => backing, fenix: true);
  await tester.pumpWidget(
    BabyLearnApp(
      store: store,
      content: content,
      audio: Get.find<LearningAudio>(),
      drawingPreferences: backing,
    ),
  );
  await tester.pumpAndSettle();
  for (final route in routes) {
    Get.toNamed(route);
    await pumpProbeReady(
      tester,
      routeReady(route),
      reason: '${w}x$h scale$scale $route',
    );
    expect(Uri.parse(Get.currentRoute).path, Uri.parse(route).path);
    if (route == '/resource-licenses') {
      await tester.scrollUntilVisible(
        find.byWidgetPredicate(
          (widget) =>
              widget is SelectableText &&
              (widget.data?.contains('ARPHIC') ?? false),
        ),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byType(SelectableText), findsWidgets);
      expect(
        tester.takeException(),
        isNull,
        reason: 'scroll license at ${w}x$h scale$scale',
      );
    }
    Get.back();
    await pumpProbeReady(
      tester,
      find.bySemanticsLabel('宝宝学识屋'),
      reason: 'return from $route',
    );
    expect(Get.currentRoute, '/home');
  }
  expect(store.learned, isEmpty);
}

void main() {
  setUp(resetRouteProbe);
  tearDown(() => Get.reset());
  testWidgets('portrait 390x844', (tester) => probe(tester, 390, 844, 1));
  testWidgets('narrow 320x568 scale2', (tester) => probe(tester, 320, 568, 2));
  testWidgets('landscape 844x390', (tester) => probe(tester, 844, 390, 1));
  testWidgets(
    'landscape 844x390 scale2',
    (tester) => probe(tester, 844, 390, 2),
  );
  testWidgets(
    'ipad landscape 1194x834 scale2',
    (tester) => probe(tester, 1194, 834, 2),
  );
}
