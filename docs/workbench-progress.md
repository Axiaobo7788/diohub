# DioHub Workbench 项目进度

最后更新：2026-08-14

当前阶段：Phase 1 进行中（Workbench 边界已建立，纯 Dart ResourceRuntime 第三阶段、Repository Code 文档/图片及 Issues/PR、Notifications 与全局 Issues/PR/Repositories/Projects/Discussions 的 forward page 生产入口已落地；主要信息流全局接入清单与复用模板已建立；GitHub 式 Home、Repository 主标签、Profile Overview、共享 App Chrome、Device Flow、新 Settings 主入口与新 UI i18n/Motion 基线已落地）

UI 状态：应用无账号时也直接进入 MD3 主页，登录前后共用 GitHub Dashboard 式响应式信息架构；Home、Repository、Profile、Notifications 与 Settings 主入口真正共用同一套 `AppChrome` 顶栏、导航抽屉和账户菜单，页面只追加自己的局部信息结构；Settings 使用唯一原生路由，先按 GitHub 网页端组织账户身份、个人设置、Access 与 Code/planning 分组，再在侧栏底部追加独立 DioHub 应用设置大类；Public profile 已复用真实 `userProvider` 与 `ViewerSettingsService` 批量写回，Emails、三类密钥、Moderation、Organizations 与 Repositories 已接入现有 REST/GraphQL 及 Provider-owned Runtime 分页会话，DioHub 分类继续复用 `SettingsCache` / persisted Provider；其余 GitHub 设置按 Web 独占、部分 API 或缺 OAuth scope 明确显示边界并提供当前 GitHub/GHES 外部入口，不伪造完整能力；Notifications 已接入真实收件箱、All/Unread、原因筛选、自定义筛选、仓库筛选、本地搜索/排序/分组、刷新/自动分页、选择及已读/完成 mutation；Saved/Done 状态入口保留 GitHub 信息结构，但因 GitHub REST 不提供等价列表查询而明确提示不可用，没有伪造内容；Profile Overview 已接入真实身份字段、Profile README、Pinned repositories、贡献日历与活动时间线，Repositories/Projects/Packages/Stars 继续复用已有正式分页列表并在同一路由内保活，但这些列表的 GitHub 网页式视觉尚未逐页迁移；Repository 的 Code、Issues、Pull requests、Actions、Projects、Wiki、Security、Insights 均已接入同一稳定外壳及正式数据源；Issue/PR 详情内容层仍未完成；新页面支持跟随系统 / English / 简体中文与集中 Reduced Motion；Bookmarks、公开访客 Code、Profile 次级列表视觉迁移、Issue/PR 详情内容层和可解释推荐尚待完成

实施约束：所有后续改动遵循 [`docs/development-constraints.md`](development-constraints.md)。基础设施可用、占位页可打开或局部测试通过均不等于用户可见事项完成。

## 1. 项目目标

DioHub Workbench 是一个独立 downstream，目标是在保留 DioHub 现有 GitHub 能力的同时，建立面向 Android 与完整 Desktop（Windows、macOS、Linux）的本地优先开发者工作台。

MVP 只验证一条纵向链路：

```text
本地 Git 仓库
  → GitHub Repository / Branch / HEAD
  → 关联 Pull Request
  → Checks / Workflow Run / Job / Step / Annotation
  → 在本地编辑器打开文件与行号
  → 返回后保留 Workbench 上下文
```

## 2. 当前仓库与基线

| 项目 | 当前状态 | 说明 |
| --- | --- | --- |
| 分支 | `develop` | downstream 基线 |
| 改造起点 | `df722a4963e18c40cf0d19db52a4f883ddcc0949` | Repository MD3、Device Flow 与统一主页开始前的 `develop` HEAD |
| 本轮功能检查点 | `6916f32a` | Runtime-backed 全局 Issues/PR/Repositories、Notifications、融合 Settings、共享排版与 Home/Repository/Profile 响应式视觉收口；包含正式路由、i18n 生成文件和回归测试 |
| Downstream workflows | `5edcf488` | CI/Release 改为仅手动触发；依赖上游私有仓库的 AI 分析任务保持可恢复文件但禁用 job，不再因每次提交自动失败 |
| Flutter | 3.44.7 | Dart 3.12.2 |
| Android SDK | Passed | SDK 36.1、Build Tools 36.1、NDK 28.2、JDK 21，licenses 已接受 |
| Linux 系统依赖 | Simplified | 认证已移除 `flutter_inappwebview`/WPE 依赖；剩余 `webview_flutter` 为 HTML 渲染的 Android/macOS 间接依赖 |
| Android Debug | Previous artifact only; current rerun stopped for memory safety | 2026-07-24 以单 worker、2 GiB Gradle 堆重跑；Kotlin 仍启动独立约 2 GiB daemon，338 秒后 Swap 耗尽且可用内存降至约 1.6 GiB，按低内存停止条件主动中止并停止 daemon。`app-dev-debug.apk` 仍是 2026-07-21 旧产物，不能作为当前工作区验证 |
| Linux Debug | Passed | 2026-07-24 ResourceRuntime 3.3 社区文档迁移后再次使用 `flutter build linux --debug --no-pub` 串行复验成功，生成 `build/linux/x64/debug/bundle/diohub` |
| Linux runtime smoke | Repository tabs rendered, existing platform errors remain | 2026-07-23 实际 `flutter run -d linux --debug`，从 Home 进入真实仓库并人工点击 Code、Actions、Projects、Security、Insights；工作流、ProjectsV2、SECURITY 检测、扫描告警、提交参与度和语言数据均返回真实状态。日志仍复现既有 Linux `flutter_display_mode` 缺插件、通知初始化缺 Linux settings、Watcher state 外键失败；本轮未把这些非 UI 问题静默算作通过 |
| Windows Debug | Not locally verified | 共用 Dart/Flutter UI 和 Device Flow；需 Windows runner 实机构建 |
| macOS Debug | Not locally verified | 共用 Dart/Flutter UI 和 Device Flow；Pod 锁已清理，需 macOS + CocoaPods 实机构建 |
| Root tests | Passed | 2026-07-24 使用 `flutter test --no-pub --concurrency=1` 单并发全套 294/294 通过；包含 ResourceRuntime 调度/真实 worker/依赖 revision/递归依赖租约保护/预取准入取消与即时预算、Code 全目录/README/CONTRIBUTING/SECURITY artifact、README 图片 8 MiB 容量与 bytes 身份/账号切换隔离、Profile MD3、Pagination SWR、Repository Tab/Wiki、Actions/Projects/Security/Insights、类型化深链、共享详情外壳、Reduced Motion、Issue/PR 四会话 LRU、文字缩放及公开访客 Issues/PR REST 回归 |
| Unified home tests | Passed | 360px 未登录/已登录、800px、1440px、1.3×/2× 文字缩放、中文、未登录语言入口、左右展开态、Changelog 失败重试及滚动预加载 Widget Test 共 17/17 通过 |
| Events 空仓库回归 | Passed | 真实 `repo: {}` ForkEvent 的解析、fork 目标降级展示数据、三级分组键与仓库专用消费者保护共 4/4 通过 |
| Dashboard data tests | Passed | Top repositories 主源/兼容回退/账户隔离与 Changelog 请求/解析/官方链接限制共 11/11 通过 |
| Repository shell tests | Passed | 当前 P0 定向 14/14：身份区 3/3、MD3 外壳 4/4、guest/正式入口 7/7；覆盖 360px 紧凑身份、真实可见性边界、稳定外壳及未登录不构造认证请求 |
| i18n + Home + Repository target tests | Passed | 2026-07-23 使用 `--concurrency=1` 串行验证 39/39；覆盖持久化、未登录语言入口、中英主页、Repository preview/文档数据层与稳定 loading 外壳 |
| Home + Repository current target tests | Passed | 2026-07-23 使用 `--no-pub --concurrency=1` 串行复验 54/54；覆盖共享顶栏/抽屉、360/800/1440px Code/Issues/PR/Wiki、1.3×/2× 文字缩放、加载/空/错误、SWR 刷新失败重试、查询变化清除旧结果、生产 Repository 外壳认证三态、已访问 Tab 状态/滚动保持、共享详情外壳和 Reduced Motion |
| Repository README regression | Passed | 36 个标题 + 28 个长代码块的 semantics/滚动/无界 sliver 回归通过；根 README 正式入口消费 Runtime artifact，fresh/retained 返回不重复请求或顶层解析，三档 Code 布局仍通过 |
| Flutter error pipeline | Simplified | 删除 `FlutterError -> Talker -> Zone -> PlatformDispatcher` 重复上报与全局 sliver `ErrorWidget` 替换，恢复 Flutter/Sentry 单一框架错误路径 |
| Public REST tests | Passed | 仓库搜索、目录排序/路径编码、文本/二进制判定、Issues/PR 搜索分页与本地化限流提示共 5/5 通过 |
| Public Repository target tests | Passed | l10n、Public REST、Repository Issues/PR 与生产 guest shell 共 31/31 通过；覆盖真实 REST 行、无 GraphQL、刷新/错误/搜索、360px/800px/1440px 及 1.3×/2× 文字缩放 |
| Repository secondary tabs target tests | Passed | Actions/Projects/Security/Insights 局部导航、360px/800px/1440px 登录边界、2× 文字、Reduced Motion、真实 Insights 比例图、SECURITY 文档候选路径及四类类型化深链共 18/18 通过 |
| Profile MD3 target tests | Passed | 生产 Profile 主入口、360px/800px/1440px、360px 2× 文字、简中、真实 Pinned fixture、稳定 loading/error、共享抽屉及主/旧路径边界共 10/10 通过 |
| Changed-code analyze | No error/warning in targeted paths | 2026-08-08 对本轮精确生产/测试文件集合筛选 `dart analyze --format=machine`：0 error、0 warning；全仓仍有 701 条历史 warning，未混入本轮 UI 修改。Flutter 3.44.7 的 `flutter analyze --no-pub` 再次在扫描前将 LSP 初始化 JSON 截断于第 353 字符并以 255 退出；该工具故障不冒充全仓 analyze 通过 |
| Repository loading/motion follow-up | Passed | 2026-07-23 已在当前环境串行运行：Repository Issues/PR 20/20、Search 默认状态 8/8、相关 Home/Repository/Tab 26/26，并在修复 README 测试容器依赖后完成全仓 237/237。覆盖路由/Tab/查询 Reduced Motion、README 留白、图片软失败、Open→Closed→Open 会话复用、四会话 LRU、五行响应式 Shimmer 和“返回列表无骨架/无新请求” |
| Format check | Existing baseline fails | 2026-07-24 的 `dart format --output=none --set-exit-if-changed .` 只读检查扫描 2196 个文件，其中 1155 个存在既有格式差异并返回 1；命令没有改写工作区，本轮触及 Dart 文件已定向 format |
| Workbench tests | Passed | 17/17 纯 Dart 契约/边界测试通过 |
| Workbench analyze | Passed | `lib/workbench` 和 `test/workbench` 均为 0 issues |
| ResourceRuntime target tests | Passed | 2026-07-24 原第三阶段 69/69；分页通用 source 当前 5/5、Repository 正式入口 4/4。覆盖页 Single Flight、fresh/stale 复用与后台替换、显式下一页、刷新失败保留旧项、Open→Closed→Open、REST transport 与账号 scope；尚无 Profile/Release 结论 |
| ResourceRuntime changed-code analyze | No error/warning in targeted paths | 3.3 的生产 Provider、resource spec、Service、Code/Security 正式消费者、mutation 失效及回归测试共 12 个路径定向 `dart analyze` 为 0 error、0 warning、157 info；全仓 `dart analyze --format=machine` 为 0 error、704 个既有 warning 和 17735 info |
| Issues/PR Runtime performance follow-up | Target tests passed; live Profile pending | 2026-07-24 定向 43/43：登录列表改用轻量 GraphQL 投影，Runtime stale 首页立即回显并后台替换，隐藏 Tab sentinel 为 0 请求，Repository Tab 使用独立 Material 边界；定向 `dart analyze` 为 0 error、0 warning（179 个严格 lint info）。`flutter analyze` 仍因 analysis server LSP JSON 截断以 255 退出；未运行全仓测试、build 或 Profile，不能声称真实耗时已经达标 |
| Global loading correctness follow-up | Structural/request-count contracts passed; Profile pending | 2026-08-12 合并定向 50/50 通过。Star 共享轻量状态区分乐观/权威值，支持 Repository/Profile 刷新对账、账号隔离、双消费者和 `gen_l10n`，7/7 证明操作前后均不创建完整 Repository Provider。PR patch 直接 page + 正式 Provider 3/3 证明首页命中不请求第二页，两文件复用同一 Runtime 页；Diff 10/10 包含命中、4-entry LRU 和超 2 MiB 绕过；Security 8/8 证明 overview 0 请求且三分区各首次一次。Events 投影重建、Notifications 调度/生命周期、Profile activity 解串行同组通过。这些是请求/状态合同；未运行全仓、build 或 Profile/Release，不声称真实帧性能或大列表内存上界已解决。 |
| Scope/conflict cleanup follow-up | Targeted suite passed; logical commit split pending | 2026-08-12 低内存串行回归 93/93 通过，覆盖 Motion、Diff、Events、PR patch Runtime、Notifications、Star、Global Projects/Discussions、Profile 与 Repository Secondary Tabs。该合并运行暴露 Watcher dispose 后在途结果写入已关闭 stream 的竞态；修复后 Notifications/Watcher/Lifecycle 精确复验 10/10 通过，定向 analyze 为 0 error/0 warning。当前全仓 `dart analyze --format=machine` 为 0 error / 689 baseline warnings / 17858 infos，因历史 warning 以 2 退出，不冒充全仓清零。旧完整 Repository Star mutation owner 已删除，五个重点文件无关格式扩散已收窄；本轮约束固化前为 60 tracked + 20 untracked，当前快照为 62 tracked + 20 untracked 的多功能 worktree，尚未经过逻辑分组提交。 |
| Development closure gate | Documented; applies to future code rounds | 2026-08-14 将范围快照、逐文件分类、新旧 owner 账本、异步晚返回/销毁矩阵、测试完整日志审阅、最后修改后重验与多功能 worktree 分组固化到 `AGENTS.md` 和 `development-constraints.md` §7.6。同时将旧的全仓 formatter 默认命令改为触及路径定向检查，全仓基线与本轮增量证据分开报告。本轮仅改文档，不更新之前的运行时/平台完成状态。 |
| Notifications MD3 + Runtime target | Foreground/background ownership verified; live polling pending | 原 27/27 可见会话/响应式回归保留；2026-08-12 追加的通知会话、可见协调器、应用生命周期与 Watcher 精确回归已证明：路由可见时前台租约暂停 `inbox_poll:default`，最后租约释放后按正常 interval 恢复；失败继续下一窗口，dispose 或 app hidden/paused 取消计时并释放所有权，resumed 且路由仍可见时恢复。账户切换继续由现有 Home account listener 停止、invalidate 并重建 Watcher Service。真实账号平台请求时序、Saved/Done 历史列表、有界页窗口和 Profile/Release 性能仍未验证。 |
| Settings MD3 target | Blended GitHub/DioHub structure plus five native account collections implemented; live visual review pending | 2026-08-08 当前呈现定向 23/23：唯一 `SettingsRoute` 复用 `AppChrome`，宽屏侧栏保持 GitHub 分组并追加 DioHub 应用设置；紧凑账户头可进入既有账户上下文切换。账户初始化/失败重试/确认未登录/已登录在 360/800/1440px 分开呈现，加载/错误保持稳定外壳且不会误显示 Sign in。Public profile 与五类账户集合仍复用正式 Provider/Service/Runtime；这些数据层专项测试本轮未重跑。Linux/Android 实拍、真实 API 写入、全仓测试及平台 build 仍待执行 |
| Global work lists target | Formal Issues / Pull requests / Repositories / Projects / Discussions route and retained destination sessions implemented; live-account page review pending | 2026-08-11 抽屉五项进入唯一 `GlobalListsRoute`，并在同一稳定 `AppChrome` 内懒加载、保留访问过的目标页，不再通过 route replacement 销毁查询池和滚动位置。Issues/PR/Discussions 使用现有跨仓库 Search Service，Repositories/Projects 使用现有 User GraphQL Service；全部由 Runtime page + Provider-owned 有界查询会话管理。Projects 支持服务端标题搜索、更新时间/名称排序与 OAuth scope 边界；Discussions 使用官方 `involves:` 与 answered/unanswered 查询语义。五页均有真实 loading/empty/error/retry/refresh/pagination，Projects/Discussions 新增 360/800/1440、1.3×/2×、简中、请求保留和失败重试回归。Linux/Android 真实账号视觉、Projects/Discussions 精确原生详情及组织项目聚合仍待验证或实现，见 TD-020。 |

