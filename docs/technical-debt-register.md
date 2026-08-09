# DioHub 技术债登记表

最后更新：2026-08-09

## 1. 用途与边界

本文件登记已经有代码、测试、Profile 或稳定复现证据的问题。登记不等于授权立即重构；处理范围仍受
[`development-constraints.md`](development-constraints.md) 和当轮用户任务约束。

本表最初基于 `develop@324de833` 建立，后续条目按当前工作区的生产入口、代码和回归逐项更新。
未建立 Android 或 Linux Profile 性能基线的条目仍统一标记为“待 Profile 验证”，不把代码形态、Debug
观感或 Widget Test 直接写成已测量的性能结论。

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
| 状态 | Resolved（`6916f32a`） |
| 优先级 | P1 |
| 位置 | `lib/common/animations/app_motion_media_query.dart`；`lib/main.dart` 根应用包装；`test/common/animations/app_motion_media_query_test.dart` |
| 症状 | 原根 `MediaQuery` 将 `disableAnimations` 直接写成应用设置值，没有与继承自平台的 `MediaQuery.disableAnimations` 合并。 |
| 证据 | `6916f32a` 保留单一 `AppMotionMediaQuery`，按 `appAnimationsDisabled || platformData.disableAnimations` 合并；应用/平台 `false/false`、`true/false`、`false/true` 三种组合测试均通过。 |
| 用户影响 | 已避免应用设置重新开启平台明确要求关闭的动画；具体组件级 Reduced Motion 覆盖仍属于 TD-003。 |
| 冲突来源 | 自定义外观设置与 Flutter 平台辅助功能状态的合并规则缺失。 |
| 建议方案 | 已采用根级单一合并策略；后续组件只读取合并后的 `MediaQuery.disableAnimations`，不得自行反转。 |
| 清理风险 | 根 `MediaQuery` 改动会影响全应用动画与现有测试时序。 |
| 前置条件 | 根级组合矩阵已完成；路由、Tab、Drawer 的组件级行为仍由 TD-003 继续约束。 |
| 回归验证 | `flutter test --concurrency=1 test/common/animations/app_motion_media_query_test.dart` 3/3 通过；全仓 237/237 通过。 |
| 触发条件 | 后续修改根 `MediaQuery`、应用动画总开关或平台辅助功能桥接时，必须重跑组合矩阵；若组件绕过合并值则重新开启本条目。 |

### TD-003 Motion Token 与路由/组件时序尚未收敛

| 字段 | 内容 |
| --- | --- |
| ID | TD-003 |
| 状态 | In Progress（新页面/详情外壳已收敛，旧页面视觉时序仍待逐页迁移） |
| 优先级 | P2 |
| 位置 | `lib/common/animations/motion.dart`；`lib/common/animations/app_page_transition.dart`；`lib/routes/router.dart`；`lib/common/nav_center/shell/tab_page_view.dart`；Wiki/Repository 切换与异步状态 |
| 症状 | 原 Home 路由内联 400ms 转场，旧详情 Tab、Wiki、异步状态和 Shimmer 分别维护时序；仓库其他旧页面仍存在未分类的视觉 Duration。 |
| 证据 | 当前工作区已把 Home/Repository/Wiki/Issue/PR/Profile 路由统一为 240ms 前进、220ms 返回，把 Repository/Profile/旧详情 Tab/Wiki/异步状态集中为 180ms，并让 Shimmer 使用集中 Token；路由、Tab、异步状态及 Shimmer 的 Reduced Motion 测试通过。静态搜索仍会命中未迁移旧页面以及防抖/轮询等非视觉时序，因此不能标记全仓完成。 |
| 用户影响 | 新页面与共享详情外壳已有一致转场和平台 Reduced Motion 行为；旧内容页仍可能表现出不同节奏。尚未测量帧影响。 |
| 冲突来源 | 上游动画工具、自定义旧视觉与新 MD3 页面并存。 |
| 建议方案 | 继续按页面迁移视觉时序；组件只读取集中 Token 与合并后的 `MediaQuery.disableAnimations`，防抖/轮询等业务时序保持独立。 |
| 清理风险 | 直接缩短所有 Duration 会误改防抖、轮询、Toast 等业务时序。 |
| 前置条件 | 新页面入口与核心切换测试已建立；旧页迁移仍需逐页行为测试。 |
| 回归验证 | 页面转场 2/2、Reduced Motion 组件 2/2、旧详情 Tab 2/2、既有目标回归 54/54、全仓 237/237；Profile 目标 10/10 与共享外壳回归 28/28 通过，但 Profile/Release 帧记录仍未执行。 |
| 触发条件 | 下一张旧内容页迁移时同步收敛其视觉时序；建立解决提交且剩余视觉 Duration 完成分类后再转 `Resolved`。 |

### TD-004 Repository Tab 切换会销毁列表控制器

