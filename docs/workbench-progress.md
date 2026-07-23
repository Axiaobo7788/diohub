# DioHub Workbench 项目进度

最后更新：2026-07-23

当前阶段：Phase 1 进行中（Workbench 边界已建立，GitHub 式 Repository Code、Issues/Pull requests 列表、Actions、Projects、Wiki、Security、Insights、共享 App Chrome、Device Flow、登录前后统一主页与新 UI i18n/Motion 基线已落地）

UI 状态：应用无账号时也直接进入 MD3 主页，登录前后共用 GitHub Dashboard 式响应式信息架构；Home 与 Repository 已真正共用同一套 `AppChrome` 顶栏、导航抽屉和账户菜单，Repository 只追加自己的二级 Tab；登录后已接入真实 Top repositories、Events Feed 和官方 GitHub Changelog；Repository 的 Code、Issues、Pull requests、Actions、Projects、Wiki、Security、Insights 均已接入同一稳定外壳及正式数据源，公开访客也可通过无 Token REST 搜索浏览 Issues/PR 列表；Issue/PR 详情路由已接入同一全局与仓库上下文外壳，但标题、正文、评论时间线、Review/Checks 仍复用旧内容层，不能称为详情页迁移完成；新页面支持跟随系统 / English / 简体中文与集中 Reduced Motion；Home 打开 Repository 时已使用轻量预览预热，Notifications/Bookmarks、公开访客 Code、Issue/PR 详情内容层迁移和可解释推荐尚待完成

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
| 本轮检查点 | Included | Repository MD3 UI、Device Flow、统一主页/Events Feed、公共浏览、测试与文档 |
| Flutter | 3.44.7 | Dart 3.12.2 |
| Android SDK | Passed | SDK 36.1、Build Tools 36.1、NDK 28.2、JDK 21，licenses 已接受 |
| Linux 系统依赖 | Simplified | 认证已移除 `flutter_inappwebview`/WPE 依赖；剩余 `webview_flutter` 为 HTML 渲染的 Android/macOS 间接依赖 |
| Android Debug | Passed, needs latest rerun | 早先已生成 `app-dev-debug.apk`；统一主页变更后待低并发复验 |
| Linux Debug | Passed | 2026-07-23 使用 `CMAKE_BUILD_PARALLEL_LEVEL=2 NINJAFLAGS=-j2 flutter build linux --debug --no-pub` 低并发复验成功，生成 `build/linux/x64/debug/bundle/diohub` |
| Linux runtime smoke | Repository tabs rendered, existing platform errors remain | 2026-07-23 实际 `flutter run -d linux --debug`，从 Home 进入真实仓库并人工点击 Code、Actions、Projects、Security、Insights；工作流、ProjectsV2、SECURITY 检测、扫描告警、提交参与度和语言数据均返回真实状态。日志仍复现既有 Linux `flutter_display_mode` 缺插件、通知初始化缺 Linux settings、Watcher state 外键失败；本轮未把这些非 UI 问题静默算作通过 |
| Windows Debug | Not locally verified | 共用 Dart/Flutter UI 和 Device Flow；需 Windows runner 实机构建 |
| macOS Debug | Not locally verified | 共用 Dart/Flutter UI 和 Device Flow；Pod 锁已清理，需 macOS + CocoaPods 实机构建 |
| Root tests | Passed | 2026-07-23 使用 `flutter test --no-pub --concurrency=1 --reporter compact` 单并发全套 227/227 通过；包含 Pagination SWR、Repository Tab/Wiki、Actions/Projects/Security/Insights、类型化深链、共享详情外壳、页面/Tab/查询 Reduced Motion、Issue/PR 四会话 LRU、文字缩放及公开访客 Issues/PR REST 回归 |
| Unified home tests | Passed | 360px 未登录/已登录、800px、1440px、1.3×/2× 文字缩放、中文、未登录语言入口、左右展开态、Changelog 失败重试及滚动预加载 Widget Test 共 17/17 通过 |
| Events 空仓库回归 | Passed | 真实 `repo: {}` ForkEvent 的解析、fork 目标降级展示数据、三级分组键与仓库专用消费者保护共 4/4 通过 |
| Dashboard data tests | Passed | Top repositories 主源/兼容回退/账户隔离与 Changelog 请求/解析/官方链接限制共 11/11 通过 |
| Repository shell tests | Passed | 开启 semantics 后的 360px、800px、1440px 响应式与简中外壳 Widget Test 4/4 通过 |
| i18n + Home + Repository target tests | Passed | 2026-07-23 使用 `--concurrency=1` 串行验证 39/39；覆盖持久化、未登录语言入口、中英主页、Repository preview/文档数据层与稳定 loading 外壳 |
| Home + Repository current target tests | Passed | 2026-07-23 使用 `--no-pub --concurrency=1` 串行复验 54/54；覆盖共享顶栏/抽屉、360/800/1440px Code/Issues/PR/Wiki、1.3×/2× 文字缩放、加载/空/错误、SWR 刷新失败重试、查询变化清除旧结果、生产 Repository 外壳认证三态、已访问 Tab 状态/滚动保持、共享详情外壳和 Reduced Motion |
| Repository README regression | Passed | 36 个标题 + 28 个长代码块，semantics/滚动/无界 sliver 回归通过；Repository 路径不再构建 `MultiSliver` 或完整 `AppCodeEditor` |
| Flutter error pipeline | Simplified | 删除 `FlutterError -> Talker -> Zone -> PlatformDispatcher` 重复上报与全局 sliver `ErrorWidget` 替换，恢复 Flutter/Sentry 单一框架错误路径 |
| Public REST tests | Passed | 仓库搜索、目录排序/路径编码、文本/二进制判定、Issues/PR 搜索分页与本地化限流提示共 5/5 通过 |
| Public Repository target tests | Passed | l10n、Public REST、Repository Issues/PR 与生产 guest shell 共 31/31 通过；覆盖真实 REST 行、无 GraphQL、刷新/错误/搜索、360px/800px/1440px 及 1.3×/2× 文字缩放 |
| Repository secondary tabs target tests | Passed | Actions/Projects/Security/Insights 局部导航、360px/800px/1440px 登录边界、2× 文字、Reduced Motion、真实 Insights 比例图、SECURITY 文档候选路径及四类类型化深链共 18/18 通过 |
| Changed-code analyze | No new error/warning | Motion、Repository/Wiki、Issue/PR 外壳此前定向分析为 0 error / 0 warning；本轮新增的 Actions/Projects/Security/Insights、深链及测试共 17 个文件再次定向分析为 0 error / 0 warning。全仓仍有大量旧 warning/info；Flutter 3.44.7 的 `flutter analyze --no-pub` 仍在扫描前将 LSP 初始化 JSON 截断于第 352 字符并以 255 退出 |
| Repository loading/motion follow-up | Passed | 2026-07-23 已在当前环境串行运行：Repository Issues/PR 20/20、Search 默认状态 8/8、相关 Home/Repository/Tab 26/26，并在修复 README 测试容器依赖后完成全仓 227/227。覆盖路由/Tab/查询 Reduced Motion、README 留白、图片软失败、Open→Closed→Open 会话复用、四会话 LRU、五行响应式 Shimmer 和“返回列表无骨架/无新请求” |
| Format check | Existing baseline fails | `dart format --output=none --set-exit-if-changed .` 只读检查发现上游、依赖快照与生成文件共 1166 个既有格式差异并返回 1；命令没有改写工作区，本轮触及 Dart 文件此前已定向 format |
| Workbench tests | Passed | 17/17 纯 Dart 契约/边界测试通过 |
| Workbench analyze | Passed | `lib/workbench` 和 `test/workbench` 均为 0 issues |

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
- Notifications、Bookmarks 等账号能力尚未迁入新的原生内容页；账户菜单中的 Copilot settings、Feature preview、Appearance、Accessibility、Enterprise 等暂为明确的阶段入口。
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
- README 图片分类只发起一次网络请求并直接复用返回的 SVG/栅格 bytes；同 URL 由 Riverpod 合并并在离屏后有界保留 1 分钟，连接/接收超时分别为 6/12 秒。网络失败降级为局部可重试图标，不再把可选图片超时上抛为 Provider 失败，也不让图片错误替换整个 README。
- 右栏使用既有 `RepoInfo` 展示 About、Releases、Sponsor 和 Languages；Contributors 改用独立、轻量的真实 REST 摘要 provider，与文件表和完整 Repository 查询互不阻塞。
- 根目录不再重复显示仓库名面包屑；桌面 Code/About 比例收紧到接近网页的主内容布局，最新 Commit 与文件列表合并为同一个描边区域，README 页签与正文合并为一个文档区域。
- 文件表在未启用逐路径 Commit 查询时会隐藏 Commit/时间列，不再用“目录”或本地化占位文字伪装服务器没有返回的数据；360px、800px、1440px 均有无横向溢出的结构回归。
- Code、Issues、Pull requests 与 Wiki 使用首次访问才构建的有界保活栈：未访问 Tab 不启动其 Provider/Controller，访问后在同一 Repository 路由内保留筛选、分页、Wiki 页面与滚动状态；不会把页面会话提升为跨仓库全局缓存。
- Issue/PR 默认 Open 查询由 `SearchStateNotifier` 在 Provider 创建时建立，Widget 生命周期不再写 Provider；首次进入只呈现一次真实首屏加载态，不再先显示页面级占位，也不再概率性触发 Riverpod build-time mutation。Repository 主 Tab 保留已访问子树；列表内部再按完整 query 与 SearchType 保留最近四个分页会话，因此 Open→Closed→Open 会直接恢复旧列表和滚动状态，不显示骨架、不发第三次请求。第五个不同查询会按 LRU 淘汰最旧会话；显式刷新仍只刷新当前查询。
- Actions、Projects、Security 与 Insights 已移除阶段占位并接入共享仓库外壳；它们首次访问才启动自己的工作流、ProjectsV2、安全告警或统计数据，不再由 Code 首帧预取。

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
- 默认 Open 预设在 `SearchStateNotifier.build()` 构造初始状态时完成，不再依赖页面 `initState`、`didUpdateWidget` 或 post-frame 写入；搜索输入使用真实 300ms 防抖，提交时立即应用，外部状态变化不会覆盖尚未提交的输入。
- 用户在默认 `is:open` 上输入 `is:closed` 或其他同键限定词时会原子替换旧值，不再生成互相冲突的查询；普通文本保留现有筛选，同一次输入的多值标签仍可并存。
- 加载、空数据、错误、重试、下拉刷新和接近列表末端自动加载下一页均有明确状态。首屏加载使用五行、接近真实 Issue/PR 行结构的响应式 Shimmer，而不是单个空白占位。手动刷新会隔离旧请求 epoch、保留已提交列表直到新首页成功后原子替换；失败时旧列表仍可阅读，连续刷新会合并，重试从空 cursor 开始。搜索条件或结果类型改变时激活独立查询会话，不会在新筛选下展示旧结果；最近四个查询可直接恢复，超过容量后最旧会话被释放。
- Repository 顶栏刷新会按当前 Tab 刷新 Code、Issues 或 Pull requests；Tab 内容在索引变化时立即切换，不等待动画结束后再整页替换。
- 登录后新建按钮进入既有 `NewIssueRoute` / `NewPullRequestRoute`，列表项进入既有原生详情路由；未登录使用相同搜索、状态、刷新、空/错误、分页与行组件，但数据改由既有无会话 `RESTHandler` 请求 `/search/issues`，不创建 Search GraphQL、Account 或 Token。
- 未登录写操作与需要账号元数据的高级筛选仍进入明确登录流程；在原生详情迁移完成前，公开列表项打开 GitHub 返回的真实网页 URL，不伪装为已完成的访客原生详情。
- 公开 REST 只增加传输边界摘要，并立即映射为共用的 `RepositoryIssuePullRowData`；登录态继续消费现有 `IssueOrPull`，没有建立第二套列表状态机、分页或页面外壳。
- 360px、800px、1440px 的 Issues/PR 结构、长标题、加载/空/错误/刷新、搜索防抖和访客 REST/no-GraphQL 已有 Widget Test；800px/1.3× 与 360px/2× 文字缩放会按可用宽度重排工具栏，不再横向溢出；新增筛选和公共 API 限流客户端文案已进入 `gen_l10n`，标签、分支、账号、Issue/PR 标题保持原文。

