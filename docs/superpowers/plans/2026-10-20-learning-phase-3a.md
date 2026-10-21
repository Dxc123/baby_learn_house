# 数字启蒙 3A Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans 在当前会话逐项实施，末尾一次独立审查。Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 开放数字认读、数个数、可视化加法与可视化减法，保留全部旧内容与学习进度。

**Architecture:** ContentRepository 承载 11 个数字条目与三类 activityKind 分类。新增 math 模块将纯 Dart 互动状态、数量绘制和页面分开；数字认读复用目录与 LearningStore，互动状态仅存在页面生命周期中。

**Tech Stack:** 现有 Flutter 3.41.6 / Dart 3.11.4、GetX、本地 JSON 与 SharedPreferences；不升级 SDK 或添加运行时依赖。

**Spec:** docs/superpowers/specs/2026-10-20-learning-phase-3a-design.md（用户已确认）。

## Global Constraints

- 保留 241 个既有 ID、21 篇阅读内容、现有资源与 learning_state_v1。
- 新增 number-0 至 number-10，总计 252 个学习条目、20 个开放入口；互动工具不产生已学条目。
- numbers、count、plus-block、minus-block 开放；百数表、九九运算表及漫画三个入口继续待开放。
- 数字音频 audio=null、audioQuality=unavailable，不新增录音或运行时 TTS。
- 加法两数 0～10 且和≤10；减法 0≤减数≤被减数≤10；数数目标 1～10。
- 不新增随机题库、积分、自动评分、练习持久化或网络服务。
- 本项目向上继承主目录 Git；不执行父级 status/add/commit/branch 或工作树创建。任务证据记入 docs/phase-3a-ledger.md。

## Review Focus

1. JSON 的 kind/activityKind 同时存在、未知值、互动分类带条目：启动校验应明确拒绝，不默默进入错误页面（Task 1）。
2. 数量收缩后减数越界、结果显示后修改参数：模型必须收敛并隐藏旧结果，不残留错误算式（Task 2）。
3. 重复点数与界面重建：同一物体只累计一次，修改数量清除旧序号，重建不重置当前操作（Tasks 2/4）。
4. 全局笔画/拼音排序及失效 cursor：数字始终数值升序，旧数字链接安全回退，旧记录不丢（Task 3）。
5. 直接访问互动分类的旧 /learn 路径、退出后迟到保存/声音：正确分派，互动不写进度，切页停止旧阅读音频（Tasks 3/4）。

## 文件边界

- data/content_types.dart、learning_content.dart：模式校验、ActivityKind、数字字段与排序/搜索。
- modules/math/math_state.dart：可独立测试的纯 Dart 数数与加减状态，无 GetX、I/O 或播放器。
- modules/math/quantity_objects.dart：可访问的数量图形、组标签、序号与删除线。
- modules/math/number_detail_view.dart：数字详情及进度操作。
- modules/math/math_activity_view.dart：三个互动页面与页面内状态生命周期。
- routes/app_pages.dart、modules/home/views/home_view.dart：按分类能力统一分派与路由守卫。
- tool/number_catalog.py：确定性新增数字目录；由现有 expand_phase2_content.py 集成，不覆盖旧资源。

## Task 1：扩展目录模式与确定性数据

**Files:** 修改 lib/app/data/content_types.dart、learning_content.dart、tool/expand_phase2_content.py；新增 tool/number_catalog.py、test/number_content_test.dart、test/fixtures/phase2c_ids.json、tool/tests/test_number_catalog.py；生成 assets/data/content.json。

**Interfaces:** 新增 `enum ActivityKind { count, addition, subtraction }` 与 `ContentKind.number`；`LearningCategory.activityKind: ActivityKind?`、`LearningItem.numberValue: int?`。Python `build_number_catalog(data: dict) -> dict` 接受已生成的旧目录，返回新目录快照；不修改正文或 readingRevision。