| 字段 | 内容 |
| --- | --- |
| ID | TD-004 |
| 状态 | Resolved（`6916f32a`） |
| 优先级 | P1 |
| 位置 | `lib/view/repository/md3/repository_md3_screen.dart`；`lib/common/wrappers/search_scroll_wrapper.dart`；`lib/providers/search/search_state_notifier.dart`；相关 Repository/Search Widget Test |
| 症状 | 原 Repository 只构建当前 Tab；切离 Issues/PR 时其 Stateful 子树被卸载，内部 `PaginationController` 随之 dispose，返回时重新创建。第一轮保活只覆盖 Repository 主 Tab，Issue/PR 内部 Open/Closed 仍共用一个 controller，切换查询会清空并重取；页面还会在 `initState` 写入默认 Open Provider，存在 Riverpod build-time mutation 红屏。 |
| 证据 | `6916f32a` 使用两层有界会话：八个仓库主 Tab “首次访问才构建 + `IndexedStack` 保活”；Issue/PR 内部按完整 API query 与 SearchType 分配独立 `PaginationController`，仅保留最近四个 LRU 查询。默认 Open 由 `SearchStateNotifier.build()` 创建，不再由 Widget 生命周期写 Provider；查询切换使用 180ms 轻淡入，Reduced Motion 下为零时长，缓存命中不显示首屏骨架也不发新请求。 |
| 用户影响 | 已消除同一 Repository 路由内返回 Tab，以及 Issue/PR 的 Open→Closed→Open 往返时丢失列表、重复首屏请求和概率性 Riverpod 红屏；显式刷新仍会刷新当前查询。 |
| 冲突来源 | 新 Repository 外壳与原搜索分页 Widget 的页面级生命周期不一致。 |
| 建议方案 | 已采用每个 Repository 路由最多保活八个主 Tab 子树、每张 Issue/PR 列表最多四个查询会话的双重有界策略；跨仓库仍由路由实例隔离，不提升为全局缓存。后续增加主 Tab 或会话容量前必须重新评估生命周期边界。 |
| 清理风险 | 用户访问全部主 Tab 后会同时保留其已加载页面状态，Issue/PR 各保留最多四个分页控制器；LRU 淘汰会在第五个不同查询后重新请求最旧查询，这是明确的内存/网络折中。低内存 Profile 尚未建立，不能据此声称内存影响已解决。 |
| 前置条件 | 当前身份键、惰性构建和状态恢复 Widget Test 已建立；内存影响待 Profile。 |
| 回归验证 | `repository_issue_pull_md3_test.dart` 20/20：Issues 与 Pull requests 都验证 Open→Closed→Open 只有两次请求、返回无首屏骨架，四会话 LRU、五行响应式 Shimmer、Reduced Motion、360/800/1440px、错误重试和刷新均通过；`search_state_notifier_test.dart` 8/8 验证六类 Issue/PR scope 在 Provider 创建时即有 Open；相关 Home/Repository/Tab 回归另有 26/26、全仓 237/237 通过。 |
| 触发条件 | 若后续扩展保活 Tab 或查询会话容量，先做内存验证；若生产回归再次出现返回骨架、重复首屏请求或生命周期写 Provider，则重新开启本条目。 |

### TD-005 分页刷新会在新结果成功前清空旧内容

