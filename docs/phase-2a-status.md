# 2A 执行记录与交付

日期：2026-10-19。该批次扩充课程内容，未包含 2B 笔顺/字帖与 2C 阅读器。

## 课程范围

| 类型 | 数量 | 状态 |
|---|---:|---|
| 拼音 | 63 | 23 声母、24 韵母、16 整体认读音节，按组学习 |
| 英文字母 | 26 | Aa–Zz，字母名称示范与常见例词 |
| 认知 | 60 | 家庭、身体、运动、职业、颜色、形状、动物、植物、食物、交通工具，各 6 项 |
| 汉字 | 6 | 保留原批次，不宣称已经扩充汉字课程 |

合计 155 项，开放 13 个入口。原有 16 项 ID 与 learning_state_v1 存储格式保持不变。

## 行为与兼容性

- 中文按字注音；拼音、英语按完整单位显示，zh/ang/zhi/Aa 不拆散。
- 拼音分组、关键词和已学筛选可组合，详情下一项保持当前分组；标记学会不会导致下一项跳过内容。
- 搜索支持大小写、声调、ɑ/a、ü/u:/v 的归一；显示文本不被搜索归一结果替换。
- 分组外或已失效游标回退本组首个未学项，全部已学则回到本组首项。
- 保留原有写入失败反馈、离线浏览和进度恢复；显式 sortKey 保证不依赖 JSON 条目排列的偶然顺序。
- 缺失图片显示明确回退，图形语义标签独立可读；颜色和形状有原生绘制示意，白色图块有边框。

## 资源状态

98 段音频是随包合成示范，不是经专业校对的标准教学录音。57 项新增拼音无录音，界面显示“暂缺录音”，仍可阅读和标记已学。没有标为 verified 的音频。

认知图形使用原生 Canvas 图形和系统 Unicode 图形字形，结合文字说明表达概念，不是原站插画或照片。家庭人物须结合亲属说明理解，不能仅凭图形判断亲属关系。完整来源说明见 assets/RESOURCE_SOURCES.md；音频逐项记录见 assets/audio/manifest.json。

## 验证

- flutter analyze --no-pub：无问题。
- flutter test --no-pub --reporter expanded：33 项全部通过。
- dart run tool/validate_content.dart：155 项、98 段有效 PCM 音频、57 项明确缺音，校验通过。
- flutter build apk --debug --no-pub：通过。产物：[Android 调试包](/Users/liyaping/Desktop/baby_learn_house/build/app/outputs/flutter-apk/app-debug.apk)。未安装 Android 私人真机。
- flutter build ios --simulator --debug --no-codesign --no-pub：通过，产物 build/ios/iphonesimulator/Runner.app。
- iPhone 17 Pro / iOS 26.3 模拟器已运行升级版本：首页保留原来的 1 个已学条目，总数变为 155；三个拼音分组分别显示 23/24/16 项，韵母页仍显示原 ɑ 已学会；zhi 完整排版并提示暂缺录音；英语搜索 z 得到 Zz，26/26 末项返回列表；播放结束控件恢复；白色与圆形页有独立图形语义标签。验收后应用留在首页。
- 320px/200% 字号、平板、缺图像回退、分组末项、失效游标、旧记录恢复、无录音导航停音均有自动测试覆盖；未宣称逐一人工听审所有内容。
- 独立只读审查发现一项 P2：PCM 审核未检查声道/采样率/帧完整性，且误认 8-bit 静音。已补充失败回归，验证格式字段、RIFF 长度、字节率、blockAlign 和完整帧，并区分 8-bit/有符号 PCM 的静音。修复后全套 33/33，通过全部 98 个随包音频审核。无遗留的重要审查问题。
- 模拟器运行命令仍出现 `Target native_assets required define SdkRoot but it was not provided` 环境日志，但命令退出 0 且应用正常运行；未将开发环境描述为完全无警告。

## 本次决定与边界

- 在原有 v1 内容格式上兼容添加字段，未新建存储版本，避免无必要迁移。
- 未开放分类的 kind 可为空；旧 pinyin/chinese/animals 可推导类型，新开放分类必须显式声明。这样既能读旧清单，又不把尚未实现的阅读/数字模块假装为汉字课程。
- 图形使用本地代码和系统字形，不额外引入位图生成、远端图片或字体包；imageAsset 为后续授权插图保留，并具备加载失败提示。
- 普通词语和字母使用合成示范，新增拼音录音保持缺失状态；不为凑齐“可播放”数量使用近似音。
- 工程继承了主目录 Git 仓库，本次仅修改工程文件，未创建分支、提交或操作工程外仓库。
- 当前还需人工听审、插图教学审核，以及正式发布前的资源使用条件核对。音频帧校验不能证明发音标准。

## 使用

```sh
flutter pub get
flutter run -d <设备ID>
```

内容构建源：tool/expand_phase2_content.py；词语/字母示范音频生成：tool/generate_phase2_audio.py（macOS 系统语音服务）。复现内容清单不会清除学习记录。

后续仍按第二阶段路线推进：2B 基础汉字、笔顺与字帖，2C 古诗/成语/三字经阅读器。

## 模拟器截图

![升级首页与旧进度](/Users/liyaping/Desktop/baby_learn_house/docs/screenshots/phase-2a-home.png)

![完整音节与缺音提示](/Users/liyaping/Desktop/baby_learn_house/docs/screenshots/phase-2a-pinyin.png)

![英文字母 Zz](/Users/liyaping/Desktop/baby_learn_house/docs/screenshots/phase-2a-alphabet.png)

![白色图块与语义说明](/Users/liyaping/Desktop/baby_learn_house/docs/screenshots/phase-2a-color.png)

![原生绘制圆形](/Users/liyaping/Desktop/baby_learn_house/docs/screenshots/phase-2a-shape.png)

![韵母分组与旧学习记录](/Users/liyaping/Desktop/baby_learn_house/docs/screenshots/phase-2a-finals.png)
