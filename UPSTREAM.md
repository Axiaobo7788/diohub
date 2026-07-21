# Upstream Baseline

This repository is an independent downstream of DioHub. Upstream changes are
inputs to review, not an automatic release dependency.

## Pinned source baseline

- Upstream repository: `https://github.com/NamanShergill/diohub.git`
- Source branch: `develop`
- Source commit: `5e77b8d24fee4dd438aa26422b7558ac61a2b26f`
- Source commit date: 2026-04-19
- Downstream Flutter baseline: Flutter 3.44.7 / Dart 3.12

The local `origin` is expected to be the downstream fork. When upstream history
needs to be inspected, configure a separate read-only `upstream` remote:

```bash
git remote add upstream https://github.com/NamanShergill/diohub.git
git fetch upstream --prune
```

Do not replace the downstream `origin` with the upstream URL.

## Update policy

1. Fetch upstream without rewriting downstream history.
2. Review upstream commits against this pinned baseline.
3. Cherry-pick or reimplement only changes that fit the downstream roadmap.
4. Record each adopted upstream commit and any local adaptation below.
5. Re-run public bootstrap, root analysis, tests, Android regression, and Linux
   regression before advancing the pinned baseline.

## Adopted source and dependency changes

| Upstream source | Local adaptation | Reason |
| --- | --- | --- |
| `fluttercandies/extended_text_field@106b8a57050cbd231b7ab5dc905feb9be42662ab` | Public submodule and path dependency | Flutter 3.44 selection API compatibility |
