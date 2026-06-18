#!/bin/bash
set -e

usage() {
  echo "Usage: $0 <major|minor|patch> [build_number]"
  echo "  major|minor|patch  — bump MARKETING_VERSION"
  echo "  build_number       — optional explicit CURRENT_PROJECT_VERSION (default: auto-increment)"
  exit 1
}

if [ $# -lt 1 ]; then usage; fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PBXPROJ="$SCRIPT_DIR/Wallhaven.xcodeproj/project.pbxproj"

# Read current MARKETING_VERSION (Debug or Release, both are the same)
CURRENT_MARKETING=$(grep "MARKETING_VERSION" "$PBXPROJ" | head -1 | sed 's/.*= //;s/;//')
echo "Current MARKETING_VERSION: $CURRENT_MARKETING"

# Bump
IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_MARKETING"
case "$1" in
  major) MAJOR=$((MAJOR + 1)); MINOR=0; PATCH=0 ;;
  minor) MINOR=$((MINOR + 1)); PATCH=0 ;;
  patch) PATCH=$((PATCH + 1)) ;;
  set)   ;;
  *)     echo "Unknown: $1"; usage ;;
esac

if [ "$1" = "set" ]; then
  NEW_MARKETING="$2"
  shift
else
  NEW_MARKETING="$MAJOR.$MINOR.$PATCH"
fi

# Build number
if [ -n "$2" ]; then
  NEW_BUILD="$2"
else
  CURRENT_BUILD=$(grep "CURRENT_PROJECT_VERSION" "$PBXPROJ" | head -1 | sed 's/.*= //;s/;//')
  NEW_BUILD=$((CURRENT_BUILD + 1))
fi

echo "New MARKETING_VERSION:     $NEW_MARKETING"
echo "New CURRENT_PROJECT_VERSION: $NEW_BUILD"

# Replace in pbxproj (both Debug & Release)
sed -i '' "s/MARKETING_VERSION = .*;/MARKETING_VERSION = $NEW_MARKETING;/g" "$PBXPROJ"
sed -i '' "s/CURRENT_PROJECT_VERSION = .*/CURRENT_PROJECT_VERSION = $NEW_BUILD;/g" "$PBXPROJ"

echo "Done. Updated $PBXPROJ"
