import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../data/learning_content.dart';
import '../../data/hanzi_strokes.dart';
import 'stroke_board.dart';
import 'stroke_playback_controller.dart';
import 'trace_controller.dart';

class HandwritingView extends StatefulWidget {
  const HandwritingView({super.key, required this.itemId});
  final String itemId;
  @override
  State<HandwritingView> createState() => _HandwritingViewState();
}

class _HandwritingViewState extends State<HandwritingView>
    with WidgetsBindingObserver {
  final _playback = StrokePlaybackController();
  final _trace = TraceController();
  late Future<HanziStrokeData> _loading;
  LearningItem? _item;
  bool _tracing = false;
  int _loadRevision = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  void _load() {
    final matches = Get.find<ContentRepository>().items.where(
      (i) => i.id == widget.itemId && i.kind == ContentKind.hanzi,
    );
    _item = matches.isEmpty ? null : matches.first;
    final item = _item;
    final revision = ++_loadRevision;
    _trace.clear();
    _playback.pause();
    _loading = () async {
      if (item?.strokeAsset == null) {
        throw const FormatException('Missing strokes');
      }
      final data = await HanziStrokeRepository(
        rootBundle,
      ).load(item!.strokeAsset!);
      if (!mounted || revision != _loadRevision) return data;
      if (data.character != item.text || data.strokes.length != item.strokes) {
        throw const FormatException('Mismatched strokes');
      }
      _playback.load(data);
      return data;
    }();
  }

  @override
  void didUpdateWidget(covariant HandwritingView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.itemId != widget.itemId) _load();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _playback.pause();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _playback.onClose();
    _trace.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('${_item?.text ?? ''} · 书写练习')),
    body: FutureBuilder<HanziStrokeData>(
      future: _loading,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('笔顺暂时无法打开，请返回认读或重试。'),
                TextButton(
                  onPressed: () => setState(_load),
                  child: const Text('重试'),
                ),
              ],
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Wrap(
              spacing: 12,
              children: [
                ChoiceChip(
                  label: const Text('笔顺演示'),
                  selected: !_tracing,
                  onSelected: (_) => setState(() => _tracing = false),
                ),
                ChoiceChip(
                  label: const Text('自由描红'),
                  selected: _tracing,
                  onSelected: (_) {
                    _playback.pause();
                    setState(() => _tracing = true);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Obx(
                  () => StrokeBoard(
                    data,
                    visibleStrokeCount: _playback.visible.value,
                    trace: _tracing ? _trace : null,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (!_tracing) ...[
              Obx(
                () => Text(
                  '第 ${_playback.visible.value} / ${data.strokes.length} 笔',
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  Obx(
                    () => FilledButton.icon(
                      onPressed: _playback.playing.value
                          ? _playback.pause
                          : _playback.play,
                      icon: Icon(
                        _playback.playing.value
                            ? Icons.pause
                            : Icons.play_arrow,
                      ),
                      label: Text(_playback.playing.value ? '暂停' : '播放'),
                    ),
                  ),
                  OutlinedButton(
                    onPressed: _playback.stepForward,
                    child: const Text('下一笔'),
                  ),
                  OutlinedButton(
                    onPressed: _playback.replay,
                    child: const Text('重放'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Obx(
                () => Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  children: [
                    for (final speed in [.5, 1.0, 2.0])
                      ChoiceChip(
                        label: Text('$speed 倍速'),
                        selected: _playback.speed.value == speed,
                        onSelected: (_) => _playback.setSpeed(speed),
                      ),
                  ],
                ),
              ),
            ] else ...[
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                children: [
                  OutlinedButton(
                    onPressed: _trace.undo,
                    child: const Text('撤销一笔'),
                  ),
                  OutlinedButton(
                    onPressed: _trace.clear,
                    child: const Text('清空'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                '在田字格内自由练习，返回后草稿会清除。练习不会自动标记学会。',
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 20),
            Text(_item!.example, textAlign: TextAlign.center),
          ],
        );
      },
    ),
  );
}
