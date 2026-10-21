# 2B 交付记录

日期：2026-10-20。基础汉字、离线笔顺、自由描红与 A4 字帖功能已实现；Android 原生 PDF 预览仍待设备验收，不宣称全站复刻完成。

## 已实现

- 汉字从 6 字扩充到 60 字，十组各六字，每字两个逐字注音词组。原有 155 项 ID 保留，总内容 209 项、开放入口 13 个。`learning_state_v1` 与排序存储值 `grade` 保持兼容，界面改称“按课程”。“长短”与“长大”分别注音。
- 60 字笔顺随包离线加载，灰色全轮廓、顺序高亮、笔画计数、播放/暂停/单步/重放及 0.5/1/2 倍速。后台和销毁取消计时器；资源加载失败可重试，认读不受影响。
- 自由描红使用归一坐标与第一指针所有权，支持撤销、清空、取消和切字清理。画板立即接管手势，竖向描笔不会滚动外层页面；草稿不持久化、不评分、不改变已学标记。
- 字帖按稳定 ID 选字，可选每字 1–4 行，A4 矢量田字格，每行 1 个示范、3 个浅色描红、5 个空格。完整字块不拆页；预览、系统分享及打印使用同一份 PDF 字节，取消不报保存成功。
- 设置页可查看原始笔顺/字体许可。资源清单包含固定版本、来源、散列，App 不使用笔顺 CDN 或在线字体。

## 资源与构建

- 笔顺：Hanzi Writer Data 提交 `68d10a4b21150cae5e1ebbd223eed289cf32d90c`，60 文件及 `ARPHICPL.TXT`。Y 变换为 `900-y`，屏幕和 PDF 使用相同相对内边距。
- 字体：LXGW WenKai Regular v1.530 原文件，25,928,940 bytes，Git blob `7f8f031dc5c6c5ba1913d93c36d4667c1e311cea`；SHA-256 与 OFL 许可散列见 assets/fonts/manifest.json。PDF 以子集嵌入，App 包内保留完整字体，增加约 25 MB 原始资源。
- 新依赖锁定：path_drawing 1.0.1、pdf 3.12.0、printing 5.14.3；当前 Dart 3.11.4 下 pin image 4.5.4，避免 image 4.11 对 archive 新 API 的兼容问题。
- `tool/content_sources` 为生产输入；`build_catalog` 返回前校验完整生成资料，写入采用原子替换，`--check` 不写文件。资源维护脚本仅开发时联网。

## 自动验证

| 项目 | 本轮结果 |
|---|---|
| `flutter analyze` | No issues found |
| `flutter test` | 最终 49 项通过；此前用 WRITE_WORKSHEETS 导出两份 PDF |
| `python3 -m unittest discover -s tool/tests` | 3 项通过 |
| `python3 tool/expand_phase2_content.py --check` | 209 项一致，无漂移 |
| `dart run tool/validate_content.dart` | 209 项、98 PCM 音频、111 项暂缺录音；字形/字体/许可散列通过 |
| PDF 字体 cmap 覆盖 | 标题、说明、60 字及词组拼音无缺字 |
| Android debug | APK 构建成功 |
| iOS simulator | Runner.app 构建成功并升级运行 |

新增测试覆盖旧 JSON 默认值、多音字词组、坐标正逆变换、指针生命周期、播放定时器、全部字形/中线笔数与散列、A4 分页、非法 ID/行数/缺字体、320px/200% 字号练习和选字、来源篡改及缺许可等。

收尾另补充“词组注音遵守全局拼音开关”的失败回归并修复；更新汉字列表底部文案以反映已开放能力。最终静态分析与 49 项测试均已重新执行。

独立代码审查发现三项问题：描红与滚动竞争、生成器接受非法课程资料、审计漏查缺字形关联。均先复现失败测试，再修复并通过回归。当前工程继承用户主目录 Git，本轮未对父仓库建分支、暂存或提交。

## PDF 和原生验收

- [六字默认字帖](/Users/liyaping/Desktop/baby_learn_house/docs/artifacts/worksheet-six.pdf)：2 页。
- [60 字四行字帖](/Users/liyaping/Desktop/baby_learn_house/docs/artifacts/worksheet-sixty.pdf)：30 页。
- 两份均由 App 的 `WorksheetPdfService` 生成，A4 595.276 × 841.89 pt。所有 32 页已渲染，核对字形方向、格线、分页、页脚与缺字；长、短、女、鸟、竹等在总览中可见，无倒置或裁切。标签可从 PDF 提取。
- iPhone 17 Pro / iOS 26.3：升级后仍为“已学会 1 / 209”；走通认读→口字第一笔→描红竖笔→撤销→选字→六字与 60 字最大 PDF 预览。最大版页脚显示 1 / 30；系统分享面板打开后取消，返回预览且按钮恢复，无误报保存成功。
- Android 只有构建验收：`flutter emulators` 仅列出 iOS，没有 Android AVD。本轮未安装私人真机，Android 原生预览和系统窗口仍待设备补验；未实际打印或向收件人发送文件。
- 构建日志包含 Java source/target 8 废弃警告；模拟器运行仍有 `native_assets ... SdkRoot` 提示，进程成功、页面和 PDF 已实际显示。未将其描述为无运行警告。

证据：

![升级进度](/Users/liyaping/Desktop/baby_learn_house/docs/screenshots/phase-2b-progress.png)
![口字第一笔](/Users/liyaping/Desktop/baby_learn_house/docs/screenshots/phase-2b-kou-step.png)
![自由描红](/Users/liyaping/Desktop/baby_learn_house/docs/screenshots/phase-2b-trace.png)
![最大字帖原生预览](/Users/liyaping/Desktop/baby_learn_house/docs/screenshots/phase-2b-pdf-max-preview.png)

PDF 全页总览位于 docs/screenshots/phase-2b-pdf-six.png、phase-2b-pdf-sixty-a.png、phase-2b-pdf-sixty-b.png。

## 保留的边界与下一步

98 段录音仍为未经教学听审的合成示范；57 项拼音与 54 个新增汉字共 111 项无录音。字形结构、散列及版式验证不等于专业教学审核，人工教学校对仍待完成。描红不做笔顺正确性判定，也不保存手写作品。

下一批次为 2C 共用阅读器、10 首古诗、10 则成语故事和三字经开篇 12 句，需另行细化内容与朗读队列方案。Android 原生预览可在设备可用后补验。
