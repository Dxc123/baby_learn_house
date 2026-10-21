import 'dart:async';
import 'package:get/get.dart';
import '../../data/hanzi_strokes.dart';

class StrokePlaybackController extends GetxController {
  final visible = 0.obs;
  final playing = false.obs;
  final speed = 1.0.obs;
  int _total = 0;
  Timer? _timer;
  bool _closed = false;
  void load(HanziStrokeData data) {
    pause();
    _total = data.strokes.length;
    visible.value = 0;
  }

  void play() {
    if (_closed || playing.value || _total == 0 || visible.value >= _total) {
      return;
    }
    playing.value = true;
    _timer = Timer.periodic(
      Duration(milliseconds: (600 / speed.value).round()),
      (_) {
        visible.value++;
        if (visible.value >= _total) pause();
      },
    );
  }

  void pause() {
    _timer?.cancel();
    _timer = null;
    playing.value = false;
  }

  void replay() {
    if (_closed) return;
    pause();
    visible.value = 0;
    play();
  }

  void stepForward() {
    pause();
    if (!_closed && visible.value < _total) visible.value++;
  }

  void setSpeed(double value) {
    if (![.5, 1.0, 2.0].contains(value)) {
      throw ArgumentError('Unsupported speed');
    }
    final resume = playing.value;
    pause();
    speed.value = value;
    if (resume) play();
  }

  @override
  void onClose() {
    _closed = true;
    pause();
    super.onClose();
  }
}
