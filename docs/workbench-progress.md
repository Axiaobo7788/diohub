# DioHub Workbench 项目进度

最后更新：2026-07-21

当前阶段：Phase 1 进行中（远程/本地纯 Dart 边界与统一 Controller 已建立）

UI 状态：可开始独立路由与 Fake 驱动的功能性 UI 骨架；真实本地 Git/编辑器接线待 Desktop Source

## 1. 项目目标

DioHub Workbench 是一个独立 downstream，目标是在保留 DioHub 现有 GitHub 能力的同时，建立面向 Linux Desktop 和 Android 的本地优先开发者工作台。

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
| 基线提交 | `5e77b8d24fee4dd438aa26422b7558ac61a2b26f` | 上游六个月工作的 squash 提交 |
| Worktree | Dirty | 当前有 60+ 个 changed/untracked 条目，包含基线修复、依赖更新、Workbench 边界与文档；尚未提交 |
| Flutter | 3.44.7 | Dart 3.12.2 |
| Android SDK | Passed | SDK 36.1、Build Tools 36.1、NDK 28.2、JDK 21，licenses 已接受 |
| Linux 系统依赖 | Passed | `wpe-webkit-2.0` 2.52.4 已可用 |
| Android Debug | Passed | 已生成 `build/app/outputs/flutter-apk/app-dev-debug.apk` |
| Linux Debug | Needs revalidation | WPE 阻塞已解决；便携玻璃着色器已移除，但后续构建因系统内存/Swap 耗尽被终止，尚不能声称通过 |
| Root tests | Needs current rerun | 早期基线曾 54/54 通过，但需在最新兼容修复后串行复跑 |
| Workbench tests | Passed | 17/17 纯 Dart 契约/边界测试通过 |
| Workbench analyze | Passed | `lib/workbench` 和 `test/workbench` 均为 0 issues |

## 3. 已完成

- 确认 `develop@5e77b8d` downstream 基线与 `upstream` 记录策略。
- 建立 Flutter 3.44.7 / Dart 3.12.2 可复现工具链约束。
- 修复公开 bootstrap/codegen 路径，不再依赖私有 premium codegen CI。
- 完成 Android SDK/NDK/licenses 配置并验证 Android Debug APK。
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

## 4. 当前边界

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

## 5. 进入生产 UI 前置门槛

信息架构、线框图和静态布局研究可以立即进行。开始接入真实数据的 Workbench UI 前，应满足以下门槛：

### Gate 1：当前平台基线可区分回归

- [x] Android Debug 构建通过。
- [ ] 在充足内存下串行复跑 Linux Debug，记录是否仍有 Sentry 含空格路径链接问题。
- [ ] 在最新代码上串行复跑 root tests，不与平台构建并发。
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

## 6. Now / Next / Later

### Now

1. 固定 Workbench 桌面三栏/双栏与移动折叠信息结构，建立独立路由的 Fake 功能性 UI 骨架。
2. 建立 WorkspaceDesktop Source，仅使用可执行文件 + 参数数组调用系统 `git` / `code` / `codium`。
3. 补齐 Production Source 的 offline / permission / rate-limit 精确分类。
4. 在系统内存恢复后，串行复跑 Linux Debug 与 root tests。

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

## 7. 当前非目标

- 不替换 Flutter、Riverpod、Dio、Drift 或 AutoRoute。
- 不在 UI 前全量精简依赖。
- 不重写全部 DioHub 页面。
- 不扩大 OAuth scope，不更改 token 存储模型。
- 不在 MVP 中实现完整 Git GUI。
- 不自动 checkout、fetch、切分支、merge、rebase 或丢弃本地修改。
- 不删除现有移动 UI。

## 8. 低内存执行约束

- 同一时间只运行一个 analyze/test/build 任务。
- Android 与 Linux 绝不并发构建。
- 单元测试优先使用纯 Dart，并设置 `--concurrency=1`。
- Gradle 需限制 worker/堆大小，完成后停止本项目 daemon。
- 在 Swap 耗尽或可用内存过低时，不启动 Flutter/Gradle 全量构建。
- codegen 只在 schema/model 变化时执行，不作为每个小步骤的例行验证。

## 9. 停止条件

出现以下任一情况时，当前小步骤应停止并先汇报：

- 新边界需要修改 OAuth scope、Client ID/Secret 或签名配置。
- 需要执行 Git 写操作或修改用户工作区。
- 必须更换状态管理、路由或数据库才能继续。
- 新 Workbench 代码导致现有 Android 构建或移动路由回归。
- 系统可用内存/Swap 不足以安全执行验证。
- 当前改动超出单个可审查边界。

## 10. 下一个唯一建议

下一步只固定 Workbench 的响应式信息结构，并建立一个使用 Fake 快照的独立功能性 UI 路由。不删除旧 Repository 页面，不重画全站视觉，不执行技术栈精简。
