# DioHub 技术债登记表

最后更新：2026-07-23

## 1. 用途与边界

本文件登记已经有代码、测试、Profile 或稳定复现证据的问题。登记不等于授权立即重构；处理范围仍受
[`development-constraints.md`](development-constraints.md) 和当轮用户任务约束。

本轮审查基于 `develop` 分支、提交 `903e80ea` 的工作区代码。审查是只读静态审查，没有建立 Android
或 Linux Profile 性能基线，因此涉及耗时和掉帧的影响均标记为“待 Profile 验证”，不把代码形态直接
写成已测量的性能结论。

### 状态

- `Proposed`：证据表明存在风险，但影响、方案或优先级仍需专项验证。
- `Accepted`：问题与边界已经确认，当前明确保留并等待独立任务。
- `In Progress`：已经有获批任务正在处理。
- `Resolved`：已修复，且保留解决提交和回归验证记录。
- `Rejected`：复核后不构成技术债，保留否决原因。

### 优先级

- `P0`：安全、数据丢失、公开构建失败或核心正确性问题。
- `P1`：已经造成回归、明显性能问题，或阻塞下一阶段。
- `P2`：维护成本较高，但当前已经隔离。
- `P3`：命名、风格、纯整理或暂不影响功能的问题。

当前功能轮只处理 P0 和无法绕开的 P1。P2/P3 默认登记后单独排期。清理旧 UI、替换状态管理或迁移
业务模型前必须先建立行为测试。已解决项目不得删除，应补充解决提交与验证记录。

## 2. 当前登记

### TD-001 `runApp` 前存在串联的启动初始化

| 字段 | 内容 |
| --- | --- |
| ID | TD-001 |
| 状态 | Proposed |
| 优先级 | P2 |
| 位置 | `lib/main.dart:82-98,100-143,172-175` |
| 症状 | 应用先等待 API 缓存与数据库初始化，再读取设置和账户信息，随后等待 premium lifecycle 与 Sentry 初始化，最后才调用 `runApp`。 |
| 证据 | `initFuture` 在第 98 行被等待；设置/账户读取位于其后；`premiumLifecycleProvider.initialize` 和 `initSentry` 均位于 `runApp` 之前。尚无 process-to-first-frame Profile 数据。 |
| 用户影响 | 可能延长冷启动白屏或系统启动画面停留时间；实际占比待 Android/Linux Profile 验证。 |
| 冲突来源 | 上游启动顺序与新增基础服务逐步叠加。 |
| 建议方案 | 先测量冷启动时间线，再区分“首帧强依赖”和“可在稳定外壳后初始化”的任务；保持设置与数据库正确性，不盲目并发。 |
| 清理风险 | 调整顺序可能让 Provider 在数据库、账户、错误上报或付费能力就绪前被读取。 |
| 前置条件 | 固定 Android/Linux 基准环境；为 startup state、深链和账户恢复建立行为测试。 |
| 回归验证 | Profile process-to-first-frame 对比；冷/暖启动、已有账户、guest、深链和初始化失败测试。 |
| 触发条件 | 建立启动 Profile 基线后，或启动时序阻塞下一轮体验验收时。 |

### TD-002 Reduced Motion 的平台值可能被应用设置覆盖

| 字段 | 内容 |
| --- | --- |
| ID | TD-002 |
| 状态 | In Progress（代码与回归已完成，待建立解决提交） |
| 优先级 | P1 |
| 位置 | `lib/common/animations/app_motion_media_query.dart`；`lib/main.dart` 根应用包装；`test/common/animations/app_motion_media_query_test.dart` |
| 症状 | 原根 `MediaQuery` 将 `disableAnimations` 直接写成应用设置值，没有与继承自平台的 `MediaQuery.disableAnimations` 合并。 |
| 证据 | 当前工作区新增单一 `AppMotionMediaQuery`，按 `appAnimationsDisabled || platformData.disableAnimations` 合并；应用/平台 `false/false`、`true/false`、`false/true` 三种组合测试均通过。解决提交尚未建立，因此暂不标记 `Resolved`。 |
| 用户影响 | 已避免应用设置重新开启平台明确要求关闭的动画；具体组件级 Reduced Motion 覆盖仍属于 TD-003。 |
| 冲突来源 | 自定义外观设置与 Flutter 平台辅助功能状态的合并规则缺失。 |
| 建议方案 | 已采用根级单一合并策略；后续组件只读取合并后的 `MediaQuery.disableAnimations`，不得自行反转。 |
| 清理风险 | 根 `MediaQuery` 改动会影响全应用动画与现有测试时序。 |
| 前置条件 | 根级组合矩阵已完成；路由、Tab、Drawer 的组件级行为仍由 TD-003 继续约束。 |
| 回归验证 | `flutter test --concurrency=1 test/common/animations/app_motion_media_query_test.dart` 3/3 通过；全仓 227/227 通过。 |
| 触发条件 | 用户确认当前工作区并建立 Git 检查点后补写解决提交，转为 `Resolved`。 |