## 3. 主页统一决策与状态

已确定的产品边界：

- `HomeRoute` 是登录前后的唯一默认入口。
- 认证是能力状态，不是进入应用的门禁。
- 启动页只负责初始化/错误；无账号时不再展示登录页。
- 登录页只在用户主动点击 `Sign in` 或触发受限功能时出现。
- 限制功能可以隐藏；如果保留可发现入口，必须显示明确登录提示，不允许失败后才暴露权限问题。

Feed 数据策略：

| 内容 | 真实数据源 | 当前状态 |
| --- | --- | --- |
| 关注用户/仓库动态 | GitHub REST `GET /users/{username}/received_events` | DioHub 已有 Service、分页、事件模型和卡片，已接入统一主页 |
| Star 动态 | Events API `WatchEvent` | 已有解析、语义化文案与连续 Star 聚合 |
| Release / Push / Fork / Issue / PR 动态 | Events API 对应 event payload | 已有卡片、分支/提交上下文和分页 |
| GitHub 网页“为您推荐” | 无已公开的官方 REST/GraphQL Dashboard 推荐端点 | 不伪装为 GitHub 官方推荐；后续使用 Star、访问历史、语言/Topic 构建可解释的 `Suggested by DioHub` |

Events API 不是实时流，官方明确提示可存在延迟，且时间线仅保留最近事件。主页必须保留刷新、空状态和延迟语义，不将它表述为实时通知。

已完成：

- 未登录用户启动后直接进入主页。
- 登录/未登录共用 `UnifiedHomeScreen`、顶栏、搜索位置、公共仓库列表和 Code 浏览区。
- 同一顶栏操作位置在未登录时显示 `Sign in`，登录后显示账号菜单。
- 登录后的主区域已接回 DioHub 现有真实 Events Feed，包含刷新、空状态、失败重试和距底部约 800px 的自动预加载。
- Events Feed 手动刷新改为 stale-while-revalidate：已有动态和总数保留到新首页成功返回，刷新失败仍可继续阅读并从首页重试；追加分页继续使用原来的 forward 状态，不会退回首屏骨架。
- Events 的 compound actions 设置是跨页分组语义；切换时现在会显式重建同一查询会话，不再让旧分组页与新分组页混合。这是正确性修复，Events 页资源化和距离式预取仍未完成。
- 宽屏主页已按 GitHub Dashboard 信息层级拆成左侧 `Top repositories`、中央 Home/Feed 与可选右侧辅助栏；360px/800px 复用同一数据与操作，按顺序折叠为单列。
- `Top repositories` 主源改为 GitHub GraphQL `viewer.topRepositories(since: 最近一年)`：候选集合包含用户创建和贡献过的仓库，再按公开 API 可用的 `PUSHED_AT DESC` 排序；仅在旧 GHES 明确不支持该字段或响应结构不兼容时回退现有 affiliation 查询。它是公开 API 近似，不声称复刻 GitHub 网页内部交互排名。
- Top repositories 缓存使用 `serverConfig.id/nodeId + login` 隔离；账户切换会重建 API client、Viewer 状态和前台 Watcher，避免新主页继续显示或请求上一账户数据。
- 1440px 右侧栏接入 GitHub Blog 官方 Changelog JSON，使用独立、无认证拦截器的 Dio client；仅接受 `https://github.blog` 链接，并提供加载、空、失败和重试状态。
- 顶栏左上角使用 DioHub 自有标识；左侧汉堡菜单还原全局导航抽屉，右侧头像还原账户菜单。已有原生 Profile/Repositories/Stars/Gists/Organizations/Sponsors/Settings 路由直接复用，其余未迁移入口明确显示阶段提示。
- Home 与 Repository 不再各自维护一套相似顶栏：二者共用 `AppChrome`、全局搜索、导航抽屉、账户菜单与登录/退出动作；Repository 仅通过 `secondaryNavigation` 注入仓库 Tab。抽屉中的 Home 使用显式根路由替换，避免因页面栈不同出现两种“返回主页”行为。
- 共享搜索保留页面语义：Home 继续走公共 REST 仓库搜索，Repository 顶栏进入带仓库上下文的现有搜索路由，没有为了统一外观改变数据源。
- 退出入口会明确确认“移除所有本机 DioHub 账户和 token”，不再把 `logOutAll()` 伪装成无提示的单账户退出。
- 顶栏、账号条、命令面板、快捷操作、Feed 过滤入口和宽屏辅助栏已建立；尚未接入的操作会明确提示阶段状态，不伪装成可用。
- 建立 Flutter 官方 `gen_l10n` + ARB 基线，当前只支持跟随系统 / English / 简体中文（`zh-Hans`）；语言偏好复用既有持久化设置，是设备本地设置，不随 GitHub 账号切换。未登录时可从顶栏切换，已登录时可从账号菜单切换。
- 新主页与新 Repository Code 的客户端文案已迁入 English / 简体中文 ARB；仓库名、README、Issue 等 GitHub/用户内容保持原文。
- Feed 仓库卡片已从 Repository 整页 GraphQL 查询改为复用作者已生成的 `repoCard` 专用查询，复用现有 5 分钟实体缓存避免回滚重复请求，并将首屏大型骨架数从实际 8 个收缩为 3 个。
- Events API 历史事件可能返回空的 `repo: {}`；事件模型按真实缺失字段建模，不伪造仓库 ID/名称。此类 ForkEvent 使用 `payload.forkee` 降级展示，分页仍按原始页长度推进，不再因解析失败重复请求第 1 页。
- 账号菜单显示真实账号头像；头像缺失或加载失败时使用首字母/人物图标回退。
- 未登录时不启动通知/后台 Watcher，不伪造 Account/Token，不放开私有数据或写操作。
- 旧 `NavCenterShell` Dashboard 组件仍保留在仓库，但不再作为登录后的另一套默认主页。

尚未完成：

