# 百数表与运算表 3B Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans 在当前会话逐项实施，末尾一次独立审查。Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** 开放百数表和四类运算表，提供可访问的点选探索与乘除分组图示。

**Architecture:** 扩展现有 ActivityKind 和目录生成器，复用 /math/:categoryId 分派。纯 Dart 规则负责表格与选择合法性，独立表格组件负责可访问布局和定位，百数页/运算页负责页面内状态；原3A运算模型不接收新类型。

**Tech Stack:** 现有 Flutter 3.41.6 / Dart 3.11.4、GetX、本地 JSON；不新增运行时依赖。

**Spec:** docs/superpowers/specs/2026-10-20-learning-phase-3b-design.md（用户已确认）。

## Global Constraints

- 252 个学习条目不变，开放入口20增至25；旧ID、readingRevision、190段demo、122项缺录音与learning_state_v1保持。
- hundred、plus、minus、times、divide 为离线工具，不写learned/cursors，不持久化选择或练习，不新增音频、TTS、随机题库或评分。
- 百数主体1～100十列，0独立；加法/乘法两参数1～9，减法被减数1～9、减数0～被减数，除法除数与商1～9且无余数。
- 每格最小48×48，支持320px/200%字号与平板；横向滚动，页面负责唯一纵向滚动。
- 不操作继承的用户主目录Git，不执行status/add/commit/branch或工作树脚本。当前工程与docs/phase-3b-ledger.md作为实施范围和记录。

## Review Focus

1. 新ActivityKind落入3A的else分支被当减法：精确分派，新类型传给ArithmeticState必须被拒绝（Tasks1/5）。
2. 除法相同被除数对应不同除数/商：选择身份用参数对，不能按结果反查格子（Tasks2/5）。
3. 减法非法格、被减数收缩、输入0/100及格式错误：禁用格不触发操作，非法输入保留旧选择，收缩减数不出现负数（Tasks2/4/5）。
4. 末格未布局、大字号横滚、连续选格或退出后迟到定位：只定位最新有效选择，不越界、不访问已销毁控制器（Tasks3/4/5）。
5. 主题重建、退出重入、旧路由和存储记录：重建保留选择，重入默认，工具不写进度且切页取消原声音（Tasks4/5）。

## 文件与接口划分

- data/content_types.dart、tool/number_catalog.py、tool/expand_phase2_content.py：活动类型与生成/审计映射。
- modules/math/math_table_rules.dart：运算种类、事实与合法参数；不依赖Flutter/GetX。
- modules/math/hundred_state.dart：百数选择、输入校验与行列映射。
- modules/math/learning_table_grid.dart：完整二维网格、语义与横向定位。
- modules/math/hundred_view.dart：百数页面与输入控制器。
- modules/math/math_table_view.dart：四类运算表的选择、控件、详情。
- modules/math/grouped_quantity.dart：最大9×9的只读分组图示，不改变3A对象组件行为。
- routes/app_pages.dart：按类型分派页面，保留旧学习链接重定向。

## Task 1：分类扩展与旧模型保护

**Files:** 修改 lib/app/data/content_types.dart、lib/app/modules/math/math_state.dart、tool/number_catalog.py、tool/expand_phase2_content.py；新增 test/math_table_content_test.dart、tool/tests/test_math_table_catalog.py、test/fixtures/phase3a_ids.json；更新受入口数量影响的既有测试，生成assets/data/content.json。

**Interfaces:** ActivityKind新增hundred、additionTable、subtractionTable、multiplicationTable、divisionTable；分别仅允许hundred/plus/minus/times/divide分类ID。原三类型映射保持。ArithmeticState构造器仅允许addition/subtraction，其他值抛ArgumentError。

- [x] 修改数据前保存252项ID fixture。写失败测试：252项/25开放入口、五分类映射精确；旧ID、条目字段、readingRevision不变，新工具无普通条目。
- [x] 写失败测试：新类型放到错误分类、kind/activityKind歧义、工具带条目均拒绝；遍历新五类型传入ArithmeticState均抛ArgumentError。运行 `flutter test test/math_table_content_test.dart test/math_state_test.dart`，确认新增行为失败。
- [x] 实现Dart/Python映射与旧模型白名单；扩展build_number_catalog开放五分类，说明明确范围，除法说明“行是分组数，列是每组数量”。不增加普通条目或音频。
- [x] 写Python重复生成、非法映射拒绝和旧条目不变测试；生成前后对比readings.json内容，必须不变。运行生成器、`python3 -m unittest discover -s tool/tests`、`python3 tool/expand_phase2_content.py --check`及上述Flutter测试，全部通过。

## Task 2：纯规则与选择状态

**Files:** 新增 lib/app/modules/math/math_table_rules.dart、hundred_state.dart、test/math_table_rules_test.dart、test/hundred_state_test.dart。

