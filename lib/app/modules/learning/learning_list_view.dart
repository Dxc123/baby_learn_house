import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/learning_widgets.dart';
import '../../core/learning_label.dart';
import '../../data/learning_content.dart';
import '../../services/learning_store.dart';
import '../../routes/app_pages.dart';
import '../story/story_scene.dart';

class LearningListView extends StatefulWidget {
  const LearningListView({super.key, required this.categoryId});
  final String categoryId;
  @override
  State<LearningListView> createState() => _LearningListViewState();
}

class _LearningListViewState extends State<LearningListView> {
  String _query = '', _filter = 'all';
  String? _group;
  bool _opening = false;
  Future<void> _open(LearningItem item) async {
    if (_opening) return;
    _opening = true;
    await saveWithFeedback(
      () => Get.find<LearningStore>().setCursor(widget.categoryId, item.id),
    );
    if (mounted) {
      await Get.toNamed(
        item.storyId != null
            ? storyRoute(item)
            : item.kind == ContentKind.reading
            ? readingRoute(item)
            : Uri(
                path: '/learn/${widget.categoryId}/${item.id}',
                queryParameters: _group == null ? null : {'group': _group!},
              ).toString(),
      );
    }
    _opening = false;
  }

  @override
  Widget build(BuildContext context) {
    final content = Get.find<ContentRepository>();
    final store = Get.find<LearningStore>();
    final category = content.category(widget.categoryId);
    final groups = content.groupsFor(widget.categoryId);
    return LearningScaffold(
      title: category.name,
      child: Obx(() {
        final all = content.filteredItems(
          widget.categoryId,
          groupId: _group,
          order: store.order.value,
        );
        final learned = store.learned.toSet();
        final count = all.where((i) => learned.contains(i.id)).length;
        final filtered = content
            .filteredItems(
              widget.categoryId,
              groupId: _group,
              order: store.order.value,
              query: _query,
            )
            .where(
              (item) =>
                  _filter == 'all' ||
                  (_filter == 'learned') == learned.contains(item.id),
            )
            .toList();
        final resume = content.resumeItem(
          widget.categoryId,
          groupId: _group,
          order: store.order.value,
          cursor: store.cursors[widget.categoryId],
          learned: learned,
        );
        return ListView(
          key: ValueKey('list-${widget.categoryId}'),
          padding: const EdgeInsets.all(20),
          children: [
            PinyinText(category.name, category.pinyin, fontSize: 28),
            if (category.kind == ContentKind.hanzi)
              TextButton.icon(
                onPressed: () => Get.toNamed('/worksheet'),
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('制作 A4 字帖'),
              ),
            const SizedBox(height: 10),
            Text(
              '${all.length} 个学习内容 · 已学会 $count 个',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF858675)),
            ),
            if (groups.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    key: const ValueKey('group-all'),
                    label: const Text('全部分组'),
                    selected: _group == null,
                    onSelected: (_) => setState(() => _group = null),
                  ),
                  for (final group in groups)
                    ChoiceChip(
                      key: ValueKey('group-${group.id}'),
                      label: Text(group.title),
                      selected: _group == group.id,
                      onSelected: (_) => setState(() => _group = group.id),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            if (resume != null)
              FilledButton.icon(
                onPressed: () => _open(resume),
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(
                  store.cursors[widget.categoryId] == null ? '开始学习' : '继续学习',
                ),
              ),
            const SizedBox(height: 20),
            TextField(
              decoration: InputDecoration(
                hintText: category.kind == ContentKind.alphabet
                    ? '搜索英文字母'
                    : '搜索名称或拼音',
                prefixIcon: const Icon(Icons.search_rounded),
              ),
              onChanged: (value) => setState(() => _query = value.trim()),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final entry in {
                  'all': '全部',
                  'learned': '已学会',
                  'unlearned': '还未学',
                }.entries)
                  ChoiceChip(
                    key: ValueKey('filter-${entry.key}'),
                    label: Text(entry.value),
                    selected: _filter == entry.key,
                    onSelected: (_) => setState(() => _filter = entry.key),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            if (filtered.isEmpty)
              const SoftPanel(
                child: Column(
                  children: [
                    Icon(
                      Icons.spa_outlined,
                      size: 44,
                      color: Color(0xFF9FAE8E),
                    ),
                    SizedBox(height: 16),
                    Text('还没有匹配的内容'),
                    Text('换个关键词，或切换到“全部”看看。', textAlign: TextAlign.center),
                  ],
                ),
              ),
            for (final item in filtered)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    key: ValueKey('item-${item.id}'),
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => _open(item),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 60,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF2F5E8),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: item.coverSceneId != null
                                ? StoryScene(
                                    sceneId: item.coverSceneId!,
                                    alt: '${item.text}封面',
                                  )
                                : Icon(
                                    item.kind == ContentKind.cognition
                                        ? Icons.explore_outlined
                                        : item.kind == ContentKind.alphabet
                                        ? Icons.abc_rounded
                                        : Icons.menu_book_outlined,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    size: 28,
                                  ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                LearningLabel(item, fontSize: 23),
                                const SizedBox(height: 5),
                                Text(
                                  learned.contains(item.id)
                                      ? '已学会 ✓'
                                      : item.audio == null
                                      ? item.storyId != null
                                            ? (item.coverSceneId != null
                                                  ? '6页图文 · 点击打开'
                                                  : '双角色陪练 · 点击打开')
                                            : item.kind == ContentKind.reading
                                            ? '逐句阅读 · 点击打开'
                                            : '暂缺录音 · 可以阅读'
                                      : '点一点，开始探索',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: learned.contains(item.id)
                                        ? Theme.of(context).colorScheme.primary
                                        : const Color(0xFF929481),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Text(switch (category.kind) {
              ContentKind.pinyin => '声母、韵母和整体认读音节。部分录音待补充，已有合成示范不代替标准教学录音。',
              ContentKind.hanzi => '支持笔顺演示、自由描红与 A4 字帖。描红不评分，也不会自动标记学会。',
              ContentKind.alphabet => '认识大小写与字母名称。例词仅供阅读，本页不提供自然拼读评分。',
              ContentKind.reading => '逐句读一读，按自己的节奏学习。听完不会自动标记学会。',
              ContentKind.pictureBook => '图文一起读，按整本手动标记，读到末页不会自动标记学会。',
              ContentKind.dialogue => '和家长分角色练一练，可以换成自己的话。录音后续补充。',
              ContentKind.number => '数字和数量一起认识。按数值排列，录音后续补充。',
              _ => '图形为概念示意，结合文字说明一起认识。发音为离线合成示范。',
            }, style: const TextStyle(fontSize: 12, color: Color(0xFF8A8D7B))),
          ],
        );
      }),
    );
  }
}
