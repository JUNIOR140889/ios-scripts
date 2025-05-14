#!/usr/bin/env bash

# ✅ Validar bash
if [ -z "$BASH_VERSION" ] || [ "${BASH_VERSINFO[0]}" -lt 4 ]; then
  echo "❌ Este script requiere Bash 4 o superior."
  exit 1
fi

# 🎯 Mapeo Partner → Target
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

# 🧹 Opción de limpieza forzada
if [ "$1" == "--clean" ]; then
  echo "🧹 Limpiando entorno (Pods, DerivedData)..."
  rm -rf Pods/ ~/Library/Developer/Xcode/DerivedData build/
  pod deintegrate
  pod install
  shift
fi

# ✅ Forzar uso de Xcode 16.2
export DEVELOPER_DIR="/Applications/Xcode-16.2.app/Contents/Developer"
if [ ! -x "$DEVELOPER_DIR/usr/bin/xcodebuild" ]; then
  echo "❌ Xcode 16.2 no está disponible en $DEVELOPER_DIR"
  exit 1
fi

# ✅ Validar argumentos
if [ "$#" -ne 2 ]; then
  echo "❌ Uso: $0 [--clean] <Partner> <Environment>"
  exit 1
fi

PARTNER="$1"
ENVIRONMENT="$2"
TARGET="${PARTNER_TARGET_MAP[$PARTNER]}"
SCHEME="$TARGET"
APP_NAME="$TARGET"
IPA_NAME="${PARTNER}.ipa"

if [ -z "$TARGET" ]; then
  echo "❌ Partner inválido: '$PARTNER'"
  echo "Partners válidos: ${!PARTNER_TARGET_MAP[@]}"
  exit 1
fi

# Detectar si usar .xcodeproj o .xcworkspace
if [ -f "GoPagos.xcodeproj" ]; then
  PROJECT_TYPE="-project GoPagos.xcodeproj"
else
  PROJECT_TYPE="-workspace GoPagos.xcworkspace"
fi

# Validar scheme
if ! xcodebuild $PROJECT_TYPE -list | grep -q "^[[:space:]]*$SCHEME$"; then
  echo "❌ El scheme '$SCHEME' no existe."
  exit 1
fi

export SDKROOT=$(xcrun --sdk iphoneos --show-sdk-path)
ARCHIVE_DIR="$HOME/Library/Developer/Xcode/Archives/$(date +%Y-%m-%d)"
ARCHIVE_PATH="$ARCHIVE_DIR/${APP_NAME}.xcarchive"
rm -rf "$ARCHIVE_PATH"

echo "📦 Archivando $SCHEME [$ENVIRONMENT] con Xcode 16.2..."

xcodebuild \
  $PROJECT_TYPE \
  -scheme "$SCHEME" \
  -configuration "$ENVIRONMENT" \
  -destination 'generic/platform=iOS' \
  -archivePath "$ARCHIVE_PATH" \
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
  clean archive

if [ $? -ne 0 ]; then
  echo "❌ Error: Falló el archive. Abortando."
  exit 1
fi

APP_PATH="$ARCHIVE_PATH/Products/Applications/$APP_NAME.app"
if [ ! -d "$APP_PATH" ]; then
  echo "❌ No se encontró $APP_NAME.app en el archive."
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
rm -rf Payload

cat << EOF > "$README_PATH"
# UNSIGNED IPA - $PARTNER ($ENVIRONMENT)

Este .ipa fue generado SIN FIRMA para que el equipo de $PARTNER lo firme con sus propios certificados.

Versión: $VERSION
Entorno: $ENVIRONMENT

Firmar con Fastlane:
fastlane resign \\
  --ipa $IPA_NAME \\
  --signing_identity "iPhone Distribution: ..." \\
  --provisioning_profile "profile.mobileprovision"
EOF

cd "$HOME/Desktop"
zip -r "$(basename "$ARTIFACTS_DIR").zip" "$(basename "$ARTIFACTS_DIR")" > /dev/null
cd - > /dev/null

open "$ARTIFACTS_DIR"

echo "✅ Listo: $ARTIFACTS_DIR y $(basename "$ARTIFACTS_DIR").zip"
