import 'dart:math';
import 'package:flutter/foundation.dart';

/// Ephemeral normalized paths. Deliberately has no dependency on learning state.
class TraceController extends ChangeNotifier {
  final List<List<Point<double>>> _completed = [];
  List<Point<double>> _active = [];
  int? _pointer;
  List<List<Point<double>>> get completed => List.unmodifiable(
    _completed.map((p) => List<Point<double>>.unmodifiable(p)),
  );
  List<Point<double>> get active => List.unmodifiable(_active);
  bool _inside(Point<double> p) =>
      p.x.isFinite &&
      p.y.isFinite &&
      p.x >= 0 &&
      p.y >= 0 &&
      p.x <= 1 &&
      p.y <= 1;
  void begin(int pointerId, Point<double> point) {
    if (_pointer != null || !_inside(point)) return;
    _pointer = pointerId;
    _active = [point];
    notifyListeners();
  }

  void update(int pointerId, Point<double> point) {
    if (_pointer != pointerId || !_inside(point)) return;
    _active.add(point);
    notifyListeners();
  }

  void end(int pointerId) {
    if (_pointer != pointerId) return;
    if (_active.isNotEmpty) _completed.add(List.of(_active));
    _active = [];
    _pointer = null;
    notifyListeners();
  }

  void cancel(int pointerId) {
    if (_pointer != pointerId) return;
    _active = [];
    _pointer = null;
    notifyListeners();
  }

  void undo() {
    _active = [];
    _pointer = null;
    if (_completed.isNotEmpty) _completed.removeLast();
    notifyListeners();
  }

  void clear() {
    _completed.clear();
    _active = [];
    _pointer = null;
    notifyListeners();
  }
}
