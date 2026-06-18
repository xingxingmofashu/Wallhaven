#!/bin/bash
set -e

SCHEME="Wallhaven"
BUILD_DIR="/tmp/Wallhaven_Build"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VERSION="${1:-}"
SUFFIX=""
if [ -n "$VERSION" ]; then
  SUFFIX="_${VERSION}"
  echo "Version: $VERSION"
fi
IPA_OUTPUT="$SCRIPT_DIR/Wallhaven${SUFFIX}.ipa"

echo "Cleaning..."
rm -rf "$BUILD_DIR" /tmp/Wallhaven_IPA "$IPA_OUTPUT"

echo "Building for iOS device..."
xcodebuild -scheme "$SCHEME" \
  -sdk iphoneos \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_ALLOWED=NO \
  BUILD_DIR="$BUILD_DIR" \
  -quiet \
  build

echo "Creating IPA..."
mkdir -p /tmp/Wallhaven_IPA/Payload
cp -R "$BUILD_DIR/Release-iphoneos/Wallhaven.app" /tmp/Wallhaven_IPA/Payload/
cd /tmp/Wallhaven_IPA
zip -r -q "$IPA_OUTPUT" Payload

echo "Done: $IPA_OUTPUT"
