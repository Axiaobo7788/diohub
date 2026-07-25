# DioHub Workbench 项目进度

最后更新：2026-07-24

当前阶段：Phase 1 进行中（Workbench 边界已建立，纯 Dart ResourceRuntime 第三阶段、Repository Code 文档/图片及 Issues/PR forward page 首个生产试点已落地；主要信息流全局接入清单与复用模板已建立；GitHub 式 Home、Repository 主标签、Profile Overview、共享 App Chrome、Device Flow 与新 UI i18n/Motion 基线已落地）

UI 状态：应用无账号时也直接进入 MD3 主页，登录前后共用 GitHub Dashboard 式响应式信息架构；Home、Repository 与 Profile 主入口真正共用同一套 `AppChrome` 顶栏、导航抽屉和账户菜单，页面只追加自己的二级 Tab；Profile Overview 已接入真实身份字段、Profile README、Pinned repositories、贡献日历与活动时间线，Repositories/Projects/Packages/Stars 继续复用已有正式分页列表并在同一路由内保活，但这些列表的 GitHub 网页式视觉尚未逐页迁移；Repository 的 Code、Issues、Pull requests、Actions、Projects、Wiki、Security、Insights 均已接入同一稳定外壳及正式数据源；Issue/PR 详情内容层仍未完成；新页面支持跟随系统 / English / 简体中文与集中 Reduced Motion；Notifications/Bookmarks、公开访客 Code、Profile 次级列表视觉迁移、Issue/PR 详情内容层和可解释推荐尚待完成

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
| Android Debug | Previous artifact only; current rerun stopped for memory safety | 2026-07-24 以单 worker、2 GiB Gradle 堆重跑；Kotlin 仍启动独立约 2 GiB daemon，338 秒后 Swap 耗尽且可用内存降至约 1.6 GiB，按低内存停止条件主动中止并停止 daemon。`app-dev-debug.apk` 仍是 2026-07-21 旧产物，不能作为当前工作区验证 |
| Linux Debug | Passed | 2026-07-24 ResourceRuntime 3.3 社区文档迁移后再次使用 `flutter build linux --debug --no-pub` 串行复验成功，生成 `build/linux/x64/debug/bundle/diohub` |
| Linux runtime smoke | Repository tabs rendered, existing platform errors remain | 2026-07-23 实际 `flutter run -d linux --debug`，从 Home 进入真实仓库并人工点击 Code、Actions、Projects、Security、Insights；工作流、ProjectsV2、SECURITY 检测、扫描告警、提交参与度和语言数据均返回真实状态。日志仍复现既有 Linux `flutter_display_mode` 缺插件、通知初始化缺 Linux settings、Watcher state 外键失败；本轮未把这些非 UI 问题静默算作通过 |
| Windows Debug | Not locally verified | 共用 Dart/Flutter UI 和 Device Flow；需 Windows runner 实机构建 |
| macOS Debug | Not locally verified | 共用 Dart/Flutter UI 和 Device Flow；Pod 锁已清理，需 macOS + CocoaPods 实机构建 |
| Root tests | Passed | 2026-07-24 使用 `flutter test --no-pub --concurrency=1` 单并发全套 294/294 通过；包含 ResourceRuntime 调度/真实 worker/依赖 revision/递归依赖租约保护/预取准入取消与即时预算、Code 全目录/README/CONTRIBUTING/SECURITY artifact、README 图片 8 MiB 容量与 bytes 身份/账号切换隔离、Profile MD3、Pagination SWR、Repository Tab/Wiki、Actions/Projects/Security/Insights、类型化深链、共享详情外壳、Reduced Motion、Issue/PR 四会话 LRU、文字缩放及公开访客 Issues/PR REST 回归 |
| Unified home tests | Passed | 360px 未登录/已登录、800px、1440px、1.3×/2× 文字缩放、中文、未登录语言入口、左右展开态、Changelog 失败重试及滚动预加载 Widget Test 共 17/17 通过 |
| Events 空仓库回归 | Passed | 真实 `repo: {}` ForkEvent 的解析、fork 目标降级展示数据、三级分组键与仓库专用消费者保护共 4/4 通过 |
| Dashboard data tests | Passed | Top repositories 主源/兼容回退/账户隔离与 Changelog 请求/解析/官方链接限制共 11/11 通过 |
| Repository shell tests | Passed | 开启 semantics 后的 360px、800px、1440px 响应式与简中外壳 Widget Test 4/4 通过 |
| i18n + Home + Repository target tests | Passed | 2026-07-23 使用 `--concurrency=1` 串行验证 39/39；覆盖持久化、未登录语言入口、中英主页、Repository preview/文档数据层与稳定 loading 外壳 |
| Home + Repository current target tests | Passed | 2026-07-23 使用 `--no-pub --concurrency=1` 串行复验 54/54；覆盖共享顶栏/抽屉、360/800/1440px Code/Issues/PR/Wiki、1.3×/2× 文字缩放、加载/空/错误、SWR 刷新失败重试、查询变化清除旧结果、生产 Repository 外壳认证三态、已访问 Tab 状态/滚动保持、共享详情外壳和 Reduced Motion |
| Repository README regression | Passed | 36 个标题 + 28 个长代码块的 semantics/滚动/无界 sliver 回归通过；根 README 正式入口消费 Runtime artifact，fresh/retained 返回不重复请求或顶层解析，三档 Code 布局仍通过 |
| Flutter error pipeline | Simplified | 删除 `FlutterError -> Talker -> Zone -> PlatformDispatcher` 重复上报与全局 sliver `ErrorWidget` 替换，恢复 Flutter/Sentry 单一框架错误路径 |
| Public REST tests | Passed | 仓库搜索、目录排序/路径编码、文本/二进制判定、Issues/PR 搜索分页与本地化限流提示共 5/5 通过 |
| Public Repository target tests | Passed | l10n、Public REST、Repository Issues/PR 与生产 guest shell 共 31/31 通过；覆盖真实 REST 行、无 GraphQL、刷新/错误/搜索、360px/800px/1440px 及 1.3×/2× 文字缩放 |
| Repository secondary tabs target tests | Passed | Actions/Projects/Security/Insights 局部导航、360px/800px/1440px 登录边界、2× 文字、Reduced Motion、真实 Insights 比例图、SECURITY 文档候选路径及四类类型化深链共 18/18 通过 |
| Profile MD3 target tests | Passed | 生产 Profile 主入口、360px/800px/1440px、360px 2× 文字、简中、真实 Pinned fixture、稳定 loading/error、共享抽屉及主/旧路径边界共 10/10 通过 |
| Changed-code analyze | No error/warning in targeted paths | Profile MD3、ResourceRuntime、Markdown artifact/图片、目录/README/社区文档 adapter、共享顶栏、路由、通用 TabBody 和测试定向分析未报告 error/warning；ResourceRuntime 3.3 的 12 个生产/测试路径定向分析为 0 error、0 warning、157 条严格 lint info，未把全仓 lint 清理混入资源任务。Flutter 3.44.7 的 `flutter analyze --no-pub` 仍在扫描前将 LSP 初始化 JSON 截断于第 353 字符并以 255 退出；可完成的全仓 `dart analyze --format=machine` 为 0 error、704 warning、17735 info |
| Repository loading/motion follow-up | Passed | 2026-07-23 已在当前环境串行运行：Repository Issues/PR 20/20、Search 默认状态 8/8、相关 Home/Repository/Tab 26/26，并在修复 README 测试容器依赖后完成全仓 237/237。覆盖路由/Tab/查询 Reduced Motion、README 留白、图片软失败、Open→Closed→Open 会话复用、四会话 LRU、五行响应式 Shimmer 和“返回列表无骨架/无新请求” |
| Format check | Existing baseline fails | 2026-07-24 的 `dart format --output=none --set-exit-if-changed .` 只读检查扫描 2196 个文件，其中 1155 个存在既有格式差异并返回 1；命令没有改写工作区，本轮触及 Dart 文件已定向 format |
| Workbench tests | Passed | 17/17 纯 Dart 契约/边界测试通过 |
| Workbench analyze | Passed | `lib/workbench` 和 `test/workbench` 均为 0 issues |
| ResourceRuntime target tests | Passed | 2026-07-24 原第三阶段 69/69；分页通用 source 当前 5/5、Repository 正式入口 4/4。覆盖页 Single Flight、fresh/stale 复用与后台替换、显式下一页、刷新失败保留旧项、Open→Closed→Open、REST transport 与账号 scope；尚无 Profile/Release 结论 |
| ResourceRuntime changed-code analyze | No error/warning in targeted paths | 3.3 的生产 Provider、resource spec、Service、Code/Security 正式消费者、mutation 失效及回归测试共 12 个路径定向 `dart analyze` 为 0 error、0 warning、157 info；全仓 `dart analyze --format=machine` 为 0 error、704 个既有 warning 和 17735 info |
| Issues/PR Runtime performance follow-up | Target tests passed; live Profile pending | 2026-07-24 定向 43/43：登录列表改用轻量 GraphQL 投影，Runtime stale 首页立即回显并后台替换，隐藏 Tab sentinel 为 0 请求，Repository Tab 使用独立 Material 边界；定向 `dart analyze` 为 0 error、0 warning（179 个严格 lint info）。`flutter analyze` 仍因 analysis server LSP JSON 截断以 255 退出；未运行全仓测试、build 或 Profile，不能声称真实耗时已经达标 |

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
| Home/Repository 刷新不能因“有功能”而闪空或丢失旧数据 | 公共 `PaginationController` 默认使用 SWR，成功后原子替换；刷新失败保留旧内容并提供 refresh-aware retry | 已满足，待 Git 检查点 | controller 4/4、Sliver 2/2、全仓 237/237 |
| Repository Tab 首次进入不应预取无关页面，返回时不能丢失会话 | 未访问 Tab 为占位；首次访问后在当前路由的有界 `IndexedStack` 中保留 Code/Issues/PR/Wiki 子树 | 已满足，待 Git 检查点 | no-build、搜索输入、Wiki 页面和 360px/2× 滚动保持 Widget Test |
| Repository 跳转和左右 Tab 切换必须可感知且不以动画伪装重载 | 路由使用固定 16px 位移；Tab 对保活栈施加方向化 8px/轻淡入，Reduced Motion 直接返回原子树；Issue/PR 去除额外初始化占位帧 | 实现完成，真实运行待用户验收 | page/tab/reduced-motion 与返回无骨架断言已在目标 Widget Test 通过 |
| Issue/PR 的 Open/Closed 往返不能重复首屏加载或在 build 中写 Provider | Provider 构造默认 Open；每页按 query + 类型保留最近四个独立分页会话，缓存命中使用 180ms 轻淡入且不重取；Reduced Motion 为零时长 | 已满足，待真实运行复验 | Issue/PR 20/20、Search Provider 8/8；两类列表均证明 Open→Closed→Open 仅两次请求，LRU 淘汰边界已覆盖 |
| README 不贴边且可选图片失败不得破坏文档 | 文档正文使用 16/24px 响应式内边距；栅格复用 source bytes 直接渲染、Runtime 有界缓存、6/12 秒超时、局部重试软失败 | 实现完成，目标测试已复验 | 三档 padding、bytes 对象身份/渲染、失败软化与缓存命中目标测试通过 |
| 平台 Reduced Motion 不得被应用设置反向覆盖 | 根级 `AppMotionMediaQuery` 对应用与平台值取逻辑 OR | 已满足，待 Git 检查点 | 3 种组合 3/3，通过全仓回归 |
| Home/Repository 在文字放大时仍可用 | Home 快捷操作允许标签弹性换行；Issues/PR 工具栏断点同时考虑可用宽度与 text scale | 已满足当前基线 | 1.0 的 360/800/1440、1.3× 的 800、2× 的 360；全仓 237/237 |
| 不因本轮性能讨论扩散业务层 | 未修改 GraphQL、codegen、路由、认证、数据库或核心模型；TD-006 保持待 Profile/GraphQL 专项，TD-007 仅推进根 README、CONTRIBUTING、SECURITY 顶层 artifact 与 README 图片原始字节/分类，其余 Markdown/Diff 保持待 Profile/专项任务 | 边界已保持；TD-007 部分推进 | Git diff 复核；没有新增核心 API 或第二套页面状态模型，Runtime Provider 仍是唯一全局控制面 |
| 证明首页到仓库“更快” | 本轮只消除视觉闪空和重复构造，不将 Widget Test 解释为帧性能结论 | 待验证 | 仍需 Linux/Android Profile 的冷/暖导航 trace |
| 未登录公开 Repository Issues/PR 可读 | 复用公共 RESTHandler、SearchState、PaginationController 与 MD3 行；REST 摘要只作为传输 DTO，未创建账号或 Token | 已满足列表范围 | 公开 REST 5/5、全仓 237/237；生产 guest shell 证明无 Repository/Search GraphQL |
| Repository Wiki 必须是可验证的真实页面而非占位 | 共用既有 Wiki provider/controller，接入同一 Repository Tab 与深链；页面列表、正文、状态与外部入口均消费真实参数 | 已满足只读浏览范围 | Wiki 6/6、目标回归 54/54、全仓 237/237 |
| Repository 未完成 Tab 不能继续保留阶段占位 | Actions/Projects/Security/Insights 接入各自既有正式 Service/Provider、共享局部页面壳、类型化深链及完整状态；网页没有公开等价数据的管理子页明确留在未完成边界 | 已满足四个主 Tab 的只读浏览范围 | 二级标签页目标回归 18/18；Linux Debug 真实仓库逐页截图；全仓 237/237 |
| Issue/PR 详情不得再次出现第二套全局顶栏和嵌套页面壳 | 详情路由接入 `RepositoryContextChrome`，旧详情内容以 embedded 模式复用，移除嵌套 `Scaffold`/`SafeArea` | 已满足外壳范围，内容迁移未完成 | 共用外壳 4/4、详情 Tab Motion 2/2、全仓 237/237 |
| Profile 主入口仿照 GitHub 网页且不新建业务层 | 主路径接入共享 `AppChrome`、五项资料导航、真实 `userProvider` / README / Pinned / contributions；既有四类分页列表在惰性保活 Tab 中复用 | Overview 已满足；次级列表仅完成正式接入，视觉迁移未完成 | Profile 10/10；共享 Home/Repository 回归 28/28 |
| 本轮 Profile 性能 | 用户明确允许暂不测试；没有以 Debug 观感或 Widget Test 代替测量 | 待验证 | 未运行，不提供帧时间或“已优化”结论 |
| 统一资源加载、渲染交付和生命周期管理 | 纯 Dart `ResourceRuntime` 控制 identity/scope/lease/freshness/dependency/budget；正式试点迁移 Repository Code 文档/图片及 Issues/PR 不可变 forward page | 控制面与首个分页桥已满足；License、Wiki、Flutter 像素解码、详情分页和有界 Controller 页窗口未迁移 | 原目标 69/69 + 分页当前 9/9；全仓 294/294 是本轮轻量投影与 stale 原位替换前基线 |
| Repository Issues/PR 冷暖列表不应下载详情字段或在隐藏页继续分页 | 同一 Runtime page source 改用轻量 GraphQL 投影；stale 首页立即回显/后台替换；隐藏 sentinel 禁止请求；每个 Repository Tab 使用独立 Material 边界 | 代码与定向回归已满足；真实大仓库 Profile 和当前 Linux Debug 快速切页待验证 | 本轮定向 43/43，0 error/0 warning；未运行全仓、build、Profile |
| 全局整理可能拖长加载的信息流并形成复用模板 | 主要信息流清单按 Integrated/Partial/Wave A/B/C/Excluded 分类；固定 Controller/Runtime page/Service 混合所有权与身份、预算、失效、UI、正/负验证模板 | 设计基线完成；Issues/PR 首个生产试点部分接入 | 静态追踪 67 处 `PaginationController`、25 处定时保活；试点合同见独立文档 |

