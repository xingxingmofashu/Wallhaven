#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCHEME="Wallhaven"
BUILD_DIR="/tmp/Wallhaven_Install_Build"
TEMP_DIR="/tmp/Wallhaven_Install_IPA"
IPA_PATH="$SCRIPT_DIR/Wallhaven.ipa"

# Read DEVELOPMENT_TEAM from pbxproj (set in Xcode Signing & Capabilities)
PROJECT_FILE="$SCRIPT_DIR/Wallhaven.xcodeproj/project.pbxproj"
DEVELOPMENT_TEAM=$(grep "DEVELOPMENT_TEAM" "$PROJECT_FILE" | head -1 | sed 's/.*= //;s/;//;s/"//g')

if [ -z "$DEVELOPMENT_TEAM" ]; then
  echo "DEVELOPMENT_TEAM not set in project. Auto-detecting from signing certificate..."
  DEVELOPMENT_TEAM=$(security find-identity -v -p codesigning 2>/dev/null \
    | grep "Apple Development" \
    | head -1 \
    | sed 's/.*(\([^)]*\).*/\1/')
fi

if [ -z "$DEVELOPMENT_TEAM" ]; then
  echo "Error: No development team found."
  echo "Set one in Xcode: open project → Signing & Capabilities → select Team"
  echo "Or pass it: DEVELOPMENT_TEAM=XXXXXXXXXX ./Scripts/install.sh"
  exit 1
fi

echo "Using team: $DEVELOPMENT_TEAM"

# 1. Build with native Xcode signing
echo "Cleaning..."
rm -rf "$BUILD_DIR" "$TEMP_DIR" "$IPA_PATH"

echo "Building for iOS device..."
xcodebuild -scheme "$SCHEME" \
  -sdk iphoneos \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -allowProvisioningUpdates \
  DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM" \
  BUILD_DIR="$BUILD_DIR" \
  -quiet \
  build

# 2. Package into IPA
echo "Creating IPA..."
mkdir -p "$TEMP_DIR/Payload"
cp -R "$BUILD_DIR/Release-iphoneos/$SCHEME.app" "$TEMP_DIR/Payload/"
cd "$TEMP_DIR"
zip -r -q "$IPA_PATH" Payload

# 3. Install via devicectl
echo "Finding connected iPhone..."
DEVICE_ID=$(xcrun devicectl list devices 2>/dev/null \
  | grep "iPhone" \
  | head -1 \
  | awk '{print $3}')

if [ -z "$DEVICE_ID" ]; then
  echo "Error: No iPhone found. Make sure your device is connected and paired."
  exit 1
fi

echo "Installing to iPhone ($DEVICE_ID)..."
xcrun devicectl device install app \
  --device "$DEVICE_ID" \
  "$BUILD_DIR/Release-iphoneos/$SCHEME.app"

echo "Done! IPA saved at: $IPA_PATH"
