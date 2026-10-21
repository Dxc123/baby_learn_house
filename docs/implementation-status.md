# 第一阶段执行结果

这是历史交付记录；当前 2A 版本见 [最新交付记录](/Users/liyaping/Desktop/baby_learn_house/docs/phase-2a-status.md)。构建产物路径会被后续构建覆盖，不作为第一阶段归档包。

2026-10-19。当前交付是可运行的离线样例版，不是全站完成版本。

## 已实现

- 保留 GetX，接入四栏首页，呈现原站 28 个功能入口。
- 拼音单韵母 6 个、汉字 6 个、动物认知 4 个，合计 16 个可学习条目。
- 学习列表支持汉字/带调拼音搜索、全部/已学/未学筛选、继续学习。
- 学习详情支持离线发音、标记学会、撤销与下一项；末项返回列表。
- 设置支持全局拼音显隐、三种主题色、汉字按年级/笔画/拼音排序。
- 设置、已学条目和学习位置保存在设备上；写入串行提交，失败不显示为已保存。
- 清理下载缓存保留进度、设置和随包内容。
- 快速请求只播放最新音频，切页与进入后台停止播放。
- 原生应用显示名已改为“宝宝学识屋”。

## 验证记录

- flutter analyze --no-pub：无问题。
- flutter test --no-pub --reporter expanded：18 项全部通过。
- 测试覆盖：内容 ID 与资源映射、真实 PCM 音频帧、进度重建、并发写入、失败后继续写入、缓存隔离、损坏/不可读存储回退、播放竞态、后台停音、四栏导航、设置、已学筛选、空搜索、末项和撤销、320px/200% 字号、平板布局。
- flutter build ios --simulator --debug --no-codesign --no-pub：构建通过，产物 build/ios/iphonesimulator/Runner.app。
- iPhone 17 Pro / iOS 26.3 模拟器：已运行，进入拼音详情、调用发音、标记学会，再重新运行应用，首页仍显示已学会 1/16，确认真实设备存储适配正常。
- 发音控件调用未出现播放错误；音频文件已校验非零 PCM 数据。普通话教学准确度仍需人工听审，未将控件无错误等同于专业教学录音验收。
- 模拟器启动日志出现 `Target native_assets required define SdkRoot but it was not provided`，命令退出码为 0，应用正常运行；未宣称该开发环境日志完全无警告。
- flutter build apk --debug --no-pub：构建通过，产物 [Android 调试包](/Users/liyaping/Desktop/baby_learn_house/build/app/outputs/flutter-apk/app-debug.apk)。尚未执行 Android 真机运行验收。
- 未在连接的私人真机安装应用，未配置发布签名或上传商店。

## 审查与修复

独立只读审查发现两项影响离线体验的问题，均已增加失败回归测试后修复：存储读取异常不再阻断启动；保存学习位置失败不再阻断进入课程或下一项。保存失败仍会提示，未成功保存的标记不会伪装成成功。

## 本次采用的默认决策

- 先 Android/iOS、先离线学习，延续 GetX。若后续要求 Web，则追加浏览器行为验收。
- 当前目录没有独立 Git 仓库，Git 向上指向用户主目录。因此保留工程内文件修改，未建立分支、提交或操作主目录仓库。
- 原站插画未获取授权，首版使用项目内绘制的几何封面；视觉结构保留浅黄色顶部、奶油色背景、绿色强调、拼音注音和四栏导航。
- 使用可替换的合成示范 WAV 打通离线发音，正式上线前仍需审核音频分发条件并替换为专业教学录音。
- 阶段 0 的全部页面/内容/授权盘点随后续模块持续补齐，不将本次样例数据视为全量内容。

## 尚未实现

其他 25 个入口仅提供筹备中说明；声母/复韵母/整体认读音节、全量汉字、笔顺动画、书写测试、字帖导出、古诗/成语/三字经、数字运算、绘本/对话/画板和账号同步均属于后续阶段。

## 启动与产物

```sh
flutter pub get
flutter run -d <设备ID>
```

实际代码位于 lib/app，版本化内容位于 assets/data/content.json，音频生成脚本为 tool/generate_sample_audio.py（仅在 macOS 且可访问系统语音服务时运行）。包版本与解析结果已写入 pubspec.yaml / pubspec.lock。

依赖说明可核查 [shared_preferences 官方包文档](https://pub.dev/packages/shared_preferences) 与 [audioplayers 官方包文档](https://pub.dev/packages/audioplayers)。

## iOS 模拟器截图

首页截图为重新运行应用后保存，显示持久化的 1 个已学条目。

![首页](/Users/liyaping/Desktop/baby_learn_house/docs/screenshots/home-ios.png)

![拼音学习详情](/Users/liyaping/Desktop/baby_learn_house/docs/screenshots/pinyin-ios.png)

![设置](/Users/liyaping/Desktop/baby_learn_house/docs/screenshots/settings-ios.png)
