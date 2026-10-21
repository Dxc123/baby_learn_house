# 首页文学封面更新

2026-10-21。用户确认三张统一国风童趣插画设计后，已生成并接入首页。

| 首页入口 | 图片 | 主题 |
|---|---|---|
| 成语故事（idioms） | assets/images/home/idioms-cover.webp | 三名儿童围读，书页展开山水、兔子与故事场景 |
| 学习古诗词（poetry） | assets/images/home/poetry-cover.webp | 小诗人、书卷、桃花、山水与明月 |
| 三字经（classics） | assets/images/home/classics-cover.webp | 两名儿童在书院共读，竹子和书卷作陪衬 |

图片由内置imagegen生成，原图1984×800，统一暖米白/桃红/青绿/浅蓝，无嵌入文字。生产使用WebP压缩副本（质量85），三张约706KiB；原始PNG保留在Codex generated_images，不随App重复打包。首页继续2.5:1居中裁切，标题与注音仍使用现有Flutter组件。

HomeCategoryCover只映射三个稳定分类ID，其他分类仍用原CategoryArt；资源失败回退到原图形。pubspec登记本机图片目录，完全离线加载；课程内容、学习状态、其他封面和依赖未改变。

## 验证

- 现有首页/导航定向7项通过；首页代码静态分析无问题。
- 正式测试集合`flutter test test/[a-z]*_test.dart`：134项通过。
- iOS模拟器成功构建并运行；实际查看三张封面，人物/书卷未被裁掉。成语入口正常进入课程列表，返回后封面位置保留，旧学习进度仍4/261。
- 手机截图：docs/screenshots/home-covers-idioms-poetry.png、home-cover-classics.png。平板布局由既有首页自适应测试覆盖，未另做iPad设备人工验收。

## 当前工作区全量检查的额外发现

后续进展：以下8项探测失败和2条警告已在4B定位并解决，完整套件现145/145通过。根因是测试等待、跨FakeAsync资源缓存和懒列表就绪标记，未修改生产加载逻辑。详见[4B交付记录](phase-4b-status.md)。下文保留封面交付当时的历史结果。

`flutter test`包含另外两个未由本次修改的临时探测文件，结果135项通过、8项失败，不能称全量通过。本次未修改、删除或忽略其结果：

- test/_probe_landscape_test.dart：portrait 390x844；narrow 320x568 scale2；landscape 844x390；landscape 844x390 scale2；ipad landscape 1194x834 scale2，五项均因部分阅读/图文/描红等路由未settle失败。
- test/_probe_async_test.dart：844.0x390.0 scale2.0；1194.0x834.0 scale2.0；320.0x568.0 scale2.0，三项因/practice/hanzi-yi加载指示仍存在而失败。
- 全项目静态分析还有_probe_landscape_test.dart的unused_import、undefined_shown_name两条警告；本次首页文件定向分析无问题。

这些探测结果未在本次封面更新中修复，也未据此认定根因；详细输出保存在docs/artifacts/home-covers/。不操作父级Git，不提交或推送。
