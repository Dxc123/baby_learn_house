# 4A 首页视觉对齐执行记录

2026-10-21 用户确认有界设计，直接实施；不另起架构设计/计划审批。

范围：HomeView及其专用组件，CategoryArt仅首页使用；不改课程、共享PinyinText、全局主题、存储或原生功能。不操作父级Git，保留已有修改。

原站截图：Chrome浏览器接口超时，原生Chrome窗口成功读取；390×844响应式视口与桌面截图已保存。确认逐字注音标题、横幅图、细虚线卡片、白底四栏。只复用布局特征，不复制原站插画和作者身份。

实现选择：首页用独立组件承接排版；保持手机单列/平板双列，卡片图2.5:1；欢迎与进度压缩但保留；底栏保留注音/主题响应与48px触控。每栏独立PageStorageKey保留滚动，普通返回保留当前栏。

验证：先写首页行为/布局失败测试，再实现；完整Flutter测试/分析/双端构建，截图核对。Android/iPad旧设备缺口继续保留。

RED：原首页未逐字注音，且切栏丢失滚动位置，home_presentation_test对应2项失败；320px/200%既有行为通过。实现后新增3项和widget原4项共7项通过。
实现：新增home_presentation.dart放品牌标记、进度、卡片虚线与底栏；CategoryArt新增可选aspectRatio且默认行为保留，不改其他学习页。首页卡片/底栏提供单一具名按钮语义并排除装饰图形朗读。
验证中：analyze无问题，Python15项通过，生成器check261/28通过，双端构建通过。全量Flutter133过/1失败，number_ui旧断言查完整Text；品牌已按确认设计逐字排版，改为同一完整无障碍label检查，不改变导航预期。

最终验证：Flutter134/134通过（/tmp/4a-tests-final.log），analyze无问题，Python15通过；生成器check/联合审计通过；Android debug和iOS simulator构建通过。以上133/1为已解决的中间状态。
原生验收：iPhone17Pro/iOS26.3四栏实际查看并保存phase-4a-home-0.png～home-3.png；原站reference-desktop/reference-mobile与before截图在同目录。旧进度4/261保持，首页进画板旧两线/红粗恢复，返回保留漫画栏，最终中英栏展示。
独立审查：phase4a_final_review只读一次，无Critical/Important。唯一Minor是本ledger未记最终结果，由交付步骤补齐；没有待修产品小项。大字/平板、语义现场朗读、惯性快速切栏、按压反馈的证据边界见phase-4a-status.md，不据源码推定已人工验收。
完成：未修改课程/资源/存储/原生文件，未操作父级Git或推送。无新增运行时依赖。
