import 'package:flutter/material.dart';

/// Stable, countable objects. Empty sets remain visibly labelled.
class QuantityObjects extends StatelessWidget {
  const QuantityObjects({
    super.key,
    required this.count,
    this.countedIndices = const {},
    this.removedCount = 0,
    this.groupLabel = '',
    this.onTap,
    this.splitAt,
  });
  final int? splitAt;
  final int count, removedCount;
  final Set<int> countedIndices;
  final String groupLabel;
  final ValueChanged<int>? onTap;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (groupLabel.isNotEmpty) Text(groupLabel, textAlign: TextAlign.center),
      const SizedBox(height: 8),
      if (count == 0)
        const Padding(padding: EdgeInsets.all(12), child: Text('一个也没有')),
      Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var i = 0; i < count; i++)
            Semantics(
              label:
                  '第 ${i + 1} 个，${i >= count - removedCount
                      ? '已拿走'
                      : countedIndices.contains(i)
                      ? '已数'
                      : '未数'}',
              button: onTap != null,
              onTap: onTap == null ? null : () => onTap!(i),
              child: ExcludeSemantics(
                child: InkWell(
                  key: ValueKey('object-$i'),
                  onTap: onTap == null ? null : () => onTap!(i),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 52,
                      minHeight: 52,
                    ),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: i >= count - removedCount
                          ? Colors.grey.shade200
                          : splitAt != null && i >= splitAt!
                          ? Theme.of(context).colorScheme.secondaryContainer
                          : Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: countedIndices.contains(i)
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          i >= count - removedCount
                              ? Icons.remove_circle_outline
                              : Icons.circle,
                          size: 24,
                          color: i >= count - removedCount
                              ? Colors.grey
                              : Theme.of(context).colorScheme.primary,
                        ),
                        if (countedIndices.contains(i))
                          Text('${countedIndices.toList().indexOf(i) + 1}'),
                        if (splitAt != null) Text(i < splitAt! ? '左' : '右'),
                        if (i >= count - removedCount)
                          const Text(
                            '拿走',
                            style: TextStyle(
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ],
  );
}
