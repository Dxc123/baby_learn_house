import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'drawing_document.dart';

class DrawingController extends ChangeNotifier {
  DrawingDocument _document = DrawingDocument();
  DrawingDocument get document => _document;
  final _undo = <List<DrawingStroke>>[], _redo = <List<DrawingStroke>>[];
  List<DrawingPoint>? _points;
  int? _pointer;
  int _strokeColor = drawingColors.first;
  double _strokeWidth = 10;
  int revision = 0;
  int contentRevision = 0;
  bool limitReached = false;
  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;
  DrawingStroke? get activeStroke => _points == null
      ? null
      : DrawingStroke(
          color: _strokeColor,
          width: _strokeWidth,
          points: _points!,
        );
  void restore(DrawingDocument doc) {
    doc.validate();
    cancel();
    _document = doc;
    _undo.clear();
    _redo.clear();
    limitReached = false;
    notifyListeners();
  }

  bool begin(int pointer, double x, double y) {
    if (_pointer != null ||
        !x.isFinite ||
        !y.isFinite ||
        x < 0 ||
        x > 1 ||
        y < 0 ||
        y > 1) {
      return false;
    }
    if (document.strokes.length >= 256 ||
        document.pointCount >= drawingMaxPoints) {
      limitReached = true;
      notifyListeners();
      return false;
    }
    limitReached = false;
    _pointer = pointer;
    _points = [DrawingPoint(x, y)];
    _strokeColor = document.color;
    _strokeWidth = document.width;
    notifyListeners();
    return true;
  }

  bool move(int pointer, double x, double y) {
    if (pointer != _pointer || _points == null || !x.isFinite || !y.isFinite) {
      return false;
    }
    x = x.clamp(0, 1);
    y = y.clamp(0, 1);
    final last = _points!.last;
    if (math.sqrt(math.pow(x - last.x, 2) + math.pow(y - last.y, 2)) * 1024 <
        2) {
      return false;
    }
    if (document.pointCount + _points!.length >= drawingMaxPoints) {
      limitReached = true;
      notifyListeners();
      return false;
    }
    _points!.add(DrawingPoint(x, y));
    notifyListeners();
    return true;
  }

  bool end(int pointer) {
    if (pointer != _pointer || _points == null) return false;
    final stroke = activeStroke!;
    _points = null;
    _pointer = null;
    _replace([...document.strokes, stroke]);
    return true;
  }

  void cancel([int? pointer]) {
    if (pointer != null && pointer != _pointer) return;
    if (_pointer == null) return;
    _pointer = null;
    _points = null;
    notifyListeners();
  }

  void setBrush({int? color, double? width}) {
    final next = DrawingDocument(
      color: color ?? document.color,
      width: width ?? document.width,
      strokes: document.strokes,
    );
    next.validate();
    if (next.color == document.color && next.width == document.width) return;
    _document = next;
    revision++;
    notifyListeners();
  }

  void _set(List<DrawingStroke> strokes) {
    final next = DrawingDocument(
      color: document.color,
      width: document.width,
      strokes: strokes,
    );
    next.encode();
    _document = next;
    revision++;
    limitReached = false;
    contentRevision++;
    notifyListeners();
  }

  void _replace(List<DrawingStroke> strokes) {
    final old = document.strokes;
    _set(strokes);
    _undo.add(old);
    _redo.clear();
    notifyListeners();
  }

  void undo() {
    cancel();
    if (!canUndo) return;
    _redo.add(document.strokes);
    _set(_undo.removeLast());
  }

  void redo() {
    cancel();
    if (!canRedo) return;
    _undo.add(document.strokes);
    _set(_redo.removeLast());
  }

  void clear() {
    cancel();
    if (document.strokes.isNotEmpty) _replace([]);
  }

  @override
  void dispose() {
    _points = null;
    _undo.clear();
    _redo.clear();
    super.dispose();
  }
}
