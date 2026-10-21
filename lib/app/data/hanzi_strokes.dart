import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:path_drawing/path_drawing.dart';
import 'content_types.dart';

class HanziStrokeData {
  HanziStrokeData._(this.character, this.strokes, this.medians);
  factory HanziStrokeData.fromJson(
    Map<String, dynamic> json, {
    required String character,
  }) {
    final strokes = List<String>.from(json['strokes'] as List);
    if (character.runes.length != 1 ||
        strokes.isEmpty ||
        strokes.length > 64 ||
        strokes.length != (json['medians'] as List).length) {
      throw const FormatException('Invalid stroke count');
    }
    for (final path in strokes) {
      if (!RegExp(r'^[MmLlHhVvCcSsQqTtAaZz0-9., +\-]+$').hasMatch(path)) {
        throw const FormatException('Invalid stroke path');
      }
      final parsed = parseSvgPathData(path);
      final bounds = parsed.getBounds();
      if (bounds.isEmpty ||
          !bounds.left.isFinite ||
          !bounds.top.isFinite ||
          bounds.left < -256 ||
          bounds.right > 1280 ||
          bounds.top < -380 ||
          bounds.bottom > 1156) {
        throw const FormatException('Invalid stroke bounds');
      }
    }
    final medians = (json['medians'] as List).map((line) {
      final points = (line as List).map((raw) {
        final pair = raw as List;
        if (pair.length != 2 || pair.any((n) => n is! num || !n.isFinite)) {
          throw const FormatException('Invalid median point');
        }
        return Point<double>(
          (pair[0] as num).toDouble(),
          (pair[1] as num).toDouble(),
        );
      }).toList();
      if (points.length < 2) throw const FormatException('Invalid median');
      return List<Point<double>>.unmodifiable(points);
    }).toList();
    return HanziStrokeData._(
      character,
      List.unmodifiable(strokes),
      List.unmodifiable(medians),
    );
  }
  final String character;
  final List<String> strokes;
  final List<List<Point<double>>> medians;
  String svg({String color = '#222222'}) =>
      '<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024"><g transform="translate(0 900) scale(1 -1)" fill="$color">${strokes.map((s) => '<path d="$s"/>').join()}</g></svg>';
}

class HanziStrokeRepository {
  HanziStrokeRepository(this.bundle);
  final AssetBundle bundle;
  final _cache = <String, HanziStrokeData>{};
  Future<HanziStrokeData> load(String assetPath) async {
    if (!safeAsset(assetPath, 'assets/strokes') ||
        !RegExp(r'/[0-9a-f]+\.json$').hasMatch(assetPath)) {
      throw const FormatException('Invalid stroke asset');
    }
    if (_cache.containsKey(assetPath)) return _cache[assetPath]!;
    final code = int.parse(
      assetPath.split('/').last.split('.').first,
      radix: 16,
    );
    final data = HanziStrokeData.fromJson(
      jsonDecode(await bundle.loadString(assetPath)) as Map<String, dynamic>,
      character: String.fromCharCode(code),
    );
    _cache[assetPath] = data;
    return data;
  }
}
