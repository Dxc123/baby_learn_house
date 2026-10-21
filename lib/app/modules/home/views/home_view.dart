import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/home_controller.dart';
import 'home_presentation.dart';
import '../../../core/learning_widgets.dart';
import '../../../data/learning_content.dart';
import '../../../services/learning_store.dart';
import '../../../routes/app_pages.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});
  @override
  Widget build(BuildContext context) {
    final content = Get.find<ContentRepository>();
    final store = Get.find<LearningStore>();
    return Obx(() {
      final showPinyin = store.showPinyin.value;
      final tab = controller.selectedTab.value;
      final categories = content.categories.where((c) => c.tab == tab).toList();
      final learned = content.items
          .where((item) => store.learned.contains(item.id))
          .length;
      final scaler = MediaQuery.textScalerOf(context);
      final headerHeight =
          (scaler.scale(20) * 1.3 +
                  (showPinyin ? scaler.scale(11.4) * 1.25 : 0) +
                  20)
              .clamp(64.0, 140.0);
      return Scaffold(
        appBar: AppBar(
          toolbarHeight: headerHeight,
          titleSpacing: 16,
          scrolledUnderElevation: 0,
          title: Row(
            children: [
              if (MediaQuery.sizeOf(context).width >= 400 ||
                  scaler.scale(20) <= 26) ...[
                const HomeBrandMark(),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Semantics(
                    header: true,
                    child: const PinyinText('宝宝学识屋', [
                      'bǎo',
                      'bao',
                      'xué',
                      'shí',
                      'wū',
                    ], fontSize: 20),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: IconButton.filledTonal(
                tooltip: '设置',
                onPressed: () => Get.toNamed('/settings'),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xff3d443d),
                  minimumSize: const Size(48, 48),
                ),
                icon: const Icon(Icons.settings_outlined),
              ),
            ),
          ],
        ),
        body: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              key: PageStorageKey('home-scroll-$tab'),
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 940),
                  child: LayoutBuilder(
                    builder: (context, inner) {
                      final columns = inner.maxWidth >= 652 ? 2 : 1;
                      final width =
                          (inner.maxWidth - (columns - 1) * 24) / columns;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            '小小探索，大大世界',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          HomeProgressSummary(
                            learned: learned,
                            total: content.items.length,
                          ),
                          if (store.loadWarning != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(store.loadWarning!),
                            ),
                          const SizedBox(height: 20),
                          Wrap(
                            spacing: 24,
                            runSpacing: 24,
                            children: [
                              for (var i = 0; i < categories.length; i++)
                                SizedBox(
                                  width: width,
                                  child: HomeCategoryCard(
                                    category: categories[i],
                                    variant: i + tab,
                                    onOpen: () => _open(categories[i]),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 28),
                          const Text(
                            '陪伴每一次好奇与成长',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xff727967),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            '离线样例版 · 更多学习内容正在准备',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xff727967),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
        bottomNavigationBar: HomeTabBar(
          selected: tab,
          onSelect: (value) => controller.selectedTab.value = value,
        ),
      );
    });
  }

  void _open(LearningCategory category) {
    if (category.available) {
      Get.toNamed(categoryRoute(category));
      return;
    }
    Get.dialog(
      AlertDialog(
        title: const Text('正在准备中'),
        content: Text('“${category.name}”将在后续版本开放。'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('知道啦')),
        ],
      ),
    );
  }
}
