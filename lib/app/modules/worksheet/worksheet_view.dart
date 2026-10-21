import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:printing/printing.dart';
import '../../data/learning_content.dart';
import '../../data/hanzi_strokes.dart';
import '../../services/worksheet_pdf_service.dart';

class WorksheetView extends StatefulWidget {
  const WorksheetView({super.key});
  @override
  State<WorksheetView> createState() => _WorksheetViewState();
}

class _WorksheetViewState extends State<WorksheetView> {
  final _selected = <String>{};
  int _rows = 2;
  bool _busy = false;
  String? _error;
  Future<void> _preview() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final content = Get.find<ContentRepository>();
      final ids = content
          .sortedItems('chinese', 'grade')
          .where((i) => _selected.contains(i.id))
          .map((i) => i.id)
          .toList();
      final bytes = await WorksheetPdfService(
        content,
        HanziStrokeRepository(rootBundle),
        rootBundle,
      ).build(WorksheetConfig(itemIds: ids, rowsPerCharacter: _rows));
      if (mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => WorksheetPreview(bytes: bytes),
          ),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _error = '字帖暂时无法生成，请检查选择并重试。');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = Get.find<ContentRepository>();
    final items = content.sortedItems('chinese', 'grade');
    return Scaffold(
      appBar: AppBar(title: const Text('A4 汉字字帖')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            '选择想练习的汉字',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('按课程顺序排版，每行 1 个示范、3 个描红和 5 个空格。'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              TextButton(
                onPressed: _busy
                    ? null
                    : () => setState(
                        () => _selected.addAll(items.map((i) => i.id)),
                      ),
                child: const Text('全选 60 字'),
              ),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => setState(() {
                        _selected.clear();
                        _selected.addAll(items.take(6).map((i) => i.id));
                      }),
                child: const Text('基础六字'),
              ),
              TextButton(
                onPressed: _busy ? null : () => setState(_selected.clear),
                child: const Text('取消选择'),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in items)
                FilterChip(
                  label: Text(item.text, style: const TextStyle(fontSize: 22)),
                  selected: _selected.contains(item.id),
                  onSelected: _busy
                      ? null
                      : (on) => setState(() {
                          if (on) {
                            _selected.add(item.id);
                          } else {
                            _selected.remove(item.id);
                          }
                        }),
                ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('每个字的练习行数'),
          Wrap(
            spacing: 8,
            children: [
              for (var rows = 1; rows <= 4; rows++)
                ChoiceChip(
                  label: Text('$rows 行'),
                  selected: _rows == rows,
                  onSelected: _busy
                      ? null
                      : (_) => setState(() => _rows = rows),
                ),
            ],
          ),
          const SizedBox(height: 20),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          FilledButton.icon(
            onPressed: _busy || _selected.isEmpty ? null : _preview,
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: Text(_busy ? '正在生成…' : '生成并预览 · ${_selected.length} 字'),
          ),
          const SizedBox(height: 12),
          const Text('生成、分享与打印不会改变学习进度。可在系统窗口中取消。'),
        ],
      ),
    );
  }
}

class WorksheetPreview extends StatefulWidget {
  const WorksheetPreview({super.key, required this.bytes});
  final Uint8List bytes;
  @override
  State<WorksheetPreview> createState() => _WorksheetPreviewState();
}

class _WorksheetPreviewState extends State<WorksheetPreview> {
  bool _busy = false;
  Future<void> _action(bool print) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (print) {
        await Printing.layoutPdf(
          onLayout: (_) => widget.bytes,
          name: '宝宝学识屋-汉字字帖',
        );
      } else {
        await Printing.sharePdf(
          bytes: widget.bytes,
          filename: '宝宝学识屋-汉字字帖.pdf',
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('系统窗口暂时无法打开，请重试。')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('字帖预览')),
    body: PdfPreview(
      build: (_) => widget.bytes,
      useActions: false,
      canChangePageFormat: false,
      canChangeOrientation: false,
      canDebug: false,
      pdfFileName: '宝宝学识屋-汉字字帖.pdf',
      onError: (context, error) => const Center(child: Text('预览暂时无法打开，请返回重试。')),
    ),
    bottomNavigationBar: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          alignment: WrapAlignment.spaceEvenly,
          spacing: 12,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: _busy ? null : () => _action(true),
              icon: const Icon(Icons.print_outlined),
              label: const Text('打印字帖'),
            ),
            FilledButton.tonalIcon(
              onPressed: _busy ? null : () => _action(false),
              icon: const Icon(Icons.share_outlined),
              label: const Text('分享 PDF'),
            ),
          ],
        ),
      ),
    ),
  );
}
