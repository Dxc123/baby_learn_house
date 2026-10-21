# 4B 加载稳定性与横屏验收

2026-10-21 用户确认实施；保持三张新封面、261项/28入口及用户数据，不操作父级Git。

调查基线：_probe_landscape_test竖屏单独运行复现失败，/read/poetry-yong-e无法settle。该脚本在页面首帧构建前runAsync等待，之后只推进fake时间，阅读JSON 71981字节会由Flutter派发真实UTF8解码isolate，fake时间无法完成真实工作。待最小实验核实。

正在比较：_probe_async同一横屏配置单独运行与连续运行；rootBundle缓存Future跨Widget测试fake zone的影响。产品加载/错误/生命周期与测试问题分别取证，不以放大超时替代修复。

证据1：_probe_async中844×390/200%独立运行通过（原固定等待方式57秒），连续运行失败；最小asset_zone_diagnostic_test两轮缓存笔顺字符串，第二轮失败。仅setUp清理rootBundle缓存后2/2通过，证实跨FakeAsync zone缓存Future问题。
证据2：新探测先pump首帧再按真实内容就绪条件让出事件循环，读取JSON/笔顺全部恢复；初次用SelectableText判断许可页就绪，大字号4项失败。诊断显示loading=0、licenseIntro=1，正文已加载但SelectableText位于懒列表屏幕外，不是产品加载挂起。改为已加载分支介绍文本，并补滚动到许可正文验证。
修复范围：当前仅测试/测试辅助，不改生产加载逻辑。测试间缓存隔离、统一依赖注入、条件等待、每次返回检查、异常不吞掉、窗口/字号tearDown恢复；旧2条import警告一并修正。尚不宣称产品加载故障已修复，等待完整回归与设备实测。

首轮完整验证：11项探测/缓存隔离全部通过；不排除文件的flutter test145/145通过；flutter analyze无问题。后续加强每个同步路由的具体就绪标记，拒绝泛用Scaffold冒充成功，新增打开路径及返回/home断言，探测仍11/11通过，正在最终全量重跑。
实际设备：iPhone17Pro/iOS26.3正常横屏加载咏鹅；模拟器Increase Preferred Text Size提高5档后，阅读/返回首页/设置/资源许可均可显示。截图phase-4b-reading-landscape.png、phase-4b-reading-landscape-large.png、phase-4b-home-landscape-large.png、phase-4b-license-landscape-large.png。该系统字号不声明恰为200%，精确TextScaler2.0由Widget矩阵覆盖。验收后同量降低5档并恢复正常竖屏。
产品变更结论：当前未发现需要改动生产加载逻辑的证据，本轮修复测试等待/缓存隔离和就绪判断，不为让测试通过而增加产品延迟或超时。

最终完成：加强路由契约后，flutter test145/145（28秒）通过；flutter analyze无问题（4.3秒），Python15通过、生成器check和联合审计通过。完整结果已读，未跳过_probe文件。
唯一独立审查phase4b_final_review：Critical/Important/Minor均无；确认具体ready、路由/返回和spinner断言没有放宽加载标准。审查未代替本轮命令执行或物理设备覆盖，边界已记交付文档。
交付：phase-4b-status.md、四张横屏截图、RED/诊断/GREEN日志。没有生产代码修复、依赖修改、提交、推送或父级Git操作。已恢复模拟器原字号和正常竖屏。