## 3.8 Profile MD3 第一阶段

已完成：

- `UserProfileRoute` 的 Overview、Repositories、Projects、Packages、Stars 主路径进入新的 Profile MD3 页面；Gists、Organizations、Followers、Keys、Sponsors 等尚未迁移的扩展路径继续走旧页面，不用占位内容冒充完成。
- Profile 复用 Home/Repository 的 `AppChrome`、DioHub 标识、全局搜索、抽屉和账户菜单；窄屏标题空间不足时只保留带语义标签的标识，不再产生 360px 顶栏溢出。
- Overview 使用既有 `userProvider` 及生成类型展示头像、姓名、登录名、状态、简介、关注关系和公开元数据；编辑资料与 Follow/Unfollow 继续复用既有 mutation。
- Profile README、Pinned repositories、贡献日历和贡献活动分别复用已有正式 Provider/组件。贡献加载错误保持局部重试，不替换整张 Profile；Pinned 卡片打开现有 Repository 路由。
- 1440px 使用身份侧栏 + Overview 主列；800px 与 360px 折叠为同一信息架构。Repositories/Projects/Packages/Stars 在窄屏仍保留身份上下文，并复用既有 `TabBody` 分页/刷新生命周期。
- 五个主标签首次访问才创建内容，访问后在当前 Profile 路由的有界 `IndexedStack` 中保留，标签切换使用集中 Motion；Profile 路由使用与 Home/Repository 相同的页面转场。
- 新增客户端文案进入 English / 简体中文 ARB；用户名、简介、仓库名、README 等服务端或用户内容保持原文。

