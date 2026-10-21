# 基础汉字、笔顺与字帖 2B Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans task-by-task. 功能已实施，最新证据见 docs/phase-2b-status.md。未勾选项含尚未完全覆盖的设备或手工验收，不代表整项功能未实现。

**Goal:** 将汉字认读扩充至 60 字，提供离线逐笔演示、自由描红和可打印 A4 PDF 字帖，同时保留 2A 的课程与学习进度。

**Architecture:** 继续使用 GetX、本地内容仓库和 learning_state_v1。认读资料、向量笔顺和练习轨迹分离；先以原有 6 字验证绘制、描红、PDF，再覆盖全部 60 字。页面与 PDF 共用字形来源和坐标规范，练习轨迹不参与“已学会”判定。

**Tech Stack:** 当前 Flutter 3.41.6 / Dart 3.11.4；保留已锁定依赖。拟新增 path_drawing（解析 SVG 路径）、pdf、printing，实施时核查版本与平台最低要求并写入 pubspec.lock；不在本轮计划编写时安装依赖。

**Spec:** docs/replica-proposal.md、docs/phase-2-roadmap.md 的 2B 范围；起点见 docs/phase-2a-status.md。

## 当前事实与范围

本轮重新读取代码：LearningItem 只有笔画数，没有结构化词组或笔顺资源；详情没有书写区域；工程没有笔顺资源、PDF 依赖或中文字体。2A 记录的 33 项测试及双端构建是上批次结果，本轮未重新构建，不将其作为 2B 完成证明。

本计划中的 60 字清单、课程分组、字帖布局与描红行为是本次建议的实现默认值。它们不是原站全量数据，也不声称对应某一版教材。2B 不包含严格笔顺评分、手写识别、跟读评分、保存手写作品、云同步或文学阅读器。

## Global Constraints

- 默认 Android/iOS；继续沿用 GetX，不重新初始化项目。
- 原有 155 个 ID、已学标记和学习位置保留，内容版本仍为 v1，状态仍为 learning_state_v1。
- 认读、笔顺、字体和 PDF 生成离线可用，App 运行时不访问笔顺 CDN 或在线字体服务。
- 新增 54 字默认暂缺录音，保留原 6 字音频；不要用未经核对的多音字 TTS 填充。发音质量继续沿用 unavailable/demo/verified。
- 清理下载缓存不能删除随包资源、设置或已学记录。
- 描红仅表示练习，不自动标记学会，不显示正确率或“书写通过”。
- 当前目录继承主目录 Git 仓库；仅修改当前工程，不创建分支、提交或操作主目录仓库。

## Review Focus

1. 内容重建覆盖已扩充数据：重复运行生成器仍是 60 个汉字、209 个总条目，不回退到 6 字，不删除旧 ID。
2. 字形方向与坐标：原始笔顺 Y 轴反向，显示、触摸和 PDF 必须一致；缩放与旋转后不能出现镜像、倒置或描线错位。
3. 触摸生命周期：多指、越界、pointer cancel、撤销、切字不能串入错误轨迹，描红不改变学习进度。
4. 播放生命周期：暂停、速度变化、切页和后台会停止对应定时任务；重放不叠加定时器。
5. 导出边界：空选择、未知 ID、缺字形/字体、最大批次、分页和取消分享有明确结果；失败不能留下貌似成功的空 PDF。

## 课程与资源决策

### 固定 60 字，十组各六字

| groupId | 名称 | 汉字，按默认顺序 |
|---|---|---|
| starter | 基础起步 | 一 二 三 人 口 山 |
| numbers | 数量 | 四 五 六 七 八 九 |
| nature | 自然 | 日 月 水 火 土 木 |
| directions | 方位 | 上 下 左 右 中 大 |
| comparisons | 大小与比较 | 小 多 少 长 短 高 |
| body | 身体 | 目 耳 手 足 心 头 |
| family | 家庭 | 父 母 子 女 兄 弟 |
| daily | 生活 | 门 车 马 牛 羊 鸟 |
| plants | 植物 | 花 草 竹 禾 米 果 |
| actions | 动作 | 来 去 走 出 入 开 |

六个既有 ID hanzi-yi/er/san/ren/kou/shan 不变；新增 ID 用 `hanzi-u<小写十六进制码点>`，例如四为 hanzi-u56db。每字包含主读音、笔画数、两个逐字注音词组及一条自编说明。长的主读音取 cháng，词组“长短”读 cháng duǎn、“长大”读 zhǎng dà；主读音不能直接套到所有词组。

课程不是完整年级目录。排序设置中的存储值 grade 保留，但中文标签改为“按课程”；按笔画/拼音排序保留，所有排序仍以稳定 ID 关联进度。

### 笔顺与字体来源

