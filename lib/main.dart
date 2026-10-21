import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'app/routes/app_pages.dart';
import 'app/core/learning_theme.dart';
import 'app/data/learning_content.dart';
import 'app/data/reading_repository.dart';
import 'app/data/story_repository.dart';
import 'app/services/learning_store.dart';
import 'app/services/learning_audio.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _Startup());
}

class _Startup extends StatefulWidget {
  const _Startup();
  @override
  State<_Startup> createState() => _StartupState();
}

class _StartupState extends State<_Startup> {
  late Future<(LearningStore, ContentRepository, LearningAudio)> _loading;
  @override
  void initState() {
    super.initState();
    _loading = _load();
  }

  Future<(LearningStore, ContentRepository, LearningAudio)> _load() async {
    final store = await LearningStore.open(DevicePreferences());
    final content = await ContentRepository.load(rootBundle);
    return (store, content, LearningAudio(AssetAudioBackend()));
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: _loading,
    builder: (context, snapshot) {
      if (snapshot.hasData) {
        return BabyLearnApp(
          store: snapshot.data!.$1,
          content: snapshot.data!.$2,
          audio: snapshot.data!.$3,
        );
      }
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: learningTheme(0),
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: snapshot.hasError
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off_rounded, size: 48),
                        const SizedBox(height: 20),
                        const Text('学习内容暂时无法打开，请重试。'),
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: () => setState(() => _loading = _load()),
                          child: const Text('重新打开'),
                        ),
                      ],
                    )
                  : const CircularProgressIndicator(),
            ),
          ),
        ),
      );
    },
  );
}

class BabyLearnApp extends StatefulWidget {
  const BabyLearnApp({
    super.key,
    required this.store,
    required this.content,
    required this.audio,
    this.drawingPreferences,
  });
  final LearningStore store;
  final ContentRepository content;
  final LearningAudio audio;
  final PreferenceStore? drawingPreferences;
  @override
  State<BabyLearnApp> createState() => _BabyLearnAppState();
}

class _BabyLearnAppState extends State<BabyLearnApp> {
  late final AudioRouteObserver _audioObserver;
  @override
  void initState() {
    super.initState();
    Get.put(widget.store, permanent: true);
    Get.put(widget.content, permanent: true);
    Get.put(ReadingRepository(rootBundle, widget.content), permanent: true);
    Get.put(StoryRepository(rootBundle, widget.content), permanent: true);
    Get.put(widget.audio, permanent: true);
    Get.lazyPut<PreferenceStore>(
      () => widget.drawingPreferences ?? DevicePreferences(),
      fenix: true,
    );
    _audioObserver = AudioRouteObserver(widget.audio);
  }

  @override
  Widget build(BuildContext context) => Obx(
    () => GetMaterialApp(
      title: '宝宝学识屋',
      debugShowCheckedModeBanner: false,
      theme: learningTheme(widget.store.themeIndex.value),
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
      navigatorObservers: [_audioObserver],
      defaultTransition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 180),
    ),
  );
}