尚未完成：

- Repositories、Projects、Packages、Stars 当前是“正式数据与生命周期已接入”，但列表行、筛选区和空状态仍主要复用旧呈现，不能称为四张网页式页面已经完成。
- 贡献日历与活动时间线继续使用原组件；年份/时间范围控件和 GitHub 网页的完整 Activity 筛选尚未迁移进新 Overview。
- Organizations、Gists、Followers/Following、Sponsors、Keys 等扩展页仍是旧 UI；没有在本轮批量删除。
- 尚未在真实登录态 Linux/Android 运行并截图对比，也未建立 Profile/Release 帧性能与内存基线。

## 3.9 ResourceRuntime 第三阶段

架构边界见 [`resource-runtime-architecture.md`](resource-runtime-architecture.md)。

已完成：

- 建立纯 Dart 类型化资源身份、稳定账号/服务器 scope、Loading/Data/Failure 状态、独立 Lease 与
  visible/retained presence。
- 建立有界 L1、Single Flight、SWR、generation 旧结果隔离、pending revalidate、精确标签失效、
  scope 清理、三档调度、预取接管、LRU/内存 trim、可注入时钟与结构化 Telemetry。
- Runtime 继续作为一个统一控制面，但把 network、compute、decode 放入独立调度 lane；页面不能
  自建调度器，也不能把领域 Service、Widget 或业务模型塞入 Runtime。调度 lane 只控制优先级与
  并发，纯 Dart CPU 变换必须显式调用 `runInWorker()` 才真正离开调用 isolate。
