#!/usr/bin/env bash

if [ -z "$BASH_VERSION" ] || [ "${BASH_VERSINFO[0]}" -lt 4 ]; then
  echo "❌ Este script requiere Bash 4 o superior."
  echo "👉 Instalalo con: brew install bash"
  echo "👉 Ejecutalo así: /usr/local/bin/bash build_unsigned_ipa.sh <Partner> <Environment>"
  exit 1
fi

declare -A PARTNER_TARGET_MAP=(
  [BPN]="BPN"
  [BancoDeChile]="BancoDeChile"
  [Cabal]="Cabal"
  [CardNet]="CardNet"
  [FirstData]="FirstData"
  [MacroWallet]="MacroWallet"
  [Medianet]="Medianet"
  [Mio]="Mio"
  [Billet]="Billet"
  [OpenpayAR]="OpenpayAR"
  [OpenpayCol]="OpenpayCol"
  [OpenpayPE]="OpenpayPE"
  [PIK]="PIK"
  [PuntoClave]="PuntoClave"
  [Santander]="Santander"
  [TacaTaca]="TacaTaca"
  [UalaBis]="UalaBis"
  [VendeMas]="VendeMas"
  [VentaExpress]="VentaExpress"
  [WAPA]="WAPA"
  [compraqui]="compraqui"
)

if [ "$#" -ne 2 ]; then
  echo "❌ Uso: $0 <PartnerName> <Environment>"
  exit 1
fi

PARTNER="$1"
ENVIRONMENT="$2"
TARGET="${PARTNER_TARGET_MAP[$PARTNER]}"
SCHEME="$TARGET"
APP_NAME="$TARGET"
IPA_NAME="${PARTNER}.ipa"
BUILD_DIR="build"

if [ -z "$TARGET" ]; then
  echo "❌ Partner inválido: '$PARTNER'"
  echo "Partners válidos: ${!PARTNER_TARGET_MAP[@]}"
  exit 1
fi

if [ -f "GoPagos.xcodeproj" ]; then
  PROJECT_TYPE="-project GoPagos.xcodeproj"
else
  PROJECT_TYPE="-workspace GoPagos.xcworkspace"
fi

if ! xcodebuild $PROJECT_TYPE -list | grep -q "^[[:space:]]*$SCHEME$"; then
  echo "❌ El scheme '$SCHEME' no existe."
  exit 1
fi

rm -rf "$BUILD_DIR"

export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
export SDKROOT=$(xcrun --sdk iphoneos --show-sdk-path)

echo "🔎 Compilando $SCHEME [$ENVIRONMENT] → $APP_NAME.ipa"
echo "🧪 whoami: $(whoami)"
echo "🧪 DEVELOPER_DIR: $DEVELOPER_DIR"
echo "🧪 SDKROOT: $SDKROOT"

# Opcional y seguro aunque no uses SPM
xcodebuild -resolvePackageDependencies -scheme "$SCHEME" $PROJECT_TYPE -configuration "$ENVIRONMENT"

xcodebuild \
  $PROJECT_TYPE \
  -scheme "$SCHEME" \
  -configuration "$ENVIRONMENT" \
  -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGN_STYLE=Manual \
  PROVISIONING_PROFILE_SPECIFIER="" \
  DEVELOPMENT_TEAM="" \
  GCC_PREPROCESSOR_DEFINITIONS="DEBUG=1" \
  ONLY_ACTIVE_ARCH=NO \
  ENABLE_BITCODE=NO \
  ENABLE_TESTABILITY=YES \
  ENABLE_PARALLEL_BUILD=YES \
  CONFIGURATION_BUILD_DIR="$BUILD_DIR" \
  clean build

if [ $? -ne 0 ]; then
  echo "❌ Error: Falló la compilación. Abortando."
  exit 1
fi

APP_PATH="$BUILD_DIR/$APP_NAME.app"
if [ ! -d "$APP_PATH" ]; then
  echo "❌ No se encontró $APP_NAME.app en $BUILD_DIR"
  exit 1
fi

VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP_PATH/Info.plist" 2>/dev/null)
VERSION="${VERSION:-unknown}"

ARTIFACTS_DIR="$HOME/Desktop/${PARTNER}-${VERSION}-${ENVIRONMENT}"
README_PATH="$ARTIFACTS_DIR/README.txt"
mkdir -p "$ARTIFACTS_DIR"

mkdir -p Payload
cp -r "$APP_PATH" Payload/
cd Payload
zip -r "../$ARTIFACTS_DIR/$IPA_NAME" . > /dev/null
cd ..
rm -rf Payload "$BUILD_DIR"

cat << EOF > "$README_PATH"
# UNSIGNED IPA

Este .ipa fue generado sin firmar para que el equipo de $PARTNER lo firme con sus propios certificados.

- Nombre: $IPA_NAME
- Versión: $VERSION
- Entorno: $ENVIRONMENT

Firmar con Fastlane:
fastlane resign --ipa $IPA_NAME --signing_identity "..." --provisioning_profile "..."

Firmado manual:
1. Cambiar extensión a .zip y descomprimir
2. Firmar .app con codesign
3. Reempaquetar como .ipa
EOF

cd "$HOME/Desktop"
zip -r "$(basename "$ARTIFACTS_DIR").zip" "$(basename "$ARTIFACTS_DIR")" > /dev/null
cd - > /dev/null

open "$ARTIFACTS_DIR"

echo "✅ Listo: $ARTIFACTS_DIR y $(basename "$ARTIFACTS_DIR").zip creados en tu Escritorio."
