# ResourceRuntime 信息流接入任务模板

状态：Reusable template
日期：2026-07-24

使用本模板时复制“任务卡”章节到当轮设计或实现记录。不得只填写 Runtime 类型和测试文件；
必须从当前生产入口追踪到正式 Service，并证明用户可见行为。

参考：

- [信息流接入清单](resource-runtime-information-flow-inventory.md)
- [ResourceRuntime 架构](resource-runtime-architecture.md)
- [开发约束](development-constraints.md)

## 1. 任务卡

### 1.1 范围声明

| 项目 | 本轮填写 |
| --- | --- |
| 精确页面/路由 |  |
| 精确主 Tab / 页内筛选 |  |
| 本轮目标 |  |
| 非目标 |  |
| 正式数据源 |  |
| 预计修改文件 |  |
| 既有行为影响 |  |
| 用户可见验收条件 |  |
| 停止条件 |  |
| 验证命令 |  |

### 1.2 当前生产链

```text
Route:
  → Page:
  → main tab:
  → in-page state/filter:
  → Provider/Notifier:
  → PaginationController/query session:
  → Service:
  → REST/GraphQL/Drift:
```

必须记录：

- 是否有第二次路由、整页替换或因异步数据变化而更换外壳；
- Provider 在何时创建、auto-dispose、keep-alive 和失效；
- Controller 由谁创建、是否在 Tab/筛选切换时保持身份；
- 首屏请求数、后续页请求数、是否有循环抓取或 `Future.wait` 扇出；
- 是否已有 `APICache`、entity store 或其他 L2，不能另建重复 Service。

### 1.3 可证伪复现

```text
前置账号/权限：
网络条件：
数据规模：
窗口与文字缩放：

1. 从 ______ 进入 ______。
2. 等待首屏出现 ______。
3. 切换 ______ → ______ → ______。
4. 滚动到 ______，触发下一页/预取。
5. 返回上一状态或离开页面后返回。
6. 执行显式刷新或 mutation。

必须出现：
-

禁止出现：
- 重复首次请求：
- 返回时首屏骨架：
- 旧 query 结果串入新 query：
- 被淘汰页面继续占用可见 Lease：
```

## 2. 数据与规模

| 维度 | 值/上限 | 证据 |
| --- | --- | --- |
| 单页条数 |  |  |
| 典型/极端总量 |  |  |
| 单项估算字节 |  |  |
| 单页估算权重 |  |  |
| 请求数与扇出 |  |  |
| 解析/解码成本 |  |  |
| 公开/私有/企业服务器差异 |  |  |
| mutation 类型 |  |  |

不清楚总量时不得假定“小列表”。先使用 GitHub API 合同、fixture 或真实仓库观测给出上限策略。

## 3. 接入决策

### 3.1 资源分类

勾选并说明：

- [ ] 单值只读 snapshot
- [ ] 不可变分页 page
- [ ] source → derived artifact
- [ ] 轻量计数/摘要
- [ ] mutation 后可失效的查询结果
- [ ] 长轮询/stream（不进入普通 Runtime，转专用 session）
- [ ] 本地数据库/工作区状态（不进入 Runtime）
- [ ] 表单、筛选、滚动或草稿（页面状态）

### 3.2 为什么接入

```text
需要 Runtime 统一的能力：
- Single Flight:
- SWR:
- scheduling:
- prefetch:
- retention:
- memory budget:
- dependency invalidation:
- telemetry:

继续由现有层负责：
- 页面/筛选：
- Controller：
- Provider/Notifier：
- Service：
- mutation：
```

如果只为了“API 看起来统一”而没有复用、预算或调度收益，则不接入。

## 4. 身份合同

```text
ResourceId kind:
schema version:
ResourceScope:
  server:
  principal:
domain key:
  owner/repository/user:
  branch/ref/SHA:
  path/number/query:
page key:
  cursor or page:
  direction:
  page size:
  sort/filter:
normalization:
```

身份检查：

- [ ] owner/repository 大小写策略明确；
- [ ] 匿名、账号 A、账号 B、GHES 不共享私有数据；
- [ ] branch 名与 immutable SHA 不混用；
- [ ] query/filter/sort/page size 改变时不会命中旧页；
- [ ] cursor 方向和锚点足以表达双向时间线；
- [ ] schema/loader contract 改变时升级版本；
- [ ] 不把 Token、Cookie、完整搜索隐私字段写入 Telemetry。

## 5. 分页与查询会话合同

```text
PaginationController owns:
- current query/filter:
- page order:
- next/previous cursor:
- selected item/anchor:
- scroll restoration:
- refresh intent:

ResourceRuntime owns:
- page result by immutable page key:
- in-flight join:
- fresh/stale:
- scheduling/prefetch:
- retain/eviction:
- request telemetry:
```

页面窗口策略：

| 项目 | 决策 |
| --- | --- |
| Controller 最多保留查询会话数 |  |
| 每会话最多保留实体页数 |  |
| 超出窗口后保留页键还是轻量索引 |  |
| 返回已淘汰页的行为 |  |
| 下一页预取触发距离 |  |
| refresh 是否保留旧页 |  |
| query 改变是否清除旧结果 |  |

禁止条件：

- Controller 无界聚合所有项；
- 页面先循环抓完全部页才展示；
- Runtime LRU 已淘汰资源，但 Controller 仍永久持有同一批完整对象；
- 第五个查询会话淘汰后仍声称永不重载。

