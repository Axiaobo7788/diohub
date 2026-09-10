# Historical secret-rotation notice

Status: external completion not verified

Last repository review: 2026-08-12

## Why this record remains

An upstream migration replaced Envied-generated secret sources with
`--dart-define-from-file`. Before that migration, generated Dart sources could be
placed in `generated-code.tar.gz` and uploaded or cached by GitHub Actions. The
affected values named by the original notice were:

- `OAUTH_CLIENT_SECRET`
- `SENTRY_DSN`
- `SLACK_CLIENT_ID`
- `SLACK_CLIENT_SECRET`

The current checkout has no Envied dependency or generated environment source;
runtime configuration reads values through `String.fromEnvironment`. The current
`_codegen.yaml` archive step selects generated `*.g.dart`, `*.freezed.dart`, and
`*.graphql.dart` files. Together these facts show that the old repository-side
generation path is no longer present. They do not prove that every old credential
was rotated or every external artifact/cache was removed.

## Evidence required before closing

- Record when each affected credential was rotated or explicitly retired.
- Confirm obsolete GitHub Actions caches and artifacts were removed or expired.
- Inspect a generated-code artifact and confirm it contains no injected values.
- Run the relevant manual CI/release path with replacement credentials.
- Record the verifier, date, repository, and workflow run or audit reference.

Do not paste credential values into this file. Once every item has dated evidence,
the durable contributor rules remain in [`SECURITY.md`](SECURITY.md) and this
one-time record can be removed. Until then, deleting it would erase an unresolved
security obligation rather than consolidate documentation.