| 字段 | 内容 |
| --- | --- |
| ID | TD-005 |
| 状态 | Resolved（`6916f32a`） |
| 优先级 | P1 |
| 位置 | `lib/common/pagination/pagination_controller.dart`；`lib/common/pagination/paginated_sliver_list.dart`；`lib/common/events/events.dart`；`lib/common/wrappers/search_scroll_wrapper.dart` |
| 症状 | 原 `refresh()` 在 replacement first page 返回前执行 `_items.clear()` 并清空总数。 |
| 证据 | `6916f32a` 的默认刷新保留已提交 items/count，首个新页成功后原子替换；失败保留旧内容，重试仍从空 cursor 开始。查询或搜索类型变化显式使用 `retainItems: false`，不会在新筛选下短暂展示旧查询结果。 |
| 用户影响 | Home Feed 与 Repository Issues/PR 手动刷新不再闪空或因刷新失败丢失可读内容；筛选切换仍保持结果语义正确。 |
| 冲突来源 | 现有分页控制器将 refresh 定义为 reset-and-fetch。 |
| 建议方案 | 已在公共 `PaginationController` 实现 SWR 与 refresh-aware retry；搜索范围变化使用明确的非保留刷新，不建立第二套分页状态机。 |
| 清理风险 | controller 被多个页面复用，状态机变化可能影响筛选、乐观更新和 refresh 去重。 |
| 前置条件 | 有数据刷新、失败重试、连续 refresh、旧请求 epoch 与查询变化测试均已建立。 |
| 回归验证 | Pagination controller 4/4、Sliver 刷新 2/2、目标测试 54/54、全仓 237/237 通过。 |
| 触发条件 | 后续修改分页刷新、epoch 隔离或查询切换语义时必须保留正向结果与禁止事件断言；若再次出现刷新闪空或失败清空旧内容则重新开启本条目。 |

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
| 状态 | In Progress（Repository 根 README、CONTRIBUTING、SECURITY 顶层解析及 README 图片下载/分类已接入 Runtime；其他路径待处理） |
| 优先级 | P1 |
| 位置 | `lib/common/markdown_view/markdown_render_artifact.dart`；`lib/common/markdown_view/markdown_body.dart`；`lib/common/markdown_view/readme_image_resource.dart`；`lib/providers/repository/repository_readme_resource.dart`；`lib/providers/repository/repository_document_resource.dart`；`lib/view/repository/commits/widgets/changes_viewer.dart` |
| 症状 | Repository 根 README 原本会在 Widget 状态初始化/更新时重复同步解析完整 HTML；其他 Markdown 入口仍走同步完整解析。Diff 仍在 `build()` 中同步解析完整 patch，并把完整 Diff 放入单个 `SingleChildScrollView`。README 栅格最终像素解码仍由 Flutter `ImageCache` 完成，不属于 Runtime worker。 |
| 证据 | 当前根 README、CONTRIBUTING 与 SECURITY 的顶层解析、标题提取和 section 切分由 compute lane 中的真实 worker isolate 完成并缓存 artifact；Code/Security 双消费者、auto-dispose 返回、显式刷新和缺失负缓存回归证明相同身份的源请求和顶层解析不重复。README 图片下载/原始字节/分类已进入 Runtime：分类跨真实 worker，但栅格只返回元数据，artifact 与 source 复用同一份 bytes；合法 8 MiB 栅格链落入默认预算，且持有最外层 artifact Lease 时递归依赖链不会被普通 LRU 或内存 trim 单独逐出。失败继续局部重试；每个 `HtmlWidget` section 仍有内部构建/解析，License/Wiki/Profile/旧 Markdown 入口未迁移，`parseUnifiedDiff(widget.patch)` 仍在 build。 |
| 用户影响 | 大 README 或大 Diff 可能占用 UI isolate 并产生长帧；实际阈值和影响待 Profile。 |
| 冲突来源 | 上游 Markdown/Diff 组件按完整文档模型实现，新页面只完成了部分 Sliver 化。 |
| 建议方案 | 保留当前 source → artifact 与图片 source → classification 边界；先 Profile 短生命周期 worker、长 README 和图片内存峰值，再决定常驻 worker pool 或其他正式 Markdown 入口迁移。另行构造大 Diff 基准，再评估 isolate/分块解析和虚拟化。 |
| 清理风险 | HTML Widget、anchor、语法高亮和 Diff 行号依赖完整结构，分块可能破坏链接与布局。 |
| 前置条件 | 根 README 与社区文档已有纯 Dart artifact、图片原始资源合同、请求/解析/下载次数、长文档 sliver 和三档正式入口回归；完整解决仍需代表性 fixture、内存与帧 trace、anchor/Diff 行为测试。 |
| 回归验证 | 当前 Runtime/Markdown/Provider/Code 目标 69/69、全仓 294/294、Linux Debug build 通过；包含双消费者 Single Flight、社区文档失败重试/缺失负缓存/精确失效、递归依赖租约保护、预取准入/取消/预算、栅格 bytes 对象身份与 8 MiB 容量不变量回归。仍需大/小 README、图片与 Diff 的 Profile 对比，以及 anchor、图片、代码块、换行、复制和滚动测试。 |
| 触发条件 | Profile 出现可复现长帧，或 Markdown/Diff 成为下一页面迁移的阻塞项时。 |

### TD-008 新 UI 大文件已混合多个独立职责

| 字段 | 内容 |
| --- | --- |
| ID | TD-008 |
| 状态 | Accepted |
| 优先级 | P2 |
| 位置 | 既有：`repository_md3_screen.dart` 1420 行、`repository_code_md3.dart` 2099 行、`repository_issue_pull_md3.dart` 1331 行、`github_dashboard_home.dart` 1112 行、`unified_home_screen.dart` 725 行；本轮新增：`notifications_inbox_toolbar.dart` 1201 行、`notifications_md3_screen.dart` 840 行、`settings_github_account_page.dart` 629 行、`global_lists_results.dart` 628 行；对应 Notifications/Global Lists 场景测试也已超过 600 行。 |
| 症状 | 多个文件同时包含请求/状态协调、响应式布局、工具栏、导航、列表、辅助区和多种异步状态 Section。 |
| 证据 | 静态行数和类清单显示：Repository shell 同时实现身份、操作、About 和 Contributors；Code 同时实现工具栏、目录、提交和文档；Issue/PR 同时实现查询、筛选、侧栏、列表与状态面板。共享导航/上下文已抽为独立组件，Wiki 已拆为数据协调器与纯响应式视图；Actions 与 Security 也把纯行/状态卡拆为同 library 的展示文件，Insights 拆出图表/指标组件。新 Notifications 工具栏仍同时包含状态分类、自定义筛选、仓库投影、查询、排序和分组；Notifications 协调页、Settings 账户页与 Global Lists 结果页也各自跨越多个 Section。判定依据是职责混合，不是单纯行数。 |
| 用户影响 | 小改动触发大范围 review 和回归，容易再次出现重复尺寸、生命周期或“基础完成被误报为页面完成”。 |
| 冲突来源 | UI 快速迁移阶段将样板页面持续堆叠在少数文件。 |
| 建议方案 | 按 shell、数据协调、响应式布局、Section 和纯展示组件逐步抽取；Notifications 优先按分类导航、搜索/排序/分组和 Saved filter 编辑器拆分，Global Lists 按结果头/行/分页状态拆分，测试按可见状态与生命周期场景拆分；保持现有 Provider/Controller 为唯一业务源。 |
| 清理风险 | 机械拆文件会制造参数传递、重复状态和无语义组件，扩大 diff。 |
| 前置条件 | 先建立当前入口、状态、响应式和关键交互测试；逐文件职责图；限定单轮只拆一条边界。 |
| 回归验证 | 360/800/1440 Widget Test、导航/Tab/刷新测试、analyze/test 和截图对比。 |
| 触发条件 | 下一次修改对应大文件前先拆其本轮触及职责；尤其 Notifications、Global Lists 或 Settings 再新增筛选、Section 或交互时，不允许继续直接增长现有超限文件。当前检查点不在提交前机械拆分，是为了保留已完成的 159 项 UI 回归证据；后续拆分必须以同一入口、请求次数、响应式、语义和 Reduced Motion 回归保持为完成条件。 |

