# 3D Drawing Board Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking. 沿用Native：当前会话本人实施，末尾一次独立审查，不逐任务分派agent。

**Goal:** 开放画板，支持自由绘画、会话内撤销重做、本机单幅草稿与PNG系统分享。

**Architecture:** 纯数据模型与输入/历史控制器独立于现有描红。独立PreferenceStore队列保存草稿；屏幕和PNG共用绘制函数；专用原生通道打开Android/iOS分享面板。

**Tech Stack:** 当前Flutter/Dart、GetX、SharedPreferencesAsync、Canvas、MethodChannel、Kotlin、Swift；不新增运行时依赖，测试复用已有image。

**Spec:** [已确认设计](../specs/2026-10-21-learning-phase-3d-design.md)。状态：用户确认后已实施，设备范围与证据见docs/phase-3d-status.md。

## Global Constraints

- 学习条目仍261项，开放入口27增至28；不新增已学ID，不改learning_state_v1、旧条目/revision、190段demo和131项缺录音。
- 独立/drawing与ActivityKind.drawing；旧/learn/drawing重定向；不得进入ArithmeticState。现有TraceController保持原行为。
- 画纸正方形，显示最大640逻辑像素；参考及PNG尺寸1024×1024，白底。坐标归一化[0,1]，序列化四位小数。
- 颜色固定#263238/#E85D5D/#E9A23B/#30946D/#477BC0/#9365B8；宽度4/10/20参考像素；默认黑色、中号。控件至少48×48。
- 单指输入，第二指忽略；单点为圆点，圆头圆角、裁切纸面；有效起点后的移动限制边界，非有限数拒绝；取消、退出、尺寸变化丢弃活动笔。
- 最多256笔、合计12000采样点、JSON UTF8≤1MiB；移动距离≥2参考像素才追加；达限保留有效画面并提示可导出或撤销。
- 独立键drawing_draft_v1，version=1；只保存可见完成笔迹与画笔设置，历史不跨会话。清缓存保留草稿；清画板保留课程进度。
- 清空确认：“清空当前画面？可以在本次打开期间撤销。”；说明：“重启后保留画面，操作历史重新开始”。
- 初载前禁画；损坏/读失败不自动覆盖旧值。保存串行、合并未开始快照；仅最新版本成功可显示已保存。返回flush失败可留页重试或仍离开。
- PNG不可变快照，空画禁导出、重复导出禁用；仅纸面。平台仅收PNG字节/锚点，≤12MiB，验证格式，独立缓存目录，旧文件超过24小时才清理。
- Android FileProvider不可导出且仅暴露专属缓存子目录；iOS兼容隐式引擎/Scene并设置iPad锚点；不新增外部存储/相册权限。结果只表述面板已打开，不表述已发送。
- 不提交、推送或操作继承的用户主目录Git/worktree。保留既有修改；验收打开分享面板后取消，不发送。

## Review Focus

1. 旧写入晚完成、失败后又编辑：最新状态不能误报已保存，也不能被旧值覆盖（Task2延迟写测试）。
2. 撤销后开始新笔又被系统取消：重做必须保留；清空后仍可撤销恢复（Task1历史测试）。
3. 导出期间编辑或退出页面：PNG保持点击时快照，异步完成不得操作已销毁页面（Task3/5测试）。
4. 旋转、多指、画布与页面滚动竞争：不产生跨笔连线、不让绘画拖动页面，工具区仍可滚动（Task1/5测试）。
5. 原生异常参数、无可用presenter及文件分享延迟读取：明确报错、锚点有效、当前文件不提前删除（Task4测试及设备验收）。

## 文件职责

