# 绘本与情景对话 3C Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans 在当前会话逐项实施，末尾一次独立审查。Steps use checkbox (`- [ ]`) syntax for tracking。

**Goal:** 开放3本六页绘本和6场六轮对话，支持自有场景、注音、陪练与整篇进度。

**Architecture:** 新增图文模型与按需StoryRepository，共用StoryView入口，分别渲染当前绘本页和完整对话列表。复用目录、AnnotatedReadingText、LearningStore与音频路由观察器；正文与场景映射从规范源生成，三份目录/正文输出共同验证与事务替换。

**Tech Stack:** 保留Flutter3.41.6/Dart3.11.4、GetX、本地资源；自绘矢量场景，不新增运行时依赖或位图生成流水线。

**Spec:** docs/superpowers/specs/2026-10-20-learning-phase-3c-design.md（用户已确认）。

## Global Constraints

- 原252个ID、21篇readings及readingRevision不变，新增9项，合计261项、27开放入口。drawing继续筹备。
- 固定3本×6页、6场×6轮、每场2角色，18场景与18页一一对应；按整篇标记，不扩充分母。
- 无新录音/TTS、语音识别、评分、上传、云同步或运行时依赖；原190段demo与122项缺录音保持，新增9项目录缺录音后共131项。
- learning_state_v1与旧进度保留；每次选择以setCursors原子写目录游标和story:<id>游标。
- 320px/200%字号、平板、48×48按钮；首批交付按钮翻页，不实现可选滑动手势，避免扩大交互范围。
- 当前工程继承主目录Git；不执行父级status/add/commit/branch或工作树脚本。证据与取舍写docs/phase-3c-ledger.md。

## Review Focus

1. 三输出中途替换失败、旧文件缺失、revision不一致：不留下半份内容，不使旧课程无法启动（Tasks1/2）。
2. 单篇损坏、失败缓存、重试及未知sceneId：只隔离坏篇，插图错误保留正文，不默默显示其他页（Tasks1/3/5）。
3. 快速翻页、保存失败和迟到结果：页码/正文/图一致，存储错误可继续阅读，旧结果不覆盖新选择或退出后的页面（Tasks4/5）。
4. 显式unit、失效cursor及跨篇相同序号：按稳定ID恢复，未知显式unit回首个并提示，整篇标记只影响目标ID（Tasks4/5）。
5. 200%字号、角色长台词、末轮未布局和定位回调：可读、可见，排队选择只定位最新，销毁前后不操作失效控制器（Tasks3/5）。

## 文件划分

- data/story_types.dart：纯模型、结构与交叉引用校验。
- data/story_repository.dart：按需加载、revision核对与成功缓存。
- tool/content_sources/stories.json：正文、注音、角色和18场景来源规范源。
- tool/story_catalog.py、tool/catalog_transaction.py：图文目录生成、通用多输出回滚。
- modules/story/story_scene_registry.dart、story_scene.dart：白名单和场景UI；story_scene_painter.dart与三个主题的场景绘制文件按职责拆分，避免18场景堆进单一巨型paint方法。
- modules/story/story_controller.dart：位置选择、原子保存、整篇标记与生命周期。
- modules/story/story_view.dart、picture_book_body.dart、dialogue_body.dart：异步入口、绘本页、对话列表。
- tool/validate_stories.dart：完整资源与场景引用审计，接入既有联合审计。

## Task 1：模型、按需仓库与旧模式兼容

**Files:** 新增lib/app/data/story_types.dart、story_repository.dart；修改content_types.dart、learning_content.dart；新增test/story_types_test.dart、story_repository_test.dart、story_fixtures.dart及test/fixtures/phase3b_ids.json。

**Interfaces:**
- `enum StoryKind { pictureBook, dialogue }`；ContentKind新增pictureBook/dialogue，仅允许books/dialog分类。LearningItem新增`String? storyId,coverSceneId`，ContentRepository新增`String? storyRevision`。
- `StoryDocument.fromJson(Map<String,dynamic>)`：id/categoryId/title/titlePinyin/intro/provenance/kind、`List<StoryUnit> units`、roles、parentTips、prompt。JSON绘本pages/对话turns在模型内统一成units；`StoryUnit`含id/text/pinyin与可选sceneId/roleId。`StoryRole`含id/name/avatarId；`StorySceneMetadata`含id/bookId/pageId/alt/version/source/quality。
- `validateStoryDocument(Map raw,Map catalog,List<Map<String,dynamic>> scenes)`只校验目标篇；`validateStoryData(Map body,Map catalog)`做全9篇覆盖，复用validateAnnotations的标点规则。
- `StoryRepository(AssetBundle bundle,ContentRepository content)`，`Future<StoryDocument> load(String storyId)`按目标篇加载，只有成功结果缓存。

