# 共用阅读器与首批文学内容 2C Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans 在当前会话内逐项实施；末尾进行一次独立审查。未勾选项含未完成的人工或设备子项，不得把设计或旧版本测试当作本轮验收。

**Goal:** 开放古诗、成语故事、三字经三个入口，实现离线逐句阅读、可取消连续朗读、稳定 ID 进度恢复，保留现有全部能力。

**Architecture:** 沿用 ContentRepository 的目录和 LearningStore 的 v1 状态，正文由 ReadingRepository 按需读取。阅读页与原有认读页共用 LearningAudio 一个音频所有者，后端给完成事件附带请求身份；正文、播放和已学标记分别管理。

**Tech Stack:** Flutter 3.41.6 / Dart 3.11.4，GetX、audioplayers 6.7.1、shared_preferences；保留 pubspec.lock，不新增运行时依赖。开发时可用现有 macOS say/afconvert 生成离线 demo，不能依赖运行设备上的 TTS。

**Spec:** docs/superpowers/specs/2026-10-20-learning-phase-2c-design.md；起点见 docs/phase-2b-status.md。

## Global Constraints

- 保留 Flutter 3.41.6 / Dart 3.11.4、GetX、Android/iOS、本地资源和 `learning_state_v1`。
- 原有 209 个学习 ID、设置、课程顺序、字形及字帖功能保持兼容。不新增账号、云同步、在线 TTS、视频、插图生成、背诵评分或自动判定学会。
- 固定新增 32 个学习条目、21 篇正文：诗 10、故事 10、三字经合集 1；三字经独立学习条目 12 个、正文 12 行、共 36 字。总数 241，开放入口 16。
- 诗文核对古籍正文；解释、故事改写自编，不复制现代译文、原站注音或配图。demo 不标 verified；原 98 段音频及 111 项暂缺录音状态不变。
- 整段播放只覆盖当前篇，从当前句开始；缺录音或失败即停在该句，不静默跳句。听完不自动标记学会。
- 当前工程继承用户主目录 Git。只在本工程操作，不使用父级 git status/add/commit/branch；实施取舍写入本计划专属 ledger，不创建主目录工作树。
- 执行时在 docs/phase-2c-ledger.md 记录 RED/GREEN、阶段证据和取舍；读已有 ledger 后续作，避免重复实施。

## Review Focus

1. 停止、切页、后台或点播其他内容后，旧 completion/异步 play 错误不能推进队列、清除新播放态或改当前句；Task 3 用带身份假事件覆盖。
2. 目录与正文写入中途失败或 revision 不一致：恢复旧文件，或仅禁用阅读，不影响旧 209 项启动；Tasks 1/2 做损坏 bundle 和替换失败测试。
3. 标点、括号及大字号：注音与 Unicode 字符对齐，标点附着前字，关闭拼音隐藏全部注音；Tasks 1/4 校验并做 320px/200% Widget 测试。
4. 三字经合集、重复/失效路由与进度：按稳定行 ID 定位、逐句标记，不能误记整篇或其他句；Task 4 测深链、重启、并发点击和保存失败。
5. 缺录音、单篇损坏、重复点击和生成失败：可重试、无伪成功、无跳句、无半份资源覆盖；Tasks 2/3/5 验证。

## 文件与接口约定

以下 data/services/modules/core 路径以 lib/app/ 为根，其他路径相对工程根目录。

