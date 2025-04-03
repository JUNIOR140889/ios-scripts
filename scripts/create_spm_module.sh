#!/bin/bash

# ---------------------------------------------------------------------------
# USO:
#   ./create_spm_module.sh NombreDelModulo
#
# DESCRIPCIÓN:
#   Crea un directorio con el nombre especificado, inicializa un paquete Swift
#   y configura la estructura básica para un módulo SPM junto con un Example App.
#
# REQUISITOS:
#   - Swift 5.3 o superior.
#   - XcodeGen instalado (se instalará si no existe mediante Homebrew).
#   - Homebrew instalado.
# ---------------------------------------------------------------------------

# Verificar que se haya proporcionado un nombre de módulo
if [ -z "$1" ]; then
  echo "Error: Debes indicar el nombre del módulo."
  echo "Ejemplo: ./create_spm_module.sh MiNuevoModulo"
  exit 1
fi

MODULE_NAME=$1

# Validar si el directorio ya existe
if [ -d "$MODULE_NAME" ]; then
  echo "Error: El módulo '$MODULE_NAME' ya existe."
  exit 1
fi

echo "Creando módulo SPM '$MODULE_NAME'..."

# Crear la estructura básica del módulo SPM
mkdir "$MODULE_NAME"
cd "$MODULE_NAME" || exit 1

# Inicializar el paquete Swift con tipo 'library'
swift package init --type library

# Sobrescribir el Package.swift con la configuración deseada
cat > Package.swift <<EOF
// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "$MODULE_NAME",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "$MODULE_NAME",
            targets: ["$MODULE_NAME"]
        )
    ],
    dependencies: [
        // Declara dependencias externas aquí, si es necesario.
    ],
    targets: [
        .target(
            name: "$MODULE_NAME",
            dependencies: [],
            path: "Sources/$MODULE_NAME",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "${MODULE_NAME}Tests",
            dependencies: ["$MODULE_NAME"],
            path: "Tests/${MODULE_NAME}Tests"
        )
    ]
)
EOF

# Crear .gitignore básico
cat > .gitignore <<EOF
.build
DerivedData
EOF

# Crear la carpeta Sources/$MODULE_NAME y un archivo de ejemplo
mkdir -p "Sources/$MODULE_NAME"
cat > "Sources/$MODULE_NAME/${MODULE_NAME}.swift" <<EOF
public struct $MODULE_NAME {
    public init() { }
    
    public func hello() -> String {
        return "Hello from $MODULE_NAME"
    }
}
EOF

# Crear la carpeta Resources dentro de Sources/$MODULE_NAME
mkdir -p "Sources/$MODULE_NAME/Resources"
# (Puedes colocar aquí archivos de recursos si lo deseas)

# Crear la carpeta Tests y un test básico
mkdir -p "Tests/${MODULE_NAME}Tests"
cat > "Tests/${MODULE_NAME}Tests/${MODULE_NAME}Tests.swift" <<EOF
import XCTest
@testable import $MODULE_NAME

final class ${MODULE_NAME}Tests: XCTestCase {
    func testHello() {
        let module = $MODULE_NAME()
        XCTAssertEqual(module.hello(), "Hello from $MODULE_NAME")
    }
}
EOF

echo "Módulo SPM '$MODULE_NAME' creado correctamente."

# Verificar si xcodegen está instalado; si no, instalarlo con Homebrew
if ! command -v xcodegen >/dev/null 2>&1; then
  echo "xcodegen no está instalado. Intentando instalarlo vía Homebrew..."
  if ! command -v brew >/dev/null 2>&1; then
    echo "Error: Homebrew no está instalado. Instálalo y vuelve a intentarlo."
    exit 1
  fi
  brew install xcodegen || { echo "Error instalando xcodegen"; exit 1; }
else
  echo "xcodegen ya está instalado."
fi

# Generar el Example App usando XcodeGen
echo "Generando Example App..."
mkdir Example

# Crear un Info.plist para el Example App
mkdir -p Example/Info
cat > Example/Info/Info.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
      <key>CFBundleIdentifier</key>
      <string>com.geopagos.${MODULE_NAME}Example</string>
      <key>CFBundleName</key>
      <string>${MODULE_NAME}Example</string>
      <key>CFBundleExecutable</key>
      <string>${MODULE_NAME}Example</string>
      <key>CFBundleVersion</key>
      <string>1.0</string>
      <key>CFBundleShortVersionString</key>
      <string>1.0</string>
      <key>UILaunchStoryboardName</key>
      <string>LaunchScreen</string>
      <key>UIMainStoryboardFile</key>
      <string></string>
      <key>LSRequiresIPhoneOS</key>
      <true/>
      <key>UIRequiredDeviceCapabilities</key>
      <array>
          <string>armv7</string>
      </array>
      <key>UISupportedInterfaceOrientations</key>
      <array>
          <string>UIInterfaceOrientationPortrait</string>
      </array>
  </dict>
</plist>
EOF

# Crear un AppDelegate y un ViewController básicos para el Example App
mkdir -p Example/Sources
cat > Example/Sources/AppDelegate.swift <<EOF
import UIKit
import $MODULE_NAME

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(
      _ application: UIApplication,
      didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        let vc = ViewController(moduleName: "$MODULE_NAME")
        window?.rootViewController = vc
        window?.makeKeyAndVisible()
        return true
    }
}
EOF

cat > Example/Sources/ViewController.swift <<EOF
import UIKit
import $MODULE_NAME

class ViewController: UIViewController {
    
    let moduleName: String
    
    init(moduleName: String) {
        self.moduleName = moduleName
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) no implementado")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        let label = UILabel(frame: view.bounds)
        label.textAlignment = .center
        label.text = moduleName
        label.font = .systemFont(ofSize: 24)
        view.addSubview(label)
    }
}
EOF

# Crear un XcodeGen spec para el Example App
cat > Example/project.yml <<EOF
name: ${MODULE_NAME}Example
options:
  bundleIdPrefix: com.geopagos
configs:
  Debug: debug
  Release: release
settings:
  base:
    INFOPLIST_FILE: Info/Info.plist
packages:
  ${MODULE_NAME}:
    path: ".."
targets:
  ${MODULE_NAME}Example:
    type: application
    platform: iOS
    sources: [Sources]
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: "com.geopagos.${MODULE_NAME}Example"
    dependencies:
      - package: ${MODULE_NAME}
        product: ${MODULE_NAME}
EOF

# Ejecutar XcodeGen para generar el proyecto Xcode para el Example App
if xcodegen generate -s Example/project.yml -p Example; then
  echo "---------------------------------------------"
  echo "Módulo SPM '$MODULE_NAME' y Example App generados correctamente."
  echo "Estructura del módulo:"
  # Si tienes 'tree' instalado, lo muestra; de lo contrario, solo mensaje.
  if command -v tree >/dev/null 2>&1; then
    tree .
  else
    echo "Instala 'tree' para ver la estructura completa."
  fi
  echo "---------------------------------------------"
  echo "Para abrir el Example App, navega a la carpeta 'Example' y abre el proyecto Xcode generado."
else
  echo "Error: Falló la generación del proyecto Example App con XcodeGen."
  echo "Se eliminarán los archivos creados en 'Example'."
  rm -rf Example
  exit 1
fi
