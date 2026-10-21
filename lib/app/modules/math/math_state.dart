import '../../data/content_types.dart';

class CountingState {
  CountingState({int target = 5}) {
    setTarget(target);
  }
  int _target = 5;
  final _counted = <int>{};
  int get target => _target;
  Set<int> get countedIndices => Set.unmodifiable(_counted);
  int get count => _counted.length;
  bool get complete => count == target;
  void setTarget(int value) {
    if (value < 1 || value > 10) throw ArgumentError.value(value);
    _target = value;
    reset();
  }

  void tap(int index) {
    if (index < 0 || index >= target) throw ArgumentError.value(index);
    _counted.add(index);
  }

  void reset() => _counted.clear();
}

class ArithmeticState {
  ArithmeticState({required this.kind}) {
    if (kind != ActivityKind.addition && kind != ActivityKind.subtraction) {
      throw ArgumentError.value(kind);
    }
    _left = kind == ActivityKind.addition ? 2 : 5;
    _right = kind == ActivityKind.addition ? 3 : 2;
  }
  final ActivityKind kind;
  late int _left, _right;
  bool _revealed = false;
  int get left => _left;
  int get right => _right;
  bool get revealed => _revealed;
  int get result => kind == ActivityKind.addition ? left + right : left - right;
  bool get canIncrementLeft =>
      left < 10 && (kind != ActivityKind.addition || left + right < 10);
  bool get canIncrementRight =>
      kind == ActivityKind.addition ? left + right < 10 : right < left;
  void setLeft(int value) {
    if (value < 0 ||
        value > 10 ||
        (kind == ActivityKind.addition && value + right > 10)) {
      throw ArgumentError.value(value);
    }
    _left = value;
    if (kind == ActivityKind.subtraction && right > value) _right = value;
    reset();
  }

  void setRight(int value) {
    if (value < 0 ||
        value > 10 ||
        (kind == ActivityKind.addition ? left + value > 10 : value > left)) {
      throw ArgumentError.value(value);
    }
    _right = value;
    reset();
  }

  void reveal() => _revealed = true;
  void reset() => _revealed = false;
}
