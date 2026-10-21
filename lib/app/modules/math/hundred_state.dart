class HundredState {
  int _value = 1;
  int get value => _value;
  int? get row => value == 0 ? null : (value - 1) ~/ 10;
  int? get column => value == 0 ? null : (value - 1) % 10;
  bool get canPrevious => value > 0;
  bool get canNext => value < 100;
  void select(int value) {
    if (value < 0 || value > 100) throw ArgumentError.value(value);
    _value = value;
  }

  void previous() {
    if (canPrevious) select(value - 1);
  }

  void next() {
    if (canNext) select(value + 1);
  }

  String? submit(String input) {
    final text = input.trim();
    final parsed = RegExp(r'^[0-9]+$').hasMatch(text)
        ? int.tryParse(text)
        : null;
    if (parsed == null || parsed < 0 || parsed > 100) return '请输入 0～100 的整数。';
    select(parsed);
    return null;
  }
}
