# DioHub

DioHub is an independent Flutter GitHub client for Android and desktop
(Windows, macOS, and Linux). This downstream is rebuilding the application around
a shared Material 3 information architecture while preserving the existing GitHub
API, GraphQL, authentication, caching, database, and state-management layers.

This repository follows the pinned upstream baseline and adoption policy in
[`UPSTREAM.md`](UPSTREAM.md). It is not an automatic mirror of upstream DioHub.

## Development status

The active branch is under development and is not a release-completeness claim.
The shared Material 3 Home and repository shell, GitHub Device Flow, localization,
and the pure Dart `ResourceRuntime` have production consumers, while legacy and
new UI still coexist and several detail/workbench surfaces remain incomplete.
For the exact completed, partial, blocked, and pending scope, see
[`docs/workbench-progress.md`](docs/workbench-progress.md) and
[`docs/technical-debt-register.md`](docs/technical-debt-register.md).

## Technology and architecture

The retained core stack is:

- Flutter and Material 3 for shared Android/desktop UI
- Riverpod for composition, dependency injection, and UI state
- Dio plus generated GraphQL operations behind service/gateway boundaries
- Drift for typed local persistence
- AutoRoute for navigation and deep links
- Sentry and Talker behind configurable diagnostics boundaries

The repository intentionally contains generated GraphQL/model code and a broad
legacy UI surface. Dependency and code-generation reduction is a later, measured
task rather than a prerequisite for every UI migration. See
[`docs/technology-simplification.md`](docs/technology-simplification.md).

Important source areas:

```text
lib/app/                         application setup, configuration, theme
lib/common/resource_runtime/     pure Dart resource control plane
lib/providers/                   Riverpod bindings and page/query sessions
lib/services/                    GitHub and application service boundaries
lib/view/app_chrome/              shared global application shell
lib/view/home/                    unified Home
lib/view/repository/              repository shell and content pages
lib/view/notifications/           notifications surface
lib/view/profile/                 profile surfaces
lib/view/settings/                settings surfaces
lib/workbench/                    Workbench domain, data, and application layers
packages/                         internal models, database, GraphQL, and lint packages
```

## Platform validation boundary

Android and Linux are the current local validation baselines. Windows and macOS
runners are present and share the Flutter implementation, but must be validated on
their native hosts before a change can be called cross-platform complete. Do not
infer platform support from the existence of a runner alone.

## Building from source

### Prerequisites

- Flutter 3.44.7 with Dart 3.12.x
- Git submodules
- Android: JDK 17, Android SDK 36, NDK `28.2.13676358`, accepted SDK licenses
- Native platform toolchains for any additional desktop runner being built

### Checkout and bootstrap

```bash
git clone --recurse-submodules --branch develop \
  https://github.com/Axiaobo7788/diohub.git
cd diohub

cp .env.example .env.json
dart run tool/bootstrap.dart
```

`.env.json` is ignored by Git. Keep real credentials outside the repository.
Device Flow only needs a public GitHub OAuth Client ID; a client secret and callback
URL are not required for normal sign-in. Downstream distributions may override the
client ID through `--dart-define-from-file`.

### Run

```bash
# Android development flavor
flutter run --flavor dev -t lib/main.dart \
  --dart-define-from-file=.env.json

# Linux
flutter run -d linux -t lib/main.dart \
  --dart-define-from-file=.env.json
```

After changing GraphQL operations, models, database tables, or generated root
sources:

```bash
dart run tool/bootstrap.dart --codegen-only
```

Low-memory machines should run Flutter, Gradle, CMake, analysis, and test tasks
serially.

## Project documentation

- [`AGENTS.md`](AGENTS.md): automation entry point for implementation work
- [`docs/development-constraints.md`](docs/development-constraints.md): product,
  quality, motion, performance, and completion rules
- [`docs/workbench-progress.md`](docs/workbench-progress.md): current state and
  Now/Next/Later
- [`docs/technical-debt-register.md`](docs/technical-debt-register.md): accepted and
  unresolved engineering debt
- [`docs/resource-runtime-architecture.md`](docs/resource-runtime-architecture.md):
  implemented Runtime contracts
- [`docs/resource-runtime-information-flow-inventory.md`](docs/resource-runtime-information-flow-inventory.md):
  per-information-flow migration state
- [`docs/resource-runtime-integration-template.md`](docs/resource-runtime-integration-template.md):
  checklist for a new Runtime integration
- [`CONTRIBUTING.md`](CONTRIBUTING.md): contribution workflow

## Security and privacy

Report vulnerabilities privately and review the current credential boundary in
[`SECURITY.md`](SECURITY.md). An unresolved historical rotation obligation is
tracked separately in
[`SECURITY_ROTATION_NOTICE.md`](SECURITY_ROTATION_NOTICE.md).

[`PrivacyPolicy.md`](PrivacyPolicy.md) is an implementation data-handling summary,
not a release privacy notice. A shipping distributor must supply the missing
operator, retention, contact, jurisdiction, and integration review.

## License

GPL-3.0. See [`LICENSE`](LICENSE).
