import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/learning_widgets.dart';
import '../../data/story_repository.dart';
import '../../data/story_types.dart';
import '../../services/learning_store.dart';
import 'story_controller.dart';
import 'picture_book_body.dart';
import 'dialogue_body.dart';

class StoryView extends StatefulWidget {
  const StoryView({super.key, required this.storyId, this.unitId});
  final String storyId;
  final String? unitId;
  @override
  State<StoryView> createState() => _StoryViewState();
}

class _StoryViewState extends State<StoryView> {
  late Future<StoryDocument> _loading;
  StoryController? _controller;
  final _scroll = ScrollController();
  int _generation = 0;
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final generation = ++_generation;
    _controller?.onClose();
    _controller = null;
    _loading = () async {
      final doc = await Get.find<StoryRepository>().load(widget.storyId);
      if (!mounted || generation != _generation) return doc;
      final controller = StoryController(
        doc,
        Get.find<LearningStore>(),
        itemId: doc.id,
      );
      _controller = controller;
      await controller.open(requestedUnitId: widget.unitId);
      return doc;
    }();
  }

  @override
  void didUpdateWidget(covariant StoryView old) {
    super.didUpdateWidget(old);
    if (old.storyId != widget.storyId || old.unitId != widget.unitId) _load();
  }

  void _move(int delta) {
    final c = _controller!;
    final index = c.document.units.indexOf(c.currentUnit);
    final next = index + delta;
    if (next < 0 || next >= c.document.units.length) return;
    c.selectUnit(c.document.units[next].id);
    if (c.document.kind == StoryKind.pictureBook && _scroll.hasClients) {
      _scroll.jumpTo(0);
    }
  }

  @override
  void dispose() {
    _generation++;
    _controller?.onClose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LearningScaffold(
    title: '一起读故事',
    child: FutureBuilder<StoryDocument>(
      future: _loading,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('这个故事暂时无法打开，请返回目录或重试。'),
                  const SizedBox(height: 12),
                  FilledButton(
                    key: const ValueKey('story-retry'),
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
        final doc = snapshot.data!;
        final c = _controller!;
        return Obx(() {
          final index = doc.units.indexOf(c.currentUnit);
          final store = c.store;
          return SingleChildScrollView(
            controller: _scroll,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PinyinText(doc.title, doc.titlePinyin, fontSize: 28),
                const SizedBox(height: 12),
                Text(doc.intro, style: const TextStyle(fontSize: 17)),
                const SizedBox(height: 16),
                if (c.warning.value != null) ...[
                  Text(
                    c.warning.value!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  TextButton(
                    onPressed: () => c.selectUnit(c.currentUnitId.value),
                    child: const Text('重试保存位置'),
                  ),
                ],
                if (doc.kind == StoryKind.pictureBook)
                  PictureBookBody(document: doc, controller: c)
                else
                  DialogueBody(document: doc, controller: c),
                const SizedBox(height: 18),
                const Text('可以分角色读一读，录音后续补充。', textAlign: TextAlign.center),
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    OutlinedButton(
                      key: const ValueKey('story-previous'),
                      onPressed: index > 0 ? () => _move(-1) : null,
                      child: Text(
                        doc.kind == StoryKind.pictureBook ? '上一页' : '上一轮',
                      ),
                    ),
                    OutlinedButton(
                      key: const ValueKey('story-next'),
                      onPressed: index < doc.units.length - 1
                          ? () => _move(1)
                          : null,
                      child: Text(
                        doc.kind == StoryKind.pictureBook ? '下一页' : '下一轮',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FilledButton(
                  key: const ValueKey('story-learned'),
                  onPressed: c.saving.value ? null : c.markLearned,
                  child: Text(
                    store.learned.contains(doc.id)
                        ? '已学会 · 点击撤销'
                        : doc.kind == StoryKind.pictureBook
                        ? '这本我已学会'
                        : '这一场我已学会',
                  ),
                ),
              ],
            ),
          );
        });
      },
    ),
  );
}
