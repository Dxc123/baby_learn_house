# 2A 内容与图形来源

## 3D 画板补充

画板为项目自行实现的Canvas笔迹，不引入第三方图画、图标包或新运行时依赖。用户画面只保存在本机drawing_draft_v1；导出使用同一绘制函数生成1024×1024白底PNG，通过系统面板由用户选择保存或分享。原课程资源、190段demo与131项缺录音保持不变。示例PNG见docs/artifacts/phase-3d/sample.png。

## 3C 图文补充

新增9篇自编图文、18页绘本、36轮情景对话及18幅项目自绘矢量场景，详见STORY_SOURCES.md。没有新增音频、第三方图片或运行时依赖；旧190段demo保持，目录暂缺录音由122项增加到131项。各阶段旧说明按历史保留。

## 3B 表格补充

百数表及加减乘除事实由本项目纯规则生成，乘除分组图示由Flutter代码绘制，无新第三方图像、音频或运行时依赖。学习条目仍252项，190段demo与122项缺录音状态不变。工具不产生新的学习条目或成绩。

## 3A 数字启蒙补充

新增 0～10 数字、中文名称和注音为项目自编基础课程，生成于 tool/number_catalog.py。数数和加减法数量对象均由 Flutter 代码绘制，不使用外部图片。新增 11 项明确暂缺录音，无新 TTS 资产；全项目仍为 190 段 demo，暂缺录音合计 122 项。以下早期阶段描述按阶段保留。

## 文字

assets/data/content.json 的课程文字、解释和词语清单为本项目编写，构建源为 tool/expand_phase2_content.py。
原 16 个条目 ID 保留。新增课程与词语均不是某版教材的完整授权课程。
识字仅保留原 6 字；拼音 63 项、英文 26 项、认知十类共 60 项。

## 概念图形

颜色、形状、跳绳、草、竹子由 lib/app/modules/learning/cognition_visual.dart 使用 Canvas 绘制，无外部图像文件。
其余认知条目的 symbol 字段使用系统提供的 Unicode 表情字形，逐项映射可在内容 JSON 和构建脚本查看。
家庭人物通过人物图形与亲属文字说明共同表达关系；表情本身不代表亲属关系判断。
这些是概念示意，不是原站图片，也不是照片。不同操作系统的字形外观可能不同。
不随包复制系统表情字体，不依赖远端图片。imageAsset 保留给后续获授权插图，缺图时明确显示错误。

## 录音

assets/audio/manifest.json 逐条记录 asset、source、quality、reviewedBy。
98 个 WAV 是 macOS 系统语音合成的开发示范；中文为 Tingting，英文字母名称为 Samantha。
57 项新增拼音无录音，audio=null、audioQuality=unavailable；不以同音汉字 TTS 冒充声母或整体认读发音。
所有合成音频均标 demo，尚未经过专业教学听审；verified 需有真实审核人记录。
正式发布前应核对合成语音分发条件，替换为获授权且逐条校对的教学录音。

## 本地资源校验

执行 dart run tool/validate_content.dart 可核验结构、唯一 ID、分组、资源路径、WAV PCM 数据及来源清单。
该校验不能判断插图教学准确性或发音是否标准；这些内容仍需人工审核。
# 2B offline writing resources

- Stroke files: Hanzi Writer Data, pinned revision `68d10a4b21150cae5e1ebbd223eed289cf32d90c`. Per-file URLs and SHA-256 are in `strokes/manifest.json`. Data license: `licenses/ARPHICPL.TXT` (Arphic Public License). Source coordinates follow Make Me a Hanzi, Y transformed by `900-y`.
- PDF font: LXGW WenKai Regular v1.530, original unmodified static TTF. Download URL, Git blob and SHA-256 in `fonts/manifest.json`; OFL 1.1 in `licenses/LXGW-OFL.txt`. Used in PDFs only.
- 60-character course, explanations and annotated examples are authored in `tool/content_sources/hanzi.json`; they are not an official textbook syllabus. Structural validation is automated; qualified teaching review is pending.
- Added 54 Hanzi recordings remain unavailable. The 98 demo clips and 57 missing pinyin recordings from 2A are retained.

# 2C offline reading resources

- 21 passages / 92 lines: ancient poem/classic text with edition notes; story retellings and explanations authored for this project. See `assets/READING_SOURCES.md` and per-passage provenance in `assets/data/readings.json`.
- 92 reading clips are macOS Tingting synthesized development demos, not professionally reviewed teaching recordings. Original transcripts, pronunciation-draft hashes and WAV hashes are in `assets/audio/reading/manifest.json`. Existing 98 demo clips and 111 unavailable pinyin/Hanzi recordings are unchanged.
- `tool/author_readings.py` uses pypinyin 0.55.0 only as a developer draft helper, with explicit poetry readings and contextual overrides; it is not an App dependency. Committed canonical source can be corrected directly. Re-running the helper resets reading audio references; run `tool/generate_reading_audio.py` to validate/reuse or regenerate clips, then `tool/expand_phase2_content.py`.

