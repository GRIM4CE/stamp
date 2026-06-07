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
ARCHES=(arm64)
if [[ "${1:-}" == "--universal" ]]; then
  ARCHES=(arm64 x86_64)
fi

# Force the native build system: Swift 6.2+ defaults to the Xcode-based
# "swiftbuild" system, which needs XCBuild.framework from a full Xcode install.
# With only the Command Line Tools, that's missing, so we use native.
#
# The native build system also can't emit a multi-arch binary in one pass
# (that path wants xcbuild too), so for universal we build each arch
# separately and stitch them together with lipo.
BINS=()
for arch in "${ARCHES[@]}"; do
  FLAGS="--build-system native -c release --arch $arch"
  echo "==> Building (release) $arch"
  swift build $FLAGS
  BINS+=("$(swift build $FLAGS --show-bin-path)/Stamp")
done

echo "==> Assembling $APP"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
if [[ ${#BINS[@]} -eq 1 ]]; then
  cp "${BINS[0]}" "$APP/Contents/MacOS/Stamp"
else
  lipo -create "${BINS[@]}" -output "$APP/Contents/MacOS/Stamp"
fi
cp Scripts/Info.plist "$APP/Contents/Info.plist"
cp Resources/stamp-100.png Resources/stamp-50.png "$APP/Contents/Resources/"
[[ -f Resources/AppIcon.icns ]] && cp Resources/AppIcon.icns "$APP/Contents/Resources/"

echo "==> Ad-hoc signing"
codesign --force --deep -s - "$APP"

echo "==> Done: $APP"
echo "    Open with: open \"$APP\""
