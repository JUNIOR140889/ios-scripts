#!/bin/bash

# Verifica argumentos
PARTNER=$1
ENVIRONMENT=$2

if [[ -z "$PARTNER" || -z "$ENVIRONMENT" ]]; then
  echo "❌ Debe indicar el nombre del partner (ej: UalaBis) y el ambiente (Release, Debug, Test, Preprod)"
  exit 1
fi

SCHEME="$PARTNER"
WORKSPACE="GoPagos.xcworkspace"
CONFIGURATION="$ENVIRONMENT"

# Ruta temporal
BUILD_DIR=$(mktemp -d)

echo "📦 Compilando $SCHEME ($CONFIGURATION)..."

# Ejecuta build sin firma
set -o pipefail
xcodebuild \
  -workspace "$WORKSPACE" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -sdk iphoneos \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  BUILD_DIR="$BUILD_DIR" \
  | xcpretty --progress

APP_PATH="$BUILD_DIR/Release-iphoneos/$SCHEME.app"

if [[ ! -d "$APP_PATH" ]]; then
  echo "❌ .app no encontrado en $APP_PATH"
  exit 1
fi

# Extrae la versión del build
INFO_PLIST="$APP_PATH/Info.plist"
BUILD_NUMBER=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$INFO_PLIST" 2>/dev/null)

if [[ -z "$BUILD_NUMBER" ]]; then
  echo "❌ No se pudo obtener el CFBundleVersion desde $INFO_PLIST"
  exit 1
fi

echo "🔢 Build encontrado: $BUILD_NUMBER"

# Prepara estructura Payload y empaqueta
PAYLOAD_DIR="$BUILD_DIR/Payload"
mkdir -p "$PAYLOAD_DIR"
cp -r "$APP_PATH" "$PAYLOAD_DIR/"

IPA_OUTPUT_DIR=~/Desktop/UNSIGNED-IPA/$ENVIRONMENT
mkdir -p "$IPA_OUTPUT_DIR"

IPA_PATH="$IPA_OUTPUT_DIR/${PARTNER}-${BUILD_NUMBER}.ipa"
cd "$BUILD_DIR"
zip -qr "$IPA_PATH" Payload

echo "✅ IPA sin firmar generado en: $IPA_PATH"

# Limpieza opcional (mantener si querés debuggear)
# rm -rf "$BUILD_DIR"