- `ResourceSpec` 可静态声明强类型依赖；derived loader 只能通过 `ResourceLoadContext.require`
  读取已声明的同 scope 依赖。未声明、循环和当前会死锁的同调度 lane 依赖快速失败，source 失效沿
  依赖图级联。
- 应用生命周期通过 Flutter 薄适配器进入 Runtime；账号切换清理上一 scope，既有 `APICache` 继续作为
  L2 transport cache。
- Repository Code 根目录与所有子目录统一迁移：Riverpod 继续作为薄页面适配器，正式 Loader 仍是
  既有 `fetchDirectoryEntries`；目录不再同时使用旧 keep-alive。
- 根 README 拆为既有 `RepositoryServices.fetchReadmeHtml` 网络源与纯 Dart Markdown artifact；
  顶层 HTML 解析、标题提取和 section 切分通过短生命周期 `Isolate.run` worker 完成，artifact 缓存
  headings/惰性 HTML sections，不缓存 Widget/Element/BuildContext。正式 Code 文档卡消费 artifact，
  原链接和 HtmlWidget 展示组件继续复用。
- CONTRIBUTING / SECURITY 拆为既有 `RepositoryDocumentService.fetchHtml()` source 与同一
  `MarkdownRenderArtifact`；Code 文档页签与 Security Tab 持有独立 presence Lease，但相同账号、
  仓库、分支和文档类型共享同一 source/artifact。候选路径全部 404 是可保留的缺失数据，传输失败、
  重试与显式刷新保持独立状态。