- `data/content_types.dart`：新增 reading 枚举；保留旧类型的校验规则。纯 Dart `validateAnnotations(String text, List<String> pinyin)` 校验阅读注音：按 runes 对齐，汉字非空；允许标点 `，。！？；：、（）《》“”‘’—…·` 对应空注音，不允许把汉字注音留空。
- `data/learning_content.dart`：LearningItem 增加可选 `readingId`、`readingLineId`（默认 null）；ContentRepository 增加可选 `readingRevision`（旧 JSON 为 null）。readingLineId 仅三字经使用，避免由数组位置或字符串截取推导行 ID。
- `data/reading_types.dart`：纯 Dart 不导入 Flutter。`ReadingLine` 含 id/text/pinyin/explanation/audio/audioQuality/learningItemId；`ReadingPassage` 含 id/categoryId/title/titlePinyin/author/sourceLabel/intro/lines/provenance。模型通过 fromJson 创建不可变集合；`validateReadingPassage(Map<String,dynamic> passage, Map<String,dynamic> catalog) -> void` 校验单篇及其引用；`validateReadingData(Map<String,dynamic> body, Map<String,dynamic> catalog) -> void` 遍历前者，再检查完整文档的唯一性、覆盖与交叉引用。
- `data/reading_repository.dart`：`ReadingRepository(AssetBundle bundle, ContentRepository content)`；`Future<ReadingPassage> load(String readingId)`。按需读取，成功按 id 缓存，失败不永久缓存；使用 validateReadingPassage 只解析校验所选作品，资源 revision 不匹配抛明确错误。完整审计由 validateReadingData 完成，单篇错误不阻断其他旧学习内容。
- `services/learning_audio.dart`：`AudioCompletion(int requestId, {Object? error})`；AudioBackend 的 `completed` 改为 `Stream<AudioCompletion>`，`play(String path, {required int requestId})`，stop/dispose 接口不变。所有假后端同步改签名。`AudioCue(String id, String? path)`；LearningAudio 保留 `Future<void> play(String path)`、stop、shutdown，新增 `Future<void> playSequence(List<AudioCue> cues)`、`RxnString activeCueId`、`RxBool sequencePlaying`。playSequence 的 Future 在首句启动或被阻断后结束，不等待整篇结束；后续由完成事件推进。
- `services/learning_store.dart`：新增 `Future<void> setCursors(Map<String,String> updates)`，在现有串行 `_update` 内一次写入多个 cursor；旧 setCursor 可委托该接口，状态 schema 不变。
- `modules/reader/reading_controller.dart`：`ReadingController(ReadingPassage passage, LearningStore store, LearningAudio audio)`，`Future<void> open({String? requestedLineId})`、`selectLine(String id)`、`playLine(String id)`、`playFromCurrent()`、`stop()`、`toggleLearned()`；`currentLineId` 与 `saving` 可观察。控制器销毁解绑 worker、取消旧操作并停止所属朗读。
- `modules/reader/reading_view.dart`：`ReadingView({required String readingId, String? lineId})`，处理异步加载、错误/重试与控制器生命周期。`core/annotated_reading_text.dart` 负责标点附着和注音换行，不改动原有认读组件行为。
- `/read/:readingId?line=<stable-line-id>`；目录的三字经条目通过 readingLineId 定位。旧 `/learn/:categoryId/:itemId` 中的 reading 条目由路由守卫转到阅读器；非法作品显示可返回错误页，非法 line 回退第一句并提示，忽略无效数组索引。

## Task 1：阅读模型、校验及旧目录兼容

**Files:** 修改 data/content_types.dart、learning_content.dart；新增 data/reading_types.dart、reading_repository.dart；新增 test/reading_content_test.dart、test/reading_repository_test.dart、test/fixtures/reading_sample.json。此任务不开放空入口。

**Consumes:** 现有 ContentRepository.fromJson、AssetBundle。**Produces:** 上述模型、校验接口、可选阅读引用与 revision，供 Task 2 生成器和 Task 4 阅读器使用。

- [x] 写失败测试：旧 209 项 JSON 没有 reading 字段仍可读；`床前明月光，` 对应 6 个注音位置、末位为空；汉字空注音、标点带拼音、长度不符、重复 passage/line ID、跨篇 line 引用、缺 explanation、非法音频路径均被拒绝。用一诗一经典片段 fixture，不预先写入完整生产数据。
- [x] 写仓库失败测试：匹配 revision 正常读取；未知作品、损坏目标作品、revision 不符可报告错误；另一个正常作品仍可读；模拟首次 load 失败后二次成功，证明失败 Future 不被永久缓存。旧 ContentRepository 不读 readings.json，坏正文不会让旧内容启动失败。
- [x] 运行 `flutter test test/reading_content_test.dart test/reading_repository_test.dart`，确认因新接口缺失失败。
- [x] 实现接口。目录中 reading 条目必须有安全 readingId；readingLineId 只能与 readingId 一同出现。完整正文校验要求每个 learningItemId 唯一关联正确类别，诗/故事一篇对应一个目录项，三字经每行一项；正文行可选 learningItemId 在诗/故事留空，整篇标记从目录反查唯一条目。
- [x] 运行新测试与 `flutter test test/content_test.dart test/content_upgrade_test.dart test/hanzi_content_test.dart`，通过后记录 Task 1。

## Task 2：21 篇正文、确定性生成与内容来源

**Files:** 新增 tool/content_sources/readings.json、tool/reading_catalog.py、tool/tests/test_reading_catalog.py、test/fixtures/phase2b_ids.json；修改 tool/expand_phase2_content.py、tool/tests/test_catalog_build.py；生成 assets/data/content.json、readings.json；修改 pubspec.yaml 的 assets。正文初始 audio=null、audioQuality=unavailable。

**Consumes:** Task 1 schema。**Produces:** 241 条目录、21 篇正文与相同 readingRevision；three new available categories。