### TD-003 Motion Token 与路由/组件时序尚未收敛

| 字段 | 内容 |
| --- | --- |
| ID | TD-003 |
| 状态 | In Progress（新页面/详情外壳已收敛，旧页面视觉时序仍待逐页迁移） |
| 优先级 | P2 |
| 位置 | `lib/common/animations/motion.dart`；`lib/common/animations/app_page_transition.dart`；`lib/routes/router.dart`；`lib/common/nav_center/shell/tab_page_view.dart`；Wiki/Repository 切换与异步状态 |
| 症状 | 原 Home 路由内联 400ms 转场，旧详情 Tab、Wiki、异步状态和 Shimmer 分别维护时序；仓库其他旧页面仍存在未分类的视觉 Duration。 |
| 证据 | 当前工作区已把 Home/Repository/Wiki/Issue/PR 路由统一为 240ms 前进、220ms 返回，把 Repository/旧详情 Tab/Wiki/异步状态集中为 180ms，并让 Shimmer 使用集中 Token；路由、Tab、异步状态及 Shimmer 的 Reduced Motion 测试通过。静态搜索仍会命中未迁移旧页面以及防抖/轮询等非视觉时序，因此不能标记全仓完成。 |
| 用户影响 | 新页面与共享详情外壳已有一致转场和平台 Reduced Motion 行为；旧内容页仍可能表现出不同节奏。尚未测量帧影响。 |
| 冲突来源 | 上游动画工具、自定义旧视觉与新 MD3 页面并存。 |
| 建议方案 | 继续按页面迁移视觉时序；组件只读取集中 Token 与合并后的 `MediaQuery.disableAnimations`，防抖/轮询等业务时序保持独立。 |
| 清理风险 | 直接缩短所有 Duration 会误改防抖、轮询、Toast 等业务时序。 |
| 前置条件 | 新页面入口与核心切换测试已建立；旧页迁移仍需逐页行为测试。 |
| 回归验证 | 页面转场 2/2、Reduced Motion 组件 2/2、旧详情 Tab 2/2、目标回归 54/54、全仓 227/227；Profile 转场记录仍未执行。 |
| 触发条件 | 下一张旧内容页迁移时同步收敛其视觉时序；建立解决提交且剩余视觉 Duration 完成分类后再转 `Resolved`。 |

### TD-004 Repository Tab 切换会销毁列表控制器