- 旧 Dashboard 的个人动态、贡献、Pinned Repositories、Review Requests 等尚未按 MD3 信息层级迁入统一主页。
- Bookmarks 尚未迁入新的原生内容页；Notifications 已完成活动收件箱主路径，未读 count/watcher 与网页 Saved/Done 能力仍是独立后续边界。账户菜单中的 Copilot settings、Feature preview、Appearance、Accessibility、Enterprise 等暂为明确的阶段入口。
- Home 页的问答框和 `Agent / Create issue / Write code / Git / Pull requests` 当前是信息架构入口；DioHub 尚无 GitHub Copilot Dashboard 的私有后端能力，因此已登录点击时显示阶段提示。
- 尚未建立能将 Activity 与 `Suggested by DioHub` 稳定穿插的类型化 `HomeFeedEntry` 组合层。
- 所有旧路由尚未统一接入“需要登录”的功能门控。
- 主页视觉密度与真实 Changelog/Top repositories 数据仍需在当前 Linux Debug 进程 Hot Restart 后人工视觉审阅。
- Windows/macOS 仍需在对应宿主机执行原生 Debug 构建。

开发调试注意：Linux `flutter run` 运行期间不要另行覆盖 `build/linux/.../diohub`。若 `/proc/self/exe` 已显示 `(deleted)`，`path_provider`/`flutter_cache_manager` 将无法解析缓存目录，头像会统一回退；必须完整停止后重新 `flutter run`，Hot Restart 不能修复已删除的可执行文件。

## 3.1 Repository Code 响应式状态

已完成：

- Repository 页已移除独立 `NavigationRail`，与主页统一为全局顶栏、仓库面包屑与横向 Repository Tab。
- Repository 页已接入与 Home 相同的 `AppChrome`；宽屏刷新/旧版回退保留为顶栏动作，窄屏次要动作进入溢出菜单，仓库 Tab 作为可横向滚动的二级导航。
- 1440px 使用居中内容区、Code 主列和 About 辅助列；800px 收窄为单主列；360px 保持单列和横向可滚动 Tab。
- 窄屏信息顺序调整为 Watch/Fork/Star → About → Branch/Code/更多 → fork 上游状态 → 最新 Commit → 文件列表 → README。
- 360px 仓库身份区不再被操作按钮替换：保留头像、`owner/repository`、真实 Public/Private、Archived 与 fork 来源，再在其后折叠操作；预览和完整仓库都没有可见性字段时不再猜测为 Public。全局仓库标题也移除了没有对应交互的下拉箭头。
- About 复用真实 `RepoInfo`，展示描述、主页、License、Contributing、Security Policy、Topics、Star/Fork/Watch、Branch/Tag、语言与 fork 上游。
- 窄屏次要操作收入 `Code options`；当前目录过滤仍可用，未实现的 Repository-wide `Go to file` 明确禁用。
- 实时 render tree 证明首个布局异常位于 README 代码块：旧横向 `SingleChildScrollView` 向后来迁入的 `re_editor` 传递无限宽/高，其 `Row + Expanded` 先失败，后续 `geometry == null`/semantics 异常均为级联。
- 静态 `CodeBlockView` 已改为自适应高度的轻量高亮文本；完整 `AppCodeEditor` 只保留在明确提供双向有界约束的文件/编辑页。
- Repository README 从双层 `MultiSliver`/全量布局改为单一惰性 `SliverList`，不再在 README 完全处于 cache 外时仍创建全部 HTML/代码子树。
- 逐文件 last-commit GraphQL 已改为显式 opt-in；默认不再对 53 个根目录项目发出 53 次独立 history 查询，设置页保留可解释开关。
- 全局错误管线不再将一次 Flutter layout 错误同时写入 Talker、console、Zone、PlatformDispatcher 和 Sentry，也不再根据“处于 Viewport 内”错误地返回 `SliverToBoxAdapter`。
- Repository 不同目录的 `PageStorageKey` 已包含 path，避免进入子目录时沿用根目录深滚动位置。
- 主页点击 Top repository 只会执行一次 `RepoRef.navigate`，没有隐藏的二次路由；点击时会在转场动画期间预热目标页相同的 `repositoryProvider(repoRef)`。
- Home 的 Top repository 数据同时保留仓库 node ID 与 default branch，点击时写入按账号/仓库隔离的 `RepositoryPreview`；Repository loading / error / data 共用同一套 MD3 shell 与顶栏/Tab 高度，不再先显示一张简易 Scaffold 后整页重排。
- Branch provider 可先用 `RepositoryPreview.defaultBranch` 解析首个分支，因此目录、最新 Commit 与 README 请求可在完整 Repository GraphQL 返回前启动；完整查询随后补齐权限、计数和操作能力，不再阻塞可浏览内容的首帧。
- 生产 Repository 外壳现在明确区分账号初始化、已登录、已确认未登录与本地账号读取失败：初始化不会闪出登录提示，失败态可重试，未登录和初始化阶段都不会构造 Repository/RepoCard/Branch/Code/Search 的认证 GraphQL 请求。
- 未登录 Code 保留相同 App Chrome、仓库面包屑和 Tab，并明确说明当前公开仓库详情尚待 REST 数据源；返回主页后仍可使用现有公共搜索和 Code 浏览，不以空模型或伪造 Token 冒充完整仓库页。
- Code 页身份区、工具栏、文件表、README 与右栏共用纵向滚动；仓库身份/About 只在 Code Tab 显示，不泄漏到 Issues/PR 页。
- README 区已建立 README / Contributing / License / Security 四类文档页签：只请求当前选中的真实文档，README 复用现有 provider，License 复用现有内容源，Contributing/Security 通过 Contents API 候选路径按需取得；缺失、加载和错误状态均显式显示，仓库文档正文保持原文。
- Repository 文档卡正文使用集中响应式内边距：360px 紧凑窗口为 16px，800px/1440px 为 24px，避免 README 文字、图片和标题贴近描边边缘。
- README 图片分类只发起一次网络请求；SVG 保留解码字符串，栅格 artifact 直接复用 source bytes，
  不从 worker 复制第二份字节。同 URL 由 Runtime Single Flight 合并并在 fresh/retain 窗口内有界
  保留，连接/接收超时分别为 6/12 秒。网络失败降级为局部可重试图标，不再把可选图片超时上抛为
  Provider 失败，也不让图片错误替换整个 README。
- Repository 保留 Tab 现在区分可见与隐藏呈现：切到 Actions 等页面后，Code 的 README 图片仍完成
  Runtime 下载/分类并保留 lease，但不会在隐藏 Sliver 树中插入迟到的 `Image`；返回 Code 后才呈现
  最新结果。这样保留滚动与查询状态的同时，避免后台 README 布局级联触发 Material
  `referenceBox.attached` 断言。
- 右栏使用既有 `RepoInfo` 展示 About、Releases、Sponsor 和 Languages；Contributors 改用独立、轻量的真实 REST 摘要 provider，与文件表和完整 Repository 查询互不阻塞。
- 根目录不再重复显示仓库名面包屑；桌面 Code/About 比例收紧到接近网页的主内容布局，最新 Commit 与文件列表合并为同一个描边区域，README 页签与正文合并为一个文档区域。
- 文件表在未启用逐路径 Commit 查询时会隐藏 Commit/时间列，不再用“目录”或本地化占位文字伪装服务器没有返回的数据；360px、800px、1440px 均有无横向溢出的结构回归。
- Code、Issues、Pull requests 与 Wiki 使用首次访问才构建的有界保活栈：未访问 Tab 不启动其 Provider/Controller，访问后在同一 Repository 路由内保留筛选、分页、Wiki 页面与滚动状态；不会把页面会话提升为跨仓库全局缓存。
- Issue/PR 默认 Open 查询由 `SearchStateNotifier` 在 Provider 创建时建立，Widget 生命周期不再写 Provider；首次进入只呈现一次真实首屏加载态，不再先显示页面级占位，也不再概率性触发 Riverpod build-time mutation。Repository 主 Tab 保留已访问子树；列表内部再按完整 query 与 SearchType 保留最近四个分页会话，因此 Open→Closed→Open 会直接恢复旧列表和滚动状态，不显示骨架、不发第三次请求。第五个不同查询会按 LRU 淘汰最旧会话；显式刷新仍只刷新当前查询。
- Actions、Projects、Security 与 Insights 已移除阶段占位并接入共享仓库外壳；它们首次访问才启动自己的工作流、ProjectsV2、安全告警或统计数据，不再由 Code 首帧预取。
- Security overview 现在只启动 SECURITY policy；Dependabot、Code scanning 和 Secret scanning 在用户首次打开对应分区时才各自发起请求。Overview 刷新也只刷新已访问分区，未访问摘要明确显示“打开后加载”。

尚未完成：

- GitHub 网页的 fork ahead/behind 数、`Contribute`、`Sync fork` 需要额外 compare/mutation 数据，本轮仅展示真实上游仓库，不硬编码截图中的数字。
- `Go to file` 仍待仓库级文件搜索数据源；现有搜索只过滤已加载目录。
- 惰性 README 的跨 section 锚点定位尚未验证真正滚动到目标，当前回归只证明调用不抛错；需要 section index/定位策略后再声称功能对等。
- Repository 的完整 `repo_info` GraphQL 仍携带 6 组 Issues/PR 快捷计数，以及 Releases、Languages、License、Issue templates、Pinned Issues 等非首帧字段；当前预览预热让目录/README 不再等待它，但这些辅助数据自身尚未实现严格懒加载。
- 下一层性能工作仍需将完整查询拆成 Code baseline + 各区域惰性 provider，并增加 stale-while-revalidate 缓存；在此完成前不能声称 Releases/Languages 已按可见区域延迟请求。
- Issues 与 Pull requests 已迁移为共享 Repository 顶部外壳下的两张独立 MD3 列表页；详情路由已接入相同外壳但内容层仍复用旧实现，新建流程仍复用旧路由，尚未迁移的边界在下一节单列。

## 3.2 Repository Issues / Pull requests 列表

已完成：

- Repository 的 Issues 与 Pull requests Tab 已直接进入各自的 MD3 列表，不再显示阶段占位，也不再嵌入旧 `NavCenterShell`。
- 两页复用查询、筛选、刷新和分页基础，但保留不同语义：Issues 在桌面宽度显示局部导航，Pull requests 保持全宽；状态选项分别为 Open/Closed 与 Open/Closed/Merged。
- 查询、筛选和页面状态仍复用既有 `SearchScope` / `SearchState`；登录态继续由 `SearchService`/GraphQL 取得数据，访客态由既有公共 `PublicRepositoryService` 请求 REST `/search/issues`，仓库范围均固定为当前 `repo:`。两条正式数据链返回的真实总数贯通到列表顶部，不用已加载条数伪装总数。
- Issue/PR 页资源工厂按当前 transport 延迟解析服务：访客 REST 会话不再提前构造认证
  `ApiClient`，登录 GraphQL 会话也不依赖匿名 REST 服务；账号 scope 变化仍由列表会话键触发旧
  Controller 释放和新 source 创建。
- 登录列表不再复用全局搜索的重型 Issue/PR card fragment；新投影只取行实际展示的编号、标题、
  作者、状态、时间、评论数和前 5 个标签。详情正文、assignees、milestone、projects、reactions、
  review/check 等字段仍由既有详情入口按需加载，没有建立第二套列表或 Runtime。