### TD-009 Dense Typography 与可访问性验证尚未形成单一入口

| 字段 | 内容 |
| --- | --- |
| ID | TD-009 |
| 状态 | In Progress（`AppTypography` 基线与首批消费者已建立，全页迁移与真机矩阵待完成） |
| 优先级 | P2 |
| 位置 | `lib/style/app_typography.dart`；`lib/main.dart` Theme extensions；Home/Repository/Compare 首批消费者；`test/style/app_typography_test.dart`；Home/Repository 响应式与可访问性测试 |
| 症状 | 新 UI 已有 GitHub Dense MD3 语义排版扩展，但当前只迁移了首批标题、主信息和等宽文本；其他新页与旧 UI 仍有裸 `fontSize` 或同一语义不同尺寸。可访问性测试也尚未形成全部页面×宽度×文字比例的完整矩阵。 |
| 证据 | `AppTypography` 已集中定义页标题、仓库标题、区块标题、主信息、正文、元数据、标签和等宽角色，并安装到亮/暗 Theme；专项测试校验角色尺寸、行高、字重、用户字体与 Theme 颜色继承。Home 页标题、Repository Code 主信息和 Compare 文件名等已开始消费 Token；静态搜索仍可见未迁移排版。 |
| 用户影响 | 首批页面开始共用稳定排版语义，文字放大和 Reduced Motion 也已有第一层回归守门；未迁移区域仍可能在字号、行高和密度上产生视觉漂移。 |
| 冲突来源 | 旧 UI Theme 与新 MD3 语义层仍处于过渡阶段。 |
| 建议方案 | 保持现有 `AppTypography` 为唯一语义入口，按正式页面逐步迁移 Home、Repository、Notifications、Settings、Profile 与全局列表；仅替换客户端视觉常量，不翻译或改写用户内容。 |
| 清理风险 | 全仓机械替换会改变旧页面布局并造成大范围 Golden 变化。 |
| 前置条件 | Token API 与亮/暗 Theme 安装已建立；仍需为各正式页面建立 360/800/1440 与 1.0/1.3/2.0 的有界验收矩阵，并用实际视觉验收校准密度。 |
| 回归验证 | `app_typography_test.dart` 已覆盖角色派生与亮/暗 Theme 安装；Home/Repository/Compare 已有部分三档宽度和文字放大回归。尚未证明所有新页均已消费 Token，也尚未完成全矩阵和真机字形对比。 |
| 触发条件 | 每次继续迁移正式新页时同步收敛该页排版；全页迁移与可访问性矩阵完成后才可转 `Resolved`。 |

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

### TD-012 主要只读信息流尚未进入统一调度与内存预算

