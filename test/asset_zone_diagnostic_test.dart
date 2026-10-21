import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'route_probe_support.dart';

void main() {
  setUp(resetRouteProbe);
  for (final round in [1, 2]) {
    testWidgets('cached stroke asset resolves in widget zone $round', (
      tester,
    ) async {
      var done = false;
      rootBundle.loadString('assets/strokes/4e00.json').then((value) {
        done = value.contains('strokes');
      });
      await pumpProbeCondition(
        tester,
        () => done,
        reason: 'cached asset round $round',
      );
      expect(
        done,
        true,
        reason: 'Asset cache future must settle in this test zone',
      );
    });
  }
}
