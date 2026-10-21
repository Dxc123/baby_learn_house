import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/learning_widgets.dart';
import '../../data/learning_content.dart';
import 'math_state.dart';
import 'quantity_objects.dart';

class MathActivityView extends StatefulWidget {
  const MathActivityView({super.key, required this.categoryId});
  final String categoryId;
  @override
  State<MathActivityView> createState() => _MathActivityViewState();
}

class _MathActivityViewState extends State<MathActivityView> {
  late final LearningCategory category;
  CountingState? counting;
  ArithmeticState? arithmetic;
  @override
  void initState() {
    super.initState();
    category = Get.find<ContentRepository>().category(widget.categoryId);
    if (category.activityKind == ActivityKind.count) {
      counting = CountingState();
    } else {
      arithmetic = ArithmeticState(kind: category.activityKind!);
    }
  }

  Widget _stepper(
    String label,
    int value,
    String prefix,
    VoidCallback? minus,
    VoidCallback? plus,
  ) => SoftPanel(
    child: Column(
      children: [
        Text(
          '$label：$value',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22),
        ),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          children: [
            IconButton(
              key: ValueKey('$prefix-minus'),
              tooltip: '$label减少一个',
              onPressed: minus,
              icon: const Icon(Icons.remove_circle_outline),
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            ),
            IconButton(
              key: ValueKey('$prefix-plus'),
              tooltip: '$label增加一个',
              onPressed: plus,
              icon: const Icon(Icons.add_circle_outline),
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            ),
          ],
        ),
      ],
    ),
  );
  @override
  Widget build(BuildContext context) {
    final c = counting;
    final a = arithmetic;
    final addition = category.activityKind == ActivityKind.addition;
    return LearningScaffold(
      title: category.name,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            c != null
                ? '点一个，数一个'
                : addition
                ? '把两组放在一起'
                : '拿走一些，看看还剩多少',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          if (c != null) ...[
            _stepper(
              '物体数量',
              c.target,
              'left',
              c.target > 1
                  ? () => setState(() => c.setTarget(c.target - 1))
                  : null,
              c.target < 10
                  ? () => setState(() => c.setTarget(c.target + 1))
                  : null,
            ),
            const SizedBox(height: 16),
            SoftPanel(
              child: QuantityObjects(
                count: c.target,
                countedIndices: c.countedIndices,
                onTap: (i) => setState(() => c.tap(i)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '已经数了 ${c.count} 个',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24),
            ),
            if (c.complete)
              Text(
                '一共有 ${c.target} 个',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24),
              ),
            const SizedBox(height: 16),
            OutlinedButton(
              key: const ValueKey('reset'),
              onPressed: () => setState(c.reset),
              child: const Text('重新数'),
            ),
          ] else if (a != null) ...[
            _stepper(
              addition ? '左边一组' : '原来数量',
              a.left,
              'left',
              a.left > 0 ? () => setState(() => a.setLeft(a.left - 1)) : null,
              a.canIncrementLeft
                  ? () => setState(() => a.setLeft(a.left + 1))
                  : null,
            ),
            const SizedBox(height: 12),
            _stepper(
              addition ? '右边一组' : '拿走数量',
              a.right,
              'right',
              a.right > 0
                  ? () => setState(() => a.setRight(a.right - 1))
                  : null,
              a.canIncrementRight
                  ? () => setState(() => a.setRight(a.right + 1))
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              '${a.left} ${addition ? '+' : '−'} ${a.right} = ${a.revealed ? a.result : '？'}',
              key: const ValueKey('equation'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            SoftPanel(
              child: Column(
                children: [
                  if (addition && a.revealed)
                    QuantityObjects(
                      key: const ValueKey('combined-quantity'),
                      count: a.result,
                      splitAt: a.left,
                      groupLabel: '合在一起：左组 ${a.left} 个，右组 ${a.right} 个',
                    )
                  else ...[
                    QuantityObjects(
                      count: a.left,
                      groupLabel: addition ? '左边一组' : '原来有 ${a.left} 个',
                      removedCount: !addition && a.revealed ? a.right : 0,
                    ),
                    if (addition) ...[
                      const Divider(height: 32),
                      QuantityObjects(
                        count: a.right,
                        splitAt: 0,
                        groupLabel: '右边一组',
                      ),
                    ],
                  ],
                  if (a.revealed)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        addition ? '合起来一共有 ${a.result} 个' : '还剩 ${a.result} 个',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const ValueKey('reveal'),
              onPressed: () => setState(a.reveal),
              child: Text(addition ? '合在一起' : '拿走几个'),
            ),
            OutlinedButton(
              key: const ValueKey('reset'),
              onPressed: () => setState(a.reset),
              child: const Text('重新演示'),
            ),
          ],
          const SizedBox(height: 12),
          const Text('慢慢探索，不计分；返回后可以重新开始。', textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