- [x] 修改生成数据前记录252项ID fixture及旧readings.json SHA256到ledger。写失败模型测试：绘本6页、对话6轮/2角色，非法角色、缺页/轮、重复ID、跨篇unit、未知/重复scene、注音不齐、空提示和错分类被拒绝。
- [x] 写仓库失败测试：启动和旧目录不读stories正文；revision不一致拒绝；一个坏篇不影响另一好篇；失败修复bundle后可重试，成功后重复请求命中缓存；未知/重复storyId明确错误。
- [x] 运行`flutter test test/story_types_test.dart test/story_repository_test.dart`确认新增行为失败，再实现类型与校验。旧fixture无新字段继续加载；其他内容不得带storyId/coverSceneId，dialogue不得带绘本封面场景引用。
- [x] 整篇目录ID与storyId保持相同，校验必须一对一；单篇校验不强制其他8篇完整，否则违背坏篇隔离。provenance明确project-authored与reviewStatus=text-reviewed，不能表示录音听审。
- [x] 实现仓库，读取assets/data/stories.json时cache:false；核对version=1与storyRevision，找到唯一目标，再验证目标与该篇场景元数据。重跑Task1测试及原content_upgrade/reading_repository测试通过。

## Task 2：固定正文与三输出生成事务

**Files:** 新增tool/content_sources/stories.json、tool/story_catalog.py、tool/catalog_transaction.py、tool/tests/test_story_catalog.py、test/story_content_test.dart；修改tool/expand_phase2_content.py、reading_catalog.py、现有生成器测试；生成assets/data/stories.json与content.json；pubspec.yaml加入正文资产。

**Interfaces:** `build_story_catalog(root:Path,catalog:dict)->tuple[dict,dict]`返回新目录/正文，输入不变；`write_documents(root:Path,documents:dict[str,dict])->None`写入assets/data/<name>.json，name仅content/readings/stories。保留`build_catalog(root)->dict`和`write_catalog_pair(root,catalog,body)`既有接口，后者委托通用事务，避免破坏旧测试。

- [x] 写失败测试：确定性生成261项/27入口，原252ID与全部旧条目字段、readingRevision不变；storyRevision由排序规范JSON的SHA256产生，目录正文相同；--check不改文件字节和mtime。
- [x] 写事务失败测试：第2/第3次os.replace失败、stories原先不存在、临时写失败，均恢复全部原字节及原先缺失状态；无残留临时输出。只验证最终输出相同不够，必须注入每个中间失败点。
- [x] 运行`python3 -m unittest discover -s tool/tests -p 'test_story_catalog.py'`确认失败，再实现通用事务及图文生成。旧目录先完成readings/数字生成，再加入图文；main组装并共同验证3输出后调用write_documents。--check比较3份输出，任何漂移退出非零且不写入。
- [x] 按已确认设计写3本6页骨架，ID为book-share-toys/book-tidy-up/book-feelings；页ID为<bookId>-page-01..06。每页正文12～32汉字、不计标点，1～2句；末尾prompt必填。注音显式存储并校对多音字/轻声，不复制原站现代文字。
- [x] 写6场6轮对话，ID按设计greeting/thanks/borrowing/help/taking-turns/feelings；轮ID<dialogId>-turn-01..06，角色各2个、avatarId为静态白名单。每轮8～28汉字、不计标点；intro、两条parentTips、prompt完整。
- [x] 写18场景元数据：sceneId采用share-01..06、tidy-01..06、feelings-01..06；一一绑定书和页，alt描述动作；source='project-authored vector scene'、quality='illustration'、version=1。封面引用该书第一页sceneId。
- [x] 数字/旧阅读不变，新9条目录audio=null/unavailable，文本与注音对齐。旧临时根生成测试补齐规范源文件而非跳过图文校验。运行生成器、--check、Python全套及`flutter test test/story_resource_test.dart test/story_types_test.dart`，全通过（内容验证合并到资源及模型测试）。

## Task 3：18幅原创矢量场景与预览

