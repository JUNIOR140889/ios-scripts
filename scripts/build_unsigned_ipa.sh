#!/bin/bash

set -e

PARTNER="$1"
ENVIRONMENT="$2"

if [ -z "$PARTNER" ] || [ -z "$ENVIRONMENT" ]; then
  echo "❌ Debes indicar el nombre del partner y el ambiente (ej: UalaBis Release)"
  exit 1
fi

WORKSPACE="GoPagos.xcworkspace"
SCHEME="$PARTNER"
CONFIGURATION="$ENVIRONMENT"
DERIVED_DATA="$(mktemp -d)"

# Extraer la version del Info.plist
PLIST_PATH=$(find . -name "Info.plist" | grep "$PARTNER" | head -n 1)
VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$PLIST_PATH")

# Directorio destino final
DEST_DIR=~/Desktop/UNSIGNED-IPA/$ENVIRONMENT
mkdir -p "$DEST_DIR"
OUTPUT_IPA="$DEST_DIR/${PARTNER}-${VERSION}.ipa"

# Build sin firma
xcodebuild \
  -workspace "$WORKSPACE" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -sdk iphoneos \
  -derivedDataPath "$DERIVED_DATA" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  build

# Empaquetar .ipa
APP_PATH="$DERIVED_DATA/Build/Products/${CONFIGURATION}-iphoneos/${PARTNER}.app"

if [ ! -d "$APP_PATH" ]; then
  echo "❌ No se encontró la ruta de la app: $APP_PATH"
  exit 1
fi

cd "$DERIVED_DATA"
mkdir Payload
cp -r "$APP_PATH" Payload/
zip -r "$OUTPUT_IPA" Payload > /dev/null

# Limpiar
rm -rf "$DERIVED_DATA"

# Éxito
echo "✅ IPA sin firmar generado en: $OUTPUT_IPA"