| 字段 | 内容 |
| --- | --- |
| ID | TD-012 |
| 状态 | In Progress（首个 Repository Issues/PR forward page 生产试点已接入） |
| 优先级 | P1 |
| 位置 | `lib/providers`；`lib/view`；`lib/services`；`lib/view/repository/md3/repository_issue_pull_md3.dart`；`docs/resource-runtime-information-flow-inventory.md`；`docs/resource-runtime-integration-template.md` |
| 症状 | Runtime 已覆盖 Repository Code/文档/图片及 Issues/PR 不可变列表页，但 Controller 仍展开持有全部已加载项目；首个 Issues/PR 试点还由 Widget 读取 active scope、选择 fallback 并构造 Runtime page source，尚未形成可直接复用的 Riverpod/query-session binding；Home、Repository 主信息、详情时间线、Actions、Profile、Notifications 等仍由页面级分页 Controller、Riverpod 定时保活或 Service 聚合分别管理。 |
| 证据 | Issues/PR 正式入口现在按 scope + repository + transport + query + cursor/page + size 建立页身份，GraphQL/REST 仍复用原 Service；登录列表已从全局重卡片 fragment 分离为只含行字段的 GraphQL 投影，不再取正文、review/check/project/reaction 等详情数据，labels 从 100 收敛为 5。Runtime stale 首页立即回显并后台原位替换，隐藏 Tab sentinel 保持 0 请求；但 `_runtimePageSource()` 与 `_buildListContent()` 仍在 Widget state 中读取 `activeResourceScopeProvider`、处理 null fallback 并选择 page source。静态搜索仍有 67 处 `PaginationController<...>` 类型引用和 25 处 `keepAliveFor(ref)`。`allReviewThreadsMapProvider` 会分页到耗尽；单文件 patch 查找可能从第一页循环；workflow overview 对工作流列表执行多请求 `Future.wait`；Profile activity 会跨连接和年份聚合；Repository 完整首查询仍携带 6 组 Issues/PR 快捷计数。尚无 Profile 耗时结论。 |
| 用户影响 | 高频页面可能重复请求、在辅助数据到齐前等待、产生网络扇出，或让 Controller 长期持有大列表；具体卡顿和内存影响仍待 Profile/Release 测量。 |
| 冲突来源 | 上游按页面建立 Provider/Controller，ResourceRuntime 后加入且只做了窄试点；分页会话与页资源所有权此前被错误理解为二选一。 |
| 建议方案 | 使用混合边界：`PaginationController` 保留 query/cursor/order/refresh/scroll，会话中的不可变 page result 以 query + cursor/page + size + scope 接入 Runtime；先把 Issues/PR 的 scope、transport、fallback 与 source factory 收进显式 Riverpod/query-session binding，再用第二个 forward-page 消费者验证执行器只需新 Recipe/Loader；大列表 Controller 改为有界页窗口或轻量索引。之后再拆 Repository baseline、PR 时间线/files/reviews、Home feed、Notifications 和 Actions 扇出。 |
| 清理风险 | 直接替换全部 Controller 会破坏双向分页、滚动恢复、mutation overlay、公开 REST 回退和既有查询 LRU；只加 Runtime 缓存但继续无界保留实体则不会降低内存。 |
| 前置条件 | 逐信息流填写接入模板；明确身份、页窗口、SWR、失效、Lease、预算和禁止事件；先建立请求次数与 Controller 身份失败回归。 |
| 回归验证 | 本轮定向 43/43：通用 source 5/5、分页 sliver 3/3、轻量查询合同 1/1、正式 Runtime 入口 4/4、Repository Issues/PR 20/20、Tab transition + guest shell 10/10。已证明 Single Flight、fresh/stale 复用与后台替换、显式下一页、隐藏页 0 请求、刷新失败保留旧项、Open→Closed→Open、REST transport、账号 scope 与独立 Material 边界。尚待真实大仓库、LRU 后实体/Lease、360/800/1440px 人工复核及 Profile/Release 冷暖与内存对比。 |
| 触发条件 | 先人工复核首个试点并收敛 Widget 中的 Runtime 胶水，再设计有界 Controller 页窗口、距离式预取和 mutation 失效；第二个 forward-page 消费者必须验证执行器无需再次修改，完成前不机械扩散到全仓分页。 |

### TD-013 Repository 隐藏 Tab 的异步图片会污染活动 Tab 布局

| 字段 | 内容 |
| --- | --- |
| ID | TD-013 |
| 状态 | In Progress（失败回归与边界修复已更新，待当前工作区 Linux Debug 重新复核） |
| 优先级 | P1 |
| 位置 | `lib/common/markdown_view/widgets/readme_image_view.dart`；`lib/view/repository/md3/repository_md3_screen.dart`；`lib/view/repository/md3/repository_tab_transition.dart` |
| 症状 | Code 的 README 图片尚在下载/分类时切换到 Actions，后台保留的 Code Sliver 会在图片完成后插入新的 `Image`，随后连续出现 `referenceBox.attached`、InheritedElement 和 Sliver 布局断言；表面看似 Actions 页面报错。 |
| 证据 | 用户再次复现后，旧“Linux Debug 已无异常”结论按入口约束自动降级。当前 VM 的一次 PR→Issues 切换记录到 60 个框架异常，其中 31 个为 `InkFeature._paint/referenceBox.attached`，另有隐藏 `RawImage.updateRenderObject`；原转场把整个 `IndexedStack` 放入同一个透明 Material，导致隐藏 Tab 的 Ink feature 与已脱离的 reference box 共用绘制边界。Flutter 上游 issue #161718 仍说明隐藏保留分支异步增加子节点存在同类布局风险。 |
| 用户影响 | 打开 Actions 时可能连续红屏、卡顿并污染整个 Repository 路由；Actions 自身即使已成功加载也无法可靠呈现。 |
| 冲突来源 | Repository 为保留滚动/查询使用 `IndexedStack`，README 图片又可在隐藏期间异步完成；Flutter 3.44.7 的隐藏保留子树布局边界仍存在上游风险。 |
| 建议方案 | 已让访问过的 Repository Tab 显式声明前台 `TickerMode`；图片仍持有 Runtime lease 并继续加载，但隐藏时冻结最后一次前台渲染结果，返回 Code 后再呈现最新结果；移除栅格内部 `LayoutBuilder`。本轮进一步把透明 Material 下沉为每个 Tab 独立边界，转场只移动保留栈，不再让隐藏和活动 Tab 共用 Ink feature 容器；隐藏分页 sentinel 同时停止请求。 |
| 清理风险 | 不能直接卸载隐藏 Tab，否则会重新引入筛选、分页和滚动丢失；不能停止资源 lease，否则返回 Code 会重复下载。隐藏期间图片从 loading 到 data 的视觉变化被有意延迟到再次可见。 |
| 前置条件 | 回归必须在同一保留栈中完成“Code 图片 loading → 切 Actions → 图片完成 → 返回 Code”，并断言隐藏阶段没有 `Image` 实体化、返回后真实图片存在、全程无 Flutter 异常。 |
| 回归验证 | 本轮分页 sentinel 3/3、Tab motion 3/3、Repository guest shell 7/7 通过，并断言隐藏 sentinel 0 请求、两个已访问 Tab 各自存在 Material 边界。此前 README late raster/图片回归仍是历史证据；由于用户复现推翻旧运行结论，当前代码尚须重新执行同一 Linux Debug Code/Actions/Issues/PR 快速切换与 VM 错误流检查。 |
| 触发条件 | 当前工作区 Linux Debug 复现序列无框架异常后才可转为 `Resolved`；若其他隐藏 Tab 仍触发同类布局更新，继续以具体异步叶节点补失败回归，不把整个保活栈退回销毁重建。 |

