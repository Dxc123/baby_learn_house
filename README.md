# 宝宝学识屋

Flutter + GetX 离线学习样例版，参考 [宝宝学识屋网页版](https://learn.fxss.work/) 的页面结构。

当前为3D离线学习版：合计261项、28个开放入口。画板支持六色三档画笔、撤销重做、确认清空、本机单幅草稿恢复和1024×1024白底PNG系统分享。绘本、情景对话、数字、文学阅读、笔顺、描红和A4字帖保留；画板不计分，未完成笔迹不保存，重启后操作历史重新开始。28入口开放不代表原站内容与视觉全部复刻完成。

4A已完成首页视觉收敛：逐字注音页头、横幅自绘卡片、细虚线边框、白底四栏及栏目滚动位置恢复。课程规模不变，详见 [4A交付记录](docs/phase-4a-status.md)。

## 启动

开发环境：Flutter 3.41.6 / Dart 3.11.4。首发目标 Android / iOS。

```sh
flutter pub get
flutter devices
flutter run -d <设备ID>
```

## 验证

```sh
flutter analyze
flutter test
dart run tool/validate_content.dart
python3 tool/expand_phase2_content.py --check
python3 -m unittest discover -s tool/tests
flutter build ios --simulator --debug --no-codesign
flutter build apk --debug
```

## 内容与发音

目录在assets/data/content.json，21篇文学正文在assets/data/readings.json，9篇图文正文在assets/data/stories.json，学习记录使用稳定ID。原190段合成demo随包；原122项加上9项图文目录内容，共131项暂缺录音。图文首批不提供录音；阅读demo未经专业教学听审，App不依赖原站或在线TTS。来源见assets/RESOURCE_SOURCES.md、assets/READING_SOURCES.md与assets/STORY_SOURCES.md。

首页封面为项目内绘制的几何插画，未复制原站图片。汉字课程与词组为自编资料，不对应某版完整教材；描红不评分、不自动标记学会。笔顺使用固定版本 Hanzi Writer Data，PDF 嵌入 LXGW WenKai 字体，原始许可随包并可在设置中查看。

生成课程：`python3 tool/expand_phase2_content.py`，生产源位于 tool/content_sources。笔顺与字体已随包，运行 App 不需要下载；维护资源时才使用 tool/import_hanzi_strokes.py、tool/fetch_font.py。字体原文件约 25 MB，未全局替换 UI 字体；PDF 使用子集嵌入。

可打印示例：[六字字帖](docs/artifacts/worksheet-six.pdf) / [60 字四行版](docs/artifacts/worksheet-sixty.pdf)。生成同源产物：`flutter test --dart-define=WRITE_WORKSHEETS=true test/worksheet_export_test.dart`。

阅读正文和目录由同一规范源生成并带共同 revision，生成失败恢复旧文件，`--check` 不写入。修改正文/注音后需重新生成或复核对应 demo：`python3 tool/generate_reading_audio.py`，再运行课程生成器与审计。录音生成仅开发机使用 macOS say/afconvert；运行 App 不需要开发脚本。

图文规范源为tool/content_sources/stories.json，三份JSON带各自正文revision，生成失败回滚旧输出。图文与场景均为项目自编；场景预览由生产绘制入口导出，位于docs/artifacts/phase-3c-scenes/。

完整调研见docs/replica-proposal.md，当前交付与验收边界见docs/phase-3c-status.md。此前记录见docs/phase-3b-status.md、docs/phase-3a-status.md及第二阶段各批交付记录。
