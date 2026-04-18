# Pipeline Redesign - Implementation Summary

## What Changed

The entire CI/CD pipeline has been redesigned to be more robust, predictable, and maintainable.

## Key Changes

### 1. Deterministic Build Numbers
- **Before**: `git rev-list --count HEAD` (fragile, changes with rebases)
- **After**: `.build-number` file committed to repo (stable, portable)
- Starting value: `2054` (one higher than current store builds of 2053)

### 2. Automated Semantic Versioning
- **Before**: Version stuck at `1.0.0`, Cocogitto only runs on main
- **After**: Cocogitto runs on all branches (develop, beta, main) with pre-release suffixes
  - develop: `1.1.0-dev` → `1.2.0-dev` based on commit messages
  - beta: `1.1.0-beta` → `1.2.0-beta`
  - main: `1.1.0` → `1.2.0`
- Zero manual intervention in version management

### 3. Simplified Labels
- **Before**: 6 labels (build-android, build-ios, patch-android, patch-ios, distribute-android, distribute-ios)
- **After**: 2 labels (release-android, release-ios)
- Labels auto-applied based on changed files, remove to opt out
- No labels = no build (for docs/CI-only changes)

### 4. Emergency-Only OTA Patches
- **Before**: Every Dart-only change auto-triggers OTA patch (performance risk)
- **After**: OTA patches require manual workflow dispatch with:
  - Explicit `release_version` (e.g., `1.1.0-dev+2054`)
  - Required `reason` (why is this an emergency?)
  - No auto-patching ever
- Hotfix tags: `v1.1.0-dev+2054-hotfix.android.1`

### 5. Streamlined Pipeline
- **Before**: 4 overlapping entry points (release.yaml, android-pipeline.yaml, ios-pipeline.yaml, github-release.yaml)
- **After**: 1 main pipeline (release.yaml) + 1 manual patch workflow (ota-patch.yaml)
- Deleted workflows:
  - `_detect-action.yaml` (410-line detection script replaced by label reading)
  - `android-pipeline.yaml`
  - `ios-pipeline.yaml`
  - `github-release.yaml`

### 6. Eliminated Tag-Based State Machine
- **Before**: Pipeline state tracked via complex git tags (`pipeline/*/built`, `/distributed`, `/patched.*`)
- **After**: GitHub Releases serve as source of truth
- No pipeline state tags created anymore
- Simpler, more reliable state management

### 7. Infinite Loop Prevention
- All bot commits include `[skip ci]` to prevent recursive pipeline triggers
- Cocogitto version bump commits: `[skip ci]`
- Build number bump commits: `[skip ci]`
- CHANGELOG updates: `[skip ci]`

## Files Created

| File | Purpose |
|---|---|
| `.build-number` | Monotonic build number (starts at 2054) |
| `.github/PIPELINE_MIGRATION.md` | Post-merge migration instructions |

## Files Modified

| File | Changes |
|---|---|
| `cog.toml` | Added develop/beta to branch_whitelist |
| `.github/scripts/detect-pipeline-state.sh` | Rewritten to read from files, not git history |
| `.github/pipeline-config.yaml` | New 2-label system |
| `.github/workflows/release.yaml` | Complete rewrite: label-based, file-based versioning, build-number bump |
| `.github/workflows/pr-pipeline-preview.yaml` | Smart path-based auto-labeling |
| `.github/workflows/ota-patch.yaml` | Manual-only with explicit inputs |
| `.github/workflows/_patch-android.yaml` | Explicit release_version, hotfix tags |
| `.github/workflows/_patch-ios.yaml` | Explicit release_version, hotfix tags |
| `.github/workflows/_release-android.yaml` | Removed pipeline tags |
| `.github/workflows/_release-ios.yaml` | Removed pipeline tags |
| `.github/workflows/_distribute-android.yaml` | Removed pipeline tags |
| `.github/workflows/_distribute-ios.yaml` | Removed pipeline tags |
| `.github/workflows/_publish-release.yaml` | Removed pipeline tags, added [skip ci] |
| `.github/workflows/_cleanup.yaml` | Removed pipeline tag cleanup logic |
| `.github/workflows/cleanup-schedule.yaml` | Disabled pipeline tag cleanup |

## Files Deleted

- `.github/workflows/_detect-action.yaml`
- `.github/workflows/android-pipeline.yaml`
- `.github/workflows/ios-pipeline.yaml`
- `.github/workflows/github-release.yaml`

## How It Works Now

### Normal Release Flow

```
1. Developer creates PR with feat/fix/etc commits
2. PR opened → auto-labeled with release-android + release-ios (or neither for docs-only)
3. Developer can remove labels to narrow scope or skip release
4. PR merges → pipeline triggers
5. Cocogitto bumps version based on commits (1.0.0 → 1.1.0-dev)
6. Read .build-number (2054)
7. Build with --build-name=1.1.0-dev --build-number=2054
8. Distribute to stores
9. Publish GitHub Release: v1.1.0-dev+2054
10. Bump .build-number to 2055, commit with [skip ci]
```

### Emergency Hotfix Flow

```
1. Navigate to Actions → OTA Patch (Emergency Only)
2. Click "Run workflow"
3. Enter:
   - Platform: android/ios/both
   - Flavor: dev/beta/rel
   - Release version: 1.1.0-dev+2054 (exact version to patch)
   - Reason: "Critical crash on startup for users with dark mode enabled"
4. Workflow runs shorebird patch with --release-version=1.1.0-dev+2054
5. Creates tag: v1.1.0-dev+2054-hotfix.android.1
6. Users on 1.1.0-dev+2054 get OTA update immediately
```

## Migration Required

After merging this PR, follow `.github/PIPELINE_MIGRATION.md` to:
1. Clean up old pipeline tags (if any)
2. Remove old labels from GitHub
3. Verify `.build-number` is correct
4. Test with a small PR

## Benefits

✅ **Robust**: Build numbers can't drift due to git history changes
✅ **Automated**: Version bumps happen automatically based on commit messages
✅ **Safe**: OTA patches require explicit approval and documentation
✅ **Simple**: 2 labels instead of 6, 1 pipeline instead of 4
✅ **Predictable**: File-based state, no complex tag archaeology
✅ **Maintainable**: Less code, clearer flow, easier to debug

## Risks & Mitigations

| Risk | Mitigation |
|---|---|
| Build number conflict with stores | Verified current store builds are 2053, starting at 2054 |
| Cocogitto not bumping version | Conventional commit enforcement in CI already active |
| [skip ci] not working | GitHub Actions native feature, well-tested |
| Accidental OTA patches | Removed from PR flow entirely, manual dispatch only |

## Next Steps

1. Merge this PR to `develop`
2. Follow migration guide in `.github/PIPELINE_MIGRATION.md`
3. Test with a small feature PR
4. Monitor first few releases to ensure version bumping works correctly
5. Document emergency hotfix process for team
