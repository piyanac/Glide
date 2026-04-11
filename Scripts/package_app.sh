#!/bin/zsh

set -euo pipefail

APP_NAME="Glide"
BUNDLE_ID="${BUNDLE_ID:-com.ztdu.Glide}"
VERSION="${VERSION:-1.0.0}"
BUILD_NUMBER="${BUILD_NUMBER:-2}"
CONFIGURATION="${CONFIGURATION:-release}"
SIGN_IDENTITY="${SIGN_IDENTITY:--}"
ENABLE_HARDENED_RUNTIME="${ENABLE_HARDENED_RUNTIME:-auto}"
ENTITLEMENTS_PLIST="${ENTITLEMENTS_PLIST:-}"

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUTPUT_DIR="${OUTPUT_DIR:-$ROOT_DIR/dist}"
APP_DIR="$OUTPUT_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
TEMP_DIR="$(mktemp -d)"
ICONSET_DIR="$TEMP_DIR/AppIcon.iconset"

cleanup() {
  rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

mkdir -p "$OUTPUT_DIR"

echo "Building $APP_NAME ($CONFIGURATION)..."
swift build -c "$CONFIGURATION"

BIN_DIR="$(swift build -c "$CONFIGURATION" --show-bin-path)"
EXECUTABLE_PATH="$BIN_DIR/$APP_NAME"
RESOURCE_BUNDLE_PATH="$BIN_DIR/${APP_NAME}_${APP_NAME}.bundle"

if [[ ! -x "$EXECUTABLE_PATH" ]]; then
  echo "Expected executable not found: $EXECUTABLE_PATH" >&2
  exit 1
fi

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

cp "$EXECUTABLE_PATH" "$MACOS_DIR/$APP_NAME"

if [[ -d "$RESOURCE_BUNDLE_PATH" ]]; then
  cp -R "$RESOURCE_BUNDLE_PATH" "$RESOURCES_DIR/"
fi

mkdir -p "$ICONSET_DIR"
cp "$ROOT_DIR"/Sources/Glide/Resources/Assets.xcassets/AppIcon.appiconset/*.png "$ICONSET_DIR/"
iconutil -c icns "$ICONSET_DIR" -o "$RESOURCES_DIR/AppIcon.icns"

cat > "$CONTENTS_DIR/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "https://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleDisplayName</key>
  <string>$APP_NAME</string>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>$VERSION</string>
  <key>CFBundleVersion</key>
  <string>$BUILD_NUMBER</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
EOF

printf 'APPL????' > "$CONTENTS_DIR/PkgInfo"

codesign_args=(
  --force
  --deep
  --sign "$SIGN_IDENTITY"
)

if [[ "$ENABLE_HARDENED_RUNTIME" == "yes" ]] || {
  [[ "$ENABLE_HARDENED_RUNTIME" == "auto" ]] &&
  [[ "$SIGN_IDENTITY" != "-" ]]
}; then
  codesign_args+=(--options runtime)
fi

if [[ -n "$ENTITLEMENTS_PLIST" ]]; then
  codesign_args+=(--entitlements "$ENTITLEMENTS_PLIST")
fi

codesign "${codesign_args[@]}" "$APP_DIR" >/dev/null

echo "Created app bundle:"
echo "  $APP_DIR"
