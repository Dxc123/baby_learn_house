import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/learning_widgets.dart';
import '../../data/learning_content.dart';
import '../../services/learning_store.dart';
import 'quantity_objects.dart';

class NumberDetailView extends StatefulWidget {
  const NumberDetailView({super.key, required this.itemId});
  final String itemId;
  @override
  State<NumberDetailView> createState() => _NumberDetailViewState();
}

class _NumberDetailViewState extends State<NumberDetailView> {
  bool busy = false;
  Future<void> _mark(LearningItem item) async {
    if (busy) return;
    setState(() => busy = true);
    final store = Get.find<LearningStore>();
    await saveWithFeedback(
      () => store.setLearned(item.id, !store.learned.contains(item.id)),
    );
    if (mounted) setState(() => busy = false);
  }

  Future<void> _go(LearningItem item) async {
    if (busy) return;
    final origin = ModalRoute.of(context);
    setState(() => busy = true);
    final saved = await saveWithFeedback(
      () => Get.find<LearningStore>().setCursor('numbers', item.id),
    );
    if (mounted && saved && origin?.isCurrent == true) {
      Get.offNamed('/learn/numbers/${item.id}');
    }
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final items = Get.find<ContentRepository>().sortedItems('numbers', 'grade');
    final index = items.indexWhere((i) => i.id == widget.itemId);
    if (index < 0) {
      return const LearningScaffold(
        title: '学数字',
        child: Center(child: Text('这个内容暂时找不到了，请返回列表。')),
      );
    }
    final item = items[index];
    final store = Get.find<LearningStore>();
    return LearningScaffold(
      title: '学数字',
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('${index + 1} / ${items.length}', textAlign: TextAlign.center),
          Text(
            '${item.numberValue}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 90, fontWeight: FontWeight.w700),
          ),
          PinyinText(item.text, item.pinyin, fontSize: 36),
          const SizedBox(height: 20),
          SoftPanel(child: QuantityObjects(count: item.numberValue!)),
          const SizedBox(height: 16),
          Text(
            item.example,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22),
          ),
          const SizedBox(height: 16),
          const Text('暂缺录音', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Obx(
            () => FilledButton(
              key: const ValueKey('number-learned'),
              onPressed: busy ? null : () => _mark(item),
              child: Text(
                store.learned.contains(item.id) ? '已学会 · 点击撤销' : '这个数字我已学会',
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              OutlinedButton(
                key: const ValueKey('number-previous'),
                onPressed: busy || index == 0
                    ? null
                    : () => _go(items[index - 1]),
                child: const Text('上一个'),
              ),
              OutlinedButton(
                key: const ValueKey('number-next'),
                onPressed: busy || index == items.length - 1
                    ? null
                    : () => _go(items[index + 1]),
                child: Text(index == items.length - 1 ? '已经是最后一个' : '下一个'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
