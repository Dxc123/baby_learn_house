import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/learning_store.dart';
import 'learning_theme.dart';

/// A Chinese character and its reading always wrap as one unit.
class PinyinText extends StatelessWidget {
  const PinyinText(
    this.text,
    this.pinyin, {
    super.key,
    this.fontSize = 20,
    this.color,
  });
  final String text;
  final List<String> pinyin;
  final double fontSize;
  final Color? color;
  @override
  Widget build(BuildContext context) => Obx(() {
    final show =
        Get.find<LearningStore>().showPinyin.value &&
        pinyin.any((p) => p.isNotEmpty);
    final characters = text.runes.toList();
    return Semantics(
      label: text,
      child: ExcludeSemantics(
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: 4,
          runSpacing: 8,
          children: [
            for (var i = 0; i < characters.length; i++)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (show)
                    Text(
                      i < pinyin.length ? pinyin[i] : '',
                      style: TextStyle(
                        fontSize: fontSize * .57,
                        color: color ?? ink.withValues(alpha: .7),
                        height: 1.25,
                      ),
                    ),
                  Text(
                    String.fromCharCode(characters[i]),
                    style: TextStyle(
                      fontSize: fontSize,
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                      color: color ?? ink,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  });
}

class LearningScaffold extends StatelessWidget {
  const LearningScaffold({
    super.key,
    required this.title,
    required this.child,
    this.actions,
  });
  final String title;
  final Widget child;
  final List<Widget>? actions;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: IconButton(
        tooltip: '返回',
        onPressed: () => Get.back(),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
      ),
      actions: actions,
    ),
    body: SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: child,
        ),
      ),
    ),
  );
}

Future<bool> saveWithFeedback(Future<void> Function() save) async {
  try {
    await save();
    return true;
  } catch (_) {
    Get.snackbar(
      '保存失败',
      '这次修改尚未保存，请稍后重试。',
      snackPosition: SnackPosition.BOTTOM,
    );
    return false;
  }
}

class SoftPanel extends StatelessWidget {
  const SoftPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFFECEBDB)),
    ),
    child: child,
  );
}
