# DioHub

A professional GitHub client for Android, iOS, macOS, Linux, and Windows. Built with Flutter.

[![CI](https://github.com/namanshergill/diohub/actions/workflows/ci.yaml/badge.svg)](https://github.com/namanshergill/diohub/actions/workflows/ci.yaml)
[![Quality Gate Status](https://sonarcloud.io/api/project_badges/measure?project=namanshergill_diohub&metric=alert_status)](https://sonarcloud.io/summary/new_code?id=namanshergill_diohub)
[![codecov](https://codecov.io/gh/namanshergill/diohub/branch/main/graph/badge.svg)](https://codecov.io/gh/namanshergill/diohub)
[![Snyk Vulnerabilities](https://img.shields.io/snyk/vulnerabilities/github/namanshergill/diohub)](https://snyk.io/test/github/namanshergill/diohub)
[![OpenSSF Scorecard](https://api.securityscorecards.dev/projects/github.com/namanshergill/diohub/badge)](https://securityscorecards.dev/viewer/?uri=github.com/namanshergill/diohub)
[![GitHub release](https://img.shields.io/github/v/release/namanshergill/diohub)](https://github.com/namanshergill/diohub/releases)

[![Get it on Google Play](https://user-images.githubusercontent.com/33877135/129138668-8d48aaf5-c844-4e38-bb9b-78df12af8ea9.png)](https://play.google.com/store/apps/details?id=com.felix.diohub)

[Download latest APK from releases](https://github.com/NamanShergill/diohub/releases) • [Join Telegram Community](https://t.me/diohubchat)

---

## What Makes DioHub Different

### DioLens AI Assistant
Context-aware AI that understands what you're looking at. 12 LLM providers including on-device inference (Apple Intelligence, Gemini Nano). 10 MCP server integrations (GitHub, Linear, Slack, Notion, Atlassian, Sentry, Stripe, Figma, Supabase, Vercel). ~90 auto-generated tools from custom codegen.

### Beyond a Viewer
16-section repository insights engine with punch card heatmaps, anomaly detection, and traffic funnels. Visual commit graph with lane-based DAG layout. Terminal-based CI log viewer with live tailing. SSH terminal with key-based auth. Code browser with blame, editing, and commit history.

### Production-Grade Infrastructure
210K lines of hand-written Dart across a 7-package monorepo with custom lint rules. 20-table offline database with encrypted cloud sync (AES-256-GCM + PBKDF2). 16 background watchers monitoring CI, security, deployments, and milestones. Multi-account support with OAuth2 and PAT auth.

---

## Features

### Repository Management
- **Full repository browser** with tabs for code, issues, PRs, releases, actions, insights, deployments, security, wiki, projects, collaborators, discussions, and compare view
- **Code browsing** with directory navigation, file viewer (View/Blame/History tabs), file editing, breadcrumb navigation, syntax highlighting
- **Commit graph** with visual git DAG, branch visualization, incremental layout algorithm, cursor-based pagination
- **GitHub Actions** with workflow runs, terminal-based log viewer with live tailing for in-progress runs, workflow dispatch, deployment approvals, artifact downloads
- **Repository insights** (15 sections): at-a-glance summary, repo pulse health score, commit activity with anomaly detection, time patterns with punch card heatmap, contributors with bus factor warnings and sparklines, traffic analytics with visitor-to-star funnel, star history, languages, community health checklist, dependencies, milestones, release cadence, contributing guidelines

### Issues & Pull Requests
- **Comprehensive timelines** with full discussion threads, review comments, status checks, CI results
- Create, edit, comment, react, label, assign, milestone, project management
- Issue templates and PR templates
- Cross-references, sub-issues, merge queue, auto-merge
- Review threads with approval/request changes/comment workflows
- Transfer issues between repositories

### Security & Monitoring
- **Security alerts**: Dependabot vulnerabilities with CVSS scores, secret scanning, code scanning (SAST)
- **Background watchers** (16 types): inbox polling, workflow run status, PR merge status, issue state, releases, deployments, security alerts, star milestones, followers, milestone progress, branch CI, scheduled workflows
- WorkManager integration with 15-minute periodic checks
- 17 Android notification channels for granular control

### Search & Discovery
- **6-tab search** covering repositories, issues/PRs, users, discussions, saved searches, and history
- Context-based filter suggestions
- Query helpers for advanced GitHub search syntax
- Trending repositories when query is empty

### Profile & Contributions
- **Contribution analytics** with calendar, statistics, patterns, streaks, highlights, year selection, custom date ranges
- Activity timeline with event tracking
- Profile tabs: stars, repos, gists, following, followers, organizations, watching, keys, packages, projects, sponsors
- Organization-specific tabs: members, teams, activity, security

### DioLens AI
- **12 LLM providers**: OpenAI, Anthropic, Google AI Studio, Groq, DeepSeek, Mistral, Ollama (local), LM Studio (local), Azure OpenAI, GitHub Models, AWS Bedrock, On-Device (Apple Intelligence / Gemini Nano / Windows AI)
- **5 wire format implementations**: OpenAI, Anthropic, Google AI, Bedrock Converse, Azure OpenAI
- **5 auth strategies**: GitHub OAuth, API Key, No Auth, AWS SigV4, Azure
- **~90 auto-generated tools** from 21 annotated services via custom codegen (`lens_annotations` + `lens_generator`)
- **6 meta tools**: discover tools, paginate, present options, compact context, select, delegate task
- **Context window management**: 3-tier compaction (truncate tool results → drop middle turns → LLM summarization)
- **Tool scoping**: 5 scope types (Global, Repo, IssuePull, PullRequest, User) with typed args
- **Tool safety**: 3 levels (read, write, optIn) with user preference overrides
- **MCP integration**: 10 curated servers with full OAuth support and context injection
- **On-device inference**: Apple Intelligence (iOS/macOS), Gemini Nano (Android), Windows AI

### SSH Terminal
- Full interactive terminal via `dartssh2` + `xterm`
- Password and key-based authentication
- CRUD for saved connections
- Theme-aware terminal colors
- Configurable font size and scrollback

### Data & Sync
- **20 Drift (SQLite) tables** with 16 DAOs
- Entity caching for offline repository, issue, and PR browsing
- Bookmarks, collections, saved searches, drafts, history (all account-scoped)
- **Encrypted cloud sync** to private `.diohub-sync` GitHub repo
- AES-256-GCM encryption with PBKDF2-HMAC-SHA256 key derivation (100K iterations)
- Three-way conflict resolution with visual diff viewer
- 19 sync scopes (14 settings + 5 data types)
- Local backup as ZIP

### Theming & Customization
- Material You dynamic theming with `flex_color_scheme`
- Squircle shape system (iOS-style superellipse) or standard rounded
- 5 radius sizes with configurable smoothing
- Completely customizable color palettes
- Shareable theme configurations
- 57 settings files across 5 areas (Themes, Preferences, Code & Diffs, Behavior, DioLens & AI)

### Platform Support
- **Android** (API 21+)
- **iOS** (14.0+)
- **macOS** (10.15+)
- **Linux**
- **Windows**

---

## Architecture

### Monorepo Structure
- **5 internal packages**: `diohub_database`, `diohub_gql_client`, `diohub_graphql`, `diohub_lint`, `diohub_models`
- **2 custom codegen packages**: `lens_annotations`, `lens_generator`
- **14 custom lint rules** enforcing layered architecture
- Melos-based workspace management

### GraphQL API Layer
- 132 source `.graphql` files generating 132 type-safe operation files
- Full GitHub GraphQL API coverage
- `gql_dio_link` transport with persistent HTTP cache (`dio_cache_interceptor`)
- Partial data recovery from failed queries

### State Management
- Riverpod throughout (171 provider files)
- No code generation for providers (manual `Provider`, `FutureProvider`, `StreamProvider`, etc.)
- `.family` providers for parameterized data
- `.autoDispose` for screen-scoped state

### Routing
- `auto_route` v11 with 26 routes
- Deep linking via `app_links` + `receive_sharing_intent`
- Custom route transitions (fade + slide for home)
- Reactive navigation based on startup state

---

## Technical Highlights

### Custom Codegen Pipeline
`lens_annotations` (5 annotations + 2 enums) + `lens_generator` (source_gen-based) produces typed tool definitions from annotated Dart service methods. 21 services generate ~90 tools with JSON schema, parameter injection, scope inference, and safety levels. Adding a tool = adding an `@Lens` annotation.

### Background Processing
WorkManager integration with background isolates opening separate database connections. Alert dispatcher routes to in-app toast, system notifications (17 channels), or silent updates. Secure token storage access from background context.

### Offline-First
20-table Drift database with entity caching. Repo/issue/PR snapshots for full offline browsing. FK cascades ensure referential integrity. All account-scoped data automatically cleaned up on account deletion.

### Security
- Encrypted cloud sync with AES-256-GCM + PBKDF2 (100K iterations)
- Secure token storage (iOS keychain `first_unlock`, Android encrypted shared prefs)
- Proactive + reactive OAuth token refresh with concurrency guard
- Scope checking for PAT-based authentication
- Multi-account isolation with separate credential namespaces

---

## Building from Source

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) 3.44.7
- Dart SDK 3.12.x (included with Flutter 3.44.7)
- FVM is optional; `.fvmrc` and `.flutter-version` pin the same SDK
- Android: JDK 17, Android SDK 36, NDK `28.2.13676358`, and accepted SDK licenses
- Linux: a WPE WebKit pkg-config module (`wpe-webkit-2.0`, `1.1`, or `1.0`)

### Setup

1. Clone the repository:
```bash
git clone --recurse-submodules https://github.com/NamanShergill/diohub.git
cd diohub
```

2. Initialize submodules:
```bash
git submodule update --init --recursive
```

3. Create a [GitHub OAuth App](https://docs.github.com/en/developers/apps/building-oauth-apps/creating-an-oauth-app):
   - Set Authorization callback URL to: `auth.felix.diohub://login-callback`
   - Note your Client ID and Client Secret

4. Create the local environment configuration and fill in the OAuth values you use:

```bash
cp .env.example .env.json
```

Do not commit `.env.json`; it is ignored by Git. Authentication credentials are
injected with `--dart-define-from-file` and are not generated into source files.

5. Resolve application dependencies and generate sources in dependency order:

```bash
dart run tool/bootstrap.dart
```

6. Run the app. Android uses the configured product flavor; desktop defaults to
the `dev` application flavor:

```bash
# Android
flutter run --flavor dev -t lib/main.dart \
  --dart-define-from-file=.env.json

# Linux
flutter run -d linux -t lib/main.dart \
  --dart-define-from-file=.env.json
```

After changing GraphQL operations, models, database tables, or generated root
sources, regenerate without resolving dependencies again:

```bash
dart run tool/bootstrap.dart --codegen-only
```

### Build Variants
- **Android debug**: `flutter build apk --debug --flavor dev -t lib/main.dart`
- **Android release**: `flutter build apk --release --flavor rel -t lib/main.dart`
- **Linux debug**: `flutter build linux --debug -t lib/main.dart`

Other Flutter platform runners are present, but each host still needs its native
toolchain and plugin dependencies before it can be treated as a validated build.

---

## Contributing

DioHub is an open-source project and contributions are welcome! Whether it's bug reports, feature requests, code contributions, or translations via [Weblate](https://hosted.weblate.org/projects/diohub/), every contribution helps.

### Areas to Contribute
- Custom tool builders (stubs exist in `lib/services/lens/tools/custom/`)
- Additional AI provider integrations
- MCP server integrations
- Repository insight sections
- Background watcher types
- Localization / translations

### Development Guidelines
- Follow the custom lint rules (`diohub_lint` package enforces architecture)
- Add tests for new features
- Update documentation as needed
- Use semantic commit messages

---

## License

GPL-3.0 License

---

## Support

Like this project? Consider supporting its development:

[☕ Buy me a coffee](https://www.buymeacoffee.com/byefelixia) • [💬 Join Telegram](https://t.me/diohubchat) • [⭐ Star on GitHub](https://github.com/NamanShergill/diohub)

---

## Statistics

- **1,890 commits** across 5.7 years
- **210K lines** of hand-written Dart code
- **1.7M total lines** including generated code
- **1,547 hand-written files**
- **26 routes** with deep linking
- **15 custom painters** for visualizations
- **132 GraphQL operations**
- **21 lens-annotated services** generating ~90 tools
- **16 background watchers** with 17 notification channels
- **12 AI providers** with 5 wire formats and 5 auth strategies
- **10 curated MCP servers**
- **5 platforms** supported

---

**Built with ❤️ using Flutter**