- README 图片拆为未认证 source 与分类 artifact：第三方下载使用专用 Dio client，剥离认证/Cookie，
  同时按 header 和流累计执行 8 MiB 上限；SVG/栅格判定进入真实 worker，同 scope/URL Single Flight，
  失败短期负缓存并只显示局部重试。worker 对栅格只返回分类元数据，artifact 直接复用 source 的同一
  份 `Uint8List`，不再跨 isolate 返回第二份 bytes。栅格像素仍由 `Image.memory`/Flutter ImageCache
  解码，SVG 仍由 `jovial_svg` 展示，Runtime 不缓存 `ui.Image`、texture 或 Widget。
- 图片 source/classification 在 Repository Tab 隐藏时继续运行并保留 lease，但 Flutter `Image`
  只在所属 Tab 可见时从最新 artifact 实体化；资源生命周期和 Widget/Sliver 呈现生命周期不再混为
  一层。
- 所有资源使用统一 4 KiB 估算权重；默认约 16 MiB L1 上限、内存压力约 8 MiB trim 目标，至少容纳
  一条合法最大 README 栅格链。普通 LRU 同时保护持有 Lease 的 artifact 及其递归依赖，避免“产物还在、
  source 已被逐出”导致返回后重新下载；多个大 Lease 导致无法立即满足预算时，Telemetry 明确标记
  超预算并报告估算字节，最外层 Lease 释放后再淘汰。
