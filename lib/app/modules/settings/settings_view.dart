import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/learning_widgets.dart';
import '../../core/learning_theme.dart';
import '../../services/learning_store.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});
  @override
  Widget build(BuildContext context) {
    final store = Get.find<LearningStore>();
    return LearningScaffold(
      title: '设置',
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const PinyinText('设置', ['shè', 'zhì'], fontSize: 28),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              '让学习，变成喜欢的样子',
              style: TextStyle(color: Color(0xFF858675)),
            ),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => Get.toNamed('/resource-licenses'),
            child: const Text('笔顺与字体许可'),
          ),
          SoftPanel(
            child: Obx(
              () => SwitchListTile.adaptive(
                key: const ValueKey('pinyin-switch'),
                contentPadding: EdgeInsets.zero,
                title: const Text('显示拼音'),
                subtitle: const Text('帮助宝宝认识每一个汉字'),
                value: store.showPinyin.value,
                onChanged: (value) =>
                    saveWithFeedback(() => store.setShowPinyin(value)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SoftPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '主题颜色',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text('选择一个喜欢的颜色'),
                const SizedBox(height: 16),
                Obx(
                  () => Wrap(
                    spacing: 14,
                    runSpacing: 12,
                    children: [
                      for (var i = 0; i < themeColors.length; i++)
                        Semantics(
                          label: ['青草绿', '天空蓝', '暖珊瑚'][i],
                          selected: store.themeIndex.value == i,
                          child: InkWell(
                            key: ValueKey('theme-$i'),
                            borderRadius: BorderRadius.circular(24),
                            onTap: () =>
                                saveWithFeedback(() => store.setTheme(i)),
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: themeColors[i],
                                shape: BoxShape.circle,
                              ),
                              child: store.themeIndex.value == i
                                  ? const Icon(
                                      Icons.check_rounded,
                                      color: Colors.white,
                                      size: 28,
                                    )
                                  : null,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SoftPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '汉字学习顺序',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Obx(
                  () => Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final choice in {
                        'grade': '按课程',
                        'strokes': '按笔画',
                        'pinyin': '按拼音',
                      }.entries)
                        ChoiceChip(
                          label: Text(choice.value),
                          selected: store.order.value == choice.key,
                          onSelected: (_) => saveWithFeedback(
                            () => store.setOrder(choice.key),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  '当前提供 60 个基础汉字，按自编课程分组。',
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SoftPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '本地学习记录',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Obx(() => Text('已学会 ${store.learned.length} 个内容，进度保存在当前设备。')),
                const SizedBox(height: 8),
                const Text(
                  '无需登录。账号与跨设备同步将在后续版本开放。',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () async {
                    if (await saveWithFeedback(store.clearCache)) {
                      Get.snackbar(
                        '缓存已清理',
                        '已学记录与设置已保留；随包学习资源不受影响。',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    }
                  },
                  icon: const Icon(Icons.cleaning_services_outlined),
                  label: const Text('清理下载缓存'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Center(
            child: Text(
              '宝宝学识屋 · 离线样例版',
              style: TextStyle(color: Color(0xFF929581)),
            ),
          ),
        ],
      ),
    );
  }
}
