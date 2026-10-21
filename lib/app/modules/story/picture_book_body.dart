import 'package:flutter/material.dart';
import '../../core/annotated_reading_text.dart';
import '../../data/story_types.dart';
import 'story_controller.dart';
import 'story_scene.dart';

class PictureBookBody extends StatelessWidget {
  const PictureBookBody({
    super.key,
    required this.document,
    required this.controller,
  });
  final StoryDocument document;
  final StoryController controller;
  @override
  Widget build(BuildContext context) {
    final unit = controller.currentUnit;
    final index = document.units.indexOf(unit);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${index + 1} / ${document.units.length}',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        StoryScene(
          key: ValueKey('scene-${unit.sceneId}'),
          sceneId: unit.sceneId!,
          alt:
              document.sceneMetadata[unit.sceneId]?['alt'] as String? ??
              '这页故事插图',
        ),
        const SizedBox(height: 18),
        AnnotatedReadingText(unit.text, unit.pinyin),
        if (index == document.units.length - 1) ...[
          const SizedBox(height: 16),
          const Text(
            '这本读完啦',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24),
          ),
          Text(document.prompt, style: const TextStyle(fontSize: 18)),
        ],
      ],
    );
  }
}
