#!/bin/bash

set -euo pipefail

PARTNER_NAME=${1:-UalaBis}
CONFIGURATION=${2:-Release}

WORKSPACE="GoPagos.xcworkspace"
SCHEME="$PARTNER_NAME"
IPA_NAME="${PARTNER_NAME}-unsigned.ipa"

DERIVED_DATA=$(mktemp -d)
BUILD_DIR="$DERIVED_DATA/Build/Products/${CONFIGURATION}-iphoneos"
APP_PATH="$BUILD_DIR/${PARTNER_NAME}.app"

echo "▶️ Building ${SCHEME} (${CONFIGURATION}) without code signing..."

xcodebuild \
  -workspace "$WORKSPACE" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -sdk iphoneos \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  BUILD_DIR="$DERIVED_DATA" \
  build

if [ ! -d "$APP_PATH" ]; then
  echo "❌ .app not found at $APP_PATH"
  exit 1
fi

echo "📦 Packaging .ipa from $APP_PATH..."

mkdir -p Payload
cp -r "$APP_PATH" Payload/
zip -qry "$IPA_NAME" Payload
rm -rf Payload

echo "✅ Unsigned .ipa generated: $IPA_NAME"