固定学习条目 ID：

| 类别 | 后缀或完整 ID |
|---|---|
| poetry- | yong-e、jingyesi、chunxiao、minnong-2、dengguanquelou、xunyinzhebuyu、jiangxue、gulangyuexing-excerpt、xiaochi、shanxing |
| idiom- | shouzhudaitu、wangyangbulao、huashetianzu、yanerdaoling、jingdizhiwa、kezhouqiujian、bamiaozhuzhang、hujiahuawei、zixiangmaodun、yugongyishan |
| classics | classic-opening-01 至 classic-opening-12，共用 classics-opening |

诗/故事 readingId 与条目 ID 相同；正文行依次为 `<readingId>-line-01` 等。三字经正文行为 classics-opening-line-01 至 -12。ID 一经交付不因标题改字或版式变化而重排。

- [x] 先保存当前 209 个真实 ID 为 fixture；写失败测试断言完整包含、总数 241、开放 16、诗 10、故事 10、三字经 12。断言 21 篇正文；三字经逐字等于设计中的 36 字；《古朗月行》只取前四句并标节选；《悯农》是其二。故事每篇 4–6 句，每句去标点后 12–28 汉字。
- [x] 写生成器失败保护测试：相同输入结果逐字相同；`--check` 不写任何文件；无效正文/跨引用不改旧输出；模拟第二次 `os.replace` 抛错，恢复两份原内容并清理临时文件；原先任一输出不存在时，回滚恢复“缺失”状态。
- [x] 运行 `python3 -m unittest discover -s tool/tests`，确认新增范围和接口尚缺导致失败。
- [x] 核对十首诗和典故出处：只使用可核实古籍文本，记录精确页面 URL、版本说明和结构校对状态；自编解释和故事改写。明确多音字，如“少”“处”“见”“为”“长”“行”，不能全靠逐字默认读音。标题括号和正文标点按 Task 1 规则注音。尚未核实的正文不得生成音频；无现代译文复制。
- [x] 实现 `build_reading_catalog(root: Path, base: dict) -> tuple[dict,dict]`，为既有 `build_catalog(root)` 保留返回目录的兼容接口，内部读取同一生产源。对旧 209 项使用 Task 2 fixture 精确比对；不回退到 phase1 内容规模。
- [x] readingRevision 取规范正文 `{version:1,passages:[...]}` 的 UTF-8 JSON SHA-256（sort_keys=True、separators=(',',':')、ensure_ascii=False，不含 revision 自身），目录和正文写同一值。`write_catalog_pair(root, catalog, body) -> None` 先验证、暂存和备份再替换；异常执行回滚，保留原错误。导入模块无写入副作用；生产源不得依赖 test/fixtures。
- [x] 运行生成器、`--check`、Python 测试、Task 1 测试。当前缺录音的正文仍能完整阅读；此处不宣称朗读已交付。

## Task 3：带完成事件身份的音频队列

**Files:** 修改 services/learning_audio.dart、test/learning_audio_test.dart 及现有所有 AudioBackend 假实现；新增 test/reading_audio_test.dart。

**Consumes:** Task 1 的可选音频路径（用 AudioCue 传递，不让音频服务依赖阅读模型）。**Produces:** 可复用 playSequence、activeCueId、sequencePlaying，以及旧单条播放接口。

- [x] 用可控假后端写失败测试：emit 当前 requestId 正常逐句播放、末句清空播放态；旧 requestId 完成不推进；停止后晚到事件不启动后续；连续重启、单句抢占和后台均取消旧队列；旧 play Future 抛错不能清除较新播放态。不要用按音频时长的 sleep 驱动正常前进。
- [x] 再写边界测试：空队列和重复 cue ID 返回 ArgumentError；首句/中句 path=null 时定位该句并停止，后一句不播；当前解码失败停止、可从当前句重试；多次 stop/shutdown 幂等，dispose 后不响应事件。既有“只播放最新请求”测试保留。
- [x] 运行 `flutter test test/learning_audio_test.dart test/reading_audio_test.dart`，确认新增队列行为缺失。
- [x] 改造后端。AssetAudioBackend 每次 play 创建独立 AudioPlayer 播放实例，订阅闭包捕获 requestId；替换前先移除旧活动实例、取消订阅、停止并 dispose，任意时刻最多一个活动实例。stop 先使活动身份失效，再 await 清理。播放实例不能复用 playerId；dispose 关闭后端事件流。测试替身需支持人为晚发旧事件。
- [x] 服务维护“会话代次”和“每次后端播放 requestId”。stop/新请求同步失效旧会话；所有 play、完成推进、错误处理经现有串行命令队列，执行前再次检查身份。收到完成事件时必须同时匹配活动 requestId 与会话；只匹配会话但无法辨认旧声音事件不合格。异步错误只更新所属活动请求。
- [x] playSequence 复制输入为不可变队列，从第一项开始；每次设置 activeCueId 后核查音频；缺失显示“本句暂缺录音，可继续阅读。”；失败使用现有可重试错误文案并停止。stop 清除音频状态/队列，阅读页保留其独立 selected line；页面不要靠 playingId 反推已学状态。
- [x] 跑全部音频测试及 `flutter test test/learning_edges_test.dart test/widget_test.dart`。检查后台、路由观察器仍作用于唯一 LearningAudio。

