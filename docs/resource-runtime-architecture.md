# ResourceRuntime 第三阶段架构

状态：Implemented（统一控制面、Repository Code/文档/图片试点；Repository Issues/PR 与 Notifications 分页部分接入）
日期：2026-07-25

## 1. 决策

DioHub 使用一套纯 Dart、进程内的 `ResourceRuntime` 统一协调只读资源的交付、刷新、预取、失效、
生命周期和内存预算。Runtime 位于现有领域 Service 与 Riverpod 页面适配器之间：

```text
Widget / Riverpod thin adapter
            ↓
       ResourceRuntime (L1)
            ↓
existing Service / ApiClient / APICache (L2 transport cache)
```

Runtime 不替换 Riverpod、REST/GraphQL Service、`ApiClient`、`APICache`、Drift、业务模型、
认证或 `PaginationController`。Loader 必须继续调用现有领域入口，不持有 `Ref`，Runtime 也不解释
“空目录”“没有 README”等业务语义。

这里“不替换 `PaginationController`”不表示分页页数据永远排除在 Runtime 外。Controller 继续拥有
查询会话、页序、游标方向、刷新意图与滚动恢复；不可变的 page result 可以按
scope + query + cursor/page + page size 进入 Runtime，由统一控制面负责 Single Flight、SWR、
调度、预取、Lease 与预算。完整候选清单和逐信息流任务格式见
[信息流接入清单](resource-runtime-information-flow-inventory.md) 与
[接入任务模板](resource-runtime-integration-template.md)。首个生产接入的精确合同与验证记录见
本文 [§5.2](#52-repository-issuespr-forward-page-生产试点)。

这里的“统一”是一个控制面，不是一个包含所有业务的 God Object：

```text
ResourceRuntime control plane
├── identity / scope / lease / freshness / invalidation / telemetry
├── network scheduling lane
├── compute scheduling lane
├── decode scheduling lane
└── explicit pure-Dart worker boundary

domain ResourceSpec
└── existing Service / parser / decoder
```

身份、预算、优先级、依赖和失效由 Runtime 统一裁决；网络、解析、解码仍由独立强类型
`ResourceSpec` 和已有领域实现执行。Runtime 不导入 Widget、Theme、BuildContext 或页面模型。

### 1.1 统一治理不等于统一加载算法

Runtime 统一的是资源治理，不会自动决定一张 Issue 行需要哪些 GraphQL 字段、时间线从哪个方向
分页、目录如何复用 immutable tree、聚合请求怎样分批，或实时状态何时订阅。冷加载速度仍取决于
正式 Service 的最小投影和与访问模式匹配的专用算法。

目标结构是：

```text
Widget / Riverpod thin binding
             ↓
query or page session（按需）
             ↓
specialized access-pattern executor  ←  Resource Recipe
             ↓
       ResourceRuntime control plane
             ↓
typed ResourceSpec loader
             ↓
existing domain Service / transport cache
```

这里的 Resource Recipe 是对身份、页键、标签、策略、估算权重和正式 Loader 的声明，可以由现有
`ResourceSpec` factory 与 Provider 组成，不要求再造一套配置框架。特化执行器按访问模式封装操作
算法，不能包含某个页面的 Widget、文案、业务字段或第二套 Service。

| 层级 | 职责 |
| --- | --- |
| 领域 Service | 正式 REST/GraphQL、本页最小字段投影、游标和领域错误语义 |
| Resource Recipe | 类型化身份、scope、页键、标签、策略、Loader、依赖和估算权重 |
| 特化执行器 | 该访问模式的分页、增量刷新、锚点、预取、页窗口、有界扇出及 Lease 生命周期 |
| `ResourceRuntime` | Single Flight、SWR、generation、调度、Lease、失效、LRU、预算和 Telemetry |
| Riverpod thin binding / Notifier | 依赖注入、Recipe 构造、简单资源的 Lease 生命周期、执行器注入和状态投影 |
| Widget | 真实可见性事件、筛选、滚动、展示和用户操作；不直接协调资源机制 |

当前访问模式的事实边界如下：

| 访问模式 | 应负责的专用算法 | 当前状态 |
| --- | --- | --- |
| Snapshot / source→artifact | 单值交付、静态依赖、派生产物重建 | 已由 Runtime acquire、dependencies 与 worker 原语落地 |
| Forward page | 显式页键、首页 SWR、顺序游标和页替换 | Repository Issues/PR 与 Notifications 两个生产消费者未修改通用执行器；基础抽象已由第二消费者证明，有界 Controller 页窗口与距离式预取仍未完成 |
| Bidirectional timeline | 头部增量、尾部历史分页、锚点与双向去重 | 尚未实现；至少存在第二个明确潜在消费者且任务获批时再建立 |
| Tree / path | immutable tree/ref、path 分块和父子失效 | 目录资源试点已落地，但没有通用 `TreeExecutor` |
| Bounded fan-out | 有界并发、局部交付、失败隔离和阶段进度 | 尚未实现；不得用无界 `Future.wait` 代替 |
| Live activity | 前后台订阅、轮询退避和停止语义 | 不作为普通 Runtime 执行器；使用专用 session，稳定只读 snapshot 可进入 Runtime |

Repository Issues/PR 首个试点目前仍由 `repository_issue_pull_md3.dart` 读取 active scope、选择
fallback 并构造 Runtime page source。这是迁移期例外，不是推荐 binding。第二个消费者
Notifications 已把 scope、Recipe factory、All/Unread Controller 与销毁收进显式 Riverpod
query-session pool；Widget 只读取当前会话、提交筛选与用户事件，不管理 Lease、generation、资源
身份或请求调度。后续新页面应沿用这一所有权方向，不复制 Issues/PR 的迁移期胶水。

后续读取型功能使用以下工作流：

1. 从真实 UI 需求追踪正式 Service，先固定最小投影、身份、规模、错误和 mutation 语义；
2. 判断访问模式，优先复用已有执行器；普通 snapshot/source→artifact 直接使用 Runtime 原语；
3. 用 Recipe 声明资源差异，不把字段、scope、页键或标签散落在 Widget；
4. 以生产入口测试首次、fresh、stale、下一页/增量、返回、失效、scope 和禁止事件；
5. TTL 先由新鲜度与失效合同解释；正确性成立后再用 Profile/Release 调整页大小、预取距离、窗口和
   并发预算；
6. 第二个生产消费者只新增 Recipe/领域 Loader 而无需修改执行器，才证明该访问模式抽象成熟。

如果新页面必须修改 Runtime 核心、通用 `PaginationController`，或让 Widget 直接管理 Lease、
generation、资源身份和请求协调，应立即停止页面扩展并审查抽象。只有现有执行器缺少通用能力、需求
确实构成新的访问模式、且至少存在第二个明确潜在消费者时，才新增公共执行器；单页差异留在领域
Service/Provider 的薄适配器中。

## 2. 公共合同与状态

- `ResourceId<T>`：由 kind、schema version、`ResourceScope` 与领域键组成；同一逻辑 ID 冲突使用
  不同类型、策略或 Loader contract 时快速失败。
- `ResourceScope`：由稳定的 server ID 和 principal 组成。公开 GitHub、GitHub 账号、不同账号和
  GHES 服务器具有不同作用域。
- `ResourceSpec<T>`：声明身份、策略、精确标签、Loader contract、work kind、静态依赖与现有领域
  Loader。
- `ResourceWorkKind`：network、compute、decode 三类调度预算，避免一种工作占满全部 Runtime 槽位。
  work kind 只负责准入、优先级与并发数，不会自动把代码移出 UI isolate。
- `ResourceLoadContext.runInWorker()`：只有显式调用这个入口的可发送、纯 Dart 变换才会进入真实
  worker isolate。网络 Loader、Widget、`ui.Image`、BuildContext 和带平台句柄对象不得传入。
- `ResourceLoadContext.require()`：只能读取 `ResourceSpec.dependencies` 中静态声明的依赖；未声明、
  跨 scope、循环或当前会死锁的同调度 lane 依赖快速失败。
- `ResourceLease<T>`：每个消费者独立持有并幂等释放；presence 为 `visible` 或 `retained`。
- `ResourceSnapshot<T>`：
  - `ResourceLoading`：尚无可交付数据；
  - `ResourceData`：包含 fresh/stale、刷新中标记、来源、获取时间和可选的刷新错误；
  - `ResourceFailure`：首次加载没有可保留数据时的失败。

空集合仍是 `ResourceData`，不增加会改变领域含义的通用 Empty 状态。

## 3. L1 与现有 L2

`ResourceRuntime` 是有界的 L1 对象缓存和协调器；现有 Dio `APICache` 仍是 HTTP/GraphQL 传输层
L2。L1 复用已解析的业务对象并合并同一资源的并发工作，L2 继续负责响应缓存与现有刷新策略。
两层不会各自创建第二套 API、Repository 或业务模型。

目录使用 2 分钟 fresh 窗口和 5 分钟保留窗口；README 以及 CONTRIBUTING / SECURITY 的源 HTML
与解析产物使用 2 分钟 fresh、10 分钟保留；README 图片源与分类产物使用 1 分钟 fresh、5 分钟
保留且禁止预取。条目同时受最大条目数和估算权重约束。

所有资源统一以 4 KiB 为一个估算权重单位。默认最大 4096 单位（约 16 MiB），内存压力 trim 到
2048 单位（约 8 MiB）；这是可预测的保留预算，不是 Dart heap 精确测量。默认上限必须至少容纳
一条合法的 8 MiB README 栅格图片 source → artifact 链，当前回归把这个容量关系固定为配置不变量。
Runtime 不会为满足预算驱逐仍持有 Lease 的资源，也不会单独驱逐仍被该资源依赖的 source；超预算时
会通过 `overEntryBudget` / `overWeightBudget` 和 `estimatedBytes` 暴露事实，并在最外层 Lease
释放后继续淘汰，而不是留下一个会在下次访问时重新下载的断链 artifact。显式 scope 清理和 Runtime
dispose 仍可清除整条链。依赖保护递归传播，持有最外层 artifact Lease 时，中间 artifact 与最底层
source 都不能被普通 LRU 或 `trimMemory()` 单独逐出；`trimMemory()` 优先清理无人使用、未被接管的
预取结果。

## 4. Single Flight、SWR 与一致性

- 同一个规范化 ID 同时只执行一个 Loader；后续 acquire 加入同一 in-flight。
- fresh 数据同步交付，不重新加载。
- stale + visible 先交付旧数据，再调度一次刷新；stale + retained 只标记过期，不自动请求。
- 刷新失败保留旧数据并设置 `lastRefreshError`；首次失败才进入 `ResourceFailure`。
- 每次失效递增 generation。旧 generation 的完成结果不能发布。
- 请求中重复失效只登记一次 pending revalidate；当前请求结束后至多再执行一次。
- 标签与 scope 必须精确匹配，不做字符串模糊遍历。
- source 失效沿静态依赖图级联到 derived artifact；只有 visible derived resource 自动重建，
  retained artifact 保持 stale，返回可见时再执行 SWR。
- derived artifact 会记录本次构建所见的 dependency data revision。即使没有显式 invalidate，
  依赖自然过期、被替换或被回收也会使 artifact 失去 fresh 资格，不能在新 source 上继续谎报 fresh。
- derived loader 通过 Runtime 读取 source，因此并发消费者共享同一 source Single Flight，不在
  Markdown Provider 内再造第二层缓存。

## 5. 调度、预取与生命周期

三类调度 lane 各自按 interactive、refresh、prefetch 三档排队，并为 interactive 工作保留并发
能力。默认 network 4、compute 2、decode 2；预算可注入测试，不能由页面另建调度器。它们只控制
并发和优先级，不等于 isolate executor。生产 `ResourceWorker` 当前通过短生命周期
`Isolate.run` 执行明确的纯 Dart 变换；是否需要常驻 worker pool 必须由 Profile 证明，不能先行
增加进程内常驻复杂度。预取被真实 acquire 命中时会提升和接管，不产生第二次请求。策略禁止或应用
处于 hidden/paused/detached 时，预取在创建 L1 条目前直接拒绝，不留下空的 Loading 条目；预取获准
入队后立即执行条目数与估算权重预算，不能靠排队风暴暂时绕过 L1 上限。

尚未开始的预取可由 ticket 或进入后台精确取消，并且只记 `prefetchCanceled`；因预算、scope 清理或
其他淘汰而移除的未接管预取才记 `prefetchWasted`，同一任务不能同时算作取消和浪费。已经进入既有
网络栈的请求仍不支持强制取消。

Flutter 生命周期由薄适配器映射到纯 Dart 环境：

- resumed：允许投机工作，并只刷新 visible 且 stale 的资源；
- hidden/paused/detached：不启动投机预取；
- inactive：可能只是系统浮层，不改变 Runtime 环境。

Repository 使用保活 Tab，因此 Code 与 Security 资源 presence 由各自页面会话 Provider 在真实
Tab 用户事件中更新；目录、README 和社区文档 adapter 只监听对应状态。不得在 `build`、
`initState`、`didUpdateWidget` 等生命周期中写共享 Provider，也不能用 Widget mounted 或监听数量
推断可见性。Flutter 的内存压力回调会调用统一 `trimMemory()`，而不是让页面分别清缓存。

### 5.1 分页、聚合与长时活动的边界

分页采用 Controller + Runtime page resource 的混合所有权：

```text
Page / Provider
    ↓
PaginationController
query session / cursor / page order / refresh / scroll
    ↓
ResourceRuntime
immutable page result / Single Flight / SWR / prefetch / budget
    ↓
existing domain Service
```

- Controller 不进入 Runtime，也不能无界保留所有实体对象；大列表应逐步改为有界页窗口、页键或轻量
  索引，让 Runtime 的 LRU 与内存压力回收真正生效。
- 同一查询的不同页是不同资源；query、filter、sort、direction、page size 或 scope 改变都必须改变
  身份，不能只把 cursor 藏在页面 adapter 内。
- 首次加载、fresh 命中、stale/SWR、加载下一页、显式刷新和 LRU 淘汰后恢复是不同状态，UI 与测试
  不得合并成一个 loading。
- 需要循环到耗尽才能生成的聚合结果，应拆为可渐进交付的页或时间窗口；如果业务确实要求全量，必须
  声明上限、并发、取消、阶段进度和估算预算。
- 轮询、watcher、长连接、下载/上传、SSH 和本地 Git 操作不作为普通 page resource；它们使用各自
  专用 session/manager，稳定的只读 snapshot 才可作为 Runtime 资源供 UI 消费。
- mutation 留在领域 Notifier/Service，通过 overlay 与精确标签失效同步相应页资源。

Repository Issues / Pull requests 已按这条边界接入通用 `RuntimeForwardPageSource`：登录态仍调用
既有 GraphQL Search Service，访客态仍调用既有 Public REST Service，Open/Closed 四会话 LRU 和
滚动仍由原 Controller 管理。该试点尚未建立有界 Controller 页窗口、距离式预取或 mutation
overlay，不能据此声称全局分页或大列表内存治理完成。

### 5.2 Repository Issues/PR forward page 生产试点

精确生产入口仅为 Repository → Issues 与 Repository → Pull requests 的不可变列表页。登录态继续
复用 `SearchService`，但使用只包含编号、标题、作者、状态、时间、评论数和前 5 个标签的
`searchRepositoryIssuePulls` GraphQL 投影；访客态继续使用
`PublicRepositoryService.searchIssuesPulls` REST。详情正文、review/check、project、reaction 与
mutation 没有进入这份列表合同。

每页身份固定包含：

- server/principal `ResourceScope`；
- owner/repository；
- authenticated GraphQL 或 public REST transport；
- 完整规范化 query；
- GraphQL cursor 或 REST page number；
- page size 与 schema version。

GraphQL 首页使用 `cursor:start`，后续页必须有非空 `endCursor`；REST 使用显式 `page:1`、
`page:2`。当前策略为 fresh 1 分钟、retain 5 分钟；估算重量为每项 2 个统一单位，空页 1 个单位。
显式刷新精确失效当前 query 的全部页，在替换首页成功前保留旧列表；stale 首页立即进入 Controller，
后台 revalidate 仅在 Controller 仍表示该首页时原位替换。隐藏 Repository Tab 的 sentinel 不请求
下一页，重新可见后才恢复按需分页。

截至提交 `698c3837`，自动回归已经证明：

- 同页并发 source 只有一次 Loader，新 Controller 可复用 fresh 页；
- next page 使用独立身份，reset 会等待替换首页，刷新失败保留旧项；
- stale 首页先交付再后台替换；
- Open → Closed → Open 只加载两个查询页，显式刷新才产生第三次加载；
- public REST、账号 scope 隔离、REST page 推进、隐藏 sentinel 0 请求均成立；
- 登录投影不再下载列表不展示的详情字段。

当前仍是 Partial：`PaginationController` 会展开保留当前会话全部对象，尚无有界页窗口、距离式预取
或 mutation overlay；Issue/PR 详情、评论、Review、commits、files、review threads 及 Repository
主查询的六组快捷计数也未迁移。没有 Profile/Release 冷暖耗时、帧时间或 heap 证据，因此这里只能
证明合同、请求复用和禁止事件，不能宣称页面已经更快。

### 5.3 Notifications forward page 第二生产消费者

精确生产入口为共享 `AppChrome` 右上角通知按钮进入的 `NotificationsRoute`。领域 Loader 继续调用
既有 `NotificationsService.getNotifications` REST 入口，没有创建第二套 API、模型或传输缓存。
资源身份包含 server/principal scope、All/Unread 查询、显式 REST page number、page size 与版本；
策略为 fresh 30 秒、retain 5 分钟，每项估算 2 个统一单位。

该入口验证了通用 forward-page 执行器无需为第二个页面增加核心分支：

- Riverpod route session pool 最多持有 All 与 Unread 两个 Controller，切换返回原 Controller；
- 原因、自定义、仓库筛选及查询、排序、分组只对 Controller 保留的已加载页调用 `refilter()`，
  不改变资源身份也不产生请求；`PaginationController.filter` 是可逆视图投影，不再在页进入
  Controller 时破坏性丢弃被过滤项；
- 已读、完成、批量完成和全部已读仍由正式 Service 执行，成功后按账号 scope 的 inbox tag 精确失效；
- mutation 先向两会话应用 overlay，失败只回滚对应 thread patch；
- Provider 负责 Controller/source 销毁；Widget 不注册全局 controller，也不在生命周期回调中写共享
  Provider；
- 返回新 Route session 时，30 秒内的 fresh 首页可由 Runtime 直接交付。

自动回归证明 All → Unread → All 只有两次首次 Loader、返回 All 不出现骨架、原因筛选零请求，以及
销毁页面会话后新会话复用 fresh Runtime 页。该入口仍是 Partial：Controller 仍展开已加载实体，
分页触发仍是视口 sentinel 而非带预算的距离式预取；未读 count 与后台 watcher 继续使用独立合同，
Saved/Done 收件箱也没有可用的 GitHub REST 查询，不能伪造为已实现。当前查询只覆盖已加载窗口；
GitHub REST 列表没有服务端搜索、排序和分组参数，因此它不能表述为跨所有未加载通知的全局搜索。

## 6. Repository Code 正式试点

试点保持 `directoryProvider` 为 Widget 兼容层：

- 根路径和所有子目录统一通过 Runtime acquire；移除目录原有的 Riverpod 定时 keep-alive；
- Loader 同样调用既有 `fetchDirectoryEntries`，没有新增 API；
- 身份包含 server/principal scope、保持大小写的 owner/repository、分支、规范化目录路径和版本；
- Home/全局仓库入口仅在被点击仓库具有可靠默认分支时导航前预取，不批量预取卡片；
- 创建、编辑或删除成功后按 scope、仓库、分支和父目录精确失效。

Repository Code 根 README 是首个 source → derived 试点：

- source 使用既有 `RepositoryServices.fetchReadmeHtml`，404 继续表示“没有 README”；
- artifact 在 compute lane 中通过 `runInWorker()` 进入真实 isolate，复用现有标题 ID 语义并生成
  headings 与可惰性构建的 HTML sections；不缓存 Widget、Element、GlobalKey 或 BuildContext；
- 正式 Code 文档卡消费 artifact，现有 `RepositoryReadmeSliver`、图片 builder、链接和 HTML Widget
  继续作为 Flutter 展示层；
- README Tab 离开再返回、Repository Code Tab 隐藏再返回，以及 Riverpod auto-dispose 后重建，在
  fresh/retain 窗口内均复用同一个 artifact，不重新请求或重新执行顶层 Markdown 解析；
- 显式 Code 刷新和根 `README` / `README.*` 文件提交失效 source，并由依赖图重建可见 artifact；
  `docs/README.md` 等子目录文档不会错误失效根 README。

当前导航前没有可靠的 immutable tree OID，因此试点按现有语义使用分支名。外部提交在 fresh
窗口内可能继续读取 L1 旧数据，显式刷新、前台过期刷新和本地 mutation 精确失效会触发重取。后续
只有在正式数据链稳定提供 tree OID 后才升级身份版本，不能用可能错误的 SHA 推测代替。

## 7. README 图片正式试点

README 图片继续复用原来的 Markdown image builder，但下载与分类已进入 Runtime：

- source ID 使用当前 server/principal scope 与去除 fragment 后的完整 URL；不同账号不会共享
  L1 条目，同一 scope 的并发消费者共享一次下载。Riverpod 薄适配器还用 build generation 丢弃
  账号切换前尚未完成的订阅投递，避免旧 scope 图片覆盖新账号状态。
- 下载使用独立、未认证的 Dio client，显式移除 Authorization、Cookie 与 Proxy-Authorization。
  README 可引用任意第三方 host，绝不能把 GitHub Token 发送给该 host；这里没有改用 `ApiClient`。
- 只接受带 host 的 HTTP/HTTPS URL，最多跟随 5 次跳转；同时检查 Content-Length 和流式累计字节，
  单资源上限 8 MiB，避免先把不受控响应完整读入内存。
- 下载失败、非法 URL 和超限被转换为 `unavailable` 软结果并短期缓存，只让对应图片显示本地重试，
  不让可选图片摧毁整篇 README；显式重试只精确失效该 URL 的 source。
- SVG/栅格判定在 compute lane 中通过真实 worker isolate 执行。worker 只返回 SVG 字符串或“栅格”
  元数据，不把栅格 bytes 再传回主 isolate；栅格 artifact 直接引用 source 中同一份 `Uint8List`。
  source 计入完整字节权重，栅格 artifact 只计元数据权重；SVG 解码字符串按独立产物计重。
- 栅格最终由 `Image.memory` + 尺寸约束交给 Flutter `ImageCache` 解码，SVG 由既有
  `jovial_svg` Widget 展示。Runtime 不缓存解码后的 `ui.Image`、GPU texture 或 Widget，也不宣称
  已经统一 Flutter 图像缓存。

这次迁移统一了下载 Single Flight、生命周期、负缓存、重试、账号隔离和原始字节预算；没有改变
GitHub/第三方图片的认证能力。私有资源若未来需要授权代理，必须先设计可信 host 与凭证边界，不能
把现有账号 Token 注入通用 README 图片请求。

## 8. Repository 社区文档正式试点

CONTRIBUTING 与 SECURITY 继续使用既有 `RepositoryDocumentService.fetchHtml()` 及其候选路径，
没有新增 API、领域模型或页面缓存：

- source/artifact 身份由 server/principal scope、仓库、分支、文档类型和 schema version 组成；
  CONTRIBUTING 与 SECURITY、不同分支和不同账号不会误共享。
- source 负责现有 Contents API 候选路径遍历；全部 404 仍是可缓存的 `null` 数据，非 404 失败仍进入
  明确错误状态。artifact 复用 `MarkdownRenderArtifact`，在 compute lane 通过 worker 生成，不缓存
  Widget 或 BuildContext。
- Code 文档页签与 Security Tab 各持有独立 presence Lease，但相同文档身份落到同一 source/artifact
  条目；同时打开、auto-dispose 后返回和显式刷新都服从同一 Single Flight 与 retain 合同。Security
  卡片只展示是否存在及命中路径，正文和仓库内容保持原文。
- Code 文档正文消费 render artifact，因此返回页面不再重新执行顶层 HTML 解析；Security 与 Code
  并发消费同一 SECURITY 文档时，网络请求和顶层解析各执行一次。
- 显式 Code 刷新会失效当前分支的 README、CONTRIBUTING 与 SECURITY；Security 局部刷新只失效当前
  SECURITY。文件创建、编辑或删除只在路径精确命中现有候选集合时失效对应类型，不会因为任意
  Markdown 变化清空整个仓库文档缓存。

License 没有被并入本合同：它继续使用 branch/blob 加载链，必须先独立审计身份、缺失和 mutation
语义。Wiki、Repository 主 Provider 与其他页面数据尚未迁移；分页目前只有 Repository
Issues/PR 的 forward page 小范围试点。

## 9. Telemetry

Debug/测试可读取结构化事件与汇总，不记录 scope principal 或资源 key。当前包含 fresh/stale
命中、load started/completed、Single Flight join、预取 started/promoted/claimed/canceled/wasted、
旧 generation 丢弃、刷新失败保留数据、dependency cache hit/load、条目数、统一估算字节和因为
可见 Lease 暂时无法回收而产生的超预算状态。

## 10. 限制与迁移顺序

- Runtime 不支持取消已经进入现有网络栈的真实请求；取消仅能阻止尚未开始的排队任务，正确性依赖
  generation 丢弃旧结果。
- 当前禁止 parent 与 dependency 使用同一个调度 lane。这是避免有限并发池递归等待死锁的保守
  合同；未来若需要同类依赖，必须先实现可重入调度或显式 DAG 分层，不能放宽为可能卡死。
- 当前 worker 为每次纯 Dart 变换使用短生命周期 `Isolate.run`，尚无常驻 pool；这保证边界简单但有
  启动开销。没有 Profile 前不声称它一定比 UI isolate 路径更快，也不先建立常驻 worker。
- 尚未接入可靠网络状态源；接口已保留，当前只依据应用生命周期限制投机工作。
- retainFor 不建立每资源 Timer；条目在访问、预算收紧、scope 清理或显式 trim 时惰性回收。
- Repository Code 全目录、根 README source/artifact、README 图片下载/分类，以及 CONTRIBUTING /
  SECURITY source/artifact 已迁移；Repository Issues/PR 与 Notifications 列表的不可变 forward
  page 已部分接入。License、Wiki、其他 Markdown、Issue/PR 详情、Actions、Profile、Home 数据及
  Repository 主 Provider 均未迁移。分页 Controller 仍展开持有已加载项目，尚无有界页窗口。
- README artifact 消除了页面重复的顶层 `html.parse`、标题遍历和 section 切分，但每个惰性
  `HtmlWidget` section 仍可能执行自己的 HTML 构建/解析；Diff 同步解析也未处理。因此 TD-007 只是
  部分推进，不得宣称 Markdown/Diff 性能问题已解决。
- README 图片的 Flutter 像素解码与 GPU 上传不在 Runtime 中。一条合法最大栅格链能够落入默认
  预算，但多个同时持有 Lease 的大资源仍可暂时超过预算；Telemetry 会如实标记，释放后才回收。
  真实 heap、解码与 GPU 内存峰值仍需 Profile。
- 没有 Profile/Release 帧与内存对比，不能从请求次数测试推导“页面更流畅”或给出帧时间结论。

后续迁移必须逐资源完成身份、正式 Loader、mutation 失效、presence 所有权和确定性测试。当前
README/图片仍需 Profile/Release 冷暖基线；若 isolate 启动开销成为证据充分的瓶颈，再评估常驻
pool。License 与 Wiki 仍须独立审计，不能因二者都展示 Markdown 就强行并入同一加载语义。

通用 forward page resource 桥接已经由 Repository Issues/Pull requests 与 Notifications 两个生产
消费者复用，第二个消费者只增加领域 Recipe、Provider-owned 会话和 mutation adapter，没有修改
执行器核心、正式 Service、`PaginationController` 或业务模型。下一步应人工复核真实大仓库/大收件
箱并设计有界 Controller 页窗口与距离式预取；在 Profile/Release 和实体保留量都被证明前，仍只能
标记“部分接入”。
