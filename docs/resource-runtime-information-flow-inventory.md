# DioHub ResourceRuntime 信息流接入清单

状态：Active migration（清单已建立；Repository Issues/PR 为首个分页生产试点）
日期：2026-07-24

## 1. 目的

本清单回答三个问题：

1. 哪些正式信息流可能因为重复请求、扇出、全量聚合或无界保留而拉长加载时间；
2. 哪些资源适合进入 `ResourceRuntime`，哪些状态必须继续由页面、分页 Controller 或专用服务管理；
3. 后续迁移如何使用同一份任务模板，而不是每张页面重新发明缓存、预取和加载状态。

清单最初来自静态审计；当前已按其合同完成 Repository Issues/PR 不可变 forward page 的首个
生产试点，其他分类仍是迁移计划。没有建立 Profile/Release 性能基线；下文的“风险”表示代码结构
可能产生的成本，不表示已经测得具体耗时。

配套文档：

- [ResourceRuntime 第三阶段架构](resource-runtime-architecture.md)
- [ResourceRuntime 接入任务模板](resource-runtime-integration-template.md)
- [Repository Issues/PR 分页生产试点](resource-runtime-pagination-pilot.md)
- [开发约束](development-constraints.md)
- [技术债登记表](technical-debt-register.md)

## 2. 当前证据

静态搜索当前生产代码得到：

- `lib/providers` 与 `lib/view` 中有 67 处 `PaginationController<...>` 类型引用；
- `lib/providers` 中有 25 处 `keepAliveFor(ref)`；
- Runtime 已正式覆盖 Repository Code 全目录、根 README、README 图片以及
  CONTRIBUTING / SECURITY 的 source 与 render artifact；
- Home、Repository 主信息、Issues、Pull requests、Actions、Profile、Notifications 等主要信息流
  仍分别使用 Riverpod keep-alive、页面级 Controller、Service 聚合或直接 FutureProvider。

计数只用于说明迁移面较大，不能直接推导 67 个新资源或 25 个缺陷。每条信息流仍须按身份、生命周期、
分页、mutation 和 UI 语义独立审计。

## 3. 统一所有权边界

```text
Route / page / main tab
        │
        ├─ UI session
        │   filter / sort / selected tab / scroll / draft
        │
        └─ PaginationController
            query session / next cursor / refresh / page order
                    │
                    ▼
          ResourceRuntime page resources
          query + cursor/page + page size + scope
                    │
                    ▼
          existing Service / ApiClient / APICache
```

各层职责：

| 层级 | 保留职责 | 不应承担 |
| --- | --- | --- |
| 页面 / Route | 可见性、布局、导航、滚动与用户事件 | 网络去重、全局预算、跨页面缓存 |
| Provider / Notifier | 强类型业务适配、mutation、组合轻量状态 | 私建无界缓存、隐藏循环抓取所有页 |
| `PaginationController` | 查询会话、游标方向、页序、显式刷新、滚动恢复 | 跨页面 Single Flight、全局内存预算、永久持有所有实体 |
| `ResourceRuntime` | 页资源身份、Single Flight、SWR、调度、预取、Lease、失效、预算、Telemetry | UI 筛选、表单、业务 mutation、Widget |
| Service / `ApiClient` / `APICache` | REST/GraphQL、领域解析、传输缓存 | 页面生命周期和视觉状态 |

分页不是整体排除项。正确目标是：

- `PaginationController` 保留会话；
- 每一页不可变结果可以进入 Runtime；
- 对超大列表，Controller 最终只保留页键、轻量索引或有界窗口，实体由 Runtime 按 Lease 与预算保留；
- 首次加载、缓存命中、后台刷新、加载下一页和 LRU 淘汰必须是五种可区分状态。

## 4. 分级

| 标记 | 含义 |
| --- | --- |
| Integrated | 已由正式入口消费 Runtime，并有对应合同与回归 |
| Partial | 同一页面只有部分资源已进入 Runtime |
| Wave A | 首批候选；直接影响高频入口或大列表 |
| Wave B | 第二批候选；有扇出、解析或中等频率复用价值 |
| Wave C | 后续候选；低频、管理型或需先厘清业务语义 |
| Excluded | 不应作为普通只读资源接入 Runtime |

## 5. 全局信息流清单

