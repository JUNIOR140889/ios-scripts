#!/bin/bash

set -e

PARTNER=$1
ENVIRONMENT=$2

if [ -z "$PARTNER" ] || [ -z "$ENVIRONMENT" ]; then
  echo "❌ Debe indicar el nombre del partner y el ambiente (ej: UalaBis Release)"
  exit 1
fi

SCHEME="$PARTNER"
CONFIGURATION="$ENVIRONMENT"
WORKSPACE="GoPagos.xcworkspace"

DERIVED_DATA_PATH=$(mktemp -d)
BUILD_PATH="$DERIVED_DATA_PATH/Build/Products/$CONFIGURATION-iphoneos"
APP_NAME="$PARTNER"
APP_PATH="$BUILD_PATH/$APP_NAME.app"

echo "🔨 Compilando sin firma..."
xcodebuild \
  -workspace "$WORKSPACE" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -sdk iphoneos \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  build | xcpretty

if [ ! -d "$APP_PATH" ]; then
  echo "❌ .app no encontrado en $APP_PATH"
  exit 1
fi

echo "📦 Empaquetando .ipa sin firma..."

# Obtener versión desde Info.plist
INFO_PLIST="$APP_PATH/Info.plist"
VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$INFO_PLIST")

# Crear carpeta de salida
OUTPUT_DIR=~/Desktop/"$PARTNER IPA's Productivos"
mkdir -p "$OUTPUT_DIR"
IPA_PATH="$OUTPUT_DIR/$PARTNER-$VERSION.ipa"

# Crear Payload y empaquetar
cd "$BUILD_PATH"
mkdir -p Payload
cp -r "$APP_NAME.app" Payload/
zip -r "$IPA_PATH" Payload > /dev/null
rm -rf Payload

echo "✅ IPA sin firmar generado en:"
echo "$IPA_PATH"
