import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/annotated_reading_text.dart';
import '../../core/learning_widgets.dart';
import '../../data/story_types.dart';
import 'story_controller.dart';

class DialogueBody extends StatefulWidget {
  const DialogueBody({
    super.key,
    required this.document,
    required this.controller,
  });
  final StoryDocument document;
  final StoryController controller;
  @override
  State<DialogueBody> createState() => _DialogueBodyState();
}

class _DialogueBodyState extends State<DialogueBody> {
  final _keys = <String, GlobalKey>{};
  Worker? _worker;
  int _generation = 0;
  @override
  void initState() {
    super.initState();
    _watch();
  }

  void _watch() {
    _worker = ever(widget.controller.currentUnitId, (_) => _locate());
    if (widget.controller.currentUnitId.value !=
        widget.document.units.first.id) {
      _locate();
    }
  }

  void _locate() {
    final generation = ++_generation;
    final id = widget.controller.currentUnitId.value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || generation != _generation) return;
      final ctx = _keys[id]?.currentContext;
      if (ctx != null) Scrollable.ensureVisible(ctx, alignment: .15);
    });
  }

  @override
  void didUpdateWidget(covariant DialogueBody old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      _generation++;
      _worker?.dispose();
      _keys.clear();
      _watch();
    }
  }

  @override
  void dispose() {
    _generation++;
    _worker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final unit in widget.document.units)
        Padding(
          key: _keys.putIfAbsent(unit.id, () => GlobalKey()),
          padding: EdgeInsets.fromLTRB(
            unit.roleId == widget.document.roles.first.id ? 0 : 14,
            0,
            unit.roleId == widget.document.roles.first.id ? 14 : 0,
            14,
          ),
          child: Semantics(
            key: ValueKey('unit-${unit.id}'),
            label: unit.id == widget.controller.currentUnitId.value
                ? '当前轮'
                : null,
            selected: unit.id == widget.controller.currentUnitId.value,
            child: InkWell(
              onTap: () => widget.controller.selectUnit(unit.id),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: unit.id == widget.controller.currentUnitId.value
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: SoftPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Wrap(
                        spacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Icon(
                            switch (widget.document.roles
                                .firstWhere((r) => r.id == unit.roleId)
                                .avatarId) {
                              'adult' => Icons.school_rounded,
                              'friend' => Icons.face_retouching_natural_rounded,
                              _ => Icons.face_rounded,
                            },
                            color: widget.document.roles.first.id == unit.roleId
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.secondary,
                          ),
                          Text(
                            widget.document.roles
                                .firstWhere((r) => r.id == unit.roleId)
                                .name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (unit.id == widget.controller.currentUnitId.value)
                            const Text('当前轮'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      AnnotatedReadingText(
                        unit.text,
                        unit.pinyin,
                        fontSize: 24,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      if (widget.controller.currentUnitId.value ==
          widget.document.units.last.id)
        const Text(
          '这一场读完啦',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24),
        ),
      const SizedBox(height: 12),
      const Text(
        '家长陪练',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
      for (final tip in widget.document.parentTips)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(tip, style: const TextStyle(fontSize: 18)),
        ),
      const SizedBox(height: 12),
      Text(widget.document.prompt, style: const TextStyle(fontSize: 18)),
    ],
  );
}