### TD-014 Notifications 网页信息结构超出公开 REST 列表能力

| 字段 | 内容 |
| --- | --- |
| ID | TD-014 |
| 状态 | Open（活动 Inbox 已完成，本项只登记不可等价部分） |
| 优先级 | P2 |
| 位置 | `lib/view/notifications/notifications_md3_screen.dart`；`lib/providers/notifications/notifications_filters_provider.dart`；GitHub Notifications REST |
| 症状 | GitHub 网页公开展示 Saved、Done、全文搜索、排序、分组及条件引导，但公开 REST 列表只提供 All/Unread、Participating、时间范围和分页；没有 Saved/Done 列表、服务端全文搜索、排序或分组参数，也没有公开“Clear out the clutter”触发合同。 |
| 证据 | 当前页面的 All/Unread 使用正式 REST 会话；原因、自定义、仓库筛选及查询/排序/分组只对已加载窗口做可逆本地投影。宽屏侧栏与 360/800px 底部面板复用同一分类模型；Saved/Done 带 lock 和能力说明，不创建假列表。账户初始化、失败重试、确认未登录、已登录已分离，仅已登录构造 inbox 与 Runtime scope；条件提示只在 All 范围存在已读可见项且本地未关闭时显示。 |
| 用户影响 | 三档宽度都能到达同一通知分类，但本地搜索仍不能命中尚未加载的历史页；Saved/Done 不能像网页一样列出内容；提示出现条件可能与 GitHub 私有服务端策略不同。 |
| 冲突来源 | 网页产品能力与公开 REST 契约不对等，不是通过更换 Flutter 组件或再建一套本地列表即可可靠补齐。 |
| 建议方案 | 保持当前诚实边界。若要补齐 Saved/Done 或全局搜索，先确认官方 GraphQL/REST 是否出现稳定等价接口；否则单独评估本地持久化索引的产品语义、跨设备一致性、账号隔离和迁移成本，不抓取网页私有接口。 |
| 清理风险 | 把当前已加载窗口结果冒充全局结果，或只在本地维护 Saved/Done，会造成跨设备与 GitHub 网页状态不一致；反向工程网页私有接口会引入稳定性和合规风险。 |
| 前置条件 | 明确产品是否接受“仅本地”语义；建立账号切换、分页历史、mutation 回滚、数据库迁移和跨设备不一致提示。 |
| 回归验证 | 当前呈现定向 15/15 证明 All/Unread 会话、本地投影、过滤可恢复、360/800/1440 分类可达、账户四态、文字缩放、Reduced Motion 与错误重试；未证明 Saved/Done、跨未加载页搜索、GitHub 私有提示条件或真实账户平台视觉。 |
| 触发条件 | 用户明确要求本地 Saved/Done，或 GitHub 提供稳定公开接口时重新评估；在此之前不把入口扩写为完整实现。 |

### TD-015 旧设置表面仍有未迁移的高级与运维能力

| 字段 | 内容 |
| --- | --- |
| ID | TD-015 |
| 状态 | Accepted（融合入口、Public profile 与五类正式账户集合已迁移，Web 独占/部分 API 和旧高级表面待逐项取舍） |
| 优先级 | P2 |
| 位置 | `lib/view/settings/` 旧 Themes/Preferences/Behavior；`lib/view/settings/md3/`；旧 Home secondary settings |
| 症状 | 新 `SettingsRoute` 已建立 GitHub 网页设置 IA、真实 Public profile、五类原生账户集合和底部 DioHub 持久化偏好，但 GitHub Web 独占、部分公开 API 与当前 OAuth 未授权能力仍不能完整原生管理；旧设置还包含高级主题/玻璃参数、卡片显示、watcher、accounts、integrations、logs、AI/Premium 等混合能力，不能机械搬入新页面。 |
| 证据 | 当前生产 Settings 的 Public profile 读取 `userProvider` 并由 `ViewerSettingsService` 单次 PATCH；Emails、三类密钥、blocked users 使用现有 REST，Organizations/Repositories 使用现有 GraphQL，并由 Provider-owned Runtime page session 管理分页和精确失效。Account/Appearance/Accessibility/Password/Sessions/Enterprises 明确为 Web 独占，Billing/Notifications 标记部分 API，Codespaces 标记缺 scope。紧凑账户头已接入既有上下文切换；初始化、失败重试、确认未登录与已登录使用稳定外壳分开呈现。DioHub 分类仍读取既有 persisted Provider；旧 secondary settings 未破坏性删除。 |
| 用户影响 | 公开资料、邮箱、密钥和屏蔽可原生管理，组织/仓库可原生浏览；其他 GitHub 设置仍需离开应用，需要旧高级能力的用户也暂时缺少新的原生入口。 |
| 冲突来源 | 原设置按旧 Dashboard secondary tab 和自定义主题体系组织，而当前产品采用共享 App Chrome、MD3 与按正式能力渐进迁移。 |
| 建议方案 | 先为每项旧设置确认真实消费者、平台支持和产品保留决策；保留项接入现有 persisted Provider，新视觉参数优先集中到 Theme/ThemeExtension，watcher/账号/日志按独立页面迁移，不建立第二套 Settings Repository。 |
| 清理风险 | 直接删除会丢失仍有消费者的偏好；直接复制会把过时视觉、平台专用能力和本地/服务器设置混为一谈。 |
| 前置条件 | 旧设置消费者清单；GitHub REST/GraphQL 能力与 OAuth scope 清单；Windows/macOS/Linux/Android 能力矩阵；真实资料写入/重启回归；每轮只迁移一类职责。 |
| 回归验证 | 当前呈现 23/23 覆盖 360/800/1440、2× 文字、简中、Reduced Motion、紧凑上下文入口和账户四态；Public profile 写入与 Runtime 集合专项是此前验证，本轮未重跑。仍需真实账户 REST/GraphQL、失败回滚、数据库重启恢复与 Linux/Android 实拍，对删除项证明无生产消费者和迁移策略。 |
| 触发条件 | 用户确认 Settings 第一阶段视觉后，或下一项功能需要旧偏好入口时按类别排期；在此之前不声称完整设置功能对等。 |