**Files:** 新增lib/app/modules/story/story_scene_registry.dart、story_scene.dart、story_scene_painter.dart、scenes/share_scenes.dart、tidy_scenes.dart、feelings_scenes.dart、test/story_scene_test.dart、test/story_scene_preview_test.dart；新增assets/STORY_SOURCES.md与docs/artifacts/phase-3c-scenes/。

**Interfaces:** `Set<String> get supportedStoryScenes`固定18项；`StoryScene({required String sceneId,required String alt})`使用AspectRatio(4/3)，未知场景显示“这页插图暂时无法显示”。共享逻辑画布640×480，theme只影响装饰色，不改变主体动作。绘制层输入sceneId而非任意JSON指令。

- [x] 写失败测试：源中18个sceneId与实现白名单精确相等；每幅绘制在320px/200%及平板无异常，有一个alt语义摘要，装饰图形不产生焦点；未知scene保留保底文字。运行`flutter test test/story_scene_test.dart`确认失败。
- [x] 实现可复用但有表达力的房间、玩具、轨道、人物、表情与手势元素；三个主题各6个动作组合，正文在场景组件外。人物衣服/肤色/玩具跨页连续，数量与自编正文匹配，不能18页仅换背景色。
- [x] 实现规范的共享绘制入口`void paintStoryScene(Canvas canvas,Size size,String sceneId)`，预览测试直接调用同一入口，避免另写预览画法。图形自动缩放，不裁切人物动作；unknown由UI保底且绘制入口抛ArgumentError。
- [x] 用Flutter测试导出真实渲染PNG：`flutter test --dart-define=WRITE_STORY_PREVIEWS=true test/story_scene_preview_test.dart`，输出18张640×480及3张六页联系图。测试默认不写文件，开启define才导出到docs/artifacts/phase-3c-scenes/。
- [x] 实际查看3张联系图及必要单页，按正文逐幅核对动作、人物、数量、角色连续性；有误改画后重导出。来源清单列18行scene/book/page/alt/版本与原创说明；不以白名单存在替代视觉核对。
- [x] 重跑Task3测试，通过后ledger记录视觉检查结果与局限，不声称写实插画或专业美术审定。

## Task 4：图文进度控制器

**Files:** 新增lib/app/modules/story/story_controller.dart、test/story_progress_test.dart。

**Interfaces:** `StoryController(StoryDocument document,LearningStore store,{required String itemId})`；公开`RxString currentUnitId`、`RxnString warning`、`RxBool saving`、`StoryUnit get currentUnit`、`Future<void> open({String? requestedUnitId})`、`Future<void> selectUnit(String id)`、`Future<void> markLearned()`，onClose使待完成操作失效。无播放器依赖。

- [x] 写失败测试：有效显式unit优先；显式无效回首个并提示，不使用已存unit；无显式时恢复有效已存unit，失效已存回首个。跨篇同序号不是有效ID。
- [x] 写保存测试：setCursors一次写入目录→整篇itemId及story:<id>→unitId；失败前台仍可读选中页、有警告可重试，失败不发布半份存储状态；快速选择A/B时晚到A不能覆盖B。
- [x] 写生命周期测试：选择待保存时关闭控制器，不发出销毁后UI更新/导航；无自动learned。markLearned仅改变整篇itemId，写失败未标记，重试/撤销/防重复提交正确，旧已学与设置保留。
- [x] 运行`flutter test test/story_progress_test.dart`确认失败，再实现选择代次和closed守卫。位置错误允许继续阅读；标记按钮仅成功持久化后由store发布状态，控制器不另造乐观已学集合。
- [x] 重开LearningStore验证末页/末轮、目录cursor与旧reader cursor仍存在；重跑Task4及原learning_store测试通过。

## Task 5：阅读页面、目录与路由

**Files:** 新增lib/app/modules/story/story_view.dart、picture_book_body.dart、dialogue_body.dart、test/story_ui_test.dart；修改lib/main.dart、routes/app_pages.dart、core/learning_label.dart、modules/learning/learning_list_view.dart。

**Interfaces:** `StoryView({required String storyId,String? unitId})`负责异步加载/重试与控制器生命周期；`PictureBookBody({required StoryDocument document,required StoryController controller})`、`DialogueBody(...)`分别消费同一模型。新增/story/:storyId?unit=<id>与`String storyRoute(LearningItem item)`；旧学习详情链接重定向。

