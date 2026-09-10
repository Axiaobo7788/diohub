# Contributing to DioHub

Thank you for contributing. This repository is an independent DioHub downstream;
pull requests normally target `develop`.

## Project rules

The contributor-facing quality and completion rules are maintained in
[`docs/development-constraints.md`](docs/development-constraints.md). Current
product status and known debt live in
[`docs/workbench-progress.md`](docs/workbench-progress.md) and
[`docs/technical-debt-register.md`](docs/technical-debt-register.md). Read the
architecture document for the area you change. `AGENTS.md` is the automation
entry point and links to the same canonical documents; this guide does not copy
their detailed rules.

## Prerequisites

- Flutter 3.44.7 and Dart 3.12.x
- Git with submodule support
- Native toolchains for the platform being tested
- Android work: JDK 17, Android SDK 36, and NDK `28.2.13676358`

FVM, Lefthook, and Cocogitto are optional local conveniences. The Flutter version
is pinned in `.flutter-version` and `.fvmrc`.

## Local setup

```bash
git clone --recurse-submodules --branch develop \
  https://github.com/Axiaobo7788/diohub.git
cd diohub

cp .env.example .env.json
dart run tool/bootstrap.dart
```

Keep `.env.json` and real credentials out of Git. GitHub Device Flow requires a
public Client ID, not a client secret or callback URL. Optional integrations can
remain empty.

Run the app with the development flavor:

```bash
# Android
flutter run --flavor dev -t lib/main.dart \
  --dart-define-from-file=.env.json

# Linux
flutter run -d linux -t lib/main.dart \
  --dart-define-from-file=.env.json
```

Regenerate sources only after changing GraphQL operations, generated models,
database schema, or routes:

```bash
dart run tool/bootstrap.dart --codegen-only
```

The bootstrap script runs package and root generators in dependency order. Do not
commit populated environment configuration or generated artifacts outside the
paths selected by the repository bootstrap.

## Branches and commits

Create feature or fix branches from `develop` and target `develop`. The exact
allowed merge paths are enforced by `.github/workflows/branch-enforce.yaml`.
Do not rewrite another contributor's branch or discard unrelated worktree changes.

Use Conventional Commit messages when committing:

```text
feat(scope): concise description
fix(scope): concise description
docs(scope): concise description
test(scope): concise description
refactor(scope): concise description
```

Repository workflows change over time and some build/release workflows are manual
or intentionally paused. Inspect the current files under `.github/workflows/`
instead of relying on a fixed list of automatic checks in this guide.

## Verification

Run checks serially on low-memory machines. For Dart/Flutter changes, the expected
baseline is:

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

Select focused tests from the canonical development constraints. Run heavy tasks
serially on low-memory machines. Do not delete failing tests to obtain a pass. If a
check cannot run, record the command, reason, impact, and narrower evidence actually
obtained.

## Pull request description

Describe the user-visible problem, exact scope, formal data source, verification
commands and results, and any unverified platform or responsive state. Separate
completed work from foundations, blockers, and pending work.

Security issues must be reported privately through the process in
[`SECURITY.md`](SECURITY.md), not through a public issue or pull request.

## License and conduct

Contributions are made under the repository's GPL-3.0 license. Be respectful,
specific, and evidence-driven in issues, reviews, and discussions.