| 字段 | 内容 |
| --- | --- |
| ID | TD-004 |
| 状态 | In Progress（代码与回归已完成，待建立解决提交） |
| 优先级 | P1 |
| 位置 | `lib/view/repository/md3/repository_md3_screen.dart`；`lib/common/wrappers/search_scroll_wrapper.dart`；`lib/providers/search/search_state_notifier.dart`；相关 Repository/Search Widget Test |
| 症状 | 原 Repository 只构建当前 Tab；切离 Issues/PR 时其 Stateful 子树被卸载，内部 `PaginationController` 随之 dispose，返回时重新创建。第一轮保活只覆盖 Repository 主 Tab，Issue/PR 内部 Open/Closed 仍共用一个 controller，切换查询会清空并重取；页面还会在 `initState` 写入默认 Open Provider，存在 Riverpod build-time mutation 红屏。 |
| 证据 | 当前工作区使用两层有界会话：八个仓库主 Tab “首次访问才构建 + `IndexedStack` 保活”；Issue/PR 内部按完整 API query 与 SearchType 分配独立 `PaginationController`，仅保留最近四个 LRU 查询。默认 Open 由 `SearchStateNotifier.build()` 创建，不再由 Widget 生命周期写 Provider；查询切换使用 180ms 轻淡入，Reduced Motion 下为零时长，缓存命中不显示首屏骨架也不发新请求。解决提交尚未建立。 |
| 用户影响 | 已消除同一 Repository 路由内返回 Tab，以及 Issue/PR 的 Open→Closed→Open 往返时丢失列表、重复首屏请求和概率性 Riverpod 红屏；显式刷新仍会刷新当前查询。 |
| 冲突来源 | 新 Repository 外壳与原搜索分页 Widget 的页面级生命周期不一致。 |
| 建议方案 | 已采用每个 Repository 路由最多保活八个主 Tab 子树、每张 Issue/PR 列表最多四个查询会话的双重有界策略；跨仓库仍由路由实例隔离，不提升为全局缓存。后续增加主 Tab 或会话容量前必须重新评估生命周期边界。 |
| 清理风险 | 用户访问全部主 Tab 后会同时保留其已加载页面状态，Issue/PR 各保留最多四个分页控制器；LRU 淘汰会在第五个不同查询后重新请求最旧查询，这是明确的内存/网络折中。低内存 Profile 尚未建立，不能据此声称内存影响已解决。 |
| 前置条件 | 当前身份键、惰性构建和状态恢复 Widget Test 已建立；内存影响待 Profile。 |
| 回归验证 | `repository_issue_pull_md3_test.dart` 20/20：Issues 与 Pull requests 都验证 Open→Closed→Open 只有两次请求、返回无首屏骨架，四会话 LRU、五行响应式 Shimmer、Reduced Motion、360/800/1440px、错误重试和刷新均通过；`search_state_notifier_test.dart` 8/8 验证六类 Issue/PR scope 在 Provider 创建时即有 Open；相关 Home/Repository/Tab 回归另有 26/26、全仓 227/227 通过。 |
| 触发条件 | 用户确认当前工作区并建立 Git 检查点后补写解决提交，转为 `Resolved`；若后续扩展保活 Tab，先做内存验证。 |

### TD-005 分页刷新会在新结果成功前清空旧内容

| 字段 | 内容 |
| --- | --- |
| ID | TD-005 |
| 状态 | In Progress（代码与回归已完成，待建立解决提交） |
| 优先级 | P1 |
| 位置 | `lib/common/pagination/pagination_controller.dart`；`lib/common/pagination/paginated_sliver_list.dart`；`lib/common/events/events.dart`；`lib/common/wrappers/search_scroll_wrapper.dart` |
| 症状 | 原 `refresh()` 在 replacement first page 返回前执行 `_items.clear()` 并清空总数。 |
| 证据 | 当前工作区默认刷新保留已提交 items/count，首个新页成功后原子替换；失败保留旧内容，重试仍从空 cursor 开始。查询或搜索类型变化显式使用 `retainItems: false`，不会在新筛选下短暂展示旧查询结果。解决提交尚未建立。 |
| 用户影响 | Home Feed 与 Repository Issues/PR 手动刷新不再闪空或因刷新失败丢失可读内容；筛选切换仍保持结果语义正确。 |
| 冲突来源 | 现有分页控制器将 refresh 定义为 reset-and-fetch。 |
| 建议方案 | 已在公共 `PaginationController` 实现 SWR 与 refresh-aware retry；搜索范围变化使用明确的非保留刷新，不建立第二套分页状态机。 |
| 清理风险 | controller 被多个页面复用，状态机变化可能影响筛选、乐观更新和 refresh 去重。 |
| 前置条件 | 有数据刷新、失败重试、连续 refresh、旧请求 epoch 与查询变化测试均已建立。 |
| 回归验证 | Pagination controller 4/4、Sliver 刷新 2/2、目标测试 54/54、全仓 227/227 通过。 |
| 触发条件 | 用户确认当前工作区并建立 Git 检查点后补写解决提交，转为 `Resolved`。 |

### TD-006 Repository 首个正式查询携带多组非 Code 必需计数