- 新增lib/app/modules/drawing/drawing_document.dart：不可变数据、编码校验与常量；drawing_controller.dart：输入、历史、修订号；drawing_draft_store.dart：独立键与保存队列。
- 同目录drawing_painter.dart：公共Canvas绘画；drawing_png_service.dart：离屏编码；drawing_share_service.dart：通道封装；drawing_view.dart：页面、生命周期与返回处理。
- 修改lib/app/routes/app_pages.dart、app_routes.dart、lib/app/data/content_types.dart、lib/main.dart：入口与依赖；tool/number_catalog.py、expand_phase2_content.py、tool/validate_content.dart及既有类别校验：drawing能力与审计。
- Android MainActivity.kt注册通道，新增同包DrawingShareHandler.kt与res/xml/drawing_share_paths.xml，修改AndroidManifest.xml。iOS新增Runner/DrawingShareHandler.swift，修改AppDelegate.swift及必要的Runner.xcodeproj/project.pbxproj文件引用。
- 新增test/drawing_{controller,draft_store,png,share,ui,resource}_test.dart；原有内容、路由、数学和音频测试随能力扩展更新。原生测试放android/app/src/test/.../DrawingShareHandlerTest.kt与ios/RunnerTests/DrawingShareHandlerTests.swift；若项目无测试target，在Task4建立最小可运行target并记录命令。
- 交付docs/phase-3d-status.md、docs/phase-3d-ledger.md、docs/artifacts/phase-3d/、docs/screenshots/phase-3d-*.png；更新README.md、assets/RESOURCE_SOURCES.md、docs/phase-2-roadmap.md。

## Task 1：数据、输入与会话历史

**Interfaces:** `DrawingPoint(double x,double y)`；`DrawingStroke({required int color,required double width,required List<DrawingPoint> points})`；`DrawingDocument({required int color,required double width,required List<DrawingStroke> strokes})`不可变；`DrawingDocument.decode(String raw)`抛FormatException，`String encode()`严格校验。`DrawingController extends ChangeNotifier`：`document`、`activeStroke`、`revision`、`canUndo/canRedo/limitReached` getters；`restore(DrawingDocument)`只在加载成功调用；`begin(int pointer,double x,double y)`、`move(...)`、`end(int pointer)`、`cancel()`、`setBrush({int? color,double? width})`、`undo()`、`redo()`、`clear()`。输入坐标已归一化，begin/move/end返回bool表示是否接受；revision仅在可持久化状态变化时递增。

- [x] 写drawing_controller_test：单点、移动采样、开始捕获颜色/宽度、多指忽略、外起点拒绝、越界移动clamp、NaN/Infinity拒绝、取消不提交；断言256笔/12000点/1MiB边界以及达限仍可撤销、保存、导出。编码验证未知版本/色值/宽度/空笔/超大输入与四位精度。
- [x] 写历史测试：undo→begin→cancel后canRedo=true；undo→新笔end后canRedo=false；clear→undo恢复原图→redo为空；恢复草稿后历史为空；设置不进历史，undo/redo/clear先取消活动笔。
- [x] 运行`flutter test test/drawing_controller_test.dart`，确认因未实现而失败。
- [x] 实现上述两个文件；历史存不可变前后画面快照，共享未改变的stroke引用，不深复制点列；清空旧redo时释放引用，dispose释放全部历史，不改描红。笔/点限制按当前画面计算，序列化上限在提交前验证，禁止提交会导致无法保存的画面。
- [x] 重跑该测试及`flutter test test/handwriting_test.dart test/math_state_test.dart`，全部通过。

## Task 2：草稿加载、串行保存与flush

**Interfaces:** 消费Task1及现有PreferenceStore。`DrawingDraftStore(PreferenceStore preferences)`；`Future<DrawingDocument?> load()`；`void submit(DrawingDocument document,int revision)`；`Future<void> flush()`失败抛错误；`Future<void> retry()`重试最新快照；`ValueListenable<DrawingSaveStatus> get status`，状态含saving/saved/failed与目标revision；`void dispose()`停止通知，不丢弃已接受写入。load与decode错误保留给页面处理，初始化不submit。