尚未完成：

- Issue/PR 详情路由现在使用共用 `AppChrome`、仓库面包屑、Repository Tab 和稳定加载/错误外壳，并移除了嵌套的第二层 `Scaffold` / `SafeArea`；但详情标题、正文、评论时间线、Review/Checks 和新建表单仍是旧内容 UI。本节只完成列表与详情外壳迁移，不能据此声称 Issues/PR 全功能迁移完成。
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

- Home、Repository、Wiki、Issue 详情和 Pull request 详情路由统一使用 240ms 前进/220ms 返回、16 逻辑像素的淡入横向位移；不再按屏幕比例让手机位移缩到难以辨认。Repository 主 Tab 在保活栈之上使用 180ms、最多 8 逻辑像素的左右方向过渡，不替换或重建目标页面。
- `MediaQuery.disableAnimations` 为真时，路由、Repository 内容切换、旧详情 Tab、Wiki 标题、异步状态与 Shimmer 均立即切换或静态显示，不由组件自行反转平台设置。
- 只迁移已经重写或本轮触及的视觉时序；搜索防抖、网络轮询、Toast 等业务时序不做机械替换。
- 本轮验证的是时序和无动画语义，不是 Profile 帧性能；未提供“更流畅”或“性能已解决”的测量结论。

## 3.6 i18n 边界