- 默认 Open 预设在 `SearchStateNotifier.build()` 构造初始状态时完成，不再依赖页面 `initState`、`didUpdateWidget` 或 post-frame 写入；搜索输入使用真实 300ms 防抖，提交时立即应用，外部状态变化不会覆盖尚未提交的输入。
- 用户在默认 `is:open` 上输入 `is:closed` 或其他同键限定词时会原子替换旧值，不再生成互相冲突的查询；普通文本保留现有筛选，同一次输入的多值标签仍可并存。
- 加载、空数据、错误、重试、下拉刷新和接近列表末端自动加载下一页均有明确状态。首屏加载使用五行、接近真实 Issue/PR 行结构的响应式 Shimmer，而不是单个空白占位。手动刷新会隔离旧请求 epoch、保留已提交列表直到新首页成功后原子替换；失败时旧列表仍可阅读，连续刷新会合并，重试从空 cursor 开始。搜索条件或结果类型改变时激活独立查询会话，不会在新筛选下展示旧结果；最近四个查询可直接恢复，超过容量后最旧会话被释放。
- fresh Runtime 页由新 Controller 直接复用；stale 首页先进入现有 Controller，再由后台 revalidate
  原位替换。隐藏 Repository Tab 的 sentinel 不会继续翻页，重新成为活动 Tab 后才恢复按需分页。
- Repository 顶栏刷新会按当前 Tab 刷新 Code、Issues 或 Pull requests；Tab 内容在索引变化时立即切换，不等待动画结束后再整页替换。
- 登录后新建按钮进入既有 `NewIssueRoute` / `NewPullRequestRoute`，列表项进入既有原生详情路由；未登录使用相同搜索、状态、刷新、空/错误、分页与行组件，但数据改由既有无会话 `RESTHandler` 请求 `/search/issues`，不创建 Search GraphQL、Account 或 Token。
- 未登录写操作与需要账号元数据的高级筛选仍进入明确登录流程；在原生详情迁移完成前，公开列表项打开 GitHub 返回的真实网页 URL，不伪装为已完成的访客原生详情。
- 公开 REST 摘要与登录 GraphQL 轻量摘要都立即映射为共用的
  `RepositoryIssuePullRowData`；全局搜索仍消费现有 `IssueOrPull` 丰富卡片，没有建立第二套列表
  状态机、分页或页面外壳。
- 360px、800px、1440px 的 Issues/PR 结构、长标题、加载/空/错误/刷新、搜索防抖和访客 REST/no-GraphQL 已有 Widget Test；800px/1.3× 与 360px/2× 文字缩放会按可用宽度重排工具栏，不再横向溢出；新增筛选和公共 API 限流客户端文案已进入 `gen_l10n`，标签、分支、账号、Issue/PR 标题保持原文。

尚未完成：

- Issue/PR 详情路由现在使用共用 `AppChrome`、仓库面包屑、Repository Tab 和稳定加载/错误外壳，并移除了嵌套的第二层 `Scaffold` / `SafeArea`；但详情标题、正文、评论时间线、Review/Checks 和新建表单仍是旧内容 UI。本节只完成列表与详情外壳迁移，不能据此声称 Issues/PR 全功能迁移完成。
- PR 文件 patch 现在以 scope + PR + page + page size 作为 Runtime 身份：查找第二个文件会复用已读页，不再每次从网络页 1 重新扫描。首次查找仍可能顺序读取到目标页，path index 和可见文件预取仍属下一步。
- Labels、Milestones、Projects 的管理页尚未迁移；当前列表页只把已有筛选能力接入真实查询，Projects 入口转到明确的阶段页，不伪装成已经实现。
- GitHub 网页的高级提示横幅、批量选择、完整桌面列筛选菜单和筛选器定向打开仍待补齐；现有通用筛选面板可用，但尚未达到网页所有交互的功能对等。

## 3.3 Repository Wiki

已完成：

- Repository 二级导航新增 Wiki，仓库内切换与 `RepoLocationWiki` 深链共用同一 `WikiBrowser`，不会为深链再建立另一套页面。
- Wiki 继续使用作者已有 `wikiProvider` / Controller 和正式 GitHub 数据源；页面列表、Home 页、指定页面、Markdown 正文和内部 Wiki 链接都来自真实返回值，没有演示数据或第二套 API。
- 加载、错误、空仓库 Wiki、重试、页面切换中保留旧正文并显示细进度条等状态均显式呈现；页面菜单、面包屑返回和“在 GitHub 打开”使用真实仓库/页面参数。
- 360px（含 2× 文字）、800px、1440px 的布局以及 Reduced Motion 下零时长标题切换均有 Widget Test；Wiki 客户端文案进入 English / 简体中文 ARB，页面名与 Markdown 正文保持原文。
- 原先同时承担状态协调和全部布局的 Wiki 文件已拆为 176 行数据协调器与 455 行纯响应式视图，保持 Provider 为唯一业务源。

尚未完成：

- GitHub Wiki 的搜索、历史、编辑和新建仍交由网页完成；客户端当前只提供只读浏览与明确外部入口。
- Wiki Markdown 仍走现有同步完整解析路径，大文档影响属于 TD-007，未做 Profile 前不声称性能已经优化。
- 未登录 Wiki 是否可读取取决于现有数据源和 GitHub 权限/限流；本轮没有伪造匿名 Token 或放宽私有仓库权限。

## 3.4 Repository Actions / Projects / Security / Insights

已完成：

- 四个 Tab 共用 `RepositoryTabScaffold` 的页面标题、刷新、宽屏局部导航和窄屏选择器；它只负责页内筛选，不复制全局抽屉或仓库二级 Tab。
- Actions 复用现有 Workflow Service，展示真实 workflow、总运行数、分支筛选、状态、触发者、分支和 SHA；列表接入既有 `PaginationController`，加载更多只影响尾部。
- 2026-07-24 复核确认“打开 Actions 连续红屏”的首个异常来自后台保留的 Code/README 图片完成，
  不是 Actions workflow 请求；修复保持 Actions 数据链不变，只收敛 Repository 隐藏 Tab 的异步
  呈现边界和转场 Material 边界。Linux Debug 在真实 `krille-chan/fluffychat` README 图片位置连续
  执行 Code → Actions → Code → Actions → Code 后，Actions 真数据、README 图片和 Code 滚动恢复
  均正常，VM Extension/Logging 流没有新的 Flutter 异常。
- Projects 复用现有 ProjectsV2 GraphQL，支持真实标题排序、加载、刷新、空状态、错误和分页；没有项目时不显示伪造的“新建项目”能力。
- Security 复用现有 Dependabot GraphQL、Code scanning REST、Secret scanning REST 和 Repository 文档 provider；默认分支的 SECURITY.md、未配置分析、无告警、权限失败分别呈现，不再把 GitHub 的 `no analysis found` 404 当成权限错误。
- Insights 复用现有 participation、languages、contributors、traffic 和 community profile providers；Pulse 使用真实年度提交柱状图和语言比例，Contributors、Traffic、Community standards 按进入的局部页面延迟请求。
- `RepoLocation` 与 GitHub 链接解析已为 Actions、Projects、Security 和 Insights 建立类型化深链；浏览器 `/actions`、`/projects`、`/security`、`/pulse`/`/graphs` 不再降级成 Code。
- 新增文案全部进入 English / 简体中文 ARB；workflow 名、项目标题、分支、SHA、贡献者和统计内容保持服务器原文。
- 360px、800px、1440px 的登录边界、局部导航折叠、2× 文字和 Reduced Motion 有 Widget Test；Linux Debug 已用真实登录账号逐页截图复核。

2026-07-23 截图对比结论：

- Actions 已对齐网页的“左侧 workflow 导航 + 当前 workflow 标题/筛选 + 运行列表”主层级；客户端行保留真实状态、触发者、分支和 SHA，并在窄屏把左侧导航折叠为选择器。
- Projects 已对齐仓库 Tab、页面标题、排序、项目列表与真实空状态；由于当前正式 ProjectsV2 合同没有网页全局搜索/管理写入，本轮没有放置看似可用但只搜索已加载页的输入框，也没有伪造 New project。
- Security 已对齐 Security overview 与 Security policy 的公开层级，并在已登录客户端补充已有正式 Service 能提供的 Dependabot、Code scanning、Secret scanning 三类真实状态；网页的 advisory/配置管理仍明确留在未完成边界。
- Insights 已对齐“左侧报告导航 + Pulse 内容”的桌面层级，Pulse 以真实年度 participation 和 languages 绘制；Contributors、Traffic、Community standards 继续按所选报告延迟加载。
- 对比图按每行“GitHub 网页 / DioHub Linux Debug”排列并保存在本机临时文件 `/tmp/diohub-repository-tabs-comparison.png`，不提交运行截图或 IDE 背景到仓库。

尚未完成：

- GitHub Actions 的 Caches、Deployments、管理操作和完整事件/状态/Actor 筛选没有现成页面合同；当前完成的是可读运行列表与 workflow/branch 筛选，不伪装成网页全功能管理台。
- Projects 当前只读展示 ProjectsV2；创建、编辑、关闭和字段管理仍交由现有网页能力，未新增写入 API。
- Security advisories、Dependency graph、Dependabot 配置等 GitHub 专属管理页尚无本轮批准的数据/写入边界；已实现的 SECURITY 与三类告警保持真实只读状态。
- Insights 的 Dependency graph、Network、Forks、People 等报告尚未迁移；现有 Pulse、Contributors、Traffic、Community standards 不使用推测数据补齐这些入口。

## 3.5 Motion 与 Reduced Motion 边界

- Home、Repository、Wiki、Issue 详情、Pull request 详情及通知等迁移路由统一使用 240ms 前进/220ms 返回、16 逻辑像素的淡入横向位移；被覆盖页只后退 4 逻辑像素并降至 0.98 opacity，建立层级而不制造第二套转场。Repository 主 Tab 与通知 All/Unread 等同层内容使用 180ms、最多 8 逻辑像素的方向过渡，并保证任一时刻只有目标内容树可交互。
- 冷加载骨架必须近似最终几何且使用中性色呼吸；SWR 刷新保留旧内容，只在稳定工具栏显示 2px 进度；追加页只在列表尾显示紧凑进度，不重播整页骨架。禁止彩色 shimmer、逐行 stagger、blur、bounce/spring 或用动画掩盖重新请求。
- `MediaQuery.disableAnimations` 为真时，路由、Repository 内容切换、旧详情 Tab、Wiki 标题、异步状态与 Shimmer 均立即切换或静态显示，不由组件自行反转平台设置。
- 只迁移已经重写或本轮触及的视觉时序；搜索防抖、网络轮询、Toast 等业务时序不做机械替换。
- 视觉时序由 Gemini 仅按 UI/MD3 职责协助审查，API、Runtime、缓存和生命周期结论仍由本项目正式合同决定。本轮验证的是时序、单树和无动画语义，不是 Profile 帧性能；未提供“更流畅”或“性能已解决”的测量结论。

## 3.6 i18n 边界

- 应用使用 Flutter 官方 `flutter_localizations` / `gen_l10n` / ARB，不引入第二套翻译框架。
- 当前支持跟随系统、English 和简体中文；不在 Widget 内按语言写 `if/switch`。
- 新 UI 的所有新增客户端文案必须先进 ARB；旧 UI 在页面迁移时逐步本地化，不为追求数量一次性修改 200+ 个旧文件。
- API/用户内容、仓库名、分支名、README、Issue/PR 正文不自动翻译；时间、空状态、错误和操作标签由客户端本地化。
- 新语言必须同时补齐 ARB key parity、语言选择项、持久化往返和至少一个页面 Widget Test。

