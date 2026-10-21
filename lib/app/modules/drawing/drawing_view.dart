import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/learning_store.dart';
import 'drawing_controller.dart';
import 'drawing_document.dart';
import 'drawing_draft_store.dart';
import 'drawing_painter.dart';
import 'drawing_png_service.dart';
import 'drawing_share_service.dart';

class DrawingView extends StatefulWidget {
  const DrawingView({
    super.key,
    this.draftStore,
    this.shareService,
    this.pngService,
  });
  final DrawingDraftStore? draftStore;
  final DrawingShareService? shareService;
  final DrawingPngService? pngService;
  @override
  State<DrawingView> createState() => _DrawingViewState();
}

class _DrawingViewState extends State<DrawingView> with WidgetsBindingObserver {
  final controller = DrawingController();
  late final DrawingDraftStore store;
  final exportKey = GlobalKey();
  bool loading = true,
      loadFailed = false,
      exporting = false,
      leaving = false,
      allowPop = false;
  int submitted = 0, loadGeneration = 0;
  Size? paperSize;
  String? exportMessage;
  @override
  void initState() {
    super.initState();
    store =
        widget.draftStore ??
        DrawingDraftStore(
          Get.isRegistered<PreferenceStore>()
              ? Get.find<PreferenceStore>()
              : DevicePreferences(),
        );
    controller.addListener(_changed);
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  Future<void> _load() async {
    final generation = ++loadGeneration;
    setState(() => loading = true);
    try {
      final doc = await store.load();
      if (!mounted || generation != loadGeneration) return;
      if (doc != null) controller.restore(doc);
      setState(() {
        loading = false;
        loadFailed = false;
      });
    } catch (_) {
      if (mounted && generation == loadGeneration) {
        setState(() {
          loading = false;
          loadFailed = true;
        });
      }
    }
  }

  void _changed() {
    if (!mounted) return;
    if (!loading &&
        controller.revision != submitted &&
        (!loadFailed || controller.contentRevision > 0)) {
      submitted = controller.revision;
      loadFailed = false;
      store.submit(controller.document, submitted);
    }
    setState(() {});
  }

  @override
  void didChangeMetrics() => controller.cancel();
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      controller.cancel();
      // Completed edits were submitted synchronously by _changed.
      store.flush().catchError((Object _) {});
    }
  }

  Future<void> _clear() async {
    controller.cancel();
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空画板'),
        content: const Text('清空当前画面？可以在本次打开期间撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确认清空'),
          ),
        ],
      ),
    );
    if (mounted && yes == true) controller.clear();
  }

  Future<void> _export() async {
    if (exporting || controller.document.strokes.isEmpty) return;
    controller.cancel();
    final snapshot = controller.document;
    final box = exportKey.currentContext?.findRenderObject() as RenderBox?;
    final anchor = box == null
        ? const Rect.fromLTWH(0, 0, 48, 48)
        : box.localToGlobal(Offset.zero) & box.size;
    setState(() {
      exporting = true;
      exportMessage = null;
    });
    try {
      final bytes = await (widget.pngService ?? DrawingPngService()).encode(
        snapshot,
      );
      if (!mounted) return;
      await (widget.shareService ?? DrawingShareService()).openPng(
        bytes,
        anchor: anchor,
      );
      if (mounted) setState(() => exportMessage = '分享面板已打开');
    } catch (_) {
      if (mounted) setState(() => exportMessage = '导出未完成，请重试。');
    } finally {
      if (mounted) setState(() => exporting = false);
    }
  }

  Future<void> _leave() async {
    if (leaving) return;
    leaving = true;
    controller.cancel();
    try {
      await store.flush();
    } catch (_) {
      if (!mounted) return;
      final leave = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('画面尚未保存'),
          content: const Text('可以留在画板重试，或仍然离开。未保存的修改可能丢失。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('留在画板'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('仍然离开'),
            ),
          ],
        ),
      );
      if (leave != true) {
        leaving = false;
        return;
      }
    }
    if (!mounted) return;
    setState(() => allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    loadGeneration++;
    WidgetsBinding.instance.removeObserver(this);
    controller.removeListener(_changed);
    controller.dispose();
    store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: allowPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('小小画板'),
          leading: BackButton(onPressed: _leave),
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('选一种颜色，画出你的发现。'),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (var i = 0; i < drawingColors.length; i++)
                              Semantics(
                                selected:
                                    controller.document.color ==
                                    drawingColors[i],
                                child: SizedBox(
                                  width: 56,
                                  height: 56,
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      side: BorderSide(
                                        color: Color(drawingColors[i]),
                                        width:
                                            controller.document.color ==
                                                drawingColors[i]
                                            ? 3
                                            : 1,
                                      ),
                                    ),
                                    onPressed: () => controller.setBrush(
                                      color: drawingColors[i],
                                    ),
                                    child: Text(
                                      ['黑', '红', '橙', '绿', '蓝', '紫'][i],
                                      style: TextStyle(
                                        color: Color(drawingColors[i]),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (var i = 0; i < drawingWidths.length; i++)
                              SizedBox(
                                height: 48,
                                child: OutlinedButton(
                                  onPressed: () => controller.setBrush(
                                    width: drawingWidths[i],
                                  ),
                                  child: Text(
                                    '${controller.document.width == drawingWidths[i] ? '✓ ' : ''}${['细', '中', '粗'][i]}',
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (loadFailed)
                          Wrap(
                            children: [
                              const Text('草稿暂时无法读取，可以重试或重新绘画。'),
                              TextButton(
                                onPressed: _load,
                                child: const Text('重试读取'),
                              ),
                            ],
                          ),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final size = Size.square(constraints.maxWidth);
                            if (paperSize != null && paperSize != size) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) controller.cancel();
                              });
                            }
                            paperSize = size;
                            return DecoratedBox(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.black26),
                              ),
                              child: RawGestureDetector(
                                gestures: {
                                  EagerGestureRecognizer:
                                      GestureRecognizerFactoryWithHandlers<
                                        EagerGestureRecognizer
                                      >(() => EagerGestureRecognizer(), (_) {}),
                                },
                                child: Listener(
                                  key: const ValueKey('drawing-canvas'),
                                  behavior: HitTestBehavior.opaque,
                                  onPointerDown: (e) => controller.begin(
                                    e.pointer,
                                    e.localPosition.dx / size.width,
                                    e.localPosition.dy / size.height,
                                  ),
                                  onPointerMove: (e) => controller.move(
                                    e.pointer,
                                    e.localPosition.dx / size.width,
                                    e.localPosition.dy / size.height,
                                  ),
                                  onPointerUp: (e) => controller.end(e.pointer),
                                  onPointerCancel: (event) =>
                                      controller.cancel(event.pointer),
                                  child: CustomPaint(
                                    size: size,
                                    painter: DrawingPainter(
                                      controller.document,
                                      activeStroke: controller.activeStroke,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _button(
                              '撤销',
                              controller.canUndo ? controller.undo : null,
                            ),
                            _button(
                              '重做',
                              controller.canRedo ? controller.redo : null,
                            ),
                            _button(
                              '清空',
                              controller.document.strokes.isEmpty
                                  ? null
                                  : _clear,
                            ),
                            SizedBox(
                              key: exportKey,
                              height: 48,
                              child: FilledButton(
                                onPressed:
                                    exporting ||
                                        controller.document.strokes.isEmpty
                                    ? null
                                    : _export,
                                child: Text(exporting ? '处理中…' : '导出PNG'),
                              ),
                            ),
                          ],
                        ),
                        if (controller.limitReached)
                          const Text('画面已经很丰富了，可以先导出，或撤销一些笔迹。'),
                        ValueListenableBuilder<DrawingSaveStatus>(
                          valueListenable: store.status,
                          builder: (context, status, _) => Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                loadFailed
                                    ? '原草稿未覆盖'
                                    : switch (status.phase) {
                                        DrawingSavePhase.saved => '已保存到本机',
                                        DrawingSavePhase.saving => '正在保存',
                                        DrawingSavePhase.failed => '尚未保存，可重试',
                                      },
                              ),
                              if (status.phase == DrawingSavePhase.failed)
                                TextButton(
                                  onPressed: () async {
                                    try {
                                      await store.retry();
                                    } catch (_) {}
                                  },
                                  child: const Text('重试保存'),
                                ),
                            ],
                          ),
                        ),
                        if (exportMessage != null) Text(exportMessage!),
                        const Text('重启后保留画面，操作历史重新开始'),
                        const Text('未完成的一笔不会保存。导出将打开系统分享面板，由你选择保存或分享。'),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _button(String text, VoidCallback? action) => SizedBox(
    height: 48,
    child: OutlinedButton(onPressed: action, child: Text(text)),
  );
}