| 字段 | 内容 |
| --- | --- |
| ID | TD-006 |
| 状态 | Proposed |
| 优先级 | P1 |
| 位置 | `lib/view/repository/md3/repository_md3_screen.dart:152-154`；`lib/providers/repository/repository_providers_core.dart:61-81`；`packages/diohub_graphql/lib/queries/repositories/repo_info.graphql:4-74` |
| 症状 | 登录状态下 Repository 外壳立即 watch 完整 repository provider；其 GraphQL 查询除仓库信息外还包含 3 组 Issue 和 3 组 PR 搜索计数。 |
| 证据 | `RepositoryNotifier.build()` 调用 `fetchRepositoryGraphQLFull`；`repositoryInfo` 同一个 operation 内包含六个 `search(first: 0)` alias。网络与解析耗时尚未 Profile。 |
| 用户影响 | Code 首屏可能等待当前 Tab 不需要的搜索工作，放大冷缓存导航等待；实际贡献待 trace 验证。 |
| 冲突来源 | 旧 Repository 信息聚合查询被新稳定外壳继续复用。 |
| 建议方案 | 先以 GraphQL/DevTools timeline 确认关键路径，再将身份/默认分支等首屏数据与 Tab 计数分层延迟加载；继续复用现有模型和缓存。 |
| 清理风险 | 拆查询涉及生成类型、缓存键、计数显示和错误边界，可能造成额外请求或 codegen 扩散。 |
| 前置条件 | 记录 operation 时间与 payload；定义稳定外壳的最小正式数据合同；获批 GraphQL/codegen 专项范围。 |
| 回归验证 | 同仓库冷/暖缓存导航对比；Code/Issues/PR 计数正确性、错误和 guest 测试；GraphQL codegen 与现有测试。 |
| 触发条件 | Profile 确认它占据 Repository 可读时间，或下一阶段获批数据分层任务时。 |

### TD-007 Markdown 与 Diff 仍有同步完整解析路径

| 字段 | 内容 |
| --- | --- |
| ID | TD-007 |
| 状态 | Proposed |
| 优先级 | P1 |
| 位置 | `lib/common/markdown_view/markdown_body.dart:109-139,358-380,566-599`；`lib/view/repository/commits/widgets/changes_viewer.dart:28-70` |
| 症状 | Markdown 在状态初始化/更新时同步解析完整 HTML；Diff 在 `build()` 中同步解析完整 patch，并把完整 Diff 放入单个 `SingleChildScrollView`。 |
| 证据 | `parse(htmlContent)` 和 heading 遍历位于同步 `_updateData`；`parseUnifiedDiff(widget.patch)` 位于 `build`。Markdown 后续 Section 已使用 `SliverList.builder`，说明构建已部分惰性化，但解析仍是完整同步路径。 |
| 用户影响 | 大 README 或大 Diff 可能占用 UI isolate 并产生长帧；实际阈值和影响待 Profile。 |
| 冲突来源 | 上游 Markdown/Diff 组件按完整文档模型实现，新页面只完成了部分 Sliver 化。 |
| 建议方案 | 先构造可重复的大文档/大 Diff 基准，再缓存解析结果、避免 build 重算，并评估 isolate/分块解析和虚拟化。 |
| 清理风险 | HTML Widget、anchor、语法高亮和 Diff 行号依赖完整结构，分块可能破坏链接与布局。 |
| 前置条件 | 代表性 fixture、内存与帧 trace、anchor/Diff 行为测试。 |
| 回归验证 | 大/小 README 与 Diff 的 Profile 对比；anchor、图片、代码块、换行、复制和滚动测试。 |
| 触发条件 | Profile 出现可复现长帧，或 Markdown/Diff 成为下一页面迁移的阻塞项时。 |

### TD-008 新 UI 大文件已混合多个独立职责

| 字段 | 内容 |
| --- | --- |
| ID | TD-008 |
| 状态 | Accepted |
| 优先级 | P2 |
| 位置 | `repository_md3_screen.dart` 1329 行；`repository_code_md3.dart` 1869 行；`repository_issue_pull_md3.dart` 1201 行；`github_dashboard_home.dart` 1066 行；`unified_home_screen.dart` 711 行 |
| 症状 | 多个文件同时包含请求/状态协调、响应式布局、工具栏、导航、列表、辅助区和多种异步状态 Section。 |
| 证据 | 静态行数和类清单显示：Repository shell 同时实现身份、操作、About 和 Contributors；Code 同时实现工具栏、目录、提交和文档；Issue/PR 同时实现查询、筛选、侧栏、列表与状态面板。共享导航/上下文已抽为独立组件，Wiki 已拆为数据协调器与纯响应式视图；本轮 Actions 与 Security 也把纯行/状态卡拆为同 library 的展示文件，Insights 拆出图表/指标组件，但其余大文件职责仍混合。判定依据是职责混合，不是单纯行数。 |
| 用户影响 | 小改动触发大范围 review 和回归，容易再次出现重复尺寸、生命周期或“基础完成被误报为页面完成”。 |
| 冲突来源 | UI 快速迁移阶段将样板页面持续堆叠在少数文件。 |
| 建议方案 | 按 shell、数据协调、响应式布局、Section 和纯展示组件逐步抽取；保持现有 Provider/Controller 为唯一业务源。 |
| 清理风险 | 机械拆文件会制造参数传递、重复状态和无语义组件，扩大 diff。 |
| 前置条件 | 先建立当前入口、状态、响应式和关键交互测试；逐文件职责图；限定单轮只拆一条边界。 |
| 回归验证 | 360/800/1440 Widget Test、导航/Tab/刷新测试、analyze/test 和截图对比。 |
| 触发条件 | 下一次大幅修改对应文件，或文件继续新增独立 Section 时。 |