- 应用使用 Flutter 官方 `flutter_localizations` / `gen_l10n` / ARB，不引入第二套翻译框架。
- 当前支持跟随系统、English 和简体中文；不在 Widget 内按语言写 `if/switch`。
- 新 UI 的所有新增客户端文案必须先进 ARB；旧 UI 在页面迁移时逐步本地化，不为追求数量一次性修改 200+ 个旧文件。
- API/用户内容、仓库名、分支名、README、Issue/PR 正文不自动翻译；时间、空状态、错误和操作标签由客户端本地化。
- 新语言必须同时补齐 ARB key parity、语言选择项、持久化往返和至少一个页面 Widget Test。

## 3.7 本轮需求—实现—验证映射

| 需求 | 实现 | 状态 | 验证 |
| --- | --- | --- | --- |
| Home/Repository 刷新不能因“有功能”而闪空或丢失旧数据 | 公共 `PaginationController` 默认使用 SWR，成功后原子替换；刷新失败保留旧内容并提供 refresh-aware retry | 已满足，待 Git 检查点 | controller 4/4、Sliver 2/2、全仓 227/227 |
| Repository Tab 首次进入不应预取无关页面，返回时不能丢失会话 | 未访问 Tab 为占位；首次访问后在当前路由的有界 `IndexedStack` 中保留 Code/Issues/PR/Wiki 子树 | 已满足，待 Git 检查点 | no-build、搜索输入、Wiki 页面和 360px/2× 滚动保持 Widget Test |
| Repository 跳转和左右 Tab 切换必须可感知且不以动画伪装重载 | 路由使用固定 16px 位移；Tab 对保活栈施加方向化 8px/轻淡入，Reduced Motion 直接返回原子树；Issue/PR 去除额外初始化占位帧 | 实现完成，真实运行待用户验收 | page/tab/reduced-motion 与返回无骨架断言已在目标 Widget Test 通过 |
| Issue/PR 的 Open/Closed 往返不能重复首屏加载或在 build 中写 Provider | Provider 构造默认 Open；每页按 query + 类型保留最近四个独立分页会话，缓存命中使用 180ms 轻淡入且不重取；Reduced Motion 为零时长 | 已满足，待真实运行复验 | Issue/PR 20/20、Search Provider 8/8；两类列表均证明 Open→Closed→Open 仅两次请求，LRU 淘汰边界已覆盖 |
| README 不贴边且可选图片失败不得破坏文档 | 文档正文使用 16/24px 响应式内边距；图片分类结果 bytes 直接渲染、1 分钟有界缓存、6/12 秒超时、局部重试软失败 | 实现完成，目标测试已复验 | 三档 padding、bytes 渲染、失败软化与缓存命中目标测试通过 |
| 平台 Reduced Motion 不得被应用设置反向覆盖 | 根级 `AppMotionMediaQuery` 对应用与平台值取逻辑 OR | 已满足，待 Git 检查点 | 3 种组合 3/3，通过全仓回归 |
| Home/Repository 在文字放大时仍可用 | Home 快捷操作允许标签弹性换行；Issues/PR 工具栏断点同时考虑可用宽度与 text scale | 已满足当前基线 | 1.0 的 360/800/1440、1.3× 的 800、2× 的 360；全仓 227/227 |
| 不因本轮性能讨论扩散业务层 | 未修改 GraphQL、codegen、路由、认证、数据库或核心模型；仅在获批的访客浏览边界增加 Public REST 传输摘要与 adapter；TD-006/007 保持待 Profile/专项任务 | 已登记未处理 | Git diff 复核；没有新增核心 API、全局 Provider 或第二套页面状态模型 |
| 证明首页到仓库“更快” | 本轮只消除视觉闪空和重复构造，不将 Widget Test 解释为帧性能结论 | 待验证 | 仍需 Linux/Android Profile 的冷/暖导航 trace |
| 未登录公开 Repository Issues/PR 可读 | 复用公共 RESTHandler、SearchState、PaginationController 与 MD3 行；REST 摘要只作为传输 DTO，未创建账号或 Token | 已满足列表范围 | 公开 REST 5/5、全仓 227/227；生产 guest shell 证明无 Repository/Search GraphQL |
| Repository Wiki 必须是可验证的真实页面而非占位 | 共用既有 Wiki provider/controller，接入同一 Repository Tab 与深链；页面列表、正文、状态与外部入口均消费真实参数 | 已满足只读浏览范围 | Wiki 6/6、目标回归 54/54、全仓 227/227 |
| Repository 未完成 Tab 不能继续保留阶段占位 | Actions/Projects/Security/Insights 接入各自既有正式 Service/Provider、共享局部页面壳、类型化深链及完整状态；网页没有公开等价数据的管理子页明确留在未完成边界 | 已满足四个主 Tab 的只读浏览范围 | 二级标签页目标回归 18/18；Linux Debug 真实仓库逐页截图；全仓 227/227 |
| Issue/PR 详情不得再次出现第二套全局顶栏和嵌套页面壳 | 详情路由接入 `RepositoryContextChrome`，旧详情内容以 embedded 模式复用，移除嵌套 `Scaffold`/`SafeArea` | 已满足外壳范围，内容迁移未完成 | 共用外壳 4/4、详情 Tab Motion 2/2、全仓 227/227 |
| 本轮 Profile 性能 | 用户明确允许暂不测试；没有以 Debug 观感或 Widget Test 代替测量 | 待验证 | 未运行，不提供帧时间或“已优化”结论 |

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
- [ ] 对当前 60+ 项 worktree 变更做一次人工审阅；是否建立 Git 检查点由用户授权。

