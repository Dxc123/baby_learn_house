# 学习内容扩充 2A Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. 本批次已执行，勾选项为完成记录；验证与边界见 docs/phase-2a-status.md。

**Goal:** 保留第一阶段进度，完成 63 项拼音、26 项英文字母和 10 类各 6 项认知内容的学习页面。

**Architecture:** 保留 GetX、现有路由与音频服务。内容由统一清单索引不同类型，中文注音和字母/音节使用不同排版；向现有 v1 JSON 添加可选字段并保持旧数据可读。学习状态继续使用原稳定 ID，不做无必要的数据迁移。

**Tech Stack:** Flutter 3.41.6 / Dart 3.11.4；沿用现有 GetX、shared_preferences、audioplayers，具体解析版本保持 pubspec.lock。

**Spec:** docs/replica-proposal.md；docs/phase-2-roadmap.md 的 2A 范围。

## Global Constraints

- 默认 Android/iOS；关键离线资源随包；未实现入口仍明确标为筹备中。
- 沿用现有 GetX，不重新初始化项目。
- 保留原 16 个学习条目的 ID，以及 learning_state_v1 存储格式。
- 清缓存不删除进度；读写失败不阻断读取离线课程，也不伪装保存成功。
- 没有获授权、已校对的录音时显示资源状态，不把系统合成声称为标准教学录音。
- 仅修改当前工程，不操作继承自主目录的 Git 仓库，不进行 Git 提交。

## Review Focus

1. 原有已学 ID 和失效游标：内容扩充后保留已学，游标失效或不在所选分组时回退到该分组未学项，全部学会则回到该组首项。
2. 多字符音节与英语大小写：zh/ang/zhi/Aa 不应被当作汉字拆开；全局拼音开关不隐藏主体字母。
3. 缺失或损坏音频：明确提示、仍可阅读，切到下一项不继续播放旧音频。
4. 分组/搜索/筛选组合：空结果与末项正确，下一项遵循当前分组，不跳入其他分组。
5. 可用入口与资源审核：只有完成本批内容及资源校验的分类开放，示范音频与待校对资源始终可辨认。

## 文件职责与接口

修改 lib/app/data/learning_content.dart，新增 lib/app/data/content_types.dart、lib/app/core/learning_label.dart、tool/validate_content.dart；复用现有列表、详情、仓库、学习状态和音频服务。无需为每个认知分类复制一套 Controller。

新增类型：

- `enum ContentKind { pinyin, hanzi, alphabet, cognition }`
- `enum AudioQuality { unavailable, demo, verified }`
- `LearningGroup(String id, String title, int order)`，分类内 ID 唯一。
- `LearningItem` 新增 `groupId: String?`、`sortKey: String?`、`audioQuality: AudioQuality`、`imageAsset: String?`；`audio` 改为 `String?`。
- `LearningCategory` 新增 `kind: ContentKind`、`groups: List<LearningGroup>`。
- `ContentRepository.groupsFor(String categoryId) -> List<LearningGroup>`。
- `ContentRepository.filteredItems(String categoryId, {String? groupId, String query = '', String order = 'grade'}) -> List<LearningItem>`；已学筛选由视图使用 LearningStore.learned 处理。
- `LearningLabel(LearningItem item, {double fontSize = 24})`：汉字/认知调用现有 PinyinText；拼音/英语按完整单位显示。

旧字段保持含义：pinyin 仍按 text 的 Unicode 码点配对，标点对应空串，源数据使用预组合声调字符。拼音/英语不需要注音时可使用空列表，由 kind 决定校验规则；不为凑长度制造假注音。

## Task 1：兼容内容类型、分组与资源状态

**Files:** 修改 lib/app/data/learning_content.dart、assets/data/content.json；新建 lib/app/data/content_types.dart、lib/app/core/learning_label.dart、tool/validate_content.dart、test/content_upgrade_test.dart。

**Consumes:** 当前 ContentRepository.load(AssetBundle)、LearningStore.open(PreferenceStore)。
**Produces:** 上述类型和接口；旧 v1 内容可读，新增字段仍使用顶层 version=1。旧分类缺 kind 时只对已开放的 pinyin/chinese/animals 按现有含义推导，其余未开放分类允许缺省，开放前必须显式填写。

