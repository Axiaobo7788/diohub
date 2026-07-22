# DioHub Workbench 项目进度

最后更新：2026-07-22

当前阶段：Phase 1 进行中（Workbench 边界已建立，Repository MD3 样板、Device Flow 与登录前后统一主页已落地）

UI 状态：应用无账号时也直接进入 MD3 主页，登录前后共用顶栏、搜索、响应式布局和仓库浏览；登录后已接回真实 Events Feed，个人仓库/通知/推荐尚待迁入

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
| Linux Debug | Passed | 2026-07-22 Events Feed 接入统一主页后使用 `CMAKE_BUILD_PARALLEL_LEVEL=1` 复验并生成 Debug bundle |
| Windows Debug | Not locally verified | 共用 Dart/Flutter UI 和 Device Flow；需 Windows runner 实机构建 |
| macOS Debug | Not locally verified | 共用 Dart/Flutter UI 和 Device Flow；Pod 锁已清理，需 macOS + CocoaPods 实机构建 |
| Root tests | Passed | 2026-07-22 单并发全套 89/89 通过 |
| Unified home tests | Passed | 360px 未登录/已登录、800px、1440px 公共/已登录 Feed Widget Test 共 5/5 通过 |
| Public REST tests | Passed | 搜索、目录排序/路径编码、文本/二进制判定共 3/3 通过 |
| Home targeted analyze | Passed | 4 个 Feed/主页相关文件 0 error / 0 warning；保留 32 条项目现有严格 style info |
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
- 登录后的主区域已接回 DioHub 现有真实 Events Feed，包含刷新、空状态和显式“加载更多”。
- 未登录时不启动通知/后台 Watcher，不伪造 Account/Token，不放开私有数据或写操作。
- 旧 `NavCenterShell` Dashboard 组件仍保留在仓库，但不再作为登录后的另一套默认主页。

尚未完成：

- 旧 Dashboard 的个人动态、贡献、Pinned Repositories、Review Requests 等尚未按 MD3 信息层级迁入统一主页。
- Notifications、账号仓库列表、Bookmarks 等账号能力尚未建立统一导航入口。
- 尚未建立能将 Activity 与 `Suggested by DioHub` 稳定穿插的类型化 `HomeFeedEntry` 组合层。
- 所有旧路由尚未统一接入“需要登录”的功能门控。
- 主页视觉密度、窄屏菜单和桌面导航仍需真机视觉审阅。
- Windows/macOS 仍需在对应宿主机执行原生 Debug 构建。

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
- 建立 Repository Code MD3 响应式样板，360/800/1440px Widget Test 通过。
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
- [x] 在 Device Flow + 统一主页 + Events Feed 基线上串行复跑 root tests，89/89 通过。
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

1. 将 Notifications、账号仓库、Bookmarks 等仅账号功能收口到统一主页，并建立一致的登录门控。
2. 固定 Workbench 桌面三栏/双栏与移动折叠信息结构，建立独立路由的 Fake 功能性 UI 骨架。
3. 建立 WorkspaceDesktop Source，并将 Windows/macOS/Linux 命令发现与编辑器启动差异收敛在平台适配器。
4. 补齐 Production Source 的 offline / permission / rate-limit 精确分类。

### Next

1. 建立类型化 Drift 快照与 schema 版本。
2. 完成 PR Review 概览与自适应 Workflow 轮询。
3. 打通 Repository → Local Repo → HEAD → PR → Actions → Editor 真实纵向演示。
4. 审阅当前基线 diff，决定是否建立本地 Git 检查点。

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

下一步只建立类型化 `HomeFeedEntry` 组合层：保留 GitHub Events 为真实 Activity，再将基于 Star、历史、语言/Topic 的本地结果标记为 `Suggested by DioHub` 后可控穿插。不抓取 GitHub 私有 Dashboard 端点，不伪装为 GitHub 官方推荐。
