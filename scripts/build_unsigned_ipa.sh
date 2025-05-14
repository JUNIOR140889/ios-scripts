#!/bin/bash

# Argumentos: PARTNER y ENVIRONMENT
PARTNER="$1"
ENVIRONMENT="$2"

if [[ -z "$PARTNER" || -z "$ENVIRONMENT" ]]; then
  echo "❌ Debe indicar el nombre del partner (ej: UalaBis) y el environment (Release, Debug, etc)."
  exit 1
fi

SCHEME="$PARTNER"
CONFIGURATION="$ENVIRONMENT"
WORKSPACE="GoPagos.xcworkspace"

# Ruta base del DerivedData
DERIVED_DATA_PATH="~/Library/Developer/Xcode/DerivedData"

# Clean build path antes de compilar
BUILD_PATH=$(mktemp -d)

echo "📦 Compilando $SCHEME ($CONFIGURATION)..."

xcodebuild \
  -workspace "$WORKSPACE" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -sdk iphoneos \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  BUILD_DIR="$BUILD_PATH" \
  build

APP_PATH=$(find "$BUILD_PATH" -type d -name "$SCHEME.app" | head -n 1)

if [[ ! -d "$APP_PATH" ]]; then
  echo "❌ No se encontró el .app compilado. Abortando."
  exit 1
fi

# Obtener el valor de CFBundleVersion (build)
INFO_PLIST="$APP_PATH/Info.plist"
BUILD_VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "$INFO_PLIST" 2>/dev/null)

if [[ -z "$BUILD_VERSION" ]]; then
  echo "❌ No se pudo leer CFBundleVersion desde el Info.plist"
  exit 1
fi

# Ruta final del .ipa
OUTPUT_DIR=~/Desktop/UNSIGNED-IPA/$CONFIGURATION
OUTPUT_PATH="$OUTPUT_DIR/${PARTNER}-${BUILD_VERSION}.ipa"

mkdir -p "$OUTPUT_DIR"

# Generar IPA
TEMP_PAYLOAD=$(mktemp -d)
mkdir -p "$TEMP_PAYLOAD/Payload"
cp -r "$APP_PATH" "$TEMP_PAYLOAD/Payload"

cd "$TEMP_PAYLOAD"
zip -qr "$OUTPUT_PATH" Payload
cd - > /dev/null

# Limpieza
rm -rf "$TEMP_PAYLOAD"
rm -rf "$BUILD_PATH"

echo "✅ IPA sin firma generada:"
echo "$OUTPUT_PATH"
