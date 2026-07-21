# Contributing to DioHub

Thank you for your interest in contributing to DioHub! This guide will help you get started with development.

## Prerequisites

Before you begin, ensure you have the following installed:

- **Flutter SDK**: `3.44.7` (stable channel)
- **FVM** (Flutter Version Management): [Installation guide](https://fvm.app/docs/getting_started/installation)
- **Lefthook**: Git hooks manager - `brew install lefthook` or [other methods](https://github.com/evilmartians/lefthook#install)
- **Cocogitto**: Conventional commit tool - `brew install cocogitto` or [cargo install](https://github.com/cocogitto/cocogitto#installation)

## Local Setup

1. **Clone the repository**

```bash
git clone https://github.com/namanshergill/diohub.git
cd diohub
```

2. **Use FVM to set Flutter version**

```bash
fvm use
```

This will install and use the Flutter version specified in `.fvmrc`.

3. **Initialize submodules and bootstrap public dependencies**

```bash
git submodule update --init --recursive
fvm dart run tool/bootstrap.dart
```

4. **Install Git hooks**

```bash
lefthook install
```

This sets up pre-commit hooks for code formatting and commit message linting.

5. **Set up environment variables**

Create a `.env.json` file in the project root:

```bash
cp .env.example .env.json
```

Edit `.env.json` and fill in your values (get GitHub OAuth credentials from [GitHub Developer Settings](https://github.com/settings/developers)):

```json
{
  "GITHUB_CLIENT_ID": "your_client_id",
  "GITHUB_CLIENT_SECRET": "your_client_secret",
  "SENTRY_DSN": "",
  "SENTRY_AUTH_TOKEN": "",
  "SLACK_CLIENT_ID": "",
  "SLACK_CLIENT_SECRET": ""
}
```

Note: Leave empty strings for services you don't need. The app gracefully handles missing credentials.

6. **Run code generation after source changes**

```bash
fvm dart run tool/bootstrap.dart --codegen-only
```

This generates files for:
- Data models (`freezed`, `json_serializable`)
- Database (`drift`)
- Routing (`auto_route`)
- GraphQL operations (`ferry`)

7. **Run the app**

```bash
# Android development flavor
fvm flutter run --flavor dev -t lib/main.dart --dart-define-from-file=.env.json

# Linux desktop (defaults to the dev application flavor)
fvm flutter run -d linux -t lib/main.dart --dart-define-from-file=.env.json
```

## Branching Model

DioHub uses a structured branching strategy enforced by CI:

- **`main`**: Production releases only (protected)
- **`beta`**: Pre-release testing (protected)
- **`develop`**: Active development (default PR target, protected)

### Valid merge paths (enforced by `.github/workflows/branch-enforce.yaml`):

- Feature branches → `develop`
- `develop` → `beta`
- `develop` → `main`
- `hotfix/*` → `beta` or `main`
- `beta` → `main`

### Workflow:

1. Create a feature branch from `develop`:
   ```bash
   git checkout develop
   git pull
   git checkout -b feature/your-feature-name
   ```

2. Make your changes and commit (see Commit Convention below)

3. Push and create a PR targeting `develop`:
   ```bash
   git push -u origin feature/your-feature-name
   ```

4. After PR approval and merge, changes flow: `develop` → `beta` → `main`

## Commit Convention

DioHub enforces [Conventional Commits](https://www.conventionalcommits.org/) via `lefthook` and `cocogitto`.

### Format:

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

### Types:

- `feat`: New feature
- `fix`: Bug fix
- `refactor`: Code refactoring (no behavior change)
- `perf`: Performance improvement
- `docs`: Documentation only
- `style`: Code style (formatting, whitespace)
- `test`: Adding or updating tests
- `chore`: Maintenance (dependencies, build config)
- `ci`: CI/CD changes

### Examples:

```bash
feat(lens): add streaming support for LLM responses
fix(repo): handle null safety in insights calculation
refactor(database): migrate to drift 3.0 API
perf(ui): optimize list rendering with keys
docs(readme): update setup instructions
chore(deps): bump dio to 5.4.0
ci(quality): add SonarCloud workflow
```

### Scopes (common areas):

- `lens`: DioLens AI assistant
- `repo`: Repository features
- `issues`: Issue tracking
- `pr`: Pull requests
- `insights`: Repository analytics
- `database`: Drift database layer
- `graphql`: GraphQL operations
- `ui`: UI components
- `auth`: Authentication
- `deps`: Dependencies

## Code Generation

Re-run code generation when you:

- Change data models (classes with `@freezed`, `@JsonSerializable`)
- Change GraphQL queries/mutations in `packages/diohub_graphql/lib/graphql/`
- Update database schema in `packages/diohub_database/lib/database/`
- Add new routes in `lib/app/router/`

Note: Environment variables are injected at build/run time via `--dart-define-from-file`, not via code generation.

```bash
fvm dart run tool/bootstrap.dart --codegen-only
```

The bootstrap script runs GraphQL, model, database, and root generators in the
required order. Run a package's `build_runner watch` directly only when working
inside that package.

## Flavors

DioHub uses three flavors for different environments:

| Flavor | Purpose | Bundle ID | When to Use |
|--------|---------|-----------|-------------|
| `dev` | Development | `com.felix.diohub.dev` | Local development, testing new features |
| `beta` | Pre-release testing | `com.felix.diohub.beta` | Internal testing before production |
| `rel` | Production | `com.felix.diohub` | Play Store / App Store releases |

### Running specific flavors:

```bash
# Development
fvm flutter run --flavor dev -t lib/main.dart --dart-define-from-file=.env.json

# Beta
fvm flutter run --flavor beta -t lib/main.dart --dart-define-from-file=.env.json

# Production (local)
fvm flutter run --flavor rel -t lib/main.dart --dart-define-from-file=.env.json
```

### Building for release:

```bash
# Android APK
fvm flutter build apk --flavor rel -t lib/main.dart --release

# Android App Bundle
fvm flutter build appbundle --flavor rel -t lib/main.dart --release

# iOS
fvm flutter build ipa --flavor rel -t lib/main.dart --release
```

## CI/CD Checks

When you create a PR, the following automated checks run:

1. **Conventional Commits** (`cocogitto`): Validates commit message format
2. **Tests** (`flutter test`): Runs unit and widget tests with coverage
3. **Code Coverage** (Codecov): Requires 70% project coverage, 80% patch coverage
4. **Code Quality** (SonarCloud): Quality gates for bugs, code smells, security hotspots
5. **Security** (Snyk): Dependency vulnerability scanning
6. **AI Code Review** (CodeRabbit): Automated code review with context-aware suggestions
7. **Linting** (Shorebird CI): Dart analysis, formatting, custom_lint

All checks must pass before merging.

## Testing

Write tests for:
- New features (unit + widget tests)
- Bug fixes (regression tests)
- Critical paths (authentication, data sync)

Run tests locally:

```bash
# All tests
fvm flutter test

# With coverage
fvm flutter test --coverage

# Specific test file
fvm flutter test test/features/lens/lens_service_test.dart
```

## Release Process

Releases are automated via [Release Please](https://github.com/googleapis/release-please):

1. **Contributors**: Write conventional commits (the commit messages drive the changelog)
2. **Release Please**: Automatically creates a release PR when commits are pushed to `main`
3. **Maintainers**: Review and merge the release PR
4. **CI/CD**: Automatically builds, tags, and deploys to Play Store (internal track) and TestFlight

You don't need to manually bump versions or write changelogs—just write good commit messages!

## Code Style

- **Formatting**: Auto-formatted by `dart format` (runs via `lefthook` pre-commit hook)
- **Analysis**: Follow lints in `analysis_options.yaml` (strict, custom rules enabled)
- **Null Safety**: All code must be null-safe
- **Documentation**: Public APIs should have doc comments
- **Architecture**: Follow existing patterns (Riverpod for state, Drift for database, Ferry for GraphQL)

## Getting Help

- **GitHub Discussions**: Ask questions and share ideas
- **Issues**: Report bugs or suggest features using the issue templates
- **Setup Guide**: See `SETUP_GUIDE.md` for detailed CI/CD and deployment setup

## Code of Conduct

Be respectful, inclusive, and collaborative. Maintainers reserve the right to remove comments, commits, or contributions that don't align with a welcoming environment.

---

Thank you for contributing to DioHub!
