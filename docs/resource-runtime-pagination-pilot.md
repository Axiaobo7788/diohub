# ResourceRuntime 分页生产试点

状态：Partial implementation（仅 Repository Issues / Pull requests 列表）
日期：2026-07-24

## 1. 精确范围

本试点只迁移以下正式入口的不可变列表页结果：

- Repository → Issues；
- Repository → Pull requests；
- 登录态复用既有 `SearchService` 与 GraphQL transport，但改用只包含列表字段的
  `searchRepositoryIssuePulls` 投影；
- 未登录态复用既有 `PublicRepositoryService.searchIssuesPulls` REST。

没有新建第二套列表、分页 Controller、缓存、Repository 路由或详情页。GraphQL 只新增一份
Repository 列表投影，`SearchService` 仍是正式服务边界；公开 REST DTO 不变。通用
`PaginationController` 仅增加 Runtime stale page 原位替换能力，测试注入的
`SearchTypeConfigFactory` 继续走原有 source，不会误读正式账号 scope。

## 2. 所有权

```text
Repository page
  └── SearchScrollSlivers
      ├── query / filter / sort / current tab
      ├── four-session LRU / scroll / flattened visible items
      └── PaginationController
          └── RuntimeForwardPageSource
              └── ResourceRuntime immutable page
                  └── existing GraphQL or REST Service
```

页面与 Controller 仍拥有查询会话、页序、刷新意图和滚动。Runtime 只拥有按显式页键标识的不可变
page result、Single Flight、fresh/stale、统一调度、保留期限、失效与估算预算。

## 3. 身份与策略

每页身份包含：

- server/principal `ResourceScope`；
- owner/repository；
- authenticated GraphQL 或 public REST；
- 完整规范化查询；
- GraphQL cursor 或 REST page number；
- page size；
- schema version。

GraphQL 首页使用显式 `cursor:start`，后续页必须有非空 `endCursor`；REST 使用 `page:1`、`page:2`
等显式页号。策略为 fresh 1 分钟、retain 5 分钟；估算重量为每项 2 个统一单位，空页 1 个单位。

## 4. 交付语义

- 首次加载：Controller 显示现有五行响应式骨架，Runtime 启动正式 Service 请求；
- fresh 命中：新建 Controller 可以直接复用 Runtime 页，不重新显示首屏骨架或发请求；
- Open / Closed 往返：页面保留最近四个查询 Controller，返回已访问查询时不重新请求；
- 下一页：由现有可视 sentinel 触发，显式页键进入独立 Runtime 资源，不替换首屏；
- stale 命中：立即交付旧首页并在后台 revalidate；Controller 仍只表示该首页时，新结果原位替换，
  已继续分页时则只更新 Runtime，避免游标页重叠；
- 显式刷新：精确失效当前 query 的全部页，Controller 在新首页成功前保留旧列表；失败进入既有
  refresh-aware error 状态；
- 账号 scope 变化：销毁旧查询 Controller，以新 scope 重建 source；旧账户页不能跨 scope 复用；
- page 交付后释放 Lease，Runtime 可按 retain、预算或内存压力回收条目。
- 隐藏 Repository Tab 的 forward sentinel 不发请求；重新可见后才允许加载下一页。

## 5. 已证明

- 两个并发 source 请求同一页只执行一次 Loader；
- 新 Controller 会复用 fresh 页；
- 不同 next page 使用不同资源身份并可分别复用；
- reset 会失效当前查询并等待替换首页；
- 刷新失败时 `PaginationController` 保留旧项目；
- stale 首页不等待网络即可进入 Controller，后台完成后会原位替换；
- 正式 Repository 入口中 Open → Closed → Open 只加载两个查询页，显式刷新才产生第三次加载；
- 未登录正式入口使用 REST transport；
- 页面自动推进 `page:1 → page:2`；
- 账号 scope 变化后执行新 scope 加载；
- 原有 Repository Issues/PR 响应式、筛选、错误、刷新、LRU 与公开行场景不回归。
- 登录列表查询不再请求正文、assignees、projectItems、reactionGroups、review/check 等详情字段，
  labels 上限由 100 收敛为列表实际展示的 5；
- 隐藏 sentinel 保持 0 请求，重新可见后才请求下一页；
- 每个保留的 Repository Tab 使用独立透明 Material，转场不再把多个 Tab 的 Ink feature 合入同一
  reference box 边界。

## 6. 尚未完成

以下项目不能因本试点通过而写成“统一分页完成”或“页面已经更快”：

- `PaginationController` 仍持有当前会话已经展开的全部项目对象，尚未实现有界页窗口或轻量索引；
- 下一页仍由可视 sentinel 按需加载，隐藏页已禁止自动分页，但尚未加入 Runtime 距离式预取；
- Issue/PR mutation overlay 与页标签精确失效尚未接入；
- query 晚到隔离与四会话 LRU 复用既有 Controller 回归，本轮没有改变其所有权；
- Issue/PR 详情、评论、Review、commits、files 和 review threads 尚未迁移；
- Repository 主查询中的六组快捷计数尚未拆分；
- 没有 Profile/Release 冷暖耗时、帧时间或 heap 证据。
- GraphQL handler 仍会按请求构造 client/Dio，连接复用收益尚未单独验证；应在 transport 专项中
  处理，不能为 Issues/PR 再建一套客户端。

因此当前结论是：通用 forward page bridge 与 Repository Issues/PR 首个生产试点已接入；全局分页
资源化和大列表内存治理仍在进行中。

## 7. 下一步入口条件

继续扩散前必须先完成：

1. 人工验证真实大仓库的首屏、连续翻页、Open/Closed 往返、刷新失败和返回滚动；
2. 设计 Controller 有界页窗口，证明 Runtime LRU 能实际降低实体保留量；
3. 为列表 mutation 定义 overlay、成功失效和失败回滚；
4. 建立距离式预取的网络/内存准入和取消测试；
5. 再选择 Issue/PR 详情时间线或 Home Events 作为第二个分页试点。
