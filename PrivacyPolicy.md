# DioHub implementation privacy summary

Status: not a release privacy notice

Last code review: 2026-08-12

DioHub does not include advertising. It communicates with the GitHub or GitHub
Enterprise server selected by the user to authenticate, load repository/account
data, and perform requested mutations. GitHub-hosted content may reference external
image hosts, and the Home changelog reads GitHub's public changelog service.

Sentry diagnostics require a non-empty DSN in the distributed build. For a new
github.com profile, the current application defaults enable crash reports, HTTP
metadata, navigation tracking, and sampled performance tracing; session replay is
off by default. Enterprise/GHES defaults only enable crash reports. These settings
are user-configurable. The implementation disables default PII and request bodies,
scrubs events, and keeps screenshots/view hierarchies disabled. If session replay
is explicitly enabled, text and images are masked.

Authentication tokens are stored through platform secure storage. Local settings,
caches, and account-scoped application data remain on the device unless the user
invokes a feature that sends them to a configured remote service.

Before release, the distributor must provide and approve a complete notice that
identifies the operator and contact channel, exact telemetry defaults and enabled
integrations, data categories, retention/deletion rules, processors and terms,
target jurisdictions, complaint process, and store requirements. None of those
release decisions are inferred or approved by this repository summary.