候选笔顺数据采用 [Hanzi Writer Data](https://github.com/chanind/hanzi-writer-data)，其数据文档声明适用 Arphic Public License，不能用程序代码许可证代替数据许可证。导入时固定提交 SHA、保存原始许可、记录每个文件的 SHA-256 和来源 URL，不打包整个上游仓库。

每字保留 strokes 与 medians；两者长度必须等于笔画数。显示使用原始有序轮廓逐笔高亮，不承诺连续笔锋模拟或严格书写判定。坐标按 [Make Me a Hanzi 格式说明](https://github.com/skishore/makemeahanzi#format) 统一：从源坐标转换为平面坐标时使用 `(x, 900-y)`，再缩放到内容方框。

PDF 标题、说明及拼音拟嵌入官方发布的 LXGW WenKai Regular 静态 TTF，保留原文件与 [OFL.txt](https://github.com/lxgw/LxgwWenKai/blob/main/OFL.txt)。维护者的[字体说明](https://github.com/lxgw/LxgwWenKai#授权信息)列明 OFL 1.1；实施时记录版本、下载地址、校验值，并检查实际字符覆盖，不依赖设备系统字体。练习格里的字形使用同一笔顺向量，避免手机和 PDF 的练习字形不一致。

PDF 生成与预览参考 [pdf 文档](https://pub.dev/packages/pdf)和 [printing 文档](https://pub.dev/packages/printing)。本轮仅核查候选资源的公开说明，没有下载资源、证明 60 字全部可用或验证字体实际嵌入；这些属于 Task 2/4/5 的验收工作。

## 文件与接口

以下 data/core/modules/services 路径均以 lib/app/ 为根；tool/assets/test/docs、pubspec.yaml 相对工程根目录。

保留现有学习路由，增加 `/practice/:itemId`、`/worksheet`。练习页只接受 chinese 分类已存在的 ID；非法参数显示可返回的错误页。

- 修改 learning_content.dart：新增 `AnnotatedWord(String text, List<String> pinyin)`；LearningItem 新增 `List<AnnotatedWord> words`、`String? strokeAsset`，旧 JSON 缺字段时分别默认空列表/null。
- 新建 data/hanzi_strokes.dart：`HanziStrokeData` 包含 character、strokes（SVG path 字符串）、medians（二维点数组）；`HanziStrokeRepository(AssetBundle bundle)`，`load(String assetPath) -> Future<HanziStrokeData>`，按需读取并缓存。
- 新建 core/glyph_geometry.dart：纯 Dart `GlyphTransform(side, inset=16)`，提供 `Point<double> toView(Point<double>)`、`toGlyph(Point<double>)`；页面和 PDF 的 SVG 序列化遵守同一变换定义。
- 新建 modules/handwriting/：`StrokeBoard(HanziStrokeData data, {required int visibleStrokeCount})`；StrokePlaybackController 提供 `void load(HanziStrokeData) / play() / pause() / replay() / stepForward() / setSpeed(double)`；TraceController 与 HandwritingView 通过现有 GetX 绑定资源与控制器。
- 新建 services/worksheet_pdf_service.dart：`WorksheetConfig({required List<String> itemIds, int rowsPerCharacter=2})`；`WorksheetLayout.paginate(config) -> List<List<String>>`；`WorksheetPdfService(ContentRepository content, HanziStrokeRepository strokes, AssetBundle bundle)`，`build(config) -> Future<Uint8List>`。服务在生成前核对 ID 与所有所需资源，布局类只负责参数边界与分页。
- 新建 modules/worksheet/：选择页与 PDF 预览页。选择/顺序使用稳定 ID，不以列表当前索引传递。

## Task 1：60 字认读及可重复构建

**Files:** tool/content_sources/base_catalog.json、tool/content_sources/hanzi.json、tool/expand_phase2_content.py；assets/data/content.json；lib/app/data/learning_content.dart、content_types.dart；现有学习列表/详情与设置页；test/hanzi_content_test.dart、tool/tests/test_catalog_build.py。

**Consumes:** 2A 的内容模型、groups/filteredItems/resumeItem 与 LearningStore。**Produces:** 60 个汉字认读，209 个总条目，仍是 13 个开放入口；新增词组结构，旧状态可直接读取。

- [x] 写失败测试：60 个汉字且无重复，十组各六字；旧六字 ID 和已学记录保留；“长大”与“长短”注音不同；旧 JSON 可读；新词组注音长度错误必须被校验器拒绝。
- [x] 运行 `flutter test test/hanzi_content_test.dart`，确认新行为缺失导致失败。
- [x] 将生产生成器的基线移到 tool/content_sources/base_catalog.json，汉字数据从 hanzi.json 读取，不再把 test/fixtures 作为生产输入。提供 `build_catalog(root: Path) -> dict` 与 `--check` 模式；后者只比较生成结果与已提交数据，有差异退出非 0，不改写文件。生成时验证全部数据，再替换目标文件；输入缺失/非法时保留原输出。
- [x] 新增两个词组的详情排版，接入十个课程组和“按课程”标签，保持存储值 grade。修改 Hanzi 默认排序，使课程顺序/显式 sortKey 生效。既有六字排序测试改用固定 fixture，另测全量课程/笔画/拼音排序。
- [x] 运行内容测试、`python3 -m unittest discover -s tool/tests` 与全部 Flutter 测试；验证重复构建不改变结果，失败构建不截断现有 JSON。新增 54 字无录音时明确 unavailable，既有音频不受影响。

## Task 2：六字离线笔顺与坐标闭环

**Files:** tool/import_hanzi_strokes.py；assets/strokes/4e00.json 等首六字资源、manifest.json；assets/licenses/；pubspec.yaml；lib/app/data/hanzi_strokes.dart、core/glyph_geometry.dart；modules/handwriting/stroke_board.dart、stroke_playback_controller.dart；test/hanzi_strokes_test.dart、test/stroke_playback_test.dart；扩展 tool/validate_content.dart。

**Consumes:** Task 1 的 strokeAsset、稳定 ID。**Produces:** 一二三人口山的笔顺资源加载、静态轮廓和可控逐笔演示，供描红与 PDF 使用。

- [x] 写失败测试：一/口分别为 1/3 笔；轮廓与中线笔数一致，非法路径/非有限坐标被拒绝；边长 288、内边距 16 时，源点 (0,900) 映射 (16,16)，(1024,-124) 映射 (272,272)，逆变换恢复源点。
- [x] 再写控制器测试：`play()` 每 600ms 显示下一笔；`pause()` 冻结；`stepForward()` 暂停并前进一笔；`replay()` 清零并启动；`setSpeed(0.5/1/2)` 生效；完成后停在最后一笔，不自动循环。使用可控时钟，切页、后台与 dispose 后不再触发计时。
- [x] 运行对应测试，确认失败；再导入固定上游提交的六字、许可和清单。导入工具只在开发时联网；App 使用随包文件，路径转为 ASCII 码点文件名并校验散列。
- [x] 实现轮廓解析、统一坐标变换、田字格、灰色完整轮廓和按序高亮，显示“第 n / m 笔”；接入播放/暂停/重放/单步/速度控件。资源加载失败保留认读并显示“笔顺暂时无法打开”，不让全 App 启动失败。
- [ ] 跑单元/Widget 测试与资源校验；在固定尺寸保存六字截图，逐字检查方向、缺笔、裁切和口的三笔结构。笔顺入口仅在资源存在且有效时开放。

## Task 3：六字自由描红

**Files:** modules/handwriting/trace_controller.dart、handwriting_view.dart、bindings/handwriting_binding.dart；lib/app/routes/app_pages.dart；学习详情页；test/handwriting_test.dart。

**Consumes:** Task 2 的 StrokeBoard、GlyphTransform 与资源仓库。**Produces:** `/practice/:itemId` 练习页，支持切换笔顺演示/自由描红、撤销和清空。

- [x] 写失败测试：第一根手指独占当前轨迹，第二根手指不追加；框外点忽略；pointer cancel 丢弃未完成轨迹；撤销删除最后一条已完成轨迹；清空/切字清掉轨迹和活动指针；任何练习不写入 learned。
- [x] 运行 `flutter test test/handwriting_test.dart`，确认失败。
- [x] 实现 `TraceController.begin(pointerId, Point<double>) / update(pointerId, point) / end(pointerId) / cancel(pointerId) / undo() / clear()`；轨迹保存为练习区域内 0..1 归一坐标，尺寸变化后重新投影，不保存屏幕像素。撤销先取消未完成轨迹，再删除上一条；关闭页面即释放临时草稿。
- [x] 使用原生触摸事件、画布裁切与路径绘制，背景为相同字形浅色轮廓。进入描红时暂停演示；所有按钮、笔画计数和状态可被读屏理解，不在界面加入“通过/正确率”文案。
- [ ] 验证旋转/重排后轨迹对齐、320px/200% 字号下控件可达、多指不崩溃、返回/下一字不串轨迹；跑全套测试。

## Task 4：六字 A4 字帖与原生预览

**Files:** assets/fonts/LXGWWenKai-Regular.ttf、assets/licenses/字体许可；services/worksheet_pdf_service.dart；modules/worksheet/worksheet_view.dart、worksheet_preview.dart；routes/app_pages.dart；pubspec.yaml；test/worksheet_layout_test.dart、test/worksheet_export_test.dart。

**Consumes:** Task 1 的汉字/词组与 Task 2 的笔顺轮廓。**Produces:** 选择汉字和行数，离线生成 A4 PDF，原生预览与系统分享/打印入口。

- [x] 写失败测试：空选择、重复 ID、未知 ID、非汉字 ID、超过 60 项、rows 不在 1..4 均返回明确校验失败；输入顺序保留；构建缺笔顺或字体时失败，不用空白格伪装成功。
- [x] 固定布局：A4 竖版；页边距 36pt，页眉 32pt，页脚 18pt；田字格边长 48pt，每行 9 格（1 黑色示范、3 灰色描红、5 空格）；字标题 22pt、行距 8pt、字块后间距 12pt。默认每字 2 行；字块不跨页。按该布局，6 字默认导出应为 2 页，60 字每字 4 行应为 30 页，测试分页计算与页面尺寸。
- [x] 运行布局和导出测试确认失败，下载并锁定官方静态 TTF、保留许可；检查标题、说明、全部汉字和拼音字符在字体中存在。使用随包字体，不调用在线 GoogleFonts；不全局替换 App UI 字体。
- [x] 实现 WorksheetPdfService，以矢量格线/字形生成真实 PDF，不截取 Widget。通过 printing 的 PdfPreview、分享和打印入口使用同一份 PDF 字节；用户取消不改进度或报成功保存，生成失败可重试，重复点击不启动多个导出任务。
- [ ] 产出实际六字默认 PDF 和最大批次 PDF，使用 PDF 技能要求的渲染检查流程逐页核对缺字、分页、格线、字形方向与裁切；Android/iOS 均实际打开预览。不执行自动打印或向外部收件人发送文件。

## Task 5：推广到 60 字与资源一致性

**Files:** assets/strokes/其余 54 字、manifest.json；tool/import_hanzi_strokes.py；tool/validate_content.dart；test/hanzi_resource_test.dart；assets/RESOURCE_SOURCES.md。

**Consumes:** 已通过六字验证的绘制、描红和 PDF。**Produces:** 全部 60 字均具备认读、逐笔演示、描红与字帖输出。

- [x] 写失败测试：每个 chinese 项必须关联唯一、存在的字形，字符与条目一致，轮廓/中线数量等于笔画数；资源散列或许可缺失时校验失败；笔顺路径不能越出允许的 assets/strokes 目录。
- [x] 导入同一固定提交的其余 54 字，保留每个来源与散列；逐条检查主读音、词组、多音字及笔画数。校验器不把“JSON 可读”当成教学审核完成，人工审核状态单列记录。
- [x] 渲染 60 字总览和跨页字帖，抽查长/鸟/女/竹等不同结构、横折/撇捺、多个笔画端点与复杂轮廓；无论单字缺资源还是加载出错，认读功能仍可使用。
- [x] 跑生成器 `--check`、全部资源校验和测试；确认内容为 209 项、13 个开放入口，原有 155 个 ID 全保留，旧已学记录重启后可见。

## Task 6：回归、双端验收与交付

**Files:** 现有回归测试；README.md；docs/phase-2b-status.md；docs/screenshots/phase-2b-*.png；docs/artifacts/worksheet-*.pdf。

**Consumes:** Tasks 1–5 完成的功能。**Produces:** 可复核的 2B 交付及资源审核边界。

- [x] 运行 `dart format lib test tool`、`python3 -m unittest discover -s tool/tests`、生成器 `--check`、`dart run tool/validate_content.dart`、`flutter analyze`、`flutter test`；记录新测试数量，不沿用旧 33 项结果。
- [ ] 构建 Android debug 与 iOS 模拟器；模拟器走通“汉字→笔顺→描红撤销/清空→选字→PDF 预览→返回”，测试后台、切页、重启恢复、最大字帖和取消分享；保存证据，不安装私人真机或发布商店。
- [x] 独立代码审查后，对重要问题先补失败回归再修复，跑完整测试；记录无独立仓库的处理，不对主目录 Git 操作。
- [x] 文档区分自动校验、视觉验收和教学人工审核；保留原先 57 项拼音缺录音的说明，列出新增汉字录音状态，不宣称全站复刻完成。后续进入 2C 阅读器。

## 计划自查与状态

2026-10-20 执行更新：60 字、笔顺、描红与 PDF 功能已实现；49 项 Flutter 测试、3 项 Python 测试、资源审计及双端构建通过。iOS 原生预览与分享取消已验收。尚待 Android 原生预览、所有六字逐一手机截图和物理旋转专项补验；执行取舍见 docs/phase-2b-ledger.md。

自查：六个任务覆盖认读、资源、坐标、演示、描红、PDF、兼容和双端交付；5 项 Review Focus 均有对应失败测试；接口按学习仓库、字形仓库、画布、轨迹和导出分开。资源实际缺失或使用条件不满足时，受影响能力不开放并明确记录，不静默替换数据源或声称完成。