- [x] 写失败UI测试：两目录可搜索、筛选与继续，绘本有第一页封面、dialogue角色摘要；9项统计正确。注册StoryRepository不增加启动Future，也不在build重复加载。
- [x] 写绘本测试：单个当前unit快照同时决定页码/正文/scene，首末翻页禁用；末页提示与prompt可见，不自动标记；快速点击最终三者一致；翻页后页滚动回顶部，默认首屏标题保留。无需滑动翻页。
- [x] 写对话测试：6轮全部构建、2角色姓名/头像可辨，选轮与前后按钮同步；末轮定位hitTestable，末尾家长提示和prompt可读。默认首轮不卷走标题，恢复非首轮才定位。
- [x] 写错误/生命周期测试：未知作品可返回，正文错误/revision不符可重试；坏scene保留正文/页码/导航；加载后退出不创建控制器。定位回调用buildScope同步更新真正排队后再绘帧，验证只定位最新轮及先退出不报错，不用settle后的移除冒充覆盖。
- [x] 运行`flutter test test/story_ui_test.dart`确认失败，再实现异步代次守卫。使用SingleChildScrollView+Column构建固定6轮，不引入未布局末轮问题；绘本每次只画当前页场景。
- [x] 接入AnnotatedReadingText及全局拼音，按钮至少48；图文加载错误、存储warning、缺录音说明清晰。不创建播放器，切入Story路由由现有AudioRouteObserver取消旧队列，新增对应测试。
- [x] 测试320px/200%与平板、主题/拼音切换、整篇标记/撤销、错误重试与保存失败。跑Task5及原reading_ui、number_ui、learning_edges测试通过，保持旧课程行为。

## Task 6：联合审计、完整验收与交付

**Files:** 新增tool/validate_stories.dart、test/story_resource_test.dart、docs/phase-3c-status.md、docs/phase-3c-ledger.md、docs/screenshots/phase-3c-*.png；修改tool/validate_content.dart、README.md、assets/RESOURCE_SOURCES.md、docs/phase-2-roadmap.md及受计数影响的既有测试。

**Interfaces:** `Future<List<String>> validateStoryResources(Directory root)`读取stories/content并做全部结构、revision、场景和来源覆盖审计；运行入口接入既有联合审计，不跳过旧字体/笔顺/WAV校验。

- [x] 写资源坏包测试：重复/孤立场景、未知sceneId、错封面、未实现场景、错误来源/revision、缺正文均审计失败。原无stories fixture仍兼容。运行`flutter test test/story_resource_test.dart`确认失败，再实现审计。
- [x] 运行`dart format lib test tool`、`flutter analyze`、`flutter test`、`python3 -m unittest discover -s tool/tests`、`python3 tool/expand_phase2_content.py --check`、`dart run tool/validate_content.dart`，逐项记录退出码和本轮实际测试数，不沿用3B的94项。
- [x] 构建`flutter build apk --debug`与`flutter build ios --simulator`，检查本轮完成输出。核对旧readings哈希、旧资源和252项数据未漂移。
- [x] iOS模拟器查看至少一本的6页动作、绘本末页、对话末轮、整篇标记和撤销；保存位置后重启恢复旧新进度；快速切换、拼音与大字显示按实际观察记录。保存模拟器截图，18幅预览另作为完整视觉证据。2026-10-21解锁后完成主流程，快速并发/200%字号仍以自动测试结果单列。
- [x] 按executing-plans做唯一一次独立全变更审查；重要问题补RED回归修复，重跑受影响及完整套件。不主动分派实现agent或逐任务审查。
- [x] 文档更新261项/27入口、9项新缺录音/总131项、18自有场景/36轮自编对话、实际视觉核对和设备范围；无Android设备时只报告构建，保留Android/PDF/教学听审缺口和构建警告。
- [x] 勾选有真实证据的计划项，未完成项明确保留，不操作父级Git。3D画板不随本阶段开放。

## 自查与交接

覆盖：模型/坏篇隔离→Task1；正文/三输出一致性→Task2；场景/预览→Task3；进度/并发→Task4；交互/布局/路由→Task5；审计/设备→Task6。Review Focus五项均有失败测试落点。绘本pages与对话turns统一为StoryDocument.units，但持久化始终使用原始unit.id；storyId与整篇目录ID相同，不引入第二套已学身份。

用户确认后已在当前会话实施。110项Flutter测试、15项Python测试、静态分析、联合审计和双平台构建通过；唯一独立审查的两项问题已RED/GREEN修复。18幅预览及三张联系图已导出查看。2026-10-21用户解锁后补完模拟器主流程，绘本末页与对话末轮重启恢复、旧新标记持久化已确认；验收边界见docs/phase-3c-status.md。