**Interfaces:**
- `enum MathTableKind { addition, subtraction, multiplication, division }`。
- `MathTableRules(kind)`：`List<int> get rows/columns`、`bool isValid(int row,int column)`、`MathFact fact(int row,int column)`；无效fact抛ArgumentError。
- `MathFact`不可变字段：`int row,column,left,right,result`、`String equation`、`int? groups,perGroup`。加减乘left/right为算式两参数；除法left=row×column、right=row、result=column，groups=row、perGroup=column。
- `MathTableSelection(kind)`：持有rules、只读row/column/fact，`select(int row,int column)`、`setRow(int)`、`setColumn(int)`；默认(1,1)，减法默认(1,0)。setRow减法收敛column；其他非法参数抛ArgumentError且保持旧状态。
- `HundredState()`：只读value（默认1）、row/column（0返回null）、canPrevious/canNext；`select(int)`、`previous()`、`next()`；`String? submit(String input)`成功返回null并更新，失败返回“请输入 0～100 的整数。”且不改变value。纯规则只接受trim后匹配`^[0-9]+$`且数值0..100，不接受正负号、小数或指数。

- [x] 写失败测试穷举加法/乘法/除法各81格及减法90候选格，逐项断言合法性、参数、结果、算式、groups/perGroup。加法9+9=18不能套用3A的和≤10限制。
- [x] 写除法重复被除数测试：(2,6)和(3,4)都显示12，但结果为6与4，选择后row/column保持对应身份。非法参数不修改旧选择，减法9−9收缩row到1时column收敛为1。
- [x] 写百数测试：1/10/11/100的零基行列为(0,0)/(0,9)/(1,0)/(9,9)，0无行列；previous/next边界不变；覆盖空串、-1、1.5、1e2、101、超长整数字符串及前后空白。无效select抛ArgumentError，submit无效返回固定错误。
- [x] 运行 `flutter test test/math_table_rules_test.dart test/hundred_state_test.dart` 确认失败，再实现纯规则与状态。MathTableRules生成不可变rows/columns，不以结果作为选择键。
- [x] 重跑同命令全部通过，测试规则无计时器、I/O或存储依赖。

## Task 3：可访问表格与分组图示

**Files:** 新增 lib/app/modules/math/learning_table_grid.dart、grouped_quantity.dart、test/learning_table_grid_test.dart、test/grouped_quantity_test.dart。

**Interfaces:** `LearningTableCell`包含`String id,label,semanticsLabel`、`bool enabled,selected,highlighted`、`VoidCallback? onTap`；`LearningTableGrid({required List<String> columnLabels, required List<String> rowLabels, required List<List<LearningTableCell>> cells, required String? selectedCellId, required int selectionRevision})`。内部State管理横滚控制器与每格GlobalKey，不暴露控制器给模型。`GroupedQuantity({required int groups,required int perGroup})`只接受1..9，超界抛ArgumentError。

- [x] 写失败测试：完整二维表一次构建，十列末格存在；合法格有读屏点击动作和选中状态；非法格显示“—”，无点击动作。行列头有可区分说明，数据格键用参数对而不是结果。
- [x] 写失败定位测试：320px/200%字号选择末行末列后目标hitTestable；连续选择末格再首格只定位最新；调度定位后立即移除组件不抛错；用户滚动但选择未变不抢回。滚动测试需真实pump下一帧，不能只断言Future结束。
- [x] 写分组测试：9组×9个实际图形81个，9个组级语义摘要，每个说明“第k组，每组9个”；不产生81个独立读屏焦点或点击动作。窄屏/大字号/平板不溢出。
- [x] 运行 `flutter test test/learning_table_grid_test.dart test/grouped_quantity_test.dart` 确认失败；实现横向Scrollbar与单个横向SingleChildScrollView，网格无独立纵向ScrollView。外层页面承担纵滚。
- [x] 格尺寸按MediaQuery文字缩放后的三位数字与表头测量值加内边距计算，且不小于48；当前格边框、行列高亮、文字语义共同表达。数据格用一个Semantics节点包裹排除的视觉子树，显式设置onTap，避免重现3A“按钮有名称无动作”。
- [x] 仅selectedCellId或selectionRevision改变时安排下一帧定位；捕获代次，mounted/控制器hasClients/代次匹配后再ensureVisible，包含横滚及页面纵滚。初始化默认选择可定位；0的null目标取消旧任务、不滚动。
- [x] 实现GroupedQuantity紧凑只读图形和组容器Wrap，不复用3A的52像素可点卡片；运行Task3测试全部通过。

## Task 4：百数页面

**Files:** 新增 lib/app/modules/math/hundred_view.dart、test/hundred_ui_test.dart。

**Interfaces:** `HundredView()`消费HundredState与LearningTableGrid。页面State在initState创建状态、TextEditingController；每次有效选择同步输入文本并增加selectionRevision，dispose释放输入控制器。键：hundred-input、hundred-submit、hundred-previous、hundred-next、hundred-zero；格ID为hundred-<value>。