- [x] 写兼容测试：载入原 16 项 fixture，保留 hanzi-yi/pinyin-a/animal-cat；学习状态预写已学 hanzi-yi 后切换扩充内容，已学状态不变。
- [x] 写资源校验测试：未知 groupId、重复 ID、注音数量不匹配、路径含 ../、verified 但无文件均拒绝；audio=null 且 unavailable 可读。
- [x] 运行 `flutter test test/content_upgrade_test.dart`，确认新类型/新行为缺失导致失败。
- [x] 实现上述字段与校验，新增 `validateContent(Directory root) -> Future<List<String>>`；CLI `dart run tool/validate_content.dart` 校验内容、图像、实际音频帧和资源来源清单，任何错误退出非 0。该工具仅使用 Dart 标准库直接读取 JSON，不导入依赖 Flutter AssetBundle 的仓库，否则无法独立运行。缺录音作为质量提示，不与“文件缺失却声明可播放”混为一谈。
- [x] 运行对应测试和 `flutter test`；确认旧内容与新内容均可加载，旧进度无损。

## Task 2：完整拼音分组与独立音节排版

**Files:** 修改 assets/data/content.json、lib/app/modules/learning/learning_list_view.dart、lib/app/modules/learning/learning_detail_view.dart、lib/app/core/learning_label.dart；新增 test/pinyin_learning_test.dart、assets/audio/manifest.json。

**Consumes:** Task 1 的 kind、groups、filteredItems、LearningLabel。
**Produces:** 分组 IDs initials/finals/syllables，分别为 23/24/16 项；沿用已有 6 个单韵母 ID。声调教学、测验不属于本批次。

- [x] 写测试：三组数量 23/24/16；搜索 zhi 只匹配对应学习项；zh 与 zhi 均作为完整文本控件呈现；关闭拼音仍显示音节；分组筛选为空显示空态。
- [x] 运行 `flutter test test/pinyin_learning_test.dart`，确认失败。
- [x] 填写规范清单：声母 b p m f d t n l g k h j q x zh ch sh r z c s y w；韵母 ɑ o e i u ü ɑi ei ui ɑo ou iu ie üe er ɑn en in un ün ɑng eng ing ong；整体认读 zhi chi shi ri zi ci si yi wu yu ye yue yuan yin yun ying。搜索将显示用的 ɑ 与输入 a 归一，ü/ǖ/ǘ/ǚ/ǜ/u:/v 归一，声调去除后匹配，显示文本不被归一结果替换。
- [x] 移除列表里写死的 6 项文案，增加分组选择。详情路径用 group 查询参数保留上下文，下一项只在所选组内前进；已学/未学仅筛选列表，不因标记已学而导致下一项索引跳变。旧游标仍以分类保存，不新增状态键；继续学习时游标不在所选组则取该组首个未学项，整组已学则取首项；非法 group 参数回退全部。
- [x] 补充音频清单字段 asset/source/quality/reviewedBy；保留原 demo 标签，无合适录音的条目使用 unavailable 与“暂缺录音”，不得用同音汉字合成结果批量标 verified。
- [x] 运行测试、内容校验与全套测试；确认 63 项可离线浏览，已有资源可播放，缺录音状态可辨。教学录音齐全/标准化单列为正式发布门槛，不能仅凭本任务完成宣称通过。

## Task 3：英文字母学习

**Files:** 修改 assets/data/content.json、lib/app/core/learning_label.dart、现有学习列表/详情；新增 test/alphabet_learning_test.dart。

**Consumes:** Task 1 的 ContentKind.alphabet 和音频质量字段。
**Produces:** alphabet 分类开放，26 项 ID en-a 至 en-z。每项以 Aa/Bb 的完整单位显示，note 描述字母名称，example 放一个例词及中文意思；本批不增加自然拼读或口语评分。

- [x] 写测试：A–Z 顺序固定，共 26 项；输入 a/A 都找到 Aa；拼音开关不改变字母显示；Z 的下一步返回列表；标记学会后重建 store 仍保留 en-z。
- [x] 运行 `flutter test test/alphabet_learning_test.dart`，确认失败。
- [x] 填充 26 项，音频只播放字母名称。例词如 Apple 可以显示，但没有例词录音时不复用字母音频冒充例词发音。
- [x] 使用现有通用学习页完成列表与详情，类别提示改成数据驱动，避免沿用动物样例文案。
- [x] 运行对应测试、内容校验与全套测试。

## Task 4：十类认知扩充

