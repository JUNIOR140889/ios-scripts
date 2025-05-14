#!/bin/bash

set -e

# VALIDACIÓN DE INPUT
PARTNER=$1
ENVIRONMENT=$2

if [ -z "$PARTNER" ] || [ -z "$ENVIRONMENT" ]; then
  echo "❌ Debes indicar el nombre del partner y el ambiente. Ejemplo:"
  echo "bash build_unsigned_ipa.sh UalaBis Release"
  exit 1
fi

# CONFIGURACIÓN
WORKSPACE="GoPagos.xcworkspace"
SCHEME="$PARTNER"
CONFIGURATION="$ENVIRONMENT"
DERIVED_DATA_PATH=$(mktemp -d)

echo "📦 Compilando $PARTNER ($ENVIRONMENT)..."

# BUILD SIN FIRMA
xcodebuild \
  -workspace "$WORKSPACE" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -sdk iphoneos \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  build > /dev/null

APP_PATH="$DERIVED_DATA_PATH/Build/Products/${CONFIGURATION}-iphoneos/${SCHEME}.app"

if [ ! -d "$APP_PATH" ]; then
  echo "❌ .app no encontrado en $APP_PATH"
  exit 1
fi

# OBTENER VERSIÓN DEL .app
INFO_PLIST="${APP_PATH}/Info.plist"
VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$INFO_PLIST" 2>/dev/null || echo "0.0.0")

# GENERAR .IPA
PAYLOAD_DIR=$(mktemp -d)
mkdir -p "$PAYLOAD_DIR/Payload"
cp -r "$APP_PATH" "$PAYLOAD_DIR/Payload/"

IPA_NAME="${PARTNER}-${VERSION}.ipa"
OUTPUT_FOLDER=~/Desktop/UNSIGNED-IPA/${ENVIRONMENT}
mkdir -p "$OUTPUT_FOLDER"
cd "$PAYLOAD_DIR"
zip -r "$OUTPUT_FOLDER/$IPA_NAME" Payload > /dev/null
cd - > /dev/null

echo "✅ IPA sin firmar generada en:"
echo "$OUTPUT_FOLDER/$IPA_NAME"