### TD-016 全部仓库尚未合并纯贡献仓库集合

| 字段 | 内容 |
| --- | --- |
| ID | TD-016 |
| 状态 | Accepted（affiliation 正式入口已完成，贡献集合待执行器） |
| 优先级 | P2 |
| 位置 | `lib/view/global_lists/`；`lib/providers/search/global_search_*`；`UserInfoService.getUserRepositories` |
| 症状 | All repositories 已包含 viewer 拥有、协作及组织成员仓库，但不会包含仅提交过代码、当前没有 collaborator/org affiliation 的公开仓库；GitHub 网页 Repository Dashboard 的集合语义更宽。 |
| 证据 | 现有 GraphQL operation 固定 `affiliations: [OWNER, COLLABORATOR, ORGANIZATION_MEMBER]`；GitHub 官方“Viewing all your repositories”文档说明网页列表也包含 contributed repositories。Search API 的 `user:` 只能按 owner 限定，不能作为等价补源。 |
| 用户影响 | 主要可访问仓库可浏览、搜索和新建工作项，但少量历史贡献仓库不会出现在 All repositories，不能称为 GitHub 网页完全等价。 |
| 冲突来源 | 公开 API 将 affiliation repositories 与 contributions 分成不同连接；当前 Runtime 已落地 snapshot/forward page，没有已证明的 FanOut 合并执行器。 |
| 建议方案 | 先定义 contributed repository 的正式 GraphQL source、稳定去重键、跨源排序、游标/刷新与失败降级合同；确认第二个消费者后实现通用 FanOut 执行器，再把两条 source 合并到同一查询会话。 |
| 清理风险 | 在 Widget 中 `Future.wait` 两条列表、抓完再排序或把 Search `user:` 结果混入都会破坏首屏、分页顺序、请求预算和准确语义；抓取网页私有接口不可接受。 |
| 前置条件 | 真实账号 fixture 能区分 owner/collaborator/org member/contributed-only；FanOut 身份、分页和局部失败测试；大列表 Profile/Release 基线。 |
| 回归验证 | 首屏不等待抓完；重复仓库只出现一次；任一 source 失败时边界明确；刷新与账号切换精确失效；360/800/1440 与滚动恢复不回归。 |
| 触发条件 | 用户确认 affiliation 版本 UI 后，且产品要求网页 Repository Dashboard 完整集合时进入架构评审；在此之前不为单页临时实现聚合。 |

### TD-017 Home 公开搜索浏览与正式 Repository 路由尚未合流

| 字段 | 内容 |
| --- | --- |
| ID | TD-017 |
| 状态 | Accepted |
| 优先级 | P1 |
| 位置 | `lib/view/home/unified_home_screen.dart`；正式 `RepositoryRoute` guest shell |
| 症状 | Home 中点击公开搜索结果后，在当前 Home 外壳内切换到独立 `PublicRepositoryBrowser`；点击 Top repositories 则进入正式 `RepositoryRoute`。两条入口的顶栏语义、返回行为、加载状态和可用功能不完全一致。 |
| 证据 | `_UnifiedHomeScreenState` 对选中搜索结果直接构建 `PublicRepositoryBrowser`，而 Top repository 走 `_openTopRepository` 的正式导航。当前未登录正式 Repository Code 尚未与该公开 REST 浏览能力对等，直接改路由会让无账号用户丢失已有公开目录/文本浏览。 |
| 用户影响 | 同一仓库因入口不同呈现两种页面和导航语义，也扩大了响应式、空/错误状态与可访问性的双重维护面。 |
| 冲突来源 | 公开 REST 浏览早于正式 guest Repository Code 对等落地，不能用一次路由替换掩盖数据能力差异。 |
| 建议方案 | 先让正式 Repository Code guest shell 复用现有公开 REST Service/Provider，达到目录、文本、loading/empty/error/retry 和权限对等；再让 Home 搜索结果统一导向正式路由，最后删除页面内临时浏览分支。 |
| 清理风险 | 过早改路由会回归免登录浏览；直接把 `PublicRepositoryBrowser` 搬进外壳会形成第二套 Repository 状态模型。 |
| 前置条件 | 列出两条生产入口的能力差异；为正式 guest Code 建立公开仓库、限流、404、二进制文件和返回状态回归。 |
| 回归验证 | 未登录从 Home 搜索和 Top repositories 打开同一公开仓库时，只出现一个正式 Repository 路由，且目录/文本能力、返回、刷新、深链、360/800/1440px 和 2× 文字均不回归。 |
| 触发条件 | 下一轮公开 Repository Code 对等任务；在对等完成前不删除当前公开浏览能力。 |

