import 'package:flutter/material.dart';
import 'story_scene_registry.dart';
import 'story_scene_painter.dart';

class StoryScene extends StatelessWidget {
  const StoryScene({super.key, required this.sceneId, required this.alt});
  final String sceneId, alt;
  @override
  Widget build(BuildContext context) {
    if (!supportedStoryScenes.contains(sceneId)) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Text('这页插图暂时无法显示'),
      );
    }
    return Semantics(
      label: alt,
      image: true,
      child: ExcludeSemantics(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: CustomPaint(painter: StoryScenePainter(sceneId)),
          ),
        ),
      ),
    );
  }
}