## 3.7 本轮需求—实现—验证映射

| 需求 | 实现 | 状态 | 验证 |
| --- | --- | --- | --- |
| Home/Repository 刷新不能因“有功能”而闪空或丢失旧数据 | 公共 `PaginationController` 默认使用 SWR，成功后原子替换；刷新失败保留旧内容并提供 refresh-aware retry | 已满足（`6916f32a`） | controller 4/4、Sliver 2/2、全仓 237/237 |
| Repository Tab 首次进入不应预取无关页面，返回时不能丢失会话 | 未访问 Tab 为占位；首次访问后在当前路由的有界 `IndexedStack` 中保留 Code/Issues/PR/Wiki 子树 | 已满足（`6916f32a`） | no-build、搜索输入、Wiki 页面和 360px/2× 滚动保持 Widget Test |
| Repository 跳转和左右 Tab 切换必须可感知且不以动画伪装重载 | 路由使用固定 16px 位移；Tab 对保活栈施加方向化 8px/轻淡入，Reduced Motion 直接返回原子树；Issue/PR 去除额外初始化占位帧 | 实现完成，真实运行待用户验收 | page/tab/reduced-motion 与返回无骨架断言已在目标 Widget Test 通过 |
| 紧凑 Repository 不能丢失身份、猜测可见性或展示假交互 | 360px 身份区保留 avatar、`owner/repository`、服务端已知的可见性/Archived/fork，再排列操作；未知可见性不渲染 Public，仓库全局标题移除无动作的下拉箭头 | P0 结构已满足；真实字形与触控仍待平台实拍 | identity 3/3、shell 4/4、guest/正式入口 7/7 |
| Issue/PR 的 Open/Closed 往返不能重复首屏加载或在 build 中写 Provider | Provider 构造默认 Open；每页按 query + 类型保留最近四个独立分页会话，缓存命中使用 180ms 轻淡入且不重取；Reduced Motion 为零时长 | 已满足，待真实运行复验 | Issue/PR 21/21、Search Provider 8/8；两类列表均证明 Open→Closed→Open 仅两次请求，LRU 淘汰、加载语义与中性骨架边界已覆盖 |
| README 不贴边且可选图片失败不得破坏文档 | 文档正文使用 16/24px 响应式内边距；栅格复用 source bytes 直接渲染、Runtime 有界缓存、6/12 秒超时、局部重试软失败 | 实现完成，目标测试已复验 | 三档 padding、bytes 对象身份/渲染、失败软化与缓存命中目标测试通过 |
| 平台 Reduced Motion 不得被应用设置反向覆盖 | 根级 `AppMotionMediaQuery` 对应用与平台值取逻辑 OR | 已满足（`6916f32a`） | 3 种组合 3/3，通过全仓回归 |
| Home/Repository 在文字放大时仍可用 | Home 快捷操作允许标签弹性换行；Issues/PR 工具栏断点同时考虑可用宽度与 text scale | 已满足当前基线 | 1.0 的 360/800/1440、1.3× 的 800、2× 的 360；全仓 237/237 |
| 不因本轮性能讨论扩散业务层 | 未修改 GraphQL、codegen、路由、认证、数据库或核心模型；TD-006 保持待 Profile/GraphQL 专项，TD-007 仅推进根 README、CONTRIBUTING、SECURITY 顶层 artifact 与 README 图片原始字节/分类，其余 Markdown/Diff 保持待 Profile/专项任务 | 边界已保持；TD-007 部分推进 | Git diff 复核；没有新增核心 API 或第二套页面状态模型，Runtime Provider 仍是唯一全局控制面 |
| 证明首页到仓库“更快” | 本轮只消除视觉闪空和重复构造，不将 Widget Test 解释为帧性能结论 | 待验证 | 仍需 Linux/Android Profile 的冷/暖导航 trace |
| 未登录公开 Repository Issues/PR 可读 | 复用公共 RESTHandler、SearchState、PaginationController 与 MD3 行；REST 摘要只作为传输 DTO，未创建账号或 Token | 已满足列表范围 | 公开 REST 5/5、全仓 237/237；生产 guest shell 证明无 Repository/Search GraphQL |
| Repository Wiki 必须是可验证的真实页面而非占位 | 共用既有 Wiki provider/controller，接入同一 Repository Tab 与深链；页面列表、正文、状态与外部入口均消费真实参数 | 已满足只读浏览范围 | Wiki 6/6、目标回归 54/54、全仓 237/237 |
| Repository 未完成 Tab 不能继续保留阶段占位 | Actions/Projects/Security/Insights 接入各自既有正式 Service/Provider、共享局部页面壳、类型化深链及完整状态；网页没有公开等价数据的管理子页明确留在未完成边界 | 已满足四个主 Tab 的只读浏览范围 | 二级标签页目标回归 18/18；Linux Debug 真实仓库逐页截图；全仓 237/237 |
| Issue/PR 详情不得再次出现第二套全局顶栏和嵌套页面壳 | 详情路由接入 `RepositoryContextChrome`，旧详情内容以 embedded 模式复用，移除嵌套 `Scaffold`/`SafeArea` | 已满足外壳范围，内容迁移未完成 | 共用外壳 4/4、详情 Tab Motion 2/2、全仓 237/237 |
| Profile 主入口仿照 GitHub 网页且不新建业务层 | 主路径接入共享 `AppChrome`、五项资料导航、真实 `userProvider` / README / Pinned / contributions；既有四类分页列表在惰性保活 Tab 中复用 | Overview 已满足；次级列表仅完成正式接入，视觉迁移未完成 | Profile 11/11，新增元数据链接视觉/语义断言；未运行 Profile 性能 |
| 本轮 Profile 性能 | 用户明确允许暂不测试；没有以 Debug 观感或 Widget Test 代替测量 | 待验证 | 未运行，不提供帧时间或“已优化”结论 |
| 统一资源加载、渲染交付和生命周期管理 | 纯 Dart `ResourceRuntime` 控制 identity/scope/lease/freshness/dependency/budget；正式试点迁移 Repository Code 文档/图片及 Issues/PR 不可变 forward page | 控制面与首个分页桥已满足；License、Wiki、Flutter 像素解码、详情分页和有界 Controller 页窗口未迁移 | 原目标 69/69 + 分页当前 9/9；全仓 294/294 是本轮轻量投影与 stale 原位替换前基线 |
| Repository Issues/PR 冷暖列表不应下载详情字段或在隐藏页继续分页 | 同一 Runtime page source 改用轻量 GraphQL 投影；stale 首页立即回显/后台替换；隐藏 sentinel 禁止请求；每个 Repository Tab 使用独立 Material 边界 | 代码与定向回归已满足；真实大仓库 Profile 和当前 Linux Debug 快速切页待验证 | 本轮定向 43/43，0 error/0 warning；未运行全仓、build、Profile |
| 全局加载审计不得用重缓存代替正确会话和最小请求 | Star 使用共享轻量 mutation/authoritative 状态；Events 在投影语义变化时重建会话；Security 三类告警按分区惰性启动；PR patch 跨文件复用 Runtime 页并命中即停；Diff parse artifact 有界复用；Profile Activity 与 contributions 解耦 | Star 权威 seed、i18n、双消费者和账号隔离自动合同已闭环；Events/Security/PR patch/Diff/Profile 定向正负回归已覆盖。有界 Controller 页窗口、大 Diff worker、Repository baseline 投影与真实性能未完成 | 精确自动回归只证明请求/状态合同；全仓 analyze 历史基线、build、真实账号与 Profile/Release 未通过本轮验收 |
| 全局整理可能拖长加载的信息流并形成复用模板 | 主要信息流清单按 Integrated/Partial/Wave A/B/C/Excluded 分类；固定 Controller/Runtime page/Service 混合所有权与身份、预算、失效、UI、正/负验证模板 | 设计基线完成；Issues/PR 首个生产试点部分接入 | 静态追踪 67 处 `PaginationController`、25 处定时保活；试点合同见独立文档 |
| 右上角 Notifications 必须是共享外壳中的真实原生页面，并避免筛选往返重复首屏请求 | `NotificationsRoute` 复用 `AppChrome`；既有 REST Service 经不可变 Runtime page 进入 Provider-owned All/Unread 两会话池；原因/自定义/仓库筛选和查询、排序、分组均对 Controller 保留数据做可逆本地重投影，已读/完成以 overlay 乐观更新并精确失效。可见 session 按 `X-Poll-Interval` 刷新已加载当前 Controller，并在租约期间暂停同一 `InboxPollWatcher`计时器；app hidden/paused 释放所有权，resumed 恢复。宽屏左栏分为 Inbox/Saved/Done、Filters、Repositories；360/800px 复用同一分类模型的底部面板。账户初始化/失败/未登录/已登录分开呈现 | 活动 Inbox、本地投影、三档分类、账户四态及前台/Watcher/生命周期所有权自动合同已实现；Saved/Done 历史列表仍无公开等价查询，自定义筛选使用既有 SavedSearch 持久化；跨未加载页服务端全局搜索、GitHub 未公开提示算法、有界页窗口及真实账号视觉/轮询时序仍未完成或待验证 | 通知/前台协调/生命周期/Watcher 精确回归覆盖禁止重复调度、失败续调度、dispose、hidden/paused/resumed 和正常间隔恢复；真实登录态 Linux/Android 待人工检查 |
| 设置入口必须缝合 GitHub 网页设置与 DioHub 应用设置 | 账户菜单进入唯一 `SettingsRoute`；账户身份头和宽屏分组侧栏先复现 GitHub 设置 IA，底部追加 DioHub 大类；紧凑头部进入同一既有账户上下文切换；账户初始化/失败/确认未登录/已登录使用稳定外壳分开呈现。Public profile 从真实 `userProvider` 读取并由 `ViewerSettingsService` 单次更新，GitHub 私有页面诚实外跳；DioHub 值继续来自既有持久化 Provider | Public profile、统一结构、紧凑上下文入口及账户状态边界已实现；GitHub Account/Access/Code planning 其余页面仅有外部管理边界，旧 Advanced theme、watcher/account/integration/log 仍未迁移 | 本轮 UI 14/14，覆盖 360/800/1440、2×、简中、Reduced Motion、四种账户结果、retry 及 comfortable density 下 48dp 菜单目标；数据集合专项本轮未重跑，真实 Linux/Android 视觉、真 API 写入和重启恢复待人工验证 |

### 3.7.1 2026-08-08 Gemini 视觉审查闭环

Gemini 本轮仅用于 UI、信息密度、动效和 Material 3 符合度审查；数据源、路由、状态与 Runtime 边界仍由项目约束和生产代码决定。

