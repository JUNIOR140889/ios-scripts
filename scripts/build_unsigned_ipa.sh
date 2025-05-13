#!/bin/bash

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
WORKSPACE="GoPagos.xcworkspace"
TARGET="${PARTNER_TARGET_MAP[$PARTNER]}"
SCHEME="$TARGET"
APP_NAME="$TARGET"
IPA_NAME="${PARTNER}.ipa"
BUILD_DIR="build"

# 🚨 Validar partner
if [ -z "$TARGET" ]; then
  echo "❌ Partner inválido: '$PARTNER'"
  echo "Partners disponibles: ${!PARTNER_TARGET_MAP[@]}"
  exit 1
fi

# ✅ Validar que el scheme exista en el workspace
echo "🔍 Verificando que '$SCHEME' exista en $WORKSPACE..."
if ! xcodebuild -workspace "$WORKSPACE" -list | grep -q "^[[:space:]]*$SCHEME$"; then
  echo "❌ El scheme '$SCHEME' no existe en $WORKSPACE."
  exit 1
fi

# 🧼 Limpiar
echo "🧹 Limpiando build anterior..."
rm -rf "$BUILD_DIR"

# 🧪 Mostrar configuración usada
echo "🧪 Ejecutando build con:"
echo "  Workspace: $WORKSPACE"
echo "  Scheme:    $SCHEME"
echo "  Target:    $TARGET"
echo "  Config:    $ENVIRONMENT"

# ⚙️ Compilar sin firmar
xcodebuild \
  -workspace "$WORKSPACE" \
  -scheme "$SCHEME" \
  -configuration "$ENVIRONMENT" \
  -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  CONFIGURATION_BUILD_DIR="$BUILD_DIR" \
  build

# ❌ Cortar si falla la build
if [ $? -ne 0 ]; then
  echo "❌ Error: Falló la compilación. Abortando."
  exit 1
fi

# ✅ Validar que se haya generado el .app
APP_PATH="$BUILD_DIR/$APP_NAME.app"
if [ ! -d "$APP_PATH" ]; then
  echo "❌ No se encontró $APP_NAME.app en $BUILD_DIR"
  exit 1
fi

# 🔢 Obtener versión desde Info.plist
VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP_PATH/Info.plist" 2>/dev/null)
if [ -z "$VERSION" ]; then
  VERSION="unknown"
  echo "⚠️ No se pudo leer CFBundleShortVersionString, usando 'unknown'"
fi

# 📁 Ruta de artefactos en el escritorio
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

---

📦 ARCHIVO ENTREGADO:

- $IPA_NAME

Este archivo contiene el binario de la app en formato estándar (.ipa), empaquetado sin firma digital.

---

⚠️ IMPORTANTE:

- Este .ipa no está firmado.
- No puede instalarse en dispositivos ni subirse a App Store Connect hasta que sea firmado correctamente.
- El uso de este binario sin firma es bajo responsabilidad del partner.

---

🔏 ¿CÓMO FIRMAR ESTE .IPA?

Opción 1: Usando Fastlane

\`\`\`bash
fastlane resign \\
  --ipa $IPA_NAME \\
  --signing_identity "iPhone Distribution: Nombre del equipo" \\
  --provisioning_profile "ruta/al/profile.mobileprovision"
\`\`\`

Opción 2: Manual con Xcode (Avanzado)

1. Cambiar extensión a .zip y descomprimir
2. Firmar $APP_NAME.app con codesign
3. Reempaquetar como .ipa

---

📬 Soporte:

Contactar al equipo técnico que entregó el artefacto si tienen dudas sobre la firma o el uso.
EOF

# 🗜️ Comprimir .zip
ZIP_NAME="${ARTIFACTS_DIR}.zip"
cd "$HOME/Desktop"
zip -r "$(basename "$ZIP_NAME")" "$(basename "$ARTIFACTS_DIR")" > /dev/null
cd - > /dev/null

# 📂 Abrir en Finder
open "$ARTIFACTS_DIR"

echo "✅ Listo: $ARTIFACTS_DIR y $(basename "$ZIP_NAME") creados en tu Escritorio."

