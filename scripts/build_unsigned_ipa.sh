#!/usr/bin/env bash

# 🔐 Validar versión mínima de Bash
if [ -z "$BASH_VERSION" ] || [ "${BASH_VERSINFO[0]}" -lt 4 ]; then
  echo "❌ Este script requiere Bash versión 4 o superior."
  echo "👉 Instalalo con: brew install bash"
  echo "👉 Ejecutalo así: /usr/local/bin/bash build_unsigned_ipa.sh <Partner> <Environment>"
  exit 1
fi

# 🎯 MAPPING Partner -> Target/Scheme/AppName
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

# 🧪 Validar argumentos
if [ "$#" -ne 2 ]; then
  echo "❌ Uso: $0 <PartnerName> <Environment>"
  echo "Ejemplo: $0 UalaBis Release"
  exit 1
fi

PARTNER="$1"
ENVIRONMENT="$2"
TARGET="${PARTNER_TARGET_MAP[$PARTNER]}"
SCHEME="$TARGET"
APP_NAME="$TARGET"
IPA_NAME="${PARTNER}.ipa"
BUILD_DIR="build"

# 🔐 Validar partner
if [ -z "$TARGET" ]; then
  echo "❌ Partner inválido o mal escrito: '$PARTNER'"
  echo "Partners válidos: ${!PARTNER_TARGET_MAP[@]}"
  exit 1
fi

# ⚙️ Detectar si se usa .xcodeproj o .xcworkspace
if [ -f "GoPagos.xcodeproj" ]; then
  PROJECT_TYPE="-project GoPagos.xcodeproj"
else
  PROJECT_TYPE="-workspace GoPagos.xcworkspace"
fi

# ✅ Validar scheme
echo "🔍 Verificando que '$SCHEME' exista..."
if ! xcodebuild $PROJECT_TYPE -list | grep -q "^[[:space:]]*$SCHEME$"; then
  echo "❌ El scheme '$SCHEME' no existe en el proyecto/workspace."
  exit 1
fi

# 🧼 Limpiar build anterior
echo "🧹 Limpiando build anterior..."
rm -rf "$BUILD_DIR"

# 🌍 Entorno explícito
export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
export SDKROOT=$(xcrun --sdk iphoneos --show-sdk-path)

echo "🔎 Partner=$PARTNER → Scheme=$SCHEME → Env=$ENVIRONMENT"
echo "🧪 whoami: $(whoami)"
echo "🧪 uname: $(uname -a)"
echo "🧪 DEVELOPER_DIR: $DEVELOPER_DIR"
echo "🧪 SDKROOT: $SDKROOT"

# ⚙️ Compilar sin firma
echo "⚙️ Compilando sin firma..."
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
  CONFIGURATION_BUILD_DIR="$BUILD_DIR" \
  clean build

# ❌ Si falla
if [ $? -ne 0 ]; then
  echo "❌ Error: Falló la compilación. Abortando."
  echo "📌 Consejo: Si compila en Xcode pero falla acá, revisá el Bridging Header, defines, y la firma."
  exit 1
fi

# ✅ Validar .app generado
APP_PATH="$BUILD_DIR/$APP_NAME.app"
if [ ! -d "$APP_PATH" ]; then
  echo "❌ No se encontró $APP_NAME.app en $BUILD_DIR"
  exit 1
fi

# 🔢 Obtener versión
VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP_PATH/Info.plist" 2>/dev/null)
if [ -z "$VERSION" ]; then
  VERSION="unknown"
  echo "⚠️ No se pudo leer CFBundleShortVersionString, usando 'unknown'"
fi

# 📁 Carpeta de salida
ARTIFACTS_DIR="$HOME/Desktop/${PARTNER}-${VERSION}-${ENVIRONMENT}"
README_PATH="$ARTIFACTS_DIR/README.txt"
mkdir -p "$ARTIFACTS_DIR"

# 📦 Empaquetar .ipa
echo "📦 Empaquetando .ipa sin firmar..."
mkdir -p Payload
cp -r "$APP_PATH" Payload/
cd Payload
zip -r "../$ARTIFACTS_DIR/$IPA_NAME" . > /dev/null
cd ..
rm -rf Payload "$BUILD_DIR"

# 📝 README
cat << EOF > "$README_PATH"
# UNSIGNED IPA - PARA FIRMA Y DISTRIBUCIÓN

Este archivo .ipa ha sido generado SIN FIRMA para que el equipo de $PARTNER lo firme y distribuya con sus propios certificados y perfiles de aprovisionamiento.

📦 ARCHIVO ENTREGADO:
- $IPA_NAME

⚠️ IMPORTANTE:
- Este .ipa no está firmado.
- No puede instalarse ni subirse a App Store Connect hasta que sea firmado correctamente.

🔏 ¿CÓMO FIRMAR ESTE .IPA?

Fastlane:
fastlane resign \\
  --ipa $IPA_NAME \\
  --signing_identity "iPhone Distribution: Nombre del equipo" \\
  --provisioning_profile "ruta/al/profile.mobileprovision"

Manual:
1. Cambiar extensión a .zip y descomprimir
2. Firmar $APP_NAME.app con codesign
3. Reempaquetar como .ipa
EOF

# 🗜️ Comprimir .zip
ZIP_NAME="${ARTIFACTS_DIR}.zip"
cd "$HOME/Desktop"
zip -r "$(basename "$ZIP_NAME")" "$(basename "$ARTIFACTS_DIR")" > /dev/null
cd - > /dev/null

# 📂 Abrir en Finder
open "$ARTIFACTS_DIR"

echo "✅ Listo: $ARTIFACTS_DIR y $(basename "$ZIP_NAME") creados en tu Escritorio."