| 审查项 | 本轮实现 | 验证与完成边界 |
| --- | --- | --- |
| 排版比例散落 | 建立 `AppTypography` ThemeExtension，安装到亮/暗 Theme，并迁移 Home、Repository、Compare 首批语义角色 | Typography 2/2；全页迁移和真机字形矩阵仍见 TD-009 |
| 全局顶栏密度、搜索与侧栏不一致 | Home/Repository 继续共用 `AppChrome`；固定稳定边线、集中 52/56dp 高度、`/` 搜索快捷键、相同抽屉宽度与选中对比 | Motion/Chrome/Drawer/Secondary 34/34；不采用 64dp 顶栏、胶囊抽屉、桌面 48dp 可见 SearchBar 和滚动动态阴影，因其与当前 GitHub 紧凑参照及项目 Token 冲突；桌面 40dp 可见控件仍保留至少 48dp 命中区 |
| Home 夸大为单个搜索目标，子控件像假按钮 | Ask、添加上下文、模型和发送拆成独立可操作目标；紧凑账户行改为真实 48dp 切换操作 | Home + Compare 23/23；公开搜索结果与正式 guest Repository 路由尚未合流，见 TD-017 |
| Repository 加载几何不稳定、旧玻璃骨架、列表太矮、README 边距/语义不稳定 | Code 首屏统一 5 行几何，桌面目录行至少 48dp；Issues/PR 改中性 `surfaceContainerHighest` 骨架，保留单一 loading 语义和 Reduced Motion；README 使用响应式内边距 | Code + Issues/PR 26/26；正式 `lib/view/repository/md3` 已无 legacy Shimmer/Glass/Squircle 引用 |
| Actions 长标题被 branch/SHA 挤压 | 小于 520px 或文字放大时将 branch/SHA 收入元数据 Wrap，状态同时用文本和图标表达 | API 字段形状在 360px/2×/Reduced Motion 的二级 Tab 7/7 通过；实机长名 workflow 待拍摄复核 |
| Notifications/Settings 紧凑目标、退场语义及密度收缩 | 筛选清除、紧凑菜单与触发器强制 48dp 命中；退场通知树不可点击/不可宣读；保留 GitHub 式矩形密度，不滥用 MD3 大胶囊 | Notifications + Settings 31/31；Saved/Done 和 Web 独占设置仍按 API 边界明确未完成 |
| Profile 链接仅有颜色、Compare 紧凑区域溢出 | Profile 元数据加链接语义/点击；Compare 在 480px 下或 1.3× 以上堆叠 ref 选择器，摘要改 Wrap 并完成客户端文案 i18n | Profile 11/11、Compare 已包含在 23/23；Compare 独立 Scaffold 尚未进入共享 Repository 外壳，见 TD-018 |

本轮不重复计数的目标 Widget Test 共 159/159 通过，覆盖 360/800/1440px、1.3×/2× 文字、Reduced Motion、键盘搜索、链接/选中/loading 语义、稳定异步外壳和查询会话保留。未执行实机截图、Windows/macOS 运行、Profile/Release 性能或平台 build，因此不声称最终视觉和流畅度已验收。

## 3.8 Profile MD3 第一阶段

已完成：

- `UserProfileRoute` 的 Overview、Repositories、Projects、Packages、Stars 主路径进入新的 Profile MD3 页面；Gists、Organizations、Followers、Keys、Sponsors 等尚未迁移的扩展路径继续走旧页面，不用占位内容冒充完成。
- Profile 复用 Home/Repository 的 `AppChrome`、DioHub 标识、全局搜索、抽屉和账户菜单；窄屏标题空间不足时只保留带语义标签的标识，不再产生 360px 顶栏溢出。
- Overview 使用既有 `userProvider` 及生成类型展示头像、姓名、登录名、状态、简介、关注关系和公开元数据；编辑资料与 Follow/Unfollow 继续复用既有 mutation。
- Profile README、Pinned repositories、贡献日历和贡献活动分别复用已有正式 Provider/组件。贡献加载错误保持局部重试，不替换整张 Profile；Pinned 卡片打开现有 Repository 路由。
- Activity timeline 已不再被 contributions 的成功状态门闩阻塞，两个区域可独立启动和局部显示状态。Activity 本身的跨连接/跨年聚合仍未改成时间窗口，本轮未运行 Profile/Release 性能。
- 1440px 使用身份侧栏 + Overview 主列；800px 与 360px 折叠为同一信息架构。Repositories/Projects/Packages/Stars 在窄屏仍保留身份上下文，并复用既有 `TabBody` 分页/刷新生命周期。
- 五个主标签首次访问才创建内容，访问后在当前 Profile 路由的有界 `IndexedStack` 中保留，标签切换使用集中 Motion；Profile 路由使用与 Home/Repository 相同的页面转场。
- 新增客户端文案进入 English / 简体中文 ARB；用户名、简介、仓库名、README 等服务端或用户内容保持原文。

尚未完成：

- Repositories、Projects、Packages、Stars 当前是“正式数据与生命周期已接入”，但列表行、筛选区和空状态仍主要复用旧呈现，不能称为四张网页式页面已经完成。
- 贡献日历与活动时间线继续使用原组件；年份/时间范围控件和 GitHub 网页的完整 Activity 筛选尚未迁移进新 Overview。
- Organizations、Gists、Followers/Following、Sponsors、Keys 等扩展页仍是旧 UI；没有在本轮批量删除。
- 尚未在真实登录态 Linux/Android 运行并截图对比，也未建立 Profile/Release 帧性能与内存基线。

## 3.9 ResourceRuntime 第三阶段

本节只保留阶段结论，不再复制资源合同、逐信息流状态和历史测试计数。当前已经建立纯 Dart
Runtime 控制面，并把 Repository Code/社区文档/README 图片与 Repository Issues/PR、
Notifications 分页部分接入正式生产链。`RuntimeForwardPageSource` 已有两个生产消费者，但
有界页窗口、距离式预取、详情流和更完整的 mutation 失效仍未完成。

事实来源分工如下：

- 架构、已落地资源和 Repository Issues/PR forward page 精确合同以
  [`resource-runtime-architecture.md`](resource-runtime-architecture.md) 为唯一事实源；
- 其他主要信息流的 Integrated / Partial / Wave A–C / Excluded 状态以
  [`resource-runtime-information-flow-inventory.md`](resource-runtime-information-flow-inventory.md)
  为准；
- 后续接入统一填写
  [`resource-runtime-integration-template.md`](resource-runtime-integration-template.md)，不能复制
  当前 Issues/PR Widget 胶水或把候选访问模式写成已实现能力；
- 风险、触发条件和未解决项继续登记在 TD-007、TD-012、TD-013，不在本节复制技术债全文。

此前 69/69 定向 Runtime 回归、294/294 全仓测试与 Linux Debug build 属于历史检查点，
不用来代替当前工作区验证；实时结果只在顶部基线表与当轮完成报告更新。

## 3.10 GitHub / DioHub 融合 Settings 第一阶段

已完成：

- 账户菜单中的 Settings、Appearance、Accessibility 不再进入旧 Profile/NavCenter 路径，而是进入
  唯一 `SettingsRoute`；Home 的显式账户菜单回调与其他 `AppChrome` 页面使用相同路由语义。
- Settings 页面复用全局 `AppChrome`。800/1440px 使用 GitHub 式分组侧栏和受限宽度内容列，
  360px 将同一分组/目的地模型折叠到 `MenuAnchor` 与单列滚动，不复制第二套设置业务状态。
- 页面顶部显示当前 GitHub 账户身份；侧栏顺序先是 Public profile、Account、GitHub Appearance /
  Accessibility / Notifications，再是 Access、Code/planning，最下方才是独立 DioHub 应用设置大类。
- Public profile 直接复用 `userProvider` 的正式 GraphQL 资料；公开邮箱选择器从现有
  `ViewerSettingsService.listEmails` 读取已验证邮箱且局部处理失败，一次保存再通过
  `ViewerSettingsService.updateProfile` 合并为一次 REST `PATCH /user`；头像、Pronouns 等公开
  API 不支持的编辑项明确交给当前 GitHub/GHES 服务器管理。
- General、Appearance、Accessibility、Code & repositories、Notifications、Privacy、About
  只读写既有 `SettingsCache`、`PersistedNotifier` 与正式 Provider；语言、主题、布局、代码浏览、
  Diff、通知轮询和诊断偏好继续使用原数据库持久化，没有新增第二套设置仓库。
- Emails、SSH keys、GPG keys、SSH signing keys 与 blocked users 复用
  `ViewerSettingsService` 的正式 REST；Organizations 与 Repositories 复用 `UserInfoService` 的正式
  GraphQL。只为组织查询补回既有 operation 已返回的 `pageInfo/totalCount`，没有改 codegen 或再造 API。
- 上述远程集合统一使用 `ResourceRuntime` 不可变 page recipe、显式 REST page/GraphQL cursor identity、
  精确 collection tag，以及 Provider-owned 惰性 `ViewerSettingsSession`；短时离开目的地保留
  Controller，返回时可复用 30 秒 fresh page。Widget 不持有 cursor、Lease、generation 或资源 identity。
- Emails 原生页支持添加、删除非主邮箱和主邮箱公开可见性；三类密钥支持添加/删除；Moderation 支持
  列出、屏蔽与取消屏蔽。Organizations 与 Repositories 是原生真实只读列表并跳转应用内资料/仓库，
  成员关系与仓库管理明确继续前往当前 GitHub/GHES。
- 其余 GitHub 页面不再共用语义不明的占位说明：Account/Appearance/Accessibility/Password/Sessions/
  Enterprises 标注为 Web 独占；Billing/Notifications 标注公开 API 只覆盖部分；Codespaces 标注当前
  OAuth scope 未授权。三类都保留当前服务器外部入口，不写成原生完成。
- 所有新增客户端文案进入 English / 简体中文 ARB；仓库、账号及其他用户内容不翻译。
- 分类切换使用集中内容 Motion，`MediaQuery.disableAnimations` 下为零时长。选择控件以当前值作为
  identity，Provider 更新后不会继续显示旧的 `initialSelection`。
- 当前定向验证 Settings 21/21：既有 12 项覆盖 360/800/1440、360px/2×、简中、深链、
  Reduced Motion 与 Public profile 单次写入；新增 3 项用真实页面组件覆盖 Emails 在
  360/800/1440 的数据/可见性 mutation 与无溢出，2 项证明 REST page identity、返回 fresh cache
  不重复请求和精确 refresh，4 项覆盖 Keys/Organizations/Moderation/Repositories 正式空状态与
  360px 无溢出。它没有替代真实服务器写入、失败回滚实测和平台实拍。

尚未完成：

- 旧 Themes/Preferences/Behavior 中的高级色彩、透明度、玻璃效果、卡片显示、watcher 管理、
  integrations/accounts/logs/AI/Premium 等未逐项迁移；它们保留为 TD-015，不用本轮本地偏好页
  冒充完整旧设置功能对等。
- Account、GitHub Appearance/Accessibility、Password/Authentication、Sessions、Enterprises
  仍是 Web 独占；Billing 与 GitHub Notifications 只有部分 API；Codespaces 尚缺 OAuth scope。
  这些目的地是“边界说明 + 外部管理”，不是原生页面完成。Repositories/Organizations 当前也只是
  原生真实只读与应用内导航，不冒充已具备完整账户管理写操作。
- 尚未在当前 Linux/Android 真实进程执行设置修改、重启恢复及三档实拍；本轮 Widget Test 证明
  响应式与 Provider 读取结构，不替代平台持久化和最终视觉验收。

## 3.11 全局 Issues / Pull requests / Repositories

已完成：

- 全局导航抽屉的 All issues、All pull requests、All repositories 使用显式选中态并进入唯一
  `GlobalListsRoute`；三页互相切换时停留在同一稳定 `AppChrome`，只在页面协调层切换目的地，不再
  replace 路由并销毁查询会话。从其他页面首次进入仍正常 push，不复制 Home/Repository 的 App Chrome。