- derived artifact 记录 dependency data revision；依赖显式失效、自然过期、更新或被回收都会使旧
  artifact 失去 fresh 资格，不再只依赖标签级联。
- 预取在策略或生命周期拒绝时不会先创建空的 L1 Loading 条目；获准入队后立即受条目/权重预算约束。
  ticket 与进入后台造成的排队取消只记录 canceled，因预算或淘汰移除的未接管预取才记录 wasted，
  遥测不再对同一任务重复计数。
- 点击一个具有可靠默认分支的 Top repository 时可在导航前预取同一资源；预取和目的页 acquire
  共享同一次请求，不批量预取 Home 卡片。
- Code / Security Tab 由用户事件更新各自页面会话 presence，目录、README 与社区文档 adapter 共同
  监听对应状态；返回 fresh 内容不重取或重做顶层解析，过期后先交付旧对象再刷新。
- 文件创建、编辑或删除成功后按账号、仓库、分支和父目录精确失效；只有根 `README` / `README.*`
  额外失效根 README source；只有精确命中 CONTRIBUTING / SECURITY 现有候选路径才失效对应文档，
  其他分支、账号和无关 Markdown 不受影响。

明确边界：

- License、Wiki、其他 Markdown、Actions、Profile、Home、Repository 主 Provider 与大多数分页
  尚未迁移；Issues/PR 只有列表 forward page 部分接入，详情和有界页窗口仍未迁移。
- README 图片“下载与分类”已经迁移，但 Flutter 像素解码/GPU 上传没有迁移；这两层必须分开报告，
  不能把原始字节进入 Runtime 写成完整图像管线已统一。
- artifact 已避免返回页面时重复执行顶层 `html.parse`、标题遍历与 section 切分；每个惰性
  `HtmlWidget` section 的内部构建/解析及 Diff 同步解析仍未处理，TD-007 仅是 In Progress。
- 导航前没有可靠 immutable tree OID，当前沿用现有分支名语义；外部提交在 2 分钟 fresh 窗口内
  可能读到 L1 旧数据，显式刷新、过期恢复和本地 mutation 会重取。
