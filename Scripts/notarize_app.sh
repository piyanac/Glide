#!/bin/zsh

set -euo pipefail

APP_NAME="${APP_NAME:-Glide}"
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUTPUT_DIR="${OUTPUT_DIR:-$ROOT_DIR/dist}"
APP_PATH="${APP_PATH:-$OUTPUT_DIR/$APP_NAME.app}"
ZIP_PATH="${ZIP_PATH:-$OUTPUT_DIR/$APP_NAME.zip}"
SIGN_IDENTITY="${SIGN_IDENTITY:-}"
NOTARY_PROFILE="${NOTARY_PROFILE:-}"
TEAM_ID="${TEAM_ID:-}"

if [[ -z "$SIGN_IDENTITY" ]]; then
  echo "Set SIGN_IDENTITY to your Developer ID Application identity." >&2
  echo "Example: SIGN_IDENTITY='Developer ID Application: Your Name (TEAMID)'" >&2
  exit 1
fi

if [[ "$SIGN_IDENTITY" != Developer\ ID\ Application:* ]]; then
  echo "SIGN_IDENTITY must be a Developer ID Application identity." >&2
  exit 1
fi

if [[ -z "$NOTARY_PROFILE" ]]; then
  echo "Set NOTARY_PROFILE to a keychain profile created with xcrun notarytool store-credentials." >&2
  exit 1
fi

if ! security find-identity -v -p codesigning | grep -Fq "$SIGN_IDENTITY"; then
  echo "Signing identity not found in keychain: $SIGN_IDENTITY" >&2
  exit 1
fi

rm -f "$ZIP_PATH"

SIGN_IDENTITY="$SIGN_IDENTITY" ENABLE_HARDENED_RUNTIME="yes" "$ROOT_DIR/Scripts/package_app.sh"

if [[ ! -d "$APP_PATH" ]]; then
  echo "Expected app not found: $APP_PATH" >&2
  exit 1
fi

echo "Archiving app for notarization..."
ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"

echo "Submitting to Apple notarization service..."
submit_args=(
  submit "$ZIP_PATH"
  --keychain-profile "$NOTARY_PROFILE"
  --wait
)

if [[ -n "$TEAM_ID" ]]; then
  submit_args+=(--team-id "$TEAM_ID")
fi

xcrun notarytool "${submit_args[@]}"

echo "Stapling notarization ticket..."
xcrun stapler staple "$APP_PATH"

echo "Validating stapled ticket..."
xcrun stapler validate "$APP_PATH"

echo "Notarized app:"
echo "  $APP_PATH"
