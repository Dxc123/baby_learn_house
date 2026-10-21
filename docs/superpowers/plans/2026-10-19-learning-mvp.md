# 宝宝学识屋第一阶段 Implementation Plan

> **For agentic workers:** Use superpowers:executing-plans to implement this plan task-by-task. User requested execution; implement inline.

**Goal:** 四栏首页与设置，以及拼音、汉字和动物认知样例形成离线学习闭环。
**Architecture:** 保留 GetX 路由与注入；版本化 JSON 内容由仓库读取，设置和稳定 ID 进度独立保存，单一音频服务串行控制播放。
**Tech Stack:** Flutter 3.41.6 / Dart 3.11.4、GetX、shared_preferences、audioplayers。
**Spec:** docs/replica-proposal.md（本轮执行阶段 1，阶段 0 的全量内容盘点随后续模块补充）

## Global Constraints

- 默认 Android/iOS；不增加登录后台，不把未完成入口伪装成可用功能。
- 沿用现有 GetX，不重新初始化项目。
- 关键样例音频随包，清缓存不删除已学记录。
- 图片使用本项目绘制的插画，合成示范音频记录来源，后续替换经教学校对的录音。
- 当前目录继承主目录的 Git 仓库；不建分支、不提交、不触碰工程外的 Git 状态。

## Review Focus

1. 快速连点与切页：只有最后一次请求播放，退出页面或应用后台即停止。
2. 持久化失败：显示保存失败，不能假装写入成功；后续写入仍可执行。
3. 设置和缓存：清理仅限下载缓存键，进度和主题保留。
4. 小屏与大字号：注音不可拆开，底栏与学习按钮可达。
5. 空筛选与最后一项：显示真实空态，到末尾不发生越界或重复误标。

## Task 1: 本地内容、设置和进度

Files: assets/data/content.json; lib/app/data/learning_content.dart; lib/app/services/learning_store.dart; test/learning_store_test.dart; test/content_test.dart.

Interfaces: ContentRepository.load(AssetBundle) -> Future<ContentRepository>; itemsFor(String categoryId) -> List<LearningItem>; LearningStore.open(PreferenceStore) -> Future<LearningStore>; setLearned(String, bool), setShowPinyin(bool), setTheme(int), setOrder(String), clearCache() -> Future<void>.

- [x] 添加验证 28 个入口、唯一 ID、注音配对和资源映射的测试，运行确认失败。
- [x] 添加重建 store 后恢复记录、写入失败恢复与缓存隔离测试，运行确认失败。
- [x] 实现版本化内容模型、仓库、异步存储适配和串行写入。
- [x] 运行对应测试与全套测试通过。

## Task 2: 发音服务和离线资源

Files: lib/app/services/learning_audio.dart; tool/generate_sample_audio.swift; assets/audio/*.wav; assets/audio/README.md; test/learning_audio_test.dart.

Interfaces: AudioBackend.play(String), stop(), dispose() -> Future<void>; LearningAudio.play(String) -> Future<void>, stop() -> Future<void>; exposes playingId/error observables.

- [x] 测试连续请求与停止时的播放顺序、失败回退和恢复，确认失败。
- [x] 实现带请求版本号的串行音频控制，监听生命周期与播放器完成事件。
- [x] 使用本机系统语音生成随包示范 WAV，记录来源与教学局限。
- [x] 验证每个可用条目的资源存在、非空且 WAV 格式正确；运行测试。

## Task 3: 四栏首页、设置与公共视觉组件

Files: lib/main.dart; lib/app/core/*; lib/app/modules/home/*; lib/app/modules/settings/*; lib/app/routes/*; test/widget_test.dart.

Interfaces: BabyLearnApp(store, content, audio); PinyinText(text, pinyin, showPinyin, fontSize); LearningScaffold(title, child).

- [x] 写首页四栏切换、筹备中反馈、设置拼音和主题生效测试，确认失败。
- [x] 实现浅黄页头、奶油背景、绿色强调、自绘封面、注音、响应式卡片和底部导航。
- [x] 实现设置页持久化、缓存清理说明、错误反馈。
- [x] 小屏/平板/200% 字号 Widget 测试无溢出，运行全套测试。

## Task 4: 学习列表与详情闭环

Files: lib/app/modules/learning/*; test/learning_flow_test.dart; README.md; docs/implementation-status.md.

Interfaces: LearningListView(categoryId); LearningDetailView(categoryId, itemId); route /learn/:categoryId and /learn/:categoryId/:itemId.

- [x] 写搜索/已学筛选、学会→下一项、末尾、返回与 store 重建测试，确认失败。
- [x] 实现拼音、汉字、动物样例的共用列表与详情，汉字示例词组、年级、笔画数，明确不含书写判定。
- [x] 路由变更停止音频；重启恢复设置与已学进度；完成页可返回列表。
- [x] dart format、flutter analyze、flutter test、构建一个可验证的平台目标；记录真机验证边界与启动方式。

## Execution record

- 2026-10-19: 用户“执行计划”视为授权直接执行首阶段，无额外审批循环。产品代码、资源和开发文档仅写入当前工程。
- Task 1–4: complete。flutter analyze 无问题；flutter test 18/18；iOS 模拟器与 Android debug 构建通过。
- Ruling: 直接在当前工程执行，不操作继承的主目录 Git 仓库；未创建分支或提交。
- Ruling: 先用项目内插画与系统合成音频打通样例流程；正式资源和教学音频仍需后续审核替换。
- Final review: 独立审查两项 P2 已修复；存储读失败回退默认值、游标写失败仍允许进入/推进离线课程，新增回归测试 RED→GREEN，全套 18/18。
- 实际截图、范围与已知边界见 docs/implementation-status.md。没有遗留的审查修复项。
