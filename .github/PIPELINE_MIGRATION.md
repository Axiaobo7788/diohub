# Pipeline Redesign Migration Guide

## Quick Start (Automated)

**Recommended**: Use the automated migration script:

```bash
# After merging the pipeline redesign PR to develop
cd /path/to/diohub
.github/scripts/migrate-pipeline.sh
```

The script will:
- Clean up old pipeline tags
- Remove old labels from GitHub
- Verify `.build-number` is correct
- Update open PRs with new labels
- Provide a summary and next steps

## Manual Steps (if needed)

If you prefer to run steps manually or the script fails:

### Step 1: Clean Up Pipeline Tags (if any exist)

The old pipeline used tags like `pipeline/v1.0.0-dev.2053/android/built`. These need to be removed.

```bash
# Check if any pipeline tags exist
git fetch --tags
git tag -l 'pipeline/*'

# If tags are found, delete them from remote
git tag -l 'pipeline/*' | xargs -I {} git push --delete origin {}

# Verify deletion
git tag -l 'pipeline/*'  # Should be empty
```

## Step 2: Remove Old Labels from GitHub

The old pipeline used 6 labels that have been replaced by 2 new labels:

### Labels to DELETE:
- `build-android`
- `build-ios`
- `patch-android`
- `patch-ios`
- `distribute-android`
- `distribute-ios`

### Via GitHub UI:
1. Go to `https://github.com/YOUR_ORG/diohub/labels`
2. Search for each old label and click "Delete"

### Via GitHub CLI:
```bash
gh label delete build-android --yes
gh label delete build-ios --yes
gh label delete patch-android --yes
gh label delete patch-ios --yes
gh label delete distribute-android --yes
gh label delete distribute-ios --yes
```

### Verify new labels exist:
```bash
gh label list | grep release-
# Should show:
# release-android
# release-ios
```

If they don't exist, the first PR with the new pipeline will create them automatically.

## Step 3: Update Existing Open PRs (if any)

If you have open PRs that still have the old labels:

```bash
# List open PRs with old labels
gh pr list --label build-android,build-ios,patch-android,patch-ios,distribute-android,distribute-ios

# For each PR, manually relabel:
# Remove old labels, add new labels as appropriate
gh pr edit PR_NUMBER --remove-label build-android --add-label release-android
gh pr edit PR_NUMBER --remove-label build-ios --add-label release-ios
```

## Step 4: Verify Build Number

Check that `.build-number` is correct:

```bash
cat .build-number
# Should show: 2054 (or whatever you set it to)
```

Verify this is higher than the highest build in stores:
- Play Store: Check the "Open testing" track for the highest build number
- TestFlight: Check all builds for the highest build number

If the `.build-number` needs adjustment, edit it before the first release:

```bash
echo "2100" > .build-number  # Or whatever number you need
git add .build-number
git commit -m "ci: adjust build number starting point"
git push
```

## Step 5: Test with a Non-Code PR First

Before testing the full release pipeline, validate the label system with a docs-only PR:

1. Create a branch: `git checkout -b test/pipeline-labels`
2. Make a docs-only change: `echo "test" >> README.md`
3. Commit and push: `git add README.md && git commit -m "docs: test pipeline" && git push`
4. Open PR to `develop`
5. Verify: The PR should get **no labels** (docs-only changes don't trigger releases)
6. Close the PR without merging

## Step 6: Test with a Code PR

Now test the full pipeline with a small code change:

1. Create a branch: `git checkout -b test/pipeline-release`
2. Make a trivial code change (e.g., add a comment in a Dart file)
3. Commit with conventional commit: `git commit -m "feat: test new pipeline"`
4. Push and open PR to `develop`
5. Verify: PR should get **both** `release-android` and `release-ios` labels
6. Merge the PR
7. Monitor the release pipeline:
   - Cocogitto should bump version (e.g., `1.0.0` → `1.1.0-dev` if it's a `feat:`)
   - Build should use build number `2054` from `.build-number`
   - After distribution, `.build-number` should be bumped to `2055`
   - GitHub Release should be created with tag `v1.1.0-dev+2054`

## Step 7: Verify Stores Received the Build

After the first successful pipeline run:

1. **Play Store**:
   - Go to Release → Internal testing → Latest releases
   - Verify build `2054` (or your starting number) is present

2. **TestFlight**:
   - Go to TestFlight → Builds
   - Verify build `2054` is present

3. **GitHub Release**:
   - Go to Releases
   - Verify `v1.1.0-dev+2054` (or appropriate tag) is published

## Troubleshooting

### Build number conflict
If the store rejects the build saying "version code already exists":
1. Check what the actual highest build number is in the store
2. Update `.build-number` to be higher than that
3. Re-run the pipeline

### Cocogitto doesn't bump version
If the version stays at `1.0.0`:
- Check that your commit messages follow conventional commit format (`feat:`, `fix:`, etc.)
- Run `cog log` locally to see what Cocogitto would do
- If you want to force a specific version, manually edit `pubspec.yaml` and commit with `[skip ci]`

### Labels not auto-applied
If PRs aren't getting labels automatically:
- Check that `.github/workflows/pr-pipeline-preview.yaml` is present and enabled
- Verify the workflow has permissions: `pull-requests: write`
- Check workflow runs in the Actions tab for errors

### [skip ci] not working
If bot commits trigger the pipeline recursively:
- Verify the commit message includes exactly `[skip ci]` in the message
- Check the workflow's `if` condition: `!contains(github.event.head_commit.message, '[skip ci]')`

## Rollback Plan

If the new pipeline has critical issues, you can temporarily revert:

1. Revert the pipeline redesign PR
2. Re-enable the old `android-pipeline.yaml` and `ios-pipeline.yaml` workflows
3. The old workflows can coexist with the new `.build-number` file (they just won't use it)
4. Fix issues, then re-apply the redesign

## Post-Migration Checklist

- [ ] Pipeline tags cleaned up
- [ ] Old labels removed from GitHub
- [ ] `.build-number` verified
- [ ] Docs-only PR tested (no labels)
- [ ] Code PR tested (labels applied, build succeeded)
- [ ] Store builds verified (build 2054+ received)
- [ ] GitHub Release published correctly
- [ ] Build number auto-incremented (2055 in `.build-number`)
- [ ] Team notified of new label system
- [ ] Emergency hotfix process documented (manual `ota-patch.yaml` dispatch)

## Notes

- The first few releases may need monitoring to ensure Cocogitto bumps versions correctly
- Hotfixes are now manual-only via workflow dispatch - this is intentional for safety
- If you need to patch an old release, you'll need to specify the exact version (e.g., `1.1.0-dev+2054`)