- 尚未接入可靠网络状态源，也不支持取消已经进入现有网络栈的请求；排队任务可取消，旧完成结果由
  generation 丢弃。worker 当前每次使用短生命周期 `Isolate.run`，尚未建立常驻池，启动成本待
  Profile。
- 本轮没有改写 GraphQL/codegen、认证、数据库、路由、业务模型、Repository 主 mutation 或
  `PaginationController`。

验证：

- 纯 Dart 核心 35/35；Markdown artifact/Sliver 4/4；README 图片 10/10；目录与 README
  Provider/失效 6/6；社区文档 Provider/失效 7/7；社区文档 Service 3/3；Code 正式入口 4/4，
  合计 69/69。请求/解析次数、缺失负缓存、失败重试、跨 scope、in-flight 账号切换、凭证剥离、
  大小上限、递归依赖租约保护、预取拒绝/取消/即时预算、bytes 身份、默认容量及精确失效均有正向
  与负向断言。
- 全仓测试 294/294，Linux Debug build 通过；3.3 的 12 个变更路径定向 analyze 为 0 error、
  0 warning、157 info；本轮触及 Dart 文件均已定向 format。
- 全仓 `flutter analyze --no-pub` 在扫描前因 analysis server LSP JSON 于第 353 字符截断而以 255
  退出，不能声称通过；全仓 format 仍受 1155 个既有差异阻塞。
- Android Debug 本轮因 Kotlin 独立 daemon 导致 Swap 耗尽而主动中止，旧 APK 未被覆盖，当前
  Android 构建状态明确为待低内存环境复验。

## 3.10 ResourceRuntime 3.3（已完成）

精确完成范围：

- CONTRIBUTING / SECURITY 的正式 Loader 继续是 `RepositoryDocumentService.fetchHtml()` 与原候选
  路径；候选列表已集中为 Service 的单一事实源，Runtime 失效复用同一列表。
- source / artifact 身份包含 server/principal scope、仓库、分支、文档类型和版本；继续复用
  `MarkdownRenderArtifact` 与 worker，不新增 API、GraphQL、领域模型或第二套解析缓存。
- `repositoryDocumentProvider` 已改为薄 Runtime adapter。Code 与 Security 使用不同 consumer/
  presence Lease，但相同 SECURITY 身份共享一次 source 与一次解析；auto-dispose 后返回复用 retain
  数据，显式刷新只重取并重建一次。
- Code 正文直接消费 render artifact；Security 卡片消费同一 artifact 中的文档存在性与命中路径。
  404 全部缺失、首次失败、局部重试和加载成功仍是可区分状态。
- Code 全局刷新失效当前分支 README、CONTRIBUTING 与 SECURITY；Security 局部刷新只处理 SECURITY。
  文件 mutation 仅在变更路径精确命中相应候选路径时失效，不清空无关分支、文档或整个仓库缓存。
- Repository 主 Tab 用户事件同时维护 Code/Security presence；没有在 Widget build/init/dispose 等
  生命周期写共享 Provider。

回归证据：

- 先建立失败基线，再完成 7 个社区文档资源回归：双消费者 Single Flight、retained/null 复用、显式
  刷新、首次失败重试、账号切换旧完成隔离、分支/类型身份、候选路径精确失效。
- ResourceRuntime 完整目标 69/69、全仓 294/294、Linux Debug build 通过；3.3 的 12 个生产/测试
  路径定向 analyze 为 0 error、0 warning。

仍未完成：

- License、Wiki、Issues/PR、分页和 Repository 主 Provider 没有迁移；页面视觉也没有在本阶段改写。
- License 仍依赖 branch/blob 加载链，Wiki 有自己的页面身份和 Markdown 来源；两者必须先独立审计，
  不能因表面都展示文档就直接塞入当前合同。
- 常驻 worker pool 仍需 Profile/Release 证据，本阶段没有性能数值结论。

## 3.11 主要信息流全局接入与首个分页试点

新增：