## 7. Now / Next / Later

### Now

1. 人工核对已完成的 Repository Code/Issues/Pull requests/Actions/Projects/Wiki/Security/Insights，以及本轮路由/左右 Tab 动效、README 留白和图片失败重试；仍需用户确认最终信息密度与动效强度。
2. 在当前真实 `flutter run` 会话中复验 Issues 与 Pull requests 的 Open→Closed→Open：缓存返回应保留列表/滚动、不出现五行首屏骨架、不新增第三次搜索请求，也不得再出现 Riverpod build-time mutation 红屏。
3. 迁移 Issue 详情的标题/状态/正文/评论时间线为 MD3 内容层，同时继续复用现有 Provider、评论与 mutation；不得把已经完成的共享外壳重复实现一遍。
4. Issue 详情验收后，再以相同外壳迁移 Pull request 标题/状态/时间线，并单独保留 Review、Checks 与 Files changed 的领域状态。
5. 在已完成访客 Issues/PR 列表的基础上，将公开 Repository Code 接入同一稳定外壳；复用现有公共目录/文件 REST 能力，不伪造完整 `RepoInfo`。

### Next

1. 在现有 RepositoryPreview/稳定外壳之上，将完整 `repo_info` 查询拆为 Code baseline + 区域惰性 provider，并增加 stale-while-revalidate；优先移出 6 组 Issues/PR 快捷计数及 Releases/Languages。
2. 固定 Workbench 桌面三栏/双栏与移动折叠信息结构，建立独立路由的 Fake 功能性 UI 骨架。
3. 建立类型化 Drift 快照与 schema 版本，完成 PR Review 概览与自适应 Workflow 轮询。
4. 打通 Repository → Local Repo → HEAD → PR → Actions → Editor 真实纵向演示。
5. 审阅当前基线 diff，决定是否建立本地 Git 检查点。

### Later

1. 依赖与代码生成精简，详见 `docs/technology-simplification.md`。
2. `diohub_models` 纯 Dart 化。
3. GraphQL 生成体积和 `copyWith` 策略优化。
4. AI、Premium、Shorebird 与非 MVP 功能的插件化/取舍。
5. 全局 UI 视觉统一、高级动画和更多平台发布。

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

下一步唯一建议是迁移 Issue 详情内容层：保持已经完成的 `RepositoryContextChrome` 不动，逐段替换标题/状态、正文与评论时间线，并为加载、错误、空评论、刷新、360/800/1440px 和 Reduced Motion 建立回归；完成并人工验收后再开始 Pull request 的 Review/Checks/Files changed。
