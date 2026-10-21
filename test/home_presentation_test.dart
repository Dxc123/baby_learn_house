import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:baby_learn_house/app/core/category_art.dart';
import 'package:baby_learn_house/app/core/learning_widgets.dart';
import 'widget_test.dart' show launch;

void main() {
  setUp(() => Get.testMode = true);
  tearDown(() => Get.reset());
  testWidgets('brand uses paired pinyin and banner scales with card width', (
    t,
  ) async {
    await launch(t);
    final header = find.descendant(
      of: find.byType(AppBar),
      matching: find.byType(PinyinText),
    );
    expect(header, findsOneWidget);
    final title = t.widget<PinyinText>(header);
    expect(title.text, '宝宝学识屋');
    expect(title.pinyin, ['bǎo', 'bao', 'xué', 'shí', 'wū']);
    final art = find.byType(CategoryArt).first;
    final phone = t.getSize(art);
    expect(phone.width / phone.height, closeTo(2.5, .02));
    t.view.physicalSize = const Size(1024, 1200);
    await t.pumpAndSettle();
    final tablet = t.getSize(art);
    expect(tablet.width / tablet.height, closeTo(2.5, .02));
    final first = t.getTopLeft(find.byKey(const ValueKey('category-pinyin')));
    final second = t.getTopLeft(find.byKey(const ValueKey('category-chinese')));
    expect(second.dy, closeTo(first.dy, 1));
    expect(second.dx, greaterThan(first.dx));
  });
  testWidgets(
    'changing tabs restores each scroll position and back keeps category',
    (t) async {
      final store = await launch(t);
      final before = store.learned.toSet();
      await t.drag(find.byType(SingleChildScrollView), const Offset(0, -600));
      await t.pumpAndSettle();
      double offset() => t
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .pixels;
      final previous = offset();
      expect(previous, greaterThan(100));
      await t.tap(find.byKey(const ValueKey('tab-2')));
      await t.pumpAndSettle();
      expect(offset(), 0);
      await t.tap(find.byKey(const ValueKey('tab-0')));
      await t.pumpAndSettle();
      expect(offset(), closeTo(previous, 1));
      await t.tap(find.byKey(const ValueKey('tab-3')));
      await t.pumpAndSettle();
      await t.ensureVisible(find.byKey(const ValueKey('category-drawing')));
      await t.tap(find.byKey(const ValueKey('category-drawing')));
      await t.pumpAndSettle();
      await t.tap(find.byType(BackButton));
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('category-drawing')), findsOneWidget);
      expect(store.learned.toSet(), before);
    },
  );
  testWidgets('320 at double text keeps brand, settings and all tabs usable', (
    t,
  ) async {
    final store = await launch(t, width: 320, scale: 2);
    for (var i = 0; i < 4; i++) {
      final tab = find.byKey(ValueKey('tab-$i'));
      expect(t.getSize(tab).height, greaterThanOrEqualTo(48));
      await t.tap(tab);
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    }
    await t.tap(find.byTooltip('设置'));
    await t.pumpAndSettle();
    await store.setShowPinyin(false);
    await t.tap(find.byTooltip('返回'));
    await t.pumpAndSettle();
    expect(find.text('bǎo'), findsNothing);
    expect(t.takeException(), isNull);
  });
}
