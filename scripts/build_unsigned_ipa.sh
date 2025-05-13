#!/bin/bash

# 🧪 Validar cantidad de argumentos
if [ "$#" -ne 4 ]; then
  echo "❌ Uso: $0 <workspace> <scheme> <app_name> <ipa_name>"
  echo "Ejemplo: $0 TuApp.xcworkspace TuScheme TuApp UnsignedApp.ipa"
  exit 1
fi

# 🚀 PARÁMETROS
WORKSPACE="$1"
SCHEME="$2"
APP_NAME="$3"
IPA_NAME="$4"

CONFIGURATION="Release"
BUILD_DIR="build"
ARTIFACTS_DIR="artifacts"
README_PATH="$ARTIFACTS_DIR/README.txt"

# 🧾 Validar que el workspace exista
if [ ! -f "$WORKSPACE" ]; then
  echo "❌ El archivo '$WORKSPACE' no existe."
  exit 1
fi

# 🧼 LIMPIAR
echo "🧹 Limpiando build anterior..."
rm -rf "$BUILD_DIR" "$ARTIFACTS_DIR"
mkdir -p "$ARTIFACTS_DIR"

# ⚙️ COMPILAR SIN FIRMA
echo "⚙️ Compilando .app sin firmar..."
xcodebuild \
  -workspace "$WORKSPACE" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  CONFIGURATION_BUILD_DIR="$BUILD_DIR" \
  build

# 🧾 Validar que se haya generado el .app
if [ ! -d "$BUILD_DIR/$APP_NAME.app" ]; then
  echo "❌ No se encontró $APP_NAME.app en $BUILD_DIR. Verificá que el nombre coincida con el producto de tu scheme."
  exit 1
fi

# 📦 EMPAQUETAR EN IPA
echo "📦 Empaquetando .ipa sin firmar..."
mkdir -p Payload
cp -r "$BUILD_DIR/$APP_NAME.app" Payload/
cd Payload
zip -r "../$ARTIFACTS_DIR/$IPA_NAME" . > /dev/null
cd ..
rm -rf Payload "$BUILD_DIR"

# 📝 CREAR README
cat << EOF > "$README_PATH"
# UNSIGNED IPA - PARA FIRMA Y DISTRIBUCIÓN

Este archivo .ipa ha sido generado SIN FIRMA para que el equipo de Ualá lo firme y distribuya con sus propios certificados y perfiles de aprovisionamiento.

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
# Instalar Fastlane si no lo tienen
sudo gem install fastlane

# Refirmar con certificados y perfil propios
fastlane resign \\
  --ipa $IPA_NAME \\
  --signing_identity "iPhone Distribution: Nombre del equipo" \\
  --provisioning_profile "ruta/al/profile.mobileprovision"
\`\`\`

Opción 2: Manual con Xcode (Avanzado)

1. Extraer el .app del .ipa:
   - Cambiar la extensión a .zip y descomprimir
   - Encontrarán el archivo en Payload/$APP_NAME.app

2. Firmar con codesign:
   \`\`\`bash
   codesign -f -s "iPhone Distribution: Nombre del equipo" --entitlements Entitlements.plist $APP_NAME.app
   \`\`\`

3. Reempaquetar en un nuevo .ipa:
   \`\`\`bash
   mkdir Payload
   mv $APP_NAME.app Payload/
   zip -r SignedApp.ipa Payload
   \`\`\`

---

🧾 Consideraciones:

- El equipo firmante debe contar con los certificados .p12 y provisioning profiles válidos.
- Si tienen un sistema de CI propio, pueden incluir este .ipa como input para sus jobs de firma.
- Recomendamos validar el binario con \`codesign -dv\` o cargarlo en dispositivos de test antes de producción.

---

📬 Soporte:

Si tienen dudas sobre el contenido o el proceso de firma, por favor contacten al equipo técnico que entregó el artefacto.
EOF

# ✅ FINAL
echo "✅ IPA unsigned y README.txt generados en: $ARTIFACTS_DIR/"