### TD-018 Compare 仍使用独立 Scaffold，未进入共享 Repository 外壳

| 字段 | 内容 |
| --- | --- |
| ID | TD-018 |
| 状态 | Accepted |
| 优先级 | P2 |
| 位置 | `lib/view/repository/compare_view_screen.dart`；Repository context chrome/shell |
| 症状 | Compare 已完成响应式 ref 选择、文案本地化和差异摘要排版，但根页面仍直接返回自己的 `Scaffold + AppBar`，没有复用统一 `AppChrome` 与 Repository 上下文。 |
| 证据 | `CompareViewScreen.build()` 实例化独立 `Scaffold`、`AppBar`；当前 360px/2×、800px/1.3×、1440px 测试只证明 Compare 内容自身不溢出，没有证明共享顶栏、仓库面包屑、抽屉和返回语义一致。 |
| 用户影响 | 从 Repository 进入 Compare 时全局顶栏与仓库上下文会改变，与 Home/Repository/Profile/Notifications/Settings 的统一外壳决策不一致。 |
| 冲突来源 | Compare 内容先于共享 App Chrome 迁移存在，本轮只收敛了它的局部视觉与响应式。 |
| 建议方案 | 保留现有 Compare Provider/数据源，将内容拆成可嵌入的 Repository 子页，由正式路由提供共享 `AppChrome`、仓库面包屑与返回语义；不复制顶栏或再造 Compare 状态层。 |
| 清理风险 | 去掉内层 Scaffold 时可能改变 SafeArea、键盘、BottomSheet 与深链返回行为。 |
| 前置条件 | 确认 Compare 路由与 Repository 上下文的所有入口；为 branch sheet、swap、result tabs 和深链建立行为回归。 |
| 回归验证 | 从 Code/PR 进入 Compare 后共享顶栏、仓库身份与返回不变；360/800/1440px、1.3×/2×、键盘、Reduced Motion 和深链均通过。 |
| 触发条件 | 下一轮 Repository 非 Tab 子页外壳收敛，或 Compare 继续增加页面级操作前。 |

### TD-019 Actions 运行行紧凑文字放大回归

| 字段 | 内容 |
| --- | --- |
| ID | TD-019 |
| 状态 | Resolved（自动回归缺口已关闭；真机视觉仍属全局验收） |
| 优先级 | P2 |
| 位置 | `lib/view/repository/md3/repository_actions_md3.dart`；`lib/view/repository/md3/repository_actions_widgets.dart`；`test/view/repository/md3/repository_secondary_tabs_test.dart` |
| 症状 | 早期 Actions 运行行会在紧凑宽度或文字放大时重排 branch/SHA 元数据，但没有用 API 字段形状在 360px/2× 条件下构建生产行的回归。 |
| 证据 | `RepositoryWorkflowRunRow` 现使用包含长标题、workflow、branch、SHA、event 与 actor 的 `WorkflowRunItem` fixture；`repository_secondary_tabs_test.dart` 在 360px、2× 文字、`disableAnimations` 下断言无溢出、branch/SHA 可见、整行目标至少 48dp，且链接语义含 tap。当前二级 Tab 回归 7/7 通过。 |
| 用户影响 | 自动回归已守住 Android 窄屏/大字号的布局、触控与链接语义；实际字形与手指可用性仍归属 Linux/Android 平台实拍，不再单独作为此技术债。 |
| 冲突来源 | 早期回归主要验证 Tab 外壳和登录边界，没有将 Actions 行本身纳入文字缩放 fixture。 |
| 建议方案 | 已按生产行 + API 字段形状 fixture 补齐 P0 回归；800px/1.3×、1440px/1× 的页面外壳仍由二级 Tab 通用矩阵覆盖。 |
| 清理风险 | 过度为测试缩减文本或隐藏真实元数据会掩盖问题；fixture 必须保留真实字段结构。 |
| 前置条件 | 已保持正式 `WorkflowRunItem` 与生产行，没有重建第二套 workflow model。 |
| 回归验证 | 二级 Tab 7/7 通过；仍需 Android/Linux 真实已登录长名 workflow 复核字形、行高和触控，且在平台验收前不扩大为整张 Actions 页“已完成”。 |
| 触发条件 | 若 Actions 行字段或布局再改，必须保持该回归；平台实拍异常时以新证据重开。 |

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