### 5.1 启动、账号与本地状态

| 信息流 | 当前所有者 | 风险/特征 | 决策 |
| --- | --- | --- | --- |
| 启动配置、主题、语言 | 本地设置 Provider / 持久化 | 启动关键路径；不是远程只读页资源 | Excluded；单独优化启动顺序 |
| OAuth / Device Flow / Token | 认证服务与安全存储 | 凭据、轮询、账号切换 | Excluded；Runtime 只接收匿名 scope 或账号 scope |
| 当前用户身份摘要 | User Provider / entity store | Home、Chrome、Profile 共享 | Wave A；建立账号隔离的摘要资源，mutation 后精确失效 |
| Drift 数据与 Watcher state | DAO / Stream | 本地事务和持续订阅 | Excluded；由数据库与 watcher 管理 |

### 5.2 Home 与公共浏览

| 信息流 | 当前入口 | 风险/特征 | 决策 |
| --- | --- | --- | --- |
| Top repositories | `home_top_repositories_provider.dart` | Home 与抽屉可能复用；当前 Riverpod 定时保活 | Wave A；按账号、筛选和页身份接入 |
| Events Feed | Dashboard events Provider / Service | 高频分页、图片与仓库摘要交错 | Wave A；页资源化并支持滚动前预取 |
| GitHub Changelog | `github_changelog_provider.dart` | 官方公共数据、低变更 | Wave B；公共 scope、长 fresh 窗口 |
| Trending / Search repositories | Search Provider + `PaginationController` | 查询变化快、重复返回同一仓库 | Wave A；查询页进入 Runtime，搜索会话留在 Controller |
| 推荐仓库 | 尚无完整可解释正式链路 | 算法、身份和解释字段未固定 | Wave C；先定产品合同，不用假数据接入 |

### 5.3 Repository 外壳与 Code

| 信息流 | 当前入口 | 风险/特征 | 决策 |
| --- | --- | --- | --- |
| Repository preview | `repository_preview_providers.dart` | 导航前已有轻量预热 | Partial；可作为 baseline source，需与完整实体身份对齐 |
| Repository 主信息 | `repository_providers_core.dart` | 首查询带 6 组 Issues/PR 快捷计数 | Wave A；拆成 Code baseline 与惰性区域资源 |
| 目录页 | `directory_provider.dart` | 已有 scope、branch、path、SWR 与预取 | Integrated |
| 根 README source/artifact | Repository README resource providers | source → worker artifact | Integrated |
| README 图片 source/classification | README image resource | 第三方下载、大小限制、分类 | Integrated |
| CONTRIBUTING / SECURITY | Repository document resource | 候选路径、缺失负缓存、双消费者 | Integrated |
| License | `license_content_notifier.dart` | branch/blob、缺失和 mutation 语义不同 | Wave B；先独立审计，不并入社区文档假抽象 |
| 最新 commit / 目录 commit | commit Provider | 根页与目录行可能扇出 | Wave A；摘要与路径页分别定义身份，禁止每行无界并发 |
| Branch / Tag / Release | 各自 Service + 分页 Controller | 多处选择器与侧栏复用 | Wave B；不可变页资源 + 短会话 |
| About / Languages / Contributors / Releases | Repository 区域 Provider | 非首屏关键，适合惰性加载 | Wave A；从主查询拆出，视口附近预取 |

### 5.4 Repository Issues 与 Pull requests

