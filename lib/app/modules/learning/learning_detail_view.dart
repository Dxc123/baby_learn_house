import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/learning_widgets.dart';
import '../../core/learning_label.dart';
import '../../data/learning_content.dart';
import '../../services/learning_audio.dart';
import '../../services/learning_store.dart';
import 'cognition_visual.dart';

class LearningDetailView extends StatefulWidget {
  const LearningDetailView({
    super.key,
    required this.categoryId,
    required this.itemId,
    this.groupId,
  });
  final String categoryId, itemId;
  final String? groupId;
  @override
  State<LearningDetailView> createState() => _LearningDetailViewState();
}

class _LearningDetailViewState extends State<LearningDetailView> {
  bool _saving = false;
  Future<void> _mark(LearningItem item) async {
    if (_saving) return;
    setState(() => _saving = true);
    final store = Get.find<LearningStore>();
    await saveWithFeedback(
      () => store.setLearned(item.id, !store.learned.contains(item.id)),
    );
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _next(List<LearningItem> items, int index) async {
    if (_saving) return;
    if (index == items.length - 1) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _saving = true);
    final next = items[index + 1];
    await saveWithFeedback(
      () => Get.find<LearningStore>().setCursor(widget.categoryId, next.id),
    );
    if (mounted) {
      Get.offNamed(
        Uri(
          path: '/learn/${widget.categoryId}/${next.id}',
          queryParameters: widget.groupId == null
              ? null
              : {'group': widget.groupId!},
        ).toString(),
      );
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final store = Get.find<LearningStore>();
    final content = Get.find<ContentRepository>();
    final audio = Get.find<LearningAudio>();
    return Obx(() {
      final items = content.filteredItems(
        widget.categoryId,
        groupId: widget.groupId,
        order: store.order.value,
      );
      final index = items.indexWhere((i) => i.id == widget.itemId);
      if (index < 0) {
        return const LearningScaffold(
          title: '学习',
          child: Center(child: Text('这个内容暂时找不到了，请返回列表。')),
        );
      }
      final item = items[index];
      final mastered = store.learned.contains(item.id);
      return LearningScaffold(
        title: content.category(widget.categoryId).name,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.note,
                    style: const TextStyle(color: Color(0xFF7F8674)),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${index + 1} / ${items.length}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: (index + 1) / items.length,
              minHeight: 5,
              borderRadius: BorderRadius.circular(4),
              backgroundColor: const Color(0xFFE7EBD8),
            ),
            const SizedBox(height: 24),
            SoftPanel(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
              child: Column(
                children: [
                  if (item.kind == ContentKind.cognition) ...[
                    CognitionVisual(item),
                    const SizedBox(height: 18),
                  ],
                  LearningLabel(
                    item,
                    fontSize: item.kind == ContentKind.cognition ? 44 : 90,
                  ),
                  const SizedBox(height: 22),
                  if (item.audio != null)
                    Obx(
                      () => FilledButton.tonalIcon(
                        key: const ValueKey('play-audio'),
                        onPressed: () => audio.playingId.value == item.audio
                            ? audio.stop()
                            : audio.play(item.audio!),
                        icon: Icon(
                          audio.playingId.value == item.audio
                              ? Icons.stop_circle_outlined
                              : Icons.volume_up_rounded,
                        ),
                        label: Text(
                          audio.playingId.value == item.audio
                              ? '停止播放'
                              : '听一听发音',
                        ),
                      ),
                    )
                  else
                    const Text(
                      '暂缺录音',
                      style: TextStyle(color: Color(0xFF94744C)),
                    ),
                  const SizedBox(height: 10),
                  Text(
                    switch (item.audioQuality) {
                      AudioQuality.demo => '离线合成示范 · 未经教学听审',
                      AudioQuality.verified => '离线录音 · 已校对',
                      AudioQuality.unavailable => '可以先阅读，标准录音后续补充',
                    },
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF929481),
                    ),
                  ),
                  Obx(
                    () => audio.error.value == null
                        ? const SizedBox.shrink()
                        : Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              audio.error.value!,
                              style: const TextStyle(color: Color(0xFFB25A47)),
                            ),
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SoftPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.kind == ContentKind.cognition
                        ? '一起认识'
                        : item.kind == ContentKind.alphabet
                        ? '字母与例词'
                        : '一起读一读',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    item.example,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  for (final word in item.words)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (store.showPinyin.value)
                            Text(
                              word.pinyin.join('  '),
                              style: const TextStyle(color: Color(0xFF7F8674)),
                            ),
                          Text(word.text, style: const TextStyle(fontSize: 24)),
                        ],
                      ),
                    ),
                  if (item.strokes > 0) ...[
                    const SizedBox(height: 16),
                    Text(
                      '笔画：${item.strokes} 画',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (item.strokeAsset != null) ...[
              FilledButton.tonalIcon(
                onPressed: () => Get.toNamed('/practice/${item.id}'),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('笔顺与描红'),
              ),
              const SizedBox(height: 12),
            ],
            FilledButton.icon(
              key: const ValueKey('mark-learned'),
              onPressed: _saving ? null : () => _mark(item),
              icon: Icon(
                mastered
                    ? Icons.check_circle_rounded
                    : Icons.check_circle_outline_rounded,
              ),
              label: Text(
                _saving
                    ? '正在保存…'
                    : mastered
                    ? '已学会 · 点击撤销'
                    : '我已学会',
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              key: const ValueKey('next-item'),
              onPressed: _saving ? null : () => _next(items, index),
              icon: Icon(
                index == items.length - 1
                    ? Icons.grid_view_rounded
                    : Icons.arrow_forward_rounded,
              ),
              label: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  index == items.length - 1
                      ? '本组已看完 · 返回列表'
                      : '下一个：${items[index + 1].text}',
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                '不用着急，按自己的节奏慢慢学',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Color(0xFF929481)),
              ),
            ),
          ],
        ),
      );
    });
  }
}
