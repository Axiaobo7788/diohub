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

### 资源加载与特化执行

12. 远程读取型功能先判断是否属于普通 Runtime 资源；适合接入的功能遵循“正式领域 Service +
    Resource Recipe + 访问模式执行器 + `ResourceRuntime`”的单一链路。Runtime 统一身份、
    Single Flight、SWR、调度、生命周期、失效和预算，不会自动完成最小字段投影、游标、增量刷新、
    页窗口或扇出算法。详细边界见
    [`docs/resource-runtime-architecture.md`](docs/resource-runtime-architecture.md)。
13. 实现前先识别访问模式并优先复用已证明的执行路径。当前已落地直接 snapshot/source→artifact
    资源及 `RuntimeForwardPageSource`；Timeline、Tree、FanOut、Live 等名称在有实现和测试前只表示
    候选模式，不得当作现成能力。
14. 领域 Service 负责正式数据源、最小投影、游标和业务错误；Recipe 负责身份、标签、策略与 Loader；
    特化执行器负责该模式的分页、增量、预取、窗口算法及其 Lease 生命周期；简单资源也可由显式
    Riverpod binding/Notifier 持有 Lease。Widget 不得直接协调 Lease、generation、资源身份或请求调度。
15. 如果新页面必须修改 Runtime 核心、`PaginationController`，或让 Widget 直接协调请求，立即暂停
    页面实现并审查：现有执行器是否缺少通用能力、是否出现新的访问模式，以及新抽象是否至少有第二个
    潜在消费者。不得为单页创建专用加载框架。
16. TTL 必须有明确的新鲜度与一致性依据；页大小、预取距离、窗口和并发预算必须由
    Profile/Release 证据调优。Mutation、上传和其他主动写操作继续由正式 Service/Notifier 管理，
    成功后局部修补或精确失效相关只读资源。

## 复现与完成判定

17. 状态、重复加载、缓存或生命周期问题开始前，必须明确列出并分别追踪：路由/页面、页面主 Tab、
    页内状态或筛选、查询会话、分页 Controller、Provider 与缓存。不得用笼统的“Tab 已保活”覆盖不同层级。
18. 将用户复现步骤写成可证伪的操作序列，并优先建立失败回归。测试必须覆盖关键副作用，例如请求次数、
    Provider 写入、Controller 身份、骨架是否重现和滚动/分页是否恢复；空列表或静态截图不能单独证明状态保留。
19. “不会重新加载”“不会重复请求”“返回时保留状态”等负向结论，必须同时证明目标结果存在和被禁止的
    事件没有发生。首次加载、显式刷新、缓存命中和 LRU 淘汰必须分别定义，不得混写为同一种 loading。
20. 业务默认状态由 Provider/Notifier/Controller 构造；不得在 `build`、`initState`、`dispose`、
    `didUpdateWidget` 或 `didChangeDependencies` 中写共享 Provider。不得只用 post-frame 延迟掩盖职责错误；
    用户事件回调中的显式状态修改不受此限制。
21. 用户反馈与既有“已完成”结论冲突时，原结论自动降级为“待复核”：从当前生产入口、当前代码和当前日志
    重新证明，不得引用旧测试或进度文档反推问题不存在。长上下文中的历史结论只视为线索，不视为证据。
22. 完成状态必须绑定“精确层级 + 精确入口 + 精确操作序列 + 精确断言”。只完成外壳、Provider、动画、
    占位或叶组件时必须写“部分完成”或“仅有基础”，不得扩大成整个页面或交互已完成。

## 结束时

23. 按约束运行适用的 format、analyze、test、build、响应式、可访问性和性能检查；未运行项说明原因与影响。
24. 更新受影响的进度/架构文档，并提供“需求—实现—验证”映射，区分已满足、仅有基础、已登记和待验证。
25. 未经用户明确要求，不 commit、不 push、不创建 PR。
26. 不使用 `git reset --hard`、`git clean`、破坏性 checkout 或其他会覆盖用户工作的命令。

### 收尾闭环门禁

27. 声明完成、交接、暂存或提交前，必须从当前 worktree 重新执行范围审计：检查 tracked/
    untracked 文件、diff 规模、冲突、空白与生成文件成组性。不得使用最后一次代码修改之前的
    检查结果证明当前状态。详细门禁见
    [`docs/development-constraints.md` §7.6](docs/development-constraints.md#76-收尾闭环审计门禁)。
28. 新增或替换 Provider/Notifier/Controller、Timer/轮询、Stream 订阅、缓存/会话、mutation overlay 或
    生命周期观察者时，必须列出新旧 owner、全部生产调用点、并存条件、销毁/失效路径与负向断言。
    旧 owner 必须删除、显式委托或经过可证伪的互斥协调，不得无协调并存。
29. 异步功能必须按适用边界验证“在途结果晚返回”：dispose、unregister/update、路由/Tab 隐藏、
    app lifecycle、查询更换及账号/scope 切换后的晚成功与晚失败。必须断言禁止过期状态写入、事件/反馈投递、
    重排请求和缓存污染。
30. 测试进程退出码为 0 只是必要条件。必须审阅完整日志；未被测试名称、断言或注入的 observer/logger 明确归属的
    exception、assertion、关闭后写入、Provider 失败或 `[error]` 日志，均使该次验证无效。
31. formatter 只能作用于本轮新建/触及文件，并必须先检查其 diff 规模。小范围功能修改若引发整文件格式扩散，
    必须停止并收窄 hunk；不得用恢复未使用字段/import 或新增 warning 的方式单纯追求 diff 更小。
32. 当 worktree 包含多个功能簇时，必须按簇分别报告状态与验证，不得用一个笼统的“优化完成”覆盖整个
    dirty worktree。ARB 与 gen_l10n、GraphQL operation 与 codegen 合同、`part` 父文件与新 part 必须同组审阅。
