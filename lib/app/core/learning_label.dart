import 'package:flutter/material.dart';
import '../data/learning_content.dart';
import 'learning_widgets.dart';
import 'learning_theme.dart';

class LearningLabel extends StatelessWidget {
  const LearningLabel(this.item, {super.key, this.fontSize = 24});
  final LearningItem item;
  final double fontSize;
  @override
  Widget build(BuildContext context) {
    if (item.kind == ContentKind.number) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${item.numberValue}',
            style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w700),
          ),
          PinyinText(item.text, item.pinyin, fontSize: fontSize * .7),
        ],
      );
    }
    if (item.kind == ContentKind.hanzi ||
        item.kind == ContentKind.cognition ||
        item.kind == ContentKind.reading ||
        item.kind == ContentKind.pictureBook ||
        item.kind == ContentKind.dialogue) {
      return PinyinText(item.text, item.pinyin, fontSize: fontSize);
    }
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        item.text,
        key: ValueKey('unit-${item.id}'),
        maxLines: 1,
        softWrap: false,
        style: TextStyle(
          fontSize: fontSize,
          height: 1.3,
          fontWeight: FontWeight.w700,
          color: ink,
        ),
      ),
    );
  }
}
