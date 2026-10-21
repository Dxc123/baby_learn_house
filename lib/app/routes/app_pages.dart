import 'package:get/get.dart';
import 'package:flutter/widgets.dart';

import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/settings/settings_view.dart';
import '../modules/learning/learning_list_view.dart';
import '../modules/learning/learning_detail_view.dart';
import '../data/learning_content.dart';
import '../modules/handwriting/handwriting_view.dart';
import '../modules/worksheet/worksheet_view.dart';
import '../modules/settings/resource_licenses_view.dart';
import '../modules/reader/reading_view.dart';
import '../modules/story/story_view.dart';
import '../modules/drawing/drawing_view.dart';
import '../modules/math/number_detail_view.dart';
import '../modules/math/math_activity_view.dart';
import '../modules/math/hundred_view.dart';
import '../modules/math/math_table_view.dart';
import '../modules/math/math_table_rules.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const initial = Routes.home;

  static final routes = [
    GetPage(
      name: _Paths.home,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(name: '/settings', page: () => const SettingsView()),
    GetPage(name: '/drawing', page: () => const DrawingView()),
    GetPage(
      name: '/story/:storyId',
      page: () => StoryView(
        storyId: Get.parameters['storyId'] ?? '',
        unitId: Get.parameters['unit'],
      ),
    ),
    GetPage(
      name: '/math/:categoryId',
      middlewares: [MathRouteGuard()],
      page: () {
        final id = Get.parameters['categoryId']!;
        return switch (Get.find<ContentRepository>()
            .category(id)
            .activityKind) {
          ActivityKind.hundred => const HundredView(),
          ActivityKind.drawing => const DrawingView(),
          ActivityKind.additionTable => const MathTableView(
            kind: MathTableKind.addition,
          ),
          ActivityKind.subtractionTable => const MathTableView(
            kind: MathTableKind.subtraction,
          ),
          ActivityKind.multiplicationTable => const MathTableView(
            kind: MathTableKind.multiplication,
          ),
          ActivityKind.divisionTable => const MathTableView(
            kind: MathTableKind.division,
          ),
          ActivityKind.count ||
          ActivityKind.addition ||
          ActivityKind.subtraction => MathActivityView(categoryId: id),
          null => const HomeView(),
        };
      },
    ),
    GetPage(
      name: '/read/:readingId',
      page: () => ReadingView(
        readingId: Get.parameters['readingId'] ?? '',
        lineId: Get.parameters['line'],
      ),
    ),
    GetPage(
      name: '/practice/:itemId',
      page: () => HandwritingView(itemId: Get.parameters['itemId'] ?? ''),
    ),
    GetPage(name: '/worksheet', page: () => const WorksheetView()),
    GetPage(
      name: '/resource-licenses',
      page: () => const ResourceLicensesView(),
    ),
    GetPage(
      name: '/learn/:categoryId/:itemId',
      middlewares: [LearningRouteGuard()],
      page: () => Get.parameters['categoryId'] == 'numbers'
          ? NumberDetailView(itemId: Get.parameters['itemId']!)
          : LearningDetailView(
              categoryId: Get.parameters['categoryId']!,
              itemId: Get.parameters['itemId']!,
              groupId: Get.parameters['group'],
            ),
    ),
    GetPage(
      name: '/learn/:categoryId',
      middlewares: [LearningRouteGuard()],
      page: () => LearningListView(categoryId: Get.parameters['categoryId']!),
    ),
  ];
}

class LearningRouteGuard extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final parts = Uri.tryParse(route ?? '')?.pathSegments ?? [];
    final content = Get.find<ContentRepository>();
    if (parts.length == 3) {
      final matches = content.items.where(
        (i) =>
            i.id == parts[2] && i.categoryId == parts[1] && i.storyId != null,
      );
      if (matches.isNotEmpty) {
        return RouteSettings(name: storyRoute(matches.first));
      }
    }
    if (parts.length >= 2) {
      for (final category in content.categories) {
        if (category.id == parts[1] &&
            category.available &&
            category.activityKind != null) {
          return RouteSettings(name: categoryRoute(category));
        }
      }
      if (parts.length == 3 &&
          !content.items.any(
            (i) => i.categoryId == parts[1] && i.id == parts[2],
          )) {
        return RouteSettings(
          name: content.categories.any((c) => c.id == parts[1] && c.available)
              ? '/learn/${parts[1]}'
              : '/home',
        );
      }
    }
    if (parts.length == 3) {
      final matches = Get.find<ContentRepository>().items.where(
        (i) =>
            i.categoryId == parts[1] &&
            i.id == parts[2] &&
            i.kind == ContentKind.reading,
      );
      if (matches.isNotEmpty) {
        return RouteSettings(name: readingRoute(matches.first));
      }
    }
    if (parts.length < 2 ||
        !Get.find<ContentRepository>().categories.any(
          (category) => category.id == parts[1] && category.available,
        )) {
      return const RouteSettings(name: '/home');
    }
    return null;
  }
}

String categoryRoute(LearningCategory category) =>
    category.activityKind == ActivityKind.drawing
    ? '/drawing'
    : category.activityKind == null
    ? '/learn/${category.id}'
    : '/math/${category.id}';

class MathRouteGuard extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final id = Uri.tryParse(route ?? '')?.pathSegments.lastOrNull;
    if (Get.find<ContentRepository>().categories.any(
      (c) =>
          c.id == id && c.available && c.activityKind == ActivityKind.drawing,
    )) {
      return const RouteSettings(name: '/drawing');
    }
    return Get.find<ContentRepository>().categories.any(
          (c) => c.id == id && c.available && c.activityKind != null,
        )
        ? null
        : const RouteSettings(name: '/home');
  }
}

String readingRoute(LearningItem item) => Uri(
  path: '/read/${item.readingId}',
  queryParameters: item.readingLineId == null
      ? null
      : {'line': item.readingLineId!},
).toString();

String storyRoute(LearningItem item) =>
    Uri(path: '/story/${item.storyId}').toString();