| 信息流 | 当前入口 | 风险/特征 | 决策 |
| --- | --- | --- | --- |
| Issues 查询列表 | MD3 page + Search Service + Runtime source | 四查询会话留在页面；不可变 GraphQL/REST 页进入 Runtime；Controller 仍无界展开项目 | Partial；首个分页桥接已落地，待页窗口/预取/mutation |
| Pull requests 查询列表 | 同上 | 大仓库、高频 Open/Closed 切换 | Partial；与 Issues 共用页资源合同，不合并领域 UI |
| Issue / PR 快捷计数 | Repository 主 GraphQL | 阻塞 Code baseline | Wave A；独立小资源，按 Tab 可见性获取 |
| Issue 详情摘要 | `issue_detail_notifier.dart` | 标题、状态、权限与 mutation | Wave A；只读 snapshot 可入 Runtime，mutation 留在 Notifier |
| Issue 评论时间线 | discussion `PaginationController` | 双向分页、Reaction、编辑 | Wave A；页资源化，Controller 保持方向和锚点 |
| PR 详情摘要 | `pull_detail_notifier.dart` | Review、Checks、Files 多区域依赖 | Wave A；拆分区域资源，避免整页门闩 |
| PR review threads | `allReviewThreadsMapProvider` | 当前循环抓取全部页再构建 map | Wave A；禁止详情首屏全量抓取，按可见 thread/page 获取 |
| PR commits | `pull_commits_view.dart` | 分页列表 | Wave A；页资源化 |
| PR changed files | `pull_changed_files_list.dart` | 大 PR 可能很多页和大 patch | Wave A；元数据页与 patch artifact 分离 |
| 单文件 patch | `getPullFilePatch(path)` | 为找路径可能顺序遍历多页 | Wave A；建立 path 索引/页缓存，避免每次从头扫描 |
| Reactions / assignee / labels / milestones | capability Provider / sheet Controller | 多弹层复用、mutation 后需同步 | Wave B；列表页资源 + mutation overlay/失效 |

### 5.5 Actions、Projects、Security 与 Insights

| 信息流 | 当前入口 | 风险/特征 | 决策 |
| --- | --- | --- | --- |
| Workflows | Actions Provider | 一次最多取 100 条 | Wave B；仓库级列表资源 |
| Workflow overview runs | `workflowOverviewProvider` | `Future.wait` 为每个 workflow 请求 runs | Wave A；取消无界扇出，改批次调度或可见工作流惰性资源 |
| Workflow runs | Actions `PaginationController` | 高频分页与筛选 | Wave A；页资源化 |
| Run / Job / Step snapshot | Actions Provider / stream | 详情读取与实时状态并存 | Wave B；稳定快照入 Runtime，实时轮询由专用 session 管理 |
| Workflow live polling | StreamProvider / watcher | 长连接式轮询、前后台节奏 | Excluded；使用集中 PollingSession，不占普通资源 Lease |
| ProjectsV2 | Projects Controller | 分页与权限状态 | Wave B；页资源化 |
| Dependabot / code / secret alerts | Security Controllers | 三类分页并可能并发刷新 | Wave B；独立页资源，共享调度预算 |
| Commit activity / languages / participation | Insights Providers | 统计数据可复用，部分响应较大 | Wave B；仓库统计资源，使用较长 fresh |
| Stargazer history | Repo list/stat service | 最多循环 5 页 × 100 | Wave B；明确上限、阶段结果与取消 |

### 5.6 Wiki 与 Profile

| 信息流 | 当前入口 | 风险/特征 | 决策 |
| --- | --- | --- | --- |
| Wiki 页面/目录 | `wiki_providers.dart` | 分支和仓库 Wiki 语义特殊 | Wave B；先审计 source 身份与缺失语义 |
| Profile 基础信息 | `user_providers.dart` | Chrome/Profile/评论作者可能复用 | Wave A；账号 scope 与公开 scope 分离 |
| Profile README | Profile Provider / Markdown | source 与 render artifact 可复用 | Wave B；复用已有 Markdown artifact 合同 |
| Pinned repositories | Profile Provider | 首屏独立区域 | Wave A；惰性摘要资源 |
| Contributions 多年数据 | `user_contributions_service.dart` | 多年份 `Future.wait` | Wave B；按年度资源化，当前年优先，历史年延迟 |
| Activity timeline | `user_activity_service.dart` | 多连接循环至耗尽并跨年聚合 | Wave A；禁止首屏全量，改时间窗口/页资源 |
| Repositories / Stars / Followers 等 | 多个 Profile Tab | 大量分页 Controller | Wave B；统一页资源模板，保留各自查询会话 |

### 5.7 Notifications、搜索与后台活动

