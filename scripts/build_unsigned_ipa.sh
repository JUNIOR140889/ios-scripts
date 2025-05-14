#!/bin/bash

set -euo pipefail

PARTNER_NAME=${1:?Debe indicar el nombre del partner (ej: UalaBis)}
CONFIGURATION=${2:?Debe indicar el nombre del ambiente (ej: Release, Debug, Preprod, Test)}

WORKSPACE="GoPagos.xcworkspace"
SCHEME="$PARTNER_NAME"
IPA_NAME="${PARTNER_NAME}.ipa"

DERIVED_DATA=$(mktemp -d)
BUILD_DIR="$DERIVED_DATA/Build/Products/${CONFIGURATION}-iphoneos"
APP_PATH="$BUILD_DIR/${PARTNER_NAME}.app"

echo "▶️ Building $SCHEME ($CONFIGURATION) without code signing..."

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

echo "📦 Packaging unsigned .ipa..."

mkdir -p Payload
cp -r "$APP_PATH" Payload/
zip -qry "$IPA_NAME" Payload
rm -rf Payload

# Extraer versión desde Info.plist
VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP_PATH/Info.plist")

# Crear carpeta destino
DEST_DIR="scripts/${PARTNER_NAME}/${CONFIGURATION}"
mkdir -p "$DEST_DIR"

FINAL_NAME="${PARTNER_NAME}-${VERSION}.zip"
mv "$IPA_NAME" "$DEST_DIR/$FINAL_NAME"

echo "✅ IPA sin firmar generada en: $DEST_DIR/$FINAL_NAME"
