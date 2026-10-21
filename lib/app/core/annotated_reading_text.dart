import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../data/reading_types.dart';
import '../services/learning_store.dart';

class AnnotatedReadingText extends StatelessWidget {
  const AnnotatedReadingText(
    this.text,
    this.pinyin, {
    super.key,
    this.fontSize = 26,
  });
  final String text;
  final List<String> pinyin;
  final double fontSize;
  @override
  Widget build(BuildContext context) => Obx(() {
    final show = Get.find<LearningStore>().showPinyin.value;
    final chars = text.runes.map(String.fromCharCode).toList();
    final units = <Widget>[];
    for (var i = 0; i < chars.length; i++) {
      final children = <Widget>[];
      void add(int at) {
        children.add(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (show)
                Text(
                  pinyin[at],
                  style: TextStyle(
                    fontSize: fontSize * .53,
                    height: 1.3,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              Text(
                chars[at],
                style: TextStyle(fontSize: fontSize, height: 1.5),
              ),
            ],
          ),
        );
      }

      add(i);
      while (i + 1 < chars.length &&
          readingPunctuation.contains(chars[i + 1])) {
        i++;
        add(i);
      }
      units.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: children,
        ),
      );
    }
    return Semantics(
      label: text,
      child: ExcludeSemantics(
        child: Wrap(spacing: 2, runSpacing: 12, children: units),
      ),
    );
  });
}