## Task 4：阅读页、逐句进度与三类目录接入

**Files:** 新增 modules/reader/reading_controller.dart、reading_view.dart、core/annotated_reading_text.dart；修改 services/learning_store.dart、modules/learning/learning_list_view.dart、core/learning_label.dart、routes/app_pages.dart、main.dart；新增 test/reading_progress_test.dart、reading_ui_test.dart；更新受枚举/入口数量影响的既有测试。

**Consumes:** ReadingRepository、playSequence、已有 LearningStore/主题/全局拼音。**Produces:** 三入口可完整阅读、恢复和手动标记。

- [x] 写进度失败测试：诗与故事标记对应唯一学习条目；三字经只标当前三字句；听完不标记；有效请求行优先于 saved line；未知显式行回退第一句并提示、无参数时失效 saved line 回退第一句。旧状态重开仍保留原 learned/settings/cursors。
- [x] 写保存/并发测试：setCursors 一次持久化更新 category 与 reader 两个键；写失败不发布半份状态且允许继续看；快速选择 A/B 后 A 的迟到保存/播放不能把界面或音频切回 A；关闭后异步加载不得写已销毁控制器。音频自动推进只更新高亮，不写 cursor。
- [x] 写 Widget 失败测试：三个入口已开放；点击三字句直达同篇正确行；兼容旧 learn 深链；上一/下一句、末句“本篇已读完”、缺录音提示、错误重试、返回列表。320px/200% 与平板无溢出；标点和前字属于同一换行单元；关闭拼音时标题及所有正文注音隐藏，解释仍显示。
- [x] 运行 `flutter test test/reading_progress_test.dart test/reading_ui_test.dart` 确认失败，再实现上方接口。ReadingRepository 由 BabyLearnApp 以 rootBundle 注册，不增加阻塞启动的正文 Future；测试可注入假 bundle/repository。不要在 Obx/build 中反复加载或创建播放器。
- [x] 阅读标题用 28px、正文默认 26px、解释默认 16px，遵守系统 text scaling；内容最大宽 760px，不固定句高。标点附着前一个文字注音单元，末尾“，”不能单独占一行。当前句以边框/底色及读屏“当前句”共同标示，按钮有中文语义名称。
- [x] 用户选句、上一/下一或播放进度真正变化时才定位到对应句；用户手动滚动时不在每帧抢回。点击句子只选中；句内“听这一句”先取消旧朗读，再播放本句；从当前句连续播放只传当前及后续行，不跨篇。切换到其他学习页先由音频观察器取消，控制器销毁移除 Rx worker。
- [x] 实现单次保存多 cursor，操作成功发布状态，失败用现有 saveWithFeedback；页面状态先选中句再尝试保存，不因存储异常阻塞阅读。三字经保存类别项及 reader 行；诗/故事保持整篇类别 cursor。不自动改 learned。
- [x] 跑 Task 4 测试及全套 Flutter 测试。既有升级测试改成 fixture 驱动预期，不能为了 241 个总数删除原 ID/状态断言；笔顺、描红与 PDF 测试继续通过。

## Task 5：离线示范音频、来源清单与联合审计

**Files:** 新增 tool/generate_reading_audio.py、assets/audio/reading/manifest.json、对应 WAV；修改规范正文 audio 字段、pubspec.yaml、assets/RESOURCE_SOURCES.md、tool/validate_content.dart；新增 test/reading_resource_test.dart、tool/tests/test_reading_audio.py。

**Consumes:** Task 2 已核对文本与注音、Task 3 队列。**Produces:** 有效资源为 demo，其余明确 unavailable；可复核的逐句录音来源。

