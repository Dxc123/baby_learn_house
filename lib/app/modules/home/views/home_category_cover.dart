import 'package:flutter/material.dart';
import '../../../core/category_art.dart';

/// Homepage-only artwork; course content and category identifiers stay separate.
class HomeCategoryCover extends StatelessWidget {
  const HomeCategoryCover({
    super.key,
    required this.categoryId,
    required this.symbol,
    required this.variant,
  });

  final String categoryId;
  final String symbol;
  final int variant;

  @override
  Widget build(BuildContext context) {
    final asset = switch (categoryId) {
      'idioms' => 'assets/images/home/idioms-cover.webp',
      'poetry' => 'assets/images/home/poetry-cover.webp',
      'classics' => 'assets/images/home/classics-cover.webp',
      _ => null,
    };
    Widget fallback() =>
        CategoryArt(symbol: symbol, variant: variant, aspectRatio: 2.5);
    if (asset == null) return fallback();
    return AspectRatio(
      aspectRatio: 2.5,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Image.asset(
          asset,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          excludeFromSemantics: true,
          errorBuilder: (context, error, stackTrace) => fallback(),
        ),
      ),
    );
  }
}