- [`resource-runtime-information-flow-inventory.md`](resource-runtime-information-flow-inventory.md)：追踪启动/账号、Home、Repository Code、Issues/PR、Actions/Projects/Security/Insights、Wiki/Profile、Notifications/Search、Workbench 的主要信息流，并按迁移波次标记。
- [`resource-runtime-integration-template.md`](resource-runtime-integration-template.md)：
  固定生产入口、状态层级、可证伪复现、资源身份、分页会话、预算、调度、mutation 失效、UI 状态、请求次数与性能记录格式。
- [`resource-runtime-pagination-pilot.md`](resource-runtime-pagination-pilot.md)：记录 Repository Issues/PR 正式 GraphQL/REST 页资源接入、已证明行为和未完成边界。

本轮确定：

- `PaginationController` 与 Runtime 不是二选一。Controller 保留 query、cursor、page order、refresh 与 scroll；不可变 page result 才进入 Runtime。
- Repository Issues/PR 已用显式 cursor/page 身份接入通用 forward source；登录首页使用轻量行投影，
  stale 首页立即交付并后台替换，隐藏 Tab 不继续分页。大列表仍由 Controller 无界展开实体，
  Runtime 的 LRU 尚不能单独解决实际内存，后续必须设计有界页窗口或轻量索引。
- 长轮询、watcher、Stream、下载/上传、SSH、本地 Git、表单与滚动状态不作为普通 Runtime 资源；它们使用专用 session/manager，稳定只读 snapshot 才能被页面缓存。
- 首批高风险候选是 Repository 主查询中的 6 组快捷计数、Issues/PR 列表与详情分页、全量 review
  threads、单文件 patch 顺序翻页、Home Events/Search/Notifications、Workflow overview 扇出和
  Profile activity 全量聚合。

完成边界：

- 清单与模板是设计合同；首个生产试点只修改分页 bridge、Repository 列表接线和作用域生命周期，
  没有修改 Service、GraphQL/codegen、业务模型或视觉；
- 没有证明页面更快，也没有建立 Profile/Release 数据、有界页窗口、距离式预取或 mutation overlay；
- TD-012 已改为 In Progress，其他主要信息流仍不得写成已迁移。

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

1. 人工复核 Repository Issues/PR 首个分页试点的真实大仓库连续翻页、Open/Closed、刷新失败、
   返回滚动与账号切换；自动测试不能替代真实网络验收。
2. 人工审阅 ResourceRuntime 3.3 的社区文档身份、双 consumer Lease 与 mutation 精确失效 diff；
   自动验证已完成，但尚未建立 Profile/Release 性能基线。
3. 在真实登录态核对 Code 的 CONTRIBUTING / SECURITY，以及 Repository Code/Issues/Pull
   requests/Actions/Projects/Wiki/Security/Insights 与 Profile Overview；没有操作证据前不扩大
   页面或性能完成结论。

### Next

1. 在现有 forward page 试点上设计有界 Controller 页窗口、距离式预取与 mutation 精确失效；
   在实体保留量证据前不扩散到其他列表。
2. 在现有 RepositoryPreview/稳定外壳之上，将完整 `repo_info` 查询拆为 Code baseline + 区域惰性
   Provider；优先移出 6 组 Issues/PR 快捷计数及 Releases/Languages。
3. 迁移 Issue/PR 详情摘要、评论/Review 时间线、commits/files 的页资源，先消除全量 review threads
   和单文件 patch 从头翻页，再继续 MD3 内容层。
4. 单独审计 License 与 Wiki 的数据身份、分支语义和失效合同；不能为了统一表面 API 吞掉领域差异。
5. 审阅当前基线 diff，决定是否建立本地 Git 检查点。

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

下一步唯一建议是先在真实大仓库人工复核 Repository Issues / Pull requests 首个分页试点，再设计
有界 Controller 页窗口。当前自动回归已证明 Open→Closed→Open、fresh 复用、显式下一页、刷新失败
保留旧项和账号 scope；返回滚动、query 晚到与四会话 LRU 沿用既有测试，实体保留量、预取、
mutation、Profile/Release 尚未完成，因此不扩散到全仓分页，也不声称页面已经更快。
