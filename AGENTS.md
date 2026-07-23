# DioHub Agent 入口约束

本文件是强制入口。详细规则以
[`docs/development-constraints.md`](docs/development-constraints.md) 为准，不在此重复。

## 开始前

1. 完整阅读：
   - [`docs/development-constraints.md`](docs/development-constraints.md)
   - [`docs/technical-debt-register.md`](docs/technical-debt-register.md)
   - [`docs/workbench-progress.md`](docs/workbench-progress.md)
   - 实际任务涉及的架构、重构计划和模块说明；当前技术栈评估见
     [`docs/technology-simplification.md`](docs/technology-simplification.md)。
2. 执行 `git status --short --branch`，确认分支、工作区和用户已有修改；不得覆盖或顺手格式化无关文件。
3. 先追踪正式入口、数据源、Provider/Controller、缓存、路由和现有测试，再决定是否需要新增抽象。
4. 开始修改前声明：本轮目标、非目标、正式数据源、用户可见验收条件、预计文件、既有行为影响、
   停止条件和验证命令。

## 实施中

5. 复用现有 API、GraphQL、认证、数据库、模型、状态管理、缓存和分页基础；不得为单页创建第二套业务层。
6. 发现旧架构冲突但不属于本轮范围时，按证据登记到
   [`docs/technical-debt-register.md`](docs/technical-debt-register.md)，不得擅自扩大重构。
7. “基础设施完成”不等于“页面完成”。不得使用演示数据、占位页面或叶组件测试冒充真实入口已经完成。
8. 保持 Home、Repository 和后续页面使用统一 App Chrome；页面专属导航不能复制成第二套全局导航。
9. 视觉验收至少提供 360px、800px、1440px 的测试、截图或等价证据，并按范围验证文字缩放；共享实现
   不得破坏未在本机运行的 Windows/macOS 平台。
10. 流畅度结论只能由 Profile/Release 同环境对比支持；没有测量时明确写“尚未建立基线”。
11. 低内存环境中串行运行 Flutter、Gradle、CMake 和测试任务，不并发启动重型构建。

## 复现与完成判定

12. 状态、重复加载、缓存或生命周期问题开始前，必须明确列出并分别追踪：路由/页面、页面主 Tab、
    页内状态或筛选、查询会话、分页 Controller、Provider 与缓存。不得用笼统的“Tab 已保活”覆盖不同层级。
13. 将用户复现步骤写成可证伪的操作序列，并优先建立失败回归。测试必须覆盖关键副作用，例如请求次数、
    Provider 写入、Controller 身份、骨架是否重现和滚动/分页是否恢复；空列表或静态截图不能单独证明状态保留。
14. “不会重新加载”“不会重复请求”“返回时保留状态”等负向结论，必须同时证明目标结果存在和被禁止的
    事件没有发生。首次加载、显式刷新、缓存命中和 LRU 淘汰必须分别定义，不得混写为同一种 loading。
15. 业务默认状态由 Provider/Notifier/Controller 构造；不得在 `build`、`initState`、`dispose`、
    `didUpdateWidget` 或 `didChangeDependencies` 中写共享 Provider。不得只用 post-frame 延迟掩盖职责错误；
    用户事件回调中的显式状态修改不受此限制。
16. 用户反馈与既有“已完成”结论冲突时，原结论自动降级为“待复核”：从当前生产入口、当前代码和当前日志
    重新证明，不得引用旧测试或进度文档反推问题不存在。长上下文中的历史结论只视为线索，不视为证据。
17. 完成状态必须绑定“精确层级 + 精确入口 + 精确操作序列 + 精确断言”。只完成外壳、Provider、动画、
    占位或叶组件时必须写“部分完成”或“仅有基础”，不得扩大成整个页面或交互已完成。

## 结束时

18. 按约束运行适用的 format、analyze、test、build、响应式、可访问性和性能检查；未运行项说明原因与影响。
19. 更新受影响的进度/架构文档，并提供“需求—实现—验证”映射，区分已满足、仅有基础、已登记和待验证。
20. 未经用户明确要求，不 commit、不 push、不创建 PR。
21. 不使用 `git reset --hard`、`git clean`、破坏性 checkout 或其他会覆盖用户工作的命令。
