import 'package:flutter/material.dart';

class GroupedQuantity extends StatelessWidget {
  GroupedQuantity({super.key, required this.groups, required this.perGroup}) {
    if (groups < 1 || groups > 9 || perGroup < 1 || perGroup > 9) {
      throw ArgumentError('Groups must be1..9');
    }
  }
  final int groups, perGroup;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 12,
    runSpacing: 12,
    children: [
      for (var g = 0; g < groups; g++)
        Semantics(
          label: '第 ${g + 1} 组，每组 $perGroup 个',
          child: ExcludeSemantics(
            child: Container(
              width: 156,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('第 ${g + 1} 组', textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (var n = 0; n < perGroup; n++)
                        Icon(
                          Icons.circle,
                          key: ValueKey('group-object-$g-$n'),
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
    ],
  );
}
