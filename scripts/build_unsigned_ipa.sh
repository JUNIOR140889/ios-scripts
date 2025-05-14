#!/bin/bash

set -euo pipefail

# 🧩 Verificar dependencias
if ! command -v xcpretty &> /dev/null; then
  echo "🛠  Instalando xcpretty..."
  if ! command -v gem &> /dev/null; then
    echo "❌ RubyGems (gem) no está instalado. Instálalo para continuar."
    exit 1
  fi
  sudo gem install xcpretty
fi

# 📥 Validación de argumentos
if [[ $# -ne 2 ]]; then
  echo "❌ Debe indicar el nombre del partner y el entorno (ej: UalaBis Release)"
  exit 1
fi

PARTNER=$1
ENVIRONMENT=$2

WORKSPACE="GoPagos.xcworkspace"
SCHEME="$PARTNER"
CONFIGURATION="$ENVIRONMENT"

DERIVED_DATA=$(mktemp -d)
BUILD_PATH="$DERIVED_DATA/Build/Products/$CONFIGURATION-iphoneos"

echo "📦 Compilando $PARTNER ($CONFIGURATION)..."

xcodebuild \
  -workspace "$WORKSPACE" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -sdk iphoneos \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  -derivedDataPath "$DERIVED_DATA" \
  | xcpretty --progress

APP_PATH=$(find "$BUILD_PATH" -name "$PARTNER.app" -type d | head -n 1)

if [ ! -d "$APP_PATH" ]; then
  echo "❌ .app no encontrado en $BUILD_PATH"
  exit 1
fi

# 🏷 Extraer versión desde Info.plist del .app
PLIST_PATH="$APP_PATH/Info.plist"
if [ ! -f "$PLIST_PATH" ]; then
  echo "❌ No se encontró Info.plist en el .app"
  exit 1
fi

VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$PLIST_PATH" 2>/dev/null || echo "0.0.0")

# 📁 Crear carpeta de destino
OUTPUT_DIR=~/Desktop/UNSIGNED-IPA/$ENVIRONMENT
mkdir -p "$OUTPUT_DIR"

# 📦 Empaquetar el .ipa sin firmar
PAYLOAD_DIR=$(mktemp -d)
cp -R "$APP_PATH" "$PAYLOAD_DIR/Payload"
OUTPUT_NAME="$PARTNER-$VERSION.ipa"
ZIP_PATH="$OUTPUT_DIR/$OUTPUT_NAME"

echo "📦 Generando .ipa: $ZIP_PATH..."
cd "$PAYLOAD_DIR"
zip -qry "$ZIP_PATH" Payload

echo "✅ IPA generada exitosamente: $ZIP_PATH"

# 🧹 Cleanup
rm -rf "$PAYLOAD_DIR"
rm -rf "$DERIVED_DATA"
