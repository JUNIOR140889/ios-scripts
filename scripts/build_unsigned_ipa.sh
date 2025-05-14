#!/bin/bash

set -e

PARTNER=$1
ENVIRONMENT=$2

if [ -z "$PARTNER" ] || [ -z "$ENVIRONMENT" ]; then
  echo "❌ Debe indicar el nombre del partner y el environment. Ej: UalaBis Release"
  exit 1
fi

SCHEME="$PARTNER"
WORKSPACE="GoPagos.xcworkspace"
CONFIGURATION="$ENVIRONMENT"
DERIVED_DATA_PATH="./DerivedData"
OUTPUT_DIR="./output/$PARTNER/$ENVIRONMENT"
IPA_NAME="$PARTNER-unsigned.ipa"

echo "🚀 Generando build unsigned para $PARTNER [$ENVIRONMENT]..."

# Limpiar cualquier build anterior
rm -rf "$DERIVED_DATA_PATH"
mkdir -p "$OUTPUT_DIR"

# Construir sin firma
xcodebuild \
  -workspace "$WORKSPACE" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -sdk iphoneos \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  build

# Verificar que el .app existe
APP_PATH="$DERIVED_DATA_PATH/Build/Products/${CONFIGURATION}-iphoneos/${SCHEME}.app"
if [ ! -d "$APP_PATH" ]; then
  echo "❌ .app no encontrado en $APP_PATH"
  exit 1
fi

# Empaquetar .ipa unsigned
cd "$DERIVED_DATA_PATH/Build/Products/${CONFIGURATION}-iphoneos"
mkdir -p Payload
cp -r "${SCHEME}.app" Payload/
zip -r "$IPA_NAME" Payload > /dev/null
mv "$IPA_NAME" "../../../../$OUTPUT_DIR/"
cd - > /dev/null

echo "✅ .ipa sin firmar generado: $OUTPUT_DIR/$IPA_NAME"