- [x] 在修改生成数据前保存当前 241 个 ID fixture。写测试：新数据应有 252 项/20 开放分类，numberValue 为 0..10、ID 一一对应；旧 ID 全包含、readingRevision 与正文引用保持一致。
- [x] 写坏数据测试：kind/activityKind 同时存在、均缺失的开放分类、未知 activityKind、互动分类带普通条目、重复/非整数/越界 numberValue 均抛 FormatException。旧 fixture 无新字段仍可载入。
- [x] 运行 `flutter test test/number_content_test.dart`，确认新行为失败；新增 Python 测试确认非法值被拒绝、输出确定且不修改传入旧数据。
- [x] 实现以上类型/校验。activityKind 只能配置给对应的 count/plus-block/minus-block；number 只用于 numbers，条目必须有中文 text 与对齐 pinyin，numberValue 是整数而非 bool。
- [x] 实现 build_number_catalog：构造零至十的注音、说明和数值，audio=null/unavailable；复用现有双文件写入事务。生成流水线先构建旧内容和 reading 关联，再加入数字并完整验证；保持 --check 无写入。
- [x] 更新 Dart/Python 验证器及受总数影响的断言，保留旧 ID 和资源断言。运行 `python3 -m unittest discover -s tool/tests`、生成器、`python3 tool/expand_phase2_content.py --check` 和 Task 1 Flutter 测试，预期全部通过。

## Task 2：可穷举的互动状态

**Files:** 新增 lib/app/modules/math/math_state.dart、test/math_state_test.dart。

**Interfaces:** `CountingState({int target=5})`，只读 target、countedIndices（不可变快照）、count、complete；`setTarget(int)`、`tap(int index)`、`reset()`。`ArithmeticState({required ActivityKind kind})` 只接受 addition/subtraction，默认 2/3 或 5/2；只读 left/right/revealed/result、canIncrementLeft/canIncrementRight；`setLeft(int)`、`setRight(int)`、`reveal()`、`reset()`。所有 setter 返回 void，非法值抛 ArgumentError 且不改变旧状态。

- [x] 写失败测试：默认目标5，重复 tap(0) 只计1；完成全部目标后 complete=true；setTarget 清空，reset 保留目标；非法索引和 0/11 目标不改状态。
- [x] 写加法穷举测试：所有 a+b≤10 的组合结果正确，0+0合法；越界 setter 不修改状态；reveal 后改参数取消揭示，reset 保留参数。
- [x] 写减法穷举测试：所有 0≤b≤a≤10 正确，setLeft 降低到 b 以下时 right 收敛；0−0、n−0、n−n 正确，修改参数隐藏旧结果。ActivityKind.count 构造运算模型失败。
- [x] 运行 `flutter test test/math_state_test.dart` 确认失败，再实现模型；纯 Dart 状态无计时器、异步或持久化。
- [x] 重跑同命令全部通过；修改同值参数视为一次用户变更，也清除旧结果/点数，避免模糊的重置语义。

## Task 3：数字认读及入口分派

**Files:** 新增 lib/app/modules/math/number_detail_view.dart、test/number_ui_test.dart；修改 learning_content.dart、core/learning_label.dart、modules/learning/learning_detail_view.dart、routes/app_pages.dart、modules/home/views/home_view.dart。

**Interfaces:** `NumberDetailView({required String itemId})`；`String categoryRoute(LearningCategory category)` 返回 /math/<id> 或 /learn/<id>；数字详情由现有 /learn/:categoryId/:itemId 页面工厂分派，其他类型行为不变。

- [x] 写失败测试：numbers 目录显示0..10，三种全局排序下保持数值升序；查询“10”“十”“shi”均能定位十，过滤继续沿用现有 learned 规则。numberValue 搜索只对数字类型扩展。
- [x] 写路由测试：首页四入口目标正确；旧 /learn/count、/learn/plus-block、/learn/minus-block 重定向到互动页；非法 item/category 组合和失效 cursor 安全回退目录或首个有效项，不抛 firstWhere 异常。
- [x] 写进度测试：number-0/number-10 标记、撤销、继续与重开恢复正确；注入写失败不发布成功；旧 learned/settings/reader cursors 保留。
- [x] 运行 `flutter test test/number_ui_test.dart test/content_upgrade_test.dart` 确认新行为失败，再实现页面分派、数值排序/搜索和数字显示。数字详情大数字、中文名称+注音、数量图示分开；0显示“一个也没有”；注音遵循全局设置。
- [x] 使用现有 saveWithFeedback 和 LearningStore，不引入新 schema；详情上一/下一按数值顺序，异步保存后检查 mounted，防止退出后导航。暂缺录音沿用既有说明且不提供伪播放。
- [x] 重跑上述测试及 `test/learning_edges_test.dart`，预期通过。

## Task 4：数量图形与三个互动页面