- [x] 写drawing_draft_store_test：无值/有效重载/坏JSON/未知版本/读失败；断言失败后原字符串不变。A写阻塞时submit B/C，只按A、C写；A完成不能将C报saved；C失败重试成功，失败后D替换旧待写，flush等最新修订。dispose后无通知异常。
- [x] 写隔离测试：同一内存PreferenceStore上原LearningStore课程记录保留；clearCache不删drawing_draft_v1；画板空白写回不删learning_state_v1。
- [x] 运行`flutter test test/drawing_draft_store_test.dart`确认失败。
- [x] 实现独立键、最新待写槽与串行worker；失败不可形成自动无限重试；flush等待其间接收到的最新快照稳定成功，出错明确返回调用者。只在加载完成后由页面监听revision提交；损坏初载不主动提交空白。
- [x] 重跑该文件及`flutter test test/learning_store_test.dart`，验证延迟/失败分支全部通过。

## Task 3：屏幕绘制与PNG

**Interfaces:** `void paintDrawing(Canvas canvas,Size size,DrawingDocument document,{DrawingStroke? activeStroke})`负责白底和clip；`DrawingPainter extends CustomPainter`调用它。`DrawingPngService.encode(DrawingDocument snapshot) -> Future<Uint8List>`固定1024×1024，异常不返回空数据。

- [x] 写drawing_png_test：用已有image解码，断言1024×1024、角落白底、已知点圆心颜色、4/10/20宽度覆盖范围、边缘裁切、已撤销颜色不存在；编码开始后改控制器不改变传入快照；屏幕绘画和离屏走同一函数。
- [x] 运行`flutter test test/drawing_png_test.dart`确认失败。
- [x] 实现公共绘画与PictureRecorder编码，释放Picture/Image资源；单点drawCircle，多点圆头圆角路径。编码前校验数据，只绘可见完成笔迹。
- [x] 重跑测试；保存至少一幅可查看的测试PNG到docs/artifacts/phase-3d/，实际查看颜色、线宽、纸边和空白背景，记录验证结果。

## Task 4：原生系统分享

**Interfaces:** `DrawingShareService.openPng(Uint8List png,{required Rect anchor}) -> Future<void>`；通道`baby_learn_house/drawing_share`、方法`sharePng`、参数`bytes`及`anchor:{x,y,width,height}`（Flutter视图逻辑坐标）；仅原生确认present/启动chooser后返回`{status:presented}`，其他结果转PlatformException。两端原生各有可注入文件目录/时间/呈现回调的handler，生产入口只调用handler，不接收路径或URL。

- [x] 写drawing_share_test，mock binary messenger断言参数/字节一致、空/超大/非PNG和非法锚点拒绝、平台错误透明传出。写原生handler测试：缺参/伪签名/不能解码的PNG/超过12MiB被拒绝；安全唯一文件名，旧文件仅限本目录且>24h清理，当前新文件保留；无presenter返回明确错误。
- [x] 先运行Dart及原生定向测试确认失败；原生命令按项目现有Gradle/Xcode scheme确认后写入ledger，不能以Dart mock代替原生验证。
- [x] 实现Android handler：验证完整PNG可解码及1024边长，专属cache/drawing_exports，ACTION_SEND image/png + chooser + ClipData +临时读授权；FileProvider authority `${applicationId}.drawing_share`，exported=false、grantUriPermissions=true，XML只映射该子目录。核实现有androidx.core可用，不引入额外分享依赖。
- [x] 检查本机Flutter头文件确认隐式引擎registrar/messenger API，再实现Swift handler并由didInitializeImplicitFlutterEngine注册；持有通道/handler生命周期，定位所属前台Scene的Flutter presenter，busy保护；PNG解码、尺寸、目录清理同Android。iPad锚点转换并裁切到presenter bounds，无效位置采用可见区域安全锚点，UI操作回主线程。
- [x] 跑Dart与原生定向测试通过，构建Android debug与iOS simulator确认插件注册/文件引用。静态核对Manifest无新增存储/相册权限，FileProvider仅专属路径。没有原生测试设施时先建立并运行，不能静默跳过。

## Task 5：页面、生命周期与分类接入