## 6. Freshness、保留与预算

| 策略 | 取值 | 理由 |
| --- | --- | --- |
| freshFor |  |  |
| retainFor |  |  |
| negative cache |  |  |
| estimatedWeight |  |  |
| visible Lease 所有者 |  |  |
| retained Lease 所有者 |  |  |
| entry budget |  |  |
| weight budget |  |  |
| memory trim 行为 |  |  |

分别定义：

1. 首次进入且无缓存；
2. fresh 命中；
3. stale + visible 的 SWR；
4. stale + retained；
5. 显式刷新；
6. refresh 失败但旧数据可用；
7. LRU/内存压力淘汰后返回；
8. scope 清理与账号切换。

## 7. 调度、预取与计算

| 工作 | lane | priority | 并发/批次 | 可取消边界 |
| --- | --- | --- | --- | --- |
| 首屏请求 |  | interactive |  |  |
| 下一页 |  | interactive |  |  |
| SWR |  | refresh |  |  |
| 视口前预取 |  | prefetch |  |  |
| parse/decode |  |  |  |  |

检查：

- [ ] 没有对未知数量子资源直接无界 `Future.wait`；
- [ ] 候选路径探测缓存命中与明确缺失；
- [ ] 大解析不在 `build` 中重复执行；
- [ ] 只有可发送的纯 Dart 数据进入 worker；
- [ ] 没有 Profile 前不预设常驻 worker 一定更快；
- [ ] hidden/paused 时不启动新预取；
- [ ] 预取被真实 acquire 接管时不重复请求。

## 8. 依赖、mutation 与失效

```text
source:
derived artifacts:
static dependencies:
resource tags:
```

| 事件 | 失效范围 | 保留/overlay 行为 |
| --- | --- | --- |
| 显式刷新 |  |  |
| create |  |  |
| update/edit |  |  |
| delete |  |  |
| star/watch/read/unread 等轻 mutation |  |  |
| branch/ref 改变 |  |  |
| logout/account switch |  |  |

要求：

- mutation 继续由领域 Notifier/Service 执行；
- 可以先做本地 overlay，但成功后必须精确失效正式资源；
- 不用模糊字符串清全仓缓存；
- source revision 变化必须使 derived artifact 失去 fresh 资格；
- 老 generation 完成结果不能覆盖新 mutation。

## 9. UI 状态映射

| Runtime / Controller 状态 | 用户可见状态 |
| --- | --- |
| 首次 loading，无数据 | 与正式布局同构的多行骨架 |
| fresh data | 正常内容 |
| stale data + refreshing | 保留内容 + 局部刷新提示 |
| load next page | 列表尾部骨架，不替换首屏 |
| empty page / empty query | 明确空状态 |
| first load failure | 错误 + 重试 |
| refresh failure with data | 保留旧数据 + 非阻断错误 |
| rate limited / permission denied | 领域化提示，不伪装空数据 |
| evicted then revisited | 可解释局部恢复，不整页外壳跳变 |

必须使用稳定 App Chrome；加载态与正式页不得更换成两套 AppBar/Scaffold。

## 10. 验证矩阵

### 10.1 正向结果

- [ ] 首次进入得到真实数据；
- [ ] 空数据得到明确空状态；
- [ ] 下一页追加顺序正确；
- [ ] 显式刷新得到新数据；
- [ ] mutation 后目标资源更新；
- [ ] 360/800/1440px 无溢出；
- [ ] 适用的 1.3×/2× 文字缩放通过；
- [ ] Reduced Motion 保持状态语义。

### 10.2 禁止事件

- [ ] 两个并发消费者只调用一次 Loader；
- [ ] Open → Closed → Open 不产生第三次首屏请求，除非策略已过期或明确淘汰；
- [ ] 主 Tab 离开返回不重建 Controller；
- [ ] query 切换不会显示上一 query 的晚到结果；
- [ ] 下一页加载不重新显示整页骨架；
- [ ] refresh 失败不清空旧列表；
- [ ] 账号切换不收到旧 scope 完成结果；
- [ ] LRU 淘汰后没有悬挂 Lease 或无界实体副本；
- [ ] 预取取消与浪费不会重复计数；
- [ ] mutation 只失效预期资源。

### 10.3 观测记录

```text
测试命令：
通过数量：
请求计数：
Runtime telemetry：
人工操作与截图：
未运行项及原因：
```

## 11. 性能记录

没有 Profile/Release 同环境数据时填写“尚未建立基线”，不得用 Debug 观感或单元测试请求次数替代。

| 场景 | 冷启动 | fresh 命中 | stale/SWR | 大数据集 | 内存峰值 |
| --- | --- | --- | --- | --- | --- |
| 修改前 |  |  |  |  |  |
| 修改后 |  |  |  |  |  |

同时记录设备、平台、构建模式、网络、账号、仓库/列表规模和采样方法。

## 12. 完成报告

```text
已满足：
-

仅有基础：
-

已登记：
-

待验证：
-

需求 → 实现 → 验证：
-

没有改变：
- OAuth / codegen / database / route / business model ...
```

只有生产入口、真实数据、所有可见状态、生命周期、请求次数、响应式与适用验证同时成立时，才能写
“该信息流已接入”。仅新增 `ResourceSpec`、Provider、骨架或叶组件测试时，必须写“仅有基础”或
“部分接入”。
