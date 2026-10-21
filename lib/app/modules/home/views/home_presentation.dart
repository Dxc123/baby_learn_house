import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'home_category_cover.dart';
import '../../../core/learning_widgets.dart';
import '../../../core/learning_theme.dart';
import '../../../data/learning_content.dart';

class HomeBrandMark extends StatelessWidget {
  const HomeBrandMark({super.key});
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: 40,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .85),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        Icons.cottage_rounded,
        size: 28,
        color: Theme.of(context).colorScheme.primary,
      ),
    ),
  );
}

class HomeProgressSummary extends StatelessWidget {
  const HomeProgressSummary({
    super.key,
    required this.learned,
    required this.total,
  });
  final int learned, total;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primary.withValues(alpha: .06),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
        ExcludeSemantics(
          child: Icon(
            Icons.auto_awesome_rounded,
            size: 18,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '已学会 $learned / $total 个内容 · 今天也很棒！',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Color(0xff596452)),
          ),
        ),
      ],
    ),
  );
}

class HomeCategoryCard extends StatelessWidget {
  const HomeCategoryCard({
    super.key,
    required this.category,
    required this.variant,
    required this.onOpen,
  });
  final LearningCategory category;
  final int variant;
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label:
        '${category.name}，${category.description}，${category.available ? '离线样例' : '筹备中'}',
    onTap: onOpen,
    child: ExcludeSemantics(
      child: Material(
        color: Colors.transparent,
        shape: const HomeDashedBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey('category-${category.id}'),
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                Stack(
                  children: [
                    HomeCategoryCover(
                      categoryId: category.id,
                      symbol: category.symbol,
                      variant: variant,
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .94),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          child: Text(
                            category.available ? '离线样例' : '筹备中',
                            style: TextStyle(
                              fontSize: 10,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: PinyinText(
                        category.name,
                        category.pinyin,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xffd4d7ce)),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        size: 22,
                        color: ink,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  category.description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: Color(0xff66715d),
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// A homepage-only outline; shared lesson cards keep their existing borders.
class HomeDashedBorder extends ShapeBorder {
  const HomeDashedBorder();
  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(1);
  @override
  ShapeBorder scale(double t) => const HomeDashedBorder();
  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      Path()
        ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(10)));
  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect.deflate(1));
  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final paint = Paint()
      ..color = const Color(0xff737c68)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final outline = getOuterPath(rect.deflate(.5));
    for (final metric in outline.computeMetrics()) {
      for (double offset = 0; offset < metric.length; offset += 7) {
        canvas.drawPath(
          metric.extractPath(offset, math.min(offset + 4, metric.length)),
          paint,
        );
      }
    }
  }
}

class HomeTabBar extends StatelessWidget {
  const HomeTabBar({super.key, required this.selected, required this.onSelect});
  final int selected;
  final ValueChanged<int> onSelect;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    child: SafeArea(
      top: false,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xffe5e8dd))),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < 4; i++)
              Expanded(
                child: Semantics(
                  selected: selected == i,
                  button: true,
                  label: ['中英', '认知', '数字', '漫画'][i],
                  onTap: () => onSelect(i),
                  child: ExcludeSemantics(
                    child: InkWell(
                      key: ValueKey('tab-$i'),
                      onTap: () => onSelect(i),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 56),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 2,
                            vertical: 8,
                          ),
                          child: PinyinText(
                            ['中英', '认知', '数字', '漫画'][i],
                            const [
                              ['zhōng', 'yīng'],
                              ['rèn', 'zhī'],
                              ['shù', 'zì'],
                              ['màn', 'huà'],
                            ][i],
                            fontSize: 14,
                            color: selected == i
                                ? Theme.of(context).colorScheme.primary
                                : ink,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