**Interfaces:** `DrawingView({super.key,DrawingDraftStore? draftStore,DrawingShareService? shareService,DrawingPngService? pngService})`支持测试注入，生产使用独立DevicePreferences；自身拥有DrawingController并dispose。读取成功或明确用户编辑后才提交；保存订阅按revision去重。`categoryRoute`对drawing返回/drawing；旧/learn/drawing与误入/math/drawing统一重定向/drawing，未知分类保持原guard行为。

- [x] 写drawing_ui_test：加载阻塞禁止输入、晚到读取不覆盖编辑、坏草稿重试；六色三档语义/48触控；清空确认及取消、清空undo；空白导出禁用，连续点击仅一次分享；导出期间编辑不改快照，页面退出后异步完成无导航/通知异常。
- [x] 写生命周期测试：后台cancel活动笔并提交完成画面；布局尺寸变化取消；返回等待flush、失败出现留页重试/仍离开且文案不假称成功；重入仅恢复画面与设置，旧历史为空。
- [x] 写320px/200%及平板测试：工具换行、无溢出；从画布内drag画线且页面offset不变，画布外drag能滚动；第二指不会拼线。写drawing_resource_test及既有路由/音频回归：drawing无课程item、学习计数不变、旧音频进入时停止。
- [x] 运行新增UI/resource及相关旧测试确认失败；实现页面Listener/手势竞争、状态提示、保存重试、PopScope返回与mounted/代次守卫。订阅、WidgetsBindingObserver与controller生命周期完整释放。
- [x] 更新ActivityKind、分类生成器、Dart/Python校验与所有穷尽switch；生成器只开放drawing、不改变261项正文/revision。主入口注册所需服务，不增加启动期绘图加载。重跑本任务及内容/数学/音频旧测试通过。

## Task 6：完整验证、设备验收与交付

**Interfaces:** 沿用现有生成器与联合审计命令；最终状态文档记录实际结果、测试数、产物与未补验项。

- [x] 运行`dart format lib test tool`、`flutter analyze`、`flutter test`、`python3 -m unittest discover -s tool/tests`、`python3 tool/expand_phase2_content.py --check`、`dart run tool/validate_content.dart`；记录实际退出码和计数。核对261项/28入口、190demo/131缺录音以及旧readings哈希`bbd1fe07b42f4e41677eae0c04215fd789a1fe49d4dc3f2b5564f6d38105dcaa`。
- [x] 构建`flutter build apk --debug`、`flutter build ios --simulator`，运行Task4原生测试；记录具体命令和警告，不能沿用上阶段成功结果。
- [x] iOS模拟器实际画线/单点/换色粗细、撤销重做、清空后撤销；后台与重启恢复草稿，旧学习进度保留；实际打开PNG系统分享面板再取消，查看产物。iPad可用则验证popover；不可用如实留缺口，测试和构建单列。
- [x] Android有设备时同样打开分享面板并取消；无设备仅报告构建通过，保留Android分享与旧PDF设备补验、教学听审缺口。原生手势若无法驱动不得以截图或widget测试冒充实际画线验收。
- [x] 按已选Native方式做唯一一次独立全变更审查；重要问题补回归后修复，重跑受影响及完整验证。仅此审查允许分派，产品实施不分派agent。
- [x] 更新README、资源来源、路线图、3D状态与ledger，附示例PNG/截图及真实设备覆盖；声明28入口开放不代表原站全部视觉内容复刻。只勾选有本轮证据的项目，不操作父级Git。

## 自查与交接

设计覆盖：输入/边界/历史→Task1；持久化/隔离/并发→Task2；共同画法/PNG快照→Task3；双端分享/文件权限→Task4；交互/路由/生命周期→Task5；资源守恒/设备/交付→Task6。Review Focus五项均有对应测试落点；接口统一使用DrawingDocument不可变快照及revision，不把活动笔写入草稿或导出。

已按Native实施并完成一次独立审查，三项发现补回归修复；Flutter131项、Python15项、原生Android2/iOS3项通过，双端构建及iPhone模拟器主流程/重启/分享取消完成。Android实际分享、iPad及旧设备/教学验收限制如实保留于3D交付记录。