### TD-009 Dense Typography 与可访问性验证尚未形成单一入口

| 字段 | 内容 |
| --- | --- |
| ID | TD-009 |
| 状态 | Accepted（可访问性回归基线已建立，Typography Token 尚未建立） |
| 优先级 | P2 |
| 位置 | `lib/main.dart` Theme extensions；Home/Repository 页面排版；`test/view/home/unified_home_screen_test.dart`；`test/view/repository/repository_guest_shell_test.dart`；`test/common/animations/app_motion_media_query_test.dart` |
| 症状 | 新 UI 尚无专门的 GitHub Dense MD3 语义排版扩展，仍有页面级裸 `fontSize`；可访问性测试入口已建立，但尚未形成全部宽度与文字比例的完整笛卡尔矩阵。 |
| 证据 | Home/Repository 已覆盖 360/800/1440px 的 1.0 基线、800px 的 1.3× 和 360px 的 2×；测试实际发现并修复 Home 快捷操作与 Repository Issues 状态栏溢出。根 Reduced Motion 三组合并测试已建立。语义 Typography Token 仍不存在。 |
| 用户影响 | 文字放大和 Reduced Motion 已有第一层回归守门；页面迁移过程中相同语义仍可能出现不同字号，需要后续集中排版入口。 |
| 冲突来源 | 旧 UI Theme 与新 MD3 语义层仍处于过渡阶段。 |
| 建议方案 | 建立最小语义 Typography/Motion 入口，先迁移 Home 与 Repository；仅替换视觉常量，不触碰用户内容。 |
| 清理风险 | 全仓机械替换会改变旧页面布局并造成大范围 Golden 变化。 |
| 前置条件 | 三档文字缩放和根 Reduced Motion 基线已建立；仍需明确 Token API，并用实际 Profile/视觉验收校准密度。 |
| 回归验证 | 当前 Home/Repository 1.0/1.3/2.0 目标测试通过；建立 Token 后补齐 360/800/1440 × 三档比例的参数化矩阵及普通/Reduced Motion 组件测试。 |
| 触发条件 | 下一轮主题/排版基础工程，或继续迁移新页面前。 |

### TD-010 Issue/PR 详情仅完成共享外壳，内容层仍为旧 UI

| 字段 | 内容 |
| --- | --- |
| ID | TD-010 |
| 状态 | Accepted |
| 优先级 | P1 |
| 位置 | `lib/view/issues_pulls/issue_screen.dart`；`lib/view/issues_pulls/pull_screen.dart`；`lib/common/nav_center/shell/nav_center_shell.dart`；两类详情的 config/widgets |
| 症状 | Issue/PR 详情路由已经使用共享 `AppChrome`、仓库面包屑和 Repository Tab，但标题、正文、时间线、Review/Checks/Files 等仍由旧 `NavCenterShell` 内容体系呈现。 |
| 证据 | 当前工作区新增 `RepositoryContextChrome` 并以 `embedded` 模式移除第二层 `Scaffold`/`SafeArea`；真实 Provider、评论、Review 和 Checks 仍由原详情组件承载。共享外壳和 Tab Motion 有回归，但没有声称详情正文视觉迁移完成。 |
| 用户影响 | 全局导航与仓库上下文已一致，不再看到双层页面壳；进入详情后内容密度、排版与交互仍可能和新 Repository 列表明显不同。 |
| 冲突来源 | 新 App Chrome 与旧 NavCenter 详情内容需要分层迁移，不能为了统一外观重写已有业务状态。 |
| 建议方案 | 先迁移 Issue 标题/状态、正文与评论时间线，再迁移 PR 标题/状态、Review、Checks 和 Files changed；两类页面共享视觉 Section，但不合并领域 Provider/Controller。 |
| 清理风险 | 详情含评论、编辑、Reaction、Review、Checks、Diff 和写操作，整页替换容易遗漏权限、刷新或深链行为。 |
| 前置条件 | 为真实 loading/error/empty、评论、刷新、深链和写操作建立行为测试；固定 360/800/1440 响应式结构。 |
| 回归验证 | 每一小步执行详情 Provider/交互测试、共享外壳与 Tab Reduced Motion 测试、全仓测试及真实 Linux/Android UI 验收。 |
| 触发条件 | 下一轮唯一建议为 Issue 详情内容层迁移；Issue 人工验收后才开始 PR 专属区域。 |