- [x] 写失败测试：reading 音频路径必须为 `audio/reading/<lineId>.wav`；所有引用文件存在、PCM 非静音；manifest 的 lineId/正文与朗读文本散列/音频 SHA-256 对应；重复或孤立 manifest 条目、未知质量、缺来源、verified 无 reviewer 均失败。无 reading 的旧 fixture 继续能审计。
- [x] 写生成脚本失败保护测试：仅允许结构校对通过的正文；未校对/旧文本散列变化不能复用旧 WAV。合成命令失败、PCM 校验失败时不得更新正文为 demo，不截断旧可用 WAV；不改写原有 98 段音频和 111 项 unavailable。
- [x] 运行 Dart/Python 新测试确认缺资源或校验规则导致失败。
- [x] 使用已安装系统中文语音生成 demo，脚本只在开发机运行。由规范源显式给 `speechText`：正文同义读法保持词句不变，多音字合成不能凭空保证正确；若无法可靠表达读音或听审发现问题则保留 unavailable。将正文核对和专业听审状态分开，不用“结构通过”表示录音标准。
- [x] 每条来源记录 lineId、asset、source='macOS system speech; development demo'、voice、speechText、textSha256、audioSha256、quality、reviewedBy=null。音频先生成到临时文件并验证，再替换目标；正文/manifest 以共同验证后的快照提交，任何失败保留旧可用输出。
- [x] 扩展纯 Dart 资源审计调用 validateReadingData，检查全部目录与正文引用、revision、文件、PCM、散列、来源和许可说明；保留全部笔顺/字体/WAV 校验，不因新增阅读跳过旧资源。App 不在运行时读取开发脚本或联网补音。
- [ ] 重建两份 JSON、运行生成器 `--check`、联合资源审计、Python 和 Flutter 全套测试；抽听诗文多音字及故事长句，记录未完成听审和缺录音列表，不宣称全量标准录音已完成。

## Task 6：最终回归、设备验收与交付

**Files:** README.md、docs/phase-2-roadmap.md、docs/phase-2c-status.md、docs/phase-2c-ledger.md、docs/screenshots/phase-2c-*.png。

**Consumes:** Tasks 1–5。**Produces:** 可复核的 2C 功能交付与设备/内容审核边界。

- [x] 运行 `dart format lib test tool`、`python3 -m unittest discover -s tool/tests`、`python3 tool/expand_phase2_content.py --check`、`dart run tool/validate_content.dart`、`flutter analyze`、`flutter test`，逐条确认退出码与结果，记录本轮测试数，不沿用 2B 的 49 项。
- [ ] 构建 `flutter build apk --debug` 与 `flutter build ios --simulator`。iPhone 17 Pro 模拟器走通选诗→点句→连续朗读→停止→故事→三字经单句标记→返回→恢复；再测试播放中后台/切页、缺资源重试、关闭拼音与大字号。不得仅凭测试 Future 完成就宣称模拟器真听到声音。
- [ ] 重启后核对旧已学记录与新 reader cursor；清缓存仍保留进度和随包资源。若无 Android AVD，明确只验证 Android 构建，不安装私人真机；2B PDF Android 设备补验仍单列保留。
- [x] 按 executing-plans 要求进行唯一一次全变更独立审查；重要问题补 RED 回归再修复，跑受影响测试及完整套件。不得主动分派多个实现 agent 或逐任务审查。
- [x] 更新交付文档：241 项/16 入口、实际可用 demo 数与 unavailable 数、内容来源、正文核对/自动审计/听审的区别、截图、构建警告及设备缺口。不虚报古诗/故事标准发音或全站完成。
- [x] 将本计划中已验证项勾选，保留未完成的设备验收项；交付当前能力与下一阶段建议，不对父级 Git 提交或推送。

## 自查与交接

设计覆盖：Task 1 模型与坏资源隔离；Task 2 固定清单及双文件一致性；Task 3 音频身份与取消；Task 4 UI/进度；Task 5 demo 来源审计；Task 6 回归和交付。五项 Review Focus 均落实到所属任务的失败测试。自查修正：单篇仓库使用独立 validateReadingPassage，避免完整覆盖校验意外使其他坏作品阻塞目标作品；目录增加 readingLineId，避免用可变位置推导三字经行 ID。

实现澄清：目录增加可选 readingLineId，用于三字经深链；两个 cursor 用 setCursors 单次写入；不改变状态 schema。播放后端附带完成请求身份，避免只靠上层 token 无法识别迟到声音事件。以上是已确认设计的接口细化。

用户确认后已在当前会话完成 Tasks 1–5 和最终回归。63 项 Flutter 测试、8 项 Python 测试、静态分析、联合审计及双平台构建通过。未勾选的复合项中，自动检查和 iOS 主流程已完成；专业抽听、部分设备交互与 Android 运行补验仍待完成，详见 docs/phase-2c-status.md。