| 信息流 | 当前入口 | 风险/特征 | 决策 |
| --- | --- | --- | --- |
| Notifications list | Notifications `PaginationController` | 与未读计数、已读 mutation 耦合 | Wave A；页资源 + mutation overlay + 精确失效 |
| Notification count | count Provider / watcher | 轻量、周期更新 | Wave B；快照可缓存，轮询由 watcher 管理 |
| Global issue/PR/code/user search | Search Service / Controller | query 高基数、短生命周期 | Wave A；短 retain、严格预算、取消未开始预取 |
| Background inbox polling | Watcher engine | 周期任务、数据库写入 | Excluded；专用 watcher，不伪装成页面资源 |
| Avatar / repository icon | Flutter image stack / URL | HTTP bytes、解码、GPU 三层不同 | Wave B；只在有统一下载需求时接 source，像素缓存仍属 Flutter |

### 5.8 Workbench 与本地开发流

| 信息流 | 当前入口 | 风险/特征 | 决策 |
| --- | --- | --- | --- |
| GitHub Repository/PR/Checks/Annotations 快照 | `GitHubGateway` | 远端只读快照可复用 | Wave C；生产 UI 入口固定后再按资源接入 |
| LocalRepo / Worktree / HEAD | `WorkspaceGateway` | 本地命令、文件系统变化 | Excluded；由 workspace session 管理 |
| Editor target / open action | `EditorGateway` | 命令式副作用 | Excluded |
| UnifiedRepoController ViewState | Workbench Controller | 组合本地与远端 | Excluded；它消费资源，不成为 Runtime 缓存 |

## 6. 优先级与迁移波次

### Wave A：消除高频入口的门闩与无界读取

1. 完成 Repository Issues / Pull requests forward page 试点后，补有界页窗口、预取和 mutation；
2. 将 Repository 主查询拆为 baseline 与惰性区域，移出 6 组快捷计数；
3. 迁移 Issue/PR 详情摘要、时间线页、PR files/commits/review threads；
4. 处理 Home Events、Top repositories、全局 Search 与 Notifications 页资源；
5. 把 Workflow overview 的按工作流扇出改为有界调度和惰性加载；
6. 把 Profile activity 从“抓完再显示”改为时间窗口或分页。

### Wave B：统一复用、解析和统计资源

1. License、Wiki、Profile README；
2. Branch/Tag/Release、Repository 辅助统计；
3. Actions run/job 稳定快照、Projects、Security alerts、Insights；
4. Profile contributions 年度资源与次级分页列表；
5. Reactions、选择器数据、头像/图标 source 的可行性审计。

### Wave C：低频与产品合同尚未固定的资源

1. 推荐算法与解释数据；
2. 管理型页面和低频列表；
3. Workbench 远端快照；
4. 只有 Profile 证明需要时才扩展常驻 worker 或更复杂的预取策略。

## 7. 迁移反模式

以下实现即使“能加载”也不能算完成：

- 在 `FutureProvider` 内循环到 `hasNextPage == false` 才返回首个可见结果；
- 对 N 个子资源直接 `Future.wait`，没有并发上限、优先级或取消；
- 为候选路径逐个顺序请求，但不缓存命中与明确缺失；
- 页面 Controller 无界保留所有实体，同时声称 Runtime 已能回收内存；
- 一个主查询包含所有 Tab 计数和辅助区，阻塞当前 Tab 首屏；
- 在 `build` 中解析大 Markdown、Diff 或做大集合排序；
- 只测试“最终有数据”，不验证请求次数、禁止事件、Controller 身份和返回时骨架是否重现；
- 用 `keepAliveFor`、post-frame 或全局单例掩盖身份和所有权不清。

## 8. 全局完成门槛

每条信息流只有同时满足以下条件才可标记 Integrated：

1. 当前生产入口消费正式 Service 和真实数据；
2. `ResourceId` 包含 server、principal、领域键、分页键与 schema version；
3. 首次、fresh、stale/SWR、下一页、刷新、失败保旧、空结果和重试可区分；
4. 首次请求、Single Flight、返回缓存、显式刷新、mutation 失效与 LRU 淘汰均有请求次数断言；
5. 页面、Tab、筛选、分页 Controller、Provider、Runtime entry 六层生命周期分别有证据；
6. Controller 不无界持有 Runtime 已可回收的实体；
7. 预取有明确触发距离、优先级、预算、取消与浪费 Telemetry；
8. Android 与桌面共享实现，360/800/1440px 和适用文字缩放行为不回归；
9. Profile/Release 对比建立前只报告结构和请求次数，不声称“更快”；
10. 进度文档区分“合同完成”“生产接入”“人工验收”和“性能已测量”。