### TD-011 Linux Debug 启动仍触发未适配的平台集成错误

| 字段 | 内容 |
| --- | --- |
| ID | TD-011 |
| 状态 | Proposed |
| 优先级 | P1 |
| 位置 | `lib/utils/device_display_mode.dart`；`lib/services/watchers/background_watcher_service.dart`；Watcher state 持久化 |
| 症状 | Linux Debug 实际启动时尝试调用没有 Linux 实现的高刷新率插件；本地通知初始化未提供 Linux settings；Inbox watcher 写入 state 时出现 SQLite 外键失败。 |
| 证据 | 2026-07-23 从最新 Debug bundle 启动已登录 Home，日志稳定出现 `MissingPluginException(getSupportedModes)`、`Linux settings must be set` 和 `SqliteException(787) FOREIGN KEY constraint failed`；页面仍能加载真实 Home 数据。 |
| 用户影响 | 产生错误日志并使 Linux 高刷新率、后台通知或 watcher 状态保存不可用；本轮没有测量对首帧与运行时性能的影响。 |
| 冲突来源 | 移动平台插件调用与新增 Linux/Desktop 目标、Watcher 数据完整性约束未完全对齐。 |
| 建议方案 | 按三个独立小任务处理：平台能力门控 display mode；为 Linux 通知提供合法初始化或显式禁用；复现并修正 watcher owner/state 外键建立顺序。 |
| 清理风险 | 通知与 watcher 涉及后台生命周期、账号隔离和数据库写入，不能在 UI 任务中顺手吞错或放宽外键。 |
| 前置条件 | Linux 插件能力矩阵；通知初始化测试；含真实账号键与 orphan state 的数据库回归。 |
| 回归验证 | Linux Debug 日志无对应异常；通知/Watcher 启停、账号切换与数据库完整性测试；Android 行为不回归。 |
| 触发条件 | Issue 详情 UI 人工验收后安排 Linux 平台专项，或错误开始阻塞仓库页真实验收时提前处理。 |

## 3. 本轮未确认成技术债的检查项

- 未发现 Repository 新页面另建第二套 API、Repository 或核心业务模型的确证。
  `RepositoryPreview` 用作稳定外壳的种子数据，仍由既有正式数据链补全，不能仅因名称不同判为重复模型。
- 现有 `APICache`、实体缓存、Riverpod `keepAliveFor`、`PaginationController` 的请求 epoch/refresh
  serial、图片解码尺寸限制和 Markdown Section `SliverList.builder` 都是应优先复用的既有基础。
- 裸 Duration 的静态命中同时包含视觉动画、搜索防抖、轮询或其他业务时序；只有上文列出并核对语义的
  位置被登记，不能按搜索数量直接批量修改。

## 4. 新技术债模板

### TD-XXX 简短标题

| 字段 | 内容 |
| --- | --- |
| ID | TD-XXX |
| 状态 | Proposed / Accepted / In Progress / Resolved / Rejected |
| 优先级 | P0 / P1 / P2 / P3 |
| 位置 | 文件、模块或功能 |
| 症状 | 可观察到的问题 |
| 证据 | 代码、测试、Profile 或复现步骤 |
| 用户影响 | 性能、正确性、维护性或体验影响 |
| 冲突来源 | 上游遗留、自定义改动、依赖限制或架构冲突 |
| 建议方案 | 可执行的处理路径 |
| 清理风险 | 可能破坏的行为 |
| 前置条件 | 测试、迁移或设计决策 |
| 回归验证 | 修复后需要执行的检查 |
| 触发条件 | 何时应真正处理 |

Resolved 项须在“证据”或新增记录中补充解决提交、验证命令与结果；Rejected 项须记录复核依据。
