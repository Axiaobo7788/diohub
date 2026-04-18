#!/usr/bin/env bash
set -euo pipefail

# Pipeline Redesign Migration Script
# Automates post-merge cleanup using GitHub CLI

echo "=== Pipeline Redesign Migration ==="
echo ""

# Check prerequisites
if ! command -v gh &> /dev/null; then
    echo "❌ Error: GitHub CLI (gh) is not installed"
    echo "Install from: https://cli.github.com/"
    exit 1
fi

if ! gh auth status &> /dev/null; then
    echo "❌ Error: Not authenticated with GitHub CLI"
    echo "Run: gh auth login"
    exit 1
fi

echo "✓ GitHub CLI is installed and authenticated"
echo ""

# Get repository info
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
echo "Repository: $REPO"
echo ""

# Step 1: Clean up pipeline tags
echo "=== Step 1: Clean up pipeline tags ==="
git fetch --tags 2>/dev/null || true
PIPELINE_TAGS=$(git tag -l 'pipeline/*' || echo "")

if [ -z "$PIPELINE_TAGS" ]; then
    echo "✓ No pipeline tags found (already clean)"
else
    echo "Found pipeline tags to delete:"
    echo "$PIPELINE_TAGS"
    echo ""
    read -p "Delete these tags from remote? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "$PIPELINE_TAGS" | xargs -I {} git push --delete origin {} 2>/dev/null || true
        echo "✓ Pipeline tags deleted"
    else
        echo "⊘ Skipped pipeline tag deletion"
    fi
fi
echo ""

# Step 2: Remove old labels
echo "=== Step 2: Remove old labels ==="
OLD_LABELS=(
    "build-android"
    "build-ios"
    "patch-android"
    "patch-ios"
    "distribute-android"
    "distribute-ios"
)

echo "Old labels to remove:"
for label in "${OLD_LABELS[@]}"; do
    echo "  - $label"
done
echo ""

read -p "Delete old labels? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    for label in "${OLD_LABELS[@]}"; do
        if gh label list --json name --jq '.[].name' | grep -q "^${label}$"; then
            gh label delete "$label" --yes 2>/dev/null && echo "  ✓ Deleted: $label" || echo "  ⊘ Not found: $label"
        else
            echo "  ⊘ Not found: $label"
        fi
    done
else
    echo "⊘ Skipped label deletion"
fi
echo ""

# Step 3: Verify new labels exist
echo "=== Step 3: Verify new labels ==="
NEW_LABELS=(
    "release-android"
    "release-ios"
)

for label in "${NEW_LABELS[@]}"; do
    if gh label list --json name --jq '.[].name' | grep -q "^${label}$"; then
        echo "  ✓ Exists: $label"
    else
        echo "  ⚠ Missing: $label (will be created on first PR)"
    fi
done
echo ""

# Step 4: Verify .build-number
echo "=== Step 4: Verify build number ==="
if [ -f ".build-number" ]; then
    BUILD_NUM=$(cat .build-number)
    echo "✓ .build-number file exists: $BUILD_NUM"
    
    if [ "$BUILD_NUM" -lt 2053 ]; then
        echo "⚠ Warning: Build number $BUILD_NUM is less than 2053 (highest in stores)"
        echo "  This will cause store upload failures!"
        read -p "Update to 2054 now? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "2054" > .build-number
            git add .build-number
            git commit -m "ci: adjust build number to 2054"
            git push
            echo "✓ Build number updated to 2054"
        fi
    else
        echo "✓ Build number is valid (higher than store builds)"
    fi
else
    echo "❌ Error: .build-number file not found"
    echo "  This should have been created in the migration PR"
    exit 1
fi
echo ""

# Step 5: Update existing open PRs
echo "=== Step 5: Update open PRs with old labels ==="
for old_label in "${OLD_LABELS[@]}"; do
    PRS=$(gh pr list --label "$old_label" --json number --jq '.[].number' || echo "")
    if [ -n "$PRS" ]; then
        echo "Found PRs with old label '$old_label':"
        echo "$PRS"
    fi
done

read -p "Relabel open PRs automatically? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Android: build-android → release-android
    for pr in $(gh pr list --label "build-android" --json number --jq '.[].number' || echo ""); do
        gh pr edit "$pr" --remove-label "build-android" --add-label "release-android" 2>/dev/null || true
        echo "  ✓ PR #$pr: build-android → release-android"
    done
    
    # iOS: build-ios → release-ios
    for pr in $(gh pr list --label "build-ios" --json number --jq '.[].number' || echo ""); do
        gh pr edit "$pr" --remove-label "build-ios" --add-label "release-ios" 2>/dev/null || true
        echo "  ✓ PR #$pr: build-ios → release-ios"
    done
    
    # Remove patch/distribute labels (no longer used)
    for label in "patch-android" "patch-ios" "distribute-android" "distribute-ios"; do
        for pr in $(gh pr list --label "$label" --json number --jq '.[].number' || echo ""); do
            gh pr edit "$pr" --remove-label "$label" 2>/dev/null || true
            echo "  ✓ PR #$pr: removed $label"
        done
    done
else
    echo "⊘ Skipped PR relabeling"
fi
echo ""

# Step 6: Summary
echo "=== Migration Complete ==="
echo ""
echo "Next steps:"
echo "1. Create a test PR with a small code change"
echo "2. Verify it gets labeled with release-android + release-ios"
echo "3. Merge and watch the pipeline run"
echo "4. Verify build 2054 (or your starting number) appears in stores"
echo ""
echo "For detailed testing instructions, see .github/PIPELINE_MIGRATION.md"
