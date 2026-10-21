# 4B 加载稳定性与横屏验收

日期：2026-10-21。已完成原8项探测失败定位、测试修复、完整回归和一次独立只读审查。本轮只改测试及辅助文件，不将探测脚本问题表述为产品加载故障。

## 根因与处理

1. **真实异步与虚拟时间混用。** readings.json为71981字节，Flutter AssetBundle会对超过50KiB字符串使用真实isolate解码。旧探测先runAsync、后构建页面，真正启动加载之后只pump虚拟时间，不能可靠等待真实解码。新辅助函数先构建，再按实际内容出现条件让出真实事件循环；3秒截止仅用于失败保护，内容就绪立即继续，没有增加固定等待来掩盖失败。
2. **跨测试缓存Future。** rootBundle字符串缓存会保留前一个Widget测试FakeAsync zone中的Future，后续测试不能驱动旧zone。最小两轮笔顺加载实验第二轮失败，仅增加测试间缓存隔离后两轮通过；原大字号横屏配置独立运行也通过。新setUp统一清理测试缓存，生产缓存策略保持不变。
3. **把懒构建正文当加载标记。** 200%字号时许可页介绍占满首屏，后面的SelectableText尚未布局。诊断显示loading=0、介绍文本已出现，因此不是加载卡住。就绪判断改为已加载分支的介绍，并实际滚动验证许可正文可见。

旧脚本还修正了未调用的字号/像素比恢复方法、失败时未释放状态、吞掉返回异常与错误import。正式探测现在检查每个页面特定内容、当前路由、没有加载指示、返回/home及没有意外标记已学；不以泛用Scaffold或空白页面判断成功。

## 覆盖与结果

| 检查 | 最终结果 |
|---|---|
| Flutter完整套件 | **145/145通过**，无排除_probe文件；原134项+9项场景+2项缓存隔离 |
| 探测/缓存隔离定向 | 11/11通过，约8秒，替代原探测数分钟固定等待 |
| 静态分析 | **No issues found**，原2条警告已消除 |
| Python | 15/15通过 |
| 生成器--check | 261项、21篇阅读、9篇图文、28入口，通过 |
| 联合资源审计 | 内容、阅读、图文及旧资源通过 |
| 独立审查 | Critical/Important/Minor均无 |

17条路由覆盖目录、详情、阅读、图文、描红、数学、字帖入口、画板、设置和资源许可。尺寸包含390×844、320×568/200%、844×390/100%及200%、1194×834/200%；异步路由另有4组连续打开/返回验证。这里验证字帖入口，不代替原生PDF预览或分享设备验收。

文件：test/_probe_landscape_test.dart、test/_probe_async_test.dart、test/route_probe_support.dart、test/asset_zone_diagnostic_test.dart。未删除失败场景、跳过测试或修改生产页来适配错误探测。

## 实际模拟器验收

iPhone17Pro/iOS26.3：正常横屏进入古诗词并打开《咏鹅》，正文正常加载；通过Simulator系统菜单将Preferred Text Size增加5档，查看阅读、返回首页、设置和资源许可，内容可显示。随后降低相同5档，恢复正常竖屏。系统档位变化不等同于精确200%；精确TextScaler2.0由Widget矩阵验证。

截图：

- docs/screenshots/phase-4b-reading-landscape.png
- docs/screenshots/phase-4b-reading-landscape-large.png
- docs/screenshots/phase-4b-home-landscape-large.png
- docs/screenshots/phase-4b-license-landscape-large.png

三张文学封面保持，课程已学仍4/261，未标记学会、清空草稿或发送文件。Android/iPad实际设备、旧PDF/分享和教学听审缺口继续保留，不以本轮Widget矩阵替代。

## 资源与交付边界

content/readings/stories SHA256与前轮一致：d334b1b185c8b8bca2249f16c585d1d789f4d794bcdf6d3370e2120214953bda、bbd1fe07b42f4e41677eae0c04215fd789a1fe49d4dc3f2b5564f6d38105dcaa、538ac65ff8aa030170bf29c80980bea968b6b8d47b9b16cc23c730e93870cae0。没有修改生产Dart、课程、三张封面、依赖或原生配置。本轮测试改动无需重新打包相同生产版本，模拟器验收沿用已安装封面版本。

执行记录见phase-4b-ledger.md；完整日志见docs/artifacts/phase-4b/。保留当前工作目录，不操作父级Git，不提交或推送。独立审查未自行运行父任务的测试，本记录中的成功结论来自父任务实际完成的本轮命令。
