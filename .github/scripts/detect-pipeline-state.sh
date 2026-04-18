#!/usr/bin/env bash
set -euo pipefail

# Simple version and build number detection from committed files
# Usage: detect-pipeline-state.sh <branch_name>

BRANCH="${1:?Branch name required}"

# Read version from pubspec.yaml
VERSION=$(grep '^version:' pubspec.yaml | sed 's/version: *//')

if [ -z "$VERSION" ]; then
  echo "Error: Could not extract version from pubspec.yaml" >&2
  exit 1
fi

# Read build number from .build-number file
BUILD_NUMBER=$(cat .build-number 2>/dev/null || echo "")

if [ -z "$BUILD_NUMBER" ]; then
  echo "Error: Could not read .build-number file" >&2
  exit 1
fi

# Read Flutter version
FLUTTER_VERSION=$(cat .flutter-version 2>/dev/null || echo "")

if [ -z "$FLUTTER_VERSION" ]; then
  echo "Error: Could not read .flutter-version" >&2
  exit 1
fi

# Determine tag format based on branch
case "$BRANCH" in
  develop)
    TAG="v${VERSION}-dev+${BUILD_NUMBER}"
    ;;
  beta)
    TAG="v${VERSION}-beta+${BUILD_NUMBER}"
    ;;
  main)
    TAG="v${VERSION}+${BUILD_NUMBER}"
    ;;
  *)
    echo "Error: Unknown branch '$BRANCH'" >&2
    exit 1
    ;;
esac

echo "=== Version Detection ==="
echo "Version: $VERSION"
echo "Build number: $BUILD_NUMBER"
echo "Tag: $TAG"
echo "Flutter version: $FLUTTER_VERSION"
echo ""

# Write outputs to GITHUB_OUTPUT if available
if [ -n "${GITHUB_OUTPUT:-}" ]; then
  {
    echo "version=$VERSION"
    echo "build_number=$BUILD_NUMBER"
    echo "tag=$TAG"
    echo "flutter_version=$FLUTTER_VERSION"
  } >> "$GITHUB_OUTPUT"
fi