- [x] 写失败测试：主表1..100无重复，0单独可选；选择0清除行列高亮且previous禁用，选择100时next禁用；1/10/11行列映射正确。
- [x] 写输入测试：提交100定位末格，提交非法值展示固定错误且保留旧选择；修改输入后错误可由下一次成功提交清除。输入框当前文本不等于已选择值时，只提交才改变选择。
- [x] 写生命周期测试：主题重建保留选择，退出重入默认1；快速提交100再0、提交后返回不抛迟到滚动错误；learned/cursors不变。
- [x] 运行 `flutter test test/hundred_ui_test.dart` 确认失败，再实现页面。详情/输入/前后按钮在表格前方，说明0及同列+10规律；数字输入keyboardType只是提示，校验仍由HundredState执行。
- [x] 复用LearningScaffold，最大阅读宽度沿用现有约束；输入错误用行内文字，不用异步弹窗。320px/200%与平板检查无异常，重跑Task4测试通过。

## Task 5：运算表页面与路由集成

**Files:** 新增 lib/app/modules/math/math_table_view.dart、test/math_table_ui_test.dart；修改 lib/app/routes/app_pages.dart；必要时新增 modules/math/math_destination.dart封装按活动类型构建页面。

**Interfaces:** `MathTableView({required MathTableKind kind})`消费MathTableSelection/Rules、LearningTableGrid、GroupedQuantity。/math/:categoryId按ActivityKind精确switch：旧三种进入MathActivityView，新hundred进入HundredView，其余四种映射MathTableKind；默认安全回首页。

- [x] 写失败路由测试：首页新增五入口可用；/learn/hundred、/learn/plus、/learn/minus、/learn/times、/learn/divide全部重定向正确，不进入3A ArithmeticState；未知/不可用分类仍安全回首页。
- [x] 写交互测试：加法9+9=18；减法9−9=0、非法格无操作、缩小被减数收敛；乘法9×9=81与9个组摘要；除法81÷9=9及12÷2=6/12÷3=4，两格身份不混淆。点格与两个参数步进控件保持同步，边界按钮禁用。
- [x] 写状态测试：主题重建保留当前参数、退出重入回默认；全部操作不写learned/cursors；旧播放队列在切入新工具时取消。测试默认值包括减法1−0、其他(1,1)。
- [x] 运行 `flutter test test/math_table_ui_test.dart` 确认失败；实现页面详情、算式、参数控件与表头说明。除法格显示被除数且明确行/列意义，乘法和除法使用groups/perGroup图示，加减本批仅完整算式解释，不新增可视化动画。
- [x] 表格ID使用“kind-row-column”；selectionRevision随有效选择变化，非法格不变更选择或定位。参数控件Wrap布局，所有按钮最小48并有中文语义，状态在initState创建。
- [x] 接入路由，重跑Tasks3–5与原 `test/math_state_test.dart test/math_activity_ui_test.dart test/number_ui_test.dart`，窄屏大字号和平板均通过。

## Task 6：完整回归与交付

**Files:** README.md、assets/RESOURCE_SOURCES.md、docs/phase-2-roadmap.md、docs/phase-3b-status.md、docs/phase-3b-ledger.md、docs/screenshots/phase-3b-*.png；更新新入口总数涉及的旧测试与生成器输出文案。

- [x] 执行 `dart format lib test tool`、`flutter analyze`、`flutter test`，记录本轮实际通过数与退出码，不沿用3A的82项。
- [x] 执行 `python3 -m unittest discover -s tool/tests`、`python3 tool/expand_phase2_content.py --check`、`dart run tool/validate_content.dart`，确认252项/25开放入口、21篇正文与原资源审计不变，生成器--check不写入。
- [x] 构建 `flutter build apk --debug` 和 `flutter build ios --simulator`，读取完成输出与退出码。
- [x] iOS模拟器走通0/100、百数末格可见、9+9、9−9、9×9、81÷9、12的不同除法事实；工具操作前后已学计数不变，重启确认旧记录保留，保存截图。人工未验项目逐项保留，不用Widget测试冒充真机观察。
- [x] 做唯一一次独立全变更审查；重要问题加RED回归后修复，跑受影响测试与全套。本人实施，不主动分派实现agent或逐任务审查。
- [x] 更新文档为252项/25入口，五工具无学习条目、选择不持久化，录音不变。无Android设备时只报告构建，保留Android/PDF/教学听审待补项；保留已观察的构建警告。
- [x] 勾选有证据的任务，ledger记录接口取舍和真实检查结果，不进行父级Git操作。下一批漫画/绘本仍需独立设计。

## 自查与交接

设计覆盖：Task1类别兼容；Task2全部规则/非法输入；Task3布局、语义、定位和大分组；Task4百数；Task5运算和路由；Task6资源与设备。Review Focus五项均在对应任务有明确失败测试。除法fact.left是被除数，row是除数，column是商，后续页面不得混用；百数row/column用零基映射且0返回null。

用户确认后已在当前会话内完成实施与唯一一次独立审查。最终94项Flutter测试、11项Python测试、静态分析、生成一致性、资源审计及双平台构建通过；iOS主流程与重启确认完成。审查指出的测试缺口已补，包括真实排队定位回调时序。Android设备与教学听审等既有缺口见docs/phase-3b-status.md，不标记为已完成。