- Issues 与 Pull requests 继续复用正式 `SearchService.searchIssuesPulls`、`SearchScope` 与
  `SearchStateNotifier`。账号 login 在 `ViewerInfo` 尚未返回时也不会丢失，因此首个请求始终保留
  `involves:<login>` 与 `type:issue/type:pr`，不会短暂退化成全 GitHub 搜索。
- Open、Closed、Assigned、Created、Mentioned、排序、搜索、下拉刷新、错误重试、空状态和接近末端
  自动分页都连接真实查询。最近四个查询 Controller 有界保留，Runtime 保存不可变 page；实测
  Open→Closed→Open 只产生两个首屏请求，返回 Open 不重现骨架、不产生第三次请求。抽屉跨目的地
  Issues→PR→Issues 也只为首次访问的目的地创建首屏请求，返回后保留原搜索条件和滚动位置；访问过的
  页面保持 mounted，隐藏页由 `TickerMode` 禁止分页 sentinel 在后台推进，账号切换则按 account key
  重建会话边界。
- 查询或 Open/Closed 切换不再用 `AnimatedSwitcher` 同时挂载退场与入场的两棵分页树；旧 sentinel
  立即离开生产树，只对新结果使用集中 Motion Token 做单树淡入，避免视觉动画额外推进旧查询分页。
- All repositories 不再使用 `user:<login>` Search API。正式源改为现有
  `UserInfoService.getUserRepositories`，其 GraphQL affiliations 为 OWNER、COLLABORATOR 与
  ORGANIZATION_MEMBER；公开/私有、最近推送/更新、名称、Stars 由服务器查询，仓库名/描述与 fork
  为已保留页上的可逆本地投影。文字投影切换复用同一 Runtime page，不建立第二份远程缓存。
- 仓库行只展示正式投影实际拥有的字段：仓库全名、可见性、fork、描述、语言、Stars 与更新时间；
  不伪造未查询的 fork count、archive 或总数。分页未结束且 API 没有 totalCount 时只显示列表标题，
  到末页后才显示精确已加载总数。
- 新建议题与新建 Pull request 使用同一可访问仓库 Runtime 会话打开原生 MD3 选择器；Issue 继续读取
  既有正式 issue templates 并进入 `NewIssueRoute`，PR 进入 `NewPullRequestRoute`。没有新增 API、
  mutation 模型或旧 Bottom Sheet 业务副本。
- 新文案进入 English / 简体中文 `gen_l10n`，仓库名、Issue/PR 标题、标签和模板等用户内容保持原文。
  360/800/1440px、360px/1.3×、1440px/2×、抽屉正式 destination、新建仓库选择、真实空状态及
  请求次数均有回归；三张页面现在分别覆盖三档宽度，修复了只有短标题 Issues 通过、Pull requests 与
  Repositories 在 360px 结果头溢出的漏测；新增跨目的地状态/请求次数、滚动恢复、单分页树切换及真实
  失败重试回归。本轮定向测试 23/23、相关路径分析 0 issues；此前相关共享测试 24/24、全仓串行测试
  356/356，本轮没有重跑全仓。此前通过路径定向分析为
  0 error、0 warning；全仓 `dart analyze --format=machine` 为 0 error、702 个既有 warning 和
  17761 个 info。
- 原 1850 行页面已按稳定外壳、筛选控件、结果列表、创建流程和纯映射辅助拆为同一 Dart library 的
  五个职责文件，单文件均不超过 600 行；拆分没有引入第二套 Provider、Controller 或数据模型。

尚未完成：

- GitHub 网页仓库 Dashboard 还会出现“参与贡献但不是 owner/collaborator/org member”的公开仓库；
  现有单一 GraphQL connection 不返回该集合。补齐需要第二个正式 source、去重/排序合同和已经实现
  的 FanOut/聚合执行器，当前只登记 TD-016，不抓取网页私有接口，也不把 affiliation 集合写成完全
  等价。
- Issues/PR 的全局 Search 仍复用较丰富的已有 card fragment；Runtime 解决重复请求、SWR 和会话恢复，
  不会自动减少 GraphQL 字段。若真实 Profile 证明首屏仍慢，应新增全局工作列表的最小投影，而不是在
  Widget 再建一条加载链。
- 2026-08-02 Linux Debug 已实际构建并启动，真实首页账号数据正常显示；目标三页因本机 Wayland
  环境缺少输入自动化仍未完成点击/实拍。运行日志继续复现既有 display mode、sharing intent、Linux
  notifications settings、Watcher 外键和 Sentry crashpad 问题，均不冒充本轮通过。仍需真实账号验证
  大列表连续翻页、限流/权限错误、从新建页返回后的滚动保持和 Android 实拍；本节不包含
  Profile/Release 性能达标结论。

## 3.12 全局 Projects / Discussions

已完成：

- 全局导航抽屉的 Projects 与 Discussions 已从阶段提示迁入现有唯一 `GlobalListsRoute`，与 All issues、
  All pull requests、All repositories 共用稳定 `AppChrome` 和目的地保活容器；返回已访问目的地不会重放
  首页请求，隐藏目的地不会推进分页 sentinel。
- Projects 复用 `UserInfoService` 与现有 ProjectsV2 GraphQL connection，按账号、查询、排序和 cursor
  建立 Runtime page 身份；标题搜索及最近更新/名称排序由服务器执行。缺少 `project` OAuth scope 时不构造
  请求，显示可操作的重新授权状态。
- Discussions 复用 `SearchService.searchDiscussions`，使用 GitHub 官方公开搜索语义组合
  `involves:<login>`、`is:answered` 和 `is:unanswered`；仓库名、讨论标题、分类和作者等服务端内容保持原文。
- 两页均复用共享分页视图的同构骨架、下拉刷新、空状态、错误与 Retry、接近末端自动分页和滚动存储；
  查询会话由 Provider-owned 有界 LRU 持有，没有修改 Runtime 核心、`PaginationController` 或建立第二套
  Service。
- 新 UI 文案进入 English / 简体中文 `gen_l10n`；360/800/1440px 与 1.3×/2× 文字缩放、抽屉往返
  请求次数、服务端查询限定符、缺 scope 和首次失败重试都有 Widget 回归。Projects/Discussions 专项
  12/12，通过与原三张全局列表及抽屉合跑共 38/38；本轮未运行全仓测试或平台 build。

尚未完成：

- 当前原生范围是账号级列表。项目详情/编辑、讨论详情/回复尚无与新全局外壳对等的原生路由，行点击使用
  API 返回的精确 GitHub/GHES URL，不把 Repository Discussions Tab 或阶段页冒充为精确详情。
- Projects 当前只列当前用户拥有的 ProjectsV2；组织项目、Recently viewed 等网页聚合需要独立正式 source
  和跨源合同。真实账号的私有项目权限、超长讨论连续翻页、限流以及 Linux/Android 实拍仍待验证；没有
  Profile/Release 性能基线，因此不声称真实加载性能已经优于网页。

## 3.13 2026-08-12 未提交范围与性能复核

本节记录当前 dirty worktree 的初次审计与后续收敛结果。表格中的“已闭环”只指定向自动合同；
真实账号/平台验证、逻辑提交分组和公开政策审阅仍按各行状态待完成。原有定向测试不能反推新组合路径没有问题。

| 复核项 | 当前判定 | 后续边界 |
| --- | --- | --- |
| Notifications 调度 | 自动合同已闭环，待平台验证（P1） | visible-inbox session 与 `InboxPollWatcher` 已具有互斥调度所有权，并覆盖 app hidden/paused/resumed；真实账号请求时序与 Home-owned 账号重建仍待平台复核，见 TD-021。 |
| Repository Star 共享 overlay | 自动合同已闭环，待平台验证（P1） | 保留不启动完整 Repository 查询的轻量边界，权威 seed、Repository/card 双消费者、账号隔离和 `gen_l10n` 已有 7/7 回归；无调用的旧完整 Repository Star owner 已删除，见 TD-022。 |
| 当前变更范围 | hunk 已收敛，待拆分提交（P2） | 五个重点文件已逐 hunk 去除 459 行无关重排；多个功能簇、生成 i18n、内部文档与顶层公开文档仍不应被当作一项“性能优化”提交。2026-08-14 新增闭环门禁已将该审计变为后续每轮强制步骤，但不会自动解决当前的逻辑分组，见 TD-023。 |
| 顶层公开文档 | 内容边界已收敛，待独立发布审阅（P1） | README/CONTRIBUTING/Security/Privacy 已分别恢复稳定事实边界；`PrivacyPolicy.md` 显式非发布声明，责任人/联系/保留等不猜测，仍需与 Runtime/UI 分离审阅和提交，见 TD-024。 |
| Global Lists 类型化 session pool | 已登记，本轮不重构（P2） | Repository/Project 两套 LRU Controller pool 形状重复；等第三个明确消费者证明共性后再抽取，禁止继续复制第三套，见 TD-025。 |

提交前停止条件：TD-021/TD-022 的自动合同已闭环，但平台验证与解决提交前不转为
`Resolved`；TD-023 仍要求按逻辑变更组提交，TD-024 仍要求顶层公开文档独立审阅，
不建立包含整个 worktree 的单一提交。

## 4. 已完成

- 确认 `develop@5e77b8d` downstream 基线与 `upstream` 记录策略。
- 建立 Flutter 3.44.7 / Dart 3.12.2 可复现工具链约束。
- 修复公开 bootstrap/codegen 路径，不再依赖私有 premium codegen CI。
- 完成 Android SDK/NDK/licenses 配置并验证 Android Debug APK。
- 建立 GitHub OAuth Device Flow：
  - Android、Windows、macOS、Linux 共用纯 Dart HTTP 请求/轮询逻辑。
  - 系统浏览器打开一次性验证页，不内嵌 WebView，不需 Client Secret。
  - 保留 PAT/GitHub Enterprise 入口，移除 AppAuth 和 `flutter_inappwebview` 认证依赖。
- 建立统一公共主页第一版：
  - 无 Account 即为公共浏览状态，不维护冗余 Guest 开关，不伪造 Account/Token。
  - 复用既有 RESTHandler 搜索公共仓库、浏览目录与文本文件。
  - 未登录不启动通知和后台 Watcher，私有数据/写操作明确要求登录。
- 将统一主页调整为 GitHub Dashboard 式响应布局，用 `viewer.topRepositories` 接入账户隔离的 Top repositories，并接入官方 GitHub Changelog。
- 还原左侧全局导航抽屉、右侧账户菜单展开态与 DioHub 全局标识；360px/1440px 展开态 Widget Test 均无溢出。
- 建立 Home/Repository 共用的 `AppChrome`，统一全局顶栏、抽屉、账户菜单和导航语义，同时允许页面注入自己的二级导航。
- 建立 Profile Overview 的 GitHub 式 MD3 第一阶段：共享全局外壳、真实身份/README/Pinned/贡献数据、五项主导航、三档响应式、简中与稳定异步状态；次级列表视觉迁移和旧扩展页保留为明确边界。
- 建立 Settings MD3 第一阶段：唯一设置路由、共享 App Chrome、七个真实本地偏好分类、三档响应式、
  简中、2× 文字和 Reduced Motion；旧高级设置及 GitHub 账户设置保留为明确边界。