**Files:** 新增 lib/app/modules/math/quantity_objects.dart、math_activity_view.dart、test/math_activity_ui_test.dart；补齐路由与数字详情图形引用。

**Interfaces:** `QuantityObjects({required int count, Set<int> countedIndices=const {}, int removedCount=0, String groupLabel='', ValueChanged<int>? onTap})`；`MathActivityView({required String categoryId})`。页面 State 仅在 initState 创建 Task 2 模型，build 不重建模型。

- [x] 写失败测试：默认数数5个，点击同物体两次仍为1，改变目标清空序号，“重新数”保留数量；仅全部点完显示“一共有 n 个”。
- [x] 写加法 UI 测试：2+3 初始隐藏结果，“合在一起”后5；变更参数隐藏结果；和10时非法加号禁用；0+0用空区域和文字而非装饰物。
- [x] 写减法 UI 测试：5−2揭示后3个剩余、2个删除线对象；降低被减数收敛减数；重新演示恢复图示，0−0和相等两数正确。
- [x] 写生命周期/语义测试：重建保留当前操作、退出再入回默认；所有互动行为不改变 learned/cursors；点击对象有“第 k 个，已数/未数”，可操作区至少48；删除线和组标签辅助颜色。
- [x] 运行 `flutter test test/math_activity_ui_test.dart` 确认失败；实现 Wrap 图形和滚动页面。不要用 emoji 字体差异替代可控数量绘制。合法性来自模型，按钮 disabled 来自边界；无答案计时、无自动导航。
- [x] 新增 /math/:categoryId 守卫：未知、未开放或无 activityKind 返回首页；导航经过现有 LearningAudio 观察器，补路由取消旧阅读播放的测试，不另建播放器。
- [x] 测试四页面 320px/200% 与平板布局、拼音开关、所有边界及重复揭示；运行 Tasks 3/4 和既有音频测试，预期通过。

## Task 5：回归、设备验收与交付

**Files:** README.md、docs/phase-2-roadmap.md、docs/phase-3a-status.md、docs/phase-3a-ledger.md、docs/screenshots/phase-3a-*.png；必要时更新 tool/validate_content.dart 的分类汇总。

**Interfaces:** 消费 Tasks 1–4 完整产品，输出可复核交付记录，不新增功能范围。

- [x] 执行 `dart format lib test tool`、`flutter analyze`、`flutter test`，记录实际本轮数量与退出码；不可沿用2C的63项结果。
- [x] 执行 `python3 -m unittest discover -s tool/tests`、`python3 tool/expand_phase2_content.py --check`、`dart run tool/validate_content.dart`；原190段demo与111项缺录音保持，新增11项数字缺录音单列，总缺录音122。
- [x] 执行 `flutter build apk --debug` 与 `flutter build ios --simulator`；遇到失败先取证，不以旧构建替代。
- [ ] iOS 模拟器走通数字0/10、标记与继续，数数重复点击/重置，加法0+0/和10，减法0−0/n−n/收缩参数；切页停止旧阅读队列。保存截图并重启验证原记录与新数字进度保留。
- [x] 对缺设备的 Android 运行、未做的人工交互和教学听审逐项如实记录；原2B PDF设备验收继续独立保留，不安装私人设备或擅自扩大环境。
- [x] 按 executing-plans 做唯一一次独立全变更审查；重要问题加失败回归再修复，运行受影响测试和完整套件。不得主动分派实现任务或逐任务审查。
- [x] 更新文档为252项/20入口，解释三个互动工具不计分母、11项数字无录音、工具不保存操作；勾选有证据的计划项，标明剩余人工项，不执行父级 Git 操作。

## 自查与执行交接

覆盖关系：数据和兼容由Task1负责，运算与幂等由Task2负责，数字进度/排序/路由由Task3负责，交互/语义/生命周期由Task4负责，资源/设备/回归由Task5负责。Review Focus 五项均对应失败测试；无未定接口。ArithmeticState 的 result 为纯计算 int，揭示仅由 revealed 控制；未揭示时界面不得读取并展示答案。

用户确认后已在当前会话内实施。82 项 Flutter 测试、10 项 Python 测试及联合审计通过，独立审查问题均补 RED 回归后修复；交付与设备边界见 docs/phase-3a-status.md。未勾选的复合设备项中，四入口主流程已走通，切页取消旧阅读队列有自动回归，尚未单独人工补验。
