# 3D 画板交付记录

日期：2026-10-21。已完成产品实现、一次独立审查及回归修复，以及iPhone模拟器主流程与重启恢复验收。

## 已实现

- 独立/drawing；28入口开放，261学习条目、课程ID/revision、190段demo和131项缺录音保持原样；旧/learn/drawing、/math/drawing兼容重定向。
- 六色、4/10/20参考像素画笔，圆点/圆角笔迹；单指、多指忽略、边缘限制、取消及12000点/256笔限制。描红保持原实现。
- 会话内撤销重做，可撤销清空；单幅drawing_draft_v1本机草稿，串行合并保存、失败重试、返回flush及后台取消活动笔。读取失败后仅选画笔不会覆盖原草稿。
- 1024×1024白底PNG，屏幕/离屏共用绘画，导出捕获不可变完成画面；仅系统分享面板，不自动发送。
- Android专属缓存FileProvider、iOS隐式引擎注册/Scene presenter与锚点；只收PNG和锚点，原生校验格式/尺寸/12MiB上限，独立目录清理24小时前PNG，不提前删当前文件。无新增运行时依赖或相册/存储权限。

## 验证证据

| 检查 | 本轮结果 |
|---|---|
| Flutter全量 | 131项通过；/tmp/3d-full-final.log |
| Python | 15项通过；/tmp/3d-python-final.log |
| 生成器 | --check通过：261项、21篇阅读、9篇图文、28入口 |
| 联合审计 | 课程/阅读/图文资源通过；/tmp/3d-audit-final.log |
| 静态分析 | No issues found；/tmp/3d-analyze-final.log |
| Android原生 | 2项JUnit测试通过，含share工作流错误/呈现回调、文件隔离；/tmp/3d-android-review-green.log |
| iOS原生 | 3项XCTest通过，含PNG校验/缓存/参数/无presenter/呈现失败/锚点；/tmp/3d-ios-review-green.log |
| Android构建 | debug APK通过；build/app/outputs/flutter-apk/app-debug.apk |
| iOS构建 | simulator通过；build/ios/iphonesimulator/Runner.app |

旧readings.json SHA256保持bbd1fe07b42f4e41677eae0c04215fd789a1fe49d4dc3f2b5564f6d38105dcaa。联合审计的基础内容行229不含结构化阅读条目，阅读联合行仍为261总数。

## 实际设备范围

iPhone17Pro/iOS26.3模拟器：实际拖动画出黑色中号斜线、红色粗线；撤销移除红线、重做恢复；清空有确认，确认后白纸且导出禁用，撤销恢复两条线。系统PNG分享面板实际显示8KB PNG缩略图，随后取消，未选择接收人或发送。画面状态显示已保存。

最终构建重新启动后，两条笔迹及红色粗笔设置恢复，撤销/重做按钮禁用符合历史重置设计；首页旧学习状态保持4/261。最终版本系统分享面板再打开并取消成功。截图：docs/screenshots/phase-3d-drawing.png、phase-3d-restored.png、phase-3d-share-final.png。

测试导出样例：docs/artifacts/phase-3d/sample.png。实际模拟器分享文件已复制为docs/artifacts/phase-3d/device-export.png（7774字节），实际查看为1024×1024白底、黑斜线及红粗线，无页面控件。完整Flutter测试与分析日志另保存在同一产物目录。

Android无设备，不把原生单测/构建当作真实BitmapFactory/chooser/接收端延迟读取验收。当前无iPad设备，锚点逻辑有测试，实际popover待补验。200%字号、平板尺寸、多指/取消/后台/并发失败分支主要由自动测试覆盖，未全部在模拟器手动操作。旧Android/PDF设备补验和教学听审继续保留。

## 独立审查与裁定

唯一独立审查发现：读取失败后切画笔覆盖旧草稿、原生错误分支测试不足、第二指取消导致第一笔丢失。三项均补RED→GREEN测试修复；最后一项因实际数据损失从Minor升为Important处理，无延后小项。完整结果与裁定见phase-3d-ledger.md。

当前目录继承主目录Git，按已确认设计保留当前工作目录，不提交/推送/操作父级worktree；原生测试复用现有RunnerTests.swift，JUnit仅为测试依赖。28入口开放不代表原站内容规模与视觉全部复刻。
