import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:baby_learn_house/app/data/learning_content.dart';
import 'package:baby_learn_house/app/routes/app_pages.dart';
import 'package:baby_learn_house/app/modules/math/math_state.dart';

void main() {
  test('drawing opens independently without creating learning items', () {
    final content = ContentRepository.fromJson(
      jsonDecode(File('assets/data/content.json').readAsStringSync()),
    );
    final drawing = content.category('drawing');
    expect(drawing.available, true);
    expect(drawing.activityKind?.name, 'drawing');
    expect(content.items.length, 261);
    expect(content.categories.where((c) => c.available).length, 28);
    expect(content.items.where((i) => i.categoryId == 'drawing'), isEmpty);
    expect(categoryRoute(drawing), '/drawing');
    expect(
      () => ArithmeticState(kind: drawing.activityKind!),
      throwsArgumentError,
    );
    Get.put(content);
    expect(LearningRouteGuard().redirect('/learn/drawing')?.name, '/drawing');
    expect(MathRouteGuard().redirect('/math/drawing')?.name, '/drawing');
    Get.reset();
  });
}
