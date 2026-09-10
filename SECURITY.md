# Security Policy

## Supported versions

Security reports are evaluated against the active `develop` branch and any
downstream release explicitly marked as supported. This checkout does not promise
maintenance for older or upstream releases.

## Reporting a vulnerability

Do not report vulnerabilities in a public issue. Use the downstream
[GitHub Security Advisory form](https://github.com/Axiaobo7788/diohub/security/advisories/new)
so the report and follow-up can remain private.

Include the affected version or commit, impacted files or feature, reproduction
steps, expected impact, and a proof of concept when it is safe to share. Do not
include access tokens, private repository contents, or unrelated personal data.

No fixed acknowledgement or remediation deadline is promised until a maintainer
and a private contact channel are formally designated. Wait for a private
maintainer response before coordinated public disclosure.

## Current security boundaries

- GitHub access tokens are stored through `flutter_secure_storage`; the backing
  protection and availability semantics are platform-specific.
- GitHub Device Flow does not require a client secret. Optional integration values
  are injected with `--dart-define-from-file` and must never be committed, logged,
  cached, or included in generated-source artifacts.
- Values compiled into a client application must not be treated as secrets from a
  user who controls that application or device.
- Repository and Markdown content comes from remote, user-controlled sources and
  must remain subject to size, scheme, authentication, and rendering boundaries.
- Drift access must use its typed/query APIs. New code must not interpolate
  untrusted values into raw SQL.
- OpenSSF Scorecard has a repository workflow. Snyk support is currently disabled
  because it does not provide native Dart/Flutter analysis in this project; this
  policy does not claim otherwise.
- Certificate pinning and specific encryption algorithms are not project-wide
  guarantees unless an implementation and platform validation are linked here.

## Contributor requirements

1. Never commit credentials, tokens, signing material, `.env` files, or populated
   `--dart-define-from-file` configuration.
2. Use the checked-in example configuration only as a schema; keep real values
   outside the repository.
3. Redact authentication headers, cookies, tokens, private URLs, and user content
   from logs, screenshots, fixtures, crash reports, and CI artifacts.
4. Validate URI schemes, response sizes, file paths, and user-controlled content
   at the service boundary.
5. Keep security-related workflow and dependency changes independently reviewable.
6. If a credential may have entered Git history, generated sources, caches, or
   artifacts, assume compromise and rotate it; deleting the current file is not
   sufficient.

## Historical credential migration

The repository contains a migration record for an earlier generated-source
credential exposure risk in
[`SECURITY_ROTATION_NOTICE.md`](SECURITY_ROTATION_NOTICE.md). Its repository-side
packaging path has been corrected, but completion of external credential rotation
and cache cleanup is not proven by this checkout. Keep that record until those
actions have dated evidence; then retain the durable rules here and archive or
remove the one-time notice.