- 完善 Repository Code MD3 响应式样板：GitHub 式顶栏/Tab、桌面 Code+About 双列、移动单列信息顺序，360/800/1440px semantics Widget Test 通过。
- 完成 Repository Issues 与 Pull requests 两张独立 MD3 列表：真实仓库查询、默认 Open、筛选、防抖、真实总数、刷新、错误重试、自动分页、响应式和未登录权限边界均已接入；详情已接入共享外壳但仍复用旧内容层，新建仍复用旧路由。
- 完成 Home/Repository P1 状态收口：手动刷新 SWR、查询变化不展示旧范围结果、Repository Tab 惰性构建与路由内保活、根 Reduced Motion 合并，以及 1.3×/2× 文字缩放溢出回归。
- 完成 Repository Wiki 只读浏览页：复用已有正式数据源，补齐响应式页面列表、面包屑、Markdown、加载/错误/空/重试及同一外壳深链。
- 完成 Repository Actions、Projects、Security、Insights 四个主 Tab 的只读迁移：复用既有正式数据、共享局部导航与分页，补齐类型化深链、响应式、i18n 和真实 Linux 截图复核。
- Issue/PR 详情路由接入共享 App/Repository 外壳并移除嵌套页面壳；详情内容层仍明确列为下一阶段，未写成已完成。
- 建立首批集中 Motion：页面转场、Repository 内容、旧详情 Tab、Wiki/异步状态和 Shimmer 都遵守平台与应用合并后的 Reduced Motion。
- 建立第一批 Workbench 边界：
  - 纯 Dart `GitHubGateway`。
  - Repository / Workflow Run / Job / Step 稳定模型。
  - branch / HEAD SHA 到 Pull Request 的匹配结果。
  - Check rollup / Check Run / Status Context / Annotation 稳定模型。
  - `DioHubLegacyGitHubGateway` 映射层。
  - 依赖旧 `ApiClient`/Service 的独立 Production Source。
  - 防止 Domain 引入 Flutter、Riverpod、Service、Provider 或生成模型的边界测试。
- 建立最小应用层：
  - 纯 Dart `WorkbenchViewState`。
  - 纯 Dart `UnifiedRepoController`。
  - 串行加载 Repository → HEAD/PR/Checks → Annotation。
  - 刷新失败时保留上一份完整成功快照。
- 建立 Workspace Domain 与安全端口：
  - `LocalRepo` / `Worktree` / `RepoLink` / `BranchLink` / `EditorTarget`。
  - branch、HEAD、dirty、ahead/behind 的只读快照。
  - GitHub HTTPS、SCP-style SSH 和 `ssh://` remote 规范化。
  - 凭据从 UI 可显示 remote 中移除，且 `origin` fork 与 `upstream` 不合并。
  - 只读 `WorkspaceGateway` 与语义化 `EditorGateway`，业务层不接收 shell 字符串。
  - Workspace/Editor Fake 与统一 Controller 本地快照测试。

## 5. 当前边界

```text
未来 Workbench View
        ↓
UnifiedRepoController / WorkbenchViewState    （已组合本地与远程快照）
        ├─ GitHubGateway                           （已建立首批契约）
        │      ↓
        │  DioHubLegacyGitHubGateway               （已建立）
        │      ↓
        │  ApiClientDioHubLegacyGatewaySource      （已建立）
        │      ↓
        │  DioHub Legacy REST / GraphQL / Services
        └─ WorkspaceGateway / EditorGateway        （纯 Dart 端口 + Fake 已建立）
               ↓
           WorkspaceDesktop                  （真实系统适配待建）
```

## 6. 进入生产 UI 前置门槛

信息架构、线框图和静态布局研究可以立即进行。开始接入真实数据的 Workbench UI 前，应满足以下门槛：

### Gate 1：当前平台基线可区分回归

- [x] Android Debug 构建通过。
- [x] 在充足内存下单任务复跑 Linux Debug。
- [x] 在 Device Flow + 统一主页 + Events Feed + Repository README + i18n 基线上串行复跑 root tests，120/120 通过。
- [ ] 在有对应 runner 时验证 Windows/macOS Debug，不用 Linux 结果代替。
- [x] 保留当前 analyzer warning 基线，新 Workbench 与其测试当前为 0 issues。

### Gate 2：远程数据契约足以支撑纵向链路

- [x] Repository 摘要。
- [x] Workflow Run / Job / Step。
- [x] 根据 branch / HEAD SHA 查找关联 Pull Request。
- [x] Checks 概览（Check Run 与 legacy Status Context）。
- [ ] PR Review 概览。
- [x] Check Annotation 与远程文件路径/行号。
- [ ] 错误、权限、限流和条件请求的稳定结果类型（已建 failure kind，Production Source 尚未完成精确分类）。

### Gate 3：本地 Workspace 纯 Dart 契约

- [x] `LocalRepo`、`Worktree`、`RepoLink`、`BranchLink`、`EditorTarget` 模型。
- [x] HTTPS、SSH、`ssh://` remote 规范化与 origin/upstream 区分。
- [x] branch、HEAD、dirty、ahead/behind 的只读结果类型。
- [x] 系统 Git/编辑器端口的 Fake，允许不启动子进程测试 UI/Controller。
- [x] 明确禁止 UI 直接拼 shell 命令，并有静态边界测试。

### Gate 4：统一 ViewState / Controller

- [x] `UnifiedRepoController` 仅依赖纯 Dart GitHub/Workspace 端口。
- [x] `WorkbenchViewState` 覆盖 local snapshot、syncing、fresh、stale、offline、permission denied、rate limited 和 failure。
- [x] 刷新失败保留最后成功数据。
- [ ] 轮询间隔、退避与取消由应用层集中控制，不放入 Widget。
- [ ] 用 Fake Gateway/Workspace 建立一组可重复 Demo fixture。

### Gate 5：UI 范围和兼容路由固定

- [ ] 确定桌面三栏/双栏与移动折叠的信息结构，不先确定全站视觉皮肤。
- [ ] 新 Workbench 使用独立路由，不删除现有移动 Repository 页面。
- [ ] 定义需持久化的标签、选中对象、滚动位置、过滤条件和面板尺寸。
- [x] 当前累计 worktree 已完成提交前范围、生成文件、敏感文件、临时产物和文档合并审阅；用户授权后建立本地功能检查点 `6916f32a`，未 push。

## 7. Now / Next / Later

### Now

1. 在真实登录态 Linux/Android 复核 Notifications 的路由可见、app hidden/paused/resumed、
   账号切换和 `X-Poll-Interval` 请求记录；自动合同已闭环，但不代替真实平台时序。
2. 在 Repository 和 Home/Profile 仓库卡片同时可达时人工复核 Star 乐观切换、刷新对账、中英反馈与账号切换；
   自动合同已证明不会因卡片写操作启动完整 Repository Provider。
3. 在真实登录态人工复核全局 All issues / All pull requests / All repositories 的首屏、连续翻页、
   Open/Closed 返回、文字筛选、新建流程和抽屉选中态；自动请求次数测试不能替代真实限流与数据规模。
4. 在真实登录态 Linux/Android 复核 Notifications：360/800px 分类面板、1440px 侧栏、账户加载/失败/
   未登录/已登录切换、Saved/Done 能力提示及真实长标题；Widget Test 不替代最终字形和触控验收。
5. 在真实 Linux/Android 进程人工复核 Settings 的 360/800/1440 视觉、紧凑账户上下文、语言/主题切换、重启恢复与
   账户菜单深链；自动 Widget Test 不能替代平台持久化和最终视觉验收。
6. 人工复核 Repository Issues/PR 首个分页试点的真实大仓库连续翻页、Open/Closed、刷新失败、
   返回滚动与账号切换；自动测试不能替代真实网络验收。
7. 人工审阅 ResourceRuntime 3.3 的社区文档身份、双 consumer Lease 与 mutation 精确失效 diff；
   自动验证已完成，但尚未建立 Profile/Release 性能基线。
8. 在 360px 真实字形下核对 Repository 身份/操作顺序、长 `owner/repository` 和真实 Public/Private/
   Archived/fork，再核对 Code 的 CONTRIBUTING / SECURITY 及其余主 Tab；没有操作证据前不扩大页面或性能完成结论。
9. 下一次提交前按 TD-023 将已收敛 hunk 拆成可独立验证的功能簇；顶层公开文档按
   TD-024 单独审阅/提交，`PrivacyPolicy.md` 虽已与当前默认行为对照，未经项目所有者批准前仍不作为发布就绪文本。

### Next

1. 在现有 forward page 试点上设计有界 Controller 页窗口、距离式预取与 mutation 精确失效；
   在实体保留量证据前不扩散到其他列表。
2. 在现有 RepositoryPreview/稳定外壳之上，将完整 `repo_info` 查询拆为 Code baseline + 区域惰性
   Provider；优先移出 6 组 Issues/PR 快捷计数及 Releases/Languages。
3. 迁移 Issue/PR 详情摘要、评论/Review 时间线、commits/files 的页资源；先消除全量 review threads，
   再在已复用的 PR patch Runtime 页上建立 path index，避免首次目标查找仍线性扫描。
4. 单独审计 License 与 Wiki 的数据身份、分支语义和失效合同；不能为了统一表面 API 吞掉领域差异。

### Later

1. 依赖与代码生成精简，详见 `docs/technology-simplification.md`。
2. `diohub_models` 纯 Dart 化。
3. GraphQL 生成体积和 `copyWith` 策略优化。
4. 在代表性 Profile/Release trace 证明短生命周期 isolate 启动成本是瓶颈后，再评估常驻 worker pool。
5. AI、Premium、Shorebird 与非 MVP 功能的插件化/取舍。
6. 全局 UI 视觉统一、高级动画和更多平台发布。

## 8. 当前非目标

- 不替换 Flutter、Riverpod、Dio、Drift 或 AutoRoute。
- 不在 UI 前全量精简依赖。
- 不重写全部 DioHub 页面。
- 不扩大 OAuth scope，不更改 token 存储模型。
- 不在 MVP 中实现完整 Git GUI。
- 不自动 checkout、fetch、切分支、merge、rebase 或丢弃本地修改。
- 不删除现有移动 UI。

## 9. 低内存执行约束

- 同一时间只运行一个 analyze/test/build 任务。
- Android、Windows、macOS、Linux 平台构建任务绝不并发。
- 单元测试优先使用纯 Dart，并设置 `--concurrency=1`。
- Gradle 需限制 worker/堆大小，完成后停止本项目 daemon。
- 在 Swap 耗尽或可用内存过低时，不启动 Flutter/Gradle 全量构建。
- codegen 只在 schema/model 变化时执行，不作为每个小步骤的例行验证。

## 10. 停止条件

出现以下任一情况时，当前小步骤应停止并先汇报：

- 新边界需要修改 OAuth scope、Client ID/Secret 或签名配置。
- 需要执行 Git 写操作或修改用户工作区。
- 必须更换状态管理、路由或数据库才能继续。
- 新 Workbench 代码导致现有 Android 构建或移动路由回归。
- 系统可用内存/Swap 不足以安全执行验证。
- 当前改动超出单个可审查边界。

## 11. 下一个唯一建议

下一步唯一建议是先运行当前生产入口，人工核对全局 All issues / All pull requests /
All repositories 在真实账号下的三档布局、连续翻页、Open→Closed→Open、文字筛选、仓库跳转和
新建 Issue/PR。自动回归已经证明请求次数与响应式结构，但不能替代真实数据规模、限流和最终视觉；
通过后再决定先做全局 Issues/PR 最小字段投影，还是为纯贡献仓库设计 FanOut 合同。
