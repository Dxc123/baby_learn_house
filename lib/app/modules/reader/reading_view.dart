import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/learning_widgets.dart';
import '../../core/annotated_reading_text.dart';
import '../../data/learning_content.dart';
import '../../data/reading_repository.dart';
import '../../data/reading_types.dart';
import 'reading_controller.dart';

class ReadingView extends StatefulWidget {
  const ReadingView({super.key, required this.readingId, this.lineId});
  final String readingId;
  final String? lineId;
  @override
  State<ReadingView> createState() => _ReadingViewState();
}

class _ReadingViewState extends State<ReadingView> {
  late Future<ReadingPassage> _loading;
  ReadingController? _controller;
  Worker? _positionWorker;
  final _lineKeys = <String, GlobalKey>{};
  int _generation = 0;
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final generation = ++_generation;
    _positionWorker?.dispose();
    _controller?.onClose();
    _controller = null;
    _lineKeys.clear();
    _loading = () async {
      final p = await Get.find<ReadingRepository>().load(widget.readingId);
      if (!mounted || generation != _generation) return p;
      final items = Get.find<ContentRepository>().items
          .where((i) => i.readingId == p.id)
          .toList();
      final c = ReadingController(
        p,
        Get.find(),
        Get.find(),
        wholeItemId: p.categoryId == 'classics' ? null : items.single.id,
      );
      _controller = c;
      for (final l in p.lines) {
        _lineKeys[l.id] = GlobalKey();
      }
      _positionWorker = ever(c.currentLineId, (_) => _reveal());
      await c.open(requestedLineId: widget.lineId);
      if (mounted &&
          generation == _generation &&
          c.currentLineId.value != p.lines.first.id) {
        _reveal();
      }
      return p;
    }();
  }

  void _reveal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final context =
          _lineKeys[_controller?.currentLineId.value]?.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(
          context,
          alignment: .12,
          duration: const Duration(milliseconds: 180),
        );
      }
    });
  }

  @override
  void didUpdateWidget(covariant ReadingView old) {
    super.didUpdateWidget(old);
    if (old.readingId != widget.readingId || old.lineId != widget.lineId) {
      _load();
    }
  }

  @override
  void dispose() {
    ++_generation;
    _positionWorker?.dispose();
    _controller?.onClose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LearningScaffold(
    title: '一起读一读',
    actions: [
      IconButton(
        tooltip: '停止朗读',
        onPressed: () => _controller?.stop(),
        icon: const Icon(Icons.stop_circle_outlined),
      ),
    ],
    child: FutureBuilder<ReadingPassage>(
      future: _loading,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('这篇内容暂时无法打开，请返回或重试。'),
                  TextButton(
                    onPressed: () => setState(_load),
                    child: const Text('重试'),
                  ),
                ],
              ),
            ),
          );
        }
        if (!snapshot.hasData || _controller == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final p = snapshot.data!, c = _controller!;
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Obx(
              () => SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AnnotatedReadingText(p.title, p.titlePinyin, fontSize: 28),
                    const SizedBox(height: 12),
                    Text('${p.author} · ${p.sourceLabel}'),
                    const SizedBox(height: 12),
                    Text(p.intro),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          onPressed: () => c.playFromCurrent(),
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('从当前句连续朗读'),
                        ),
                        OutlinedButton(
                          onPressed: () => c.stop(),
                          child: const Text('停止朗读'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (c.audio.sequencePlaying.value) const Text('正在朗读…'),
                    const Text(
                      '离线合成示范 · 未经教学听审；无录音时可继续阅读。',
                      style: TextStyle(fontSize: 12),
                    ),
                    if (c.warning.value != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          c.warning.value!,
                          style: const TextStyle(color: Colors.brown),
                        ),
                      ),
                    if (c.audio.error.value != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          c.audio.error.value!,
                          style: const TextStyle(color: Colors.brown),
                        ),
                      ),
                    const SizedBox(height: 12),
                    for (final l in p.lines)
                      Padding(
                        key: _lineKeys[l.id],
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Semantics(
                          label: c.currentLineId.value == l.id ? '当前句' : '',
                          child: InkWell(
                            onTap: () => c.selectLine(l.id),
                            borderRadius: BorderRadius.circular(18),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: c.currentLineId.value == l.id
                                    ? const Color(0xFFE7EEDB)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: c.currentLineId.value == l.id
                                      ? Theme.of(context).colorScheme.primary
                                      : const Color(0xFFE5E8DD),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AnnotatedReadingText(l.text, l.pinyin),
                                  const SizedBox(height: 12),
                                  Text(
                                    l.explanation,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  TextButton.icon(
                                    key: ValueKey('play-${l.id}'),
                                    onPressed: () => c.playLine(l.id),
                                    icon: const Icon(Icons.volume_up_outlined),
                                    label: Text(
                                      l.audio == null ? '暂缺录音 · 继续阅读' : '听这一句',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        OutlinedButton(
                          onPressed: c.currentLineId.value == p.lines.first.id
                              ? null
                              : () => c.selectLine(
                                  p
                                      .lines[p.lines.indexWhere(
                                            (l) =>
                                                l.id == c.currentLineId.value,
                                          ) -
                                          1]
                                      .id,
                                ),
                          child: const Text('上一句'),
                        ),
                        OutlinedButton(
                          onPressed: c.currentLineId.value == p.lines.last.id
                              ? null
                              : () => c.selectLine(
                                  p
                                      .lines[p.lines.indexWhere(
                                            (l) =>
                                                l.id == c.currentLineId.value,
                                          ) +
                                          1]
                                      .id,
                                ),
                          child: Text(
                            c.currentLineId.value == p.lines.last.id
                                ? '本篇已读完'
                                : '下一句',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      key: const ValueKey('reader-learned'),
                      onPressed: c.saving.value
                          ? null
                          : () => c.toggleLearned(),
                      icon: const Icon(Icons.check_circle_outline),
                      label: Text(
                        c.saving.value
                            ? '正在保存…'
                            : c.store.learned.contains(c.learnedId)
                            ? '已学会 · 点击撤销'
                            : p.categoryId == 'classics'
                            ? '这一句我已学会'
                            : '这一篇我已学会',
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '出处：${p.provenance['url']}\n${p.provenance['edition']}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}
