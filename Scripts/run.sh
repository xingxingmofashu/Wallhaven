#!/bin/bash
set -e

# Run Wallhaven in the iOS Simulator from the command line.
# Usage:
#   ./Scripts/run.sh                   # use default simulator
#   ./Scripts/run.sh "iPhone 17 Pro"   # specify a simulator by name

SCHEME="Wallhaven"
BUNDLE_ID="com.xingxingmofashu.wallhaven.ios"
BUILD_DIR="/tmp/Wallhaven_Sim_Build"
CONFIGURATION="Debug"
DEFAULT_DEVICE="iPhone 17 Pro"
DEVICE_NAME="${1:-$DEFAULT_DEVICE}"

echo "==> Looking for simulator: $DEVICE_NAME"
DEVICE_ID=$(xcrun simctl list devices available -j \
  | python3 -c "
import json, sys
data = json.load(sys.stdin)
target = sys.argv[1]
for runtime, devices in data['devices'].items():
    for d in devices:
        if d['name'] == target and d.get('isAvailable', False):
            print(d['udid']); sys.exit(0)
sys.exit(1)
" "$DEVICE_NAME" 2>/dev/null || true)

if [ -z "$DEVICE_ID" ]; then
  echo "Error: No available simulator named '$DEVICE_NAME'."
  echo "Available devices:"
  xcrun simctl list devices available | grep -i iPhone
  exit 1
fi

echo "Found: $DEVICE_NAME ($DEVICE_ID)"

# Boot simulator if not already running
STATE=$(xcrun simctl list devices -j \
  | python3 -c "
import json, sys
data = json.load(sys.stdin)
for runtime, devices in data['devices'].items():
    for d in devices:
        if d['udid'] == sys.argv[1]:
            print(d['state']); sys.exit(0)
" "$DEVICE_ID")

if [ "$STATE" != "Booted" ]; then
  echo "==> Booting simulator..."
  xcrun simctl boot "$DEVICE_ID" 2>/dev/null || true
fi

# Bring Simulator window to front
open -a Simulator

# Build for simulator
echo "==> Building ($CONFIGURATION)..."
rm -rf "$BUILD_DIR"
xcodebuild -scheme "$SCHEME" \
  -sdk iphonesimulator \
  -configuration "$CONFIGURATION" \
  -destination "id=$DEVICE_ID" \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_ALLOWED=NO \
  BUILD_DIR="$BUILD_DIR" \
  -quiet \
  build

APP_PATH="$BUILD_DIR/$CONFIGURATION-iphonesimulator/$SCHEME.app"

if [ ! -d "$APP_PATH" ]; then
  echo "Error: Build output not found at $APP_PATH"
  exit 1
fi

# Install and launch
echo "==> Installing..."
xcrun simctl install "$DEVICE_ID" "$APP_PATH"

echo "==> Launching..."
xcrun simctl launch "$DEVICE_ID" "$BUNDLE_ID"

echo "Done! $SCHEME is running on $DEVICE_NAME."
