# DioHub 技术栈精简结论（Later）

最后更新：2026-08-11

状态：已记录，暂缓实施

与 Workbench UI 关系：不是进入第一版功能性 UI 的前置条件

## 1. 结论

核心技术选型合理，不建议更换 Flutter、Riverpod、Dio/GraphQL、Drift 或 AutoRoute。

需精简的是：

- 根应用中的零引用/重复依赖。
- UI/Provider 对 GraphQL 生成类型的直接依赖。
- `diohub_models` 中少量 Flutter 与路由类型泄漏。
- Freezed/GraphQL 生成范围与构建时间。
- AI、Premium、Shorebird 等非 MVP 能力与核心应用的耦合。
- HTTP 传输缓存与 Workbench 业务快照的责任边界。

## 2. 当前证据快照

以 2026-08-11 当前已生成 codegen 的工作区为准：

| 项目 | 数量 |
| --- | ---: |
| Dart 生成文件 | 303 |
| Dart 生成代码 | 约 1,522,087 行 |
| 手写/其他 Dart 代码 | 约 231,209 行 |
| GraphQL 源文件 | 135 |
| GraphQL 生成 Dart | 135 个文件，约 144 万行 |
| 根应用直接依赖 | 88 |
| Freezed 声明 | 约 188 |
| 手写 Dart 超过 500 行的文件 | 74 |

上述数字用于判断精简方向，不用作质量或覆盖率结论。文件数和行数会随 codegen 与 UI
迁移快速变化；实施任何删除前必须重新扫描，不能把本表当成永久依赖清单。

本文只保留“什么技术继续使用、什么方向可精简”的长期决策。已进入实施的具体问题应登记到
[`technical-debt-register.md`](technical-debt-register.md)，当前项目状态只在
[`workbench-progress.md`](workbench-progress.md) 维护，避免三份文档同时复制完成度。

## 3. 保留的核心技术

| 技术 | 决定 | 边界 |
| --- | --- | --- |
| Flutter | 保留 | Android + Windows/macOS/Linux 共用 UI，平台能力通过适配器隔离 |
| Riverpod | 保留 | 用于组合、依赖注入和 ViewState，不进入纯 Domain |
| Dio + GraphQL | 保留 | 只由 Service/Gateway 层接触传输与生成类型 |
| Drift | 保留 | 作为 Workbench 类型化持久快照与同步状态来源 |
| AutoRoute | 保留 | 既有路由广泛使用，暂不为更换而更换 |
| Sentry + Talker | 保留但隔离 | Talker 处理本地日志，Sentry 处理可选遥测，统一经过日志适配层 |

## 4. 精简候选

### 4.1 零直接 import 的根依赖

当前全仓 Dart 源码扫描未找到以下 package import：

- `animations`
- `archive`
- `crypto`
- `device_info_plus`
- `encrypt`
- `expand_widget`
- `file_picker`
- `flex_color_picker`
- `flex_list`
- `flutter_colorpicker`
- `flutter_local_ai`
- `flutter_slidable`
- `graphview`

这只是候选清单，不代表可以批量直接删除。每个包都必须再核对 platform registration、配置文件、生成器和间接依赖后，逐个移除并回归。

### 4.2 重复/位置不当

- 根应用声明 `drift_flutter`，但实际所有者应为 `diohub_database`。
- 根应用声明 `gql_dio_link`，实际所有者应为 `diohub_gql_client`。
- `freezed` 应是生成阶段依赖，运行时模型使用 `freezed_annotation`。
- `flex_color_picker` 与 `flutter_colorpicker` 同时存在但当前均无直接 import。
- `flutter_material_design_icons` 与 `flutter_vector_icons` 均在使用；可在 UI 稳定后收敛图标体系，不在当前进行高改动迁移。

## 5. 结构性精简

### 5.1 `diohub_models` 纯 Dart 化

`diohub_models` 当前只有少量文件需要 Flutter/AutoRoute，但因此整个包无法作为纯 Dart 基础。Later 阶段应将 `Color`、`IconData`、Flutter annotation 和导航目标移到 presentation/navigation 层。

预期收益：

- 更多纯 Dart 快速测试。
- Workspace Domain、CLI 与 isolate 可复用模型。
- 避免单元测试被 `dart:ui` 强制升级为 Flutter test。

### 5.2 GraphQL 生成类型隔离

当前直接 import `diohub_graphql` 的文件包括：

- View：116 个文件。
- Common：43 个文件。
- Provider：30 个文件。
- Service：35 个文件。

目标不是删除 GraphQL，而是使生成类型只停留在 Source/Service/Adapter 边界。新 Workbench UI 只消费 Domain/ViewState。

### 5.3 减少新增 codegen

- 新 Workbench 小型值对象优先使用手写不可变类。
- API/JSON/Drift schema 仍可使用生成器。
- 在既有 GraphQL `copyWith` 调用退出 UI/Provider 后，再评估 `graphql_codegen` 的 `disableCopyWithGeneration`。
- 不为了减少行数牺牲类型安全和公开构建可复现性。

## 6. 缓存简化原则

两层缓存可以同时保留，但必须分工：

| 层 | 责任 |
| --- | --- |
| Dio HTTP Cache | 短期传输缓存、条件请求、请求去重 |
| Drift Workbench Repository | 类型化业务快照、schema 版本、最后同步时间、离线和错误状态 |

UI 不应同时理解 HTTP Cache、GraphQL 生成类型和 Drift 表。

## 7. 延后实施顺序

1. 完成 Workbench 纵向 MVP 的稳定边界。
2. 逐个移除零引用与重复根依赖。
3. 将 `diohub_models` 中 Flutter/路由类型外移。
4. 将 GraphQL 生成类型逐步退出 View/Common/Provider。
5. 评估 GraphQL `copyWith` 生成与 Freezed 使用范围。
6. 决定 AI、Premium、Shorebird 的产品地位与插件化边界。
7. 在 Workbench UI 稳定后收敛颜色、图标、Sliver 和其他微型 UI 依赖。

## 8. 实施护栏

- 每次只移除一类依赖或一个结构泄漏。
- 每次都记录 `pub get`、analyze、tests、Android 与 Windows/macOS/Linux 状态；未在对应 runner 验证的平台必须明示标注。
- 不依赖“搜索不到 import”一个证据批量删除 plugin。
- 不在精简阶段同时更换状态管理、路由、网络层或数据库。
- 不更改 OAuth scope、密钥或发布签名。
- 如精简会破坏公开 codegen/build 可复现性，则应停止并重新评估。

## 9. 参考

- Flutter 架构建议：<https://docs.flutter.dev/app-architecture/recommendations>
- Flutter 架构指南：<https://docs.flutter.dev/app-architecture/guide>
- GraphQL Codegen 选项：<https://pub.dev/packages/graphql_codegen>