**Files:** 修改 assets/data/content.json、lib/app/modules/learning/learning_detail_view.dart；新增 assets/images/cognition/、lib/app/modules/learning/cognition_visual.dart、test/cognition_learning_test.dart、assets/RESOURCE_SOURCES.md。

**Consumes:** Task 1 的 ContentKind.cognition、imageAsset、现有汉字注音与学习进度。
**Produces:** 10 类各 6 项，合计 60 项，旧动物 4 项不改 ID。下表为本批固定内容，解释与图像逐项对应。

| 分类 | 6 项 |
|---|---|
| family | 爸爸、妈妈、爷爷、奶奶、哥哥、姐姐 |
| body | 眼睛、耳朵、鼻子、嘴巴、手、脚 |
| sports | 跑步、游泳、跳绳、足球、篮球、乒乓球 |
| jobs | 医生、老师、警察、消防员、厨师、农民 |
| colors | 红色、黄色、蓝色、绿色、黑色、白色 |
| shapes | 圆形、正方形、三角形、长方形、椭圆形、五角星 |
| animals | 猫、狗、兔、鸟、鱼、牛 |
| plants | 树、草、荷花、向日葵、松树、竹子 |
| foods | 苹果、香蕉、米饭、面包、鸡蛋、牛奶 |
| vehicles | 自行车、汽车、公交车、火车、轮船、飞机 |

- [x] 写测试：每类 6 项；原动物 ID 保留；家庭多字名称注音正确配对；纯白色图块在白底上有边框；圆形/正方形等有独立语义标签；缺图像显示明确回退而不崩溃。
- [x] 运行 `flutter test test/cognition_learning_test.dart`，确认失败。
- [x] 使用自绘形状/颜色组件，其他分类配自制或获授权且概念准确的插图，逐项登记来源；图像由本地 asset 读取，不以在线链接作为离线资源。
- [x] 每项填一条简短、自编说明，按 quality 字段接入音频；外来资源缺许可或概念不匹配的分类不改 available=true。
- [x] 在资源和测试通过后逐类开放，并跑内容校验与全套测试。数据存在不等于图像/发音教学审核完成，未通过审核保留相应质量标识。

## Task 5：升级回归与交付

**Files:** 更新 test/learning_edges_test.dart、test/widget_test.dart、docs/implementation-status.md、README.md；新增 docs/screenshots/phase-2a-*.png。

**Consumes:** Tasks 1–4 完成的课程。**Produces:** 可运行的 2A 批次与真实验证记录。

- [x] 写回归测试：旧游标不存在时回退本分类未学；选定分组后末项返回列表；存储不可用仍能浏览；缺音频不播放上一条；320px/200% 字号下 zhi/ang/Aa 不拆行、按钮可滚动到达。
- [x] 对新增行为先确认失败，再实现必要修复；仅修改现有缺陷，不扩展到笔顺或阅读器。
- [x] 执行 `dart format lib test tool`、`dart run tool/validate_content.dart`、`flutter analyze`、`flutter test`，全部成功；记录测试总数，不沿用第一阶段的 18 项作为新结果。
- [x] 执行 `flutter build apk --debug` 与 `flutter build ios --simulator --debug --no-codesign`；模拟器检查三个拼音分组、英语末项、颜色形状、重启保留旧进度，保存截图。
- [x] 文档列出已开放 13 个入口、每类数量、音频/图像审核状态、缺失资源与下一批 2B 范围，不宣称已完成全站或全部第二阶段。

## 执行记录

Tasks 1–5 已完成。flutter analyze 无问题；flutter test 33/33；资源校验通过；Android debug 与 iOS 模拟器构建通过。独立审查发现的 PCM 头字段与静音校验不足已通过新增失败回归测试修复（RED→GREEN）。

Ruling: 原有 v1 内容兼容增加字段，不改变 learning_state_v1 和原 16 项 ID；未开放分类 kind 允许为空，新开放分类显式声明类型。

Ruling: 认知插图采用原生绘制与系统字形，资源说明集中记录，不新增无用途的位图目录。教学准确性仍需人工审核。

Ruling: 新增测试集中到 content_upgrade_test.dart、phase2_ui_test.dart 与 resource_validator_test.dart，复用已有测试支撑；未按模块复制多套测试脚手架。

Ruling: 新增拼音保持 57 项暂缺录音，不使用近似合成声冒充标准音。2B/2C 仍是后续批次，详见 docs/phase-2-roadmap.md。本次未采购资源、发布、接入账号后台或安装私人真机。
