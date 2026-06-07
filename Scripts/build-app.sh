#!/usr/bin/env bash
# Builds Stamp.app into dist/ — a double-clickable macOS app bundle.
#
# Usage:
#   Scripts/build-app.sh            # arm64 (Apple Silicon)
#   Scripts/build-app.sh --universal  # arm64 + x86_64 (also runs on Intel Macs)
#
# Requires only the Command Line Tools (no Xcode). The result is ad-hoc signed,
# which is enough to run on the machine that built it. See README for hand-off.
set -euo pipefail

cd "$(dirname "$0")/.."   # repo root
APP="dist/Stamp.app"
ARCH_FLAGS="--arch arm64"
if [[ "${1:-}" == "--universal" ]]; then
  ARCH_FLAGS="--arch arm64 --arch x86_64"
fi

# Force the native build system: Swift 6.2+ defaults to the Xcode-based
# "swiftbuild" system, which needs XCBuild.framework from a full Xcode install.
# With only the Command Line Tools, that's missing, so we use native.
BUILD_FLAGS="--build-system native -c release $ARCH_FLAGS"

echo "==> Building (release) $ARCH_FLAGS"
swift build $BUILD_FLAGS

BIN="$(swift build $BUILD_FLAGS --show-bin-path)/Stamp"

echo "==> Assembling $APP"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/Stamp"
cp Scripts/Info.plist "$APP/Contents/Info.plist"
cp Resources/stamp-100.png Resources/stamp-50.png "$APP/Contents/Resources/"
[[ -f Resources/AppIcon.icns ]] && cp Resources/AppIcon.icns "$APP/Contents/Resources/"

echo "==> Ad-hoc signing"
codesign --force --deep -s - "$APP"

echo "==> Done: $APP"
echo "    Open with: open \"$APP\""
